#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

#======================================#
#               os_disks               #
#======================================#

my ( @list, @expected_list );
if ( is_mac() ) {
    @list = qw(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15);
}
elsif ( is_linux() ) {
    @list = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
}
else {
    croak "Unsupported system\n";
}
my $disk_prefix = get_disk_prefix();
@expected_list = map { $disk_prefix . $_ } @list;
my @os_list = os_disks();
is( \@os_list, \@expected_list, "os_disks - list of os disks is correct." );

done_testing;
