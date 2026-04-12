
use Test2::V1 -Pip;

use Moose::Util qw/ does_role /;

use JSON;

use JSON::Schema::AsType::Draft2019_09;

subtest 'default 2019-09 vocabs' => sub {
    my $schema =
      JSON::Schema::AsType::Draft2019_09->new( schema => { const => 2 } );

    my @vocabularies = $schema->vocabularies->@*;

    is scalar @vocabularies => 5, "2019-09 has 5 default vocabs";

    subtest 'has the vocab roles' => sub {
        $schema->type;    # needs to trigger the role assignment

        ok does_role( $schema, $_ ), "does $_"
          for map { "JSON::Schema::AsType::Draft2019_09::Vocabulary::$_" }
          qw/
          Core
          Applicator
          Validation
          Metadata
          Content
          /;
    };

    ok $schema->has_keyword('const'), 'has the method for const';

    ok !$schema->check('potato'), 'validation fails, as it should';
};

subtest 'custom vocab' => sub {
    my $schema = JSON::Schema::AsType->new(
        schema => {
            type       => 'string',
            anagram_of => 'meat',
        }
    );
    $schema->add_vocabulary('Anagram');

    ok $schema->check($_), $_ for qw/ team meta /;
    ok $schema->validate($_), $_ for 1, qw/ potato /;
};

done_testing;

package    # hide from CPAN
  Anagram;
use Type::Tiny;
use Types::Standard qw/ Str /;
use feature         qw/ signatures /;

use Moose::Role;

sub _keyword_anagram_of( $self, $word ) {

    my $anagram_type = Type::Tiny->new(
        name                 => 'Anagram',
        constraint_generator => sub($word) {
            $word = join '', sort split '', $word;

            return sub {
                $word eq join '', sort split '', $_;
            }
        },
        deep_explanation => sub( $type, $value, @ ) {
            my $p = $type->parameters->[0];
            [qq{"$value" is not an anagram of "$p"}];
        },
    );

    # not a string, or an acronym
    return ~Str | $anagram_type->of($word);
}

