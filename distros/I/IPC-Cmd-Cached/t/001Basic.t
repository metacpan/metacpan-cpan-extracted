######################################################################
# Test suite for IPC::Cmd::Cached
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use IPC::Cmd::Cached;
use File::Temp qw(tempdir);
use Cache::FileCache;

my $dir = tempdir();
my $cache_dir = tempdir();

plan tests => 4;

my $cmd1 = qq{$^X -le 'print time'};
my $cmd2 = qq{$^X -le 'print "abc"'};

my $runner = IPC::Cmd::Cached->new( 
  cache => Cache::FileCache->new({cache_root => $cache_dir}),
);

my($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) =
   $runner->run( command => $cmd1 );

my $output = join '', @$stdout_buf;

like($output, qr/^(\d+)$/, "perl prints date");

($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) =
   $runner->run_cached( command => $cmd1 );

my $new_output = join '', @$stdout_buf;
is($new_output, $output, "cached output");


($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) =
   $runner->run( command => $cmd2 );

my $output2 = join '', @$stdout_buf;
chomp $output2;

is($output2, "abc", "perl prints abc");

($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) =
   $runner->run_cached( command => $cmd2 );

my $new_output2 = join '', @$stdout_buf;
chomp $new_output2;
is($new_output2, $output2, "cached output");
