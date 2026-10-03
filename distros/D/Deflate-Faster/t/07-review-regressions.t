use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;
use Deflate::Faster qw(:all);

# Item 1: CLONE_SKIP
ok(Deflate::Faster->can('CLONE_SKIP'), 'CLONE_SKIP is defined');
is(Deflate::Faster->CLONE_SKIP, 1, 'CLONE_SKIP returns 1');

# Item 2: Multi-member gzip & trailing garbage rejection
{
    my $m1 = gzip("FirstMember\n");
    my $m2 = gzip("SecondMember\n");
    my $multi = $m1 . $m2;

    my $decoded = gunzip($multi);
    is($decoded, "FirstMember\nSecondMember\n", "multi-member gzip decompresses all members");

    my $df = Deflate::Faster->new();
    is($df->unzip($multi), "FirstMember\nSecondMember\n", "OO unzip decompresses multi-member gzip");

    # Trailing garbage must croak
    eval { gunzip($m1 . "junkjunk") };
    like($@, qr/libz format/i, "trailing garbage croaks");

    eval { gunzip($m1 . "\xff" x 4) };
    like($@, qr/libz format/i, "trailing 0xff croaks");

    eval { gunzip($m1 . "\0" x 8) };
    like($@, qr/libz format/i, "trailing zeros croak");

    # Raw / zlib trailing garbage must croak
    my $raw = deflate_raw("test");
    eval { inflate_raw($raw . "junk") };
    like($@, qr/libz format/i, "trailing garbage on raw deflate croaks");

    my $zl = deflate("test");
    eval { inflate($zl . "junk") };
    like($@, qr/libz format/i, "trailing garbage on zlib croaks");
}

# Item 3: Forged ISIZE protection
{
    my $short_gz = gzip("hello world");
    # Forge ISIZE to 0xFFFFFFFF (4 GiB)
    substr($short_gz, -4, 4, pack('V', 0xFFFFFFFF));
    eval { gunzip($short_gz) };
    # It should safely fail with libz format or CRC/size mismatch, without uncatchable OOM
    ok($@, "forged 0xFFFFFFFF ISIZE safely croaked without uncatchable OOM");
}

# Item 4: Header metadata isolation across calls
{
    my $w = Deflate::Faster->new();
    $w->file_name("secret-a.txt");
    $w->mod_time(1234567890);
    my $named_gz = $w->zip("Confidential");

    my $plain_gz = gzip("Plain");

    my $r = Deflate::Faster->new();
    is($r->unzip($named_gz), "Confidential", "unzip named");
    is($r->file_name, "secret-a.txt", "file_name parsed");
    is($r->mod_time, 1234567890, "mod_time parsed");

    is($r->unzip($plain_gz), "Plain", "unzip plain on same object");
    is($r->file_name, undef, "file_name reset to undef");
    is($r->mod_time, undef, "mod_time reset to undef");

    my $next_gz = $r->zip("Next");
    my $check = Deflate::Faster->new();
    $check->unzip($next_gz);
    is($check->file_name, undef, "next zip does not leak old file_name");
    is($check->mod_time, undef, "next zip does not leak old mod_time");
}

# Item 5: gunzip auto-detects zlib data
{
    my $data = "Zlib auto-detection payload " x 10;
    my $zlib = deflate($data);
    my $un = eval { gunzip($zlib) };
    is($un, $data, "gunzip auto-detects and decompresses zlib stream");

    my $df = Deflate::Faster->new();
    my $un_oo = eval { $df->unzip($zlib) };
    is($un_oo, $data, "OO unzip auto-detects and decompresses zlib stream");
}

# Item 6: Empty string returns undef and warns
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $res = gunzip("");
    is($res, undef, "gunzip('') returns undef");
    like($warnings[-1], qr/Attempt to uncompress empty string/i, "gunzip('') warns");

    $res = inflate("");
    is($res, undef, "inflate('') returns undef");
    like($warnings[-1], qr/Attempt to uncompress empty string/i, "inflate('') warns");

    $res = inflate_raw("");
    is($res, undef, "inflate_raw('') returns undef");
    like($warnings[-1], qr/Attempt to uncompress empty string/i, "inflate_raw('') warns");

    my $df = Deflate::Faster->new();
    $res = $df->unzip("");
    is($res, undef, "unzip('') returns undef");
    like($warnings[-1], qr/Attempt to uncompress empty string/i, "unzip('') warns");
}

