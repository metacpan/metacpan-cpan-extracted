use Test::More tests => 4;

use_ok('Email::FolderType',qw(folder_type));
use Email::FolderType::Mbox;

BEGIN { $^W = 0; }

my $package = "Email::FolderType";

${"$package\::DEFAULT"}     = 'TestMatcher';

is(folder_type('t/this_is_a_test_matcher'), 'TestMatcher', 'new TestMatcher works');
is(folder_type('t/testmh/.'), 'MH', 'MH still works');
is(folder_type('t/testmbox'), 'Mbox', 'Mbox still works');

package Email::FolderType::Mbox;

sub match { return (defined $_[0] && -f $_[0]) }

package Email::FolderType::TestMatcher;

sub match { return 1; }




1;
