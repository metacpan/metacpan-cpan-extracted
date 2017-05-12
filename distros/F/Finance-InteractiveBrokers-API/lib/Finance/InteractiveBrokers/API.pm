package Finance::InteractiveBrokers::API;
#
#   Finance::InteractiveBrokers::API - Convenience functions for IB API
#
#   Copyright (c) 2010-2013 Jason McManus
#
#   Full POD documentation after __END__
#

use Carp qw( croak confess );
use strict;
use warnings;

###
### Variables
###

use vars qw( @ISA @EXPORT_OK $VERSION $TRUE $FALSE $KEEP $DELETE $REQUIRED );
BEGIN
{
    require Exporter;
    @ISA       = qw( Exporter );
    @EXPORT_OK = qw( api_version );
    $VERSION   = '0.04';
}

*TRUE     = \1;
*FALSE    = \0;
*KEEP     = \0;
*DELETE   = \1;
*REQUIRED = \2;

our %our_args = (
    version => $DELETE | $REQUIRED,
);

# IB API method and event data structures, keyed by version
my $DEFAULT_API_VERSION = '9.64';
my $methods = {};
my $events = {};
my $methods_arr = {
    '9.64' => [
        # Our add-ons
        qw(
            processMessages
            setSelectTimeout
        ),
        # Official API
        # XXX: API Docs and source code differ (I use the source code names):
        #           Docs                C++ headers
        #           -------------------------------------------
        #           reqIDs()            reqIds()
        #           setLogLevel()       setServerLogLevel()
        qw(
            eConnect
            eDisconnect
            isConnected
            reqCurrentTime
            serverVersion
            setServerLogLevel
            checkMessages
            TwsConnectionTime

            reqMktData
            cancelMktData
            calculateImpliedVolatility
            cancelCalculateImpliedVolatility
            calculateOptionPrice
            cancelCalculateOptionPrice

            placeOrder
            cancelOrder
            reqOpenOrders
            reqAllOpenOrders
            reqAutoOpenOrders
            reqIds
            exerciseOptions

            reqAccountUpdates

            reqExecutions

            reqContractDetails

            reqMktDepth
            cancelMktDepth

            reqNewsBulletins
            cancelNewsBulletins

            reqManagedAccts
            requestFA
            replaceFA

            reqHistoricalData
            cancelHistoricalData

            reqScannerParameters
            reqScannerSubscription
            cancelScannerSubscription

            reqRealTimeBars
            cancelRealTimeBars

            reqFundamentalData
            cancelFundamentalData
        ),
    ],
};
$methods_arr->{'9.65'} = $methods_arr->{'9.64'};
$methods_arr->{'9.66'} = [
    @{ $methods_arr->{'9.65'} },
    qw(
        reqMarketDataType
    ),
    # UNDOCUMENTED
    qw(
        reqGlobalCancel
    ),
];
$methods_arr->{'9.67'} = $methods_arr->{'9.66'};

my $events_arr = {
    '9.64' => [
        qw(
            winError
            error
            connectionClosed
            currentTime

            tickPrice
            tickSize
            tickOptionComputation
            tickGeneric
            tickString
            tickEFP
            tickSnapshotEnd

            orderStatus
            openOrder
            nextValidId

            updateAccountValue
            updatePortfolio
            updateAccountTime

            updateNewsBulletin

            contractDetails
            contractDetailsEnd
            bondContractDetails

            execDetails
            execDetailsEnd

            updateMktDepth
            updateMktDepthL2

            managedAccounts
            receiveFA

            historicalData

            scannerParameters
            scannerData
            scannerDataEnd

            realtimeBar

            fundamentalData

            deltaNeutralValidation
        ),
        # These are in the headers, but apparently not documented
        qw(
            openOrderEnd
            accountDownloadEnd
        )
    ],
};
$events_arr->{'9.65'} = $events_arr->{'9.64'};
$events_arr->{'9.66'} = [
    @{ $events_arr->{'9.65'} },
    qw(
        marketDataType
    ),
];
$events_arr->{'9.67'} = [
    @{ $events_arr->{'9.66'} },
    qw(
        commissionReport
    ),
];

