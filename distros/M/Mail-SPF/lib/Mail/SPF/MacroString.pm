#
# Mail::SPF::MacroString
# SPF record macro string class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: MacroString.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::MacroString;

=head1 NAME

Mail::SPF::MacroString - SPF record macro string class

=cut

use warnings;
use strict;

use utf8;  # Hack to keep Perl 5.6 from whining about /[\p{}]/.

use base 'Mail::SPF::Base';

use overload
    '""'        => 'stringify',
    fallback    => 1;

use Error ':try';
use URI::Escape ();

use Mail::SPF::Util;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant default_split_delimiters   => '.';
use constant default_join_delimiter     => '.';

use constant uri_unreserved_chars   => 'A-Za-z0-9\-._~';
    # "unreserved" characters according to RFC 3986 -- not the "uric" chars!
    # This deliberately deviates from what RFC 4408 says.  This is a bug in
    # RFC 4408.

use constant macos_epoch_offset     => ((1970 - 1904) * 365 + 17) * 24 * 3600;
    # This is a hack because the MacOS Classic epoch is relative to the local
    # timezone.  Get a real OS!

# Interface:
##############################################################################

=head1 SYNOPSIS

=head2 Providing the expansion context early

    use Mail::SPF::MacroString;

    my $macrostring = Mail::SPF::MacroString->new(
        text    => '%{ir}.%{v}._spf.%{d2}',
        server  => $server,
        request => $request
    );

    my $expanded = $macrostring->expand;

=head2 Providing the expansion context late

    use Mail::SPF::MacroString;

    my $macrostring = Mail::SPF::MacroString->new(
        text    => '%{ir}.%{v}._spf.%{d2}'
    );

    my $expanded1 = $macrostring->expand($server, $request1);

    $macrostring->context($server, $request2);
    my $expanded2 = $macrostring->expand;

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

An object of class B<Mail::SPF::MacroString> represents a macro string that
can be expanded to a plain string in the context of an SPF request.

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::MacroString>

Creates a new SPF record macro string object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<text>

I<Required>.  The unexpanded text of the new macro string.

=item B<server>

The I<Mail::SPF::Server> object that is to be used when expanding the macro
string.  A server object need not be attached statically to the macro string;
it can be specified dynamically when calling the C<expand> method.

=item B<request>

The I<Mail::SPF::Request> object that is to be used when expanding the macro
string.  A request object need not be attached statically to the macro string;
it can be specified dynamically when calling the C<expand> method.

=item B<is_explanation>

A I<boolean> denoting whether the macro string is an explanation string
obtained via an C<exp> modifier.  If B<true>, the C<c>, C<r>, and C<t> macros
may appear in the macro string, otherwise they may not, and if they do, a
I<Mail::SPF::EInvalidMacro> exception will be thrown when the macro string is
expanded.  Defaults to B<false>.

=back

=cut

