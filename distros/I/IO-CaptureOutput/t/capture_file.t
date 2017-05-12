use strict;
use Test::More; 
use IO::CaptureOutput qw/capture/;
use File::Temp qw/tempfile/;
use Config;

plan tests => 30;

my ($out, $err);
sub _reset { $_ = '' for ($out, $err); 1};
sub _readf { 
    return undef unless -r "$_[0]"; 
    local $/; open FF, "< $_[0]"; my $c = <FF>; close FF; 
    return $c 
}
sub _touch { open FF, "> $_[0]"; close FF }

# save output to specified files
(undef, my $saved_out) = tempfile; unlink $saved_out;
(undef, my $saved_err) = tempfile; unlink $saved_err;

_reset && capture sub {print __PACKAGE__; print STDERR __FILE__}, 
    \$out, \$err, $saved_out, $saved_err;
is($out, __PACKAGE__, 'save both: captured stdout from perl function 2');
is($err, __FILE__, 'save both: captured stderr from perl function 2');
ok(-s $saved_out, "save both: saved stdout file contains something");
ok(-s $saved_err, "save both: saved stderr file contains something");
is(_readf($saved_out), __PACKAGE__, 'saved both: saved stdout file content ok');
is(_readf($saved_err), __FILE__, 'saved both: saved stderr file content ok');

# confirm that files are clobbered
_reset && capture sub {print __PACKAGE__; print STDERR __FILE__}, 
    \$out, \$err, $saved_out, $saved_err;
ok(-s $saved_out, "clobber: saved stdout file contains something");
ok(-s $saved_err, "clobber: saved stderr file contains something");
is(_readf($saved_out), __PACKAGE__, 'clobber: stdout file correct');
is(_readf($saved_err), __FILE__, 'clobber: stderr correct:');

# save only stderr
unlink $saved_out, $saved_err;
_reset && capture sub {print __PACKAGE__; print STDERR __FILE__}, 
    \$out, \$err, undef, $saved_err;
ok(!-e $saved_out, "only stderr: stdout file does not exist");
ok(-s $saved_err, "only stderr: file contains something");
is(_readf($saved_err), __FILE__, 'only stdout: stderr file');

# check that the merged stdout and stderr are saved where they should
unlink $saved_out, $saved_err;
_reset && capture sub {print __FILE__; print STDERR __PACKAGE__}, 
    \$out, \$out, $saved_out;
like($out, q{/^} . quotemeta(__FILE__) . q{/}, 'merge: captured stdout into one scalar 2');
like($out, q{/} . quotemeta(__PACKAGE__) . q{/}, 'merge: captured stderr into same scalar 2');
ok(-s $saved_out, "merge: saved stdout file contains something");
like(_readf($saved_out), q{/^} . quotemeta(__FILE__) . q{/}, 'merge: saved merged file stdout content ok');
like(_readf($saved_out), q{/} . quotemeta(__PACKAGE__) . q{/}, 'merge: saved merged file stderr content ok');

# capture only stdout to a file
unlink $saved_out, $saved_err;
_reset && capture sub {print __FILE__; print STDERR __PACKAGE__}, 
    \$out, undef, $saved_out;
ok(-s $saved_out, "fileonly stdout: saved stdout file contains something");
ok(!-e $saved_err, "fileonly stdout: saved stderr file does not exist");
like(_readf($saved_out), q{/^} . quotemeta(__FILE__) . q{/}, 'fileonly stdout: saved merged file stdout content ok');

# capture only stderr to a file
unlink $saved_out, $saved_err;
_reset && capture sub {print __FILE__; print STDERR __PACKAGE__}, 
    undef, \$err, undef, $saved_err;
ok(!-e $saved_out, "fileonly stderr: saved stdout file does not exist");
ok(-s $saved_err, "fileonly stderr: saved stderr file contains something");
like(_readf($saved_err), q{/} . quotemeta(__PACKAGE__) . q{/}, 'fileonly stderr: undef, undef file stderr content ok');

# don't capture merged to scalar, only to file
unlink $saved_out, $saved_err;
_reset && capture sub {print __FILE__; print STDERR __PACKAGE__}, 
    undef, undef, $saved_out;
ok(-s $saved_out, "fileonly merge: saved stdout file contains something");
ok(!-e $saved_err, "fileonly merge: saved stderr file does not exist");
like(_readf($saved_out), q{/^} . quotemeta(__FILE__) . q{/}, 'fileonly merge: file stdout content ok');
like(_readf($saved_out), q{/} . quotemeta(__PACKAGE__) . q{/}, 'fileonly merge: file stderr content ok');

# confirm error handling on read-only files
_touch($_) for ($saved_out, $saved_err);

chmod 0444, $saved_out, $saved_err;

SKIP: {
    skip "Can't make temp files read-only to test error handling", 2
        if ( -w $saved_out || -w $saved_err );

    eval { capture sub {print __FILE__; print STDERR __PACKAGE__}, 
        \$out, \$err, $saved_out
    };
    like( $@, q{/Can't write temp file for main::STDOUT/},
        "error handling: can't write to stdout file"
    );

    eval { capture sub {print __FILE__; print STDERR __PACKAGE__}, 
        \$out, \$err, undef, $saved_err
    };
    like( $@, q{/Can't write temp file for main::STDERR/},
        "error handling: can't write to stderr file"
    );
}

# restore permissions
chmod 0666, $saved_out, $saved_err;
unlink $saved_out, $saved_err;


