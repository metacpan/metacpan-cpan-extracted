package Lingua::JA::Mail;

our $VERSION = '0.03'; # 2005-09-23 (since 2003-03-05)

our @ISA = qw(Lingua::JA::Mail::Header);
use Lingua::JA::Mail::Header;
# When you `require' this base module for some reason,
# you had better specify absolute path to the module.

use 5.008;
use strict;
use warnings;
use Carp;

use Encode;

sub body {
    my($self, $string) = @_;
    $$self{'body'} = $string;
    return $self;
}

sub build {
    my $self = shift;
    my @key = $self->_header_order;
    my @header;
    foreach my $key (@key) {
        unless ($key eq 'body') {
            push(@header, "$key: $$self{$key}");
        }
    }
    return join("\n", @header);
}

sub compose {
    my $self = shift;
    my $header = $self->build;
    
    chomp(my $header2 = <<"EOF");
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit
X-Mail-Composer: Mail.pm v$VERSION (Lingua::JA::Mail http://www.cpan.org/)
EOF
    
    $header = join("\n", $header, $header2);
    
    $self->_preconvert();
    my $body = encode('iso-2022-jp', $$self{'body'});
    
    return "$header\n\n$body";
}

sub _preconvert {
    my $self = shift;
    
    utf8::decode(my $string = $$self{'body'});
    $string =~ tr/\x{005C}\x{00A5}\x{2014}\x{203E}\x{2225}\x{FF0D}\x{FF5E}\x{FFE0}\x{FFE1}\x{FFE2}/\x{FF3C}\x{FFE5}\x{2015}\x{FFE3}\x{2016}\x{2212}\x{301C}\x{00A2}\x{00A3}\x{00AC}/;
    
    $$self{'body'} = $string;
    
    return $self;
}

sub sendmail {
    my($self, $sendmail) = @_;
    unless ($sendmail) {
        $sendmail = 'sendmail';
    }
    
    my $mail = $self->compose;
    
    open(MAIL, "| $sendmail -t -i")
      or croak "failed piping to $sendmail";
    print MAIL $mail;
    close MAIL;
    return $self;
}
########################################################################
1;
__END__

=head1 NAME

Lingua::JA::Mail - compose mail with Japanese charset

=head1 SYNOPSIS

 use utf8;
 use Lingua::JA::Mail;
 
 $mail = Lingua::JA::Mail->new;
 
 $mail->add_from('taro@cpan.tld', 'YAMADA, Taro');
 
 # display-name is omitted:
  $mail->add_to('kaori@cpan.tld');
 # with a display-name in US-ASCII characters:
  $mail->add_to('sakura@cpan.tld', 'Sakura HARUNO');
 # with a display-name containing Japanese characters:
  $mail->add_to('yuri@cpan.tld', 'NAME CONTAINING JAPANESE CHARS');
 
 # mail subject containing Japanese characters:
  $mail->subject('Subject', 'SUBJECT CONTAINING JAPANESE CHARS');
 
 # mail body    containing Japanese characters:
  $mail->body('BODY CONTAINING JAPANESE CHARS');
 
 # compose and output
  print $mail->compose;

=head1 DESCRIPTION

This module is produced mainly for Japanese Perl programmers those who wants to compose an email with Perl extention.

For some reasons, most Japanese internet users have chosen ISO-2022-JP 7bit character encoding for email rather than the other 8bit encodings (eg. EUC-JP, Shift_JIS).

We can use ISO-2022-JP encoded Japanese text as message body safely in an email.

But we should not use ISO-2022-JP encoded Japanese text as a header. We should escape some reserved C<special> characters before composing a header. To enable it, we encode ISO-2022-JP encoded Japanese text with MIME Base64 encoding. Thus MIME Base64 encoded ISO-2022-JP encoded Japanese text is safely using in a mail header.

This module has developed to intend to automate those kinds of operations.

=head1 METHODS

=head2 Constructor Method

=over

=item new

This method is the constructor class method.

=back

=head2 Building the Header Fields

See L<Lingua::JA::Mail::Header> for the descriptions.

=head2 Compose the Message Body with Header Fields.

=over

=item body($text)

This method specifies the body of the message. It can contain Japanese characters.

Note: RFC1468 describes about a line should be tried to keep length within 80 display columns. Then each JIS X 0208 character takes two columns, and the escape sequences do not take any. This module itself does not provide any auto-folding functions. See L<Lingua::JA::Fold> about the folding of Japanese text.

=item compose

This method gathers and builds the header fields, then convine with the body of the message and then returns the overall message.

=item sendmail([$location])

This method composes the overall message (see C<compose>) and pipes the data to the sendmail program.
Posts a mail using sendmail program.

At the default, it is supposed that the sendmail command is `sendmail' under a location of systems's PATH environmental variable. You can specify exact location. Ex:

 $mail->sendmail('/usr/bin/sendmail');

=back

=head1 SEE ALSO

=over

=item module: L<Lingua::JA::Mail::Header>

=item RFC2822: L<http://www.ietf.org/rfc/rfc2822.txt> (Mail)

=item RFC2045: L<http://www.ietf.org/rfc/rfc2045.txt> (MIME)

=item RFC2046: L<http://www.ietf.org/rfc/rfc2046.txt> (MIME)

=item RFC2047: L<http://www.ietf.org/rfc/rfc2047.txt> (MIME)

=item RFC1468: L<http://www.ietf.org/rfc/rfc1468.txt> (ISO-2022-JP)

=item module: L<Encode>

=item module: L<MIME::Base64>

=back

=head1 NOTES

This module runs under Unicode/UTF-8 environment (hence Perl5.8 or later is required), you should input octets with UTF-8 charset. Please C<use utf8;> pragma to enable to detect strings as UTF-8 in your source code.

=head1 TO DO

=over

=item Attachment file support.

=back

=head1 THANKS TO:

=over

=item Koichi TANIGUCHI for the suggestions.

=back

=head1 AUTHOR

Masanori HATA E<lt>lovewing@dream.big.or.jpE<gt> (Saitama, JAPAN)

=head1 COPYRIGHT

Copyright (c) 2003-2005 Masanori HATA. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
