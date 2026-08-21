use Test2::V0;
use Math::Histo;
use File::Temp qw(tempfile);

subtest 'Binary wire format roundtrip' => sub {
    my $h = Math::Histo->new(bins => 10, min => 0.0, max => 50.0, sumw2 => 1);
    $h->fill_n([2.5, 7.5, 12.5], [1.0, 2.0, 3.0]);

    my $blob = $h->serialize_binary;
    ok defined($blob) && length($blob) > 0, 'serialize_binary generated blob';
    is substr($blob, 0, 6), "\x89LHIST", 'magic header matches \x89LHIST';

    my $restored = Math::Histo->from_binary($blob);
    isa_ok $restored, 'Math::Histo';
    is $restored->nbins, 10, 'restored nbins';
    is $restored->num_entries, 3, 'restored num_entries';
    is $restored->total_weight, 6.0, 'restored total_weight';
    is $restored->bin_content(0), 1.0, 'restored bin 0';
    is $restored->bin_content(1), 2.0, 'restored bin 1';
    is $restored->bin_content(2), 3.0, 'restored bin 2';
};


subtest 'JSON roundtrip' => sub {
    my $h = Math::Histo->new(bins => 5, min => 0.0, max => 10.0);
    $h->fill_n([1.0, 3.0, 5.0, 7.0, 9.0]);

    my $json = $h->serialize_json(1);
    ok defined($json) && length($json) > 0, 'serialize_json generated string';
    like $json, qr/"nbins"\s*:\s*5/, 'json contains nbins: 5';

    my $restored = Math::Histo->from_json($json);
    isa_ok $restored, 'Math::Histo';
    is $restored->nbins, 5, 'restored from json';
    is $restored->num_entries, 5, 'restored 5 entries';
};

subtest 'File write and read roundtrip' => sub {
    my $h = Math::Histo->new(bins => 8, min => -4.0, max => 4.0);
    $h->fill_n([-3.0, -1.0, 1.0, 3.0]);

    my ($fh, $filename) = tempfile(CLEANUP => 1);
    close $fh;

    ok $h->write_file($filename, format => 'binary'), 'write_file binary';
    my $loaded = Math::Histo->from_file($filename);
    isa_ok $loaded, 'Math::Histo';
    is $loaded->num_entries, 4, 'loaded 4 entries';
};

done_testing;
