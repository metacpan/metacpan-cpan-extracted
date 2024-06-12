# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use Test::Warnings qw(warnings had_no_warnings :no_end_test);
use Test::Deep;
use JSON::Schema::Tiny 'evaluate';
use lib 't/lib';
use Helper;

foreach my $keyword (
  qw(unevaluatedItems unevaluatedProperties),
) {
  cmp_deeply(
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
  my ($spec_version, $removed_keywords) = $warnings[$index]->@*;

  note "\n", $spec_version;
  my $js = JSON::Schema::Tiny->new(specification_version => $spec_version);
  foreach my $keyword (@$removed_keywords) {
    cmp_deeply(
      [ warnings { ok($js->evaluate(true, { $keyword => $schemas{$keyword} }), 'schema with "'.$keyword.'" still validates in '.$spec_version) } ],
      [ re($strings{$keyword}), ],
      'warned for "'.$keyword.'" in '.$spec_version,
    );
  }

  next if $index == $#warnings;
  my ($next_spec_version, $removed_next_keywords) = $warnings[$index+1]->@*;
  foreach my $keyword (@$removed_next_keywords) {
    next if grep $keyword eq $_, @$removed_keywords;
    cmp_deeply(
      [ warnings { ok($js->evaluate(true, { $keyword => $schemas{$keyword} }), 'schema with "'.$keyword.'" still validates') } ],
      [],
      'did not warn for "'.$keyword.'" in '.$spec_version,
    );
  }
}

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
