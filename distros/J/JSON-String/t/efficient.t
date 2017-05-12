use strict;
use warnings;

use Test::More tests => 5;

use JSON::PP;
use JSON::String;

my $codec = JSON::EncodeCounter->new->canonical;
JSON::String->codec($codec);

sub count_encodings(&$$) {
    my($block, $expected_count, $msg) = @_;

    $codec->reset_encode_counter();
    $block->();
    is($codec->encode_counter, $expected_count, $msg);
}


my $orig = { a => 1, b => 2, c => 3 };
my $string = $codec->encode($orig);

$codec->reset_encode_counter;
my $obj;
count_encodings 
    { $obj = JSON::String->tie($string) }
    0, 'Creating new JSON::String does not call encode';

count_encodings
    { $obj->{c} = 'changed' }
    1,
    'Changing a hash value';

count_encodings
    { $obj->{d} = [ 1, 2, 3 ] }
    1,
    'Add arrayref value';

count_encodings
    { $obj->{e} = { key => [ { inner_key => 'value' } ] } }
    1,
    'Add nested value';

TODO: {
    local $TODO = q(Can't figure out how to delay the reencode until after this completes both STOREs);
    count_encodings
        { @$obj{'a','b'} = ('change','two') }
        1,
        'Assign to hash slice';
};


package JSON::EncodeCounter;

use parent 'JSON::PP';

my $counter;
sub encode {
    my $self = shift;
    $counter = 0 unless defined $counter;
    $counter++;

    $self->SUPER::encode(@_);
}

sub encode_counter {
    return $counter;
}

sub reset_encode_counter {
    $counter = 0;
}
