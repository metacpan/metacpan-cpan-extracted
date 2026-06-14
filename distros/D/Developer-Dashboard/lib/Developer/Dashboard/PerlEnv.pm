package Developer::Dashboard::PerlEnv;

use strict;
use warnings;

our $VERSION = '4.16';

use Config ();
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

# path_separator()
# Returns the platform-specific Perl library path separator.
# Input: none.
# Output: one-character separator string used by PERL5LIB.
sub path_separator {
    return $^O eq 'MSWin32' ? ';' : ':';
}

# current_perl_bin_dir()
# Returns the directory that contains the active Perl interpreter so
# dashboard-managed child processes can keep `/usr/bin/env perl` aligned with
# the current runtime.
# Input: none.
# Output: absolute or original interpreter directory path string, or empty
# string when unavailable.
sub current_perl_bin_dir {
    my $perl = $^X || '';
    return '' if $perl eq '';
    my $resolved = abs_path($perl) || $perl;
    my $dir = dirname($resolved);
    return defined $dir && $dir ne '' && -d $dir ? $dir : '';
}

# current_shell_bin_dir()
# Returns the directory that contains the shell used for dashboard-managed
# shell command execution so PATH repair can keep shell-based collector
# commands runnable even when the inherited PATH is broken.
# Input: none.
# Output: absolute or original shell directory path string, or empty string
# when unavailable.
sub current_shell_bin_dir {
    my $shell = $Config::Config{sh} || '';
    return '' if $shell eq '';
    my $resolved = abs_path($shell) || $shell;
    my $dir = dirname($resolved);
    return defined $dir && $dir ne '' && -d $dir ? $dir : '';
}

# core_inc_paths()
# Returns the stable core/site/vendor Perl library directories for the active
# interpreter in an order that keeps core dual-life modules ahead of user-local
# shadow copies.
# Input: none.
# Output: ordered list of existing Perl library directory paths.
sub core_inc_paths {
    my @paths;
    my %seen;
    for my $key (qw(archlibexp privlibexp sitearchexp sitelibexp vendorarchexp vendorlibexp)) {
        my $path = $Config::Config{$key} || '';
        next if $path eq '';
        next if !-d $path;
        my $canon = File::Spec->canonpath($path);
        next if $seen{$canon}++;
        push @paths, $path;
    }
    return @paths;
}

# dashboard_lib_roots($dashboard_lib)
# Expands one dashboard library root into the concrete Perl library paths that
# may exist inside a checkout or a local::lib style installed tree.
# Input: dashboard library root directory path string.
# Output: ordered list of existing dashboard library directory paths.
sub dashboard_lib_roots {
    my ( $class, $dashboard_lib ) = @_;
    return () if !defined $dashboard_lib || $dashboard_lib eq '';

    my @candidates = ($dashboard_lib);
    my $perl5_root = File::Spec->catdir( $dashboard_lib, 'perl5' );
    if ( -d $perl5_root ) {
        push @candidates, $perl5_root;
        my $archname = $Config::Config{archname} || '';
        if ( $archname ne '' ) {
            my $arch_root = File::Spec->catdir( $perl5_root, $archname );
            push @candidates, $arch_root if -d $arch_root;
        }
    }

    my @ordered;
    my %seen;
    for my $path (@candidates) {
        next if !defined $path || $path eq '' || !-d $path;
        my $canon = File::Spec->canonpath($path);
        next if $seen{$canon}++;
        push @ordered, $path;
    }
    return @ordered;
}

