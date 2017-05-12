package FormValidator::LazyWay::Filter::Unify;

use strict;
use warnings;
use utf8;

sub hyphen {
    my $text = shift;

    $text =~ s/[\x{30FC}\x{2015}\x{2500}\x{2501}\x{02D7}\x{2010}-\x{2012}\x{FE63}\x{FF0D}]/-/xmsg;
    $text;
}

1;

=head1 NAME

FormValidator::LazyWay::Filter::Unify - 複数の文字を統一する filter

=head1 METHOD

=head2 hyphen

ハイフンっぽい文字を - に統一する

=cut


