package Image::DS9;

# ABSTRACT: a really awesome library

use strict;
use warnings;
use Carp;

use Module::Runtime 'use_module';

our $VERSION = '0.188';

our $use_PDL;

BEGIN {
    $use_PDL =
      eval {
          use_module( 'PDL::Core' );
          use_module( 'PDL::Types' );
          1;
      };
}

use IPC::XPA;

use Image::DS9::Command;
use Time::HiRes qw[ sleep ];

use constant SERVER => 'ds9';

use namespace::clean;

#####################################################################

# Preloaded methods go here.

sub _flatten_hash
{
  my ( $hash ) = @_;

  return '' unless keys %$hash;

  join( ',', map { "$_=" . $hash->{$_} } keys %$hash );
}

#####################################################################

# create new XPA object
{

  my %def_obj_attrs = ( Server => SERVER,
                        WaitTimeOut => 2,
                        WaitTimeInterval => 0.1,
                        min_servers => 1,
                        res_wanthash => 1,
                        kill_on_destroy => 0,
                        auto_start => 0,
                        verbose => 0
                      );

  my %def_xpa_attrs = ( max_servers => 1 );


  my %def_cmd_attrs = (
                        ResErrCroak => 0,
                        ResErrWarn => 0,
                        ResErrIgnore => 0
                      );


  sub new
  {
    my ( $class, $u_attrs ) = @_;
    $class = ref($class) || $class;

    # load up attributes, first from defaults, then
    # from user.  ignore bogus elements in user attributes hash

    my $self = bless {
                      xpa => IPC::XPA->Open,
                      %def_obj_attrs,
                      xpa_attrs => { %def_xpa_attrs },
                      cmd_attrs => { %def_cmd_attrs },
                      res => undef
                     }, $class;

    croak( __PACKAGE__, "->new: error creating XPA object" )
      unless defined $self->{xpa};

    $self->{xpa_attrs}{max_servers} = $self->nservers || 1;

    $self->set_attr( %$u_attrs);

    $self->{cmd_attrs}{ResErrCroak} = 1
      unless $self->{cmd_attrs}{ResErrWarn} ||
             $self->{cmd_attrs}{ResErrIgnore};

    croak( __PACKAGE__, "->new: inconsistent ResErrXXX attributes" )
      unless 1 == (!!$self->{cmd_attrs}{ResErrCroak} +
                   !!$self->{cmd_attrs}{ResErrWarn} +
                   !!$self->{cmd_attrs}{ResErrIgnore});

    $self->_start_server( $self->{auto_start} )
      if $self->{auto_start} && !$self->nservers;


    $self;
  }

  sub set_attr
  {
    my $self = shift;

    my %attr = @_;

    $self->{xpa_attrs}{$_} = delete $attr{$_}
      foreach grep { exists $def_xpa_attrs{$_} } keys %attr;

    $self->{cmd_attrs}{$_} = delete $attr{$_}
      foreach grep { exists $def_cmd_attrs{$_} } keys %attr;

    $self->{$_} = delete $attr{$_}
      foreach grep { exists $def_obj_attrs{$_} } keys %attr;

    croak( __PACKAGE__, ": unknown attribute(s): ",
           join( ', ', sort keys %attr ) )
      if keys %attr;
  }

  sub get_attr {

    my ( $self, $attr ) = @_;

    exists $_->{$attr} && return $_->{$attr}
      for $self, $self->{xpa_attrs}, $self->{cmd_attrs};

    croak( __PACKAGE__, ": unknown attribute: $attr" );

  }

}

sub DESTROY
{
    my $self = shift;

    if ( defined $self->{xpa} ) {
        $self->quit
          if $self->get_attr( 'kill_on_destroy' );
        $self->{xpa}->Close;
    }

    # note that if we had to start up a bespoke ds9 instance, the
    # Proc::Simple object will also kill the process upon destruction.

}

#####################################################################

sub nservers
{
  my $self = shift;

  my %res = $self->{xpa}->Access( $self->{Server}, 'gs' );

  if ( grep { defined $_->{message} } values %res )
  {
    $self->{res} = \%res;
    croak( __PACKAGE__, ": error sending data to server" );
  }

  keys %res;
}

#####################################################################

sub res
{
  %{$_[0]->{res} || {}};
}

#####################################################################