# Cram them into a hash for O(1) lookup time
for my $ver ( keys( %$methods_arr ) )
{
    $methods->{$ver} = { map { $_ => 1 } @{ $methods_arr->{$ver} } };
}
for my $ver ( keys( %$events_arr ) )
{
    $events->{$ver}  = { map { $_ => 1 } @{ $events_arr->{$ver} } };
}

###
### Constructor
###

sub new
{
    my( $class, @args ) = @_;
    croak( "$class requires an even number of params" ) if( @args & 1 );

    my $self = {
        version => $DEFAULT_API_VERSION,    # IB API version
    };

    bless( $self, $class );

    my @leftover = $self->initialize( @args );

    # Make sure we received a valid API version
    confess( 'API version \'' . $self->api_version . '\' is unknown;' .
             " usable versions are: " .
             join( ' ', $self->versions ) . "\n" )
        unless( exists( $methods->{$self->api_version} ) );

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

    return( %args );
}

###
### Class methods
###

sub api_versions
{
    return( sort keys( %$methods ) );
}

###
### Methods
###

sub methods
{
    my $self = shift;

    return( @{ $methods_arr->{$self->api_version} } );
}

sub events
{
    my $self = shift;

    return( @{ $events_arr->{$self->api_version} } );
}

sub everything
{
    my $self = shift;

    return( ( ( $self->methods() ), ( $self->events() ) ) );
}

###
### Predicates
###

sub is_method
{
    my( $self, $name ) = ( shift, shift );

    return $FALSE unless( defined( $name ) );

    return( exists( $methods->{$self->api_version}->{$name} )
              ? $TRUE
              : $FALSE );
}

sub is_event
{
    my( $self, $name ) = ( shift, shift );

    return $FALSE unless( defined( $name ) );

    return( exists( $events->{$self->api_version}->{$name} )
              ? $TRUE
              : $FALSE );
}

sub in_api
{
    my( $self, $name ) = ( shift, shift );

    return $FALSE unless( defined( $name ) );

    return( ( $self->is_method( $name ) or $self->is_event( $name ) )
                ? $TRUE
                : $FALSE );
}

###
### Accessors
###

sub api_version
{
    my $self = shift;

    return( $self->{version} );
}

###
### Method aliases
###

no warnings 'once';
*version  = *api_version;
*versions = *api_versions;

1;

__END__

=pod

=head1 NAME

Finance::InteractiveBrokers::API - Convenience functions for working with the InteractiveBrokers API

=head1 SYNOPSIS

    my $ibapi = Finance::InteractiveBrokers::API->new(
        version => '9.64',          # API version
    );

    my @api_versions       = $ibapi->api_versions();
    my @methods            = $ibapi->methods();
    my @events             = $ibapi->events();
    my @events_and_methods = $ibapi->everything();
    my $bool               = $ibapi->is_method( 'reqTickPrice' );
    my $bool2              = $ibapi->is_event( 'currentTime' );
    my $bool3              = $ibapi->in_api( 'anything' );
    my $api_version        = $ibapi->api_version();

=head1 DESCRIPTION

This module describes and enumerates the InteractiveBrokers API through
successive revisions.

It is not very useful on its own, and was designed to be used by
L<Finance::InteractiveBrokers::SWIG> and L<POE::Component::Client::InteractiveBrokers>
to reduce maintenance, by isolating the API description for each revision
into one single location.

This module will ideally be updated each time new versions of the IB API are
released.  If the author gets hit by a bus, there is enough documentation
contained herein to make the changes yourself.

=head1 CONSTRUCTOR

=head2 new()

    my $ibapi = Finance::InteractiveBrokers::API->new(
        version => '9.64',          # API version
    );

