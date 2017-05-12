package Lingua::JA::Onbiki;

use strict;
use warnings;
use utf8;
use re '/amsx';

use Exporter 'import';
our @EXPORT_OK = qw(onbiki2boin);

our $VERSION = '0.01';

my %boins = qw(
  あ あ  い い  う う  え え  お お
  か あ  き い  く う  け え  こ お
  さ あ  し い  す う  せ え  そ お
  た あ  ち い  つ う  て え  と お
  な あ  に い  ぬ う  ね え  の お
  は あ  ひ い  ふ う  へ え  ほ お
  ま あ  み い  む う  め え  も お
  や あ         ゆ う         よ お
  ら あ  り い  る う  れ え  ろ お
  わ あ                ゑ え  ん ん
  が あ  ぎ い  ぐ う  げ え  ご お
  ざ あ  じ い  ず う  ぜ え  ぞ お
  だ あ  ぢ い  づ う  で え  ど お
  ば あ  び い  ぶ う  べ え  ぼ お
  ぱ あ  ぴ い  ぷ う  ぺ え  ぽ お
  ぁ ぁ  ぃ ぃ  ぅ ぅ  ぇ ぇ  ぉ ぉ
  ゃ ぁ         ゅ ぅ         ょ ぉ
  ゎ ぁ
  ア ア  イ イ  ウ ウ  エ エ  オ オ
  カ ア  キ イ  ク ウ  ケ エ  コ オ
  サ ア  シ イ  ス ウ  セ エ  ソ オ
  タ ア  チ イ  ツ ウ  テ エ  ト オ
  ナ ア  ニ イ  ヌ ウ  ネ エ  ノ オ
  ハ ア  ヒ イ  フ ウ  ヘ エ  ホ オ
  マ ア  ミ イ  ム ウ  メ エ  モ オ
  ヤ ア         ユ ウ         ヨ オ
  ラ ア  リ イ  ル ウ  レ エ  ロ オ
  ワ ア  ヰ イ         ヱ エ  ン ン
  ガ ア  ギ イ  グ ウ  ゲ エ  ゴ オ
  ザ ア  ジ イ  ズ ウ  ゼ エ  ゾ オ
  ダ ア  ヂ イ  ヅ ウ  デ エ  ド オ
  バ ア  ビ イ  ブ ウ  ベ エ  ボ オ
  パ ア  ピ イ  プ ウ  ペ エ  ポ オ
  ァ ァ  ィ ィ  ゥ ゥ  ェ ェ  ォ ォ
  ャ ァ         ュ ゥ         ョ ォ
  ヮ ァ
);

sub onbiki2boin {
    my $char;
    return join q{}, map { $char = !( m/ー|〜/ && $char ) ? $_ : exists $boins{$char} ? $boins{$char} : $_; } split //, $_[0];
}

1;
__END__

=encoding utf-8

=head1 NAME

Lingua::JA::Onbiki - convert Onbiki into Boin

=head1 SYNOPSIS

    use Lingua::JA::Onbiki qw/onbiki2boin/;

    $onbiki = 'あったか〜い';
    $boin = onbiki2boin($onbiki); # => あったかあい

=head1 DESCRIPTION

Lingua::JA::Onbiki converts Onbiki into Boin in Japanese.

=head1 LICENSE

Copyright (C) Satoshi Yanuma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YANUTETSU E<lt>yanutetsu@cpan.orgE<gt>

=cut

