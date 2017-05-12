package LWP::UserAgent::Anonymous;

$LWP::UserAgent::Anonymous::VERSION = '0.09';

=head1 NAME

LWP::UserAgent::Anonymous - Interface to anonymous LWP::UserAgent.

=head1 VERSION

Version 0.09

=cut

use strict; use warnings;

use 5.006;
use Clone;
use LWP::Simple;
use Data::Dumper;
use HTTP::Request;
use List::Util qw/shuffle/;
use base qw/LWP::UserAgent Clone/;

=head1 DESCRIPTION

It provides an anonymity to user agent by setting proxy from the pool  of proxies
fetched from L<here|http://www.gatherproxy.com> runtime.

=cut

$| = 1;
our $DEBUG = 0;
our $DEFAULT_RETRY_COUNT = 3;
our $PROXY_SERVER = 'http://www.gatherproxy.com';

=head1 METHODS

=head2 anon_request()

This is simply acts like proxy handler for user agent. It tries to get  hold of a
valid  proxy  server,  if  it can't then it simply takes the standard route. This
method  behaves exactly as method  request()  for LWP::UserAgent  plus  sets  the
proxy for you. You may find it takes little longer than usual to respond.

    use strict; use warnings;
    use HTTP::Request;
    use LWP::UserAgent::Anonymous;

    my $browser  = LWP::UserAgent::Anonymous->new;
    my $request  = HTTP::Request->new(GET=>'http://www.google.com/');
    my $response = $browser->anon_request($request);

=cut

sub anon_request {
    my ($self, $request) = @_;

    my $clone   = $self->clone();
    my $retry   = $DEFAULT_RETRY_COUNT;
    my @proxies = _fetch_proxies();

    if (scalar(@proxies)) {
        _print("INFO: Max retry: [$retry]") if $DEBUG;
        while ($retry > 0 && scalar(@proxies) > 0) {
            my $proxy = shift @proxies;
            if (defined($proxy) && ($proxy =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,6}/)) {
                $self->proxy(['http','ftp'], sprintf("http://%s/", $proxy));
                if ($self->_is_success($proxy)) {
                    return $self->SUPER::request($request);
                }
            }
            $retry--;
        }
    }

    _print('WARN: Unable to get the proxy... going no-proxy route now.') if $DEBUG;
    return $clone->SUPER::request($request);
}

=head2 set_retry()

Set retry count when fetching proxies. By default the count is 3.

    use strict; use warnings;
    use LWP::UserAgent::Anonymous;

    my $browser = LWP::UserAgent::Anonymous->new;
    $browser->set_retry(2);

=cut

sub set_retry {
    my ($self, $count) = @_;

    $DEFAULT_RETRY_COUNT = $count;
}

sub set_debug {
    my ($self, $value) = @_;

    $DEBUG = $value;
}

sub _fetch_proxies {
    my $proxy = [];
    my $file  = get($PROXY_SERVER);
    if (defined $file) {
        for my $record (split /\n/,$file) {
            $record =~ s/^\s+//g;
            if ($record =~ /^gp\./i) {
                if ($record =~ m/\"proxy\_ip\"\:\"(.*?)\".*\"proxy\_port\"\:\"(\d+)\"/i) {
                    push @$proxy, sprintf("%s:%d", $1, $2);
                }
            }
        }
    }

    return shuffle(@$proxy);
}

sub _is_success {
    my ($self, $proxy) = @_;

    my $request  = HTTP::Request->new(GET => 'http://www.google.com');
    my $response = $self->SUPER::request($request);

    return (defined($response) && $response->is_success);
}

# Untested code (trying timeout while checking proxy)
sub __is_success {
    my ($self, $proxy) = @_;

    eval {
        local $SIG{ALRM} = sub { die "Timeout" };
        alarm(20);

        my $request  = HTTP::Request->new(GET => 'http://www.google.com');
        my $response = $self->SUPER::request($request);

        return (defined($response) && $response->is_success);

        alarm(0);
    };

    return 0 if ($@ =~ /^Timeout/);
}

sub _print {
    my ($message) = @_;

    print {*STDOUT} $message, "\n";
}


=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/LWP-UserAgent-Anonymous>

=head1 BUGS

Please report  any  bugs  or feature requests to C<bug-lwp-useragent-anonymous at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-UserAgent-Anonymous>.
I will be notified and then you'll automatically be notified of progress  on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::UserAgent::Anonymous

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-UserAgent-Anonymous>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-UserAgent-Anonymous>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-UserAgent-Anonymous>

=item * Search CPAN

L<http://search.cpan.org/dist/LWP-UserAgent-Anonymous/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of LWP::UserAgent::Anonymous
