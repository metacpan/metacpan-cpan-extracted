#!perl

use 5.010001;
use strict;
use warnings;

use HTML::Tree::Create::Callback qw(create_html_tree_using_callback);
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
                    3, # number of children node
                );
            } elsif ($level == 1) {
                return ('p', {id=>$id}, "", "", 2);
            } elsif ($level == 2) {
                return (
                    'span', {id=>$id, class=>"foo".$seniority},
                    'text3.'.$seniority,
                    'text4',
                    0,
                );
            }
        }
    );
}

my $exp_tree = <<'_';
<body>
  text before children
  <p id="2">
    <span class="foo0" id="3">
      text3.0
      text4
    </span>
    <span class="foo1" id="4">
      text3.1
      text4
    </span>
  </p>
  <p id="5">
    <span class="foo0" id="6">
      text3.0
      text4
    </span>
    <span class="foo1" id="7">
      text3.1
      text4
    </span>
  </p>
  <p id="8">
    <span class="foo0" id="9">
      text3.0
      text4
    </span>
    <span class="foo1" id="10">
      text3.1
      text4
    </span>
  </p>
  text after children
</body>
_

eq_or_diff($tree, $exp_tree);

done_testing;
