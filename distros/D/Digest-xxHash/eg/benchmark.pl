use v5.42;
use Time::HiRes qw[clock_gettime CLOCK_MONOTONIC];
use Config;
use List::Util qw[max];
no warnings qw[experimental::builtin experimental::try];
$|++;
#
use blib;
use Digest::xxHash qw[
    xxhash32 xxhash32_hex xxhash64 xxhash64_hex
    xxh3_64  xxh3_64_hex
    xxh3_128 xxh3_128_hex
];
#
my %HAVE;
for my $mod (qw[Digest::CRC Digest::JHash Crypt::xxHash]) {
    try {
        $HAVE{$mod} = builtin::load_module $mod
    }
    catch ($e) { say 'Error loading ' . $mod; say $e; }
}
use Digest::MD5 ();
use Digest::SHA ();

# Helpers
sub size_label ($s) {
    return "${s}B" if $s < 1024;
    return sprintf '%.0fKB', $s / 1024 if $s < 1024 * 1024;
    return sprintf '%.1fMB', $s / ( 1024 * 1024 );
}

sub time_fn ( $fn, $min_iters, $sec ) {
    $sec //= 2.0;
    $fn->() for 1 .. 10;    # warm up
    my $iters = $min_iters;
    my $start = clock_gettime(CLOCK_MONOTONIC);
    $fn->() for 1 .. $iters;
    my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $start;

    # Re-run if the first try didn't take long enough (aiming for ~$sec)
    if ( $elapsed < $sec * 0.8 ) {
        my $scale = $elapsed > 0 ? ( $sec / $elapsed ) : 100;
        $iters = int( $iters * $scale ) + 1;
        $start = clock_gettime(CLOCK_MONOTONIC);
        $fn->() for 1 .. $iters;
        $elapsed = clock_gettime(CLOCK_MONOTONIC) - $start;
    }
    return ( $iters, $elapsed );
}

sub mbps ( $bytes, $iters, $elapsed ) {
    return 0 if $elapsed <= 0;
    return ( $bytes * $iters ) / ( $elapsed * 1024 * 1024 );
}

