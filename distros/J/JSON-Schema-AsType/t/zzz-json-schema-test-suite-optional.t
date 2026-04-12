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
  $ENV{TEST_SCHEMA};

my $todo = {};

push $todo->{4}{'ecmascript-regex.json'}->@*,
  'pattern with non-ASCII digits',
  '\w in patterns matches [A-Za-z0-9_], not unicode letters',
  'patterns always use unicode semantics with pattern',
  'ECMA 262 \S matches everything but whitespace',
  'ECMA 262 \s matches whitespace',
  'ECMA 262 \W matches everything but ascii letters',
  'ECMA 262 \D matches everything but ascii digits',
  'ECMA 262 \d matches ascii digits only';

my @optional_files = (
    '3',       'bignum.json',
    '3',       'color.json',
    '3',       'date-time.json',
    '3',       'date.json',
    '3',       'ecmascript-regex.json',
    '3',       'email.json',
    '3',       'host-name.json',
    '3',       'ip-address.json',
    '3',       'ipv6.json',
    '3',       'regex.json',
    '3',       'time.json',
    '3',       'uri.json',
    '3',       'non-bmp-regex.json',
    '3',       'zeroTerminatedFloats.json',
    '4',       'bignum.json',
    '4',       'ecmascript-regex.json',
    '4',       'float-overflow.json',
    '4',       'date-time.json',
    '4',       'email.json',
    '4',       'hostname.json',
    '4',       'ipv4.json',
    '4',       'ipv6.json',
    '4',       'unknown.json',
    '4',       'uri.json',
    '4',       'id.json',
    '4',       'non-bmp-regex.json',
    '4',       'zeroTerminatedFloats.json',
    '6',       'bignum.json',
    '6',       'ecmascript-regex.json',
    '6',       'float-overflow.json',
    '6',       'date-time.json',
    '6',       'email.json',
    '6',       'hostname.json',
    '6',       'ipv4.json',
    '6',       'ipv6.json',
    '6',       'json-pointer.json',
    '6',       'unknown.json',
    '6',       'uri-reference.json',
    '6',       'uri-template.json',
    '6',       'uri.json',
    '6',       'id.json',
    '6',       'non-bmp-regex.json',
    '6',       'unknownKeyword.json',
    '7',       'bignum.json',
    '7',       'content.json',
    '7',       'cross-draft.json',
    '7',       'ecmascript-regex.json',
    '7',       'float-overflow.json',
    '7',       'date-time.json',
    '7',       'date.json',
    '7',       'email.json',
    '7',       'hostname.json',
    '7',       'idn-email.json',
    '7',       'idn-hostname.json',
    '7',       'ipv4.json',
    '7',       'ipv6.json',
    '7',       'iri-reference.json',
    '7',       'iri.json',
    '7',       'json-pointer.json',
    '7',       'regex.json',
    '7',       'relative-json-pointer.json',
    '7',       'time.json',
    '7',       'unknown.json',
    '7',       'uri-reference.json',
    '7',       'uri-template.json',
    '7',       'uri.json',
    '7',       'id.json',
    '7',       'non-bmp-regex.json',
    '7',       'unknownKeyword.json',
    '2019-09', 'anchor.json',
    '2019-09', 'bignum.json',
    '2019-09', 'cross-draft.json',
    '2019-09', 'dependencies-compatibility.json',
    '2019-09', 'ecmascript-regex.json',
    '2019-09', 'float-overflow.json',
    '2019-09', 'date-time.json',
    '2019-09', 'date.json',
    '2019-09', 'duration.json',
    '2019-09', 'email.json',
    '2019-09', 'hostname.json',
    '2019-09', 'idn-email.json',
    '2019-09', 'idn-hostname.json',
    '2019-09', 'ipv4.json',
    '2019-09', 'ipv6.json',
    '2019-09', 'iri-reference.json',
    '2019-09', 'iri.json',
    '2019-09', 'json-pointer.json',
    '2019-09', 'regex.json',
    '2019-09', 'relative-json-pointer.json',
    '2019-09', 'time.json',
    '2019-09', 'unknown.json',
    '2019-09', 'uri-reference.json',
    '2019-09', 'uri-template.json',
    '2019-09', 'uri.json',
    '2019-09', 'uuid.json',
    '2019-09', 'id.json',
    '2019-09', 'no-schema.json',
    '2019-09', 'non-bmp-regex.json',
    '2019-09', 'refOfUnknownKeyword.json',
    '2019-09', 'unknownKeyword.json',
    '2020-12', 'anchor.json',
    '2020-12', 'bignum.json',
    '2020-12', 'cross-draft.json',
    '2020-12', 'dependencies-compatibility.json',
    '2020-12', 'dynamicRef.json',
    '2020-12', 'ecmascript-regex.json',
    '2020-12', 'float-overflow.json',
    '2020-12', 'format-assertion.json',
    '2020-12', 'date-time.json',
    '2020-12', 'date.json',
    '2020-12', 'duration.json',
    '2020-12', 'ecmascript-regex.json',
    '2020-12', 'email.json',
    '2020-12', 'hostname.json',
    '2020-12', 'idn-email.json',
    '2020-12', 'idn-hostname.json',
    '2020-12', 'ipv4.json',
    '2020-12', 'ipv6.json',
    '2020-12', 'iri-reference.json',
    '2020-12', 'iri.json',
    '2020-12', 'json-pointer.json',
    '2020-12', 'regex.json',
    '2020-12', 'relative-json-pointer.json',
    '2020-12', 'time.json',
    '2020-12', 'unknown.json',
    '2020-12', 'uri-reference.json',
    '2020-12', 'uri-template.json',
    '2020-12', 'uri.json',
    '2020-12', 'uuid.json',
    '2020-12', 'id.json',
    '2020-12', 'no-schema.json',
    '2020-12', 'non-bmp-regex.json',
    '2020-12', 'refOfUnknownKeyword.json',
    '2020-12', 'unknownKeyword.json',
);

for my ( $d, $f ) (@optional_files) {
    $todo->{$d}{$f} = 1;
}

run_draft_test_suite($_)
  for grep { !$target_draft or $_ eq $target_draft }
  reverse @JSON::Schema::AsType::DRAFT_VERSIONS;

done_testing;

###################################

sub run_draft_test_suite($draft) {

    my @files;

    my $iter = $jsts_dir->child( 'tests', 'draft' . $draft, 'optional' )
      ->iterator( { recurse => 1 } );

    while ( my $f = $iter->() ) {
        push @files, $f if $f->is_file;
    }

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
