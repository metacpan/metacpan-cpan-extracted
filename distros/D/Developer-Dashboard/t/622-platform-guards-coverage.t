#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Platform ();

sub error_of { my ($code) = @_; return eval { $code->(); 1 } ? '' : $@ }

# shell_command_argv: no explicit shell and no native shell either.
{
    no warnings 'redefine';
    local *Developer::Dashboard::Platform::native_shell_name = sub { return '' };
    like( error_of( sub { Developer::Dashboard::Platform::shell_command_argv('true') } ), qr/Unsupported shell/, 'an empty explicit and native shell is rejected' );
}

# normalize_shell_name strips directories from a shell path.
is( Developer::Dashboard::Platform::normalize_shell_name('/usr/local/bin/ZSH'), 'zsh', 'a shell path is reduced to its lower-cased base name' );

# _posix_shell_binary falls back to the bare preferred name with an empty PATH.
{
    my $empty = tempdir( CLEANUP => 1 );
    local $ENV{PATH} = $empty;
    is( Developer::Dashboard::Platform::_posix_shell_binary('bash'), 'bash', 'the preferred name is returned when neither it nor sh is on PATH' );
    is( Developer::Dashboard::Platform::_posix_shell_binary(''), '', 'an empty preferred name is returned unchanged when nothing resolves' );
}

# _exec_java_source: staging copy failure and an empty resolved classpath.
{
    my $dir = tempdir( CLEANUP => 1 );
    my $src = File::Spec->catfile( $dir, 'Hello.java' );
    open my $fh, '>', $src or die "Unable to write $src: $!";
    print {$fh} "class Hello { public static void main(String[] a) {} }\n";
    close $fh or die "Unable to close $src: $!";

    no warnings 'redefine';
    {
        local *Developer::Dashboard::Platform::copy = sub { $! = 28; return 0 };
        like( error_of( sub { Developer::Dashboard::Platform::_exec_java_source($src) } ), qr/Unable to stage Java source \Q$src\E/, 'a failed staging copy dies before javac runs' );
    }

    my $pom_root = tempdir( CLEANUP => 1 );
    my $config   = File::Spec->catdir( $pom_root, 'config' );
    mkdir $config or die "mkdir: $!";
    my $pom = File::Spec->catfile( $config, 'pom.xml' );
    open my $pfh, '>', $pom or die "Unable to write $pom: $!";
    print {$pfh} "<project/>\n";
    close $pfh or die "Unable to close $pom: $!";
    my @exec;
    local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub {
        my ( $tool, @rest ) = @_;
        for my $arg (@rest) {
            next if $arg !~ /^-Dmdep\.outputFile=(.*)/;
            open my $out, '>', $1 or die "Unable to write $1: $!";
            close $out or die "Unable to close $1: $!";
        }
        $? = 0;
        return 0;
    };
    local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub { @exec = @_; return 1 };
    ok( eval { Developer::Dashboard::Platform::_exec_java_source_via_mvn( $pom, 'Hello' ); 1 }, 'an empty classpath file is accepted' );
    is( $exec[2], File::Spec->catdir( $pom_root, 'target', 'classes' ), 'an empty dependency classpath leaves only the classes directory' );
}

done_testing;

__END__

=pod

=head1 NAME

t/622-platform-guards-coverage.t - covers the shell, PATH and Java staging guard branches of Developer::Dashboard::Platform

=head1 PURPOSE

Test file in the Developer Dashboard codebase. covers the shell, PATH and Java staging guard branches of Developer::Dashboard::Platform

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate with zero uncoverable annotations needs the empty-shell, missing-PATH, failed-copy and empty-classpath paths of Platform exercised.

=head1 WHEN TO USE

Use this file when you change Platform shell normalisation, POSIX shell lookup or Java launching, or when a coverage run reports one of those branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/622-platform-guards-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/622-platform-guards-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/622-platform-guards-coverage.t

Confirm the targeted branches are reported as covered.

=cut
