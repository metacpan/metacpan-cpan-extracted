use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;
use Cwd qw(getcwd);
use Deflate::Faster qw(:all);

# CLONE_SKIP
ok(Deflate::Faster->can('CLONE_SKIP'), 'CLONE_SKIP is defined');
is(Deflate::Faster->CLONE_SKIP, 1, 'CLONE_SKIP returns 1');

# Multi-member gzip & trailing garbage rejection
{
    my $m1 = gzip("FirstMember\n");
    my $m2 = gzip("SecondMember\n");
    my $multi = $m1 . $m2;

    my $decoded = gunzip($multi);
    is($decoded, "FirstMember\nSecondMember\n", "multi-member gzip decompresses all members");

    my $df = Deflate::Faster->new();
    is($df->unzip($multi), "FirstMember\nSecondMember\n", "OO unzip decompresses multi-member gzip");

    eval { gunzip($m1 . "junkjunk") };
    like($@, qr/libz format/i, "trailing garbage croaks");

    eval { gunzip($m1 . "\xff" x 4) };
    like($@, qr/libz format/i, "trailing 0xff croaks");

    eval { gunzip($m1 . "\0" x 8) };
    like($@, qr/libz format/i, "trailing zeros croak");

    my $raw = deflate_raw("test");
    eval { inflate_raw($raw . "junk") };
    like($@, qr/libz format/i, "trailing garbage on raw deflate croaks");

    my $zl = deflate("test");
    eval { inflate($zl . "junk") };
    like($@, qr/libz format/i, "trailing garbage on zlib croaks");
}

# Forged ISIZE protection
{
    my $short_gz = gzip("hello world");
    substr($short_gz, -4, 4, pack('V', 0xFFFFFFFF));
    eval { gunzip($short_gz) };
    ok($@, "forged 0xFFFFFFFF ISIZE safely croaked without uncatchable OOM");
}

# Header metadata isolation across calls
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

# gunzip auto-detects zlib data
{
    my $data = "Zlib auto-detection payload " x 10;
    my $zlib = deflate($data);
    my $un = eval { gunzip($zlib) };
    is($un, $data, "gunzip auto-detects and decompresses zlib stream");

    my $df = Deflate::Faster->new();
    my $un_oo = eval { $df->unzip($zlib) };
    is($un_oo, $data, "OO unzip auto-detects and decompresses zlib stream");
}

# Empty string returns undef and warns
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

# Compressed buffer size is not bloated
{
    my $zeros = "\0" x 1_000_000;
    my $gz = gzip($zeros);
    my $len = length($gz);
    ok($len < 2000, "compressed 1MB zeros is small ($len bytes)");
}

