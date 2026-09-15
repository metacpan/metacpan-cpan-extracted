use strict;
use warnings;
use Test::More;
use Carp qw(confess);
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use lib "$Bin/../lib";
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::EventBuilder;

sub new_configuration {
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{environment} = 'production';
    $config->{release} = 'abc123';
    $config->{server_name} = 'web-1';
    return $config;
}

subtest 'builds a payload with exception class, message, and configured metadata from a plain die' => sub {
    my $builder = ForgeOps::Tracker::EventBuilder->new(new_configuration());
    eval { die "boom" };
    my $payload = $builder->build($@, { url => 'https://example.com' });

    is($payload->{exception_class}, 'RuntimeError');
    is($payload->{message}, 'boom');
    is($payload->{environment}, 'production');
    is($payload->{release}, 'abc123');
    is($payload->{server_name}, 'web-1');
    is_deeply($payload->{context}, { url => 'https://example.com' });
    like($payload->{occurred_at}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);
    is($payload->{sdk_name}, 'perl');
};

subtest 'parses the file/line Perl itself appends to a plain die' => sub {
    my $builder = ForgeOps::Tracker::EventBuilder->new(new_configuration());
    eval { die "boom" };
    my $line_of_die = __LINE__ - 1;
    my $frames = $builder->build($@)->{backtrace};

    ok(scalar(@$frames) >= 1);
    is($frames->[0]{file}, __FILE__);
    is($frames->[0]{line}, $line_of_die);
};

subtest 'parses a full Carp::confess call chain into multiple frames' => sub {
    my $builder = ForgeOps::Tracker::EventBuilder->new(new_configuration());

    my $error = do {
        local $@;
        eval { inner_confess() };
        $@;
    };
    my $frames = $builder->build($error)->{backtrace};

    ok(scalar(@$frames) >= 2, 'has at least the confess-site frame and one caller frame');
    ok((grep { defined $_->{method} && $_->{method} =~ /inner_confess/ } @$frames), 'a frame names inner_confess as the calling sub');
};

sub inner_confess { confess('deep failure') }

subtest 'marks a frame under app_root as in_app' => sub {
    my $config = new_configuration();
    eval { die 'boom' };
    my $error = $@;

    # die's auto-appended file location can come back either absolute or relative to the cwd
    # `prove` was invoked from: confirmed directly (it's relative here, not $Bin, when run via
    # `prove`), so app_root is derived from a real captured frame's own file value rather than
    # assumed to be $Bin (an absolute path FindBin computes independently of how die reports it).
    my $probe = ForgeOps::Tracker::EventBuilder->new($config)->build($error)->{backtrace};
    my ($observed_dir) = $probe->[0]{file} =~ m{^(.*)/[^/]+$};
    ok(defined $observed_dir, 'captured a real frame to derive app_root from') or return;

    $config->{app_root} = $observed_dir;
    my $frames = ForgeOps::Tracker::EventBuilder->new($config)->build($error)->{backtrace};

    ok((grep { $_->{in_app} } @$frames));
};

subtest 'marks every frame as not in_app when app_root does not match' => sub {
    my $config = new_configuration();
    $config->{app_root} = '/definitely/not/here';
    eval { die 'boom' };
    my $frames = ForgeOps::Tracker::EventBuilder->new($config)->build($@)->{backtrace};

    ok(!(grep { $_->{in_app} } @$frames));
};

subtest 'scrubs likely PII out of the message and context by default' => sub {
    my $builder = ForgeOps::Tracker::EventBuilder->new(new_configuration());
    eval { die 'failed for user@example.com' };
    my $payload = $builder->build($@, { user => { email => 'ada@example.com', password => 'hunter2' } });

    is($payload->{message}, 'failed for [EMAIL FILTERED]');
    is_deeply($payload->{context}, { user => { email => '[EMAIL FILTERED]', password => '[FILTERED]' } });
};

subtest 'leaves the payload untouched when scrub_pii is disabled' => sub {
    my $config = new_configuration();
    $config->{scrub_pii} = 0;
    my $builder = ForgeOps::Tracker::EventBuilder->new($config);
    eval { die 'failed for user@example.com' };
    my $payload = $builder->build($@, { email => 'ada@example.com' });

    is($payload->{message}, 'failed for user@example.com');
    is_deeply($payload->{context}, { email => 'ada@example.com' });
};

# --- Source context capture -------------------------------------------------

# Writes a small, real Perl fixture file where line $die_at_line is a `die "boom";` statement and
# every other line is an inert comment: so `do`-ing it produces a real error with Perl's own
# auto-appended "at FILE line N." pointing at that exact line, with real, known content
# surrounding it to assert against. The placeholder text is "filler N", not "line N": a comment of
# the literal form "# line N" is a real Perl directive (like C's #line) that resets the line
# number the parser reports from that point on, which would silently break every line number this
# fixture is trying to pin down.
sub write_source_file {
    my ($line_count, $die_at_line) = @_;
    my @lines = map { $_ == $die_at_line ? 'die "boom";' : "# filler $_" } (1 .. $line_count);
    my ($fh, $path) = tempfile(SUFFIX => '.pl', UNLINK => 0);
    print $fh join("\n", @lines), "\n";
    close $fh;
    return ($path, \@lines);
}

sub die_and_capture {
    my ($path) = @_;
    local $@;
    do $path;
    return $@;
}

