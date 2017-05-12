#!/usr/bin/perl

use strict;
use warnings;

# this test will run ./destea through all files in
# t_tea and compare the result with the file in t_java

our @files;
BEGIN {
    use File::Find::Rule;
    use Symbol;
    @files = sort grep { ! /\/\./ } File::Find::Rule->file()->not_name('*~')->in('t_tea');
    use IPC::Open3;
    my ($input, $output, $err);
    my $pid = open3( $output, $input, $err, 'astyle', '--version' );
    waitpid($pid,0);
    if ($?) {
        print "1..0 # astyle not available\n";
        exit 0;
    }
}

use IPC::Open3;
use File::Slurp qw(slurp);
use Test::More qw(no_plan);

for my $file (@files) {
       my $o = $file;
        $o =~ s/^t_tea//;
        $o =~ s/\.tea$//;
        my $java = 't_java/'.$o.'.java';
        unless (-e $java) {
            fail($file);
        } else {
            my ($in,$out,$err) = (gensym(),gensym(),gensym());
            my $pid = open3($in, $out, $err, 'bin/destea', $file) || die 'Error openning compiler: '.$!;
            close $in;
            my $result = slurp $out;
            $result =~ s/\s+//g;
            $result =~ s/\n+//g;
            my $warns = slurp $err;
            chomp $warns;
            $warns =~ s/\n/\n#/gs;
            print "#".$warns."\n";
            waitpid $pid, 0;
            close $out;
            close $err;
            my $expected = slurp $java;
            $expected =~ s/\s+//g;
            $expected =~ s/\n+//g;
            is($result,$expected,$file);
        }
}