# Compression levels coercion and level 0 support
{
    my $text = "Level test payload " x 50;
    my $l0 = gzip($text, 0);
    ok(length($l0) > length($text), "level 0 stored block produces larger output than text");
    is(gunzip($l0), $text, "level 0 decompress roundtrip ok");

    my $df = Deflate::Faster->new();
    $df->level(0);
    my $oo_l0 = $df->zip($text);
    is(gunzip($oo_l0), $text, "OO level 0 roundtrip ok");

    my $def_len = length(gzip($text));
    is(length(gzip($text, undef)), $def_len, "level undef gives default level");
    is(length(gzip($text, -1)), $def_len, "level -1 gives default level");

    $df->level(undef);
    is(length($df->zip($text)), $def_len, "OO level(undef) gives default level");
    $df->level(-1);
    is(length($df->zip($text)), $def_len, "OO level(-1) gives default level");

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

# gzip_to_file(undef) and empty string file truncation
{
    my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    my $target_file = "$tmpdir/undef_output.txt";
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    gzip_to_file(undef, $target_file);
    like($w[0], qr/Empty input/i, "gzip_to_file(undef) warns Empty input");
    is(scalar(grep { /\$len/ } @w), 0, "no warning about internal \$len variable");
    ok(-e $target_file && -s $target_file == 0, "gzip_to_file(undef) creates 0-byte file");

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

# Magical arguments ($1, tied scalars/hashes)
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

# max_size coercion on string inputs
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

    $df->max_size("none");
    my $un = eval { $df->unzip($gz) };
    is($un, $p, "max_size('none') evaluates to 0 (unlimited decompression)");
    like($w[-1], qr/isn't numeric/i, "max_size('none') warned about non-numeric argument");
}

# Overloaded input modifying file_name does not UAF
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

# Single-fetch on tied level and max_size
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

# max_size unlimited for undef, 0, negative, and fractional
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

# Complex headers, FEXTRA, FCOMMENT, multi-member corruption, readonly scalars, recursive overload
{
    my $plain = "Payload for header flags test " x 10;
    my $gz = gzip($plain);

    # FHCRC (0x02) stream
    my $header_fhcrc = "\x1f\x8b\x08\x02\x00\x00\x00\x00\x00\xff";
    my $body = substr($gz, 10);
    SKIP: {
        skip "Digest::CRC required for FHCRC vector", 1
            unless eval { require Digest::CRC; 1 };
        my $crc32_val = Digest::CRC::crc32($header_fhcrc);
        my $crc16_gzip = pack('v', $crc32_val & 0xffff);
        my $stream_fhcrc = $header_fhcrc . $crc16_gzip . $body;
        is(gunzip($stream_fhcrc), $plain, "valid FHCRC stream decompresses");
    }

    # FEXTRA with unknown subfield
    my $header_fextra = "\x1f\x8b\x08\x04\x00\x00\x00\x00\x00\xff";
    my $xlen = pack('v', 6);
    my $subfield = "ZZ" . pack('v', 2) . "OK";
    my $stream_fextra = $header_fextra . $xlen . $subfield . $body;
    is(gunzip($stream_fextra), $plain, "FEXTRA with unknown subfield decompresses");
    my $fextra_oo = Deflate::Faster->new();
    is($fextra_oo->unzip($stream_fextra), $plain, "FEXTRA with unknown subfield decompresses via OO");

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

# Metadata is cleared even when unzip returns early
{
    my $w = Deflate::Faster->new();
    $w->file_name("previous.txt");
    $w->mod_time(1234567890);
    my $gz = $w->zip("Previous payload");
    my $r = Deflate::Faster->new();

    for my $input (undef, '') {
        $r->unzip($gz);
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        is($r->unzip($input), undef, "empty input returns undef after a named stream");
        is(scalar(@warnings), 1, "empty input still warns once");
        is($r->file_name, undef, "empty input clears previous file_name");
        is($r->mod_time, undef, "empty input clears previous mod_time");

        my $next = Deflate::Faster->new();
        $next->unzip($r->zip("Next payload"));
        is($next->file_name, undef, "next zip does not reuse previous file_name");
        is($next->mod_time, undef, "next zip does not reuse previous mod_time");
    }
}

# Metadata is cleared when decompression switches to a format without headers
{
    my $w = Deflate::Faster->new();
    $w->file_name("previous.txt");
    $w->mod_time(1234567890);
    my $gz = $w->zip("Previous payload");

    for my $format ('raw', 'zlib') {
        for my $input ('payload', '', undef, 'invalid') {
            my $r = Deflate::Faster->new();
            $r->unzip($gz);
            my $stream;
            if ($format eq 'raw') {
                $r->raw(1);
                $stream = deflate_raw('Next payload');
            }
            else {
                $r->gzip_format(0);
                $stream = deflate('Next payload');
            }
            $stream = $input unless defined $input && $input eq 'payload';

            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };
            my $decoded = eval { $r->unzip($stream) };
            if (defined $input && $input eq 'payload') {
                is($decoded, 'Next payload', "$format decompression preserves content");
                is($@, '', "$format decompression succeeds");
            }
            elsif (defined $input && $input eq 'invalid') {
                like($@, qr/libz format/i, "$format invalid stream still croaks");
            }
            else {
                is($decoded, undef, "$format empty input returns undef");
                is(scalar(@warnings), 1, "$format empty input still warns once");
            }
            is($r->file_name, undef, "$format decompression clears previous file_name");
            is($r->mod_time, undef, "$format decompression clears previous mod_time");

            $r->gzip_format(1);
            my $next = Deflate::Faster->new();
            $next->unzip($r->zip("Final payload"));
            is($next->file_name, undef, "gzip after $format does not reuse previous file_name");
            is($next->mod_time, undef, "gzip after $format does not reuse previous mod_time");
        }
    }
}

# Perl flags may appear anywhere among gzip extra subfields
{
    my $plain = "Unicode payload \x{263a}";
    my $bytes = $plain;
    utf8::encode($bytes);
    my $w = Deflate::Faster->new();
    $w->copy_perl_flags(1);
    $w->file_name("unicode.txt");
    my $gz = $w->zip($plain);
    my $perl_flags = substr($gz, 12, 5);
    my $unknown = "ZZ" . pack('v', 2) . "OK";
    my $r = Deflate::Faster->new();
    $r->copy_perl_flags(1);

    for my $extra ($perl_flags . $unknown,
                  $unknown . $perl_flags . $unknown,
                  $unknown . $perl_flags,
                  "ZZ" . pack('v', 0) . $perl_flags) {
        my $stream = $gz;
        substr($stream, 10, 7, pack('v', length($extra)) . $extra);
        my $decoded = $r->unzip($stream);
        is($decoded, $plain, "Unicode restored with other extra subfields");
        ok(utf8::is_utf8($decoded), "UTF-8 flag restored regardless of subfield position");
        is($r->file_name, "unicode.txt", "filename after extra fields parsed correctly");
    }

    for my $extra ("ZZ" . pack('v', length($perl_flags)) . $perl_flags,
                  "ZZ" . pack('v', 1000) . $perl_flags) {
        my $stream = $gz;
        substr($stream, 10, 7, pack('v', length($extra)) . $extra);
        my $decoded = $r->unzip($stream);
        is($decoded, $bytes, "GF inside another subfield does not restore Unicode");
        ok(!utf8::is_utf8($decoded), "invalid or nested subfield does not set UTF-8 flag");
    }
}

# gzip_file retains defaults when unrelated options are supplied
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $file = "$dir/defaults.txt";
    open my $fh, '>:raw', $file or die $!;
    print {$fh} "File payload";
    close $fh or die $!;
    utime(1234567890, 1234567890, $file) or die $!;
    my $mtime = (stat($file))[9];
    my $r = Deflate::Faster->new();

    for my $case ([{}, $file, $mtime],
                 [{level => 1}, $file, $mtime],
                 [{copy_perl_flags => 1}, $file, $mtime],
                 [{file_name => 'custom.txt'}, 'custom.txt', $mtime],
                 [{mod_time => 12345}, $file, 12345],
                 [{file_name => '', mod_time => 0}, undef, undef],
                 [{file_name => undef, mod_time => undef}, undef, undef]) {
        my ($options, $name, $time) = @$case;
        is($r->unzip(gzip_file($file, %$options)), "File payload", "gzip_file with options preserves content");
        is($r->file_name, $name, "gzip_file merges filename defaults and overrides");
        is($r->mod_time, $time, "gzip_file merges timestamp defaults and overrides");
    }
}

# Unicode markers in later members are restored without replacing first metadata
{
    my $plain = "\x{263a}";
    my $bytes = $plain;
    utf8::encode($bytes);
    my $w = Deflate::Faster->new();
    $w->copy_perl_flags(1);
    $w->file_name('second.txt');
    $w->mod_time(22222);
    my $unicode = $w->zip($plain);
    my $first = Deflate::Faster->new();
    $first->file_name('first.txt');
    $first->mod_time(11111);
    my $named = $first->zip('prefix ');
    my $empty = pack('H*', '1f8b080000000000000303000000000000000000');
    my $r = Deflate::Faster->new();
    $r->copy_perl_flags(1);

    for my $case ([gzip('prefix ') . $unicode, "prefix $plain", 1],
                 [$empty . $unicode, $plain, 1],
                 [$unicode . gzip(' suffix'), "$plain suffix", 1],
                 [$unicode . $unicode, "$plain$plain", 1],
                 [$named . $unicode, "prefix $plain", 1],
                 [gzip("\xff") . $unicode, "\xff$bytes", 0],
                 [gzip($plain), $bytes, 0]) {
        my ($stream, $expected, $flag) = @$case;
        my $decoded = $r->unzip($stream);
        is($decoded, $expected, "member flags preserve Unicode or raw bytes");
        is(utf8::is_utf8($decoded) ? 1 : 0, $flag, "UTF-8 restoration checks all members and validates bytes");
    }

    $r->unzip($named . $unicode);
    is($r->file_name, 'first.txt', "filename still comes from first member");
    is($r->mod_time, 11111, "timestamp still comes from first member");
    $r->copy_perl_flags(0);
    my $decoded = $r->unzip($named . $unicode);
    is($decoded, "prefix $bytes", "disabled flag copying returns raw bytes");
    ok(!utf8::is_utf8($decoded), "disabled flag copying leaves UTF-8 off");
}

# FHCRC validates the entire header of each member
{
    my $plain = "Header CRC payload";
    my $body = substr(gzip($plain), 10);
    my $r = Deflate::Faster->new();
    for my $case ([pack('H*', '1f8b08020000000000ff'), 0xc990, undef, undef],
                 [pack('H*', '1f8b081e3930000000ff') . pack('v', 5) . "GF\1\0\0" .
                  "header.txt\0comment\0", 0x105d, 'header.txt', 12345]) {
        my ($header, $crc, $name, $mtime) = @$case;
        my $valid = $header . pack('v', $crc) . $body;
        is(gunzip($valid), $plain, "valid header CRC accepted by gunzip");
        is($r->unzip($valid), $plain, "valid header CRC accepted by OO unzip");
        is($r->file_name, $name, "filename parsed with header CRC");
        is($r->mod_time, $mtime, "timestamp parsed with header CRC");

        my $bad = $header . pack('v', $crc ^ 1) . $body;
        eval { gunzip($bad) };
        like($@, qr/libz format/i, "incorrect header CRC rejected by gunzip");
        eval { $r->unzip($bad) };
        like($@, qr/libz format/i, "incorrect header CRC rejected by OO unzip");
        eval { gunzip(gzip('prefix ') . $bad) };
        like($@, qr/libz format/i, "incorrect header CRC rejected in later member");
        eval { $r->unzip(gzip('prefix ') . $bad) };
        like($@, qr/libz format/i, "OO unzip checks CRC in later member without flag copying");

        my $changed = $valid;
        substr($changed, 4, 1, chr(ord(substr($changed, 4, 1)) ^ 1));
        eval { gunzip($changed) };
        like($@, qr/libz format/i, "header corruption rejected despite unchanged payload CRC");
        eval { gunzip($header . substr(pack('v', $crc), 0, 1)) };
        like($@, qr/libz format/i, "truncated header CRC rejected");
    }
}

# Gzip filenames use Latin-1 regardless of the Perl UTF-8 flag
{
    my $bytes = "caf\x{e9}.txt";
    my $unicode = $bytes;
    utf8::upgrade($unicode);
    my $r = Deflate::Faster->new();
    for my $name ($bytes, $unicode, "\x{ff}.txt", "$unicode\0ignored\x{263a}") {
        my $original = $name;
        my $flag = utf8::is_utf8($name) ? 1 : 0;
        my $expected = $name;
        $expected =~ s/\0.*//s;
        my $w = Deflate::Faster->new();
        $w->file_name($name);
        my $gz = $w->zip('payload');
        is($r->unzip($gz), 'payload', "Latin-1 filename does not change content");
        is($r->file_name, $expected, "Latin-1 filename roundtrips with either Perl encoding");
        is($name, $original, "compression preserves caller filename");
        is(utf8::is_utf8($name) ? 1 : 0, $flag, "compression preserves caller filename flag");
    }

    my $w = Deflate::Faster->new();
    $w->file_name("wide\x{263a}.txt");
    eval { $w->zip('payload') };
    like($@, qr/file_name.*Latin-1/, "filename outside Latin-1 raises a clear error");
    $w->file_name('valid.txt');
    is($r->unzip($w->zip('payload')), 'payload', "object works after filename encoding error");
    $w->file_name("wide\x{263a}.txt");
    $w->raw(1);
    is(inflate_raw($w->zip('payload')), 'payload', "unused filename does not affect raw compression");
}

# The filename '0' is ordinary metadata
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $cwd = getcwd();
    chdir $dir or die $!;
    open my $fh, '>:raw', '0' or die $!;
    print {$fh} 'payload';
    close $fh or die $!;
    my $r = Deflate::Faster->new();
    is($r->unzip(gzip_file('0')), 'payload', "gzip_file reads filename '0'");
    is($r->file_name, '0', "gzip_file records default filename '0'");
    gzip_to_file('payload', 'output.gz', file_name => '0');
    my $name;
    is(gunzip_file('output.gz', file_name => \$name), 'payload', "file helpers preserve payload with filename '0'");
    is($name, '0', "file helpers record explicit filename '0'");
    chdir $cwd or die $!;
}

