
use strict;
use Test::More 'no_plan';
use File::Spec;
use Module::Build;

use Lingua::BrillTagger;

ok 1, "Module is loaded";

my $t = new Lingua::BrillTagger;
ok $t, "Created Lingua::BrillTagger object";

my $data_dir = Module::Build->current->notes('bt_home');

my $lexicon_file = File::Spec->catfile($data_dir, 'LEXICON');
ok $t->load_lexicon($lexicon_file), "Loaded lexicon from $lexicon_file";

my $bigrams_file = File::Spec->catfile($data_dir, 'BIGRAMS');
ok $t->load_bigrams($bigrams_file), "Loaded bigrams from $bigrams_file";

my $lrules_file = File::Spec->catfile($data_dir, 'LEXICALRULEFILE');
ok $t->load_lexical_rules($lrules_file), "Loaded lexical rules from $lrules_file";

my $crules_file = File::Spec->catfile($data_dir, 'CONTEXTUALRULEFILE');
ok $t->load_contextual_rules($crules_file), "Loaded contextual rules from $crules_file";



my $examples_file = File::Spec->catfile('t', 'examples.txt');
open my($fh), $examples_file or die "Can't read $examples_file: $!";

while (<$fh>) {
  next if /^\s*#/;
  my @parts = split ' ';

  my @tokens = @parts[ grep {not $_ % 2} 0..$#parts ];
  my @tags = @parts[ grep {$_ % 2} 1..$#parts ];

  my ($got_tokens, $got_tags) = $t->tag(\@tokens);
  is( "@$got_tokens", "@tokens", "Check tokens from tag() output [$examples_file line $.]" );
  is( "@$got_tags", "@tags", "Check tags from tag() output [$examples_file line $.]" );
}
