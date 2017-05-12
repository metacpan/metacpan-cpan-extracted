use Test::More tests => 3;

use_ok('Email::FolderType',qw(folder_type));

is(folder_type('t/this_is_a_test_matcher'), 'TestMatcher', 'new TestMatcher works');
is(folder_type('t/testmh/.'), 'MH', 'MH still works');



package Email::FolderType::TestMatcher;

sub match { return 1 if $_[0] =~ /this_is_a_test_matcher/; }

1;
