#!perl

use 5.010;
use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Slurp::Tiny qw(write_file);
use File::Unsaved qw(check_unsaved_file);
use Test::Exception;
use Test::More 0.98;

my $dir = tempdir(CLEANUP=>1);
write_file("$dir/a.txt", "");

dies_ok { check_unsaved_file(path=>"$dir/foo") } "nonexisting file";
ok(!check_unsaved_file(path=>"$dir/a.txt"), "unmodified");

subtest "emacs & joe/mc" => sub {
    plan skip_all => "symlink() not available" unless eval { symlink "",""; 1 };
    write_file("$dir/b.txt", "");
    symlink 'user@host.1234', "$dir/.#b.txt";
    is_deeply(check_unsaved_file(path=>"$dir/b.txt", check_pid=>0),
              {editor=>"joe/mc", user=>"user", host=>"host", pid=>1234});
    write_file("$dir/c.txt", "");
    symlink 'user@host.1234:1409321328', "$dir/.#c.txt";
    is_deeply(check_unsaved_file(path=>"$dir/c.txt", check_pid=>0),
              {editor=>"emacs",
               user=>"user", host=>"host", pid=>1234, timestamp=>1409321328});
    # XXX check with check_pid=>1
    # XXX check with check_proc_name=>1
};

subtest "vim" => sub {
    write_file("$dir/vim.txt", "");
    open my($fh), ">", "$dir/.vim.txt.swp";
    ok(!check_unsaved_file(path=>"$dir/vim.txt"));
    print $fh "x" x 0x03ef; print $fh "U"; close $fh;
    is_deeply(check_unsaved_file(path=>"$dir/vim.txt"), {editor=>"vim"});
};

DONE_TESTING:
done_testing;
