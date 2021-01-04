use warnings;
use strict;
use Test::More;
use JSON::Parse 'read_json';
eval {
    my $type = '';
    my $tri2file = read_json ('$type-tri2file.txt');
};
ok ($@);
note ($@);
done_testing ();
