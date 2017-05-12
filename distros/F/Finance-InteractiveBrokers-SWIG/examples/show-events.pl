#!/usr/bin/perl
#
#   Finance::InteractiveBrokers::SWIG - List available events
#
#   Copyright (c) 2010-2014 Jason McManus
#
#   List the events required to be overridden by your subclass of
#   Finance::InteractiveBrokers::SWIG::EventHandler
#

use strict;
use warnings;
use vars qw( $VERSION );
BEGIN {
    $VERSION = '0.13';
}
$|=1;

# Ours
use Finance::InteractiveBrokers::SWIG::EventHandler;

###
### Main
###

my @events = Finance::InteractiveBrokers::SWIG::EventHandler::override();

unless( -t STDIN and -t STDOUT )
{
    print "You must override all of these events when subclassing\n".
          "  Finance::InteractiveBrokers::SWIG::EventHandler:\n\n";

    printf "\t%s\n", $_ for( @events );
}

__END__

=pod

=head1 NAME

show-events.pl - List the events required to by overridden when subclassing Finance::InteractiveBrokers::SWIG::EventHandler

=head1 SYNOPSIS

    $ show-events.pl

=head1 DESCRIPTION

This small utility just dumps a list of events that are required to be
overridden when subclassing L<Finance::InteractiveBrokers::SWIG::EventHandler>.

Please see the documentation for
L<Finance::InteractiveBrokers::SWIG::EventHandler> for details on why this
must be done to use this module distribution.

=head1 OPTIONS AND ARGUMENTS

None.

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
