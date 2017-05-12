#!/usr/bin/perl -w
use warnings;

=head1 DESCRIPTION

this tests the fix-link program.

=cut

use Cwd;

$ENV{HOME}=cwd() . "/t/homedir";
$config=$ENV{HOME} . "/.link-control.pl";
die "LinkController test config file, $config missing." unless -e $config;

BEGIN {print "1..20\n"}

@start = qw(perl -Iblib/lib);

#$verbose=255;
$verbose=0 unless defined $verbose;
$fail=0;
sub nogo {print "not "; $fail=1;}
sub ok {my $t=shift; print "ok $t\n"; $fail=0}

sub fgrep {
  ($string, $file)=@_;
  my $result = not system "grep $string $file > /dev/null";
  print "grep $string $file > /dev/null gives $result\n" if $verbose;
  return $result;
}

$::infos="fixlink-infostruc.test-tmp~";

$fixed='test-data/fixlink-infostruc';
unlink $::infos;
-e $::infos and die "can't unlink infostruc file $::infos";
open DEFS, ">$infos" or die "couldn't open $infos $!";
print DEFS "directory http://example.com/ "
    . cwd() . "/$fixed\n";
close DEFS or die "couldn't close $infos $!";

do "t/config/files.pl" or die "files.pl script not read: " . ($@ ? $@ :$!);
#die "files.pl script failed $@" if $@;

unlink ($lonp, $phasl, $linkdb);

-e $_ and die "file $_ exists" foreach ($lonp, $phasl, $linkdb);

system 'rm', '-rf', $fixed;

-e $fixed and die "couldn't delete $fixed";

system 'cp', '-pr', 'test-data/sample-infostruc', $fixed;

ok(1);

#extract links for our later tests.

nogo if system @start, qw(blib/script/extract-links ), "--config-file=$conf",
  ($::verbose ? "--verbose" : "--silent") ;

ok(2);

nogo unless ( -e $lonp and -e $phasl and -e $linkdb );

ok(3);

$starturl='http://www.rum.com/';
$endurl='http://www.drinks.com/rum/';
$fixfile='test-data/fixlink-infostruc/banana.html';

#a standard fix of one link to another

nogo if system @start, 'blib/script/fix-link',
  "--config-file=$conf", $starturl, $endurl,
    ($::verbose ? "--verbose" : () );


ok(4);

nogo if fgrep ($starturl, $fixfile);

ok(5);

nogo unless fgrep ($endurl, $fixfile);

ok(6);

#check that fixing of fragments works

$starturl='http://www.liquer.com/orange';
$endurl='http://www.drinks.com/liquer/orange';
$fixfile='test-data/fixlink-infostruc/orange.html';

nogo if system @start, 'blib/script/fix-link',
  "--config-file=$conf", $starturl, $endurl,
    ($::verbose ? "--verbose" : () );

ok(7);

nogo if fgrep ($starturl, $fixfile);

ok(8);

nogo unless fgrep ($endurl, $fixfile);

ok(9);

#check that fixing towards a fragment works

$starturl='http://www.drinks.com/sweet/orange.html';
$endurl='http://www.drinks.com/sweet/all-about#orange';
$fixfile='test-data/fixlink-infostruc/orange.html';

nogo if system @start, 'blib/script/fix-link',
  "--config-file=$conf", $starturl, $endurl,
    ($::verbose ? "--verbose" : () );


ok(10);

nogo if fgrep ($starturl, $fixfile);

ok(11);

nogo unless fgrep ($endurl, $fixfile);

#testing relative fixing

$base='http://example.com/';
$startrel='../recipe';
$endrel='recipe';
$fixfile='test-data/fixlink-infostruc/banana.html';

ok(12);

nogo unless fgrep ($startrel, $fixfile);

ok(13);

#this should NOT fix the infostructure

nogo if system @start, 'blib/script/fix-link',
  "--config-file=$conf", $base . $startrel, $base . $endrel,
    ($::verbose ? "--verbose" : "--no-warn" );


ok(14);

nogo unless fgrep ($startrel, $fixfile);

ok(15);

nogo if fgrep ("'HREF=.$endrel.'", $fixfile);

ok(16);

#this should now fix the infostructure doing relative substitution

nogo if system @start, 'blib/script/fix-link', '--relative',
  "--config-file=$conf", $base . $startrel, $base . $endrel,
    ($::verbose ? "--verbose" : "--no-warn" );

ok(17);

nogo if fgrep ($startrel, $fixfile);

ok(18);

nogo unless fgrep ("'HREF=.$endrel.'", $fixfile);

ok(19);

#now test that we can cope with links containing ..

open CONF, ">>$conf" or die "couldn't open $conf: $!";
print CONF <<EOF;
\$::page_index="test-data/badcdb/page_has_link.cdb";
\$::link_index="test-data/badcdb/link_on_page.cdb";
EOF
close CONF or die "couldn't close $conf: $!";

nogo if system @start, 'blib/script/fix-link',
  "--config-file=$conf",
  "http://scotclimb.org.uk/../images/coire_an_lochain_diag.gif",
  "http://scotclimb.org.uk/images/coire_an_lochain_diag.gif",
  ($::verbose ? "--verbose" : "--no-warn" ); #"--silent" if ever we need

ok(20);


