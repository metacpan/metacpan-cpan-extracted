# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Lingua::En::Victory') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $v = Lingua::En::Victory->new;

my $templates = $v->templates;
for my $template (@$templates) 
  {	
      print STDERR $v->expr($template, 'Perl', 'Java') . "\n";
  }

warn $v->rand_expr('Perl', 'Python');

ok(1);
