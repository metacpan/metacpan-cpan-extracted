#!/usr/bin/perl

use strict;
use warnings;

use t::tfiles;

use Test::More 0.95;
use Test::Fatal;

use lib 'lib';

use IPC::System::Simple;
use autodie qw(system);
use Hash::Persistent;

# saving state (2)
subtest 'saving state' => sub {
    plan tests => 2;

    my $state = Hash::Persistent->new('tfiles/state');
    $state->{a} = 5;
    $state->{b} = {c => 6};
    $state->commit;
    undef $state;
    $state = Hash::Persistent->new('tfiles/state');
    is $state->{a}, 5, 'a key saved';
    is $state->{b}{c}, 6, 'b->c key saved';
};

subtest 'auto_commit' => sub {
    plan tests => 1;

    my $state = Hash::Persistent->new('tfiles/state', { auto_commit => 0 });
    $state->{a} = 0;
    undef $state;
    $state = Hash::Persistent->new('tfiles/state');
    is $state->{a}, 5, "commit didn't happen";
};

subtest 'keys' => sub {
    plan tests => 1;

    my $state = Hash::Persistent->new('tfiles/state');
    my @keys = sort keys %$state;
    is(($keys[0] eq 'a') && ($keys[1] eq 'b'), 1, "key names OK");
};

subtest 'mode' => sub {
    plan tests => 1;

    my $state = Hash::Persistent->new('tfiles/state', {mode => 0765});
    $state->commit;
    undef $state;

    my $mode = (stat('tfiles/state'))[2];
    is($mode & 07777, 0765, "mode set right");
};

subtest 'read_only' => sub {
    plan tests => 5;

    like(
        exception {
            my $state = Hash::Persistent->new('tfiles/state', { read_only => 1, auto_commit => 1 });
        },
        qr/Only one of .* options can be true/,
        'read_only incompatible with auto_commit'
    );
    is(
        exception {
            my $state = Hash::Persistent->new('tfiles/state', { read_only => 1, auto_commit => 0 });
        },
        undef,
        'read_only lives when auto_commit is 0'
    );
    is(
        exception {
            my $state = Hash::Persistent->new('tfiles/state', { read_only => 1 });
        },
        undef,
        'read_only lives when auto_commit is not specified'
    );

    my $state = Hash::Persistent->new('tfiles/state', { read_only => 1 });
    like(
        exception { $state->commit },
        qr/read only/,
        "read_only objects can't be commited"
    );

    undef $state;
    $state = Hash::Persistent->new('tfiles/state', { read_only => 1 });
    $state->{c} = 5;
    undef $state;
    $state = Hash::Persistent->new('tfiles/state', { read_only => 1 });
    is($state->{c}, undef, 'read_only turns auto_commit off');
};

subtest 'write_only' => sub {
    plan tests => 8;

    system("rm tfiles/state");

    my $state;
    is
        exception { $state = Hash::Persistent->new('tfiles/state', { write_only => 1, auto_commit => 0}) },
        undef,
        "no file";
    is scalar(keys %$state), 0, "no data";

    $state->{a} = "b";
    $state->commit; undef $state;
    is
        exception { $state = Hash::Persistent->new('tfiles/state', { write_only => 1, auto_commit => 0}) },
        undef,
        "write_only";
    is scalar(keys %$state), 0, "no data";

    $state->commit; undef $state;
    system('echo "{" > tfiles/state');
    is
        exception { $state = Hash::Persistent->new('tfiles/state', { write_only => 1, format => "json", auto_commit => 0}) },
        undef,
        "corrupt file";
    is scalar(keys %$state), 0, "no data";

    $state->commit; undef $state;
    system('echo -n > tfiles/state');
    is
        exception { $state = Hash::Persistent->new('tfiles/state', { write_only => 1, format => "json", auto_commit => 0}) },
        undef,
        "empty file";
    is scalar(keys %$state), 0, "no data";
    $state->commit; undef $state;
};

subtest 'lock' => sub {
    plan tests => 2;

    unless (fork) {
        my $state = Hash::Persistent->new('tfiles/state', { lock => { shared => 1} });
        sleep 2;
        exec('true');
    }
    sleep 1;
    is(Hash::Persistent->new('tfiles/state', { lock => { blocking => 0 } }), undef, "two persistents can't exist together");
    is(
        exception {
            Hash::Persistent->new('tfiles/state', { lock => { blocking => 0, shared => 1 } });
        },
        undef,
        "two shared persistents can exist together"
    );
};

subtest 'terse mode in Dumper' => sub {
    plan tests => 2;

    use Data::Dumper;
    $Data::Dumper::Terse = 1;

    my $state = Hash::Persistent->new('tfiles/terse');
    $state->{a} = 'b';
    $state->commit;
    undef $state;
    is(
        exception { $state = Hash::Persistent->new('tfiles/terse') },
        undef,
        'save/load works when terse mode is enabled in Data::Dumper globally'
    );
    is($state->{a}, 'b', 'data is correct when loading with Terse enabled');
};

subtest 'diamond references in dumper and storable formats' => sub {
    plan tests => 2;

    for my $format (qw/ dumper storable /) {
        my $state_code = sub { Hash::Persistent->new('tfiles/selfref', { format => $format }) };
        my $state = $state_code->();
        my $x = ['abc'];
        $state->{a} = [ $x, $x ];
        $state->commit;
        undef $state;

        $state = $state_code->();
        is($state->{a}[0], $state->{a}[1], "diamond refs are equal in format $format");
    }
};

subtest 'remove method' => sub {
    plan tests => 3;

    my $state = Hash::Persistent->new('tfiles/tbd');
    $state->{a} = 'b';
    $state->commit;
    ok(-e 'tfiles/tbd', 'file exists');
    $state->remove;
    ok(not(-e 'tfiles/tbd'), 'file removed');

    is_deeply {%$state}, {}, 'in-memory object is cleared too';
};

subtest 'remove method without commit' => sub {
    my $state = Hash::Persistent->new('tfiles/tbd');
    is(exception { $state->remove }, undef, 'remove does nothing if there is no file');
};

done_testing;
