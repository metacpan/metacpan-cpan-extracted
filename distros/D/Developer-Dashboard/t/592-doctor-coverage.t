#!/usr/bin/env perl

use strict;
use warnings;

# CORE::GLOBAL overrides must exist before the module under test is compiled.
# Each one fails only for exact registered paths (open mode and path for close),
# so the failure branches run for any uid, including root.
our ( %FAIL_CLOSE, %FAIL_CHMOD );
my %close_handles;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        my $rc = @_ == 2 ? CORE::open( $_[0], $_[1] ) : CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
        if ( $rc && @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_CLOSE{"$_[1]|$_[2]"} ) {
            $close_handles{ Scalar::Util::refaddr( $_[0] ) } = 1;
        }
        return $rc;
    };
    *CORE::GLOBAL::close = sub (;*) {
        my $fail = @_ && ref $_[0] && delete $close_handles{ Scalar::Util::refaddr( $_[0] ) };
        my $rc = @_ ? CORE::close( $_[0] ) : CORE::close();
        if ($fail) {
            $! = 5;
            return 0;
        }
        return $rc;
    };
    *CORE::GLOBAL::chmod = sub (@) {
        my ( $mode, @list ) = @_;
        if ( @list == 1 && $FAIL_CHMOD{ $list[0] } ) {
            $! = 1;
            return 0;
        }
        return CORE::chmod( $mode, @list );
    };
}

use Test::More;
use Scalar::Util ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Doctor;
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $doctor = Developer::Dashboard::Doctor->new( paths => $paths );

sub write_file {
    my ( $path, $body ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $body;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# chmod failure while repairing permissions.
{
    my $root = File::Spec->catdir( $home, 'audit-root' );
    make_path($root);
    my $file = write_file( File::Spec->catfile( $root, 'loose.txt' ), "x\n" );
    chmod 0644, $file or die "Unable to chmod $file: $!";
    local $FAIL_CHMOD{$file} = 1;
    my $ok = eval { $doctor->_audit_root( path => $root, label => 'probe', fix => 1 ); 1 };
    ok( !$ok, 'a failing chmod during fix is fatal' );
    like( $@, qr/Unable to chmod \Q$file\E to 0600/, 'the chmod failure names the file and the expected mode' );
}

# close failure after reading.
{
    my $file = write_file( File::Spec->catfile( $home, 'read.txt' ), "body\n" );
    is( $doctor->_slurp_text_file($file), "body\n", 'a normal read returns the body' );
    local $FAIL_CLOSE{"<|$file"} = 1;
    my $ok = eval { $doctor->_slurp_text_file($file); 1 };
    ok( !$ok, 'a close failure after reading is fatal' );
    like( $@, qr/Unable to close \Q$file\E after reading/, 'the read-close failure names the file' );
    my $empty = write_file( File::Spec->catfile( $home, 'empty.txt' ), '' );
    is( $doctor->_slurp_text_file($empty), '', 'an empty file reads as the empty string' );
}

# close failure after writing the rewritten bashrc.
{
    my $line = q{export PATH="$HOME/perl5/perlbrew/perls/perl-5.36/bin:$PATH"};
    my $body = "case \$- in\n    *i*) ;;\n      *) return;;\nesac\n$line\n";
    my $bashrc = write_file( File::Spec->catfile( $home, '.bashrc' ), $body );
    local $FAIL_CLOSE{">|$bashrc"} = 1;
    my $ok = eval { $doctor->_rewrite_bashrc_dashboard_lines($bashrc); 1 };
    ok( !$ok, 'a close failure after writing the bashrc is fatal' );
    like( $@, qr/Unable to close \Q$bashrc\E after writing/, 'the write-close failure names the file' );
}

done_testing;

__END__

=pod

=head1 NAME

t/592-doctor-coverage.t - covers the chmod and close failure branches of Developer::Dashboard::Doctor

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces chmod and close failures through CORE::GLOBAL overrides.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate must be met without any C<# uncoverable> annotation, and these paths can only be reached by injecting failures that work for any uid, including root.

=head1 WHEN TO USE

Use this file when you change Developer::Dashboard::Doctor, or when a coverage run reports one of these paths as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/592-doctor-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/592-doctor-coverage.t

Run this coverage-gap test by itself while editing Developer::Dashboard::Doctor.

=cut
