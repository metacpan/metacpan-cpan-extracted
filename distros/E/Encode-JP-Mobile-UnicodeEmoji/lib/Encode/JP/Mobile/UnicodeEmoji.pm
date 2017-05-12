package Encode::JP::Mobile::UnicodeEmoji;
use strict;
use warnings;
use base qw(Encode::Encoding);
use Encode::Alias;
use Encode qw(:fallbacks);
use Encode::JP::Mobile;
use Encode::JP::Emoji;
use Encode::JP::Emoji::Property;
use Encode::MIME::Name;
our $VERSION = '0.012';

__PACKAGE__->Define(qw(x-utf8-jp-mobile-unicode-emoji));
$Encode::MIME::Name::MIME_NAME_OF{'x-utf8-jp-mobile-unicode-emoji'} = 'UTF-8';

sub _encoding1() { Encode::find_encoding('x-utf8-e4u-unicode') }
sub _encoding2() { Encode::find_encoding('x-utf8-e4u-docomo') }
sub _encoding3() { Encode::find_encoding('x-utf8-docomo') }


sub decode($$;$) {
    my ($self, $str, $chk) = @_;

    $str = Encode::decode($self->_encoding1 => $str, $chk);
    if ($str =~ /\p{InEmojiGoogle}/) {
        $str = Encode::encode($self->_encoding2 => $str, $chk);
        $str = Encode::decode($self->_encoding3 => $str, $chk);
    }
    $str;
}

sub encode($$;$) {
    my ( $self, $str, $chk ) = @_;

    if ($str =~ /\p{InEmojiDoCoMo}/) {
        $str = Encode::encode($self->_encoding3 => $str, $chk);
        $str = Encode::decode($self->_encoding2 => $str, $chk);
    }
    Encode::encode($self->_encoding1 => $str, $chk);
}

1;
__END__

=head1 NAME

Encode::JP::Mobile::UnicodeEmoji - Unicode Emoji mapping for Encode::JP::Mobile

=head1 SYNOPSIS

    use Encode qw/encode decode/;
    use Encode::JP::Mobile::UnicodeEmoji;
    
    my $str = '...';
    $str = decode('x-utf8-jp-mobile-unicode-emoji', $str);
    $str = encode('x-utf8-jp-Mobile-unicode-emoji', $str);

=head1 DESCRIPTION

Encode::JP::Mobile::UnicodeEmoji is encoding module for Unicode Emoji to
Enocde::JP::Mobile's Emoji mapping.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
