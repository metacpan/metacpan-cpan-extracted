package utils;
use utf8 qw(decode);
use HTML::Entities;
use Perl6::Slurp;

sub slurp_encode {
    my $filename = shift;
    my $data = slurp $filename;
    $data = decode_entities($data);
    utf8::encode($data);
    return $data;
}

1

