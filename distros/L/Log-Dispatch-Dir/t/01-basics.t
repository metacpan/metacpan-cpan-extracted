#!perl -T

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
#use File::Stat qw(:stat);
use File::Slurper qw(read_text);

use Log::Dispatch::Dir;

#use lib './t';
#require 'testlib.pm';

my $dir = tempdir(CLEANUP=>1);
my $log;

# XXX should've test for filesystem ability, not OS
my @st;
subtest "permissions" => sub {
    use Probe::Perl;
    my $pp = Probe::Perl->new;
    plan skip_all => "non-Unix platform" if $pp->os_type ne 'Unix';

    $log = new Log::Dispatch::Dir(name=>'dir1', min_level=>'info', dirname=>"$dir/dir1", permissions=>0700);
    @st = stat("$dir/dir1");
    is($st[2] & 0777, 0700, "permissions 1");
};

$log = new Log::Dispatch::Dir(name=>'dir1', min_level=>'info', dirname=>"$dir/dir1", permissions=>0750);
@st = stat("$dir/dir1");
is($st[2] & 0777, 0750, "permissions 2");

$log->log_message(message=>101);
my @f = glob "$dir/dir1/*";
is(scalar(@f), 1, "log_message 1a");
is(read_text($f[0]), "101", "log_message 1b");

$log->log_message(message=>102);
@f = glob "$dir/dir1/*";
is(scalar(@f), 2, "log_message 2a");
is(join(".", map {read_text($_)} @f), "101.102", "log_message 2b");

$log->log_message(message=>103);
@f = glob "$dir/dir1/*";
is(scalar(@f), 3, "log_message 3a");
is(join(".", map {read_text($_)} @f), "101.102.103", "log_message 3b");

# default filename_pattern: %Y%m%d-%H%M%S.%{pid}.%{ext}
for (my $i=0; $i<@f; $i++) {
    like($f[$i], qr!^.+/\d{4}-\d{2}-\d{2}-\d{2}\d{2}\d{2}\.pid-$$\.\w+(\.\d+)?$!, "default filename_pattern $i");
}

# filename_pattern
$log = new Log::Dispatch::Dir(name=>'dir2', min_level=>'info', dirname=>"$dir/dir2", filename_pattern=>"msg");
$log->log_message(message=>101);
$log->log_message(message=>102);
$log->log_message(message=>103);
@f = glob "$dir/dir2/*";
for (my $i=0; $i<@f; $i++) {
    like($f[$i], qr!^.+/msg(\.\d+)?$!, "filename_pattern $i");
}

# filename_pattern: %{ext}
$log = new Log::Dispatch::Dir(name=>'dir2b', min_level=>'info', dirname=>"$dir/dir2b", filename_pattern=>"%{ext}");
$log->log_message(message=>"<html>hello world</html>");
$log->log_message(message=>"\0\xff");
@f = sort glob "$dir/dir2b/*";
if (eval { require File::LibMagic; require Media::Type::Simple }) {
    like($f[0], qr!/bin$!, "filename_pattern ext: bin");
    like($f[1], qr!/html$!, "filename_pattern ext: html");
} else {
    diag "Warning: File::LibMagic and/or Media::Type::Simple not available, will only be testing default extension";
    like($f[0], qr!/log$!, "filename_pattern ext: log (1)");
    like($f[1], qr!/log(\.1)?$!, "filename_pattern ext: log (2)");
}

# filename_sub
$log = new Log::Dispatch::Dir(name=>'dir3', min_level=>'info', dirname=>"$dir/dir3", filename_sub=>sub {my %p=@_; $p{message}});
$log->log_message(message=>100);
$log->log_message(message=>101);
$log->log_message(message=>102);
@f = glob "$dir/dir3/*";
for (my $i=0; $i<@f; $i++) {
    like($f[$i], qr!^.+/10$i$!, "filename_sub $i");
}

done_testing();
