package Image::DS9::Command;

use strict;
use warnings;

use Carp;

use Image::DS9::PConsts;
use Image::DS9::Grammar;
use Image::DS9::Parser;


sub new
{
  my $class = shift;
  $class = ref $class || $class;

  my $command = shift;
  my $opts = shift || {};

  return unless exists $Image::DS9::Grammar::Grammar{$command};

  my $spec = $Image::DS9::Grammar::Grammar{$command};


  my $self = bless { 
		    command => $command,
		    spec => $spec,
		    opts => $opts,
		    cvt  => 1,
		    chomp => 1,
		    retref => 0,
		    attrs => {}
		   }, $class;

  $self->parse(@_);

  $self;
}

sub parse
{
  my $self = shift;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1; 

  my $match = Image::DS9::Parser::parse_spec( $self->{command}, $self->{spec}, @_ );

  my ( $key, $value );
  $self->{$key} = $value while ( $key, $value ) = each %$match;
  $self->{found_attrs} = exists $self->{attrs};

  $self->{name} = $self->{argl}{name} || '';

  $self->{chomp} = $self->{argl}{chomp} if exists $self->{argl}{chomp};
  $self->{cvt} = $self->{argl}{cvt} if exists $self->{argl}{cvt};
  $self->{retref} = $self->{argl}{retref} if exists $self->{argl}{retref};

  # the 'new' and 'now' attributes are special.  this needs to be generalized
  for my $special ( qw( new now ) )
  {
    $self->{$special} =  $self->{attrs}{$special} || 0;
    delete $self->{attrs}{$special};
  }
  
  # if this command has a buffer argument, it needs to be
  # sent via the XPASet buffer argument, not as part of the
  # command string. split it off from the regular args
  if ( $self->{argl}{bufarg} && ! $self->{query} )
  {
    my $buf = pop @{$self->{args}};
    my $valref = 
      Image::DS9::PConsts::type_cvt( CvtSet, $buf->[0], $buf->[1] );
    $self->{bufarg} = $valref;
  }

  $self->form_command
    unless $self->{opts}{nocmd};
}


sub form_command
{
  my $self = shift;

  my @command = ( $self->{command} );

  foreach my $special( qw( new now ) )
  {
    push @command, $special if $self->{$special};
  }

  foreach my $what ( @{$self->{cmds}}, @{$self->{args}}  )
  {
    my ( $tag, $valref, $extra ) = @{$what};

    # ephemeral sub commands don't get sent
    next if T_EPHEMERAL == $tag;

    if ( T_REWRITE == $tag )
    {
      push @command, $$extra;
    }
    else
    {
      # cmds and args must be scalars.  they'll have been converted
      # to scalar refs by now to prevent copying of data.
      'SCALAR' eq ref $valref or 
	croak( __PACKAGE__, ": internal error! cmd/arg not scalar\n" );

      push @command, ${Image::DS9::PConsts::type_cvt( CvtSet, $tag, $valref )};
    }
  }

  unless ( $self->{opts}{noattrs} )
  {
    while( my ( $name, $val) = each %{$self->{attrs}} )
    {
      my $valref = 
	Image::DS9::PConsts::type_cvt( CvtSet, $val->{tag}, $val->{valref} );

      # dereference 
      push @command, $name, $$valref;
    }
  }

  $self->{command_list} = \@command;
}

sub attrs
{
  my $self = shift;

  my %attrs;

  while( my ( $name, $val) = each %{$self->{attrs}} )
  {
    my $valref = 
      Image::DS9::PConsts::type_cvt( CvtSet, $val->{tag}, $val->{valref} );

    # dereference scalar refs; leave the rest as is
    $attrs{$name} = 'SCALAR' eq ref($valref)? $$valref : $valref;
  }

  %attrs;
}

sub cvt_get
{
  my $self = shift;

  # don't change the buffer unless asked to convert values 
  # unless expecting more than one value or we're supposed to convert 
  return unless @{$self->{argl}{rvals}} > 1 || $self->{cvt};


  # the buffer will be changed, either through a split or a convert,
  # or both.

  # split the buffer if required
  my @input = @{$self->{argl}{rvals}} > 1 ? _splitbuf( $_[0] ) : ( $_[0] );
  my @output;

  if ( @input != @{$self->{argl}{rvals}} )
  {
    # too many results is always an error
    if ( @input > @{$self->{argl}{rvals}} )
    {
      croak( __PACKAGE__, 
	    "::cvt_get: $self->{command}: expected ", 
	    scalar @{$self->{argl}{rvals}}, 
	    " values, got ", scalar @input );
    }

    unless ( $self->{opts}{ResErrIgnore} )
    {
      no strict 'refs';
      my $func = $self->{opts}{ResErrWarn} ? 'carp' : 'croak';
      &$func( __PACKAGE__, 
	    "::cvt_get: $self->{command}: expected ", 
	    scalar @{$self->{argl}{rvals}}, 
	    " values, got ", scalar @input );
    }

    if ( @input < @{$self->{argl}{rvals}} )
    {
      push @input, () x ( @{$self->{argl}{rvals}} - @input );
    }
  }

  if ( $self->{cvt} )
  {
    foreach my $arg ( @{$self->{argl}{rvals}} )
    {
      my $tag = 'ARRAY' eq ref $arg ? $arg->[0] : T_OTHER;
      my $input = shift @input;

      my $valref = Image::DS9::PConsts::type_cvt( CvtGet, $tag, \$input );
      push @output, 'SCALAR' eq ref($valref) ? $$valref : $valref;
    }
  }
  else
  {
     @output = @input;
  }

  $_[0] =  @output > 1 ? \@output : $output[0];
}

sub _splitbuf
{

  $_[0] =~ s/^\s+//;
  $_[0] =~ s/\s+$//;
  split( / /, $_[0] )
}

sub command_list  { $_[0]->{command_list} };
sub command { join( ' ', @{$_[0]->{command_list}} ) };
sub query   { $_[0]->{query} }
sub bufarg  { $_[0]->{bufarg} }
sub chomp   { $_[0]->{chomp} }
sub retref  { $_[0]->{retref} }

1;
