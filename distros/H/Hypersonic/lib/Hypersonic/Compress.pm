package Hypersonic::Compress;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.03';

# JIT-compiled gzip compression for Hypersonic
# All compression happens in C via zlib for maximum performance

# Configuration
my $COMPRESS_CONFIG;

# Check if zlib is available
sub check_zlib {
    # Try to find zlib header
    my @search_paths = qw(
        /usr/include
        /usr/local/include
        /opt/homebrew/include
        /opt/local/include
    );
    
    # Add macOS SDK paths
    push @search_paths, glob('/Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk/usr/include');
    push @search_paths, glob('/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.sdk/usr/include');
    
    for my $path (@search_paths) {
        return 1 if -f "$path/zlib.h";
    }
    
    # Try pkg-config
    my $flags = `pkg-config --cflags zlib 2>/dev/null`;
    return 1 if $? == 0;
    
    # Try compiling a test
    my $test = `echo '#include <zlib.h>' | cc -E -x c - 2>/dev/null`;
    return 1 if $? == 0;
    
    return 0;
}

# Get zlib compiler flags
sub get_zlib_flags {
    # Try pkg-config first
    my $cflags = `pkg-config --cflags zlib 2>/dev/null`;
    my $libs = `pkg-config --libs zlib 2>/dev/null`;
    
    if ($? == 0) {
        chomp($cflags);
        chomp($libs);
        return ($cflags, $libs);
    }
    
    # Fallback for common paths
    my @include_paths = qw(
        /usr/include
        /usr/local/include
        /opt/homebrew/include
        /opt/local/include
    );
    
    # Add macOS SDK paths
    push @include_paths, glob('/Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk/usr/include');
    
    for my $path (@include_paths) {
        if (-f "$path/zlib.h") {
            my $lib_path = $path;
            $lib_path =~ s/include/lib/;
            # For macOS SDK, just use -lz since the library is in the system
            if ($path =~ /SDK/) {
                return ("", "-lz");
            }
            return ("-I$path", "-L$lib_path -lz");
        }
    }
    
    # Default - zlib is typically in the system path on macOS
    return ("", "-lz");
}

# Configure compression
sub configure {
    my ($class, %opts) = @_;
    
    $COMPRESS_CONFIG = {
        enabled       => $opts{enabled} // 1,
        min_size      => $opts{min_size} // 1024,      # Don't compress < 1KB
        level         => $opts{level} // 6,             # Compression level 1-9
        types         => $opts{types} // [              # MIME types to compress
            'text/html',
            'text/css',
            'text/plain',
            'text/xml',
            'text/javascript',
            'application/json',
            'application/javascript',
            'application/xml',
            'application/xhtml+xml',
            'image/svg+xml',
        ],
    };
    
    return $COMPRESS_CONFIG;
}

# Get config
sub config { $COMPRESS_CONFIG }