sub new {
    my ($self, %options) = @_;
    $self = $self->SUPER::new(%options);
    defined($self->{text})
        or throw Mail::SPF::EOptionRequired("Missing required 'text' option");
    return $self;
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<text>: returns I<string>

Returns the unexpanded text of the macro string.

=cut

# Read-only accessor:
__PACKAGE__->make_accessor('text', TRUE);

=item B<context($server, $request)>: throws I<Mail::SPF::EOptionRequired>

Attaches the given I<Mail::SPF::Server> and I<Mail::SPF::Request> objects as
the context for the macro string.

=cut

sub context {
    my ($self, $server, $request) = @_;
    $self->_is_valid_context(TRUE, $server, $request);
    $self->{server}   = $server;
    $self->{request}  = $request;
    $self->{expanded} = undef;
    return;
}

=item B<expand>: returns I<string>;
throws I<Mail::SPF::EMacroExpansionCtxRequired>, I<Mail::SPF::EInvalidMacroString>, I<Mail::SPF::Result::PermError>

=item B<expand($server, $request)>: returns I<string>;
throws I<Mail::SPF::EMacroExpansionCtxRequired>, I<Mail::SPF::EInvalidMacroString>, I<Mail::SPF::Result::PermError>

Expands the text of the macro string using either the context specified through
an earlier call to the C<context()> method, or the given context, and returns
the resulting string.  See RFC 4408, 8, for how macros are expanded.

=cut

sub expand {
    my ($self, @context) = @_;

    return $self->{expanded}
        if defined($self->{expanded});

    my $text = $self->{text};
    return undef
        if not defined($text);

    return $self->{expanded} = $text
        if $text !~ /%/;  # Short-circuit expansion if text has no '%' character.

    my ($server, $request) = @context ? @context : ($self->{server}, $self->{request});
    $self->_is_valid_context(TRUE, $server, $request);

    my $expanded = '';
    pos($text) = 0;

    while ($text =~ m/ \G (.*?) %(.) /cgx) {
        $expanded .= $1;
        my $key = $2;
        my $pos = pos($text) - 2;

        if ($key eq '{') {
            if ($text =~ m/ \G (\w|_\p{IsAlpha}+) ([0-9]+)? (r)? ([.\-+,\/_=]*)? } /cgx) {
                my ($char, $rh_parts, $reverse, $delimiters) = ($1, $2, $3, $4);

                # Upper-case macro chars trigger URL-escaping AKA percent-encoding
                # (RFC 4408, 8.1/26):
                my $do_percent_encode = $char =~ tr/A-Z/a-z/;

                my $value;

                if    ($char eq 's') {  # RFC 4408, 8.1/19
                    $value = $request->identity;
                }
                elsif ($char eq 'l') {  # RFC 4408, 8.1/19
                    $value = $request->localpart;
                }
                elsif ($char eq 'o') {  # RFC 4408, 8.1/19
                    $value = $request->domain;
                }
                elsif ($char eq 'd') {  # RFC 4408, 8.1/6/4
                    $value = $request->authority_domain;
                }
                elsif ($char eq 'i') {  # RFC 4408, 8.1/20, 8.1/21
                    my $ip_address = $request->ip_address;
                    $ip_address = Mail::SPF::Util->ipv6_address_to_ipv4($ip_address)
                        if Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ip_address);
                    my $ip_address_version = $ip_address->version;
                    if ($ip_address_version == 4) {
                        $value = $ip_address->addr;
                    }
                    elsif ($ip_address_version == 6) {
                        $value = join(".", split(//, unpack("H32", $ip_address->aton)));
                    }
                    else {
                        # Unexpected IP address version.
                        $server->throw_result('permerror', $request,
                            "Unexpected IP address version '$ip_address_version' in request");
                    }
                }
                elsif ($char eq 'p') {  # RFC 4408, 8.1/22
                    try {
                        $value = Mail::SPF::Util->valid_domain_for_ip_address(
                            $server, $request, $request->ip_address, $request->authority_domain,
                            TRUE, TRUE
                        );
                    }
                    catch Mail::SPF::EDNSError with {};
                    $value ||= 'unknown';
                }
                elsif ($char eq 'v') {  # RFC 4408, 8.1/6/7
                    my $ip_address_version = $request->ip_address->version;
                    if ($ip_address_version == 4) {
                        $value = 'in-addr';
                    }
                    elsif ($ip_address_version == 6) {
                        $value = 'ip6';
                    }
                    else {
                        # Unexpected IP address version.
                        $server->throw_result('permerror', $request,
                            "Unexpected IP address version '$ip_address_version' in request");
                    }
                }
                elsif ($char eq 'h') {  # RFC 4408, 8.1/6/8
                    $value = $request->helo_identity || 'unknown';
                }
                elsif ($char eq 'c') {  # RFC 4408, 8.1/20, 8.1/21
                    $self->{is_explanation}
                        or throw Mail::SPF::EInvalidMacro(
                                "Illegal 'c' macro in non-explanation macro string '$text'");
                    my $ip_address = $request->ip_address;
                    $ip_address = Mail::SPF::Util->ipv6_address_to_ipv4($ip_address)
                        if Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ip_address);
                    $value = Mail::SPF::Util->ip_address_to_string($ip_address);
                }
                elsif ($char eq 'r') {  # RFC 4408, 8.1/23
                    $self->{is_explanation}
                        or throw Mail::SPF::EInvalidMacro(
                                "Illegal 'r' macro in non-explanation macro string '$text'");
                    $value = $server->hostname || 'unknown';
                }
                elsif ($char eq 't') {  # RFC 4408, 8.1/24
                    $self->{is_explanation}
                        or throw Mail::SPF::EInvalidMacro(
                                "Illegal 't' macro in non-explanation macro string '$text'");
                    $value = $^O ne 'MacOS' ? time() : time() + $self->macos_epoch_offset;
                }
                elsif ($char eq '_scope') {
                    # Scope pseudo macro for internal use only!
                    $value = $request->scope;
                }
                else {
                    # Unknown macro character.
                    throw Mail::SPF::EInvalidMacro(
                        "Unknown macro character '$char' at pos $pos in macro string '$text'");
                }

                if (defined($rh_parts) or defined($reverse)) {
                    $delimiters ||= $self->default_split_delimiters;
                    my @list = split(/[\Q$delimiters\E]/, $value);
                    @list = reverse(@list) if defined($reverse);

                    # Extract desired parts:
                    if (defined($rh_parts) and $rh_parts > 0) {
                        splice(@list, 0, @list >= $rh_parts ? @list - $rh_parts : 0);
                    }
                    if (defined($rh_parts) and $rh_parts == 0) {
                        throw Mail::SPF::EInvalidMacro(
                            "Illegal selection of 0 (zero) right-hand parts at pos $pos in macro string '$text'");
                    }

                    $value = join($self->default_join_delimiter, @list);
                }

                $value = URI::Escape::uri_escape($value, '^' . $self->uri_unreserved_chars)
                    # Note the comment about the set of safe/unsafe characters at the
                    # definition of the "uri_unreserved_chars" constant above.
                    if $do_percent_encode;

                $expanded .= $value;
            }
            else {
                # Invalid macro expression.
                throw Mail::SPF::EInvalidMacro(
                    "Invalid macro expression at pos $pos in macro string '$text'");
            }
        }
        elsif ($key eq '-') {
            $expanded .= '%20';
        }
        elsif ($key eq '_') {
            $expanded .= ' ';
        }
        elsif ($key eq '%') {
            $expanded .= '%';
        }
        else {
            # Invalid macro expression.
            throw Mail::SPF::EInvalidMacro(
                "Invalid macro expression at pos $pos in macro string '$text'");
        }
    }

    $expanded .= substr($text, pos($text));  # Append remaining unmatched characters.

    #print("DEBUG: Expand $text -> $expanded\n");
    #printf("DEBUG:   Caller: %s() (line %d)\n", (caller(1))[3, 2]);
    return @context ? $expanded : ($self->{expanded} = $expanded);
}

