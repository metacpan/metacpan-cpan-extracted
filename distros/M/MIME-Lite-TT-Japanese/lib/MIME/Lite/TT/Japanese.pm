package MIME::Lite::TT::Japanese;
use strict;
use vars qw($VERSION);
$VERSION = '0.08';

use base qw(MIME::Lite::TT);
use Jcode;
use DateTime::Format::Mail;

sub _after_process {
	my $class = shift;
	my %options = (
        Type => 'text/plain; charset=iso-2022-jp',
        Encoding => '7bit',
        Datestamp => 0,
        Date => DateTime::Format::Mail->format_datetime( DateTime->now->set_time_zone('Asia/Tokyo') ),
        @_,
    );
	$options{Subject} = encode_header( $options{Subject}, $options{Icode});
    $options{From}    = encode_header( $options{From}, $options{Icode});
	$options{Data}    = encode_body( $options{Data}, $options{Icode}, $options{LineWidth} );
    delete $options{LineWidth};
	return %options;
}

sub encode_header {
    my ($str, $icode) = @_;
    $str = remove_utf8_flag($str);
    return Jcode->new($str, $icode || guess_encoding($str) )->mime_encode;
}

sub encode_body {
    my ($str, $icode, $line_width) = @_;
    $str = remove_utf8_flag($str);
    $str =~ s/\x0D\x0A/\n/g;
    $str =~ tr/\r/\n/;
    my $encoding = $icode || guess_encoding($str);
    unless ( $line_width eq '0') {
        return join "\n", map {
            Jcode->new($_, $encoding)->jfold($line_width)->jis
        } split /\n/, $str;
    } else {
        return Jcode->new($str, $encoding )->jis;
    }
}

sub guess_encoding {
    my ($str) = @_;
    my $enc = Jcode::getcode($str) || 'euc';
    $enc = 'euc' if $enc eq 'ascii' || $enc eq 'binary';
    return $enc;
}

sub remove_utf8_flag { pack 'C0A*', $_[0] }

1;
__END__

=head1 NAME

MIME::Lite::TT::Japanese - MIME::Lite::TT with Japanese character code

=head1 SYNOPSIS

  use MIME::Lite::TT::Japanese;

  my $msg = MIME::Lite::TT::Japanese->new(
              From => 'me@myhost.com',
              To => 'you@yourhost.com',
              Subject => 'Hi',
              Template => \$template,
              TmplParams => \%params, 
              TmplOptions => \%options,
              Icode => 'sjis',
              LineWidth => 72,
            );

  $msg->send();

=head1 DESCRIPTION

MIME::Lite::TT::Japanese is subclass of MIME::Lite::TT.
This module helps creation of Japanese mail.

=head2 FEATURE

=over

=item *

'text/plain; charset=iso-2022-jp' is set to 'Type' of MIME::Lite option by default.

=item *

'7bit' is set to 'Encoding' of MIME::Lite option by default.

=item *

convert the subject and the from to MIME-Header documented in RFC1522.

=item *
convert the mail text to JIS.

=item *

set Japanese local-time at Date field by default.

=item *

auto linefeed (by default changes line per 72 bytes)

=back

=head1 ADDITIONAL OPTIONS

=head2 Icode

Set the character code of the subject, the from and the template.
'euc', 'sjis' or 'utf8' can be set.
If no value is set, this module try to guess encoding.
If it is failed to guess encoding, 'euc' is assumed.

=head2 LineWidth

number of characters in which it changes line automatically.(the unit is byte. default is 72)
Set 0 (zero) if you do not want to change line automatically.


=head1 AUTHOR

Author E<lt>horiuchi@vcube.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MIME::Lite::TT>

=cut
