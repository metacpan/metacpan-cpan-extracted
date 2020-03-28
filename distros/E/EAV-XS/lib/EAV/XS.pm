=pod

=encoding utf-8

=head1 NAME

EAV::XS - Email Address Validator

=head1 SYNOPSIS

    use EAV::XS;

    my $eav = EAV::XS->new();

    if ($eav->is_email ('valid@example.com')) {
        print "This is a valid email address.\n";
    } else {
        printf "The email address is not valid: %s\n",
                $eav->get_error();
    }

=head1 DESCRIPTION

The purpose of this module is a validation of the specified
L<Email Address|https://en.wikipedia.org/wiki/Email_address>.

The core part of the module is written in C and can be
found in the B<libeav> directory.

The module conforms to:

=over 4

=item *

L<RFC 822|https://tools.ietf.org/html/rfc822>
- allows control characters.

=item *

L<RFC 5321|https://tools.ietf.org/html/rfc5321>
- does not allow any control characters.

=item *

L<RFC 5322|https://tools.ietf.org/html/rfc5322>
- allows some control characters and not allows SPACE and TAB
characters without quoted-pairs.

=item *

L<RFC 6531|https://tools.ietf.org/html/rfc6531>
- allows Internationalized Email Addresses encoded in UTF-8.
See also L<RFC 3629|https://tools.ietf.org/html/rfc3629>).
The B<RFC 6531> is based on the rules of the B<RFC 5321>.

=back

You may change the behavior of the B<RFC 6531> mode when
building the module and enable support of the
L<RFC 20|https://tools.ietf.org/html/rfc20> and
L<RFC 5322|https://tools.ietf.org/html/rfc5322>.
By default, neither B<RFC 5322> nor B<RFC 20> is enabled.

