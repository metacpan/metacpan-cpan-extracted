#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.95;
use Test::Fatal;

use t::tfiles;

use lib 'lib';
use Hash::Persistent;

sub file {
    return scalar qx(cat tfiles/state);
}

subtest 'default format' => sub {
    plan tests => 1;
    my $s = Hash::Persistent->new('tfiles/state');
    $s->{a} = 5;
    $s->commit;
    undef $s;
    is scalar(qx(cat tfiles/state)), '{"a":5}', 'JSON is default format';
};

subtest 'custom format' => sub {
    plan tests => 2;

    unlink 'tfiles/state';
    my $s = Hash::Persistent->new('tfiles/state', {format => 'dumper'});
    $s->{a} = 5;
    $s->commit;
    undef $s;
    like file(), qr/'a' => 5/, 'Data::Dumper format';

    unlink 'tfiles/state';
    $s = Hash::Persistent->new('tfiles/state', {format => 'storable'});
    $s->{a} = 5;
    $s->commit;
    undef $s;
    is length(file()), 14, 'Storable format';
};

subtest 'using previous format for existing files by default' => sub {
    plan tests => 2;

    unlink 'tfiles/state';
    my $s = Hash::Persistent->new('tfiles/state', {format => 'dumper'});
    $s->{a} = 5;
    $s->commit;
    undef $s;
    $s = Hash::Persistent->new('tfiles/state');
    $s->commit;
    undef $s;
    like file(), qr/ => /, 'Data::Dumper chosen as format';

    unlink 'tfiles/state';
    $s = Hash::Persistent->new('tfiles/state', {format => 'storable'});
    $s->{a} = 5;
    $s->commit;
    undef $s;
    $s = Hash::Persistent->new('tfiles/state');
    $s->commit;
    undef $s;
    is length(file()), 14, 'Storable chosen as format';
};

subtest 'recoding when format was specified' => sub {
    plan tests => 4;

    unlink 'tfiles/state';
    my $s = Hash::Persistent->new('tfiles/state', {format => 'dumper'});
    $s->{a} = 5;
    $s->commit;
    undef $s;

    $s = Hash::Persistent->new('tfiles/state', {format => 'storable'});
    $s->commit;
    undef $s;

    is length file(), 14, 'Recoding from Dumper into Storable';
    $s = Hash::Persistent->new('tfiles/state');
    is $s->{a}, 5, 'values recoded correctly';
    $s->commit;
    undef $s;

    unlink 'tfiles/state';
    $s = Hash::Persistent->new('tfiles/state', {format => 'storable'});
    $s->{a} = 5;
    $s->commit;
    undef $s;

    $s = Hash::Persistent->new('tfiles/state', {format => 'dumper'});
    $s->commit;
    undef $s;
    like file(), qr/ => /, 'Recoding from Storable into Dumper';
    $s = Hash::Persistent->new('tfiles/state');
    is $s->{a}, 5, 'values recoded correctly';
};

subtest 'json format' => sub {
    plan tests => 2;

    unlink 'tfiles/state';
    my $s = Hash::Persistent->new('tfiles/state', {format => 'json'});
    $s->{a} = { x => 'y', z => 't' };
    $s->commit;
    undef $s;

    $s = Hash::Persistent->new('tfiles/state', {format => 'json'});
    $s->commit;
    undef $s;

    $s = Hash::Persistent->new('tfiles/state');
    is_deeply $s->{a}, { x => 'y', z => 't' }, 'values recoded correctly';
    $s->commit;
    undef $s;

    unlink 'tfiles/state';
    $s = Hash::Persistent->new('tfiles/state', {format => 'json'});
    $s->{a} = bless {} => 'X';
    like(
        exception { $s->commit },
        qr/encountered object/,
        "json format don't support objects"
    );
};

done_testing;