sub wait
{
  my $self = shift;
  my $timeout = shift || $self->{WaitTimeOut};
  my $timeinterval = $self->{WaitTimeInterval};

  unless( $self->nservers )
  {
    my $cnt = 0;
    sleep( $timeinterval )
      until $self->nservers >= $self->{min_servers}
            || ($cnt += $timeinterval) > $timeout;
  }

  return $self->nservers >= $self->{min_servers};
}


sub _start_server {

    my ( $self, $timeout ) = @_;

    $timeout = $timeout < 0 ? -$timeout : $self->get_attr( 'WaitTimeOut' );

    return if $self->wait( $timeout );

    require Proc::Simple;

    $self->{_process} = Proc::Simple->new;
    $self->{_process}->kill_on_destroy( $self->get_attr( 'kill_on_destroy' ) );

    my @cmd = (
        'ds9',
        (
            defined $self->{Server}
            ? ( -title => $self->{Server} )
            : ()
        ),
    );


    $self->{_process}->start( @cmd )
      or croak( "error running @cmd\n" );

    $self->wait() or croak( "error connecting to ds9 (@cmd)\n " );

}


#####################################################################

{
  # mapping between PDL
  my %map;

  if ( $use_PDL )
  {
    %map = (
            $PDL::Types::PDL_B => 8,
            $PDL::Types::PDL_S => 16,
            $PDL::Types::PDL_S => 16,
            $PDL::Types::PDL_L => 32,
            $PDL::Types::PDL_F => -32,
            $PDL::Types::PDL_D => -64
           );
  }

  sub array
  {
    my $self = shift;

    my $cmd;

    {
      local $Carp::CarpLevel = $Carp::CarpLevel + 1;

      $cmd = Image::DS9::Command->new( 'array', { %{$self->{cmd_attrs}},
                                                  nocmd => 1 }, @_ );
    }

    defined $cmd
      or croak( __PACKAGE__, ":internal error: unknown method `array'\n" );

    my $data = $cmd->bufarg;
    my %attrs = $cmd->attrs;

    if ( $use_PDL && ref( $data ) && UNIVERSAL::isa( $data, 'PDL' ))
    {
      $attrs{bitpix} = $map{$data->get_datatype};
      ($attrs{xdim}, $attrs{ydim}) = $data->dims;
      $data = ${$data->get_dataref};
      $attrs{ydim} = 1 unless defined $attrs{ydim};
    }

    if ( exists $attrs{dim} )
    {
      delete $attrs{xdim};
      delete $attrs{ydim};
    }
    elsif ( ! (exists $attrs{xdim} && exists $attrs{ydim} ) )
    {
      croak( __PACKAGE__,
             '->array -- either (xdim, ydim) or (dim) must be specified' );
    }

    croak( __PACKAGE__,
           "->array: `bitpix' attribute must be specified" )
      unless exists $attrs{bitpix};

    $self->Set( 'array ['._flatten_hash(\%attrs).']', $data );
  }
}


#####################################################################

sub fits
{
  my $self = shift;

  my $cmd;

  {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    $cmd = Image::DS9::Command->new( 'fits', { %{$self->{cmd_attrs}},
                                               noattrs => 1}, @_ )
      or croak( __PACKAGE__, ":internal error: unknown method `fits'\n" );
  }

  return $self->_get( $cmd )
    if $cmd->query;

  my %attrs = $cmd->attrs;

  my @mods;
  push @mods, '[' . $attrs{$_} . ']'
    foreach grep { exists $attrs{$_}} qw( extname filter );

  push @mods, '[bin=', join( ',', @{$attrs{bin}} ), ']'
    if exists $attrs{bin};

  $self->Set( $cmd->command . join('', @mods), $cmd->bufarg );
}

#####################################################################

sub file
{
  my $self = shift;

  my $cmd;

  {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    $cmd = Image::DS9::Command->new( 'file', { %{$self->{cmd_attrs}},
                                               noattrs => 1}, @_ )
      or croak( __PACKAGE__, ":internal error: unknown method `file'\n" );
  }
  return $self->_get( $cmd )
    if $cmd->query;

  my %attrs = $cmd->attrs;

  my @mods;
  push @mods, '[' . $attrs{$_} . ']'
    foreach grep { exists $attrs{$_}} qw( extname filter );

  push @mods, '[bin=', join( ',', @{$attrs{bin}} ), ']'
    if exists $attrs{bin};

  $self->Set( $cmd->command . join('', @mods), $cmd->bufarg );
}

#####################################################################

