use warnings;
use strict;
use utf8;
use Test::More;
use File::Temp;
use Deflate::Faster qw(:all);

my $have_gzip_faster = eval {
    require Gzip::Faster;
    1;
};

# 1. System gzip compatibility
SKIP: {
    my $system_gzip = `which gzip 2>/dev/null`;
    chomp $system_gzip if defined $system_gzip;
    skip "System gzip not found", 3 unless $system_gzip && -x $system_gzip;

    my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    my $out_file = "$tmpdir/test_sys_out.txt";
    my $in_file  = "$tmpdir/test_sys_in.gz";

    my $input = "Testing interoperability with /bin/gzip! " x 30;

    # Deflate::Faster -> /bin/gzip -d
    my $gz = gzip($input);
    my $pipe_cmd = "$system_gzip -d";
    open my $pipe_in, "|-", "$pipe_cmd > \Q$out_file\E" or die $!;
    binmode $pipe_in;
    print $pipe_in $gz;
    close $pipe_in or die $!;

    open my $read_back, "<:raw", $out_file or die $!;
    my $decomp = do { local $/; <$read_back> };
    close $read_back;
    is($decomp, $input, "system gzip -d decompressed Deflate::Faster output");

    # /bin/gzip -c -> Deflate::Faster::gunzip
    open my $pipe_gz, "|-", "$system_gzip -c > \Q$in_file\E" or die $!;
    binmode $pipe_gz;
    print $pipe_gz $input;
    close $pipe_gz or die $!;

    open my $read_gz, "<:raw", $in_file or die $!;
    my $sys_gz_bytes = do { local $/; <$read_gz> };
    close $read_gz;

    my $df_decomp = gunzip($sys_gz_bytes);
    is($df_decomp, $input, "Deflate::Faster::gunzip decompressed system gzip output");
    ok(1, "system gzip bidirectional roundtrip completed");
}

# 2. Gzip::Faster cross-compatibility
SKIP: {
    skip "Gzip::Faster not installed in perl INC", 6 unless $have_gzip_faster;

    my $sample = "Cross-module testing Deflate::Faster vs Gzip::Faster: " x 25;

    # gzip / gunzip
    my $gf_gz = Gzip::Faster::gzip($sample);
    is(gunzip($gf_gz), $sample, "Deflate::Faster gunzips Gzip::Faster gzip");

    my $df_gz = gzip($sample);
    is(Gzip::Faster::gunzip($df_gz), $sample, "Gzip::Faster gunzips Deflate::Faster gzip");

    # deflate / inflate (zlib format)
    my $gf_zlib = Gzip::Faster::deflate($sample);
    is(inflate($gf_zlib), $sample, "Deflate::Faster inflates Gzip::Faster deflate");

    my $df_zlib = deflate($sample);
    is(Gzip::Faster::inflate($df_zlib), $sample, "Gzip::Faster inflates Deflate::Faster deflate");

    # deflate_raw / inflate_raw (raw DEFLATE)
    my $gf_raw = Gzip::Faster::deflate_raw($sample);
    is(inflate_raw($gf_raw), $sample, "Deflate::Faster inflates raw from Gzip::Faster");

    my $df_raw = deflate_raw($sample);
    is(Gzip::Faster::inflate_raw($df_raw), $sample, "Gzip::Faster inflates raw from Deflate::Faster");
}

# 3. UTF-8 flag cross-compatibility with Gzip::Faster
SKIP: {
    skip "Gzip::Faster not installed in perl INC", 2 unless $have_gzip_faster;

    my $kujira = '鯨魚與海豚';
    ok(utf8::is_utf8($kujira), "input is utf8");

    # Gzip::Faster zip -> Deflate::Faster unzip
    my $gf = Gzip::Faster->new();
    $gf->copy_perl_flags(1);
    my $gf_out = $gf->zip($kujira);

    my $df = Deflate::Faster->new();
    $df->copy_perl_flags(1);
    my $df_read = $df->unzip($gf_out);
    ok(utf8::is_utf8($df_read) && $df_read eq $kujira, "Deflate::Faster preserved UTF-8 flag created by Gzip::Faster");
}

done_testing();
