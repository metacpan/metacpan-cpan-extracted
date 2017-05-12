package Finance::InteractiveBrokers::SWIG;
#
#   Finance::InteractiveBrokers::SWIG - InteractiveBrokers C++ connector
#
#   Copyright (c) 2010-2014 Jason McManus
#
#   Full POD documentation after __END__
#

use Data::Dumper;
use Carp qw( croak confess longmess );
use Socket qw( inet_ntoa inet_aton );
use Net::hostent ();
use strict;
use warnings;

# Ours
use Finance::InteractiveBrokers::API 0.04;      # another package
use Finance::InteractiveBrokers::SWIG::IBAPI;   # SWIG module

###
### Variables
###

use vars qw( $VERSION $AUTOLOAD $TRUE $FALSE $KEEP $DELETE $REQUIRED );
BEGIN {
    $VERSION  = '0.13';
}

*TRUE     = \1;
*FALSE    = \0;
*KEEP     = \0;
*DELETE   = \1;
*REQUIRED = \2;

my %our_args = (
    handler       => $DELETE | $REQUIRED,         # event handler object
    '__testing__' => $DELETE,                     # Set to true if testing
);

our $API_VERSION = Finance::InteractiveBrokers::SWIG::IBAPI::api_version();

# XXX: This class variable is janky, but necessary to receive callbacks.
# Shouldn't matter, since we should only need one instance.
my $HANDLER;

###
### Constructor
###

sub new
{
    my( $class, @args ) = @_;
    confess( "$class requires an even number of params" ) if( @args & 1 );

    my $self = {
        handler     => undef,       # event handler object
        api         => undef,       # F::IB::API object reference
        ibclient    => undef,       # F::IB::SWIG::IBAPI SWIG object
    };

    bless( $self, $class );

    my @leftover = $self->initialize( @args );

    # Set the global handler class variable
    $HANDLER = $self->_handler();

    # Set up a ref to the API so we can see what's callable
    $self->{api} = $self->_handler()->_api();

    # Sneakily predeclare the IB API methods so they're callable
    my @METHODS = $self->_api()->methods();
    eval 'use subs ( @METHODS );';
    # TODO: Check $@ here

    # Finally, instantiate the SWIG interface
    $self->{ibclient} =
              Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient->new()
        unless( $self->_is_testing() );

    return( $self );
}

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

    # Make sure 'handler' implements the correct interface
    confess( 'handler ' . ref( $self->_handler() ) . ' must be subclass' .
             ' of Finance::InteractiveBrokers::SWIG::EventHandler' )
        unless( $self->_handler()->isa(
                    'Finance::InteractiveBrokers::SWIG::EventHandler'
                ) );

    return( %args );
}

# Manually define DESTROY sub so it's not handled by AUTOLOAD
sub DESTROY {}

###
### Class methods
###

# Entry point for callbacks from C++
sub _event_dispatcher
{
    my $method = shift;
    $method = shift if( ref( $method ) );

    #print "In SWIG::_event_dispatcher for $method\n";
    my $retval = eval {
        $HANDLER->$method( @_ );
    };

    # croak() here; calling confess() double-displays the call stack
    croak( "Call dispatch for $method failed with: $@" )
        if( $@ );

    return( $retval );
}

# Print list of IB API methods callable from this class
sub api_methods
{
    my $version = $API_VERSION;

    # Try to get the methods list
    my @methods = eval {
        Finance::InteractiveBrokers::API->new( version => $version )->methods();
    };

    # Version was valid, show the methods
    if( -t STDIN and -t STDOUT ) {
        print "InteractiveBrokers API methods callable for API version $version:\n";
        print "    $_\n" for( @methods );
    }

    return( @methods ) unless( -t STDIN and -t STDOUT );
    return;
}

# Do DNS resolution on whatever is passed in
sub _resolve_host
{
    my $whatever = shift;
    my( $hostname, @addresses );

    if( my $hent = Net::hostent::gethost( $whatever ) )
    {
        $hostname  = $hent->name;
        @addresses = map { inet_ntoa( $_ ) } @{ $hent->addr_list };
    }

    return( $hostname, @addresses );
}


###
### Methods
###

# Wrap eConnect to add DNS resolution and IP cycling
sub eConnect
{
    my $self = shift;

    # Skip if we're testing
    return( @_ ) if( $self->_is_testing() );

    # Grab the rest of the args
    my( $host, $port, $client_id ) = @_;

    # Resolve the hostname
    my( $hostname, @addresses ) = _resolve_host( $host );
    confess( "Cannot resolve '$host' to IP" )
        unless( @addresses );

    # Dispatch to the SWIG API to connect
    my $connected;
    for my $ip_address ( @addresses )
    {
        $connected = $self->_ibclient->eConnect( $ip_address,
                                                 $port,
                                                 $client_id );
        last if( $connected );
    }

    return( $connected );
}

# Dispatch all the other methods dynamically
sub AUTOLOAD
{
    my $self = shift;
    my( $method ) = $AUTOLOAD =~ m/.*?:?(\w*)$/;

    if( $self->_api->is_method( $method ) )
    {
#        print ref( $self ) . ": method call OK: $method( @_ )";

        # Skip the calls if we're testing
        return( @_ ) if( $self->_is_testing() );

        # dispatch the call to the SWIG API
        $self->_ibclient->$method( @_ )
    }
    else
    {
        confess( ref( $self ) . ": invalid method $method( @_ ) called" );
    }
}


###
### Accessors
###

sub api_version
{
    my $self = shift;

    return( $self->_api()->version() );
}

sub _ibclient
{
    my $self = shift;

    return( $self->{ibclient} );
}

sub _handler
{
    my $self = shift;

    return( $self->{handler} );
}

