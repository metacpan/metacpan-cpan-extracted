#!perl

use Test::More tests => 15;

use strict;
use warnings;

use JavaScript;

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();
$cx->bind_function(ok => \&ok);

{
    my $hash = JavaScript::PerlHash->new();
    ok(defined $hash);
    isa_ok($hash, "JavaScript::PerlHash");
    ok($hash->get_ref);
    my $hv = $hash->get_ref;
    is(ref $hv, "HASH");
    is_deeply($hash->get_ref, {});
}

{
    my $hash = $cx->eval(q/
        var hash = new PerlHash();
        ok(hash instanceof PerlHash);
        hash;
/);

    isa_ok($hash, "JavaScript::PerlHash");
    is_deeply($hash->get_ref, {});
}

{
    my $hash = JavaScript::PerlHash->new();

    $hash->get_ref->{a} = 10;
    $hash->get_ref->{b} = 20;
    
    $cx->eval(q/
        function check_perlhash(hash) {
            ok(hash instanceof PerlHash);
            ok(hash.a == 10);
            ok(hash.b == 20);
            
            hash.b = 30;
            hash.c = 40;
            ok(hash.b == 30);
            ok(hash.c == 40);
            
        }
/);

    $cx->call(check_perlhash => $hash);
}

{
    my $hash = JavaScript::PerlHash->new();
    $cx->eval(q/
        function populate_perlhash_via_index(hash) {
            hash.foo = 20;
        }
    /);
    is_deeply($hash->get_ref, {});
    $cx->call(populate_perlhash_via_index => $hash);
    is_deeply($hash->get_ref, {foo => 20});
}
=cut