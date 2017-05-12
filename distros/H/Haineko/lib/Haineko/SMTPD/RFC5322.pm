package Haineko::SMTPD::RFC5322;
use strict;
use warnings;

# Regular expression of valid RFC-5322 email address(<addr-spec>)
my $Rx = { 'rfc5322' => undef, 'ignored' => undef, 'domain' => undef, };

# See http://www.ietf.org/rfc/rfc5322.txt
#  or http://www.ex-parrot.com/pdw/Mail-RFC822-Address.html ...
#   addr-spec       = local-part "@" domain
#   local-part      = dot-atom / quoted-string / obs-local-part
#   domain          = dot-atom / domain-literal / obs-domain
#   domain-literal  = [CFWS] "[" *([FWS] dtext ) [FWS] "]" [CFWS]
#   dtext           = %d33-90 /          ; Printable US-ASCII
#                     %d94-126 /         ;  characters not including
#                     obs-dtext          ;  "[", "]", or "\"
#                     
#                    
BUILD_REGULAR_EXPRESSIONS: {
    my $atom = qr([a-zA-Z0-9_!#\$\%&'*+/=?\^`{}~|\-]+)o;
    my $quoted_string = qr/"(?:\\[^\r\n]|[^\\"])*"/o;
    my $domain_literal = qr/\[(?:\\[\x01-\x09\x0B-\x0c\x0e-\x7f]|[\x21-\x5a\x5e-\x7e])*\]/o;
    my $dot_atom = qr/$atom(?:[.]$atom)*/o;
    my $local_part = qr/(?:$dot_atom|$quoted_string)/o;
    my $domain = qr/(?:$dot_atom|$domain_literal)/o;

    $Rx->{'rfc5322'} = qr/$local_part[@]$domain/o;
    $Rx->{'ignored'} = qr/$local_part[.]*[@]$domain/o;
    $Rx->{'domain'}  = qr/$domain/o;
}

sub is_emailaddress {
    my $class = shift;
    my $email = shift || return 0;  # (String) Email address

    return 0 if $email =~ m{([\x00-\x1f]|\x1f)};
    return 1 if $email =~ $Rx->{'ignored'};
    return 0;
}

sub is_domainpart {
    my $class = shift;
    my $dpart = shift || return 0;  # (String) Domain part of an email address

    return 1 if $dpart =~ m{\A[-0-9A-Za-z.]+[.][A-Za-z]+\z};
    return 0;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::RFC5322 - Tools related RFC-5322

=head1 SYNOPSIS

    use Haineko::SMTPD::RFC5322;
    my $x = Haineko::SMTPD::RFC5322->is_emailaddress( 'kijitora@example.jp' );
    my $y = Haineko::SMTPD::RFC5322->is_domainpart( 'example.jp' ):

=head1 CLASS METHODS

=head2 B<is_emailaddress( I<Email address> )>

is_emailaddress() checks whether the argument is valid email address or not.

    my $x = 'Stray cat';
    my $y = 'kijitora@example.jp';
    my $z = '';

    print Haineko::SMTPD::RFC5322->is_emailaddress( $x );  # 0
    print Haineko::SMTPD::RFC5322->is_emailaddress( $y );  # 1
    print Haineko::SMTPD::RFC5322->is_emailaddress( $z );  # 0

=head2 B<is_domainpart( I<Domain part>) >

is_domainpart() returns checks the argument is valid domain part or not.

    print Haineko::SMTPD::RFC5322->is_domainpart( 'kijitora' );    # 0
    print Haineko::SMTPD::RFC5322->is_domainpart( 'example.jp.' ); # 1
    print Haineko::SMTPD::RFC5322->is_domainpart( '' );        # 0

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
