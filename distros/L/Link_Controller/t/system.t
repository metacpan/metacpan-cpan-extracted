#!/usr/bin/perl -w
use warnings;

=head1 DESCRIPTION

This test extracts links from an set of test pages and makes a link
database using standard tools.  Next it marks some of the links as
broken.  Finally it checks that the reporting programs give the
correct warnings about broken links.

=cut

use Cwd;

$ENV{HOME}=cwd() . "/t/homedir";
$home_config=$ENV{HOME} . "/.link-control.pl";
die "LinkController test config file, $home_config missing."
  unless -e $home_config;

BEGIN {print "1..10\n"}

@start = qw(perl -Iblib/lib -I../Link.pm/lib);

#$verbose=255;
$verbose=0 unless defined $verbose;
$fail=0;
sub nogo {print "not "; $fail=1;}
sub ok {my $t=shift; print "ok $t\n"; $fail=0}

$::infos="fixlink-infostruc.test-tmp~";

$fixed='test-data/system-infostruc';
unlink $::infos;
-e $::infos and die "can't unlink infostruc file $::infos";
open DEFS, ">$infos" or die "couldn't open $infos $!";
print DEFS "directory http://www.test.nowhere/ test-data/sample-infostruc/\n";
close DEFS or die "couldn't close $infos $!";

do "t/config/files.pl" or die "files.pl script not read: " . ($@ ? $@ :$!);
#die "files.pl script failed: $@" if $@;

#try to generate the lists.
unlink ($lonp, $phasl, $urls, $linkdb);

-e $_ and die "file $_ exists" foreach ($lonp, $phasl, $urls, $linkdb);
# create a "urllist" file from the directories
nogo if system @start, qw(blib/script/extract-links http://www.test.nowhere/
                          test-data/sample-infostruc/),
                          "--config-file=$conf", ($verbose ? () : "--silent");

ok(1);

nogo unless ( -e $lonp and -e $phasl and -e $linkdb );

ok(2);

nogo if system @start, 'blib/script/link-report', "--config-file=$conf";

ok(3);

#put some broken links into the database
use Fcntl;
use DB_File;
use WWW::Link;
use MLDBM qw(DB_File);

tie %::links, MLDBM, $linkdb, O_RDWR, 0666, $DB_HASH
  or die $!;

$link = $::links{"http://www.rum.com/"};

#bypass time checks, but otherwise as close as possible to reality.
$link->first_broken;
$i=6;
$link->more_broken while --$i;

$::links{"http://www.rum.com/"}  = $link;

$link = $::links{"http://www.ix.com"};

#bypass time checks, but otherwise as close as possible to reality.
$link->passed_test;

$::links{"http://www.ix.com"}  = $link;

untie %::links;

$command= (join (" ", @start) )
  . " blib/script/link-report --config-file=$conf ";

$output = `$command`;

$output =~ m,broken.*http://www.rum.com/, or nogo ;

ok(4);

$command= (join (" ", @start) )
  . " blib/script/link-report --config-file=$conf " . '--html';

$output = `$command`;

$output =~ m(BROKEN.*
             \<A\s+.*
              HREF="http://www\.rum\.com/"
             ([^<>]|\n)*\> 
             http://www\.rum\.com/
             \<\/A\> 
            )sx or nogo ;

ok(5);

$command= (join (" ", @start) )
  . " blib/script/link-report --config-file=$conf " . '--okay';

$output = `$command`;

$output =~ m(http://www\.ix\.com)sx or nogo ;

ok(6);


$command= (join (" ", @start) )
  . " blib/script/link-report --long-list --config-file=$conf " . '--okay';

$output = `$command`;

print STDERR "output\n$output\n" if $verbose;

$output =~ m( http://www\.ix\.com .*
	      rw.*test-data/sample-infostruc/banana.html .*
	      rw.*test-data/sample-infostruc/orange.html )sx or nogo;

ok(7);

#test reporting on a specified url

open URL,">report-urls.test-tmp~";
print URL "http://www.ix.com\n";
close URL;

$command= (join (" ", @start) )
  . " blib/script/link-report --all-links --uri-file=report-urls.test-tmp~ "
    .  "--config-file=$conf " . ($verbose ? "--verbose=2047" : "");

print STDERR "running $command" if $::verbose;

$output = `$command`;

print STDERR "output is:\n$output\n" if $::verbose;

$output =~ m(http://www\.ix\.com)sx or nogo ;

ok(8);

$::driver='cgi-driver.test-tmp.pl';
my $rep_cgi="blib/script/link-report.cgi";
open (CGI_DRIVER,">$::driver") or die "couldn't open $driver: $!";
print CGI_DRIVER <<EOF;
#!/usr/bin/perl
use Cwd;
my \@store=\( \$ENV{PATH}, \$ENV{BASH_ENV} \);
\$ENV{PATH}="/bin:/usr/bin";
delete \$ENV{BASH_ENV};
#print "CGI driver starting directory " . cwd() . " dir list\\n";
#print \`ls\`;
(\$ENV{PATH}, \$ENV{BASH_ENV})=\@store;
\$::verbose=0xFFF;
\$::verbose=0;
\$WWW::Link::Selector::verbose=0xFFF;
\$WWW::Link::Selector::verbose=0;
\$fixed_config=0;
\$fixed_config=1;

do "./$conf" or die "script $conf failed: \$!";
do "./$rep_cgi" or die "script $rep_cgi failed: \$!";
EOF
close CGI_DRIVER or die "couldn't close $driver: $!";

#add tainting for the CGIbin
@start = qw(perl -Iblib/lib -w -T);

$command= (join (" ", @start) ) . " $driver";

$output = `echo | $command`;

$output =~ m(\<HEAD\>.*\<TITLE\>.*\</TITLE\>.*\</HEAD\>.*\<BODY\>.*
	     BROKEN .*
             \<A\s .*
              HREF="http://www\.rum\.com/"
             ([^<>]|\n)*\> 
             http://www\.rum\.com/
             \</A\> .*
            \</BODY\>)isx or nogo ;

ok(9);

print STDERR "#going to run: echo infostructure=1 | $command" if $::verbose;
$output = `echo infostructure=1 | $command`;
($mesg="output:\n\n$output\n\n") =~ s/^/#/mg;
print STDERR $mesg if $::verbose;

$output =~ m(\<HEAD\>.*\<TITLE\>.*\</TITLE\>.*\</HEAD\>.*\<BODY\>.*
	     BROKEN .*
             \<A\s .*
              HREF="http://www\.rum\.com/"
             ([^<>]|\n)*\> .*
             http://www\.rum\.com/
             \<\/A\> .*
             \<A\s.*
              HREF="http://www\.test\.nowhere/banana\.html"
             ([^<>]|\n)*\> .*
             http://www\.test\.nowhere/banana\.html .*
             \</A\> .*
            \</BODY\>)isx or nogo ;

ok(10);

#FIXME write tests for url reporting tests for include or exclude features.

#unlink 'link_on_page.cdb', 'page_has_link.cdb', 'test-links.bdbm', 'urllist',
#  $conf;
