#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

# Check if the exit code of Doit one-liners and scripts is as
# expected.

use Doit;
use Doit::Util 'new_scope_cleanup';
use File::Temp 'tempfile';
use Test::More 'no_plan';

sub with_tempfile (&;@);

my $doit = Doit->init;

{
    $doit->system($^X, '-MDoit', '-e', q{Doit->init->system($^X, '-e', 'exit 0')});
    pass 'passing Doit one-liner';
}

{
    eval { $doit->system($^X, '-MDoit', '-e', q{Doit->init->system($^X, '-e', 'exit 1')}) };
    is $@->{exitcode}, 1, 'failing Doit one-liner';
}

with_tempfile {
    my($tmpfh,$tmpfile) = @_;
    print $tmpfh <<'EOF';
use Doit;
Doit->init->system($^X, '-e', 'exit 0');
EOF
    close $tmpfh or die $!;
    $doit->chmod(0755, $tmpfile);
    $doit->system($^X, $tmpfile);
    pass 'passing Doit script';
} SUFFIX => '_doit.pl';

with_tempfile {
    my($tmpfh,$tmpfile) = @_;
    print $tmpfh <<'EOF';
use Doit;
Doit->init->system($^X, '-e', 'exit 1');
EOF
    close $tmpfh or die $!;
    $doit->chmod(0755, $tmpfile);
    eval { $doit->system($^X, $tmpfile) };
    is $@->{exitcode}, 1, 'failing Doit script';
} SUFFIX => '_doit.pl';

sub with_tempfile (&;@) {
    my($code, @opts) = @_;
    my($tmpfh,$tmpfile) = File::Temp::tempfile(@opts);
    my $sc = new_scope_cleanup { unlink $tmpfile };
    $code->($tmpfh,$tmpfile);
}

__END__
