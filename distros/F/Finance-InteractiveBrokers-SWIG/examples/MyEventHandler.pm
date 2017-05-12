package MyEventHandler;
#
#   Finance::InteractiveBrokers::SWIG - Demonstration event handler subclass
#
#   Copyright (c) 2010-2014 Jason McManus
#
#   To use this module:
#
#     Insert your code into the event handler subroutine skeletons.  These
#     will be triggered upon receiving the responses from the IB server,
#     at the appropriate times, according to their API documentation.
#
#     Fill them to do whatever you need to do to react to the event, e.g.
#     store data into a database, set a flag, execute a trade, etc.
#
#   NOTE: You /should/ double-check to make sure that all of the events
#     subroutines exist for the version of the API you compiled against.
#
#     You can get a list of events by typing:
#       
#       perl -MFinance::InteractiveBrokers::SWIG::EventHandler -e'print Finance::InteractiveBrokers::SWIG::EventHandler::override'
#
#     at your shell prompt.
#
#     Since IB updates its API regularly, if you compile against a newer
#     version, it's possible that some events may not be caught below, at
#     which point you will receive an exception that looks like:
#
#       Finance::InteractiveBrokers::SWIG::EventHandler::EVENTNAME method
#          must be overridden
#        at line ....
#

use Carp qw( croak confess );
use Data::Dumper;
use strict;
use warnings;
use vars qw( $VERSION );
BEGIN {
    $VERSION = '0.13';
}

# Ours
use base qw( Finance::InteractiveBrokers::SWIG::EventHandler );

###
### Event handlers
###
### These will be called by Finance::InteractiveBrokers::SWIG when it
### receives the specified event from the server.  They will be called
### with their arguments in the same order as in the IB API documentation.
###
### Only a few methods are filled in for you, but this class will
### operate as a proper handler, and simply discard the events sent to
### the empty subs.  It is up to you to fill them in.
###
### Please see the InteractiveBrokers API documentation regarding EWrapper
### for a full description and list of arguments for each method.
###

#
# Connection and Server
#
sub winError
{
    my( $self, $str, $lastError ) = @_;

    print "Client Error $lastError: $str\n";

    return;
}

sub error
{
    my( $self, $id, $errorCode, $errorString ) = @_;

    if( $errorCode >= 1100 )
    {
        print "Server Message: code $errorCode: $errorString\n";
    }
    else
    {
        print "Server Error: ReqID $id; code $errorCode: $errorString\n";
    }

    return;
}

sub connectionClosed
{
    print "Connection closed.\n";

    return;
}

sub currentTime
{
    my( $self, $time ) = @_;

    printf "Current time on IB server is: %s\n", scalar gmtime( $time );

    return;
}

#
# Market Data
#

# Docs here:
# https://www.interactivebrokers.com/en/software/api/apiguide/c/tickprice.htm
sub tickPrice
{
    my( $self, $reqId, $tickType, $price, $canAutoExecute ) = @_;

    printf "tickPrice for reqId %d: type %d, price %.04f, autoexecute? %s\n",
           $reqId,
           $tickType,
           $price,
           ( $canAutoExecute ? 'Yes' : 'No' );

    return;
}
sub tickSize
{
    my $self = shift;

    print "tickSize event; contains the following data:\n";
    print Dumper \@_;

    return;
}
sub tickOptionComputation
{
    print "tickOptionComputation\n", Dumper \@_;
}
sub tickGeneric
{
    print "tickGeneric\n", Dumper \@_;
}

sub tickString
{
    my $self = shift;

    print "tickString event; contains the following data:\n";
    print Dumper \@_;

    return;
}

sub tickEFP
{
    print "tickEFP\n", Dumper \@_;
}

sub tickSnapshotEnd
{
    my( $self, $reqId ) = @_;

    print "tickSnapshotEnd for reqID $reqId\n"; 

    return;
}

# IB API >= v9.66
sub marketDataType
{}

#
# Orders
#
sub orderStatus
{}
sub openOrder
{}
sub nextValidId
{}

#
# Account and Portfolio
#
sub updateAccountValue
{}
sub updatePortfolio
{}
sub updateAccountTime
{}

#
# News Bulletins
#
sub updateNewsBulletin
{}

#
# Contract Details
#
sub contractDetails
{}
sub contractDetailsEnd
{}
sub bondContractDetails
{}

#
# Executions
#
sub execDetails
{}
sub execDetailsEnd
{}
# IB API >= 9.67
sub commissionReport
{}

#
# Market Depth
#
sub updateMktDepth
{}
sub updateMktDepthL2
{}

#
# Financial Advisors
#
sub managedAccounts
{}
sub receiveFA
{}

# 
# Historical Data
#
sub historicalData
{
    print "historicalData\n", Dumper \@_;
}

#
# Market Scanners
#
sub scannerParameters
{}
sub scannerData
{}
sub scannerDataEnd
{}

#
# Real Time Bars
#
sub realtimeBar
{}

#
# Fundamental Data
#
sub fundamentalData
{}

#
# This has something to do with RFQs
#
sub deltaNeutralValidation
{}

#
# These are in the C++ headers, but not documented in the IB API docs.
#
sub openOrderEnd
{}
sub accountDownloadEnd
{}

1;

__END__

=pod

=head1 NAME

MyEventHandler - Sample Finance::InteractiveBrokers::SWIG::EventHandler subclass

=head1 DESCRIPTION

You may this module as a starter when building your required subclass of
L<Finance::InteractiveBrokers::SWIG::EventHandler>.  It is well-commented,
and guides you through the process.

Please see the documentation for
L<Finance::InteractiveBrokers::SWIG::EventHandler> for details on why this
must be done to use this module distribution.

=head1 SEE ALSO

L<Finance::InteractiveBrokers::SWIG>

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