sub _api
{
    my $self = shift;

    return( $self->{api} );
}

sub _is_testing
{
    my $self = shift;

    return( $self->{__testing__} ? $TRUE : $FALSE );
}

1;

__END__

=pod

=head1 NAME

Finance::InteractiveBrokers::SWIG - InteractiveBrokers API C++ wrapper and connector

=head1 SYNOPSIS

Create an object as a subclass of L<Finance::InteractiveBrokers::SWIG::EventHandler>:

    my $handler = MyEventHandler->new();

Then:

    my $ib = Finance::InteractiveBrokers::SWIG->new(
        handler => $handler,    # Your subclassed event handler
    );

    $ib->eConnect();
    $ib->reqCurrentTime();

    # Your event loop here
    $ib->processMessages()
        while( $ib->isConnected() );

    # And eventually...
    $ib->eDisconnect();

See the F<examples/> directory in this distribution for more complete and
well-commented examples.

=head1 DESCRIPTION

This module provides Perl connectivity to the InteractiveBrokers market data
and program trading service, using the IB-provided C++ code.  It is primarily
intended to be used with L<POE::Component::Client::InteractiveBrokers>, which
provides a better API, but may be used standalone if desired, by referring
to the IB documentation itself (under L</"SEE ALSO">).

It is a very complex module with an involved build process, and as such, you
should read this documentation thoroughly before building or using this
module distribution.

=head1 HOW IT WORKS

The InteractiveBrokers API is available as either a set of C++ or Java
source files.  This module builds a library from this, and then runs SWIG
(the Simplified Interface Wrapper and Generator) against it to provide
Perl connectivity.

The API consists of several methods, callable from this module, as well
as several events, containing the asynchronous responses from IB to
event handlers you have created.

In order to catch the events, you must subclass
L<Finance::InteractiveBrokers::SWIG::EventHandler>, and override all of
the events therein with your own code to handle their responses (e.g.
save them to a database, or do whatever).

You then pass your C<$handler> into L</"new()">, and you will have complete
access to the IB API, delegated via XS through the C++ library.

=head1 PREREQUISITES

You must have the following to build and use this module:

=over 4

=item * L<Finance::InteractiveBrokers::API>

Provides a programmatic means of looking up methods and events in the IB API.

=item * A working build environment

Capable of compiling C and C++ files, and running 'make'.

=item * SWIG >= 1.3.28

The "Simplified Wrapper and Interface Generator", capable of building SWIG
interfaces.  This module has been tested with SWIG versions 1.3.28 - 2.0.1.

=back

And optional, but I<highly> recommended:

=over 4

=item * L<Alien::InteractiveBrokers>

Installs (downloading if necessary) the InteractiveBrokers API files,
and provides I<Perl>-y mechanisms for locating them.

=back

You can find links to SWIG and the IB API in L</"SEE ALSO">.

=head1 CONSTRUCTOR

=head2 new()

    my $ib = Finance::InteractiveBrokers::SWIG->new(
        handler => $handler,    # Subclassed F::IB::SWIG::EventHandler object 
    );

B<ARGUMENTS:>

B<handler =E<gt> $handler> [ B<REQUIRED> ]

This must be an instantiated object that is a subclass of
L<Finance::InteractiveBrokers::SWIG::EventHandler>.  It is delegated to when
receiving events from the IB service.

Please see L<Finance::InteractiveBrokers::SWIG::EventHandler> for notes on
how to subclass it, and the F<examples/> directory of this distribution.

B<RETURNS:> blessed C<$object>, or C<undef> on failure.

=head2 initialize()

    my %leftover = $self->initialize( %ARGS );

Initialize the object.  If you are subclassing, override this, not L</new()>.

B<ARGUMENTS:> C<%HASH> of arguments passed into L</new()>

B<RETURNS:> C<%HASH> of any leftover arguments.

=head1 METHODS

=head2 api_methods()

    my @api_methods = $ib->api_methods();

or

    my @api_methods = Finance::InteractiveBrokers::SWIG::api_methods();

Get a list of IB API methods you can call from this class.  These correspond
1:1 to the IB API methods, but they are dynamically dispatched, so you won't
find actual C<sub> definitions for them in the source.

B<ARGUMENTS:> None.

B<RETURNS:> C<@ARRAY> of callable IB API methods.

B<NOTE:> You can also get a list of them from the command line, via:

    perl -MFinance::InteractiveBrokers::SWIG -e'print Finance::InteractiveBrokers::SWIG::api_methods'

=head2 eConnect()

Small wrapper around the IB API eConnect() call to add DNS resolution.
See L</"INTERACTIVE BROKERS API"> for full information on how to use the
IB API.

=head2 api_version()

    my $version = $ib->api_version();

Get the IB API version this module was compiled against.

B<RETURNS:> C<$scalar> containing the version as a string, something like
C<'9.64'>.

=head1 INTERACTIVE BROKERS API

The IB API is not described in this documentation.  You should refer to
their website (L</"SEE ALSO">) for notes on how to use it and what methods
and events are available.

=head1 SEE ALSO

L<Finance::InteractiveBrokers::SWIG::EventHandler>

L<Alien::InteractiveBrokers>

L<POE::Component::Client::InteractiveBrokers>

L<Finance::InteractiveBrokers::API>

L<Finance::InteractiveBrokers::Java>

L<http://www.swig.org/> - SWIG, the Simplified Wrapper and Interface Generator

The L<POE> documentation, L<POE::Kernel>, L<POE::Session>

L<http://poe.perl.org/> - All about the Perl Object Environment (POE)

L<http://www.interactivebrokers.com/> - The InteractiveBrokers website

L<https://www.interactivebrokers.com/en/software/api/api.htm> - The IB API documentation

The F<examples/> directory of this module's distribution.

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
