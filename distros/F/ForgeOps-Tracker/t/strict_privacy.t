use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use JSON::PP;
use Time::HiRes ();
use lib "$Bin/../lib";
use ForgeOps::Tracker;
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::EventBuilder;
use ForgeOps::Tracker::PerformanceFlusher;
use ForgeOps::Tracker::StrictPrivacy qw(normalize_message message_fingerprint span_name transaction_name strict_path);

# A byte-identical copy of sdks/strict_privacy_vectors.json, generated from the server's own
# StrictPrivacy; every SDK checks itself against the same file.
my $vectors = do {
    open my $fh, '<:raw', "$Bin/fixtures/strict_privacy_vectors.json" or die "can't read vectors: $!";
    local $/;
    decode_json(<$fh>);
};

subtest 'normalizes and fingerprints every vector exactly as the server does' => sub {
    for my $vector (@{ $vectors->{fingerprint} }) {
        my $label = JSON::PP->new->ascii->allow_nonref->encode($vector->{message});
        is(normalize_message($vector->{message}), $vector->{normalized}, "normalized $label");
        is(message_fingerprint($vector->{message}), $vector->{fingerprint}, "fingerprint $label");
    }
};

subtest 'an absent message fingerprints as an empty one' => sub {
    is(message_fingerprint(undef), message_fingerprint(''));
};

subtest 'names every span vector exactly as the server does' => sub {
    is(span_name($_->{name}), $_->{strict}, $_->{name}) for @{ $vectors->{span_name} };
};

subtest 'reduces every path vector exactly as the server does' => sub {
    is(strict_path($_->{path}), $_->{strict}, $_->{path} eq '' ? '(empty)' : $_->{path}) for @{ $vectors->{path} };
};

subtest 'transaction_name keeps a route and cuts a raw path down to its first segment' => sub {
    is(transaction_name('GET /patients/:id'), 'GET /patients/:id');
    is(transaction_name('GET /patients/8821'), 'GET /patients/:path');
    is(transaction_name('MyApp::Patients::show'), 'MyApp::Patients::show');
    is(transaction_name(undef), undef);
};

subtest 'an event with strict privacy on cuts down a raw-path transaction_name' => sub {
    my $payload = ForgeOps::Tracker::StrictPrivacy::event({ message => 'boom', backtrace => [], transaction_name => 'GET /patients/8821' });

    is($payload->{transaction_name}, 'GET /patients/:path');
};

# Stands in for the Client: keeps every batch of performance samples flush() delivers.
package Fake::PerformanceClient {
    sub new { bless { delivered => [] }, shift }
    sub deliver_performance_samples { my ($self, $samples) = @_; push @{ $self->{delivered} }, @$samples; return 1 }
}

subtest 'performance samples cut down raw-path names only with strict privacy on' => sub {
    for my $strict (1, 0) {
        my $config = ForgeOps::Tracker::Configuration->new;
        $config->{dsn} = 'https://key@tracker.example.com/api/v1/events';
        $config->{enabled_environments} = { production => 1 };
        $config->{environment} = 'production';
        $config->{performance_flush_interval} = 600;
        $config->{strict_privacy} = $strict;
        my $client = Fake::PerformanceClient->new;
        my $flusher = ForgeOps::Tracker::PerformanceFlusher->new($config, $client);

        $flusher->record('GET /patients/8821', 5);
        $flusher->record('GET /patients/:id', 5);
        $flusher->flush;

        my @names = sort map { $_->{transaction_name} } @{ $client->{delivered} };
        is_deeply(\@names, $strict ? ['GET /patients/:id', 'GET /patients/:path'] : ['GET /patients/8821', 'GET /patients/:id'], $strict ? 'strict on' : 'strict off');
    }
};

subtest 'is off with no allowed fields by default' => sub {
    local $ENV{FORGE_OPS_STRICT_PRIVACY};
    local $ENV{FORGE_OPS_PRIVACY_ALLOWED_FIELDS};
    delete $ENV{FORGE_OPS_STRICT_PRIVACY};
    delete $ENV{FORGE_OPS_PRIVACY_ALLOWED_FIELDS};
    my $config = ForgeOps::Tracker::Configuration->new;

    ok(!$config->{strict_privacy});
    is_deeply($config->{privacy_allowed_fields}, []);
};

