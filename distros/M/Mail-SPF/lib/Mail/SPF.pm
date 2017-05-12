#
# Mail::SPF
# An object-oriented Perl implementation of Sender Policy Framework.
# <http://search.cpan.org/dist/Mail-SPF>
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: SPF.pm 63 2013-07-22 03:52:21Z julian $
#
##############################################################################

package Mail::SPF;

=head1 NAME

Mail::SPF - An object-oriented implementation of Sender Policy Framework

=head1 VERSION

2.009

=cut

use version; our $VERSION = qv('2.009');

use warnings;
use strict;

use Mail::SPF::Server;
use Mail::SPF::Request;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Mail::SPF;

    my $spf_server  = Mail::SPF::Server->new();

    my $request     = Mail::SPF::Request->new(
        versions        => [1, 2],              # optional
        scope           => 'mfrom',             # or 'helo', 'pra'
        identity        => 'fred@example.com',
        ip_address      => '192.168.0.1',
        helo_identity   => 'mta.example.com'    # optional,
                                                #   for %{h} macro expansion
    );

    my $result      = $spf_server->process($request);

    print("$result\n");
    my $result_code     = $result->code;        # 'pass', 'fail', etc.
    my $local_exp       = $result->local_explanation;
    my $authority_exp   = $result->authority_explanation
        if $result->is_code('fail');
    my $spf_header      = $result->received_spf_header;

=head1 DESCRIPTION

B<Mail::SPF> is an object-oriented implementation of Sender Policy Framework
(SPF).  See L<http://www.openspf.org> for more information about SPF.

This class collection aims to fully conform to the SPF specification (RFC
4408) so as to serve both as a production quality SPF implementation and as a
reference for other developers of SPF implementations.

=head1 SEE ALSO

L<Mail::SPF::Server>, L<Mail::SPF::Request>, L<Mail::SPF::Result>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 REFERENCES

=over

=item The SPF project

L<http://www.openspf.org>

=item The SPFv1 specification (RFC 4408)

L<http://www.openspf.org/Specifications>, L<http://tools.ietf.org/html/rfc4408>

=back

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
