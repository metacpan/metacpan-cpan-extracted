##############################################################################
#
#  Exception::Sink
#  Copyright (c) 2006-2024 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPLv2
#
##############################################################################
#
#  compact general purpose exception handling
#
##############################################################################
package Exception::Sink;
use Exporter;
our @ISA         = qw( Exporter );
our @EXPORT      = qw( 
                       sink 
                       dive 
                       surface 
                       surface2 
                       
                       boom_skip
                       boom 
                     );

our @EXPORT_OK   = qw( 
                       $DEBUG_SINK 
                       get_stack_trace
                     );
                     
our %EXPORT_TAGS = ( 'none' => [ ] );
our $VERSION     = '3.08';
use Exception::Sink::Class;
use strict;

our $DEBUG_SINK = 0;

sub sink($);
sub dive();
sub surface(@);
sub surface2(@);

sub boom($$);
sub boom($);

##############################################################################
#
# sink( "CLASS: ID: message..." )
# sinks the ship of class and id with reason message
#

sub sink($)
{
  my $msg = shift;

  my $org = $msg;

  my $class = 'UNKNOWN';
  my $id    = 'UNKNOWN';

  $class = $1 || $2 if $msg =~ s/^([a-z0-9_]+)\s*:\s*|^([a-z0-9_]+)$//i;
  $id    = $1       if $msg =~ s/^([a-z0-9_]+)\s*:\s*|^([a-z0-9_]+)$//i;

  $msg =~ s/\s+at\s+\/\S+.+$//;
  chomp( $msg );

  my ( $p, $f, $l ) = caller();
  $f =~ s/^(.*\/)([^\/]+)$/$2/;

  $class = uc $class;

  print STDERR "sink: $class ($f:$l)\n" if $DEBUG_SINK;

  die Exception::Sink::Class->new(
      'CLASS'   => $class,
      'ID'      => $id,
      'MSG'     => $msg,
      'PACKAGE' => $p,
      'FILE'    => $f,
      'LINE'    => $l,
      'ORG'     => $org,
      );
}

##############################################################################
#
# dive()
# continue sinking...
#

sub dive()
{
  print STDERR "dive: pre: $@\n" if $DEBUG_SINK;
  return 0 unless $@;
  if( !ref($@) )
    {
    print STDERR "dive: non-ship, resink: $@\n" if $DEBUG_SINK;
    # re-sink, non-ship
    my $AT=$@;
    eval { sink "SINK: $AT"; }
    };

  print STDERR "dive: $@->{CLASS}\n" if $DEBUG_SINK;

  die; # propagate
}

##############################################################################
#
# surface( class list )
# stops sinking of specific classes...
#

sub surface(@)
{
  print STDERR "surface: enter: $@ -> @_\n" if $DEBUG_SINK;
  return 0 unless $@;
  return 1 unless @_; # catch all
  if( !ref($@) )
    {
    print STDERR "surface: non-ship, resink: $@\n" if $DEBUG_SINK;
    # re-sink, non-ship
    my $AT=$@;
    if( $AT =~ /^[A-Z0-9_]+\:/ )
      {
      eval { sink $AT; }
      }
    else
      {
      eval { sink "SINK: $AT"; }
      }
    };

  print STDERR "surface: $@->{CLASS} -> @_?\n" if $DEBUG_SINK;

  for my $class ( @_ )
    {
    return 1 if    $class eq '*';
    return 1 if uc $class eq $@->{ 'CLASS' };
    }
  print STDERR "surface: $@->{CLASS} -> continuing...\n" if $DEBUG_SINK;
  return 0;
}

sub surface2(@)
{
  return 1 if surface(@_);
  dive();
  return 0;
}

##############################################################################
#
# boom()
# sink with stack trace
#

sub boom_skip($$)
{
  my $msg  = shift;
  my $skip = shift;
  chomp( $msg );
  $msg = "BOOM: [$$] $msg\n";
  sink( join '', ( $msg, get_stack_trace( $skip ) ) );
}

sub boom($)
{
  boom_skip($_[0],0);
}

sub get_stack_trace
{
  my $skip = shift;
  
  my @st;
  my $i;
  my $ml;
  
  $i = 1 + $skip; # skip get_stack_trace frame and optionally first N frames
  while ( my ( $pack, $file, $line, $subname ) = caller($i++) )
    {
    my $l = length( "$pack::$subname" );
    $ml = $l if $l > $ml;
    }
  
  $i = 1 + $skip; # skip get_stack_trace frame and optionally first N frames
  while ( my ( $pack, $file, $line, $subname ) = caller($i++) )
    {
    my $ii = $i - 1;
    my $l = length( "$pack::$subname" );
    my $pad = ' ' x ( $ml - $l );
    push @st, "      [$$] $ii: $pack::$subname $pad $file line $line\n";
    }
  
  return wantarray ? ( @st ) : join( '', @st );
}

