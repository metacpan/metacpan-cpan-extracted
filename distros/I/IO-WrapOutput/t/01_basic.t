use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all => 'Fails due to a newline/pipe issue I think';
    }
    else {
        plan tests => 3;
        use_ok('IO::WrapOutput');
    }
}

# 2-arg open() here because Perl 5.6 doesn't understand the '>&' mode
# with a 3-arg open
open my $orig_stdout, '>&'.fileno(STDOUT) or BAIL_OUT("Can't dup STDOUT: $!");
open my $orig_stderr, '>&'.fileno(STDERR) or BAIL_OUT("Can't dup STDERR: $!");

$SIG{ALRM} = sub { die "Timed out\n" };
alarm 5;

my ($new_stdout, $new_stderr) = eval { wrap_output() };
chomp $@;
fail("wrap_output() failed: $@") if $@;

print "Test out\n";
warn "Test err\n";
my $new_out = readline($new_stdout);
my $new_err = readline($new_stderr);

eval { unwrap_output() };
chomp $@;
fail("unwrap_output() failed $@") if $@;
alarm 0;

is($new_out, "Test out\n", 'Got piped STDOUT');
is($new_err, "Test err\n", 'Got piped STDERR');