sub version
{
    my $self = shift;

    my $cmd;
    {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        $cmd = Image::DS9::Command->new( 'version', { %{$self->{cmd_attrs}},
                                                  noattrs => 1}, @_ )
          or croak( __PACKAGE__, ":internal error: unknown method `version'\n" );
    }

    my $version = $self->_get( $cmd );
    $version =~ s/^(\S+)\s+//;

    return $version;
}




#####################################################################

sub Set
{
  my $self = shift;
  my $cmd = shift;

  print STDERR ( __PACKAGE__, "->Set: $cmd\n" )
    if $self->{verbose};

  my %res = $self->{xpa}->Set( $self->{Server}, $cmd, $_[0],
                                            $self->{xpa_attrs} );

  # chomp messages
  foreach my $res ( values %res )
  {
    chomp $res->{message} if exists $res->{message};
  }

  if ( grep { defined $_->{message} } values %res )
  {
    $self->{res} = \%res;
    croak( __PACKAGE__, ": error sending data to server" );
  }

  if ( keys %res < $self->{min_servers} )
  {
    $self->{res} = \%res;
    croak( __PACKAGE__, ": fewer than ", $self->{min_servers},
           " server(s) responded" )
  }
}

#####################################################################

# wrapper for _Get for use by outsiders
# set res_wanthash according to scalar or array mode
sub Get
{
  my $self = shift;
  my $cmd = shift;
  $self->_Get( $cmd, { res_wanthash => wantarray() } );
}

#####################################################################

# wrapper for _Get for internal use.  handles single and multiple
# value returns by splitting the latter into an array
sub _get
{
  my $self = shift;
  my $cmd = shift;

  my %results = $self->_Get( $cmd->command,
                           { chomp => $cmd->chomp, res_wanthash => 1 } );

  unless ( wantarray() )
  {
    my ( $server ) = keys %results;
    $cmd->cvt_get( $results{$server}{buf} );
    return
      ( $cmd->retref && !ref($results{$server}{buf}) ) ?
        \($results{$server}{buf}) : $results{$server}{buf};
  }

  else
  {
    for my $res ( values %results )
    {
      $cmd->cvt_get( $res->{buf} );
    }
    return %results;
  }

}

#####################################################################

# send an XPA Get request to the servers.
# the passed attr hash modifies the returns; currently

# res_wanthash attribute:
# _Get returns the XPA Get return hash directly if true, else it
# returns the {buf} entry from an arbitrary server.  if there's but
# one server, res_wanthash=0 makes for cleaner coding.

# chomp attribute: removes trailing newline from returned data

sub _Get
{
  my ( $self, $cmd, $attr ) = @_;

  print STDERR ( __PACKAGE__, "->_Get: $cmd\n" )
    if $self->{verbose};

  my %attr = ( $attr ? %$attr : () );

  $attr{res_wanthash} = $self->{res_wanthash}
    unless defined $attr{res_wanthash};

  my %res = $self->{xpa}->Get( $self->{Server}, $cmd,
                               $self->{xpa_attrs} );

  # chomp results
  $attr{chomp} ||= 0;
  foreach my $res ( values %res )
  {
    chomp $res->{message} if exists $res->{message};
    chomp $res->{buf} if exists $res->{buf} && $attr{chomp};
  }

  if ( grep { defined $_->{message} } values %res )
  {
    $self->{res} = \%res;
    croak( __PACKAGE__, ": error sending data to server" );
  }

  if ( keys %res < $self->{min_servers} )
  {
    $self->{res} = \%res;
    croak( __PACKAGE__, ": fewer than ", $self->{min_servers},
           " servers(s) responded" )
  }

  unless ( $attr{res_wanthash} )
  {
    my ( $server ) = keys %res;
    return $res{$server}->{buf};
  }

  else
  {
    return %res;
  }
}


#####################################################################

our $AUTOLOAD;

sub AUTOLOAD
{
  my $self = shift;
  (my $sub = $AUTOLOAD) =~ s/.*:://;

  $sub = 'cmap' if $sub eq 'colormap';

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $cmd = Image::DS9::Command->new( $sub, {%{$self->{cmd_attrs}}}, @_ )
    or croak( __PACKAGE__, ": unknown method `$sub'\n" );

  $cmd->query ?
    $self->_get( $cmd ) :
      $self->Set( $cmd->command, $cmd->bufarg );
}


#
# This file is part of Image-DS9
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=head1 NAME

Image::DS9 - a really awesome library

=head1 VERSION

version 0.188

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-DS9>.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
