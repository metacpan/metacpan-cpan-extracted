package Finance::InteractiveBrokers::SWIG::EventHandler;
#
#   Finance::InteractiveBrokers::SWIG - Event handler base class
#
#   Copyright (c) 2010-2014 Jason McManus
#
#   Full POD documentation after __END__
#

use Carp qw( croak confess );
use Data::Dumper;
use strict;
use warnings;

# Ours
use Finance::InteractiveBrokers::API;
use Finance::InteractiveBrokers::SWIG::IBAPI;

###
### Variabless
###

use vars qw( $VERSION $TRUE $FALSE $KEEP $DELETE $REQUIRED $AUTOLOAD );
BEGIN {
    $VERSION   = '0.13';
}

*TRUE      = \1;
*FALSE     = \0;
*KEEP      = \0;
*DELETE    = \1;
*REQUIRED  = \2;

our $API_VERSION = Finance::InteractiveBrokers::SWIG::IBAPI::api_version();

our %our_args = (
);

###
### Constructor
###

sub new
{
    my( $class, @args ) = @_;
    croak( "$class is an abstract base class and must be subclassed" )
        if( $class eq 'Finance::InteractiveBrokers::SWIG::EventHandler' );
    croak( "$class requires an even number of params" )
        if( @args & 1 );

    my $self = {
        api_version => $API_VERSION,            # Compiled IB API version
        api         => undef,                   # F::IB::API object
    };

    bless( $self, $class );

    my @leftover = $self->initialize( @args );

    # Set up an API object so we can look up what's callable
    $self->{api} =
       Finance::InteractiveBrokers::API->new( version => $self->api_version() );

    # Sneakily predeclare the IB API methods so they're callable
    my @EVENTS = $self->_api->events();
    eval 'use subs ( @EVENTS );';
    # TODO: Check $@ here

    return( $self );
}

# When subclassing, override this (if desired), not new()
sub initialize
{
    my( $self, %args ) = @_;

    # Cycle through the args, grab what's for us, and delete if appropriate
    for( keys( %args ) )
    {
        if( exists( $our_args{lc $_} ) )
        {
            $self->{lc $_} = $args{$_};
            delete( $args{$_} )
                if( $our_args{lc $_} & $DELETE );
        }
    }

    # Check all required args
    for( keys( %our_args ) )
    {
        if( $our_args{$_} & $REQUIRED )
        {
            confess( "$_ is a required argument" )
                if( ( not exists $self->{lc $_} ) or
                    ( not defined $self->{lc $_} ) );
        }
    }

    return( %args );
}

# Manually define DESTROY sub so it's not handled by AUTOLOAD
sub DESTROY {}

###
### Class methods
###

# List of event handler methods that must be overridden
sub override
{
    my $version = $API_VERSION;

    # Try to get the event list
    my @events = eval {
        Finance::InteractiveBrokers::API->new( version => $version )->events();
    };

    # Version was valid, show the events
    if( -t STDIN and -t STDOUT ) {
        print "Methods required to be overridden for API version $version:\n";
        print "    $_\n" for( @events );
    }

    return( @events ) unless( -t STDIN and -t STDOUT );
    return;
}

###
### Methods
###

# AUTOLOAD hax to cover all subs in the correct API version
sub AUTOLOAD
{
    my $self = shift;
    my( $event ) = $AUTOLOAD =~ m/.*?:?(\w*)$/;

    if( $self->_api->is_event( $event ) )
    {
        confess( __PACKAGE__ . "::$event method must be overridden\n " );
    }
    else
    {
        confess( ref( $self ) . " received invalid event $event( @_ )" );
    }
}

###
### Accessors
###

# XXX: DON'T redirect this to query the API object
sub api_version
{
    my $self = shift;

    return( $self->{api_version} );
}

sub _api
{
    my $self = shift;

    return( $self->{api} );
}

1;

__END__

=pod

=head1 NAME

Finance::InteractiveBrokers::SWIG::EventHandler - Event Handler base class

=head1 SYNOPSIS

Create a subclass of this class:

    package MyEventHandler;

    use base qw( Finance::InteractiveBrokers::SWIG::EventHandler );
    use strict;
    use warnings;

    my $handler = MyEventHandler->new();

    sub currentTime {
        # Do something with received time
    }

    # ...

