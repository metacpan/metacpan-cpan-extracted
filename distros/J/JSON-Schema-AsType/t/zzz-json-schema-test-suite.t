#!/usr/bin/env perl 

use 5.42.0;
use warnings;

use Test2::V1 -Pip;

use feature qw/ try /;

# for the bigfloat checks
BEGIN { $ENV{PERL_JSON_BACKEND} = 'JSON::backportPP'; }
use JSON;
use Path::Tiny 0.062;
use List::MoreUtils qw/ any /;
use Memoize;
use Data::Printer;
use Data::Dumper;

use JSON::Schema::AsType;
$JSON::Schema::AsType::strict_string = 1;

my $jsts_dir = path(__FILE__)->parent->child('json-schema-test-suite');

memoize('registry');

my ( $target_draft, $target_file, $target_test ) = split ':',
  $ENV{TEST_SCHEMA} // '';

my $todo = {};

push $todo->{$_}{'const.json'}->@*,
  'float and integers are equal up to 64-bit representation limits'
  for 4, 6, 7, '2019-09', '2020-12';

push $todo->{'2019-09'}{'ref.json'}->@*,
  'refs with relative uris and defs',
  'relative refs with absolute uris and defs';

push $todo->{'2020-12'}{'pattern.json'}->@*,
  'pattern with Unicode property escape requires unicode mode';

$todo->{'2020-12'}{ $_ . '.json' } = 1 for qw/
  defs
  unevaluatedItems
  unevaluatedProperties
  dynamicRef
  ref
  /;

run_draft_test_suite($_)
  for grep { !$target_draft or $_ eq $target_draft }
  reverse @JSON::Schema::AsType::DRAFT_VERSIONS;

done_testing;

###################################

sub run_draft_test_suite($draft) {

    my @files = grep { $_->is_file }
      $jsts_dir->child( 'tests', 'draft' . $draft )->children;

    subtest "draft$draft" => sub {
        run_test_suite( $draft, $_, $todo->{$draft} )
          for grep { !$target_file or /$target_file/ } @files;
    };

}

sub run_test_suite( $draft, $file, $todo = {} ) {

    my $data = from_json $file->slurp, { allow_nonref => 1 };

    my $TODO = $todo->{ path($file)->basename };
    if ( $TODO and not ref $TODO and not $ENV{HARNESS_ACTIVE} ) {
        return;
    }
    subtest $file => sub {
        run_schema_test( $draft, $_, $file, $todo->{ path($file)->basename } )
          for grep { !$target_test or $_->{description} =~ /$target_test/ }
          @$data;
    };
}

sub run_schema_test( $draft, $test, $file, $TODO = [] ) {
    subtest $test->{description} => sub {
        if ( $TODO and not ref $TODO ) {
            my $todo;
            $todo = todo "known todo";
            fail "TODO";
            return;
        }

        my $todo;
        $todo = todo "known todo"
          if any { $test->{description} eq $_ } @$TODO;

        my $registry = registry($draft);

        my $schema = JSON::Schema::AsType->new(
            draft    => $draft,
            schema   => $test->{schema},
            registry => +{%$registry},
        );

        for ( @{ $test->{tests} } ) {
            my $desc = $_->{description};

            # local $TODO = 'known to fail'
            #   if any { $desc eq $_ }
            #   'a string is still not an integer, even if it looks like one',
            #   'ignores non-strings',
            #   'a string is still a string, even if it looks like a number',
            #   'a string is still not a number, even if it looks like one';

   # Test that the result from check is the same as what is in the spec.
   # If the check should be true and the result is false, do validate_explain.
            try {
                is !!$schema->check( $_->{data} ) => !!$_->{valid},
                  $_->{description}
                  or do {

                    note $schema->type->display_name;
                    my $validation = $schema->validate_explain( $_->{data} );
                    note "explain: ", @$validation if $validation;
                    note Dumper( $schema->schema );
                    note Dumper( $_->{data} );
                    bail_out("TEST_SCHEMA defined, bailing out")
                      if $ENV{'TEST_SCHEMA'}
                      and ( !$ENV{HARNESS_ACTIVE} and !$todo );
                  };
            }
            catch ($e) {
                diag $e;
                fail $_->{description};
                note Dumper( $schema->schema );
                note Dumper( $_->{data} );

                bail_out("peace out") if $ENV{'TEST_SCHEMA'};
            };

        }
    };

}

sub registry($draft) {
    my $remotes_dir = $jsts_dir->child('remotes');

    my $registry = JSON::Schema::AsType->new( draft => $draft, schema => {} );

    $remotes_dir->visit(
        sub {
            my $path = shift;
            return if $path =~ /draft/ and $path !~ /draft$draft/;
            return unless $path =~ qr/\.json$/;

            my $name = $path->relative($remotes_dir);

            $registry->register_schema( "http://localhost:1234/$name",
                from_json $path->slurp );

            return;

        },
        { recurse => 1 }
    );

    return $registry->registry;
}
