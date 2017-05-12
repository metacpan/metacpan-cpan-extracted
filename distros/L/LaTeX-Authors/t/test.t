# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use LaTeX::Authors;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

ok(-f "t/article.tex");

my $tex_string = load_file_string("t/article.tex");

my @article = router($tex_string);
my $out_string = string_byauthors_xml(@article);
my $ok_string = "<article>
  <item>
    <author>Jo Smith</author>
    <labo>Centre de Mathématiques, CCSD/CNRS, 58, Avenue du Président Wilson, 75008 Paris Cedex, FRANCE</labo>
  </item>
</article>
";
		
ok($out_string,$ok_string);