# perl5lib_list(%args)
# Builds one ordered PERL5LIB search path that keeps dashboard libraries and
# Perl core directories ahead of inherited user-local paths while preserving
# any extra runtime-specific library roots.
# Input: optional env hash reference, optional existing path list array
# reference, optional extra path list array reference, and optional dashboard
# lib path string.
# Output: ordered list of PERL5LIB directory paths.
sub perl5lib_list {
    my ( $class, %args ) = @_;
    my $env = ref( $args{env} ) eq 'HASH' ? $args{env} : \%ENV;
    my $path_sep = $args{path_sep} || path_separator();

    my @existing = ref( $args{existing} ) eq 'ARRAY'
      ? @{ $args{existing} }
      : grep { defined $_ && $_ ne '' } split /\Q$path_sep\E/, ( $env->{PERL5LIB} || '' );

    my @ordered;
    my %seen;
    my @prefixes = (
        (
            defined $args{dashboard_lib} && $args{dashboard_lib} ne ''
              ? $class->dashboard_lib_roots( $args{dashboard_lib} )
              : ()
        ),
        @{ $args{extra} || [] },
        $class->core_inc_paths,
        @existing,
    );
    for my $path (@prefixes) {
        next if !defined $path || $path eq '';
        next if !-d $path;
        my $canon = File::Spec->canonpath($path);
        next if $seen{$canon}++;
        push @ordered, $path;
    }
    return @ordered;
}

# perl5lib_env(%args)
# Returns the merged PERL5LIB string for one process environment update using
# the safe path ordering from perl5lib_list().
# Input: same named arguments as perl5lib_list().
# Output: scalar PERL5LIB string.
sub perl5lib_env {
    my ( $class, %args ) = @_;
    my $path_sep = $args{path_sep} || path_separator();
    return join( $path_sep, $class->perl5lib_list(%args) );
}

# path_with_current_perl(%args)
# Returns one PATH value that keeps the current Perl interpreter directory and
# the active shell directory ahead of inherited entries so dashboard-owned
# shebang and shell subprocesses continue to use the same runtime tools as the
# parent process.
# Input: optional env hash reference and optional path separator override.
# Output: scalar PATH string.
sub path_with_current_perl {
    my ( $class, %args ) = @_;
    my $env = ref( $args{env} ) eq 'HASH' ? $args{env} : \%ENV;
    my $path_sep = $args{path_sep} || path_separator();
    my @existing = grep { defined $_ && $_ ne '' } split /\Q$path_sep\E/, ( $env->{PATH} || '' );
    my @ordered;
    my %seen;
    for my $path ( $class->current_perl_bin_dir, $class->current_shell_bin_dir, @existing ) {
        next if !defined $path || $path eq '' || !-d $path;
        my $canon = File::Spec->canonpath($path);
        next if $seen{$canon}++;
        push @ordered, $path;
    }
    return join( $path_sep, @ordered );
}

# dashboard_child_env(%args)
# Returns the common environment overrides dashboard-managed child processes
# need so they keep the current Perl interpreter and the safe Perl library
# ordering.
# Input: optional env hash reference plus the same named arguments accepted by
# perl5lib_env().
# Output: hash reference containing PATH and PERL5LIB overrides.
sub dashboard_child_env {
    my ( $class, %args ) = @_;
    my $env = ref( $args{env} ) eq 'HASH' ? $args{env} : \%ENV;
    return {
        PATH     => $class->path_with_current_perl( env => $env, path_sep => $args{path_sep} ),
        PERL5LIB => $class->perl5lib_env( %args, env => $env ),
    };
}