# Failed unzip leaves no metadata behind
{
    my $w = Deflate::Faster->new();
    $w->file_name("doomed.txt");
    $w->mod_time(424242);
    my $gz = $w->zip("payload data here " x 20);
    substr($gz, 30, 5) = "XXXXX";

    my $r = Deflate::Faster->new();
    eval { $r->unzip($gz) };
    like($@, qr/libz format/i, "corrupt body still croaks");
    is($r->file_name, undef, "failed unzip leaves file_name undef");
    is($r->mod_time, undef, "failed unzip leaves mod_time undef");

    my $named = do {
        my $o = Deflate::Faster->new();
        $o->file_name("first.txt");
        $o->mod_time(111);
        $o->zip("prefix ");
    };
    my $r2 = Deflate::Faster->new();
    eval { $r2->unzip($named . $gz) };
    like($@, qr/libz format/i, "corrupt trailing member still croaks");
    is($r2->file_name, undef, "first-member metadata not kept after failed unzip");
    is($r2->mod_time, undef, "first-member timestamp not kept after failed unzip");

    my $named_ok = do {
        my $o = Deflate::Faster->new();
        $o->file_name("big.txt");
        $o->zip("payload data here " x 20);
    };
    my $r3 = Deflate::Faster->new();
    $r3->max_size(10);
    eval { $r3->unzip($named_ok) };
    like($@, qr/max_size/i, "max_size still croaks");
    is($r3->file_name, undef, "max_size failure leaves file_name undef");
}