Create a new Finance::InteractiveBrokers object.

B<ARGUMENTS:>

B<version =E<gt> $scalar> [ Default: C<9.64> ]

The API version you wish to refer to.

B<RETURNS:> blessed C<$object>, or C<undef> on failure.

=head2 initialize()

    my %leftover = $self->initialize( %ARGS );

Initialize the object.  If you are subclassing, override this, not L</new()>.

B<ARGUMENTS:> C<%HASH> of arguments passed into L</new()>

B<RETURNS:> C<%HASH> of any leftover arguments.

=head1 METHODS

=head2 api_versions()

    my @api_versions = $ibapi->api_versions();

Get a list of all API versions that can be described by this module.

B<ARGUMENTS:> None.

B<RETURNS:> C<@ARRAY> of API versions.

NOTE: C<api_versions()> also works as a class method, and can be I<optionally> imported via:

    use Finance::InteractiveBrokers::API qw( api_versions );

=head2 versions()

An alias for L</api_versions()>.

=head2 methods()

    my @methods = $ibapi->methods();

Get a list of methods in the constructor-specified version of the API.

B<ARGUMENTS:> None.

B<RETURNS:> C<@ARRAY> of all API method names in this version.

=head2 events()

    my @events = $ibapi->events();

Get a list of events in the constructor-specified version of the API.

B<ARGUMENTS:> None.

B<RETURNS:> C<@ARRAY> of all API events in this version.

=head2 everything()

    my @events_and_methods = $ibapi->everything();

Get a list of both methods and events in the constructor-specified version of the API.

B<ARGUMENTS:> None.

B<RETURNS:> C<@ARRAY> of all API methods and events in this version.

=head2 is_method()

    my $bool = $ibapi->is_method( 'reqTickPrice' );

Check if a named method exists in the constructor-specified version of the API.

B<ARGUMENTS:>

B<$method_name>

The method name you wish to query.

B<RETURNS:> TRUE or FALSE (well, 1 or 0).

=head2 is_event()

    my $bool = $ibapi->is_event( 'currentTime' );

Check if a named event exists in the constructor-specified version of the API.

B<ARGUMENTS:>

B<$event_name>

The event name you wish to query.

B<RETURNS:> TRUE or FALSE (well, 1 or 0).

=head2 in_api()

    my $bool = $ibapi->in_api( 'anything' );

Check if a named method or event exists in the constructor-specified version of the API.  Probably useless; just here for completeness.

B<ARGUMENTS:>

B<$name>

The method or event name you wish to query.

B<RETURNS:> TRUE or FALSE (well, 1 or 0).

=head2 api_version()

    my $ibapi       = Finance::InteractiveBrokers::API->new( version => '9.64' );
    my $api_version = $ibapi->api_version();     # will return 9.64

Get the API version described by this object instance.

B<ARGUMENTS:> None.

B<RETURNS:> The API version as a string (e.g. C<'9.64'>).

=head2 version()

An alias for L</api_version()>.

=head1 SEE ALSO

L<Alien::InteractiveBrokers>

L<POE::Component::Client::InteractiveBrokers>

L<Finance::InteractiveBrokers::SWIG>

L<Finance::InteractiveBrokers::Java>

The L<POE> documentation, L<POE::Kernel>, L<POE::Session>

L<http://poe.perl.org/> - All about the Perl Object Environment (POE)

L<http://www.interactivebrokers.com/> - The InteractiveBrokers website

L<http://www.interactivebrokers.com/php/apiUsersGuide/apiguide.htm> - The IB API
 documentation

=head1 AUTHORS

Jason McManus, C<< <infidel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-finance-interactivebrokers-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-InteractiveBrokers-API>.  The authors will be notified, and then you'll
automatically be notified of progress on your bug as changes are made.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::InteractiveBrokers::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-InteractiveBrokers-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-InteractiveBrokers-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-InteractiveBrokers-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-InteractiveBrokers-API/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2013 Jason McManus

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
