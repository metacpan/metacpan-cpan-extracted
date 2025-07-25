use 5.010;
use strict;
use warnings;
use Test::More;

use GitHub::Config::SSH::UserData qw(get_user_data_from_ssh_cfg);

use File::Spec::Functions;

use File::Basename;

my $Test_Data_Dir = catdir(dirname(__FILE__), '01-test-data');

ok(1);

{
  my $test_cfg_file = catfile($Test_Data_Dir, 'cfg-01');
  note("Simple tests using $test_cfg_file");
  is_deeply(get_user_data_from_ssh_cfg('ALL-ITEMS', $test_cfg_file),
            {
             'email'      => 'main@addr.xy',
             'email2'     => 'foo@bar',
             'full_name'  => 'John Doe',
             'other_data' => 'additional data'
            },
           "$test_cfg_file: ALL_ITEMS");

  is_deeply(get_user_data_from_ssh_cfg('minimal', $test_cfg_file),
            {
             'email'     => 'main@addr.xy',
             'full_name' => 'minimal'
            },
           "$test_cfg_file: minimal");

  is_deeply(get_user_data_from_ssh_cfg('std', $test_cfg_file),
            {
             'email'     => 'main-jc@addr.xy',
             'full_name' => 'Jonny Controlletti'
            },
            "$test_cfg_file: std");

  is_deeply(get_user_data_from_ssh_cfg('std-data', $test_cfg_file),
            {
             'email'      => 'AlexPl@addr.xy',
             'full_name'  => 'Alexander Platz',
             'other_data' => 'more data'
            },
            "$test_cfg_file: std+data");

  {
    local $@;
    eval { get_user_data_from_ssh_cfg('no-email', $test_cfg_file) };
    ok(defined($@) && $@ =~ /\bno-email: missing or invalid user info\b/,
       "$test_cfg_file: no-email: correct error message");
  }

  {
    local $@;
    eval { get_user_data_from_ssh_cfg('no-User-comment', $test_cfg_file) };
    ok(defined($@) && $@ =~ /\bno-User-comment: missing or invalid user info\b/,
       "$test_cfg_file: no-User-comment: correct error message");
  }

  {
    local $@;
    eval { get_user_data_from_ssh_cfg('foo', $test_cfg_file) };
    ok(defined($@) && $@ =~ /\bduplicate: duplicate user name\b/,
     "$test_cfg_file: (foo) duplicate: correct error message");
  }
}

{
  my $test_cfg_file = catfile($Test_Data_Dir, 'cfg-02');
  {
    local $@;
    eval { get_user_data_from_ssh_cfg('non-existing-name', $test_cfg_file) };
    ok(defined($@) && $@ =~ /\bnon-existing-name: user name not in \Q$test_cfg_file\E\b/,
       "$test_cfg_file: non-existing-name: correct error message");
  }
}


#==================================================================================================
done_testing();