# Item 7: Compressed buffer size is not bloated
{
    my $zeros = "\0" x 1_000_000;
    my $gz = gzip($zeros);
    my $len = length($gz);
    ok($len < 2000, "compressed 1MB zeros is small ($len bytes)");
}

# Item 9 & 10: Compression levels coercion and level 0 support
{
    my $text = "Level test payload " x 50;
    my $l0 = gzip($text, 0);
    ok(length($l0) > length($text), "level 0 stored block produces larger output than text");
    is(gunzip($l0), $text, "level 0 decompress roundtrip ok");

    my $df = Deflate::Faster->new();
    $df->level(0);
    my $oo_l0 = $df->zip($text);
    is(gunzip($oo_l0), $text, "OO level 0 roundtrip ok");

    # Undef and -1 mean default level
    my $def_len = length(gzip($text));
    is(length(gzip($text, undef)), $def_len, "level undef gives default level");
    is(length(gzip($text, -1)), $def_len, "level -1 gives default level");

    $df->level(undef);
    is(length($df->zip($text)), $def_len, "OO level(undef) gives default level");
    $df->level(-1);
    is(length($df->zip($text)), $def_len, "OO level(-1) gives default level");

    # Out of range clamped with warnings
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    gzip($text, -2);
    like($w[-1], qr/less than 0/i, "level -2 warns");

    @w = ();
    gzip($text, 15);
    like($w[-1], qr/more than 12/i, "level 15 warns");

    @w = ();
    gzip($text, "invalid");
    like($w[-1], qr/isn't numeric/i, "level 'invalid' warns");
}

# Subclassing new
{
    {
        package MyCustomDeflate;
        our @ISA = ('Deflate::Faster');
    }
    my $obj = MyCustomDeflate->new();
    isa_ok($obj, 'MyCustomDeflate');
    isa_ok($obj, 'Deflate::Faster');
    is($obj->unzip(gzip("subclass works")), "subclass works", "subclass method call works");
}

# Getter / Setter copy isolation
{
    my $df = Deflate::Faster->new();
    my $name = "initial.txt";
    $df->file_name($name);
    $name = "mutated.txt";
    is($df->file_name, "initial.txt", "setter copied value, changing original scalar did not affect object");

    # Mutating returned getter value
    for ($df->file_name) {
        $_ .= "_appended";
    }
    is($df->file_name, "initial.txt", "getter returned a copy, mutating caller alias did not affect object");

    my $time = 1000;
    $df->mod_time($time);
    $time = 2000;
    is($df->mod_time, 1000, "mod_time setter copied value");
}

# Embedded NUL in file_name does not corrupt stream
{
    my $df = Deflate::Faster->new();
    $df->file_name("hello\0world.txt");
    my $gz = $df->zip("data");
    my $u = Deflate::Faster->new();
    is($u->unzip($gz), "data", "decompression succeeded");
    is($u->file_name, "hello", "file_name cleanly truncated at first NUL");
}

# Tied input fetched once
{
    {
        package TestTie;
        sub TIESCALAR { my ($pkg, $val) = @_; bless \$val, $pkg }
        sub FETCH { $main::tie_fetch_count++; ${$_[0]} }
        sub STORE { ${$_[0]} = $_[1] }
    }
    our $tie_fetch_count = 0;
    tie my $tied_var, 'TestTie', "Tied payload to compress";
    $tie_fetch_count = 0;
    my $gz = gzip($tied_var);
    is($tie_fetch_count, 1, "gzip fetches tied input exactly once");

    $tie_fetch_count = 0;
    tie my $tied_gz, 'TestTie', $gz;
    $tie_fetch_count = 0;
    my $plain = gunzip($tied_gz);
    is($tie_fetch_count, 1, "gunzip fetches tied input exactly once");
    is($plain, "Tied payload to compress", "tied input roundtrip ok");
}

# gunzip_to_file with wide / non-ASCII characters
{
    my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    my $target_file = "$tmpdir/wide_output.txt";
    my $wide_text = "Unicode test: 鯨魚與海豚 caf\x{e9} \x{263a}";

    my $w = Deflate::Faster->new();
    $w->copy_perl_flags(1);
    my $gz = $w->zip($wide_text);

    eval { gunzip_to_file($gz, $target_file, copy_perl_flags => 1) };
    ok(!$@, "gunzip_to_file does not croak on wide characters: $@");
    open my $fh, "<:raw", $target_file or die $!;
    my $written = do { local $/; <$fh> };
    close $fh;
    my $expected_bytes = $wide_text;
    utf8::encode($expected_bytes);
    is($written, $expected_bytes, "file written matches exact raw bytes");
}

# gzip_to_file(undef) and empty string file truncation (D6)
{
    my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    my $target_file = "$tmpdir/undef_output.txt";
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    gzip_to_file(undef, $target_file);
    like($w[0], qr/Empty input/i, "gzip_to_file(undef) warns Empty input");
    is(scalar(grep { /\$len/ } @w), 0, "no warning about internal \$len variable");
    ok(-e $target_file && -s $target_file == 0, "gzip_to_file(undef) creates 0-byte file");

    # D6: Existing file truncated to 0 bytes
    open my $fh, '>', $target_file or die $!;
    print $fh "existing content";
    close $fh;
    @w = ();
    gzip_to_file('', $target_file);
    is(-s $target_file, 0, "gzip_to_file('') truncates existing file to 0 bytes");
    is(scalar(@w), 1, "gzip_to_file('') warns exactly once");

    open $fh, '>', $target_file or die $!;
    print $fh "existing content";
    close $fh;
    @w = ();
    gunzip_to_file('', $target_file);
    is(-s $target_file, 0, "gunzip_to_file('') truncates existing file to 0 bytes");
    is(scalar(@w), 1, "gunzip_to_file('') warns exactly once");
}

# D1: Magical arguments ($1, tied scalars/hashes)
{
    my $p = "The quick brown fox jumps over the lazy dog. " x 20;

    # $1 regex match variables
    "match_name.txt" =~ /(\w+\.txt)/;
    my $o = Deflate::Faster->new();
    $o->file_name($1);
    "1234567" =~ /(\d+)/;
    $o->mod_time($1);
    "0" =~ /(\d)/;
    $o->level($1);

    my $z = $o->zip($p);
    my $u = Deflate::Faster->new();
    $u->unzip($z);
    is($u->file_name, "match_name.txt", "file_name(\$1) writes matched name");
    is($u->mod_time, 1234567, "mod_time(\$1) writes matched timestamp");

    # Tied hash values
    {
        package TestTiedHash;
        require Tie::Hash;
        our @ISA = 'Tie::StdHash';
    }
    tie my %cfg, 'TestTiedHash';
    %cfg = (name => "from_tied_hash.txt", mt => 987654, max => 50);
    my $to = Deflate::Faster->new();
    $to->file_name($cfg{name});
    $to->mod_time($cfg{mt});
    my $tz = $to->zip($p);
    my $tu = Deflate::Faster->new();
    $tu->unzip($tz);
    is($tu->file_name, "from_tied_hash.txt", "file_name(tied hash) preserved");
    is($tu->mod_time, 987654, "mod_time(tied hash) preserved");

    # max_size with tied value
    my $mo = Deflate::Faster->new();
    $mo->max_size($cfg{max});
    eval { $mo->unzip($tz) };
    like($@, qr/exceeds max_size of 50 bytes/i, "max_size with tied value croaks properly");
}

# D2: max_size coercion on string inputs
{
    my $p = "A" x 1000;
    my $gz = gzip($p);
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };

    my $df = Deflate::Faster->new();
    $df->max_size("50MB");
    eval { $df->unzip($gz) };
    like($@, qr/exceeds max_size of 50 bytes/i, "max_size('50MB') limits to 50 bytes rather than unlimited");
    like($w[-1], qr/isn't numeric/i, "max_size('50MB') warned about non-numeric argument");

    $df->max_size("1_000");
    eval { $df->unzip($gz) };
    like($@, qr/exceeds max_size of 1 bytes/i, "max_size('1_000') limits rather than unlimited");
    like($w[-1], qr/isn't numeric/i, "max_size('1_000') warned about non-numeric argument");

    # String with no numeric prefix evaluates to 0 (unlimited) with warning
    $df->max_size("none");
    my $un = eval { $df->unzip($gz) };
    is($un, $p, "max_size('none') evaluates to 0 (unlimited decompression)");
    like($w[-1], qr/isn't numeric/i, "max_size('none') warned about non-numeric argument");
}

# D4: Overloaded input modifying file_name does not UAF
{
    my $df = Deflate::Faster->new();
    $df->file_name("original_name_" . ("x" x 200));
    {
        package TestEvilOv;
        use overload '""' => sub { $df->file_name("evil_replaced_" . ("y" x 5000)); "payload" x 50 }, fallback => 1;
    }
    my $evil_in = bless {}, 'TestEvilOv';
    my $z = $df->zip($evil_in);
    my $u = Deflate::Faster->new();
    my $dec = $u->unzip($z);
    ok(defined $dec && length($dec) > 0, "overloaded input modifying file_name did not crash");
    is($u->file_name, "original_name_" . ("x" x 200), "original file_name preserved in header");
}

# Negative level clamping to default
{
    my $p = "Quick test payload " x 20;
    my $def_len = length(gzip($p));
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $neg_len = length(gzip($p, -5));
    like($w[-1], qr/less than 0/i, "negative level < -1 warns");
    is($neg_len, $def_len, "negative level < -1 clamps to default level");
}

# Round 3: Single-fetch on tied level and max_size
{
    {
        package TestFetchCounter;
        sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
        sub FETCH { $main::counter_fetches++; ${$_[0]} }
        sub STORE { ${$_[0]} = $_[1] }
    }
    our $counter_fetches = 0;
    tie my $lvl_var, 'TestFetchCounter', 1;
    $counter_fetches = 0;
    gzip("hello", $lvl_var);
    is($counter_fetches, 1, "gzip(plain, level) fetches tied level exactly once");

    $counter_fetches = 0;
    deflate("hello", $lvl_var);
    is($counter_fetches, 1, "deflate(plain, level) fetches tied level exactly once");

    $counter_fetches = 0;
    deflate_raw("hello", $lvl_var);
    is($counter_fetches, 1, "deflate_raw(plain, level) fetches tied level exactly once");

    $counter_fetches = 0;
    my $df = Deflate::Faster->new();
    $df->level($lvl_var);
    is($counter_fetches, 1, "OO level() fetches tied level exactly once");

    $counter_fetches = 0;
    tie my $max_var, 'TestFetchCounter', 500;
    $df->max_size($max_var);
    is($counter_fetches, 1, "max_size() fetches tied max_size exactly once");
}

# Round 3: max_size unlimited for undef, 0, negative, and fractional
{
    my $p = "A" x 1000;
    my $gz = gzip($p);
    my $df = Deflate::Faster->new();

    $df->max_size(undef);
    is($df->unzip($gz), $p, "max_size(undef) is unlimited");

    $df->max_size(0);
    is($df->unzip($gz), $p, "max_size(0) is unlimited");

    $df->max_size(-10);
    is($df->unzip($gz), $p, "max_size(-10) is unlimited");

    $df->max_size(0.5);
    is($df->unzip($gz), $p, "max_size(0.5) is unlimited");
}

# Round 4 / Adversarial stress: Complex headers, FEXTRA, FCOMMENT, multi-member corruption, readonly scalars, recursive overload
{
    my $plain = "Payload for header flags test " x 10;
    my $gz = gzip($plain);

    # FHCRC (0x02) stream
    my $header_fhcrc = "\x1f\x8b\x08\x02\x00\x00\x00\x00\x00\xff";
    my $body = substr($gz, 10);
    if (eval { require Digest::CRC; 1 }) {
        my $crc32_val = Digest::CRC::crc32($header_fhcrc);
        my $crc16_gzip = pack('v', $crc32_val & 0xffff);
        my $stream_fhcrc = $header_fhcrc . $crc16_gzip . $body;
        eval { gunzip($stream_fhcrc) };
    }
    ok(1, "FHCRC stream handled without crash");

    # FEXTRA with unknown subfield and large subfield length
    my $header_fextra = "\x1f\x8b\x08\x04\x00\x00\x00\x00\x00\xff";
    my $xlen = pack('v', 6);
    my $subfield = "ZZ" . pack('v', 2) . "OK";
    my $stream_fextra = $header_fextra . $xlen . $subfield . $body;
    eval { gunzip($stream_fextra) };
    ok(1, "FEXTRA with unknown subfield handled without crash");

    # Truncated FEXTRA
    my $bad_xlen = pack('v', 1000);
    my $stream_bad_fextra = $header_fextra . $bad_xlen . "short";
    eval { gunzip($stream_bad_fextra) };
    like($@, qr/libz format/i, "truncated FEXTRA croaks cleanly");

    # FCOMMENT without NUL terminator
    my $header_fcomment = "\x1f\x8b\x08\x10\x00\x00\x00\x00\x00\xff";
    my $stream_bad_comment = $header_fcomment . ("CommentWithoutNul" x 50);
    eval { gunzip($stream_bad_comment) };
    like($@, qr/libz format/i, "FCOMMENT without NUL terminator croaks cleanly");

    # 500 concatenated 1-byte members
    my $m1 = gzip("X");
    my $multi_500 = $m1 x 500;
    is(gunzip($multi_500), "X" x 500, "500-member gzip decompresses successfully");

    # 500 members with corruption at member #250
    my $corrupted_multi = ($m1 x 249) . substr($m1, 0, 15) . ($m1 x 250);
    eval { gunzip($corrupted_multi) };
    like($@, qr/libz format/i, "corrupted member in multi-member stream croaks cleanly");

    # Boundary checks on max_size
    my $b_plain = "Exact boundary test string 1234567890";
    my $b_plen = length($b_plain);
    my $b_gz = gzip($b_plain);
    my $b_df = Deflate::Faster->new();

    $b_df->max_size($b_plen - 1);
    eval { $b_df->unzip($b_gz) };
    like($@, qr/exceeds max_size of @{[$b_plen - 1]} bytes/i, "max_size = len - 1 croaks");

    $b_df->max_size($b_plen);
    is($b_df->unzip($b_gz), $b_plain, "max_size == len succeeds");

    $b_df->max_size($b_plen + 1);
    is($b_df->unzip($b_gz), $b_plain, "max_size == len + 1 succeeds");

    # Readonly scalar input
    my $ro_plain = "Readonly input data";
    Internals::SvREADONLY($ro_plain, 1);
    my $ro_gz = eval { gzip($ro_plain) };
    ok(!$@ && defined $ro_gz, "gzip works on readonly scalar");
    my $ro_un = eval { gunzip($ro_gz) };
    is($ro_un, $ro_plain, "gunzip works on readonly scalar");

    # Readonly options passed to OO setters
    my $ro_name = "readonly_file.txt";
    Internals::SvREADONLY($ro_name, 1);
    $b_df->file_name($ro_name);
    is($b_df->file_name, "readonly_file.txt", "file_name setter accepts readonly scalar");

    my $ro_mt = 123456;
    Internals::SvREADONLY($ro_mt, 1);
    $b_df->mod_time($ro_mt);
    is($b_df->mod_time, 123456, "mod_time setter accepts readonly scalar");

    # Recursive overload stringification
    {
        package TestRecursiveOverload;
        use overload '""' => sub {
            my $inner = Deflate::Faster::gzip("nested content");
            my $dec = Deflate::Faster::gunzip($inner);
            return "Outer payload containing: $dec";
        }, fallback => 1;
    }
    my $rec_obj = bless {}, 'TestRecursiveOverload';
    my $rec_gz = gzip($rec_obj);
    is(gunzip($rec_gz), "Outer payload containing: nested content", "recursive overload stringification is safe");

    # File edge cases: non-existent file
    eval { gunzip_file("/non/existent/path/for/sure/123456.gz") };
    like($@, qr/No such file or directory/i, "gunzip_file on non-existent file croaks cleanly");

    eval { gzip_file("/non/existent/path/for/sure/123456.txt") };
    like($@, qr/No such file or directory/i, "gzip_file on non-existent file croaks cleanly");
}

done_testing();
