use strict;
use warnings;

use Digest::Bcrypt ();
use Try::Tiny qw(try catch);

use Test::More;

my $secret = "Super Secret Squirrel";
my $salt   = "   known salt   ";

my $ctx = Digest::Bcrypt->new();
isa_ok($ctx, 'Digest::Bcrypt', 'new: got a proper object');

{
    my $res = undef;
    my $err = undef;
    try {
        $ctx->reset();
        $ctx->add($secret);
        $ctx->settings('$2a$20$GA.eY');
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/bad bcrypt settings/, 'settings: dies on invalid setup';
    is $res, undef, 'no digest';

    $res = undef;
    $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $ctx->settings('$2a$-1$GA.eY03tb02ea0DqbA.eG.');
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/bad bcrypt/i, 'settings: dies with bad cost';
    is $res, undef, 'no digest';

    $res = undef;
    $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $ctx->settings('$2a$20$GA.eY03tb02eZFOeGA.');
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/bad bcrypt settings/i, 'settings: dies with bad salt part';
    is $res, undef, 'no digest';
}

{
    my $res = undef;
    my $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $ctx->cost('foobar');
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/Cost must/i, 'cost: dies on non-numeric';
    is $res, undef, 'no digest';

    $res = undef;
    $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $ctx->salt($salt);
        $ctx->cost(32);
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/Invalid cost/i, 'cost: dies when greater than 31';
    is $res, undef, 'no digest';

    $res = undef;
    $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $ctx->salt($salt);
        $ctx->cost(0);
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/Invalid cost/i, 'cost: dies when too low';
    is $res, undef, 'no digest';

    $res = undef;
    $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/Cost must/i, 'cost: dies when none specified';
    is $res, undef, 'no digest';
}

{
    my $res = undef;
    my $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $ctx->cost(5);
        $ctx->salt('too small');
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/Salt must/i, 'salt: dies on too small of a salt';
    is $res, undef, 'no digest';

    $res = undef;
    $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $ctx->cost(5);
        $ctx->salt();
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/Salt must/i, 'salt: dies without salt';
    is $res, undef, 'no digest';

    $res = undef;
    $err = undef;
    try {
        $ctx->reset;
        $ctx->add($secret);
        $ctx->cost(5);
        $ctx->salt('This is a mighty big salt cannon we have here!');
        $res = $ctx->digest;
    }
    catch {
        $err = $_;
    };
    like $err, qr/Salt must/i, 'salt: dies when salt too large';
    is $res, undef, 'no digest';
}

done_testing();