##############################################################################
1;
##############################################################################

__END__

=pod

=head1 NAME

Exception::Sink - general purpose compact exception handling.

=head1 SYNOPSIS

  use Exception::Sink;

  eval
    {
    eval
      {
      # use one of the following for testing:
      sink 'BIG: this has no ID, should be surfaced by the global handler';
      sink 'USUAL: this has no ID, should be surfaced by the local handler';
      sink 'FATAL: EXAMPLE: fatal exception with ID "EXAMPLE", will not be handled';
      sink 'STRANGE: EXAMPLE: fatal exception with ID "EXAMPLE", will not be handled';
      };
    if( surface 'USUAL' ) # local handler
      {
      print "surface USUAL, handled\n";
      # handle 'USUAL' exceptions here, not 'BIG' ones
      }
    else
      {
      dive();
      }
    };
  dive if surface qw( FATAL STRANGE ); # avoid global handler
  if( surface '*' ) # global handler
    {
    print "surface *, handled\n";
    # will handle all exceptions, including our 'BIG' one
    # if we don't want to handle, we can still dive forward:
    dive(); # this is the last handler so diving here will stop the program
    }
  # only FATAL:EXAMPLE will reach here but will not be reported since simple
  # hashrefs has no stringification method

=head1 FUNCTIONS

=head2 sink($)

  sink() gets only one argument, string with format:

     "CLASS: ID: description"
     "CLASS: description"
     "description"

  exception will have accordingly:

     CLASS and ID
     CLASS only
     CLASS will be 'SINK'

  then it will throw (sink/dive) an exception hash ref.

=head2 surface(@)

  surface() will return true if argument list matches currently
  sinking exception:

  if( surface qw( BIG_ONE FATAL TESTING ) )
    {
    # handle one of BIG_ONE FATAL TESTING exception classes
    }
  else
    {
    # if not matched try to dive() (resink) below...
    dive();
    }

=head2 surface2(@)

  same as surface but will dive() if exception class has not been matched.
  i.e those are equal:

  if( surface( ... ) ) { handle } else { dive }

  handle if surface2( ... )

=head2 dive()

  will continue/propagate currently sinking exception

=head2 boom($)

  special version of sink() it will always has class 'BOOM' and has
  full stack trace with pid information added to the sink() description text.

=head2 boom_skip($$)

  same as boom() but has extra argument to skip the first N context frames in
  the stack. it is useful when boom() should be called from a handler, which 
  is not useful since it will be always present.
  
  if you are not sure what this means, just ignore it :)

=head2 get_stack_trace()

  this is utility function, which returns array with formatted stack trace
  lines, containing package, function names, file with line number. it can
  be called at any time, usually for debug purpose. it is not exported by
  default!

=head1 EXCEPTION STRUCTURE

  Executing this:

  sink "SINK: UNKNWON: here is the text of the exception";

  will create this exception data hash:

  $@ = {
          'CLASS'   => 'SINK',      # exception class, used by surface()
          'ID'      => 'UNKNOWN',   # this is optional error-id
          'FILE'    => 'Sink.pm',   # file where sink started
          'LINE'    => 87           # line where sink started
          'PACKAGE' => 'Sink',      # package where sink started
          'MSG'     => 'here is the text of the exception',
       };

  'CLASS' is used by surface() to filter which exceptions should be handled.
  'ID'    is used only by the exception handling code to figure what exactly
          has happened.

  The other attributes are for information puproses (debugging).

=head1 NOTES

  You may freely use die() instead of sink(). The following surface()/dive()
  will resink into hash reference.

  surface() will not dive/sink more if exception did not match class list.
  If you want surface() to handle class or otherwise to continue dive/sink,
  you should use surface2() instead:

    eval
      {
      eval
        {
        sink "TESTING: testing resink/dive surface2()";
        };
      if( surface2 'BIG_ONE' )
        {
        # only BIG_ONE exception will be handled here,
        # all the rest will dive/resink below...
        }
      };
    # TESTING exception will reach here

  If you do not want to autoimport all functions:

    use Exception::Sink qw( :none )

  If you want to use only surface() (probably with die() instead of sink() ):

    use Exception::Sink qw( :none surface )

=head1 TODO

  (more docs)

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-exception-sink.git
  
  git clone git://github.com/cade-vs/perl-exception-sink.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=cut

###EOF########################################################################

