{
    sub _safe_eval { eval "$_[0]" }
}

use strict;
use warnings;

use Test::More;

compile_ok('script/perl-info');
compile_ok('lib/Gentoo/App/PerlInfo.pm');

sub compile_ok {
    my ($filename) = @_;
    open my $fh, '<', $filename or die "Cannot open $filename, $!";
    my $magic_number = scalar time();
    my $magic_phrase = qq[Compile OK:$magic_number];
    my $code         = qq[UNITCHECK { die "$magic_phrase"; }\n];
    $code .= qq[#line 1 "$filename"\n];
    $code .= do { local $/ = undef; scalar <$fh> };
    close $fh or warn "Error closing $filename, $!";
    my $pid = fork;

    if ($pid) {
        local $?;
        waitpid $pid, 0;
        my $exit   = $? >> 8;
        my $signal = $? & 127;
        if ( $exit == 42 ) {
            diag("Internal die() for compile_ok($filename) was not called");
            return fail("compile_ok($filename) - internal die called");
        }
        if ( $exit == 43 ) {
            diag(
"die() reason for compile_ok($filename) was not the magic phrase >$magic_phrase"
            );
            return fail(
                "compile_ok($filename) - internal die has magic phrase");
        }
        pass("compile_ok($filename)");
        return;
    }
    local $@;
    if ( _safe_eval($code) ) {
        exit 42;
    }
    if ( $@ !~ /\Q$magic_phrase\E/ ) {
        diag("die reason:");
        diag("$@");
        exit 43;
    }
    exit 0;
}

done_testing;