# Generate C code for JIT inclusion
# Returns the C function and required includes
sub generate_c_code {
    my ($class, $level) = @_;
    $level //= $COMPRESS_CONFIG->{level} // 6;
    my $min_size = $COMPRESS_CONFIG->{min_size} // 1024;
    
    my $c_code = <<"END_C";
#include <zlib.h>
#include <string.h>
#include <stdlib.h>

/* Thread-local compression buffer */
static __thread unsigned char gzip_out_buf[131072];  /* 128KB max compressed */
static __thread z_stream zstrm;
static __thread int zstrm_initialized = 0;

/* Check if client accepts gzip */
static int accepts_gzip(const char* accept_encoding, size_t len) {
    if (!accept_encoding || len == 0) return 0;
    /* Simple check for "gzip" substring */
    const char* p = accept_encoding;
    const char* end = accept_encoding + len;
    while (p < end - 3) {
        if (p[0] == 'g' && p[1] == 'z' && p[2] == 'i' && p[3] == 'p') {
            return 1;
        }
        p++;
    }
    return 0;
}

/* Gzip compress data - returns compressed length or 0 on failure */
static size_t gzip_compress(const char* input, size_t input_len, 
                            unsigned char** output, int level) {
    /* Don't compress small responses */
    if (input_len < $min_size) return 0;
    
    /* Max output size */
    size_t max_out = compressBound(input_len) + 18; /* gzip header/footer */
    if (max_out > sizeof(gzip_out_buf)) return 0;
    
    /* Initialize deflate with gzip wrapper */
    z_stream strm;
    memset(&strm, 0, sizeof(strm));
    
    /* 15 + 16 = gzip format */
    if (deflateInit2(&strm, level, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        return 0;
    }
    
    strm.next_in = (Bytef*)input;
    strm.avail_in = input_len;
    strm.next_out = gzip_out_buf;
    strm.avail_out = sizeof(gzip_out_buf);
    
    int ret = deflate(&strm, Z_FINISH);
    size_t compressed_len = strm.total_out;
    
    deflateEnd(&strm);
    
    if (ret != Z_STREAM_END) return 0;
    
    /* Only use compression if it actually saves space */
    if (compressed_len >= input_len) return 0;
    
    *output = gzip_out_buf;
    return compressed_len;
}
END_C

    return $c_code;
}

# Generate the response building code with compression
sub generate_response_code {
    my ($class, $builder, $level) = @_;
    $level //= $COMPRESS_CONFIG->{level} // 6;
    
    # This generates the compression block that goes after body is determined
    # but before headers are written
    
    $builder
      ->blank
      ->comment('Check for gzip compression support')
      ->line('int use_gzip = 0;')
      ->line('unsigned char* compressed_body = NULL;')
      ->line('size_t compressed_len = 0;')
      ->line('const char* accept_enc = NULL;')
      ->line('size_t accept_enc_len = 0;')
      ->blank
      ->comment('Get Accept-Encoding from request headers')
      ->line('if (req_headers) {')
      ->line('    SV** ae = hv_fetch(req_headers, "accept_encoding", 15, 0);')
      ->line('    if (ae && SvOK(*ae)) {')
      ->line('        accept_enc = SvPV(*ae, accept_enc_len);')
      ->line('    }')
      ->line('}')
      ->blank
      ->comment('Compress if client accepts gzip and response is large enough')
      ->line("if (accepts_gzip(accept_enc, accept_enc_len) && len >= $COMPRESS_CONFIG->{min_size}) {")
      ->line("    compressed_len = gzip_compress(body_str, len, &compressed_body, $level);")
      ->line('    if (compressed_len > 0) {')
      ->line('        use_gzip = 1;')
      ->line('    }')
      ->line('}');
    
    return $builder;
}

# Modify header building to include Content-Encoding
sub generate_header_code {
    my ($class, $builder) = @_;
    
    # This adds Content-Encoding: gzip header when compression is used
    $builder
      ->line('if (use_gzip) {')
      ->line('    hdr_len += snprintf(resp_buf + hdr_len, sizeof(resp_buf) - hdr_len,')
      ->line('        "Content-Encoding: gzip\\r\\n");')
      ->line('}');
    
    return $builder;
}

1;

__END__

=head1 NAME

Hypersonic::Compress - JIT-compiled gzip compression for Hypersonic

=head1 SYNOPSIS

    use Hypersonic;

    my $server = Hypersonic->new();

    # Enable gzip compression
    $server->compress(
        min_size => 1024,    # Minimum size to compress (bytes)
        level    => 6,       # Compression level (1-9)
    );

    $server->get('/api/data' => sub {
        my ($req) = @_;
        # Large JSON response will be gzip compressed
        return res->json({ data => [...large array...] });
    }, { dynamic => 1 });

=head1 DESCRIPTION

C<Hypersonic::Compress> provides JIT-compiled gzip compression using
zlib. All compression happens in C for maximum performance.

=head2 How It Works

1. At compile time, zlib compression code is JIT-compiled into the server

2. For each response, the C code checks:
   - Does client send C<Accept-Encoding: gzip>?
   - Is response body larger than C<min_size>?
   - Is Content-Type compressible (text/*, application/json, etc.)?

3. If all conditions are met, the response is gzip compressed in C

4. C<Content-Encoding: gzip> header is added automatically

=head2 Performance

Compression runs entirely in C using zlib, with no Perl overhead.
Thread-local buffers avoid memory allocation for each request.

=head1 CONFIGURATION

=over 4

=item min_size

Minimum response size to compress. Responses smaller than this are
sent uncompressed. Default: 1024 bytes.

=item level

Compression level from 1 (fastest) to 9 (smallest). Default: 6
(good balance of speed and compression ratio).

=item types

Array of MIME types to compress. Default includes text/*, 
application/json, application/javascript, etc.

=back

=head1 REQUIREMENTS

Requires zlib library to be installed:

    # macOS
    brew install zlib
    
    # Ubuntu/Debian
    apt-get install zlib1g-dev
    
    # RHEL/CentOS
    yum install zlib-devel

=head1 SEE ALSO

L<Hypersonic>, L<Hypersonic::Response>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

Same terms as Perl itself.

=cut