# Builds a frame for $error under $config, deriving app_root from the error's own observed frame
# file rather than assuming it matches the path used to write the fixture: the same defensive
# approach the "marks a frame under app_root as in_app" subtest above uses, since a fixture path
# built from a temp-dir helper isn't guaranteed to come back byte-identical in a real backtrace.
sub frame_for {
    my ($config, $error) = @_;
    my $probe = ForgeOps::Tracker::EventBuilder->new(ForgeOps::Tracker::Configuration->new)->build($error)->{backtrace};
    my ($observed_dir) = $probe->[0]{file} =~ m{^(.*)/[^/]+$};
    $config->{app_root} = $observed_dir;
    return ForgeOps::Tracker::EventBuilder->new($config)->build($error)->{backtrace}[0];
}

subtest 'attaches pre_context/context_line/post_context around an in_app frame\'s culprit line, by default' => sub {
    my ($path, $lines) = write_source_file(20, 10);
    my $config = new_configuration();
    my $error = die_and_capture($path);

    my $frame = frame_for($config, $error);

    is($frame->{context_line}, $lines->[9]);
    is_deeply($frame->{pre_context}, [ @{$lines}[4 .. 8] ]);
    is_deeply($frame->{post_context}, [ @{$lines}[10 .. 14] ]);
    unlink $path;
};

subtest 'scrubs likely PII out of captured source context too, by default' => sub {
    my ($path, $lines) = write_source_file(3, 2);
    my $config = new_configuration();
    my $error = die_and_capture($path);
    $lines->[0] = '# contact user@example.com';
    open(my $fh, '>', $path) or die $!;
    print $fh join("\n", @$lines), "\n";
    close $fh;

    my $frame = frame_for($config, $error);

    is($frame->{pre_context}[0], '# contact [EMAIL FILTERED]');
    unlink $path;
};

subtest 'clamps pre_context/post_context at the start and end of the file rather than dying' => sub {
    my ($first_path, $first_lines) = write_source_file(3, 1);
    my ($last_path, $last_lines) = write_source_file(3, 3);
    my $config = new_configuration();

    my $first_frame = frame_for($config, die_and_capture($first_path));
    my $last_frame = frame_for(new_configuration(), die_and_capture($last_path));

    is_deeply($first_frame->{pre_context}, []);
    is_deeply($first_frame->{post_context}, [ @{$first_lines}[1 .. 2] ]);
    is_deeply($last_frame->{pre_context}, [ @{$last_lines}[0 .. 1] ]);
    is_deeply($last_frame->{post_context}, []);
    unlink $first_path;
    unlink $last_path;
};

subtest 'truncates an individual line longer than MAX_CONTEXT_LINE_LENGTH' => sub {
    my $overlong = 'die "boom"; # ' . ('x' x 600);
    my ($fh, $path) = tempfile(SUFFIX => '.pl', UNLINK => 0);
    print $fh "$overlong\n";
    close $fh;
    my $config = new_configuration();

    my $frame = frame_for($config, die_and_capture($path));

    is($frame->{context_line}, substr($overlong, 0, 500) . '...');
    unlink $path;
};

subtest 'never attaches context to a frame outside app_root' => sub {
    my ($path, $lines) = write_source_file(20, 10);
    my $config = new_configuration();
    $config->{app_root} = '/definitely/not/here';
    my $error = die_and_capture($path);

    my $frame = ForgeOps::Tracker::EventBuilder->new($config)->build($error)->{backtrace}[0];

    ok(!exists $frame->{context_line});
    ok(!exists $frame->{pre_context});
    ok(!exists $frame->{post_context});
    unlink $path;
};

subtest 'leaves a frame untouched, with no file read attempted, when capture_source_context is disabled' => sub {
    my ($path, $lines) = write_source_file(20, 10);
    my $config = new_configuration();
    my $error = die_and_capture($path);
    my $probe = ForgeOps::Tracker::EventBuilder->new(ForgeOps::Tracker::Configuration->new)->build($error)->{backtrace};
    my ($observed_dir) = $probe->[0]{file} =~ m{^(.*)/[^/]+$};
    $config->{app_root} = $observed_dir;
    $config->{capture_source_context} = 0;

    my $read_calls = 0;
    no warnings 'redefine';
    local *ForgeOps::Tracker::EventBuilder::_read_source_lines = sub { $read_calls++; return undef; };
    use warnings 'redefine';

    my $frame = ForgeOps::Tracker::EventBuilder->new($config)->build($error)->{backtrace}[0];

    is($read_calls, 0);
    ok(!exists $frame->{context_line});
    unlink $path;
};

subtest 'leaves a frame untouched when the recorded file can\'t be read' => sub {
    my ($path, $lines) = write_source_file(20, 10);
    my $config = new_configuration();
    my $error = die_and_capture($path);
    my $probe = ForgeOps::Tracker::EventBuilder->new(ForgeOps::Tracker::Configuration->new)->build($error)->{backtrace};
    my ($observed_dir) = $probe->[0]{file} =~ m{^(.*)/[^/]+$};
    $config->{app_root} = $observed_dir;
    unlink $path; # gone by the time EventBuilder tries to open it

    my $frame = ForgeOps::Tracker::EventBuilder->new($config)->build($error)->{backtrace}[0];

    ok(!exists $frame->{context_line});
};

done_testing;
