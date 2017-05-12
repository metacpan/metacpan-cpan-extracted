# IO::Callback 1.08 t/examples-from-pod.t
# Check that the examples in the POD work as described

use strict;
use warnings;

use IO::Callback;
our $pm_fh;

use Test::More;
BEGIN {
    eval 'use Pod::Snippets';
    plan skip_all => 'Pod::Snippets required' if $@;

    my $pm_file = $INC{'IO/Callback.pm'};
    unless ($pm_file and open $pm_fh, "<", $pm_file) {
        plan skip_all => 'Unable to open my own .pm file';
    }
}
use Test::NoWarnings;

my $snips = load Pod::Snippets($pm_fh, 
    -markup         => 'test',
    -named_snippets => "strict",
);

# Some fake objects
our $fake_dbh_cycle = 0;
my $dbh = bless {}, 'IO::Callback::Fake';
my $ex5_had_lastblock = 0;
my $ex5_data = '';
my $ex5_expect = "qwerty7890" x 150;
my $thing = $dbh;

# Some of the examples are missing code to access the fh and
# assertions about the results.  Add that here.
my %extra_code = (
    ex3 => <<'EOF',
        my $x; read $fh, $x, 1000; # $x now contains "foo,bar,baz\n0\n0,1\n"
EOF
    ex4 => <<'EOF',
        my $died;
        eval { print $fh "02840284203842038420384\n" }; $died = $@ ? 1 : 0; # $died now contains 0
        eval { print $fh "02840284203842038fg42038f" }; $died = $@ ? 1 : 0; # $died now contains 0
        eval { print $fh "o"                         }; $died = $@ ? 1 : 0; # $died now contains 0
        eval { print $fh "o284028420384203842038f\n" }; $died = $@ ? 1 : 0; # $died now contains 1
EOF
    ex5 => <<'EOF',
        my $x = $ex5_data; # $x now contains $ex5_expect
EOF
    ex6 => <<'EOF',
        my $died;
        eval { my $x = read $fh, $_, 1000;      defined $x or die "read: $!" }; $died = $@ ? 1 : 0; # $died now contains 0
        eval { my $x = read $fh, $_, 1_000_000; defined $x or die "read: $!" }; $died = $@ ? 1 : 0; # $died now contains 1
EOF
    ex7 => <<'EOF',
        my $died;
        my $block1 = "x" x 1000;
        my $block2 = "x" x 1_000_000;
        eval { print $fh $block1 or die "write: $!" }; $died = $@ ? 1 : 0; # $died now contains 0
        eval { print $fh $block2 or die "write: $!" }; $died = $@ ? 1 : 0; # $died now contains 1
EOF
);

my @test_name = qw/ex1 ex2 ex2a ex3 ex4 ex5 ex6 ex7/;
my @test_code;
my $test_count = @test_name;
my %skip_example;
my %example_needs = (
    ex4 => 'use Digest::SHA',
    ex6 => 'use Errno qw/EIO/',
    ex7 => 'use Errno qw/ENOSPC/',
);
foreach my $test (@test_name) {
    my $code_snippet = $snips->named($test)->as_data;
    $code_snippet or die "failed to extract $test from pod";
    if ($example_needs{$test}) {
        eval $example_needs{$test};
        if ($@) {
            $skip_example{$test} = 1;
            push @test_code, '';
          next;
        }
    }
    if ($test eq "ex4") {
        $code_snippet = "use Digest::SHA;\n$code_snippet";
    }
    $code_snippet .= "\n" . ($extra_code{$test}||'');
    push @test_code, snippet_to_testcode($test, $code_snippet, \$test_count);
}

plan tests => $test_count + 1;

foreach my $i (0 .. $#test_name) {
    SKIP: {
        skip "can't $example_needs{$test_name[$i]}]", 1 if $skip_example{$test_name[$i]};

        eval $test_code[$i];
        my $err = $@ || '';
        is( $err, '', "$test_name[$i] ran" );
    };
}

sub snippet_to_testcode {
    my ($name, $code, $count_ref) = @_;

    ++$$count_ref while $code =~ s/^\s*(.+?);\s*#\s*(.+?) now contains (.+?)\s*$/ $1 ; is_deeply([$2], [$3], q{$name $1 => $3});\n/m;
    $code =~ /now contains/i and die "failed to munge a 'now contains' in $name: $code";
    return $code;
}

sub IO::Callback::Fake::prepare {
    my $self = shift;

    return $self;
}

sub IO::Callback::Fake::execute {
    if (@_ == 2) {
        # Example 5, storing stuff in a dbh.
        if (length $_[1] != 1024) {
            $ex5_had_lastblock++ and die "multiple runt blocks";
        }
        $ex5_data .= $_[1];
    }
}

sub IO::Callback::Fake::fetchrow_array {
    my $place = $fake_dbh_cycle++;
    $fake_dbh_cycle %= 4;
    if ($place == 0) {
        return qw/foo bar baz/;
    } elsif ($place == 1) {
        return qw/0/;
    } elsif ($place == 2) {
        return qw/0 1/;
    } else {
        return;
    }
}

# for example 4
sub store_fh {
    my $fh = shift;

    my ($buf, $got);
    do {
        $got = read $fh, $buf, 11;
        defined $got or die "read failed in ex4: $!";
    } while $got;
}

# for example 5
sub IO::Callback::Fake::copy_data_out {
    my ($self, $fh) = @_;

    for (1 .. 10) {
        print $fh "qwerty7890" x 15;
    }
    close $fh;
}

