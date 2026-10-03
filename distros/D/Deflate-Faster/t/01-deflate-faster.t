use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use Deflate::Faster qw(:all);

# 1. Procedural basic round trip
my $input = "The quick brown fox jumps over the lazy dog. 1234567890! " x 10;
my $gz = gzip($input);
ok(defined $gz && length($gz) > 0, "gzip produced output");
is(gunzip($gz), $input, "gunzip round trip matches input");

# 2. Warnings on invalid inputs
{
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = shift };
    my $res = gzip(undef);
    is($res, undef, "gzip(undef) returns undef");
    like($warning, qr/Empty input/, "warns on undef input");

    $warning = '';
    $res = gzip('');
    is($res, undef, "gzip('') returns undef");
    like($warning, qr/Attempt to compress empty string/, "warns on empty string");

    $warning = '';
    $res = gunzip(undef);
    is($res, undef, "gunzip(undef) returns undef");
    like($warning, qr/Empty input/, "gunzip warns on undef");
}

# 3. Bad compressed data croaks
eval { gunzip("this is definitely not gzip data") };
ok($@, "croaked on invalid gzip data");
like($@, qr/Data input to inflate is not in libz format/, "correct error message on bad data");

# 4. Zlib format (deflate / inflate)
my $zlib = deflate($input);
ok(defined $zlib && length($zlib) > 0, "deflate produced output");
is(inflate($zlib), $input, "inflate round trip matches input");

# 5. Raw DEFLATE format (deflate_raw / inflate_raw)
my $raw = deflate_raw($input);
ok(defined $raw && length($raw) > 0, "deflate_raw produced output");
is(inflate_raw($raw), $input, "inflate_raw round trip matches input");

# 6. Procedural optional level parameter
my $gz_fast = gzip($input, 1);
is(gunzip($gz_fast), $input, "gzip with level 1 decompresses OK");
my $gz_best = gzip($input, 12);
is(gunzip($gz_best), $input, "gzip with level 12 decompresses OK");
my $z_fast = deflate($input, 1);
is(inflate($z_fast), $input, "deflate with level 1 decompresses OK");
my $raw_fast = deflate_raw($input, 1);
is(inflate_raw($raw_fast), $input, "deflate_raw with level 1 decompresses OK");

# 7. OO interface
my $df = Deflate::Faster->new();
isa_ok($df, 'Deflate::Faster');
is($df->unzip($df->zip($input)), $input, "OO zip / unzip roundtrip");

# Level control in OO mode
{
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = shift };
    $df->level(-5);
    like($warning, qr/level/, "warns on level < 0");

    $warning = '';
    $df->level(999);
    like($warning, qr/level/, "warns on level > 12");

    $df->level(1);
    my $out1 = $df->zip($input);
    is($df->unzip($out1), $input, "level 1 zip/unzip OK");

    $df->level(9);
    my $out9 = $df->zip($input);
    is($df->unzip($out9), $input, "level 9 zip/unzip OK");
}

# Raw format in OO mode
$df->raw(1);
my $raw_out = $df->zip($input);
is($df->unzip($raw_out), $input, "OO raw mode roundtrip");

# Switch back to gzip format
$df->gzip_format(1);
my $gz_out2 = $df->zip($input);
is($df->unzip($gz_out2), $input, "OO gzip mode roundtrip after raw mode");

# 8. Preservation of Perl UTF-8 flag
{
    my $kujira = '鯨';
    ok(utf8::is_utf8($kujira), "kujira is UTF-8 encoded");

    my $df_utf8 = Deflate::Faster->new();
    $df_utf8->copy_perl_flags(1);
    my $k_zipped = $df_utf8->zip($kujira);

    my $df_reader = Deflate::Faster->new();
    $df_reader->copy_perl_flags(1);
    my $k_out = $df_reader->unzip($k_zipped);
    is($k_out, $kujira, "UTF-8 string matches");
    ok(utf8::is_utf8($k_out), "UTF-8 flag preserved when copy_perl_flags is enabled");

    my $df_no_flags = Deflate::Faster->new();
    my $k_zipped2 = $df_no_flags->zip($kujira);
    my $k_out2 = $df_no_flags->unzip($k_zipped2);
    ok(! utf8::is_utf8($k_out2), "UTF-8 flag not set when copy_perl_flags is disabled");
    utf8::decode($k_out2);
    is($k_out2, $kujira, "decoded text matches");
}

# 9. Gzip header metadata: file_name and mod_time
{
    my $df_meta = Deflate::Faster->new();
    $df_meta->file_name("archive.txt");
    $df_meta->mod_time(1700000000);

    my $zipped_meta = $df_meta->zip($input);

    my $reader = Deflate::Faster->new();
    my $plain_meta = $reader->unzip($zipped_meta);
    is($plain_meta, $input, "content matches");
    is($reader->file_name(), "archive.txt", "file_name metadata preserved");
    is($reader->mod_time(), 1700000000, "mod_time metadata preserved");
}

# 10. File functions: gzip_to_file, gunzip_to_file, gzip_file, gunzip_file
{
    my $test_file = "$Bin/test_temp.txt";
    my $gz_file   = "$Bin/test_temp.txt.gz";

    open my $out, ">:raw", $test_file or die $!;
    print $out $input;
    close $out or die $!;

    # gzip_file
    my $from_file_gz = gzip_file($test_file);
    is(gunzip($from_file_gz), $input, "gzip_file works");

    # gzip_to_file
    gzip_to_file($input, $gz_file);
    ok(-f $gz_file, "gzip_to_file created file");

    # gunzip_file
    my $retrieved = gunzip_file($gz_file);
    is($retrieved, $input, "gunzip_file read and decompressed file");

    # gunzip_to_file
    my $dest_plain = "$Bin/test_dest.txt";
    gunzip_to_file($gz, $dest_plain);
    is(Deflate::Faster::get_file($dest_plain), $input, "gunzip_to_file decompressed to file");

    # gunzip_file with metadata options
    my $ret_name;
    my $ret_mtime;
    my $opt_gz = gzip_file($test_file, file_name => "custom_meta.txt", mod_time => 987654);
    open my $fh, ">:raw", $gz_file or die $!;
    print $fh $opt_gz;
    close $fh or die $!;

    gunzip_file($gz_file, file_name => \$ret_name, mod_time => \$ret_mtime);
    is($ret_name, "custom_meta.txt", "gunzip_file retrieved custom file_name");
    is($ret_mtime, 987654, "gunzip_file retrieved custom mod_time");

    # gunzip_file with max_size option
    eval { gunzip_file($gz_file, max_size => 10) };
    ok($@, "gunzip_file enforces max_size");
    like($@, qr/max_size/, "correct max_size error from gunzip_file");

    # gunzip_to_file with max_size option
    eval { gunzip_to_file($gz, $dest_plain, max_size => 10) };
    ok($@, "gunzip_to_file enforces max_size");
    like($@, qr/max_size/, "correct max_size error from gunzip_to_file");

    unlink $test_file, $gz_file, $dest_plain;
}

# 11. Test SvGMAGICAL scalar input (regex capture $1)
{
    my $string = "prefix:MagicalContent12345:suffix";
    if ($string =~ /prefix:(.*):suffix/) {
        my $magical_compressed = gzip($1);
        ok(defined $magical_compressed, "compressed magical scalar $1");
        is(gunzip($magical_compressed), "MagicalContent12345", "decompressed magical scalar correctly");
    }
}

done_testing();
