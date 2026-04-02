package Hypersonic::JIT::Util;
use strict;
use warnings;

use Config;
use Carp qw(croak);

our $VERSION = '0.12';

# =============================================================================
# Cache Directory Management
# =============================================================================

# Base cache directory
our $CACHE_BASE = '_hypersonic_cache';

# Get cache directory for a module
sub cache_dir {
    my ($class, $subdir) = @_;
    return $subdir ? "$CACHE_BASE/$subdir" : $CACHE_BASE;
}

# Subdirectory constants
sub cache_dir_core     { shift->cache_dir('core') }
sub cache_dir_socket   { shift->cache_dir('socket') }
sub cache_dir_request  { shift->cache_dir('request') }
sub cache_dir_response { shift->cache_dir('response') }
sub cache_dir_session  { shift->cache_dir('session') }
sub cache_dir_tls      { shift->cache_dir('tls') }
sub cache_dir_future   { shift->cache_dir('future') }

# =============================================================================
# Fork Detection
# =============================================================================

sub can_fork {
    return $Config{d_fork} && eval { 
        my $pid = fork();
        if (defined $pid && $pid == 0) {
            exit(0);  # Child exits immediately
        }
        waitpid($pid, 0) if defined $pid;
        1;
    };
}

# =============================================================================
# Parallel Compilation
# =============================================================================

# Standalone modules that can compile independently
our @STANDALONE_MODULES = qw(
    Hypersonic::Socket
    Hypersonic::Response
    Hypersonic::Session
    Hypersonic::TLS
);

sub compile_standalone_modules {
    my ($class, %opts) = @_;
    
    my @modules = $opts{modules} // @STANDALONE_MODULES;
    my $parallel = $opts{parallel} // 1;
    
    # Load modules
    for my $mod (@modules) {
        eval "require $mod" or do {
            warn "Failed to load $mod: $@";
            return 0;
        };
    }
    
    if ($parallel && $class->can_fork) {
        return $class->_compile_parallel(\@modules, \%opts);
    } else {
        return $class->_compile_sequential(\@modules, \%opts);
    }
}

sub _compile_parallel {
    my ($class, $modules, $opts) = @_;
    
    my @pids;
    my %child_to_mod;
    
    for my $mod (@$modules) {
        my $pid = fork();
        
        if (!defined $pid) {
            warn "Fork failed for $mod: $!";
            # Fallback to sequential for this module
            eval { $mod->compile(%$opts) };
            warn "Compile failed for $mod: $@" if $@;
        } elsif ($pid == 0) {
            # Child process
            eval { $mod->compile(%$opts) };
            exit($@ ? 1 : 0);
        } else {
            # Parent
            push @pids, $pid;
            $child_to_mod{$pid} = $mod;
        }
    }
    
    # Wait for all children
    my $all_ok = 1;
    for my $pid (@pids) {
        waitpid($pid, 0);
        if ($? != 0) {
            my $mod = $child_to_mod{$pid};
            warn "Compilation failed for $mod (exit code: " . ($? >> 8) . ")";
            $all_ok = 0;
        }
    }
    
    # After fork compilation, parent must load the compiled modules
    # (children wrote to cache, but parent needs to load)
    for my $mod (@$modules) {
        eval { $mod->compile(%$opts) };  # Will load from cache
        if ($@) {
            warn "Failed to load compiled $mod: $@";
            $all_ok = 0;
        }
    }
    
    return $all_ok;
}

sub _compile_sequential {
    my ($class, $modules, $opts) = @_;
    
    my $all_ok = 1;
    for my $mod (@$modules) {
        eval { $mod->compile(%$opts) };
        if ($@) {
            warn "Compile failed for $mod: $@";
            $all_ok = 0;
        }
    }
    
    return $all_ok;
}

# =============================================================================
# Common Include Patterns
# =============================================================================