subtest 'reads both options from the environment' => sub {
    local $ENV{FORGE_OPS_STRICT_PRIVACY} = 'true';
    local $ENV{FORGE_OPS_PRIVACY_ALLOWED_FIELDS} = 'error_code, feature,';
    my $config = ForgeOps::Tracker::Configuration->new;

    is($config->{strict_privacy}, 1);
    is_deeply($config->{privacy_allowed_fields}, [qw(error_code feature)]);
};

subtest 'an explicit init option wins over the environment' => sub {
    local $ENV{FORGE_OPS_STRICT_PRIVACY} = 'true';
    local $ENV{FORGE_OPS_PRIVACY_ALLOWED_FIELDS} = 'error_code';
    ForgeOps::Tracker::_reset_for_testing();
    my $config = ForgeOps::Tracker::init(strict_privacy => 0, privacy_allowed_fields => ['feature'], detect_changes => 0);

    ok(!$config->{strict_privacy});
    is_deeply($config->{privacy_allowed_fields}, ['feature']);
    ForgeOps::Tracker::_reset_for_testing();
};

subtest 'anything but a true-like value is off' => sub {
    local $ENV{FORGE_OPS_STRICT_PRIVACY} = 'false';

    ok(!ForgeOps::Tracker::Configuration->new->{strict_privacy});
};

