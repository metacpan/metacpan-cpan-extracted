#
# Mail::SPF::Term
# SPF record term class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Term.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Term;

=head1 NAME

Mail::SPF::Term - SPF record term class

=cut

use warnings;
use strict;

use utf8;  # Hack to keep Perl 5.6 from whining about /[\p{}]/.

use base 'Mail::SPF::Base';

use overload
    '""'        => 'stringify',
    fallback    => 1;

use NetAddr::IP;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant name_pattern               => qr/ \p{IsAlpha} [\p{IsAlnum}\-_.]* /x;

use constant macro_literal_pattern      => qr/[!-\$&-~]/;
use constant macro_delimiter            => qr/[.\-+,\/_=]/;
use constant macro_transformers_pattern => qr/\d*r?/;
use constant macro_expand_pattern       => qr/
    \%
    (?:
        { \p{IsAlpha} ${\macro_transformers_pattern} ${\macro_delimiter}* } |
        [%_-]
    )
/x;

use constant macro_string_pattern       => qr/
    (?:
        ${\macro_expand_pattern}  |
        ${\macro_literal_pattern}
    )*
/x;

use constant toplabel_pattern           => qr/
    \p{IsAlnum}+ - [\p{IsAlnum}-]* \p{IsAlnum}  |
    \p{IsAlnum}*    \p{IsAlpha}    \p{IsAlnum}*
/x;

use constant domain_end_pattern         => qr/
    \. ${\toplabel_pattern} \.? |
    ${\macro_expand_pattern}
/x;

use constant domain_spec_pattern        => qr/ ${\macro_string_pattern} ${\domain_end_pattern} /x;

use constant qnum_pattern               => qr/ 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]\d | \d /x;
use constant ipv4_address_pattern       => qr/ ${\qnum_pattern} (?: \. ${\qnum_pattern} ){3} /x;

use constant hexword_pattern            => qr/\p{IsXDigit}{1,4}/;
use constant two_hexwords_or_ipv4_address_pattern => qr/
    ${\hexword_pattern} : ${\hexword_pattern} | ${\ipv4_address_pattern}
/x;
use constant ipv6_address_pattern       => qr/
    #                x:x:x:x:x:x:x:x |     x:x:x:x:x:x:n.n.n.n
    (?: ${\hexword_pattern} : ){6}                                    ${\two_hexwords_or_ipv4_address_pattern} |
    #                 x::x:x:x:x:x:x |      x::x:x:x:x:n.n.n.n
    (?: ${\hexword_pattern} : ){1}   : (?: ${\hexword_pattern} : ){4} ${\two_hexwords_or_ipv4_address_pattern} |
    #               x[:x]::x:x:x:x:x |    x[:x]::x:x:x:n.n.n.n
    (?: ${\hexword_pattern} : ){1,2} : (?: ${\hexword_pattern} : ){3} ${\two_hexwords_or_ipv4_address_pattern} |
    #               x[:...]::x:x:x:x |    x[:...]::x:x:n.n.n.n
    (?: ${\hexword_pattern} : ){1,3} : (?: ${\hexword_pattern} : ){2} ${\two_hexwords_or_ipv4_address_pattern} |
    #                 x[:...]::x:x:x |      x[:...]::x:n.n.n.n
    (?: ${\hexword_pattern} : ){1,4} : (?: ${\hexword_pattern} : ){1} ${\two_hexwords_or_ipv4_address_pattern} |
    #                   x[:...]::x:x |        x[:...]::n.n.n.n
    (?: ${\hexword_pattern} : ){1,5} :                                ${\two_hexwords_or_ipv4_address_pattern} |
    #                     x[:...]::x |                       -
    (?: ${\hexword_pattern} : ){1,6} :     ${\hexword_pattern}                                                 |
    #                      x[:...]:: |                       -
    (?: ${\hexword_pattern} : ){1,7} :                                                                         |
    #                      ::[...:]x |                       -
 :: (?: ${\hexword_pattern} : ){0,6}       ${\hexword_pattern}                                                 |
    #                              - |         ::[...:]n.n.n.n
 :: (?: ${\hexword_pattern} : ){0,5}                                  ${\two_hexwords_or_ipv4_address_pattern} |
    #                             :: |                       -
 ::
/x;

=head1 DESCRIPTION

An object of class B<Mail::SPF::Term> represents a term within an SPF record.
Mail::SPF::Term cannot be instantiated directly.  Create an instance of a
concrete sub-class instead.

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Term>

I<Abstract>.  Creates a new SPF record term object.

%options is a list of key/value pairs, however Mail::SPF::Term itself specifies
no constructor options.

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Term>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidTerm>

I<Abstract>.  Creates a new SPF record term object by parsing the string and
any options given.

=cut

