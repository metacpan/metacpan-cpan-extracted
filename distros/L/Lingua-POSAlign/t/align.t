use Test::More tests => 3;
use_ok('Lingua::POSAlign');

use Data::Dumper;
my $n = new Lingua::POSAlign;
@s = qw(-8 6);
while(<DATA>){
#    print $_.$/;
    chomp;
    next unless $_;
    my ($a,$b) = map{eval "[qw($_)]"} split m'/';
    next if $@;
    $n->align($a, $b);
#    print Dumper $n;

#    $n->dump_table;
#    $n->dump_alignment;
    is($n->total_score => shift @s);
}

__END__
DT MD VB VBN / DT NNS VBP VBN
JJ NN NNS MD VB VBN IN / JJ NNS VBP VBN IN
