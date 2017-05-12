#!perl

use 5.010001;
use strict;
use warnings;

use HTML::Tree::Create::Callback::ChildrenPerLevel
    qw(create_html_tree_using_callback);
use Test::Differences;
use Test::More 0.98;

my $tree;
{
    my $id = 0;
    $tree = create_html_tree_using_callback(
        sub {
            my ($level, $seniority) = @_;
            $id++;
            if ($level == 0) {
                return (
                    'body',
                    {}, # attributes
                    "text before children",
                    "text after children",
                );
            } elsif ($level == 1) {
                return ('p', {id=>$id}, "", "");
            } elsif ($level == 2) {
                return (
                    'span', {id=>$id, class=>"foo".$seniority},
                    'text3.'.$seniority,
                    'text4',
                );
            } elsif ($level == 3) {
                return (
                    'span', {id=>$id, class=>"bar".$seniority},
                );
            }
        },
        [3, 2, 3],
    );
}

my $exp_tree = <<'_';
<body>
  text before children
  <p id="2">
    <span class="foo0" id="3">
      text3.0
      <span class="bar0" id="4">
      </span>
      <span class="bar1" id="5">
      </span>
      text4
    </span>
  </p>
  <p id="6">
  </p>
  <p id="7">
    <span class="foo0" id="8">
      text3.0
      <span class="bar0" id="9">
      </span>
      text4
    </span>
  </p>
  text after children
</body>
_

eq_or_diff($tree, $exp_tree);

done_testing;
