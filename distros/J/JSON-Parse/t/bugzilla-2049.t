use FindBin '$Bin';
use lib "$Bin";
use JPT;

eval {
    my $type = '';
    my $tri2file = read_json ('$type-tri2file.txt');
};
ok ($@);
note ($@);
done_testing ();
