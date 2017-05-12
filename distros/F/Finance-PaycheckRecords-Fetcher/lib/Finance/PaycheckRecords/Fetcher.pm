#---------------------------------------------------------------------
package Finance::PaycheckRecords::Fetcher;
#
# Copyright 2013 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 4 Feb 2013
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Fetch paystubs from PaycheckRecords.com
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

our $VERSION = '1.000';
# This file is part of Finance-PaycheckRecords-Fetcher 1.000 (July 12, 2014)

use Carp ();
use File::Slurp ();
use LWP::UserAgent 6 ();        # SSL certificate validation
use URI ();
use URI::QueryParam ();         # part of URI; has no version number
use WWW::Mechanize 1.50 ();     # autocheck on


#=====================================================================


sub new
{
  my ($class, $user, $password) = @_;

  bless {
    username => $user,
    password => $password,
    mech     => WWW::Mechanize->new,
  }, $class;
} # end new

#---------------------------------------------------------------------
# Get a URL, automatically supplying login credentials if needed:

sub _get
{
  my ($self, $url) = @_;

  my $mech = $self->{mech};

  $mech->get($url);

  if ($mech->form_name('Login_Form')) {
    $mech->set_fields(
      userStrId => $self->{username},
      password  => $self->{password},
    );
    $mech->click('Login', 5, 4);
    # If we still see the login form, we must have failed to login properly
    Carp::croak("PaycheckRecords: login failed")
          if $mech->form_name('Login_Form');
  }
} # end _get

#---------------------------------------------------------------------
sub listURL { 'https://www.paycheckrecords.com/in/paychecks.jsp' }


sub available_paystubs
{
  my ($self) = @_;

  $self->_get( $self->listURL );

  my @links = $self->{mech}->find_all_links(
    url_regex => qr!/in/paystub_printerFriendly\.jsp!
  );

  my %stub;

  for my $link (@links) {
    my $url = $link->url_abs;

    $stub{ $url->query_param('date') // die "Expected date= in $url" }
        = $url;
  }

  \%stub;
} # end available_paystubs
#---------------------------------------------------------------------


sub mirror
{
  my ($self) = @_;

  my $mech = $self->{mech};

  my $stubs = $self->available_paystubs;

  my @fetched;

  foreach my $date (sort keys %$stubs) {
    my $fn = "Paycheck-$date.html";
    next if -e $fn;
    $self->_get($stubs->{$date});
    File::Slurp::write_file( $fn, {binmode => ':utf8'}, $mech->content );
    push @fetched, $fn;
  }

  @fetched;
} # end mirror

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

Finance::PaycheckRecords::Fetcher - Fetch paystubs from PaycheckRecords.com

=head1 VERSION

This document describes version 1.000 of
Finance::PaycheckRecords::Fetcher, released July 12, 2014.

=head1 SYNOPSIS

  use Finance::PaycheckRecords::Fetcher;

  my $fetcher = Finance::PaycheckRecords::Fetcher->new(
    $username, $password
  );

  my @fetched = $fetcher->mirror;

=head1 DESCRIPTION

Finance::PaycheckRecords can download paystubs from
PaycheckRecords.com, so you can save them for your records.  You can
use L<Finance::PaycheckRecords> (available separately) to extract
information from the stored paystubs.

=head1 METHODS

=head2 new

  $fetcher = Finance::PaycheckRecords::Fetcher->new(
               $username, $password
             );

This constructor creates a new Finance::PaycheckRecords::Fetcher
object.  C<$username> and C<$password> are your login information for
PaycheckRecords.com.


=head2 available_paystubs

  $paystubs = $fetcher->available_paystubs;

This connects to PaycheckRecords.com and downloads a list of available
paystubs.  It returns a hashref where the keys are paystub dates in
YYYY-MM-DD format and the values are L<URI> objects to the
printer-friendly paystub for that date.

Currently, it lists only the paystubs shown on the initial page after
you log in.  For me, this is the last 6 paystubs.

It throws an error if it is unable to get the list of available
paystubs.  See L</DIAGNOSTICS>.


=head2 mirror

  @new_paystubs = $fetcher->mirror;

This connects to PaycheckRecords.com and downloads all paystubs listed
by C<available_paystubs> that haven't already been downloaded.  It
returns a list of filenames of newly downloaded paystubs, or the empty
list if there are no new paystubs.  Each paystub is saved to the
current directory under the name F<Paycheck-YYYY-MM-DD.html>.  If a
file by that name already exists, then it assumes that paystub has
already been downloaded (and is not included in the return value).

In scalar context, it returns the number of paystubs downloaded.

It throws an error if it is unable to mirror the paystubs.
See L</DIAGNOSTICS>.

=head1 SEE ALSO

L<Finance::PaycheckRecords> can be used to extract information from
the downloaded paystubs.

=head1 DIAGNOSTICS

=over

=item C<< Error GETing %s >>

WWW::Mechanize encountered an error getting the specified URL.

=for Pod::Coverage
listURL


=item C<< Expected date= in %s >>

This indicates that the specified URL does not look like it was
expected to.  Perhaps PaycheckRecords.com has changed their website.
Look for an updated version of Finance::PaycheckRecords::Fetcher.  If
no update is available, report a bug.


=item C<< PaycheckRecords: login failed >>

The fetcher was unable to login to PaycheckRecords.com.  You
probably supplied the wrong username or password to the constructor.


=back

=head1 CONFIGURATION AND ENVIRONMENT

Finance::PaycheckRecords::Fetcher requires no configuration files or environment variables.

=head1 DEPENDENCIES

Finance::PaycheckRecords::Fetcher requires
L<File::Slurp>,
L<LWP::UserAgent> (6 or later),
L<URI>, and
L<WWW::Mechanize> (1.50 or later).

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

L</available_paystubs> is limited to those displayed by default when
you log in to PaycheckRecords.com.  There's currently no way to select
a different date range.  Since L</mirror> uses C<available_paystubs>,
the same limitation applies.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Finance-PaycheckRecords-Fetcher AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Finance-PaycheckRecords-Fetcher >>.

You can follow or contribute to Finance-PaycheckRecords-Fetcher's development at
L<< https://github.com/madsen/finance-paycheckrecords-fetcher >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
