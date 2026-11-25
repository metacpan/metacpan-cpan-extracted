use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $pod_gate = File::Spec->catfile( $ROOT, 'script', 'pod-coverage-gate' );
my $markdown_gate = File::Spec->catfile( $ROOT, 'script', 'markdown-coverage-gate' );

ok( -x $pod_gate || -f $pod_gate, 'POD coverage gate exists' );
ok( -x $markdown_gate || -f $markdown_gate, 'Markdown coverage gate exists' );


my $tmp = tempdir( CLEANUP => 1 );
my $good_pod = File::Spec->catfile( $tmp, 'good.t' );
my $bad_pod  = File::Spec->catfile( $tmp, 'bad.t' );
_write( $good_pod, "use strict;\n1;\n__END__\n\n=head1 NAME\n\ngood\n\n=cut\n" );
_write( $bad_pod, "use strict;\n1;\n" );

my ( $pod_ok_rc, $pod_ok_out ) = _run( $^X, $pod_gate, $good_pod );
is( $pod_ok_rc, 0, 'POD gate accepts a fully documented Perl source file' );
like( $pod_ok_out, qr/POD coverage:\s*1\/1\s*\(100\.0%\)/,
    'POD gate reports an explicit 100 percent result' );

my ( $pod_bad_rc, $pod_bad_out ) = _run( $^X, $pod_gate, $bad_pod );
isnt( $pod_bad_rc, 0, 'POD gate fails when a Perl source file has no POD' );
like( $pod_bad_out, qr/POD coverage:\s*0\/1\s*\(0\.0%\)/,
    'POD gate reports the failed coverage percentage' );

my $good_md = File::Spec->catfile( $tmp, 'good.md' );
my $bad_md  = File::Spec->catfile( $tmp, 'bad.md' );
_write( $good_md, "# Good\n\n```text\nok\n```\n" );
_write( $bad_md,  "# Bad\n\n```text\nnot closed\n" );

my ( $md_ok_rc, $md_ok_out ) = _run( $^X, $markdown_gate, $good_md );
is( $md_ok_rc, 0, 'Markdown gate accepts structurally valid Markdown' );
like( $md_ok_out, qr/Markdown coverage:\s*1\/1\s*\(100\.0%\)/,
    'Markdown gate reports an explicit 100 percent result' );

my ( $md_bad_rc, $md_bad_out ) = _run( $^X, $markdown_gate, $bad_md );
isnt( $md_bad_rc, 0, 'Markdown gate fails an unclosed fenced code block' );
like( $md_bad_out, qr/Markdown coverage:\s*0\/1\s*\(0\.0%\)/,
    'Markdown gate reports the failed coverage percentage' );

done_testing();

sub _write {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
}

sub _run {
    my (@command) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system @command;
        return $? >> 8;
    };
    return ( $exit, $stdout . $stderr );
}

__END__

=head1 NAME

t/684-coverage-gate-scripts.t - protect the POD and Markdown coverage gate scripts

=head1 PURPOSE

Verify that the POD coverage gate and the Markdown coverage gate exist, accept a
good sample file with an explicit 100 percent result, and reject a bad sample
file with a non-zero exit and an explicit 0 percent result.

=head1 WHY IT EXISTS

These checks used to live in a test file that skipped whole once the GitHub
coverage workflow was removed, so the two gate scripts went untested. That file
was deleted on 2026-11-23. The checks on the scripts themselves are kept here,
word for word, with no workflow gate, so they run on every platform.

=head1 WHEN TO USE

Run this test whenever changing either coverage gate script, the way they report
their result, or the Perl modules they depend on.

=head1 HOW TO USE

    prove -lv t/684-coverage-gate-scripts.t

=head1 WHAT USES IT

The full repository test suite runs this test on every platform.

=head1 EXAMPLES

A Perl file with a NAME section passes the POD gate with C<POD coverage: 1/1
(100.0%)>. A Markdown file with an unclosed fenced code block fails the Markdown
gate with C<Markdown coverage: 0/1 (0.0%)>.

=cut