# mod_time range validation
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $df = Deflate::Faster->new();

    @w = ();
    $df->mod_time(-1);
    like($w[-1], qr/less than 0/i, "negative mod_time warns");
    is($df->mod_time, 0, "negative mod_time clamps to 0");

    @w = ();
    $df->mod_time(2**32);
    like($w[-1], qr/more than 4294967295/i, "oversized mod_time warns");
    is($df->mod_time, 4294967295, "oversized mod_time clamps to 2**32-1");

    @w = ();
    $df->mod_time(123.456);
    is($df->mod_time, 123, "fractional mod_time truncates");
    is(scalar(@w), 0, "fractional mod_time does not warn");

    @w = ();
    $df->mod_time("abc");
    like($w[-1], qr/isn't numeric/i, "non-numeric mod_time warns");
    is($df->mod_time, 0, "non-numeric mod_time becomes 0");

    @w = ();
    $df->mod_time(4294967295);
    is(scalar(@w), 0, "max uint32 mod_time does not warn");
    is($df->mod_time, 4294967295, "max uint32 mod_time kept");

    @w = ();
    $df->mod_time(0);
    is(scalar(@w), 0, "zero mod_time does not warn");
    is($df->mod_time, 0, "zero mod_time kept");

    my $r = Deflate::Faster->new();
    $df->mod_time(-5);
    $r->unzip($df->zip("data"));
    is($r->mod_time, undef, "clamped-0 mod_time reads back as undef");
    $df->mod_time(2**32);
    $r->unzip($df->zip("data"));
    is($r->mod_time, 4294967295, "clamped-max mod_time roundtrips");
}