The B<RFC 20> disallows the next characters within local-part:
C<`>, C<#>, C<^>, C<{>, C<}>, C<~> and C<|>.
They must be in double-quotes.

The default behavior of the module also includes
the check of:

=over 4

=item *

Special and Reserved domains as mentioned
in L<RFC 6761|https://tools.ietf.org/html/rfc6761>

=item *

FQDN - if the domain contains only alias and it is not
a special or reserved domain, then the result is negative,
that is, such an email address is considered as invalid.

=item *

TLD - the module checks that domain is a Top Level Domain (TLD).
The list of TLDs has been taken from IANA's
L<Root Zone Database|https://www.iana.org/domains/root/db>.
See the L</"TLD INFORMATION"> section below for details.

=back

=cut

package EAV::XS;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    RFC822
    RFC5321
    RFC5322
    RFC6531
    TLD_INVALID
    TLD_NOT_ASSIGNED
    TLD_COUNTRY_CODE
    TLD_GENERIC
    TLD_GENERIC_RESTRICTED
    TLD_INFRASTRUCTURE
    TLD_SPONSORED
    TLD_TEST
    TLD_SPECIAL
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ();

our $VERSION = "0.4.4";

require XSLoader;
XSLoader::load('EAV::XS', $VERSION);

# RFC specification
use constant RFC822     => 0x00000000;
use constant RFC5321    => 0x00000001;
use constant RFC5322    => 0x00000002;
use constant RFC6531    => 0x00000003;

# allow_tld: this types of TLDs considered as OK
use constant TLD_INVALID            => 0x00000002;
use constant TLD_NOT_ASSIGNED       => 0x00000004;
use constant TLD_COUNTRY_CODE       => 0x00000008;
use constant TLD_GENERIC            => 0x00000010;
use constant TLD_GENERIC_RESTRICTED => 0x00000020;
use constant TLD_INFRASTRUCTURE     => 0x00000040;
use constant TLD_SPONSORED          => 0x00000080;
use constant TLD_TEST               => 0x00000100;
use constant TLD_SPECIAL            => 0x00000200;

1;
__END__

=head1 DEPENDENCIES

You have to install one of IDN libraries on your choice:

=over 4

=item *

L<libidn2|https://github.com/libidn/libidn2>

=item *

L<libidn|https://www.gnu.org/software/libidn/>

=item *

L<libidnkit|https://jprs.co.jp/idn/index-e.html>

=back

When run Makefile.PL, you will be asked to configure EAV::XS and
at this stage you may select the IDN library to build with.

B<Makefile.PL> requirements:

=over 4

=item *

L<ExtUtils::MakeMaker> B<5.62> or newer

=item *

L<ExtUtils::PkgConfig> B<1.16> or newer

=back

=head1 METHODS

=over 4

=item *

$eav = B<new> ( [%options] )

Creates a new EAV::XS object, if something goes wrong a message will
be thrown via croak().

Possible options includes:

=over 4

=item *

B<rfc> - use this RFC specification. Possible values are: I<RFC822>, 
I<RFC5321>, I<RFC5322> or I<RFC6531>. Default is I<RFC6531>.

=item *

B<tld_check> - enable or disable TLD check. Also, this controls FQDN check.
Enabled by default.

=item *

B<allow_tld> - list of TLD types which considered be good. You have to
specify this list via logical OR ("|"). Information about possible
values described below in section L</"TLD INFORMATION">.

Default value is: I<TLD_COUNTRY_CODE> | I<TLD_GENERIC> | 
I<TLD_GENERIC_RESTRICTED> |
I<TLD_INFRASTRUCTURE> |
I<TLD_SPONSORED> |
I<TLD_SPECIAL>.

=back

=item *

$yes_no = B<is_email> ( $email )

Validates the specified email. Returns true if the email
is valid, otherwise returns false.

=item *

$error_message = B<get_error> ()

Returns an error message for the last email address tested
by B<is_email()> method.

=item *

$lpart = B<get_lpart> ()

Returns local-part of the email B<after> the B<is_email> method call.
If the email address is invalid, then B<get_lpart> returns nothing.

=item *

$domain = B<get_domain> ()

Returns domain-part of the email B<after> the B<is_email> method call.
If the email address is invalid, then B<get_domain> returns nothing.
The returned value $domain could be an IPv4 address either IPv6 one,
depending on the specified email address passed to B<is_email> ().

=item *

$bool = B<get_is_ipv4> ()

Returns whether or not the domain-part of the email contains an IPv4
address, B<after> the B<is_email> method call.
If the email address is invalid, then B<get_is_ipv4> returns false.

=item *

$bool = B<get_is_ipv6> ()

Returns whether or not the domain-part of the email contains an IPv6
address, B<after> the B<is_email> method call.
If the email address is invalid, then B<get_is_ipv6> returns false.

=item *

$bool = B<get_is_domain> ()

Returns whether or not the domain-part of the email contains an domain
name, B<after> the B<is_email> method call.
If the email address is invalid, then B<get_is_domain> returns false.

=back

=head2 TLD INFORMATION

The current list of all TLDs can be found on
L<IANA Root Zone Database|https://www.iana.org/domains/root/db> website.

The B<allow_tld> option accepts the next values:

=over 4

=item *

TLD_NOT_ASSIGNED - allow not assigned TLDs. On IANA website they are listed
as "Not assigned" in the "TLD Manager" field.

=item *

TLD_COUNTRY_CODE - allow county-code TLDs.

=item *

TLD_GENERIC - allow generic TLDs.

=item *

TLD_GENERIC_RESTRICTED - allow generic-restricted TLDs.

=item *

TLD_INFRASTRUCTURE - allow infrastructure TLDs.

=item *

TLD_SPONSORED - allow sponsored TLDs.

=item *

TLD_TEST - allow test TLDs.

=item *

TLD_SPECIAL - allow Special & Restricted TLDs.
See L<RFC 2606|https://tools.ietf.org/html/rfc2606>,
L<RFC 6761|https://tools.ietf.org/html/rfc6761> and
L<RFC 7686|https://tools.ietf.org/html/rfc7686> for details.
Currently, this includes the next TLDs: "test.", "invalid.", 
"localhost.", "example.", "onion." and also Second Level Domains,
such as, "example.com.", "example.net." and "example.org.".

=back


For instance, to allow only country-code and generic TLDs you
have to write this:

    my $eav = EAV::XS->new(
        allow_tld => EAV::XS::TLD_COUNTRY_CODE | EAV::XS::TLD_GENERIC
    );

    if (not $eav->is_email ('test@example.biz')) {
        print ".biz is generic-restricted TLD and not allowed.\n";
    }


=head1 SEE ALSO

References:

=over 4

=item *

L<RFC 20|https://tools.ietf.org/html/rfc20>

=item *

L<RFC 822|https://tools.ietf.org/html/rfc822>

=item *

L<RFC 5321|https://tools.ietf.org/html/rfc5321>

=item *

L<RFC 5322|https://tools.ietf.org/html/rfc5322>

=item *

L<RFC 6530|https://tools.ietf.org/html/rfc6530>

=item *

L<RFC 6531|https://tools.ietf.org/html/rfc6531>

=back

Other implementations:

=over 4

=item *

L<Email::Valid>

=item *

L<String::Validator::Email>

=item *

L<Data::Validate::Email>

=item *

L<Email::Address>

=item *

L<Email::IsEmail>

=back

=head1 AUTHOR

Vitaliy V. Tokarev, E<lt>vitaliy.tokarev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 Vitaliy V. Tokarev

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AVAILABILITY

You can obtain the latest version from
L<https://github.com/gh0stwizard/p5-EAV-XS/>.

=cut
