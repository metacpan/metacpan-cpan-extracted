# Argument-validation croaks. No gearmand needed — these all fail
# before any I/O.
use strict;
use warnings;
use Test::More;
use EV::Gearman;

# new()
eval { EV::Gearman->new('host') };
like $@, qr/odd number of arguments/, 'new: odd args croak';

eval { EV::Gearman->new(host => '127.0.0.1', path => '/tmp/x') };
like $@, qr/cannot specify both 'host' and 'path'/, 'new: host+path conflict croak';

# register_function requires a coderef
{
    my $g = EV::Gearman->new;
    eval { $g->register_function('f') };
    like $@, qr/callback required/, 'register_function: missing cb croak';
    eval { $g->register_function('f', 'not-a-coderef') };
    like $@, qr/coderef|callback required/, 'register_function: non-coderef croak';
}

# grab_job() with no args is an XS-level usage error. (Its coderef
# check sits behind the connection check, so the non-coderef croak
# isn't reachable on an unconnected client — not worth a live server
# here.)
{
    my $g = EV::Gearman->new;
    eval { $g->grab_job() };
    like $@, qr/Usage|callback required/, 'grab_job: missing cb croak';
}

# reconnect setter needs the enable arg
{
    my $g = EV::Gearman->new;
    eval { $g->reconnect() };
    like $@, qr/enable arg required/, 'reconnect: missing enable croak';
}

# maxqueue Perl-layer guards (text-protocol injection surface)
{
    my $g = EV::Gearman->new;
    eval { $g->maxqueue('f') };
    like $@, qr/size/, 'maxqueue: missing size croak';
    eval { $g->maxqueue("f\nshutdown", 10) };
    like $@, qr/whitespace/, 'maxqueue: whitespace in function name croak';
    eval { $g->maxqueue('f', "10\nshutdown") };
    like $@, qr/non-negative integer/, 'maxqueue: injection via size croak';
    eval { $g->maxqueue(undef, 10) };
    like $@, qr/function name required/, 'maxqueue: undef func croak';
}

# connect_unix path length is bounded by sun_path (~108 bytes). This
# surfaces via on_error (not a croak), fired synchronously from the
# connect attempt.
{
    my $err;
    my $g = EV::Gearman->new(on_error => sub { $err = $_[0] });
    $g->connect_unix('/tmp/' . ('x' x 200));
    like $err, qr/path too long/, 'connect_unix: overlong path -> on_error';
}

# Payload over GM_MAX_PACKET (256 MiB) is rejected before any request
# is allocated. Needs one ~256 MiB transient scalar (a bounded single
# allocation, not list construction) and no gearmand: the object is
# "alive" (connecting) so the guard is reached, and the croak fires
# during the synchronous submit before any I/O.
{
    my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);
    my $huge = 'x' x (256 * 1024 * 1024 + 1);
    eval { $g->submit_job('f', $huge, sub {}) };
    like $@, qr/payload too large/, 'submit_job: oversized payload croaks';
    undef $huge;
    $g->reconnect(0);   # stop any reconnect attempts before teardown
}

done_testing;
