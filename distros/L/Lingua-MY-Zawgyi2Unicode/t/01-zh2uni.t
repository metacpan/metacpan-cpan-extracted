use strict;
use warnings;

use Test::More;
use JSON;
use Readonly;
use FindBin;

Readonly my $sample_data => 'sample.json';

use_ok( 'Lingua::MY::Zawgyi2Unicode' );
use Lingua::MY::Zawgyi2Unicode;

my $json = JSON->new;
my $data;
{
    local $/;
    open my $fh, '<:encoding(UTF-8)', "$FindBin::Bin/$sample_data" or die $@;
    $data = <$fh>;
    close $fh;
}

my $test_data = $json->decode($data);

my $zg_str = join ' ', @{$test_data->{zg}};
my $uni_str = join ' ', @{$test_data->{uni}};
my $zg_converted = convert($zg_str);

is(isBurmese($zg_str), 1, 'Zawgyi string is Burmese');
is(isBurmese($uni_str), 1, 'Unicode string is Burmese');
is(isZawgyi($zg_str), 1, 'Zawgyi string is Zawgyi');
is(isZawgyi($uni_str), 0, 'Unicode string is not Zawgyi');
is(isBurmese($zg_converted), 1, 'Zawgyi converted string is Burmese');
is(isZawgyi($zg_converted), 0, 'Zawgyi converted string is not Zawgyi');
ok($zg_converted eq $uni_str, 'Zawgyi converted string is equal to the Unicode string');

done_testing;



