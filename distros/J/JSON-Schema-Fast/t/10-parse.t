use strict;
use warnings;
use Test::More;
use JSON::Schema::Fast;

# type bits (jsf_types.h) and present bits (jsf_ir.h)
use constant { T_OBJ => 2, T_STR => 8, T_INT => 32 };
use constant { H_TYPE => 1, H_MIN => 1 << 3, H_MINLEN => 1 << 8 };
use constant { TAG_TYPE_LEAF => 3 };

my $c = JSON::Schema::Fast->compile({
    type       => 'object',
    required   => [ 'name', 'age' ],
    properties => {
        name => { type => 'string',  minLength => 1 },
        age  => { type => 'integer', minimum   => 0 },
        zzz  => { type => 'boolean' },
    },
});
my $d = $c->_dump_ir;

# root
is($d->{type_mask}, T_OBJ, 'root type is object');
ok($d->{present}{type},       'present: type');
ok($d->{present}{properties}, 'present: properties');
ok($d->{present}{required},   'present: required');

# properties: sorted by name, pre-hashed
my $p = $d->{properties};
is(scalar(@$p), 3, 'three properties');
is_deeply([ map { $_->{name} } @$p ], [qw/age name zzz/], 'properties sorted by name');
for my $ent (@$p) {
    is($ent->{hash}, JSON::Schema::Fast::_prehash($ent->{name}),
       "property '$ent->{name}' carries the PERL_HASH of its name");
}

# child schemas
my %by = map { $_->{name} => $_ } @$p;
is($by{name}{child}{type_mask}, T_STR, 'name child is string');
ok($by{name}{child}{present} & H_TYPE,   'name child has type');
ok($by{name}{child}{present} & H_MINLEN, 'name child has minLength');
is($by{age}{child}{type_mask}, T_INT, 'age child is integer');
ok($by{age}{child}{present} & H_MIN, 'age child has minimum');

# required: entries carry the index into the sorted property table
my %ridx = map { $_->{name} => $_->{idx} } @{ $d->{required} };
is($ridx{age},  0, 'required age -> prop index 0 (sorted)');
is($ridx{name}, 1, 'required name -> prop index 1 (sorted)');

# a single-keyword schema gets the type-leaf fast-path tag
my $leaf = JSON::Schema::Fast->compile({ type => 'string' });
is($leaf->_dump_ir->{tag}, TAG_TYPE_LEAF, 'lone type schema tagged TYPE_LEAF');

done_testing;
