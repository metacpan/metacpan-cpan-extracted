package MyTestFramework;
use strict;
use Test::Base -base;
use HTTP::Request::FromTemplate;

our @EXPORT = qw(template_identity);
use vars '$TODO';

sub template_identity {
  my $block = shift;

  my $expected = $block->expected;
  my $template = $block->template;

  # Normalize the data because Test::Base screws it up
  for ($expected,$template) {
    s!\r?\n!\n!g;
    if ($_ !~ m!\n\n!m) { # Header without a body
      $_ .= "\n"
        until m!\n\n$!m;
    };
  };

  my $h = HTTP::Request::FromTemplate->new(template => \$template);

  # A bug in Test::Base - it eats all empty lines at
  # the end of every block.
  if ($expected !~ m!\n\n!m) { # Header without a body
    $expected .= "\n"
      until $expected =~ m!\n\n$!m;
  };

  my $req = $h->process($block->data);
  my $result = $req->as_string;

  if ($block->name =~ /^TODO: (.*)/) {
    TODO: {
      local $TODO = $1;
      is $result, $expected, $block->name;
    };
  } else {
    is $result, $expected, $block->name;
  };
}

1;