# cmpthese-style table (MB/s instead of /s)
#
# Output mimics Benchmark::cmpthese but throughput is MB/s:
#
#               MB/s   xxh3_64  xxhash64  xxhash32    sha256
# xxh3_64    9330.0       --      +33%      +53%      +69%
# xxhash64   7018.0     -25%        --      +15%      +41%
# xxhash32   6103.5     -35%      -13%        --      +22%
# sha256     5004.2     -46%      -29%      -18%        --
sub cmpthese_mbps ( $label, $data_size, $hashref ) {
    my @names = sort keys %$hashref;
    return unless @names;

    # Measure
    my @results;
    for my $name (@names) {
        my $min_iters = $data_size <= 1024 ? 100_000 : $data_size <= 64 * 1024 ? 10_000 : 1_000;
        my ( $iters, $elapsed ) = time_fn( $hashref->{$name}, $min_iters, 2.0 );
        my $rate = mbps( $data_size, $iters, $elapsed );
        push @results, { name => $name, rate => $rate };
    }

    # Sort fastest first
    @results = reverse sort { $b->{rate} <=> $a->{rate} } @results;

    # Format the rows ahead of time to calculate exact column widths
    my @rows;
    for my $row (@results) {
        my @cols;
        for my $col (@results) {
            if ( $row->{name} eq $col->{name} ) {
                push @cols, '--';
            }
            else {
                my $pct = $col->{rate} > 0 ? ( ( $row->{rate} - $col->{rate} ) / $col->{rate} ) * 100 : 0;
                push @cols, sprintf( "%+.0f%%", $pct );
            }
        }
        push @rows, { name => $row->{name}, rate => sprintf( '%.1f', $row->{rate} ), cols => \@cols, };
    }

    # Calculate column widths: wide enough for header OR the widest percentage string
    my $label_w = max( length('Benchmark'), map { length $_->{name} } @rows );
    my $rate_w  = max( length('MB/s'),      map { length $_->{rate} } @rows );
    my @col_w;
    for my $i ( 0 .. $#results ) {
        push @col_w, max( length( $results[$i]{name} ), map { length $_->{cols}[$i] } @rows );
    }
    say '';
    say "  [$label]";
    say '';

    # Header: right-align labels so they sit above the percentages
    printf "  %-${label_w}s %${rate_w}s", 'Benchmark', 'MB/s';
    printf " %${col_w[$_]}s", $results[$_]{name} for 0 .. $#results;
    say '';

    # Rows
    for my $row (@rows) {
        printf "  %-${label_w}s %${rate_w}s", $row->{name}, $row->{rate};
        for my $i ( 0 .. $#results ) {
            printf " %${col_w[$i]}s", $row->{cols}[$i];
        }
        say '';
    }
    say '';
}
#
say "Perl $^V | $Config{archname} | ivsize=$Config{ivsize}bit";
say '-' x 76;
say 'Comparators:';
say '  - Crypt::xxHash'       if $HAVE{'Crypt::xxHash'};
say '  - Digest::CRC (CRC32)' if $HAVE{'Digest::CRC'};
say '  - Digest::JHash'       if $HAVE{'Digest::JHash'};
say '  - Digest::MD5';
say '  - Digest::SHA (SHA-224)';
#
for my $size ( 16, 256, 1024, 64 * 1024, 1024 * 1024 ) {
    my $data = 'A' x $size;

    # 32-bit
    my %h32 = ( 'DH::xxhash32' => sub { xxhash32( $data, 0 ) } );
    $h32{'CH::xxhash32'} = sub { Crypt::xxHash::xxhash32( $data, 0 ) }
        if $HAVE{'Crypt::xxHash'};
    $h32{'Digest::CRC::crc32'} = sub { Digest::CRC::crc32($data) }
        if $HAVE{'Digest::CRC'};
    cmpthese_mbps( '32-bit with ' . size_label($size), $size, \%h32 );

    # 64-bit
    my %h64 = ( 'DH::xxh3_64' => sub { xxh3_64( $data, 0 ) }, 'DH::xxhash64' => sub { xxhash64( $data, 0 ) }, );
    $h64{'CH::xxhash3_64bits'} = sub { Crypt::xxHash::xxhash3_64bits( $data, 0 ) }
        if $HAVE{'Crypt::xxHash'};
    $h64{'CH::xxhash64'} = sub { Crypt::xxHash::xxhash64( $data, 0 ) }
        if $HAVE{'Crypt::xxHash'};
    cmpthese_mbps( '64-bit with ' . size_label($size), $size, \%h64 );

    # 128-bit class
    my %h128 = (
        'DH::xxh3_128'        => sub { xxh3_128( $data, 0 ) },
        'Digest::MD5::md5'    => sub { Digest::MD5::md5($data) },
        'Digest::SHA::sha224' => sub { Digest::SHA::sha224($data) }
    );
    $h128{'CH::xxhash3_128bits_hex'} = sub { Crypt::xxHash::xxhash3_128bits_hex( $data, 0 ) }
        if $HAVE{'Crypt::xxHash'};
    cmpthese_mbps( '128-bit class with ' . size_label($size), $size, \%h128 );
}
{
    my $chunk  = 'B' x ( 64 * 1024 );
    my $nchunk = 16;
    my $size   = 1024 * 1024;
    say('# Streaming interface - 1MB fed in 64KB chunks');
    my %stream = (
        'DH::xxh3_64' => sub {
            my $ctx = Digest::xxHash->new( type => 'xxh3_64' );
            $ctx->add($chunk) for 1 .. $nchunk;
            $ctx->hexdigest;
        },
        'DH::xxh3_128' => sub {
            my $ctx = Digest::xxHash->new( type => 'xxh3_128' );
            $ctx->add($chunk) for 1 .. $nchunk;
            $ctx->hexdigest;
        },
        'DH::xxh32' => sub {
            my $ctx = Digest::xxHash->new( type => 'xxh32' );
            $ctx->add($chunk) for 1 .. $nchunk;
            $ctx->hexdigest;
        },
        'DH::xxh64' => sub {
            my $ctx = Digest::xxHash->new( type => 'xxh64' );
            $ctx->add($chunk) for 1 .. $nchunk;
            $ctx->hexdigest;
        },
        'Digest::MD5' => sub {
            my $ctx = Digest::MD5->new;
            $ctx->add($chunk) for 1 .. $nchunk;
            $ctx->hexdigest;
        },
        'Digest::SHA::sha224' => sub {
            my $ctx = Digest::SHA->new(224);
            $ctx->add($chunk) for 1 .. $nchunk;
            $ctx->hexdigest;
        }
    );
    if ( $HAVE{'Crypt::xxHash'} ) {
        $stream{'CH::xxhash3_64bits_stream'} = sub {
            my $s = Crypt::xxHash::xxhash3_64bits_stream(0);
            Crypt::xxHash::xxhash3_64bits_stream_update( $s, $chunk ) for 1 .. $nchunk;
            Crypt::xxHash::xxhash3_64bits_stream_digest_hex($s);
        };
    }
    cmpthese_mbps( 'Streaming, 1MB total', $size, \%stream );
}
{
    my $data = 'C' x 1024;
    my $size = 1024;
    say('# Hex digest overhead (functional, 1KB)');
    my %hex = (
        'DH::xxhash32_hex'        => sub { xxhash32_hex( $data, 0 ) },
        'DH::xxhash64_hex'        => sub { xxhash64_hex( $data, 0 ) },
        'DH::xxh3_64_hex'         => sub { xxh3_64_hex( $data, 0 ) },
        'DH::xxh3_128_hex'        => sub { xxh3_128_hex( $data, 0 ) },
        'Digest::MD5::md5_hex'    => sub { Digest::MD5::md5_hex($data) },
        'Digest::SHA::sha224_hex' => sub { Digest::SHA::sha224_hex($data) }
    );
    if ( $HAVE{'Crypt::xxHash'} ) {
        $hex{'CH::xxhash32_hex'}        = sub { Crypt::xxHash::xxhash32_hex( $data, 0 ) };
        $hex{'CH::xxhash64_hex'}        = sub { Crypt::xxHash::xxhash64_hex( $data, 0 ) };
        $hex{'CH::xxhash3_64bits_hex'}  = sub { Crypt::xxHash::xxhash3_64bits_hex( $data, 0 ) };
        $hex{'CH::xxhash3_128bits_hex'} = sub { Crypt::xxHash::xxhash3_128bits_hex( $data, 0 ) };
    }
    cmpthese_mbps( 'Hex output, 1KB input', $size, \%hex );
}
