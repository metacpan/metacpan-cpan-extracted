##############################################################################
#
#  Exception::Sink
#  Copyright (c) 2006-2026 Vladi Belperchinov-Shabanski "Cade"
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
our $VERSION     = '3.11';
use Exception::Sink::Class;
use strict;

our $DEBUG_SINK = 0;

##############################################################################
#
# sink( "CLASS: ID: message..." )
# sinks the ship of class and id with reason message
#

sub sink($)
{
  my $msg = shift;
  $msg = '' unless defined $msg;

  my $org = $msg;

  my $class = 'SINK';
  my $id    = 'UNKNOWN';

  $class = uc( $1 || $2 ) if $msg =~ s/^([a-z0-9_]+)\s*:(?!:)\s*|^([a-z0-9_]+)$//i;
  $id    = uc( $1       ) if $msg =~ s/^([a-z0-9_]+)\s*:(?!:)\s*//i;

  # strip perl die() location suffix: " at FILE line N." with optional ", <FH> line N."
  $msg =~ s/\s+at\s+\S+\s+line\s+\d+(?:,\s*<[^>]*>\s+(?:line|chunk)\s+\d+)?\.?\s*$//;
  chomp( $msg );

  # origin is the first frame outside this package, so boom() and re-sinks
  # from dive()/surface() report the user's call site, not Sink.pm
  my ( $p, $f, $l );
  my $cl = 0;
  while( ( $p, $f, $l ) = caller( $cl++ ) )
    {
    last if $p ne __PACKAGE__;
    }
  ( $p, $f, $l ) = caller() unless defined $p;
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
  if( ! UNIVERSAL::isa( $@, 'Exception::Sink::Class' ) )
    {
    print STDERR "dive: non-ship, resink: $@\n" if $DEBUG_SINK;
    # re-sink, non-ship
    my $AT=$@;
    if( ref $AT )
      {
      # foreign reference: keep its text intact, explicit ID stops parsing
      eval { sink "SINK: UNKNOWN: $AT"; }
      }
    else
      {
      eval { sink "SINK: $AT"; }
      }
    $@->{ 'OBJ' } = $AT if ref $AT; # original foreign exception
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
  if( ! UNIVERSAL::isa( $@, 'Exception::Sink::Class' ) )
    {
    print STDERR "surface: non-ship, resink: $@\n" if $DEBUG_SINK;
    # re-sink, non-ship
    my $AT=$@;
    if( $AT =~ /^[A-Z0-9_]+\s*:(?!:)/i ) # "CLASS: ..." prefix, but not "Pkg::Name=HASH(...)"
      {
      eval { sink $AT; }
      }
    elsif( ref $AT )
      {
      # foreign reference: keep its text intact, explicit ID stops parsing
      eval { sink "SINK: UNKNOWN: $AT"; }
      }
    else
      {
      eval { sink "SINK: $AT"; }
      }
    $@->{ 'OBJ' } = $AT if ref $AT; # original foreign exception
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
  boom_skip($_[0],1);
}

sub get_stack_trace
{
  my $skip = shift || 0;
  $skip = 0 if $skip < 0;

  my @st;
  my $i;
  my $ml = 0;

  $i = 1 + $skip; # skip get_stack_trace frame and optionally first N frames
  while ( my ( $pack, $file, $line, $subname ) = caller($i++) )
    {
    my $l = length( "$subname" );
    $ml = $l if $l > $ml;
    }

  $i = 1 + $skip; # skip get_stack_trace frame and optionally first N frames
  my $ii;
  while ( my ( $pack, $file, $line, $subname ) = caller($i++) )
    {
    $ii++;
    my $l = length( "$subname" );
    my $pad = ' ' x ( $ml - $l );
    push @st, "      [$$] $ii: $subname $pad $file line $line\n";
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
  # only FATAL:EXAMPLE will reach here and will be reported by perl using
  # the original sink() text, since exception objects stringify to it

=head1 FUNCTIONS

=head2 sink($)

  sink() gets only one argument, string with format:

     "CLASS: ID: description"
     "CLASS: description"
     "CLASS"
     "description"

  exception will have accordingly:

     CLASS and ID
     CLASS only, ID will be 'UNKNOWN'
     CLASS only, empty description
     CLASS will be 'SINK', ID will be 'UNKNOWN'

  CLASS and ID may contain only letters, digits and underscore. CLASS is
  converted to upper case. a single word with no colon is taken as CLASS,
  not as description. a trailing perl die() location (" at FILE line N.")
  is removed from the description but kept in the original text (see
  EXCEPTION STRUCTURE below).

  then it will throw (sink/dive) an Exception::Sink::Class object.

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

=head2 get_stack_trace( [ $skip ] )

  this is utility function, which returns list with formatted stack trace
  lines, containing function names, file with line number. in scalar
  context it returns the lines joined in a single string. optional $skip
  argument skips the first N frames of the trace. it can be called at any
  time, usually for debug purpose. it is not exported by default!

    use Exception::Sink qw( :DEFAULT get_stack_trace );
    print get_stack_trace();

=head1 EXCEPTION STRUCTURE

  Executing this:

  sink "SINK: UNKNOWN: here is the text of the exception";

  will create this exception object (Exception::Sink::Class, a blessed hash):

  $@ = {
          'CLASS'   => 'SINK',      # exception class, used by surface()
          'ID'      => 'UNKNOWN',   # this is optional error-id
          'FILE'    => 'main.pl',   # file where sink started
          'LINE'    => 87,          # line where sink started
          'PACKAGE' => 'main',      # package where sink started
          'MSG'     => 'here is the text of the exception',
          'ORG'     => 'SINK: UNKNOWN: here is the text of the exception',
       };

  'CLASS' is used by surface() to filter which exceptions should be handled.
  'ID'    is used only by the exception handling code to figure what exactly
          has happened.
  'ORG'   is the original, unparsed text given to sink().
  'OBJ'   exists only when surface()/dive() re-sink a foreign exception
          reference (any die() with a reference which is not an
          Exception::Sink::Class object). it holds the original reference.

  'FILE', 'LINE' and 'PACKAGE' are the user code location which started the
  exception: the sink()/boom() call, or the dive()/surface() call which
  re-sunk a die() text or foreign reference.

  Exception objects stringify like die() text: "$@" gives 'ORG' and, if it
  does not end with a newline, " at FILE line LINE.\n" is appended. this is
  what an uncaught exception prints. use $@->{ 'ORG' } for the bare text:

    sink "FOO: bar";      # "$@" is "FOO: bar at main.pl line 12.\n"
    sink "FOO: bar\n";    # "$@" is "FOO: bar\n"

  The other attributes are for information purposes (debugging).

  exception objects are always true in boolean context, even when the
  message is empty. all other string operations (eq, cmp, sort, hash keys,
  regex match) use the stringified text described above.

=head1 NOTES

  You may freely use die() instead of sink(). The following surface()/dive()
  will resink into Exception::Sink::Class object. surface() keeps "CLASS: ..."
  prefix of the die() text as exception class (upper case only), dive()
  always uses class 'SINK'.

  Exceptions thrown as references by other code (objects of other exception
  classes, plain hash refs, etc.) are re-sunk the same way. Their text is
  the stringified reference, class is 'SINK' (or the "CLASS: ..." prefix of
  the stringification if the object overloads it) and the original reference
  is kept in 'OBJ':

    eval { Some::Module::call() }; # dies with Some::Error object
    if( surface 'SINK' )
      {
      my $err = $@->{ 'OBJ' }; # the original Some::Error object
      }

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

  <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>

  http://cade.noxrun.com/

=cut

###EOF########################################################################

