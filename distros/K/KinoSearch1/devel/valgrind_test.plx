#!/usr/bin/perl
use strict;
use warnings;
$|++;

=begin comment

Run the test suite under valgrind and log the output.

=end comment
=cut

opendir(my $t_dir, 't') or die "Couldn't opendir 't': $!";
my @t_files = sort grep { /\.t$/ } readdir $t_dir;
closedir $t_dir;

open(my $log_fh, '>', "valgrind_test.log");

for my $t_file (@t_files) {
    my $command = "valgrind --leak-check=full $^X -Mblib t/$t_file 2>&1";
    my $output  = "\n\n" . (scalar localtime(time)) . "\n$command\n";
    $output    .= `$command`;
    print $output;
    print $log_fh $output;
}