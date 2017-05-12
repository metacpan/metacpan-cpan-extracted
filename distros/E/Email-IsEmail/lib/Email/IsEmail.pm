package Email::IsEmail;

use v5.10;
use strict qw(subs vars);
*{'Email::IsEmail'} = \&IsEmail;  # add short alias Email::IsEmail
use strict 'refs';
use warnings;

use Scalar::Util qw(looks_like_number);

our ( @ISA, @EXPORT_OK, %EXPORT_TAGS, $VERSION );

@ISA = qw(Exporter);
@EXPORT_OK = qw(IsEmail);
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] ) ;

=head1 NAME

Email::IsEmail - Checks an email address against the following RFCs: 3696, 1123, 4291, 5321, 5322

=head1 VERSION

Version 3.04.8

=cut

$VERSION = '3.04.8';


=head1 SYNOPSIS

Checks an email address against the following RFCs: 3696, 1123, 4291, 5321, 5322

Example usage:

    use Email::IsEmail qw/IsEmail/;

    my $valid = Email::IsEmail('test@example.org');
    ...
    my $checkDNS    = 0;   # do not check DNS (default)
    my $error_level = -1;  # use dafault error threshold: Email::IsEmail::THRESHOLD
    my %parse_data  = ();  # collect E-mail components

    $valid = IsEmail( 'test@[127.0.0.1]', $checkDNS, $error_level, \%parse_data );

    print "Local-part: ",     $parse_data{Email::IsEmail::COMPONENT_LOCALPART}, "\n";
    print "Domain: ",         $parse_data{Email::IsEmail::COMPONENT_DOMAIN}, "\n";
    # only for IPv4/IPv6 addresses:
    print "Domain literal: ", $parse_data{Email::IsEmail::COMPONENT_LITERAL}, "\n";

=cut

=head1 FUNCTIONS

=cut

# Categories
use constant VALID_CATEGORY => 1;
use constant DNSWARN => 7;
use constant RFC5321 => 15;
use constant CFWS => 31;
use constant DEPREC => 63;
use constant RFC5322 => 127;
use constant ERR => 255;

# Diagnoses
# Address is valid
use constant VALID => 0;
# Address is valid but a DNS check was not successful
use constant DNSWARN_NO_MX_RECORD => 5;
use constant DNSWARN_NO_RECORD => 6;
# Address is valid for SMTP but has unusual elements
use constant RFC5321_TLD => 9;
use constant RFC5321_TLDNUMERIC => 10;
use constant RFC5321_QUOTEDSTRING => 11;
use constant RFC5321_ADDRESSLITERAL => 12;
use constant RFC5321_IPV6DEPRECATED => 13;
# Address is valid within the message but cannot be used unmodified for the envelope
use constant CFWS_COMMENT => 17;
use constant CFWS_FWS => 18;
# Address contains deprecated elements but may still be valid in restricted contexts
use constant DEPREC_LOCALPART => 33;
use constant DEPREC_FWS => 34;
use constant DEPREC_QTEXT => 35;
use constant DEPREC_QP => 36;
use constant DEPREC_COMMENT => 37;
use constant DEPREC_CTEXT => 38;
use constant DEPREC_CFWS_NEAR_AT => 49;
# The address is only valid according to the broad definition of RFC 5322. It is otherwise invalid.
use constant RFC5322_DOMAIN => 65;
use constant RFC5322_TOOLONG => 66;
use constant RFC5322_LOCAL_TOOLONG => 67;
use constant RFC5322_DOMAIN_TOOLONG => 68;
use constant RFC5322_LABEL_TOOLONG => 69;
use constant RFC5322_DOMAINLITERAL => 70;
use constant RFC5322_DOMLIT_OBSDTEXT => 71;
use constant RFC5322_IPV6_GRPCOUNT => 72;
use constant RFC5322_IPV6_2X2XCOLON => 73;
use constant RFC5322_IPV6_BADCHAR => 74;
use constant RFC5322_IPV6_MAXGRPS => 75;
use constant RFC5322_IPV6_COLONSTRT => 76;
use constant RFC5322_IPV6_COLONEND => 77;
# Address is invalid for any purpose
use constant ERR_EXPECTING_DTEXT => 129;
use constant ERR_NOLOCALPART => 130;
use constant ERR_NODOMAIN => 131;
use constant ERR_CONSECUTIVEDOTS => 132;
use constant ERR_ATEXT_AFTER_CFWS => 133;
use constant ERR_ATEXT_AFTER_QS => 134;
use constant ERR_ATEXT_AFTER_DOMLIT => 135;
use constant ERR_EXPECTING_QPAIR => 136;
use constant ERR_EXPECTING_ATEXT => 137;
use constant ERR_EXPECTING_QTEXT => 138;
use constant ERR_EXPECTING_CTEXT => 139;
use constant ERR_BACKSLASHEND => 140;
use constant ERR_DOT_START => 141;
use constant ERR_DOT_END => 142;
use constant ERR_DOMAINHYPHENSTART => 143;
use constant ERR_DOMAINHYPHENEND => 144;
use constant ERR_UNCLOSEDQUOTEDSTR => 145;
use constant ERR_UNCLOSEDCOMMENT => 146;
use constant ERR_UNCLOSEDDOMLIT => 147;
use constant ERR_FWS_CRLF_X2 => 148;
use constant ERR_FWS_CRLF_END => 149;
use constant ERR_CR_NO_LF => 150;
# diagnostic constants end

# function control
use constant THRESHOLD => 16;

# Email parts
use constant COMPONENT_LOCALPART => 0;
use constant COMPONENT_DOMAIN => 1;
use constant COMPONENT_LITERAL => 2;
use constant CONTEXT_COMMENT => 3;
use constant CONTEXT_FWS => 4;
use constant CONTEXT_QUOTEDSTRING => 5;
use constant CONTEXT_QUOTEDPAIR => 6;

# Miscellaneous string constants
use constant STRING_AT => '@';
use constant STRING_BACKSLASH => '\\';
use constant STRING_DOT => '.';
use constant STRING_DQUOTE => '"';
use constant STRING_OPENPARENTHESIS => '(';
use constant STRING_CLOSEPARENTHESIS => ')';
use constant STRING_OPENSQBRACKET => '[';
use constant STRING_CLOSESQBRACKET => ']';
use constant STRING_HYPHEN => '-';
use constant STRING_COLON => ':';
use constant STRING_DOUBLECOLON => '::';
use constant STRING_SP => ' ';
use constant STRING_HTAB => "\t";
use constant STRING_CR => "\r";
use constant STRING_LF => "\n";
use constant STRING_IPV6TAG => 'IPv6:';
# US-ASCII visible characters not valid for atext (http://tools.ietf.org/html/rfc5322#section-3.2.3)
use constant STRING_SPECIALS => '()<>[]:;@\\,."';


=over 4

=item B<IsEmail>

  my $valid = Email::IsEmail( $email, $checkDNS, $errorlevel, $parsedata );

Check that an email address conforms to RFCs 5321, 5322 and others

As of Version 3.0, we are now distinguishing clearly between a Mailbox
as defined by RFC 5321 and an addr-spec as defined by RFC 5322. Depending
on the context, either can be regarded as a valid email address. The
RFC 5321 Mailbox specification is more restrictive (comments, white space
and obsolete forms are not allowed)

    @param string   $email          The email address to check
    @param boolean  $checkDNS       If true then a DNS check for MX records will be made
    @param int      $errorlevel     Determines the boundary between valid and invalid addresses.
                                    Status codes above this number will be returned as-is,
                                    status codes below will be returned as Email::IsEmail::VALID. Thus the
                                    calling program can simply look for Email::IsEmail::VALID if it is
                                    only interested in whether an address is valid or not. The
                                    errorlevel will determine how "picky" Email::IsEmail() is about
                                    the address.

                                    If omitted or passed as -1 then Email::IsEmail() will return
                                    true or false rather than an integer error or warning.

                                    NB Note the difference between $errorlevel = -1 and
                                    $errorlevel = 0
    @param hashref  $parsedata      If passed, returns the parsed address components

