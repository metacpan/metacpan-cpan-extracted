
use strict;
use warnings;

use Test::More qw(no_plan);
use Path::Class;
use Mesoderm;
use SQL::Translator;
use Test::Differences;

my @tests = grep { /\.sql$/ } file(__FILE__)->absolute->parent->subdir('tests')->children;

foreach my $in (@tests) {
  (my $out = $in) =~ s/\.sql/.out/;

  my $sqlt = SQL::Translator->new(parser => 'MySQL',);

  $sqlt->translate({filename => $in});
  my $scaffold = Mesoderm->new(
    schema       => $sqlt->schema,
    schema_class => 'Schema',
  );

  open(my $out_fh, ">", \my $buffer);
  $scaffold->produce($out_fh);

  my $expect = file($out)->slurp;

  $buffer =~ s/^# .*//mg;
  $expect =~ s/^# .*//mg;

  eq_or_diff($buffer, $expect, $in->basename);
}
