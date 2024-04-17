use strict;
use warnings;

use Test::More;
use Test::Exception;

use JSON::Schema::AsType::Draft3::Types Schema => { -as => 'SD3' };
use JSON::Schema::AsType::Draft4::Types Schema => { -as => 'SD4' };
use JSON::Schema::AsType::Draft6::Types Schema => { -as => 'SD6' };

for my $draft ( qw/ 3 4 6 /) {
    my $class = "JSON::Schema::AsType::Draft${draft}::Types";
    subtest "Draft $draft" => sub {
        my $schema = $class->Schema->coerce({ type => 'integer', minimum => 5 });

        ok $class->Schema->check($schema), "schema is a schema";
        ok $schema->check( 6 );
        ok !$schema->check( 4 );
        ok !$schema->check( "banana" );

        dies_ok {
            my $schema = Schema->coerce({ type => 'banana', minimum => 5 });
        } "bad schema";
    }
}

done_testing;