# Dies, from line 10 of a file under app_root, with a DBI-style error carrying its SQL.
sub die_from_source_file {
    my ($fh, $path) = tempfile('forge_ops_strict_XXXX', SUFFIX => '.pl', TMPDIR => 1, UNLINK => 1);
    my @lines = map { "# filler $_" } 1 .. 20;
    $lines[9] = q{die qq{DBD::Pg::st execute failed: Couldn't find Patient with id=8821 for jane\@example.com [for Statement "SELECT * FROM patients WHERE id = 8821"]};};
    print {$fh} join("\n", @lines), "\n";
    close $fh;
    do $path;
    return ($path, $@);
}

sub event_configuration {
    my ($path) = @_;
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{environment} = 'production';
    $config->{release} = 'abc123';
    $config->{server_name} = 'web-1';
    $config->{app_root} = dirname($path);
    $config->{capture_sql_statement} = 1;
    return $config;
}

sub build_event {
    my ($config, $error, $user) = @_;
    return ForgeOps::Tracker::EventBuilder->new($config)->build(
        $error,
        { error_code => 'E42', feature => { nested => 'no' }, diagnosis => 'flu', tier => 3 },
        $user || { id => 7, email => 'jane@example.com', username => 'jane' },
        [ { category => 'custom', message => "viewed Jane's chart", level => 'info', timestamp => 'now', data => {} } ],
        { transaction_name => 'GET /patients/:id', endpoint => 'GET /patients/8821', trace_id => 'a' x 32 },
    );
}

subtest 'an event with strict privacy on carries only structured facts' => sub {
    my ($path, $error) = die_from_source_file();
    my $config = event_configuration($path);
    $config->{strict_privacy} = 1;
    $config->{privacy_allowed_fields} = [qw(error_code feature tier)];

    my $payload = build_event($config, $error);

    is($payload->{message}, '');
    # From the message as it would otherwise have been sent: after PII scrubbing.
    is($payload->{message_fingerprint},
        message_fingerprint(q{DBD::Pg::st execute failed: Couldn't find Patient with id=8821 for [EMAIL FILTERED] [for Statement "SELECT * FROM patients WHERE id = 8821"]}));
    ok(!exists $payload->{$_}, "no $_") for qw(breadcrumbs endpoint sql_statement tags);
    is_deeply($payload->{context}, { error_code => 'E42', tier => 3 });
    is_deeply($payload->{user}, { id => '7' });
    is($payload->{backtrace}[0]{file}, $path);
    is($payload->{backtrace}[0]{line}, 10);
    ok($payload->{backtrace}[0]{in_app});
    for my $frame (@{ $payload->{backtrace} }) {
        ok(!exists $frame->{$_}, "no $_") for qw(context_line pre_context post_context);
    }
    is_deeply($payload->{sql_objects}{relations}, ['patients']);
    is($payload->{transaction_name}, 'GET /patients/:id');
    is($payload->{trace_id}, 'a' x 32);
    my $json = encode_json($payload);
    unlike($json, qr/$_/, "nothing mentions $_") for qw(jane 8821 flu);
};

subtest 'an event with strict privacy on and no allowed fields has no context at all' => sub {
    my ($path, $error) = die_from_source_file();
    my $config = event_configuration($path);
    $config->{strict_privacy} = 1;

    my $payload = build_event($config, $error);

    ok(!exists $payload->{context});
    ok(!exists $payload->{tags});
};

subtest 'an event with strict privacy on leaves out a user with no id' => sub {
    my ($path, $error) = die_from_source_file();
    my $config = event_configuration($path);
    $config->{strict_privacy} = 1;

    ok(!exists build_event($config, $error, { email => 'jane@example.com' })->{user});
};

subtest 'an event with strict privacy off is exactly as before' => sub {
    my ($path, $error) = die_from_source_file();
    my $config = event_configuration($path);

    my $payload = build_event($config, $error);

    like($payload->{message}, qr/\Q[EMAIL FILTERED]\E/);
    ok(!exists $payload->{message_fingerprint});
    is($payload->{breadcrumbs}[0]{message}, "viewed Jane's chart");
    is($payload->{endpoint}, 'GET /patients/8821');
    is($payload->{sql_statement}, 'SELECT * FROM patients WHERE id = ?');
    is_deeply($payload->{context}, { error_code => 'E42', feature => { nested => 'no' }, diagnosis => 'flu', tier => 3 });
    is_deeply($payload->{user}, { id => 7, email => 'jane@example.com', username => 'jane' });
    is_deeply($payload->{tags}, {});
    ok(exists $payload->{backtrace}[0]{context_line});
};

subtest 'breadcrumbs are never recorded with strict privacy on' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(strict_privacy => 1, detect_changes => 0);

    ForgeOps::Tracker::add_breadcrumb("viewed Jane's chart");

    is_deeply(\@ForgeOps::Tracker::current_breadcrumbs, []);
    ForgeOps::Tracker::_reset_for_testing();
};

# Stands in for the DeliveryQueue: records every trace pushed instead of delivering it.
package Fake::Queue {
    sub new { bless { pushed => [] }, shift }
    sub push { my ($self, $trace) = @_; push @{ $self->{pushed} }, $trace; return 1 }
}

sub delivered_spans {
    my (%overrides) = @_;
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                     => 'https://key@tracker.example.com/api/v1/events',
        environment             => 'production',
        enabled_environments    => { production => 1 },
        trace_capture_threshold => 0,
        detect_changes          => 0,
        %overrides,
    );
    my $queue = Fake::Queue->new;
    no warnings 'redefine';
    local *ForgeOps::Tracker::_span_queue = sub { $queue };

    my $now = Time::HiRes::time;
    ForgeOps::Tracker::start_trace();
    ForgeOps::Tracker::record_span('GET https://api.example.com/patients/42?x=1', 'http', $now, 3, { status => 200 });
    ForgeOps::Tracker::record_database_span('SELECT patients', 'SELECT * FROM patients WHERE id = 8821', $now, 2, db_system => 'postgresql');
    ForgeOps::Tracker::finish_trace('GET /patients/8821', $now, 10);
    ForgeOps::Tracker::_reset_for_testing();

    return { map { $_->{kind} => $_ } @{ $queue->{pushed}[0]{spans} } };
}

subtest 'spans with strict privacy on name calls by host and keep only statement data' => sub {
    my $spans = delivered_spans(strict_privacy => 1);

    is($spans->{http}{name}, 'GET api.example.com');
    ok(!exists $spans->{http}{data});
    is_deeply($spans->{database}{data}, { 'db.statement' => 'SELECT * FROM patients WHERE id = ?', 'db.system' => 'postgresql' });
    is($spans->{controller}{name}, 'GET /patients/:path');
    ok(!exists $spans->{controller}{data});
};

subtest 'spans with strict privacy off are exactly as before' => sub {
    my $spans = delivered_spans();

    is($spans->{http}{name}, 'GET https://api.example.com/patients/42?x=1');
    is_deeply($spans->{http}{data}, { status => 200 });
    is($spans->{controller}{name}, 'GET /patients/8821');
    is_deeply($spans->{controller}{data}, {});
};

done_testing;
