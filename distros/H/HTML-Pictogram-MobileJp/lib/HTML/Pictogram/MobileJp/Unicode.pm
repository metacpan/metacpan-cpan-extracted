package HTML::Pictogram::MobileJp::Unicode;
use strict;
use warnings;
use 5.00800;
use HTML::Pictogram::MobileJp::Unicode::Map;
use HTML::Pictogram::MobileJp::Util qw/is_iphone/;

sub convert {
    my ( $class, $ma, $html ) = @_;

    $html =~ s{(&#x([0-9a-f]{4});)}{
        if ($ma->is_docomo) {
            $1;
        } elsif ($ma->is_softbank || is_iphone($ma->user_agent)) {
            if (my $e = $SOFTBANK->{$2}) {
                "&#x$e;";
            } else {
                $1;
            }
        } elsif ($ma->is_ezweb) {
            if (my $e = $EZWEB->{$2}) {
                sprintf '<img localsrc="%d" />', $e;
            } else {
                $1;
            }
        } else {
            # non-mobile
            $1;
        }
    }gei;

    $html;
}

1;
__END__

=encoding utf8

=head1 NAME

HTML::Pictogram::MobileJp::Unicode - &#xXXXX; とかくと3キャリで表示できるように変換できるライブラリ

=head1 SYNOPSIS

    use HTML::Pictogram::MobileJp::Unicode;
    use HTTP::MobileAgent;

    my $ma = HTTP::MobileAgent->new();
    HTML::Pictogram::MobileJp::Unicode->convert($ma, $html);

=head1 DESCRIPTION

&#xXXXX; のようにユニコードの実体参照で絵文字を記述しておくと、それを各キャリヤにあわせた表記に変更してくれるライブラリ。

サポート対象は 3G の3キャリです。

絵文字の変換マップは Text_Pictogram_Mobile のものを拝借してます。

絵文字として変換可能ではない &#xXXXX; は、変更されません。

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<http://openpear.org/package/Text_Pictogram_Mobile>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
