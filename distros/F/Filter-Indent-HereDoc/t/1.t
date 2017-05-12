# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2; 
BEGIN { use_ok('Filter::Indent::HereDoc') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my ($indent_heredoc,$normal_heredoc);

$indent_heredoc = <<EOT;
  Hello, World!
  EOT

no Filter::Indent::HereDoc;

$normal_heredoc = <<EOT;
Hello, World!
EOT

is($indent_heredoc,$normal_heredoc); 
