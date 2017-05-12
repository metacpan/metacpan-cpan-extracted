package HTML::Pictogram::MobileJp::EmojiNumber;
use strict;
use warnings;
use 5.00800;
use HTML::Pictogram::MobileJp::EmojiNumber::Map;
use HTML::Pictogram::MobileJp::Util qw/is_iphone/;

sub convert {
    my ( $class, $ma, $html ) = @_;

    $html =~ s{\[emoji:(\d+)\]}{
        if ($ma->is_docomo) {
            my $i = $DOCOMO->{$1};
            "&#x$i;";
        } elsif ($ma->is_softbank || is_iphone($ma->user_agent)) {
            my $s = $SOFTBANK->{$1};
            if ($s =~ /^\w+$/) {
                "&#x$s;";
            } else {
                $s;
            }
        } elsif ($ma->is_ezweb) {
            my $e = $EZWEB->{$1};
            if ($e =~ /^[0-9]+$/) {
                sprintf '<img localsrc="%d" />', $e;
            } else {
                $e;
            }
        } else {
            # non-mobile
            "[emoji:$1]";
        }
    }ge;

    $html;
}

1;
__END__

=encoding utf8

=head1 NAME

HTML::Pictogram::MobileJp::EmojiNumber - [emoji:1] みたいに絵文字を記述できるひと

=head1 SYNOPSIS

    use HTML::Pictogram::MobileJp::EmojiNumber;
    use HTTP::MobileAgent;

    my $ma = HTTP::MobileAgent->new();
    HTML::Pictogram::MobileJp::EmojiNumber->convert($ma, $html);

=head1 DESCRIPTION

[emoji:1] みたいな形式で絵文字を記述しておくと、それを各キャリヤにあわせた表記に変更してくれるライブラリ。

数字部分は docomo の絵文字番号です。

拡張絵文字を利用したい場合は、拡張絵文字番号 + 1000 で記述してください。たとえば拡1は [emoji:1001] と記述してください。

サポート対象は 3G の3キャリです。

絵文字の変換マップは Text_Pictogram_Mobile のものを拝借してます。

変換不可能な絵文字は、絵文字の名称が表示されます。

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<http://openpear.org/package/Text_Pictogram_Mobile>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