=item B<is_explanation>: returns I<boolean>

Returns B<true> if the macro string is an explanation string obtained via an
C<exp> modifier.  See the description of the L</new> constructor's
C<is_explanation> option.

=cut

# Make read-only accessor:
__PACKAGE__->make_accessor('is_explanation', TRUE);

=item B<stringify>: returns I<string>

Returns the expanded text of the macro string if a context is attached to the
object.  Returns the unexpanded text otherwise.  You can simply use a
Mail::SPF::MacroString object as a string for the same effect, see
L<"OVERLOADING">.

=cut

sub stringify {
    my ($self) = @_;
    return
        $self->_is_valid_context(FALSE, $self->{server}, $self->{request}) ?
            $self->expand  # Context availabe, expand.
        :   $self->text;   # Context unavailable, do not expand.
}

=back

=cut

sub _is_valid_context {
    my ($self, $require, $server, $request) = @_;
    if (not UNIVERSAL::isa($server, 'Mail::SPF::Server')) {
        throw Mail::SPF::EMacroExpansionCtxRequired('Mail::SPF server object required') if $require;
        return FALSE;
    }
    if (not UNIVERSAL::isa($request, 'Mail::SPF::Request')) {
        throw Mail::SPF::EMacroExpansionCtxRequired('Request object required') if $require;
        return FALSE;
    }
    return TRUE;
}

=head1 OVERLOADING

If a Mail::SPF::MacroString object is used as a I<string>, the C<stringify>
method is used to convert the object into a string.

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Record>, L<Mail::SPF::Server>, L<Mail::SPF::Request>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