=back

=cut

sub IsEmail {
    my ( $email, $checkDNS, $errorlevel, $parsedata ) = @_;

    $checkDNS   //= 0;
    $errorlevel //= -1;
    $parsedata  //= {};

    return !1
        unless $email;

    my ( $threshold, $diagnose );

    if ( $errorlevel < 0 ) {
        $threshold = Email::IsEmail::VALID;
        $diagnose  = 0;
    }
    else {
        $diagnose  = 1;
        $threshold = int $errorlevel;
    }

    my $return_status = [Email::IsEmail::VALID];


    # Parse the address into components, character by character
    my $raw_length    = length $email;
    my $context       = Email::IsEmail::COMPONENT_LOCALPART;  # Where we are
    my $context_stack = [$context];  # Where we have been
    my $context_prior = Email::IsEmail::COMPONENT_LOCALPART;  # Where we just came from
    my $token         = '';  # The current character
    my $token_prior   = '';  # The previous character
    $parsedata->{Email::IsEmail::COMPONENT_LOCALPART} = '';  # For the components of the address
    $parsedata->{Email::IsEmail::COMPONENT_DOMAIN}    = '';

    my $atomlist      = {
        Email::IsEmail::COMPONENT_LOCALPART => [''],
        Email::IsEmail::COMPONENT_DOMAIN    => [''],
    };  # For the dot-atom elements of the address
    my $element_count = 0;
    my $element_len   = 0;
    my $hyphen_flag   = 0;  # Hyphen cannot occur at the end of a subdomain
    my $end_or_die    = 0;  # CFWS can only appear at the end of the element
    my $crlf_count    = 0;

    for ( my $i = 0; $i < $raw_length; $i++ ) {
        $token = substr $email, $i, 1;
        given($context) {
            #-------------------------------------------------------------
            # local-part
            #-------------------------------------------------------------
            when (Email::IsEmail::COMPONENT_LOCALPART) {
                # http://tools.ietf.org/html/rfc5322#section-3.4.1
                #   local-part      =   dot-atom / quoted-string / obs-local-part
                #
                #   dot-atom        =   [CFWS] dot-atom-text [CFWS]
                #
                #   dot-atom-text   =   1*atext *("." 1*atext)
                #
                #   quoted-string   =   [CFWS]
                #                       DQUOTE *([FWS] qcontent) [FWS] DQUOTE
                #                       [CFWS]
                #
                #   obs-local-part  =   word *("." word)
                #
                #   word            =   atom / quoted-string
                #
                #   atom            =   [CFWS] 1*atext [CFWS]
                given($token) {
                    # Comment
                    when (Email::IsEmail::STRING_OPENPARENTHESIS) {
                        if ( $element_len == 0 ) {
                            # Comments are OK at the beginning of an element
                            push @{$return_status}, ( $element_count == 0 ) ? Email::IsEmail::CFWS_COMMENT : Email::IsEmail::DEPREC_COMMENT;
                        }
                        else {
                            push @{$return_status}, Email::IsEmail::CFWS_COMMENT;
                            $end_or_die = 1;  # We can't start a comment in the middle of an element, so this better be the end
                        }

                        push @{$context_stack}, $context;
                        $context = Email::IsEmail::CONTEXT_COMMENT;
                    }
                    # Next dot-atom element
                    when (Email::IsEmail::STRING_DOT) {
                        if ( $element_len == 0 ) {
                            # Another dot, already?
                            push @{$return_status}, ( $element_count == 0 ) ? Email::IsEmail::ERR_DOT_START : Email::IsEmail::ERR_CONSECUTIVEDOTS;  # Fatal error
                        }
                        else {
                            # The entire local-part can be a quoted string for RFC 5321
                            # If it's just one atom that is quoted then it's an RFC 5322 obsolete form
                            if ($end_or_die) {
                                push @{$return_status}, Email::IsEmail::DEPREC_LOCALPART;
                            }
                        }

                        $end_or_die  = 0;  # CFWS & quoted strings are OK again now we're at the beginning of an element (although they are obsolete forms)
                        $element_len = 0;
                        $element_count++;
                        $parsedata->{Email::IsEmail::COMPONENT_LOCALPART}               .= $token;
                        $atomlist->{Email::IsEmail::COMPONENT_LOCALPART}[$element_count] = '';
                    }
                    # Quoted string
                    when (Email::IsEmail::STRING_DQUOTE) {
                        if ( $element_len == 0 ) {
                            # The entire local-part can be a quoted string for RFC 5321
                            # If it's just one atom that is quoted then it's an RFC 5322 obsolete form
                            push @{$return_status}, ( $element_count == 0 ) ? Email::IsEmail::RFC5321_QUOTEDSTRING : Email::IsEmail::DEPREC_LOCALPART;

                            $parsedata->{Email::IsEmail::COMPONENT_LOCALPART}                .= $token;
                            $atomlist->{Email::IsEmail::COMPONENT_LOCALPART}[$element_count] .= $token;
                            $element_len++;
                            $end_or_die = 1;  # Quoted string must be the entire element
                            push @{$context_stack}, $context;
                            $context = Email::IsEmail::CONTEXT_QUOTEDSTRING;
                        }
                        else {
                            push @{$return_status}, Email::IsEmail::ERR_EXPECTING_ATEXT;  # Fatal error
                        }
                    }
                    # Folding White Space
                    when ([ Email::IsEmail::STRING_CR,
                            Email::IsEmail::STRING_SP,
                            Email::IsEmail::STRING_HTAB, ]) {
                        if ( ( $token eq Email::IsEmail::STRING_CR ) and
                             ( ( ++$i == $raw_length ) or
                               ( substr( $email, $i, 1 ) ne Email::IsEmail::STRING_LF ) ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_CR_NO_LF;
                            break;
                        }  # Fatal error
                        if ( $element_len == 0 ) {
                            push @{$return_status}, ( $element_count == 0 ) ? Email::IsEmail::CFWS_FWS : Email::IsEmail::DEPREC_FWS;
                        }
                        else {
                            $end_or_die = 1;  # We can't start FWS in the middle of an element, so this better be the end
                        }

                        push @{$context_stack}, $context;
                        $context     = Email::IsEmail::CONTEXT_FWS;
                        $token_prior = $token;
                    }
                    # @
                    when (Email::IsEmail::STRING_AT) {
                        # At this point we should have a valid local-part
                        if ( scalar @{$context_stack} != 1 ) {
                            die('Unexpected item on context stack');
                        }

                        if ( $parsedata->{Email::IsEmail::COMPONENT_LOCALPART} eq '' ) {
                            push @{$return_status}, Email::IsEmail::ERR_NOLOCALPART;  # Fatal error
                        }
                        elsif ( $element_len == 0 ) {
                            push @{$return_status}, Email::IsEmail::ERR_DOT_END;  # Fatal error
                        }
                        # http://tools.ietf.org/html/rfc5321#section-4.5.3.1.1
                        #   The maximum total length of a user name or other local-part is 64
                        #   octets.
                        elsif ( length($parsedata->{Email::IsEmail::COMPONENT_LOCALPART}) > 64 ) {
                            push @{$return_status}, Email::IsEmail::RFC5322_LOCAL_TOOLONG;
                        }
                        # http://tools.ietf.org/html/rfc5322#section-3.4.1
                        #   Comments and folding white space
                        #   SHOULD NOT be used around the "@" in the addr-spec.
                        #
                        # http://tools.ietf.org/html/rfc2119
                        # 4. SHOULD NOT   This phrase, or the phrase "NOT RECOMMENDED" mean that
                        #    there may exist valid reasons in particular circumstances when the
                        #    particular behavior is acceptable or even useful, but the full
                        #    implications should be understood and the case carefully weighed
                        #    before implementing any behavior described with this label.
                        elsif ( ( $context_prior == Email::IsEmail::CONTEXT_COMMENT ) or
                                ( $context_prior == Email::IsEmail::CONTEXT_FWS ) ) {
                            push @{$return_status}, Email::IsEmail::DEPREC_CFWS_NEAR_AT;
                        }

                        # Clear everything down for the domain parsing
                        $context       = Email::IsEmail::COMPONENT_DOMAIN;  # Where we are
                        $context_stack = [$context];  # Where we have been
                        $element_count = 0;
                        $element_len   = 0;
                        $end_or_die    = 0;  # CFWS can only appear at the end of the element
                    }
                    # atext
                    default: {
                        # http://tools.ietf.org/html/rfc5322#section-3.2.3
                        #    atext           =   ALPHA / DIGIT /    ; Printable US-ASCII
                        #                        "!" / "#" /        ;  characters not including
                        #                        "$" / "%" /        ;  specials.  Used for atoms.
                        #                        "&" / "'" /
                        #                        "*" / "+" /
                        #                        "-" / "/" /
                        #                        "=" / "?" /
                        #                        "^" / "_" /
                        #                        "`" / "{" /
                        #                        "|" / "}" /
                        #                        "~"
                        if ($end_or_die) {
                            # We have encountered atext where it is no longer valid
                            given ($context_prior) {
                                when ([ Email::IsEmail::CONTEXT_COMMENT,
                                        Email::IsEmail::CONTEXT_FWS, ]) {
                                    push @{$return_status}, Email::IsEmail::ERR_ATEXT_AFTER_CFWS;
                                }
                                when (Email::IsEmail::CONTEXT_QUOTEDSTRING) {
                                    push @{$return_status}, Email::IsEmail::ERR_ATEXT_AFTER_QS;
                                }
                                default: {
                                    die ("More atext found where none is allowed, but unrecognised prior context: $context_prior");
                                }
                            }
                        } else {
                            $context_prior = $context;
                            my $ord        = ord $token;

                            if ( ( $ord < 33 ) or ( $ord > 126 ) or ( $ord == 10 ) or
                                 ( index( Email::IsEmail::STRING_SPECIALS, $token ) != -1 ) ) {
                                push @{$return_status}, Email::IsEmail::ERR_EXPECTING_ATEXT;  # Fatal error
                            }
                            $parsedata->{Email::IsEmail::COMPONENT_LOCALPART}                .= $token;
                            $atomlist->{Email::IsEmail::COMPONENT_LOCALPART}[$element_count] .= $token;
                            $element_len++;
                        }
                    }
                }
            }
            #-------------------------------------------------------------
            # Domain
            #-------------------------------------------------------------
            when (Email::IsEmail::COMPONENT_DOMAIN) {
                # http://tools.ietf.org/html/rfc5322#section-3.4.1
                #   domain          =   dot-atom / domain-literal / obs-domain
                #
                #   dot-atom        =   [CFWS] dot-atom-text [CFWS]
                #
                #   dot-atom-text   =   1*atext *("." 1*atext)
                #
                #   domain-literal  =   [CFWS] "[" *([FWS] dtext) [FWS] "]" [CFWS]
                #
                #   dtext           =   %d33-90 /          ; Printable US-ASCII
                #                       %d94-126 /         ;  characters not including
                #                       obs-dtext          ;  "[", "]", or "\"
                #
                #   obs-domain      =   atom *("." atom)
                #
                #   atom            =   [CFWS] 1*atext [CFWS]


                # http://tools.ietf.org/html/rfc5321#section-4.1.2
                #   Mailbox        = Local-part "@" ( Domain / address-literal )
                #
                #   Domain         = sub-domain *("." sub-domain)
                #
                #   address-literal  = "[" ( IPv4-address-literal /
                #                    IPv6-address-literal /
                #                    General-address-literal ) "]"
                #                    ; See Section 4.1.3

                # http://tools.ietf.org/html/rfc5322#section-3.4.1
                #      Note: A liberal syntax for the domain portion of addr-spec is
                #      given here.  However, the domain portion contains addressing
                #      information specified by and used in other protocols (e.g.,
                #      [RFC1034], [RFC1035], [RFC1123], [RFC5321]).  It is therefore
                #      incumbent upon implementations to conform to the syntax of
                #      addresses for the context in which they are used.
                # Email::IsEmail() author's note: it's not clear how to interpret this in
                # the context of a general email address validator. The conclusion I
                # have reached is this: "addressing information" must comply with
                # RFC 5321 (and in turn RFC 1035), anything that is "semantically
                # invisible" must comply only with RFC 5322.
                given($token) {
                    # Comment
                    when (Email::IsEmail::STRING_OPENPARENTHESIS) {
                        if ( $element_len == 0 ) {
                            # Comments at the start of the domain are deprecated in the text
                            # Comments at the start of a subdomain are obs-domain
                            # (http://tools.ietf.org/html/rfc5322#section-3.4.1)
                            push @{$return_status}, ( $element_count == 0 ) ? Email::IsEmail::DEPREC_CFWS_NEAR_AT : Email::IsEmail::DEPREC_COMMENT;
                        }
                        else {
                            push @{$return_status}, Email::IsEmail::CFWS_COMMENT;
                            $end_or_die = 1;  # We can't start a comment in the middle of an element, so this better be the end
                        }

                        push @{$context_stack}, $context;
                        $context = Email::IsEmail::CONTEXT_COMMENT;
                    }
                    # Next dot-atom element
                    when (Email::IsEmail::STRING_DOT) {
                        if ( $element_len == 0 ) {
                            # Another dot, already?
                            push @{$return_status}, ( $element_count == 0 ) ? Email::IsEmail::ERR_DOT_START : Email::IsEmail::ERR_CONSECUTIVEDOTS;  # Fatal error
                        }
                        elsif ($hyphen_flag) {
                            # Previous subdomain ended in a hyphen
                            push @{$return_status}, Email::IsEmail::ERR_DOMAINHYPHENEND;  # Fatal error
                        }
                        else {
                            # Nowhere in RFC 5321 does it say explicitly that the
                            # domain part of a Mailbox must be a valid domain according
                            # to the DNS standards set out in RFC 1035, but this *is*
                            # implied in several places. For instance, wherever the idea
                            # of host routing is discussed the RFC says that the domain
                            # must be looked up in the DNS. This would be nonsense unless
                            # the domain was designed to be a valid DNS domain. Hence we
                            # must conclude that the RFC 1035 restriction on label length
                            # also applies to RFC 5321 domains.
                            #
                            # http://tools.ietf.org/html/rfc1035#section-2.3.4
                            # labels          63 octets or less
                            if ( $element_len > 63 ) {
                                push @{$return_status}, Email::IsEmail::RFC5322_LABEL_TOOLONG;
                            }
                        }

                        $end_or_die  = 0;  # CFWS is OK again now we're at the beginning of an element (although it may be obsolete CFWS)
                        $element_len = 0;
                        $element_count++;
                        $atomlist->{Email::IsEmail::COMPONENT_DOMAIN}[$element_count] = '';
                        $parsedata->{Email::IsEmail::COMPONENT_DOMAIN}               .= $token;
                    }
                    # Domain literal
                    when (Email::IsEmail::STRING_OPENSQBRACKET) {
                        if ( $parsedata->{Email::IsEmail::COMPONENT_DOMAIN} eq '' ) {
                            $end_or_die = 1;  # Domain literal must be the only component
                            $element_len++;
                            push @{$context_stack}, $context;
                            $context = Email::IsEmail::COMPONENT_LITERAL;
                            $parsedata->{Email::IsEmail::COMPONENT_DOMAIN}                .= $token;
                            $atomlist->{Email::IsEmail::COMPONENT_DOMAIN}[$element_count] .= $token;
                            $parsedata->{Email::IsEmail::COMPONENT_LITERAL}                = '';
                        }
                        else {
                            push @{$return_status}, Email::IsEmail::ERR_EXPECTING_ATEXT;  # Fatal error
                        }
                    }
                    # Folding White Space
                    when ([ Email::IsEmail::STRING_CR,
                            Email::IsEmail::STRING_SP,
                            Email::IsEmail::STRING_HTAB ]) {
                        if ( ( $token eq Email::IsEmail::STRING_CR ) and
                             ( ( ++$i == $raw_length ) or
                               ( substr( $email, $i, 1 ) ne Email::IsEmail::STRING_LF ) ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_CR_NO_LF;
                            break;
                        }  # Fatal error

                        if ( $element_len == 0 ) {
                            push @{$return_status}, ( $element_count == 0 ) ? Email::IsEmail::DEPREC_CFWS_NEAR_AT : Email::IsEmail::DEPREC_FWS;
                        }
                        else {
                            push @{$return_status}, Email::IsEmail::CFWS_FWS;
                            $end_or_die = 1;  # We can't start FWS in the middle of an element, so this better be the end
                        }

                        push @{$context_stack}, $context;
                        $context     = Email::IsEmail::CONTEXT_FWS;
                        $token_prior = $token;
                    }
                    # atext
                    default {
                        # RFC 5322 allows any atext...
                        # http://tools.ietf.org/html/rfc5322#section-3.2.3
                        #    atext           =   ALPHA / DIGIT /    ; Printable US-ASCII
                        #                        "!" / "#" /        ;  characters not including
                        #                        "$" / "%" /        ;  specials.  Used for atoms.
                        #                        "&" / "'" /
                        #                        "*" / "+" /
                        #                        "-" / "/" /
                        #                        "=" / "?" /
                        #                        "^" / "_" /
                        #                        "`" / "{" /
                        #                        "|" / "}" /
                        #                        "~"

                        # But RFC 5321 only allows letter-digit-hyphen to comply with DNS rules (RFCs 1034 & 1123)
                        # http://tools.ietf.org/html/rfc5321#section-4.1.2
                        #   sub-domain     = Let-dig [Ldh-str]
                        #
                        #   Let-dig        = ALPHA / DIGIT
                        #
                        #   Ldh-str        = *( ALPHA / DIGIT / "-" ) Let-dig
                        #
                        if ($end_or_die) {
                        # We have encountered atext where it is no longer valid
                            given($context_prior) {
                                when ([ Email::IsEmail::CONTEXT_COMMENT,
                                        Email::IsEmail::CONTEXT_FWS ]) {
                                    push @{$return_status}, Email::IsEmail::ERR_ATEXT_AFTER_CFWS;
                                }
                                when (Email::IsEmail::COMPONENT_LITERAL) {
                                    push @{$return_status}, Email::IsEmail::ERR_ATEXT_AFTER_DOMLIT;
                                }
                                default {
                                    die ("More atext found where none is allowed, but unrecognised prior context: $context_prior");
                                }
                            }
                        }

                        my $ord      = ord $token;
                        $hyphen_flag = 0;  # Assume this token isn't a hyphen unless we discover it is

                        if ( ( $ord < 33 ) or ( $ord > 126 ) or
                             ( index( Email::IsEmail::STRING_SPECIALS, $token ) ) != -1 ) {
                            push @{$return_status}, Email::IsEmail::ERR_EXPECTING_ATEXT;  # Fatal error
                        }
                        elsif ( $token eq Email::IsEmail::STRING_HYPHEN ) {
                            if ( $element_len == 0 ) {
                                # Hyphens can't be at the beginning of a subdomain
                                push @{$return_status}, Email::IsEmail::ERR_DOMAINHYPHENSTART;  # Fatal error
                            }

                            $hyphen_flag = 1;
                        } elsif ( !( ( $ord > 47 and $ord < 58 ) or ( $ord > 64 and $ord < 91 ) or ( $ord > 96 and $ord < 123 ) ) ) {
                            # Not an RFC 5321 subdomain, but still OK by RFC 5322
                            push @{$return_status}, Email::IsEmail::RFC5322_DOMAIN;
                        }

                        $parsedata->{Email::IsEmail::COMPONENT_DOMAIN}                .= $token;
                        $atomlist->{Email::IsEmail::COMPONENT_DOMAIN}[$element_count] .= $token;
                        $element_len++;
                    }
                }
            }
            #-------------------------------------------------------------
            # Domain literal
            #-------------------------------------------------------------
            when (Email::IsEmail::COMPONENT_LITERAL) {
                # http://tools.ietf.org/html/rfc5322#section-3.4.1
                #   domain-literal  =   [CFWS] "[" *([FWS] dtext) [FWS] "]" [CFWS]
                #
                #   dtext           =   %d33-90 /          ; Printable US-ASCII
                #                       %d94-126 /         ;  characters not including
                #                       obs-dtext          ;  "[", "]", or "\"
                #
                #   obs-dtext       =   obs-NO-WS-CTL / quoted-pair
                given($token) {
                    # End of domain literal
                    when (Email::IsEmail::STRING_CLOSESQBRACKET) {
                        if ( Email::IsEmail::_max($return_status) < Email::IsEmail::DEPREC ) {
                            # Could be a valid RFC 5321 address literal, so let's check

                            # http://tools.ietf.org/html/rfc5321#section-4.1.2
                            #   address-literal  = "[" ( IPv4-address-literal /
                            #                    IPv6-address-literal /
                            #                    General-address-literal ) "]"
                            #                    ; See Section 4.1.3
                            #
                            # http://tools.ietf.org/html/rfc5321#section-4.1.3
                            #   IPv4-address-literal  = Snum 3("."  Snum)
                            #
                            #   IPv6-address-literal  = "IPv6:" IPv6-addr
                            #
                            #   General-address-literal  = Standardized-tag ":" 1*dcontent
                            #
                            #   Standardized-tag  = Ldh-str
                            #                     ; Standardized-tag MUST be specified in a
                            #                     ; Standards-Track RFC and registered with IANA
                            #
                            #   dcontent       = %d33-90 / ; Printable US-ASCII
                            #                  %d94-126 ; excl. "[", "\", "]"
                            #
                            #   Snum           = 1*3DIGIT
                            #                  ; representing a decimal integer
                            #                  ; value in the range 0 through 255
                            #
                            #   IPv6-addr      = IPv6-full / IPv6-comp / IPv6v4-full / IPv6v4-comp
                            #
                            #   IPv6-hex       = 1*4HEXDIG
                            #
                            #   IPv6-full      = IPv6-hex 7(":" IPv6-hex)
                            #
                            #   IPv6-comp      = [IPv6-hex *5(":" IPv6-hex)] "::"
                            #                  [IPv6-hex *5(":" IPv6-hex)]
                            #                  ; The "::" represents at least 2 16-bit groups of
                            #                  ; zeros.  No more than 6 groups in addition to the
                            #                  ; "::" may be present.
                            #
                            #   IPv6v4-full    = IPv6-hex 5(":" IPv6-hex) ":" IPv4-address-literal
                            #
                            #   IPv6v4-comp    = [IPv6-hex *3(":" IPv6-hex)] "::"
                            #                  [IPv6-hex *3(":" IPv6-hex) ":"]
                            #                  IPv4-address-literal
                            #                  ; The "::" represents at least 2 16-bit groups of
                            #                  ; zeros.  No more than 4 groups in addition to the
                            #                  ; "::" and IPv4-address-literal may be present.
                            #
                            my $max_groups     = 8;
                            my $matchesIP      = ();
                            my $index          = -1;
                            my $addressliteral = $parsedata->{Email::IsEmail::COMPONENT_LITERAL};

                            # Extract IPv4 part from the end of the address-literal (if there is one)
                            if ( @{$matchesIP} = $addressliteral =~ /\b((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$/ ) {
                                $index = index( $addressliteral, $matchesIP->[0] );
                                if ( $index > 0 ) {
                                    $addressliteral = substr( $addressliteral, 0x0, $index ) . '0:0';  # Convert IPv4 part to IPv6 format for further testing
                                }
                            }

                            if ( $index == 0 ) {
                                # Nothing there except a valid IPv4 address, so...
                                push @{$return_status}, Email::IsEmail::RFC5321_ADDRESSLITERAL;
                            }
                            elsif ( substr( $addressliteral, 0x0, length(Email::IsEmail::STRING_IPV6TAG) ) ne Email::IsEmail::STRING_IPV6TAG ) {
                                push @{$return_status}, Email::IsEmail::RFC5322_DOMAINLITERAL;
                            }
                            else {
                                my $IPv6 = substr $addressliteral, 5;
                                $matchesIP     = [ split Email::IsEmail::STRING_COLON, $IPv6 ];  # Revision 2.7: Daniel Marschall's new IPv6 testing strategy
                                my $groupCount = scalar @{$matchesIP};
                                my $index      = index $IPv6, Email::IsEmail::STRING_DOUBLECOLON;

                                if ( $index == -1 ) {
                                    # We need exactly the right number of groups
                                    if ( $groupCount != $max_groups ) {
                                        push @{$return_status}, Email::IsEmail::RFC5322_IPV6_GRPCOUNT;
                                    }
                                }
                                else {
                                    if ( -1 != index( $IPv6, Email::IsEmail::STRING_DOUBLECOLON, $index + 1 ) ) {
                                        push @{$return_status}, Email::IsEmail::RFC5322_IPV6_2X2XCOLON;
                                    }
                                    else {
                                        if ( ( $index == 0 ) or ( $index == ( length($IPv6) - 2 ) ) ) {
                                            $max_groups++;  # RFC 4291 allows :: at the start or end of an address with 7 other groups in addition
                                        }

                                        if ( $groupCount > $max_groups ) {
                                            push @{$return_status}, Email::IsEmail::RFC5322_IPV6_MAXGRPS;
                                        }
                                        elsif ( $groupCount == $max_groups ) {
                                            push @{$return_status}, Email::IsEmail::RFC5321_IPV6DEPRECATED;  # Eliding a single "::"
                                        }
                                    }
                                }

                                # Revision 2.7: Daniel Marschall's new IPv6 testing strategy
                                if ( ( substr( $IPv6, 0x0, 1 ) eq Email::IsEmail::STRING_COLON ) and
                                     ( substr( $IPv6, 1,  1 ) ne Email::IsEmail::STRING_COLON ) ) {
                                    push @{$return_status}, Email::IsEmail::RFC5322_IPV6_COLONSTRT;  # Address starts with a single colon
                                }
                                elsif ( ( substr( $IPv6, -1 ) eq Email::IsEmail::STRING_COLON) and
                                        ( substr( $IPv6, -2, 1 ) ne Email::IsEmail::STRING_COLON ) ) {
                                    push @{$return_status}, Email::IsEmail::RFC5322_IPV6_COLONEND;  # Address ends with a single colon
                                }
                                elsif ( scalar(grep { !/^[0-9A-Fa-f]{0,4}$/ } @{$matchesIP}) != 0 ) {
                                    push @{$return_status}, Email::IsEmail::RFC5322_IPV6_BADCHAR;  # Check for unmatched characters
                                }
                                else {
                                    push @{$return_status}, Email::IsEmail::RFC5321_ADDRESSLITERAL;
                                }
                            }
                        }
                        else {
                            push @{$return_status}, Email::IsEmail::RFC5322_DOMAINLITERAL;
                        }

                        $parsedata->{Email::IsEmail::COMPONENT_DOMAIN}                .= $token;
                        $atomlist->{Email::IsEmail::COMPONENT_DOMAIN}[$element_count] .= $token;
                        $element_len++;
                        $context_prior = $context;
                        $context       = pop @{$context_stack};
                    }
                    when (Email::IsEmail::STRING_BACKSLASH) {
                        push @{$return_status}, Email::IsEmail::RFC5322_DOMLIT_OBSDTEXT;
                        push @{$context_stack}, $context;
                        $context = Email::IsEmail::CONTEXT_QUOTEDPAIR;
                    }
                    # Folding White Space
                    when ([ Email::IsEmail::STRING_CR,
                            Email::IsEmail::STRING_SP,
                            Email::IsEmail::STRING_HTAB, ]) {
                        if ( ( $token eq Email::IsEmail::STRING_CR ) and
                             ( ( ++$i == $raw_length ) or
                               ( substr( $email, $i, 1 ) ne Email::IsEmail::STRING_LF ) ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_CR_NO_LF;
                            break;
                        }  # Fatal error

                        push @{$return_status}, Email::IsEmail::CFWS_FWS;
                        push @{$context_stack}, $context;
                        $context     = Email::IsEmail::CONTEXT_FWS;
                        $token_prior = $token;
                    }
                    # dtext
                    default {
                        # http://tools.ietf.org/html/rfc5322#section-3.4.1
                        #   dtext           =   %d33-90 /          ; Printable US-ASCII
                        #                       %d94-126 /         ;  characters not including
                        #                       obs-dtext          ;  "[", "]", or "\"
                        #
                        #   obs-dtext       =   obs-NO-WS-CTL / quoted-pair
                        #
                        #   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
                        #                       %d11 /             ;  characters that do not
                        #                       %d12 /             ;  include the carriage
                        #                       %d14-31 /          ;  return, line feed, and
                        #                       %d127              ;  white space characters
                        my $ord = ord $token;

                        # CR, LF, SP & HTAB have already been parsed above
                        if ( ( $ord > 127 ) or ( $ord == 0 ) or
                             ( $token eq Email::IsEmail::STRING_OPENSQBRACKET ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_EXPECTING_DTEXT;  # Fatal error
                            break;
                        }
                        elsif ( ( $ord < 33 ) or ( $ord == 127 ) ) {
                            push @{$return_status}, Email::IsEmail::RFC5322_DOMLIT_OBSDTEXT;
                        }

                        $parsedata->{Email::IsEmail::COMPONENT_LITERAL}               .= $token;
                        $parsedata->{Email::IsEmail::COMPONENT_DOMAIN}                .= $token;
                        $atomlist->{Email::IsEmail::COMPONENT_DOMAIN}[$element_count] .= $token;
                        $element_len++;
                    }
                }
            }
            #-------------------------------------------------------------
            # Quoted string
            #-------------------------------------------------------------
            when (Email::IsEmail::CONTEXT_QUOTEDSTRING) {
                # http://tools.ietf.org/html/rfc5322#section-3.2.4
                #   quoted-string   =   [CFWS]
                #                       DQUOTE *([FWS] qcontent) [FWS] DQUOTE
                #                       [CFWS]
                #
                #   qcontent        =   qtext / quoted-pair
                given($token) {
                    # Quoted pair
                    when (Email::IsEmail::STRING_BACKSLASH) {
                        push @{$context_stack}, $context;
                        $context = Email::IsEmail::CONTEXT_QUOTEDPAIR;
                    }
                    # Folding White Space
                    # Inside a quoted string, spaces are allowed as regular characters.
                    # It's only FWS if we include HTAB or CRLF
                    when ([ Email::IsEmail::STRING_CR,
                            Email::IsEmail::STRING_HTAB, ]) {
                        if ( ( $token eq Email::IsEmail::STRING_CR ) and
                             ( ( ++$i == $raw_length ) or
                               ( substr( $email, $i, 1 ) ne Email::IsEmail::STRING_LF ) ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_CR_NO_LF;
                            break;
                        }  # Fatal error

                        # http://tools.ietf.org/html/rfc5322#section-3.2.2
                        #   Runs of FWS, comment, or CFWS that occur between lexical tokens in a
                        #   structured header field are semantically interpreted as a single
                        #   space character.

                        # http://tools.ietf.org/html/rfc5322#section-3.2.4
                        #   the CRLF in any FWS/CFWS that appears within the quoted-string [is]
                        #   semantically "invisible" and therefore not part of the quoted-string
                        $parsedata->{Email::IsEmail::COMPONENT_LOCALPART}                .= Email::IsEmail::STRING_SP;
                        $atomlist->{Email::IsEmail::COMPONENT_LOCALPART}[$element_count] .= Email::IsEmail::STRING_SP;
                        $element_len++;

                        push @{$return_status}, Email::IsEmail::CFWS_FWS;
                        push @{$context_stack}, $context;
                        $context     = Email::IsEmail::CONTEXT_FWS;
                        $token_prior = $token;
                    }
                    # End of quoted string
                    when (Email::IsEmail::STRING_DQUOTE) {
                        $parsedata->{Email::IsEmail::COMPONENT_LOCALPART}                .= $token;
                        $atomlist->{Email::IsEmail::COMPONENT_LOCALPART}[$element_count] .= $token;
                        $element_len++;
                        $context_prior = $context;
                        $context       = pop @{$context_stack};
                    }
                    # qtext
                    default {
                        # http://tools.ietf.org/html/rfc5322#section-3.2.4
                        #   qtext           =   %d33 /             ; Printable US-ASCII
                        #                       %d35-91 /          ;  characters not including
                        #                       %d93-126 /         ;  "\" or the quote character
                        #                       obs-qtext
                        #
                        #   obs-qtext       =   obs-NO-WS-CTL
                        #
                        #   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
                        #                       %d11 /             ;  characters that do not
                        #                       %d12 /             ;  include the carriage
                        #                       %d14-31 /          ;  return, line feed, and
                        #                       %d127              ;  white space characters
                        my $ord = ord $token;

                        if ( ( $ord > 127 ) or ( $ord == 0 ) or ( $ord == 10 ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_EXPECTING_QTEXT;  # Fatal error
                        }
                        elsif ( ( $ord < 32 ) or ( $ord == 127 ) ) {
                            push @{$return_status}, Email::IsEmail::DEPREC_QTEXT;
                        }

                        $parsedata->{Email::IsEmail::COMPONENT_LOCALPART}                .= $token;
                        $atomlist->{Email::IsEmail::COMPONENT_LOCALPART}[$element_count] .= $token;
                        $element_len++;
                    }
                }

                # http://tools.ietf.org/html/rfc5322#section-3.4.1
                #   If the
                #   string can be represented as a dot-atom (that is, it contains no
                #   characters other than atext characters or "." surrounded by atext
                #   characters), then the dot-atom form SHOULD be used and the quoted-
                #   string form SHOULD NOT be used.
# TODO
            }
            #-------------------------------------------------------------
            # Quoted pair
            #-------------------------------------------------------------
            when (Email::IsEmail::CONTEXT_QUOTEDPAIR) {
                # http://tools.ietf.org/html/rfc5322#section-3.2.1
                #   quoted-pair     =   ("\" (VCHAR / WSP)) / obs-qp
                #
                #   VCHAR           =  %d33-126            ; visible (printing) characters
                #   WSP             =  SP / HTAB           ; white space
                #
                #   obs-qp          =   "\" (%d0 / obs-NO-WS-CTL / LF / CR)
                #
                #   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
                #                       %d11 /             ;  characters that do not
                #                       %d12 /             ;  include the carriage
                #                       %d14-31 /          ;  return, line feed, and
                #                       %d127              ;  white space characters
                #
                # i.e. obs-qp       =  "\" (%d0-8, %d10-31 / %d127)
                my $ord = ord $token;

                if ( $ord > 127 ) {
                    push @{$return_status}, Email::IsEmail::ERR_EXPECTING_QPAIR;  # Fatal error
                }
                elsif ( ( ( $ord < 31 ) and ( $ord != 9 ) ) or ( $ord == 127 ) ) {  # SP & HTAB are allowed
                    push @{$return_status}, Email::IsEmail::DEPREC_QP;
                }

                # At this point we know where this qpair occurred so
                # we could check to see if the character actually
                # needed to be quoted at all.
                # http://tools.ietf.org/html/rfc5321#section-4.1.2
                #   the sending system SHOULD transmit the
                #   form that uses the minimum quoting possible.
# TODO: check whether the character needs to be quoted (escaped) in this context
                $context_prior = $context;
                $context       = pop @{$context_stack};  # End of qpair
                $token         = Email::IsEmail::STRING_BACKSLASH . $token;

                given($context) {
                    when (Email::IsEmail::CONTEXT_COMMENT) {}
                    when (Email::IsEmail::CONTEXT_QUOTEDSTRING) {
                        $parsedata->{Email::IsEmail::COMPONENT_LOCALPART}                .= $token;
                        $atomlist->{Email::IsEmail::COMPONENT_LOCALPART}[$element_count] .= $token;
                        $element_len += 2;  # The maximum sizes specified by RFC 5321 are octet counts, so we must include the backslash
                    }
                    when (Email::IsEmail::COMPONENT_LITERAL) {
                        $parsedata->{Email::IsEmail::COMPONENT_DOMAIN}                .= $token;
                        $atomlist->{Email::IsEmail::COMPONENT_DOMAIN}[$element_count] .= $token;
                        $element_len += 2;  # The maximum sizes specified by RFC 5321 are octet counts, so we must include the backslash
                    }
                    default {
                        die("Quoted pair logic invoked in an invalid context: $context");
                    }
                }
            }
            #-------------------------------------------------------------
            # Comment
            #-------------------------------------------------------------
            when (Email::IsEmail::CONTEXT_COMMENT) {
                # http://tools.ietf.org/html/rfc5322#section-3.2.2
                #   comment         =   "(" *([FWS] ccontent) [FWS] ")"
                #
                #   ccontent        =   ctext / quoted-pair / comment
                given($token) {
                    # Nested comment
                    when (Email::IsEmail::STRING_OPENPARENTHESIS) {
                        # Nested comments are OK
                        push @{$context_stack}, $context;
                        $context = Email::IsEmail::CONTEXT_COMMENT;
                    }
                    # End of comment
                    when (Email::IsEmail::STRING_CLOSEPARENTHESIS) {
                        $context_prior = $context;
                        $context       = pop @{$context_stack};

                        # http://tools.ietf.org/html/rfc5322#section-3.2.2
                        #   Runs of FWS, comment, or CFWS that occur between lexical tokens in a
                        #   structured header field are semantically interpreted as a single
                        #   space character.
                        #
                        # Email::IsEmail() author's note: This *cannot* mean that we must add a
                        # space to the address wherever CFWS appears. This would result in
                        # any addr-spec that had CFWS outside a quoted string being invalid
                        # for RFC 5321.
#                        if ( ( $context == Email::IsEmail::COMPONENT_LOCALPART ) or
#                             ( $context == Email::IsEmail::COMPONENT_DOMAIN ) ) {
#                            $parsedata->{$context} .= Email::IsEmail::STRING_SP;
#                            $atomlist->{$context}[$element_count] .= Email::IsEmail::STRING_SP;
#                            $element_len++;
#                        }
                    }
                    # Quoted pair
                    when (Email::IsEmail::STRING_BACKSLASH) {
                        push @{$context_stack}, $context;
                        $context = Email::IsEmail::CONTEXT_QUOTEDPAIR;
                    }
                    # Folding White Space
                    when ([ Email::IsEmail::STRING_CR,
                            Email::IsEmail::STRING_SP,
                            Email::IsEmail::STRING_HTAB ]) {
                        if ( ( $token eq Email::IsEmail::STRING_CR ) and
                             ( ( ++$i == $raw_length ) or
                               ( substr( $email, $i, 1 ) ne Email::IsEmail::STRING_LF ) ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_CR_NO_LF;
                            break;
                        }  # Fatal error

                        push @{$return_status}, Email::IsEmail::CFWS_FWS;

                        push @{$context_stack}, $context;
                        $context     = Email::IsEmail::CONTEXT_FWS;
                        $token_prior = $token;
                    }
                    # ctext
                    default {
                        # http://tools.ietf.org/html/rfc5322#section-3.2.3
                        #   ctext           =   %d33-39 /          ; Printable US-ASCII
                        #                       %d42-91 /          ;  characters not including
                        #                       %d93-126 /         ;  "(", ")", or "\"
                        #                       obs-ctext
                        #
                        #   obs-ctext       =   obs-NO-WS-CTL
                        #
                        #   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
                        #                       %d11 /             ;  characters that do not
                        #                       %d12 /             ;  include the carriage
                        #                       %d14-31 /          ;  return, line feed, and
                        #                       %d127              ;  white space characters
                        my $ord = ord $token;

                        if ( ( $ord > 127 ) or ( $ord == 0 ) or ( $ord == 10 ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_EXPECTING_CTEXT;  # Fatal error
                            break;
                        }
                        elsif ( ( $ord < 32 ) or ( $ord == 127 ) ) {
                            push @{$return_status}, Email::IsEmail::DEPREC_CTEXT;
                        }
                    }
                }
            }
            #-------------------------------------------------------------
            # Folding White Space
            #-------------------------------------------------------------
            when (Email::IsEmail::CONTEXT_FWS) {
                # http://tools.ietf.org/html/rfc5322#section-3.2.2
                #   FWS             =   ([*WSP CRLF] 1*WSP) /  obs-FWS
                #                                          ; Folding white space

                # But note the erratum:
                # http://www.rfc-editor.org/errata_search.php?rfc=5322&eid=1908:
                #   In the obsolete syntax, any amount of folding white space MAY be
                #   inserted where the obs-FWS rule is allowed.  This creates the
                #   possibility of having two consecutive "folds" in a line, and
                #   therefore the possibility that a line which makes up a folded header
                #   field could be composed entirely of white space.
                #
                #   obs-FWS         =   1*([CRLF] WSP)
                if ( $token_prior eq Email::IsEmail::STRING_CR ) {
                    if ( $token eq Email::IsEmail::STRING_CR ) {
                        push @{$return_status}, Email::IsEmail::ERR_FWS_CRLF_X2;  # Fatal error
                        break;
                    }

                    if ( ++$crlf_count > 1 ) {
                        push @{$return_status}, Email::IsEmail::DEPREC_FWS;  # Multiple folds = obsolete FWS
                    }
                }

                given($token) {
                    when (Email::IsEmail::STRING_CR) {
                        if ( ( ++$i == $raw_length ) or
                             ( substr( $email, $i, 1 ) ne Email::IsEmail::STRING_LF ) ) {
                            push @{$return_status}, Email::IsEmail::ERR_CR_NO_LF;  # Fatal error
                        }
                    }
                    when ([ Email::IsEmail::STRING_SP,
                            Email::IsEmail::STRING_HTAB, ]) {
                    }
                    default {
                        if ( $token_prior eq Email::IsEmail::STRING_CR ) {
                            push @{$return_status}, Email::IsEmail::ERR_FWS_CRLF_END;  # Fatal error
                            break;
                        }

                        $crlf_count    = 0;
                        $context_prior = $context;
                        $context       = pop @{$context_stack};  # End of FWS

                        # http://tools.ietf.org/html/rfc5322#section-3.2.2
                        #   Runs of FWS, comment, or CFWS that occur between lexical tokens in a
                        #   structured header field are semantically interpreted as a single
                        #   space character.
                        #
                        # Email::IsEmail() author's note: This *cannot* mean that we must add a
                        # space to the address wherever CFWS appears. This would result in
                        # any addr-spec that had CFWS outside a quoted string being invalid
                        # for RFC 5321.
#                        if ( ( $context == Email::IsEmail::COMPONENT_LOCALPART ) or
#                             ( $context == Email::IsEmail::COMPONENT_DOMAIN ) ) {
#                            $parsedata->{$context} .= Email::IsEmail::STRING_SP;
#                            $atomlist->{$context}[$element_count] .= Email::IsEmail::STRING_SP;
#                            $element_len++;
#                        }
                        $i--;  # Look at this token again in the parent context
                    }
                }

                $token_prior = $token;
            }
            #-------------------------------------------------------------
            # A context we aren't expecting
            #-------------------------------------------------------------
            default: {
                die("Unknown context: $context");
            }
        }

        if ( Email::IsEmail::_max($return_status) > Email::IsEmail::RFC5322 ) {
            last;  # No point going on if we've got a fatal error
        }
    }

    # Some simple final tests
    if ( Email::IsEmail::_max($return_status) < Email::IsEmail::RFC5322 ) {
        if ( $context == Email::IsEmail::CONTEXT_QUOTEDSTRING ) {
            push @{$return_status}, Email::IsEmail::ERR_UNCLOSEDQUOTEDSTR;  # Fatal error
        }
        elsif ( $context == Email::IsEmail::CONTEXT_QUOTEDPAIR ) {
            push @{$return_status}, Email::IsEmail::ERR_BACKSLASHEND;  # Fatal error
        }
        elsif ( $context == Email::IsEmail::CONTEXT_COMMENT ) {
            push @{$return_status}, Email::IsEmail::ERR_UNCLOSEDCOMMENT;  # Fatal error
        }
        elsif ( $context == Email::IsEmail::COMPONENT_LITERAL ) {
            push @{$return_status}, Email::IsEmail::ERR_UNCLOSEDDOMLIT;  # Fatal error
        }
        elsif ( $token eq Email::IsEmail::STRING_CR ) {
            push @{$return_status}, Email::IsEmail::ERR_FWS_CRLF_END;  # Fatal error
        }
        elsif ( $parsedata->{Email::IsEmail::COMPONENT_DOMAIN} eq '' ) {
            push @{$return_status}, Email::IsEmail::ERR_NODOMAIN;  # Fatal error
        }
        elsif ( $element_len == 0 ) {
            push @{$return_status}, Email::IsEmail::ERR_DOT_END;  # Fatal error
        }
        elsif ( $hyphen_flag ) {
            push @{$return_status}, Email::IsEmail::ERR_DOMAINHYPHENEND;  # Fatal error
        }
        # http://tools.ietf.org/html/rfc5321#section-4.5.3.1.2
        #   The maximum total length of a domain name or number is 255 octets.
        elsif ( length($parsedata->{Email::IsEmail::COMPONENT_DOMAIN}) > 255 ) {
            push @{$return_status}, Email::IsEmail::RFC5322_DOMAIN_TOOLONG;
        }
        # http://tools.ietf.org/html/rfc5321#section-4.1.2
        #   Forward-path   = Path
        #
        #   Path           = "<" [ A-d-l ":" ] Mailbox ">"
        #
        # http://tools.ietf.org/html/rfc5321#section-4.5.3.1.3
        #   The maximum total length of a reverse-path or forward-path is 256
        #   octets (including the punctuation and element separators).
        #
        # Thus, even without (obsolete) routing information, the Mailbox can
        # only be 254 characters long. This is confirmed by this verified
        # erratum to RFC 3696:
        #
        # http://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690
        #   However, there is a restriction in RFC 2821 on the length of an
        #   address in MAIL and RCPT commands of 254 characters.  Since addresses
        #   that do not fit in those fields are not normally useful, the upper
        #   limit on address lengths should normally be considered to be 254.
        elsif ( length( $parsedata->{Email::IsEmail::COMPONENT_LOCALPART} .
                        Email::IsEmail::STRING_AT .
                        $parsedata->{Email::IsEmail::COMPONENT_DOMAIN} ) > 254 ) {
            push @{$return_status}, Email::IsEmail::RFC5322_TOOLONG;
        }
        # http://tools.ietf.org/html/rfc1035#section-2.3.4
        # labels          63 octets or less
        elsif ( $element_len > 63 ) {
            push @{$return_status}, Email::IsEmail::RFC5322_LABEL_TOOLONG;
        }
    }

    # Check DNS?
    my $dns_checked = 0;

    if ( $checkDNS and ( Email::IsEmail::_max($return_status) < Email::IsEmail::DNSWARN ) ) {
        # http://tools.ietf.org/html/rfc5321#section-2.3.5
        #   Names that can
        #   be resolved to MX RRs or address (i.e., A or AAAA) RRs (as discussed
        #   in Section 5) are permitted, as are CNAME RRs whose targets can be
        #   resolved, in turn, to MX or address RRs.
        #
        # http://tools.ietf.org/html/rfc5321#section-5.1
        #   The lookup first attempts to locate an MX record associated with the
        #   name.  If a CNAME record is found, the resulting name is processed as
        #   if it were the initial name. ... If an empty list of MXs is returned,
        #   the address is treated as if it was associated with an implicit MX
        #   RR, with a preference of 0, pointing to that host.
        #
        # Email::IsEmail() author's note: We will regard the existence of a CNAME to be
        # sufficient evidence of the domain's existence. For performance reasons
        # we will not repeat the DNS lookup for the CNAME's target, but we will
        # raise a warning because we didn't immediately find an MX record.
        eval { require Net::DNS }
            unless $INC{'Net/DNS.pm'};
        if ( $INC{'Net/DNS.pm'} ) {
            my $domain = $parsedata->{Email::IsEmail::COMPONENT_DOMAIN};
            if ( $element_count == 0 ) {
                $domain .= '.';  # Checking TLD DNS seems to work only if you explicitly check from the root
            }

            my @domains = Net::DNS::rr( $domain, 'MX' );

            if ( scalar @domains == 0 ) {
                push @{$return_status}, Email::IsEmail::DNSWARN_NO_MX_RECORD;  # MX-record for domain can't be found

# TODO: check also AAAA and CNAME
                @domains = Net::DNS::rr( $domain, 'A' );

                if ( scalar @domains == 0 ) {
                    push @{$return_status}, Email::IsEmail::DNSWARN_NO_RECORD;  # No usable records for the domain can be found
                }
            }
        }
    }

    # Check for TLD addresses
    # -----------------------
    # TLD addresses are specifically allowed in RFC 5321 but they are
    # unusual to say the least. We will allocate a separate
    # status to these addresses on the basis that they are more likely
    # to be typos than genuine addresses (unless we've already
    # established that the domain does have an MX record)
    #
    # http://tools.ietf.org/html/rfc5321#section-2.3.5
    #   In the case
    #   of a top-level domain used by itself in an email address, a single
    #   string is used without any dots.  This makes the requirement,
    #   described in more detail below, that only fully-qualified domain
    #   names appear in SMTP transactions on the public Internet,
    #   particularly important where top-level domains are involved.
    #
    # TLD format
    # ----------
    # The format of TLDs has changed a number of times. The standards
    # used by IANA have been largely ignored by ICANN, leading to
    # confusion over the standards being followed. These are not defined
    # anywhere, except as a general component of a DNS host name (a label).
    # However, this could potentially lead to 123.123.123.123 being a
    # valid DNS name (rather than an IP address) and thereby creating
    # an ambiguity. The most authoritative statement on TLD formats that
    # the author can find is in a (rejected!) erratum to RFC 1123
    # submitted by John Klensin, the author of RFC 5321:
    #
    # http://www.rfc-editor.org/errata_search.php?rfc=1123&eid=1353
    #   However, a valid host name can never have the dotted-decimal
    #   form #.#.#.#, since this change does not permit the highest-level
    #   component label to start with a digit even if it is not all-numeric.
    if ( !$dns_checked and ( Email::IsEmail::_max($return_status) < Email::IsEmail::DNSWARN ) ) {
        if ( $element_count == 0 ) {
            push @{$return_status}, Email::IsEmail::RFC5321_TLD;
        }

        if (looks_like_number(substr( $atomlist->{Email::IsEmail::COMPONENT_DOMAIN}[$element_count], 0x0, 1 ))) {
            push @{$return_status}, Email::IsEmail::RFC5321_TLDNUMERIC;
        }
    }

    $return_status   = Email::IsEmail::_unique($return_status);
    my $final_status = Email::IsEmail::_max($return_status);

    if ( scalar @{$return_status} != 1 ) {
        shift @{$return_status};  # remove redundant Email::IsEmail::VALID
    }

    $parsedata->{'status'} = $return_status;

    if ( $final_status < $threshold ) {
        $final_status = Email::IsEmail::VALID;
    }

    return ($diagnose) ? $final_status : ( $final_status < Email::IsEmail::THRESHOLD );
}

sub _max {
    my ( $array_ref ) = @_;

    my $res = VALID;

    foreach my $val ( @{$array_ref} ) {
        if ( $val > $res ) {
            $res = $val;
        }
    }

    return $res;
}


sub _unique {
    my ( $array_ref ) = @_;

    my %seen;

    return [ grep !$seen{$_}++, @{$array_ref} ];
}


=head1 AUTHOR

Original PHP version Dominic Sayers C<< <dominic@sayers.cc> >>

Perl port Leandr Khaliullov, C<< <leandr at cpan.org> >>

=encoding utf8

=head1 COPYRIGHT

Copyright © 2008-2011, Dominic Sayers.

Copyright 2016 Leandr Khaliullov.


All rights reserved.

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-isemail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-IsEmail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::IsEmail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-IsEmail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-IsEmail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-IsEmail>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-IsEmail/>

=back


=head1 ACKNOWLEDGEMENTS

    - Dominic Sayers (original PHP version of is_email)
    - Daniel Marschall (test schemas)
    - Umberto Salsi (PHPLint)

=head1 LICENSE

This program is released under the following license: BSD

See F<http://www.opensource.org/licenses/bsd-license.php>

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    - Neither the name of Dominic Sayers nor the names of its contributors may be
      used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Email::IsEmail
