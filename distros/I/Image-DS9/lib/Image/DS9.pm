package Image::DS9;

use strict;
use warnings;
use Carp;

use Module::Runtime 'use_module';

our $VERSION = '0.186';

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

use constant SERVER => 'ds9';

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
			WaitTimeOut => 30,
			min_servers => 1,
			res_wanthash => 1,
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

    $self->set_attrs($u_attrs);

    $self->{cmd_attrs}{ResErrCroak} = 1
      unless $self->{cmd_attrs}{ResErrWarn} || 
	     $self->{cmd_attrs}{ResErrIgnore};
	
    croak( __PACKAGE__, "->new: inconsistent ResErrXXX attributes" )
      unless 1 == (!!$self->{cmd_attrs}{ResErrCroak} +
		   !!$self->{cmd_attrs}{ResErrWarn} +
		   !!$self->{cmd_attrs}{ResErrIgnore});

    $self->wait( )
      if defined $self->{Wait};

    $self;
  }

  sub set_attrs
  {
    my $self = shift;
    my $u_attrs = shift;

    my %ukeys = map { $_ => 1 } keys %$u_attrs;

    return unless $u_attrs;
    do { $self->{xpa_attrs}{$_} = $u_attrs->{$_}; delete $ukeys{$_} }
      foreach grep { exists $def_xpa_attrs{$_} } keys %$u_attrs;

    do { $self->{cmd_attrs}{$_} = $u_attrs->{$_}; delete $ukeys{$_} }
      foreach grep { exists $def_cmd_attrs{$_} } keys %$u_attrs;

    do { $self->{$_} = $u_attrs->{$_} ; delete $ukeys{$_} }
      foreach grep { exists $def_obj_attrs{$_} } keys %$u_attrs;

    croak( __PACKAGE__, ": unknown attribute(s): ", 
	   join( ', ', sort keys %ukeys ) )
      if keys %ukeys;
  }

}

sub DESTROY
{
  $_[0]->{xpa}->Close if defined $_[0]->{xpa};
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

  unless( $self->nservers )
  {
    my $cnt = 0;
    sleep(1)
      until $self->nservers >= $self->{min_servers}
            || $cnt++ > $timeout;
  }

  return $self->nservers >= $self->{min_servers};
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

  my $data = $cmd->bufarg;
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

  my $data = $cmd->bufarg;

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



# Autoload methods go after =cut, and are processed by the autosplit program.

1;