sub add_standard_includes {
    my ($class, $builder, @features) = @_;
    
    my %features = map { $_ => 1 } @features;
    
    # Always needed
    $builder->line('#include <stdlib.h>')
            ->line('#include <string.h>')
            ->line('#include <errno.h>');
    
    if ($features{stdio}) {
        $builder->line('#include <stdio.h>');
    }
    
    if ($features{unistd}) {
        $builder->line('#include <unistd.h>');
    }
    
    if ($features{fcntl}) {
        $builder->line('#include <fcntl.h>');
    }
    
    if ($features{socket}) {
        $builder->line('#include <sys/socket.h>')
                ->line('#include <sys/types.h>')
                ->line('#include <netinet/in.h>')
                ->line('#include <netinet/tcp.h>')
                ->line('#include <arpa/inet.h>')
                ->line('#include <sys/uio.h>');
    }
    
    if ($features{threading}) {
        $builder->line('#ifndef _WIN32')
                ->line('#include <pthread.h>')
                ->line('#endif');
    }
    
    if ($features{eventfd}) {
        $builder->line('#ifdef __linux__')
                ->line('#include <sys/eventfd.h>')
                ->line('#endif');
    }
    
    if ($features{time}) {
        $builder->line('#include <time.h>');
    }
    
    if ($features{signal}) {
        $builder->line('#include <signal.h>');
    }
    
    if ($features{openssl}) {
        $builder->line('#include <openssl/hmac.h>')
                ->line('#include <openssl/evp.h>')
                ->line('#include <openssl/rand.h>');
    }
    
    $builder->blank;
    
    return $builder;
}

# =============================================================================
# Platform Detection Helpers
# =============================================================================

sub add_platform_eventfd {
    my ($class, $builder) = @_;
    
    $builder->line('#ifndef _WIN32')
            ->line('#ifdef __linux__')
            ->line('#include <sys/eventfd.h>')
            ->line('#define USE_EVENTFD 1')
            ->line('#else')
            ->line('#define USE_EVENTFD 0')
            ->line('#endif')
            ->line('#endif /* !_WIN32 */')
            ->blank;
    
    return $builder;
}

sub add_platform_detection {
    my ($class, $builder) = @_;
    
    $builder->line('/* Platform detection */')
            ->line('#if defined(__APPLE__)')
            ->line('#define HYPERSONIC_MACOS 1')
            ->line('#elif defined(__linux__)')
            ->line('#define HYPERSONIC_LINUX 1')
            ->line('#elif defined(_WIN32)')
            ->line('#define HYPERSONIC_WINDOWS 1')
            ->line('#elif defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)')
            ->line('#define HYPERSONIC_BSD 1')
            ->line('#endif')
            ->blank;
    
    return $builder;
}

# =============================================================================
# Library Detection
# =============================================================================

# Check if Devel::CheckLib is available (CPAN standard for library detection)
my $HAS_DEVEL_CHECKLIB;
sub _has_devel_checklib {
    return $HAS_DEVEL_CHECKLIB if defined $HAS_DEVEL_CHECKLIB;
    $HAS_DEVEL_CHECKLIB = eval { require Devel::CheckLib; 1 } ? 1 : 0;
    return $HAS_DEVEL_CHECKLIB;
}

# Check if ExtUtils::PkgConfig is available
my $HAS_EXTUTILS_PKGCONFIG;
sub _has_extutils_pkgconfig {
    return $HAS_EXTUTILS_PKGCONFIG if defined $HAS_EXTUTILS_PKGCONFIG;
    $HAS_EXTUTILS_PKGCONFIG = eval { require ExtUtils::PkgConfig; 1 } ? 1 : 0;
    return $HAS_EXTUTILS_PKGCONFIG;
}

