#!perl

use 5.010;
use strict;
use warnings;

use Filename::Type::Backup qw(check_backup_filename);
use Test::More 0.98;

is_deeply(check_backup_filename(filename=>"foo.txt"), 0);

is_deeply(check_backup_filename(filename=>"#foo#"),
          {original_filename=>'foo'});
is_deeply(check_backup_filename(filename=>"foo~"),
          {original_filename=>'foo'});
is_deeply(check_backup_filename(filename=>"foo.txt.old"),
          {original_filename=>'foo.txt'});
is_deeply(check_backup_filename(filename=>"foo.bak"),
          {original_filename=>'foo'});
is_deeply(check_backup_filename(filename=>"foo.swp"),
          {original_filename=>'foo'});
is_deeply(check_backup_filename(filename=>"foo.txt.orig"),
          {original_filename=>'foo.txt'});
is_deeply(check_backup_filename(filename=>"foo.txt.rej"),
          {original_filename=>'foo.txt'});

# ci
is_deeply(check_backup_filename(filename=>"foo.BAK"),
                {original_filename=>'foo'});
is_deeply(check_backup_filename(filename=>"foo.BAK", ci=>0), 0);

DONE_TESTING:
done_testing;
