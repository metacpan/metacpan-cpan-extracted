# $File: //member/autrijus/Lingua-ZH-Keywords/Keywords.pm $ $Author: autrijus $
# $Revision: #9 $ $Change: 3723 $ $DateTime: 2003/01/20 22:15:45 $

package Lingua::ZH::Keywords;
$Lingua::ZH::Keywords::VERSION = '0.04';

use strict;
use vars qw($VERSION @ISA @EXPORT @StopWords);

use Exporter;
use Lingua::ZH::TaBE ();

=head1 NAME

Lingua::ZH::Keywords - Extract keywords from Chinese text

=head1 SYNOPSIS

    # Exports keywords() by default
    use Lingua::ZH::Keywords;

    print join(",", keywords($text));	    # Prints five keywords
    print join(",", keywords($text, 10));   # Prints ten keywords

=head1 DESCRIPTION

This is a very simple algorithm which removes stopwords from the
text, and then counts up what it considers to be the most important
B<keywords>.  The C<keywords> subroutine returns a list of keywords
in order of relevance.

The stopwords list is accessible as C<@Lingua::ZH::Keywords::StopWords>.

If the input C<$text> is an Unicode string, the returned keywords
will also be Unicode strings; otherwise they are assumed to be
Big5-encoded bytestrings.

=cut

@ISA	    = qw(Exporter);
@EXPORT	    = qw(keywords);

@StopWords  = qw(
    提供 相關 我們 可以 如何 因為 目前 如果 其他 我的 大家 沒有 主要 所以
    以上 這個 所有 有關 就是 他們 因此 但是 以及 是否 由於 對於 任何 什麼
    這些 現在 無法 成為 可能 不過 包括 必須 關於 這是 這樣 以下 已經 你的
    雖然 許多 也是 不是 除了 還是 為了 之後 只要 其中 都是 各種 還有 非常
    而且 這種 其它 不要 我要 他的 只是 各位 只有 的話 不能 這裡 相當 我是
    全部 很多 可是 或是 其實 那麼 你們 下列 如此 另外 然後 各項 才能 不會
    甚至 總會 不得 怎麼 即可 作為 至於 當然 根據 我想 能夠 之間 為何 不知
    例如 期間 時候 也有 常見 並且 容易 我有 實際 有人 有些 分別 並不 以後
    使得 經由 重新 如下 在此 這麼 那些 整個 都有 這次 之前 令人 來的 就會
    上述 位於 那個 而已 使用 假如 於是 還得 是在 無法 何況 曾經 我們的 
);

my $Tabe;

sub keywords {
    $Tabe ||= Lingua::ZH::TaBE->new;

    eval { require Encode::compat } if $] < 5.007;
    my $is_utf8 = eval { require Encode; Encode::is_utf8($_[0]) };

    my (%hist, %ref);
    $hist{$_}++ for grep {
	length > 2 and index($_, '一') == -1
    } $Tabe->split(
	$is_utf8 ? Encode::encode(big5 => $_[0]) : $_[0]
    );
    delete @hist{@StopWords};

    my $count = $_[1] || 5;

    # By occurence, then freq, then lexical order
    map {
	$is_utf8 ? Encode::decode(big5 => $_) : $_
    } grep length, (sort {
	$hist{$b} <=> $hist{$a}
	    or
	($ref{$b} ||= freq($b)) <=> ($ref{$a} ||= freq($a))
	    or
	$b cmp $a
    } keys %hist)[ 0 .. $count-1 ];
}

sub freq {
    my $tsi = $Tabe->Tsi($_[0]);
    $Tabe->TsiDB->Get($tsi);
    return $tsi->refcount;
}

1;

__END__

=head1 SEE ALSO

L<Lingua::ZH::TaBE>, L<Lingua::EN::Keywords>

=head1 ACKNOWLEDGEMENTS

Algorithm adapted from the L<Lingua::EN::Keywords> module by
Simon Cozens, E<lt>simon@simon-cozens.org<gt>.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