# Check if a library can actually be linked (compile+link test)
# Uses Devel::CheckLib when available (CPAN standard), falls back to manual test
sub can_link {
    my ($class, $cflags, $ldflags, $test_symbol, $extra_includes) = @_;
    $cflags //= '';
    $ldflags //= '';
    $extra_includes //= '';

    # Extract header names from include directives for Devel::CheckLib
    # e.g., '#include <math.h>' -> 'math.h'
    my @headers;
    if ($extra_includes) {
        @headers = ($extra_includes =~ /#include\s*[<"]([^>"]+)[>"]/g);
    }

    # Use Devel::CheckLib if available - it's the CPAN standard and handles
    # edge cases (different compilers, platforms, error handling) better
    if ($class->_has_devel_checklib()) {
        # Take address of symbol and store in volatile to force linker resolution
        # The void* cast works for both functions and variables
        my $function = "void *p = (void*)$test_symbol; volatile void *vp = p; return vp ? 0 : 1;";
        my %args = (
            INC      => $cflags,
            LIBS     => $ldflags,
            function => $function,
        );
        $args{header} = \@headers if @headers;
        return Devel::CheckLib::check_lib(%args);
    }

    # Fallback: manual compile+link test
    require File::Temp;

    # Generate test code that forces the linker to resolve the symbol
    # Take address and store in volatile to prevent optimization
    my $test_code = <<"C";
$extra_includes
int main(void) {
    void *p = (void*)$test_symbol;
    volatile void *vp = p;
    return vp ? 0 : 1;
}
C

    my $src = File::Temp->new(SUFFIX => '.c', UNLINK => 1);
    my $src_path = $src->filename;
    print $src $test_code;
    close $src;

    my $out = File::Temp->new(SUFFIX => '', UNLINK => 1);
    my $out_path = $out->filename;
    close $out;

    my $cc = $ENV{CC} || $Config{cc} || 'cc';
    my $result = system("$cc $cflags -o $out_path $src_path $ldflags 2>/dev/null");

    unlink $out_path if -f $out_path;

    return $result == 0;
}

sub detect_library {
    my ($class, $lib_name, %opts) = @_;

    my $result = {
        available => 0,
        cflags    => '',
        ldflags   => '',
    };

    my $test_symbol = $opts{test_symbol};
    my $test_include = $opts{test_include} // '';

    # Try Alien module first
    my $alien_module = $opts{alien} // "Alien::\u$lib_name";
    if (eval "require $alien_module; 1") {
        my $cflags = $alien_module->cflags // '';
        my $ldflags = $alien_module->libs // '';

        # Verify it actually links if test_symbol provided
        if (!$test_symbol || $class->can_link($cflags, $ldflags, $test_symbol, $test_include)) {
            $result->{available} = 1;
            $result->{cflags}  = $cflags;
            $result->{ldflags} = $ldflags;
            return $result;
        }
    }

    # Try pkg-config (prefer ExtUtils::PkgConfig if available - CPAN standard)
    my $pkg_name = $opts{pkg_config} // $lib_name;
    my ($cflags, $ldflags);

    if ($class->_has_extutils_pkgconfig() && ExtUtils::PkgConfig->exists($pkg_name)) {
        eval {
            my %pkg_info = ExtUtils::PkgConfig->find($pkg_name);
            $cflags = $pkg_info{cflags} // '';
            $ldflags = $pkg_info{libs} // '';
        };
    }

    # Fallback to command-line pkg-config
    if (!$ldflags) {
        $cflags = `pkg-config --cflags $pkg_name 2>/dev/null`;
        $ldflags = `pkg-config --libs $pkg_name 2>/dev/null`;
        if ($? == 0) {
            chomp($cflags);
            chomp($ldflags);
        } else {
            $cflags = $ldflags = '';
        }
    }

    if ($ldflags) {
        # Verify it actually links if test_symbol provided
        if (!$test_symbol || $class->can_link($cflags, $ldflags, $test_symbol, $test_include)) {
            $result->{available} = 1;
            $result->{cflags}  = $cflags;
            $result->{ldflags} = $ldflags;
            return $result;
        }
    }

    # Try common paths (with additional Homebrew versioned paths for OpenSSL)
    my @search_paths = @{$opts{paths} // [
        # macOS Homebrew (Apple Silicon) - versioned first
        '/opt/homebrew/opt/openssl@3',
        '/opt/homebrew/opt/openssl',
        '/opt/homebrew',
        # macOS Homebrew (Intel) - versioned first
        '/usr/local/opt/openssl@3',
        '/usr/local/opt/openssl',
        '/usr/local',
        # Linux standard locations
        '/usr',
        '/opt/local',
    ]};

    my $header = $opts{header};
    my $lib = $opts{lib} // "lib$lib_name";

    for my $prefix (@search_paths) {
        my $inc_dir = "$prefix/include";
        my $lib_dir = "$prefix/lib";

        # Check for header if specified
        if ($header && !-f "$inc_dir/$header") {
            next;
        }

        # Check for library file
        my $found_lib = 0;
        for my $ext (qw(.dylib .so .a)) {
            if (-f "$lib_dir/$lib$ext") {
                $found_lib = 1;
                last;
            }
        }

        if ($found_lib) {
            my $try_cflags = "-I$inc_dir";
            my $try_ldflags = "-L$lib_dir -l$lib_name";

            # Verify it actually links if test_symbol provided
            if (!$test_symbol || $class->can_link($try_cflags, $try_ldflags, $test_symbol, $test_include)) {
                $result->{available} = 1;
                $result->{cflags}  = $try_cflags;
                $result->{ldflags} = $try_ldflags;
                return $result;
            }
        }
    }

    return $result;
}

# Convenience methods for common libraries
sub detect_openssl {
    my ($class) = @_;
    return $class->detect_library('ssl',
        alien        => 'Alien::OpenSSL',
        pkg_config   => 'openssl',
        header       => 'openssl/ssl.h',
        lib          => 'libssl',
        test_symbol  => 'SSL_new',
        test_include => '#include <openssl/ssl.h>',
    );
}

