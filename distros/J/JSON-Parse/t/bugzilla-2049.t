use warnings;
use strict;
use Test::More;
use JSON::Parse 'json_file_to_perl';
eval {
my $type = '';
my $tri2file = json_file_to_perl ('$type-tri2file.txt');
};
ok ($@);
note ($@);
done_testing ();