# DESTROY on a foreign blessing does not crash the interpreter
{
    my $code = '{ my $x = bless {}, "Deflate::Faster"; } print "survived\n";';
    open my $child, '-|', $^X, '-Mblib', '-MDeflate::Faster', '-e', $code or die $!;
    my $output = do { local $/; <$child> };
    my $closed = close $child;
    ok($closed && $output =~ /survived/, "DESTROY on foreign-blessed hashref does not crash");
}

# Format selectors: disabling both selects zlib
{
    my $plain = "format selector payload " x 20;
    my $df = Deflate::Faster->new();
    $df->raw(0);
    is($df->zip($plain), deflate($plain), "raw(0) selects zlib format");
    $df->gzip_format(0);
    is($df->zip($plain), deflate($plain), "gzip_format(0) selects zlib format");
    is($df->unzip(deflate($plain)), $plain, "zlib mode unzips zlib streams");
}

# copy_perl_flags applies to gzip streams only
{
    my $k = "x\x{263a}";
    my $bytes = $k;
    utf8::encode($bytes);
    my $df = Deflate::Faster->new();
    $df->raw(1);
    $df->copy_perl_flags(1);
    my $rz = $df->zip($k);
    my $rd = Deflate::Faster->new();
    $rd->raw(1);
    $rd->copy_perl_flags(1);
    my $out = $rd->unzip($rz);
    is($out, $bytes, "raw roundtrip preserves bytes");
    ok(!utf8::is_utf8($out), "copy_perl_flags does not restore UTF-8 flag for raw streams");
}

done_testing();
