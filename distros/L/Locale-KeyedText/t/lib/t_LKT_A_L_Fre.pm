use 5.008001;
use utf8;
use strict;
use warnings;

package t_LKT_A_L_Fre;

my $xy = 'AF';
my $text_strings = {
    'one' => $xy . q[ - word <fork> < fork > <spoon> <<fork>>],
    'two' => $xy . q[ - sky pie rye],
};

sub get_text_by_key {
    my (undef, $msg_key) = @_;
    return $text_strings->{$msg_key};
}

1;
