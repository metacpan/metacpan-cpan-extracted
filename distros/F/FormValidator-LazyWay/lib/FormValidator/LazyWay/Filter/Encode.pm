package FormValidator::LazyWay::Filter::Encode;

use strict;
use warnings;

use Encode ();

sub decode {
    my $text = shift;
    my $args = shift || { encoding => 'utf8' };

    Encode::decode($args->{encoding}, $text);
}

sub encode_to {
    my $text = shift;
    my $args = shift || { encoding => 'utf8' };

    Encode::encode($args->{encoding}, $text);
}

1;
