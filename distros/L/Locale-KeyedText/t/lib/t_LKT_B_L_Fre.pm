use 5.008001;
use utf8;
use strict;
use warnings;

package t_LKT_B_L_Fre;

my $xy = 'BF';
my $text_strings = {
    'two' => $xy . q[ - sky pie rye],
    'three' => $xy . q[ - eat <knife>],
};

sub get_text_by_key {
    my (undef, $msg_key) = @_;
    return $text_strings->{$msg_key};
}

1;