# bootstrap_perl5lib(%args)
# Writes the safe PERL5LIB ordering back into the target environment during
# early process bootstrap so staged helpers do not load stale dual-life XS
# modules ahead of core Perl copies.
# Input: optional env hash reference plus the same named arguments accepted by
# perl5lib_env().
# Output: final PERL5LIB string written into the target environment.
sub bootstrap_perl5lib {
    my ( $class, %args ) = @_;
    my $env = ref( $args{env} ) eq 'HASH' ? $args{env} : \%ENV;
    my $value = $class->perl5lib_env( %args, env => $env );
    $env->{PERL5LIB} = $value;
    return $value;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::PerlEnv - normalize safe Perl library ordering for dashboard processes

=head1 SYNOPSIS

  use Developer::Dashboard::PerlEnv;

  my $perl5lib = Developer::Dashboard::PerlEnv->perl5lib_env(
      dashboard_lib => $dashboard_lib,
      extra         => \@runtime_local_libs,
  );

  BEGIN {
      Developer::Dashboard::PerlEnv->bootstrap_perl5lib(
          dashboard_lib => $dashboard_lib,
      );
  }

=head1 DESCRIPTION

This module centralizes the C<PERL5LIB> ordering used by the public
C<dashboard> switchboard, staged private helpers, and dashboard-managed child
process environments. It keeps dashboard libraries and the active Perl core
directories ahead of inherited user-local paths so stale dual-life XS modules
such as C<Encode> do not shadow the interpreter's matching core copy.

=head1 PURPOSE

Use this module when changing how dashboard bootstraps Perl library search
paths or when debugging environment-specific startup failures caused by local
Perl module shadowing.

=head1 WHY IT EXISTS

Dashboard has to keep its own Perl runtime consistent across the public
switchboard, staged private helpers, collectors, saved Ajax handlers, and
skill subprocesses. A plain inherited C<PERL5LIB> or C<PATH> can be enough to
break that guarantee on hosts with older local-lib trees or multiple Perl
installs. This module exists so every dashboard-owned child process uses one
shared normalization path instead of each caller rebuilding the environment in
slightly different ways.

=head1 WHEN TO USE

Use this module when bootstrapping C<dashboard> itself, when staging or
running private helper commands, and whenever dashboard-managed subprocesses
need a Perl-aware child environment. It is also the right place to debug XS
handshake mismatches, interpreter drift, or any bug where a child process
finds the wrong Perl binary or the wrong core module tree.

=head1 HOW TO USE

For early process bootstrap, call C<bootstrap_perl5lib()> in a C<BEGIN> block
before heavier dashboard modules load. For child process spawning, call
C<dashboard_child_env()> and layer the returned C<PATH> and C<PERL5LIB>
entries into the child environment. For inspection or tests, call
C<perl5lib_list()> or C<path_with_current_perl()> directly and assert the
ordered results.

=head1 METHODS

=head2 path_separator

Returns the platform-specific separator used by C<PERL5LIB>.

=head2 core_inc_paths

Returns the ordered core, site, and vendor Perl library directories for the
active interpreter.

=head2 perl5lib_list

Builds the ordered list of C<PERL5LIB> paths using the dashboard lib path,
runtime-specific extra paths, the active interpreter's core directories, and
the inherited environment.

=head2 perl5lib_env

Returns the final joined C<PERL5LIB> string built from C<perl5lib_list>.

=head2 path_with_current_perl

Returns the final joined C<PATH> string that keeps the current Perl
interpreter directory ahead of inherited entries.

=head2 dashboard_child_env

Returns the combined child-process C<PATH> and C<PERL5LIB> overrides used by
dashboard-managed subprocesses.

=head2 bootstrap_perl5lib

Writes the normalized C<PERL5LIB> value back into the target environment hash,
defaulting to C<%ENV>.

=head1 EXAMPLES

  my @paths = Developer::Dashboard::PerlEnv->perl5lib_list(
      dashboard_lib => '/home/mv/perl5/lib',
      extra         => ['/tmp/project/.developer-dashboard/local/lib/perl5'],
  );

  my $value = Developer::Dashboard::PerlEnv->bootstrap_perl5lib(
      dashboard_lib => "$Bin/../lib",
  );

  my $env = Developer::Dashboard::PerlEnv->dashboard_child_env(
      dashboard_lib => "$Bin/../lib",
      extra         => ['/tmp/project/.developer-dashboard/local/lib/perl5'],
  );

=head1 WHAT USES IT

The public C<bin/dashboard> entrypoint uses it during early bootstrap, the
staged private helper runtime uses it before loading command implementations,
and runtime child-process builders use it to prepare safe Perl environments
for saved Ajax handlers, skills, and collector-related subprocesses.

=cut
