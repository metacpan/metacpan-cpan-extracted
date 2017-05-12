package Devel::Spy;
use strict;
use warnings;
use Devel::Spy::Util;
use Sub::Name ();

use Devel::Spy::_constants;

our $VERSION = '0.07';

sub new {
    my @self;

    # Store a tied wrapper over the object. This will be used anytime
    # thing is ever used as a value or reference.
    $self[TIED_PAYLOAD] = Devel::Spy::Util->wrap_thing( $_[_thing], $_[_logger] );

    # Store a plain copy of $thing as well. If $thing is an object the
    # method calls have to go through this copy instead. tied objects
    # can't be returned as objects from function calls.
    $self[UNTIED_PAYLOAD] = $_[_thing];

    # Store the reporting code, whatever that is.
    $self[CODE] = $_[_logger];

    return bless \@self, "$_[_class]\::_obj";
}

my $null_eventlog = Devel::Spy::Util->Y(
    Sub::Name::subname( null_eventlog_curry => sub {
        my $f = shift @_;
        return Sub::Name::subname( null_eventlog => sub {
            return $f;
        } );
    } )
);

sub make_null_eventlog {
    return $null_eventlog;
}

sub make_eventlog {

    # C<make_eventlog> returns a closure which appends a new element to a
    # log and returns a closure which appends to the new log entry.
    #
    #   my ( $log, $logger ) = Devel::Spy->make_eventlog;
    #
    #   my $foo = $logger->log( 'A' ); # pushes 'A' onto @$log
    #   $foo = $foo->( 'B' );          # Appends 'B' to 'A'
    #   $foo = $foo->( 'C' );          # Appends 'C' to 'AB'
    #   $foo = $foo->( 'D' );          # Appends 'D' to 'ABC'
    #
    #   my $bar = $logger->log( 1 )    # pushes '1' onto @$log
    #   $bar = $bar->( 2 );            # Appends '2' onto '1'
    #   $bar = $bar->( 3 );            # Appends '3' onto '12'
    #   $bar = $bar->( 4 );            # Appends '4' onto '123'

    my @eventlog;
    my $logger = Sub::Name::subname( EVENT => sub {

        # Add to the event log
        push @eventlog, "@_";

        # Let the caller add more information to this log entry
        # with more information as needed.
        my $followup = \$eventlog[-1];
        return Devel::Spy::Util->Y(
            Sub::Name::subname( eventlog_curry => sub {
                my $f = shift @_;
                Sub::Name::subname( eventlog_followup => sub {
                    $$followup .= "@_";
                    $f;
                } );
            }
        ) );
    } );

    return ( \@eventlog, $logger );
}

my $tattler = Devel::Spy::Util->Y(
    Sub::Name::subname( tattler_curry => sub {
        my $f = shift @_;
        return Sub::Name::subname( tattler => sub {
            local $\        = "\n";
            print for @_;
            return $f;
        } );
    }
) );

sub make_tattler {
    return $tattler;
}

# Include these *after* _compile is compiled because they'll want it available.
use Devel::Spy::_obj;
use Devel::Spy::TieScalar;
use Devel::Spy::TieArray;
use Devel::Spy::TieHash;
use Devel::Spy::TieHandle;

our $DEBUG;

1;

__END__

=head1 NAME

Devel::Spy - Spy on your objects and data

=head1 DESCRIPTION

Devel::Spy is a transparent wrapper over your objects and data. All
accesses are logged. This is useful for instrumenting "black box"
code. You can just look at see what the code used and how it used it.

I used it to find out what attributes and values were being used as
booleans and then wrote tests that fed the "black box" code with
inputs covering all possible combinations. By using Devel::Spy I
didn't have to be an expert in the code I was looking at knew I wasn't
going to overlook any parameters.

=head1 SYNOPSIS

  # Create an event log and function to write to it.
  use Devel::Spy;
  my ( $log, $logger ) = Devel::Spy->make_eventlog();

  # Wrap an object and let a black box do something to it.
  my $obj = Some::Thing->new;
  my $wrapped = Devel::Spy->new( $obj, $logger );
  black_box_function( $obj );

  # Look at what happened.
  for my $event ( @$log ) {
      print "$event\n";
  }

=head1 CLASS METHODS

=over

=item C<< WRAPPED THING = Devel::Spy->new( THING, LOGGING FUNCTION ) >>

Wraps a thing in a transparent proxy object. This is how you
instrument your things.

=item C<< ( ARRAY REF, LOGGING FUNCTION ) = Devel::Spy->make_eventlog >>

Returns an array reference and a logging function. Pass the logging
function into any C<Devel::Spy> object you wish to have use the same
event log.

This is how you can make a shared event log that associates all
actions with their sources.

=item C<< LOGGING FUNCTION = Devel::Spy->make_tattler >>

Returns a plain logging function which just prints to STDOUT or
whatever else is currently selected. Normally I prefer using C<<
->make_eventlog >> because the final output is much nicer but when
there's a bug in Devel::Spy then it's useful to get it to just dump
its operation as it runs.

=item C<< LOGGING FUNCTION = Devel::Spy->make_null_eventlog >>

Returns a null eventlog.

=back

=head1 CAVEATS

This is really funky code. There's a somewhat high concentration of
magic here. It worked on the 5.8.7 and 5.9.3 I tested it on. It might
work as far back as 5.6.0. Or maybe farther back? Try it. Report back.
