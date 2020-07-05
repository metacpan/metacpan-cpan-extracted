use strict;
use warnings;

use Carp ;
use File::Spec ();
use File::Slurp;
use File::Temp qw(tempfile);
use Test::More;

# older EUMMs turn this on. We don't want to emit warnings.
# also, some of our CORE function overrides emit warnings. Silence those.
local $^W;

my @text_data = (
    [],
    [ 'a' x 8 ],
    [ ("\n") x 5 ],
    [ map( "aaaaaaaa\n", 1 .. 3 ) ],
    [ map( "aaaaaaaa\n", 1 .. 3 ), 'aaaaaaaa' ],
    [ map ( 'a' x 100 . "\n", 1 .. 1024 ) ],
    [ map ( 'a' x 100 . "\n", 1 .. 1024 ), 'a' x 100 ],
    [ map ( 'a' x 1024 . "\n", 1 .. 1024 ) ],
    [ map ( 'a' x 1024 . "\n", 1 .. 1024 ), 'a' x 10240 ],
    [],
);

my @bin_sizes = (1000, 1024 * 1024);
my @bin_stuff = ("\012", "\015", "\012\015", "\015\012", map {chr $_} (0 .. 32) ) ;
my @bin_data;
foreach my $size (@bin_sizes) {
    my $data = '';
    while (length($data) < $size) {
        $data .= $bin_stuff[ rand @bin_stuff ];
    }
    push @bin_data, $data;
}

plan(tests => 17 * @text_data + 8 * @bin_data);

my (undef, $file) = tempfile('tempXXXXX', DIR => File::Spec->tmpdir, OPEN => 0);

foreach my $data (@text_data) {
    test_text_slurp($data);
}
foreach my $data (@bin_data) {
    test_bin_slurp($data);
}

unlink $file;

exit;

sub test_text_slurp {
    my ($data_ref) = @_;

    my @data_lines = @{$data_ref};
    my $data_text = join('', @data_lines);
    my $data_length = length($data_text);

    # write_file returns 1 for success or undef on error
    # diag("Data Text: ".$data_text);

    { # write then read - regular string
        my $res = write_file($file, $data_text);
        ok($res, "write_file - $data_length");
        my $text = read_file($file);
        is($text, $data_text, "read_file: scalar context - $data_length");
    }

    { # write and read - from scalar ref
        my $res = write_file($file, \$data_text);
        ok($res, "write_file - ref arg - $data_length");
        my $text = read_file($file);
        is($text, $data_text, "read_file: scalar context - $data_length");
    }

    { # write and read using buf_ref and scalar_ref options
        my $res = write_file($file, {buf_ref => \$data_text});
        ok($res, "write_file - buf ref opt - $data_length");
        my $text = read_file($file);
        is($text, $data_text, "read_file: scalar context - $data_length");
        my $text_ref = read_file($file, scalar_ref => 1);
        is(${$text_ref}, $data_text, "read_file: scalar_ref opt - $data_length");
        read_file($file, buf_ref => \my $buffer);
        is($buffer, $data_text, "read_file - buf_ref opt - $data_length");
    }

    { # write and read - from array ref
        my $res = write_file($file, \@data_lines);
        ok($res, "write_file - list ref arg - $data_length");
        my $text = read_file($file);
        is($text, $data_text, "read_file: scalar context - $data_length");
        my @array = read_file($file);
        is_deeply(\@array, \@data_lines, "read_file: list context - $data_length");
        my $array_ref = read_file($file, array_ref => 1);
        is_deeply($array_ref, \@data_lines, "read_file: scalar context with array_ref opt - $data_length");
        ($array_ref) = read_file($file, {array_ref => 1});
        is_deeply($array_ref, \@data_lines, "read_file: list context with array_ref opt - $data_length");
    }

    { # write and read - with append option
        my $res = write_file($file, {append => 1}, $data_text);
        ok($res, "write_file - append opt - $data_length");
        my $text = read_file($file);
        is($text, $data_text x 2, "read_file: scalar context - $data_length");
    }

    { # append and read
        my $res = append_file($file, $data_text );
        ok($res, "append_file - $data_length");
        my $text = read_file($file);
        is($text, $data_text x 3, "read_file: scalar context - $data_length");
    }
}

sub test_bin_slurp {
    my ($data) = @_;

    my $data_length = length($data);

    { # write and read - binmode :raw opt
        my $res = write_file($file, {binmode => ':raw'}, $data);
        ok($res, "write_file - binmode opt - $data_length");
        my $bin = read_file($file, binmode => ':raw');
        is($bin, $data, "read_file: scalar context binmode opt - $data_length");
        my $bin_ref = read_file($file, scalar_ref => 1, binmode => ':raw');
        is(${$bin_ref}, $data, "read_file: scalar w/ scalar_ref, binmode opts - $data_length");
        read_file($file, buf_ref => \(my $buffer), binmode => ':raw');
        is($buffer,$data, "read_file: buf_ref, binmode opts - $data_length");
    }

    { # write and read - append with binmode :raw opt
        my $res = write_file($file, {append => 1, binmode => ':raw'}, $data);
        ok($res, "write_file - append and binmode opt - $data_length");
        my $bin = read_file($file, 'binmode' => ':raw');
        is($bin, $data x 2, "read_file: scalar context binmode opt - $data_length");
    }

    { # append and write - binmode :raw opt
        my $res = append_file($file, {binmode => ':raw'}, $data);
        ok($res, "append_file - binmode opt - $data_length");
        my $bin = read_file( $file, binmode => ':raw');
        is($bin, $data x 3, "read_file: scalar context binmode opt - $data_length");
    }
}
