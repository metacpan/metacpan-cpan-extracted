#!/usr/bin/perl

=head1 NAME

full-run.t - test link-controller against a real apache.

=head1 DESCRIPTION

This test tests against a running apache server for working and broken
links.

=head1 USAGE

Change to the top level directory supertest then run this script.

=cut

use Cwd;

#chdir "full-run.d" or die "couldn't change into full-run.d";
$basedir="supertest/full-run.d";
$res=system "cd $basedir; ./run-httpd";
die "couldn't start httpd $!" if $res==-1;
$ENV{HOME} = $basedir . '/homedir';
$config=$ENV{HOME} . "/.link-control.pl";
die "LinkController test config file, $config missing." unless -e $config;

BEGIN {print "1..8\n"}

@start = qw(perl -Iblib/lib);

#$verbose=255;
$verbose=0;
$fail=0;
sub nogo {print "not "; $fail=1;}
sub ok {my $t=shift; print "ok $t\n"; $fail=0}

#FIXME check that this is really the base directory of the distribution.

$files="t/config/files.pl";

$::infos=".fixlink-infostruc-defs";
do "$files" or die "$files script not read: $!";
die "$files script failed $@" if $@;

unlink $::infos;
-e $::infos and die "can't unlink infostruc file $::infos";
open DEFS, ">$infos" or die "couldn't open $infos $!";
print DEFS "directory http://www.test.nowhere/ test-data/local-linked-infostruc\n";
close DEFS or die "couldn't close $infos $!";


-e $_ and die "file $_ exists" foreach ($lonp, $phasl, $urls, $links);

#try to genereate the lists.

# create a "urllist" file from the directories
@run=( @start, $script . "/extract-links", "--config-file=$conf");
print STDERR "running " . join (" ", @run) . "\n";
nogo if system @run;

ok(1);

nogo unless -e $lonp and -e $phasl;

ok(2);

#FIXME delete test

#die "url list file $urls doesn't exist" unless -e $urls;

#push @start, '-d';

#nogo if system @start, $script . '/links-from-listfile', $links, $urls;

ok(3);

nogo unless ( -e $lonp and -e $phasl and -e $linkdb );

ok(4);

nogo if system @start, $script . '/build-schedule',
  "--config-file=$conf", "--spread-time=100";


ok(5);

nogo if system @start, ( $script . '/test-link', '--test-now', '--never-stop',
			 '--max-links=10', '--verbose=2047',
			 '--no-waitre=127.0.0.1',
			 "--config-file=$conf", '--sequential' );

ok(6);

$command= (join (" ", @start,  $script . '/link-report', '--all-links',
		 "--config-file=$conf") );

$output = `echo | $command`;

ok(7);

( $output =~ m,tested okay:- +http\Q://127.0.0.1:8083/index.html\E,
  && $output =~ m,tested okay:- +http\Q://127.0.0.1:8083/\E,
  && ( $output  =~ 
       m,could.*broken:- +http\Q://127.0.0.1:8083/nonexistent.html\E, )
) or nogo;

ok(8);
