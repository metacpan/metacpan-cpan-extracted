use strict;
use lib '../lib';
use Test::More;
use Test::Deep;
use_ok 'Imager::Barcode128';


my $barcode = Imager::Barcode128->new(text => '1234 abcd');

my $encoded = $barcode->barcode;
cmp_ok($encoded, 'eq',
    "## #  ###  # ##  ###  #   # ##   # #### ### ## ##  ##  #  # ##    #  #    ## #    # ##  #    #  ## ###   # ## ##   ### # ##",
    "'1234 abcd' rendered as expected"
);

my @chars = Imager::Barcode128::_encodable('A',"1234 abcd");
cmp_deeply(\@chars,[ '1', '2', '3', '4', ' ' ], 'code A');
@chars = Imager::Barcode128::_encodable('B',"1234 abcd");
cmp_deeply(\@chars,[ '1', '2', '3', '4', ' ', 'a', 'b', 'c', 'd' ], 'code B'); 
@chars = Imager::Barcode128::_encodable('C',"1234 abcd");
cmp_deeply(\@chars,[ '12', '34' ], 'code C');

$barcode->draw;


if (grep {'png' eq $_} Imager->write_types) {
    $barcode->image->write(file => '/tmp/barcode128.png');
    diag 'test image written to /tmp/barcode128.png';
}

done_testing();
