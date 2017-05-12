use Test::More tests => 4;
use Internals::CountObjects;
use Data::Dumper;

my $objects = Internals::CountObjects::objects();
{
    local $Data::Dumper::Varname = 'objects';
    local $Data::Dumper::Sortkeys = 1;
    diag(Dumper($objects));
}
ok($objects, "objects()");
is(ref($objects), 'HASH', "objects() returned hash");

like(
    Internals::CountObjects::dump_objects(),
    qr/
        \AMemory\ stats\n
        (?:
            ^=\d+=\ .+?:\ \d+\n
        )+
        \z
    /xm
);

my @x = 1 .. 5_000;

like(
    Internals::CountObjects::dump_objects($objects),
    qr/^=\d+= .+:\ \d+\ \(\+\d+\)\n/m
);