Then, pass your C<$handler> object into L<Finance::InteractiveBrokers::SWIG/"new()">.

=head1 DESCRIPTION

This module is designed as a base class for catching the events that the
InteractiveBrokers API returns.

It is required to be subclassed with the event handler methods filled in,
to trap the returned events so you can do something with them (e.g. save
into a database, analyze, etc).

An object of your subclass should be instantiated, and passed in as an
argument to L<Finance::InteractiveBrokers::SWIG/"new">.

There is a well-commented example subclass in the F<examples/> directory of
this module's distribution, on which you must base your subclass.

=head1 CONSTRUCTOR

=head2 new()

    my $handler = MyEventHandler->new();

B<ARGUMENTS:> None.

B<RETURNS:> blessed C<$object>, or C<undef> on failure.

=head2 initialize()

    my %leftover = $self->initialize( %ARGS );

Initialize the object.  When subclassing, override this (if desired),
not L</new()>.

B<ARGUMENTS:> C<%HASH> of arguments passed into L</new()>

B<RETURNS:> C<%HASH> of any leftover arguments.

=head1 METHODS

=head2 override()

    my @api_methods = $handler->override();

or

    my @api_methods =
        Finance::InteractiveBrokers::SWIG::EventHandler::override();

Get a list of IB API events that you I<MUST> override in your subclass.  These
correspond 1:1 to events in the IB API, but they are dynamically dispatched,
so you will not find C<sub> definitions in the source.

B<ARGUMENTS:> None.

B<RETURNS:> C<@ARRAY> of IB API events that must be overridden.

B<NOTE:> You can also get a list of them from the command line, via:

    perl -MFinance::InteractiveBrokers::SWIG::EventHandler -e'print Finance::InteractiveBrokers::SWIG::EventHandler::override'

=head2 api_version()

    my $version = $handler->api_version();

Get the IB API version this module was compiled against.

B<RETURNS:> C<$scalar> containing the version as a string, something like '9.64'.

=head1 THE INTERACTIVE BROKERS API

The IB API is not described in this documentation.  You should refer to
their website (L</"SEE ALSO">) for notes on how to use it and what methods
and events are available.

=head1 SEE ALSO

L<Finance::InteractiveBrokers::SWIG>

L<Alien::InteractiveBrokers>

L<POE::Component::Client::InteractiveBrokers>

L<Finance::InteractiveBrokers::API>

L<Finance::InteractiveBrokers::Java>

L<http://www.swig.org/> - SWIG, the Simplified Wrapper and Interface Generator

The L<POE> documentation, L<POE::Kernel>, L<POE::Session>

L<http://poe.perl.org/> - All about the Perl Object Environment (POE)

L<http://www.interactivebrokers.com/> - The InteractiveBrokers website

L<https://www.interactivebrokers.com/en/software/api/api.htm> - The IB API documentation

The F<examples/> directory of this module's distribution

=head1 AUTHORS

Jason McManus, C<< <infidel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-finance-interactivebrokers-swig at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-InteractiveBrokers-SWIG>.  The authors will be notified, and then you'll
automatically be notified of progress on your bug as changes are made.

If you are sending a bug report, please include:

=over 4

=item * Your OS type, version, Perl version, and other similar information.

=item * The version of Finance::InteractiveBrokers::SWIG you are using.

=item * The version of the InteractiveBrokers API you are using.

=item * If possible, a minimal test script which demonstrates your problem.

=back

This will be of great assistance in troubleshooting your issue.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::InteractiveBrokers::SWIG

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-InteractiveBrokers-SWIG>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-InteractiveBrokers-SWIG>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-InteractiveBrokers-SWIG>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-InteractiveBrokers-SWIG/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2014 Jason McManus

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

The authors are not associated with InteractiveBrokers, and as such, take
no responsibility or provide no warranty for your use of this module or the
InteractiveBrokers service.  You do so at your own responsibility.  No
warranty for any purpose is either expressed or implied by your use of this
module suite.

The data from InteractiveBrokers are under an entirely separate license that
varies according to exchange rules, etc.  It is your responsibility to
follow the InteractiveBrokers and exchange license agreements with the data.

=cut

# END