sub detect_zlib {
    my ($class) = @_;
    return $class->detect_library('z',
        alien        => 'Alien::zlib',
        pkg_config   => 'zlib',
        header       => 'zlib.h',
        lib          => 'libz',
        test_symbol  => 'deflate',
        test_include => '#include <zlib.h>',
    );
}

sub detect_nghttp2 {
    my ($class) = @_;
    return $class->detect_library('nghttp2',
        pkg_config   => 'libnghttp2',
        header       => 'nghttp2/nghttp2.h',
        test_symbol  => 'nghttp2_session_client_new',
        test_include => '#include <nghttp2/nghttp2.h>',
    );
}

# =============================================================================
# C99 Detection
# =============================================================================

my $C99_SUPPORTED;

sub has_c99 {
    my ($class) = @_;
    return $C99_SUPPORTED if defined $C99_SUPPORTED;

    require File::Temp;

    # Test C99 features: inline keyword and for-loop declarations
    my $test_code = <<'C';
static inline int test_inline(void) { return 1; }
int main(void) {
    for (int i = 0; i < 1; i++) { }
    return test_inline();
}
C

    my $src = File::Temp->new(SUFFIX => '.c', UNLINK => 1);
    my $src_path = $src->filename;
    print $src $test_code;
    close $src;

    my $out = File::Temp->new(SUFFIX => '', UNLINK => 1);
    my $out_path = $out->filename;
    close $out;

    my $cc = $ENV{CC} || $Config{cc} || 'cc';
    my $result = system("$cc -o $out_path $src_path 2>/dev/null");

    unlink $out_path if -f $out_path;

    $C99_SUPPORTED = ($result == 0) ? 1 : 0;
    return $C99_SUPPORTED;
}

sub inline_keyword {
    my ($class) = @_;
    return $class->has_c99() ? 'inline' : '';
}


1;

__END__

=head1 NAME

Hypersonic::JIT::Util - Utilities for JIT compilation in Hypersonic

=head1 SYNOPSIS

    use Hypersonic::JIT::Util;
    
    # Get cache directory
    my $cache = Hypersonic::JIT::Util->cache_dir('socket');
    # Returns: _hypersonic_cache/socket
    
    # Compile standalone modules in parallel
    Hypersonic::JIT::Util->compile_standalone_modules(parallel => 1);
    
    # Add common includes to builder
    Hypersonic::JIT::Util->add_standard_includes($builder, qw(socket threading));
    
    # Detect library
    my $ssl = Hypersonic::JIT::Util->detect_openssl();
    if ($ssl->{available}) {
        # Use $ssl->{cflags} and $ssl->{ldflags}
    }

=head1 DESCRIPTION

This module provides common utilities for JIT compilation across Hypersonic modules:

=over 4

=item * Unified cache directory structure

=item * Fork-based parallel compilation

=item * Standard include patterns

=item * Library detection (Alien → pkg-config → path search)

=back

=head1 METHODS

=head2 cache_dir($subdir)

Returns the cache directory path. With C<$subdir>, returns C<_hypersonic_cache/$subdir>.

=head2 compile_standalone_modules(%opts)

Compiles all standalone modules (Socket, Response, Session, TLS).

Options:

=over 4

=item parallel => 1

Use fork for parallel compilation (default: 1)

=item modules => \@list

Override list of modules to compile

=back

=head2 can_fork()

Returns true if fork() is available on this platform.

=head2 add_standard_includes($builder, @features)

Adds standard C includes to the builder based on features:
C<socket>, C<threading>, C<time>, C<signal>, C<unistd>, C<fcntl>

=head2 detect_library($name, %opts)

Detects a C library. Returns hashref with C<available>, C<cflags>, C<ldflags>.

=head2 detect_openssl(), detect_zlib(), detect_nghttp2()

Convenience methods for common libraries.

=head2 has_c99()

Returns true if the compiler supports C99 features (inline keyword and
for-loop variable declarations). Result is cached after first call.

    if (Hypersonic::JIT::Util->has_c99()) {
        $builder->line('static inline int fast_func(void) { return 1; }');
    }

=head2 inline_keyword()

Returns C<'inline'> if C99 is supported, empty string otherwise.

    my $inline = Hypersonic::JIT::Util->inline_keyword();
    $builder->line("static $inline void my_func(void) { }");

=head1 AUTHOR

Hypersonic Contributors

=cut
