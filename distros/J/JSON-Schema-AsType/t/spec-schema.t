use strict;
use warnings;

use Test::More tests => 4;

use JSON::Schema::AsType;

for ( 3..4 ) {
    isa_ok( 
        JSON::Schema::AsType->new( draft_version => $_ )->spec
            => 'JSON::Schema::AsType', $_ 
    );
}


subtest "good schema" => sub {
    my $good = { properties => { foo => { type => 'string' } } };

    ok !JSON::Schema::AsType->new( schema => $good )->validate_schema;
    ok !JSON::Schema::AsType->new( schema => $good )->validate_explain_schema;
};

subtest "bad schema" => sub {
    my $bad = { id => []  };

    ok( JSON::Schema::AsType->new( schema => $bad )->validate_schema );
    ok( JSON::Schema::AsType->new( schema => $bad )->validate_explain_schema );
};


