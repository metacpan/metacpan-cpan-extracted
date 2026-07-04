# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use if $ENV{AUTHOR_TESTING}, strictures => version => 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use if $ENV{AUTHOR_TESTING}, autovivification => warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use JSON::Schema::Tiny 'evaluate';
use lib 't/lib';
use Helper;
use Test2::Warnings qw(warnings had_no_warnings :no_end_test);

foreach my $keyword (
  qw(unevaluatedItems unevaluatedProperties),
) {
  cmp_result(
    evaluate(true, { $keyword => {} }),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/'.$keyword,
          error => 'keyword not yet supported',
        },
      ],
    },
    'use of "'.$keyword.'" results in error',
  );
}

my %strings = (
  id => qr/^no-longer-supported "id" keyword present \(at location ""\): this should be rewritten as "\$id" at /,
  definitions => qr/^no-longer-supported "definitions" keyword present \(at location ""\): this should be rewritten as "\$defs" at /,
  dependencies => qr/^no-longer-supported "dependencies" keyword present \(at location ""\): this should be rewritten as "dependentSchemas" or "dependentRequired" at /,
);

my %schemas = (
  id => 'https://localhost:1234',
  definitions => {},
  dependencies => {},
);

my @warnings = (
  [ draft7 => [ qw(id) ] ],
  [ 'draft2019-09' => [ qw(id definitions dependencies) ] ],
);

foreach my $index (0 .. $#warnings) {
  my ($specification_version, $removed_keywords) = $warnings[$index]->@*;

  note "\n", $specification_version;
  my $js = JSON::Schema::Tiny->new(specification_version => $specification_version);
  foreach my $keyword (@$removed_keywords) {
    cmp_result(
      [ warnings { ok($js->evaluate(true, { $keyword => $schemas{$keyword} }), 'schema with "'.$keyword.'" still validates in '.$specification_version) } ],
      [ re($strings{$keyword}), ],
      'warned for "'.$keyword.'" in '.$specification_version,
    );
  }

  next if $index == $#warnings;
  my ($next_specification_version, $removed_next_keywords) = $warnings[$index+1]->@*;
  foreach my $keyword (@$removed_next_keywords) {
    next if grep $keyword eq $_, @$removed_keywords;
    cmp_result(
      [ warnings { ok($js->evaluate(true, { $keyword => $schemas{$keyword} }), 'schema with "'.$keyword.'" still validates') } ],
      [],
      'did not warn for "'.$keyword.'" in '.$specification_version,
    );
  }
}

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