sub new_from_string {
    my ($self, $text, %options) = @_;
    $self = $self->new(%options, text => $text);
    $self->parse();
    return $self;
}

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<name_pattern>: returns I<Regexp>

Returns a regular expression that matches any legal name for an SPF record
term.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=cut

sub parse_domain_spec {
    my ($self, $required) = @_;
    if ($self->{parse_text} =~ s/^(${\$self->domain_spec_pattern})//) {
        my $domain_spec = $1;
        $domain_spec =~ s/^(.*?)\.?$/\L$1/;
        $self->{domain_spec} = Mail::SPF::MacroString->new(text => $domain_spec);
    }
    elsif ($required) {
        throw Mail::SPF::ETermDomainSpecExpected(
            "Missing required domain-spec in '" . $self->text . "'");
    }
    return;
}

sub parse_ipv4_address {
    my ($self, $required) = @_;
    if ($self->{parse_text} =~ s/^(${\$self->ipv4_address_pattern})//) {
        $self->{ip_address} = $1;
    }
    elsif ($required) {
        throw Mail::SPF::ETermIPv4AddressExpected(
            "Missing required IPv4 address in '" . $self->text . "'");
    }
    return;
}

sub parse_ipv4_prefix_length {
    my ($self, $required) = @_;
    if ($self->{parse_text} =~ s#^/(\d+)##) {
        $1 >= 0 and $1 <= 32 and $1 !~ /^0./
            or throw Mail::SPF::ETermIPv4PrefixLengthExpected(
                    "Invalid IPv4 prefix length encountered in '" . $self->text . "'");
        $self->{ipv4_prefix_length} = $1;
    }
    elsif (not $required) {
        $self->{ipv4_prefix_length} = $self->default_ipv4_prefix_length;
    }
    else {
        throw Mail::SPF::ETermIPv4PrefixLengthExpected(
            "Missing required IPv4 prefix length in '" . $self->text . "'");
    }
    return;
}

sub parse_ipv4_network {
    my ($self, $required) = @_;
    $self->parse_ipv4_address($required);
    $self->parse_ipv4_prefix_length();
    $self->{ip_network} = NetAddr::IP->new($self->{ip_address}, $self->{ipv4_prefix_length});
    return;
}

sub parse_ipv6_address {
    my ($self, $required) = @_;
    if ($self->{parse_text} =~ s/^(${\$self->ipv6_address_pattern})(?=\/|$)//) {
        $self->{ip_address} = $1;
    }
    elsif ($required) {
        throw Mail::SPF::ETermIPv6AddressExpected(
            "Missing required IPv6 address in '" . $self->text . "'");
    }
    return;
}

sub parse_ipv6_prefix_length {
    my ($self, $required) = @_;
    if ($self->{parse_text} =~ s#^/(\d+)##) {
        $1 >= 0 and $1 <= 128 and $1 !~ /^0./
            or throw Mail::SPF::ETermIPv6PrefixLengthExpected(
                    "Invalid IPv6 prefix length encountered in '" . $self->text . "'");
        $self->{ipv6_prefix_length} = $1;
    }
    elsif (not $required) {
        $self->{ipv6_prefix_length} = $self->default_ipv6_prefix_length;
    }
    else {
        throw Mail::SPF::ETermIPv6PrefixLengthExpected(
            "Missing required IPv6 prefix length in '" . $self->text . "'");
    }
    return;
}

sub parse_ipv6_network {
    my ($self, $required) = @_;
    $self->parse_ipv6_address($required);
    $self->parse_ipv6_prefix_length();
    $self->{ip_network} = NetAddr::IP->new(
        $self->{ip_address}, $self->{ipv6_prefix_length});
    return;
}

sub parse_ipv4_ipv6_prefix_lengths {
    my ($self) = @_;
    $self->parse_ipv4_prefix_length();
    if (
        defined($self->{ipv4_prefix_length}) and  # an IPv4 prefix length has been parsed, and
        $self->{parse_text} =~ s#^/##             # another slash is following
    ) {
        # Parse an IPv6 prefix length:
        $self->parse_ipv6_prefix_length(TRUE);
    }
    return;
}

=item B<text>: returns I<string>; throws I<Mail::SPF::ENoUnparsedText>

Returns the unparsed text of the term.  Throws a I<Mail::SPF::ENoUnparsedText>
exception if the term was created synthetically instead of being parsed, and no
text was provided.

=cut

sub text {
    my ($self) = @_;
    defined($self->{text})
        or throw Mail::SPF::ENoUnparsedText;
    return $self->{text};
}

=item B<name>: returns I<string>

I<Abstract>.  Returns the name of the term.

=back

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Record>, L<Mail::SPF::Mech>, L<Mail::SPF::Mod>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
