# -*- perl -*-
#
# Check the virus scanner.
#

use strict;

BEGIN {$| = 1;  $^W = 1};

use MIME::Entity ();
use Mail::IspMailGate ();
use Mail::IspMailGate::Parser ();
use Mail::IspMailGate::Filter ();
use Mail::IspMailGate::Filter::VirScan ();
use File::Path ();

my $cfg = $Mail::IspMailGate::Config::config;
if (! -x $cfg->{'antivir_path'}) {
    print "1..0\n";
    exit 0;
}
my $tmp_dir = $cfg->{'tmp_dir'};

my $tar = $cfg->{'tar_path'};
my $gzip = $cfg->{'gzip_path'};
print "1..", (-x $tar && -x $gzip) ? 8 : 5, "\n";
File::Path::mkpath($tmp_dir, 0, 0755) unless -d $tmp_dir;
&Sys::Syslog::openlog('14altivir.t', 'pid', $cfg->{'facility'});
eval { Sys::Syslog::setlogsock('unix'); };

my $parser = Mail::IspMailGate::Parser->new();
printf "%sok 1\n", $parser ? "" : "not ";

my $e = MIME::Entity->build('From' => 'amar@ispsoft.de',
			    'To' => 'joe@ispsoft.de',
			    'Subject' => 'Mail-Attachment',
			    'Type' => 'multipart/mixed');
$e->attach('Path' => 'Makefile',
	   'Type' => 'text/plain',
	   'Encoding' => 'quoted-printable');
$e->attach('Path' => 'ispMailGateD',
	   'Type' => 'application/x-perl',
	   'Encoding' => 'base64');
my $entity = MIME::Entity->build('From' => 'joe@ispsoft.de',
				 'To' => 'amar@ispsoft.de',
				 'Subject' => 'Re: Mail-Attachment',
				 'Type' => 'multipart/mixed');
$entity->attach('Path' => 'MANIFEST',
		'Type' => 'text/plain',
		'Encoding' => 'quoted-printable');
$entity->add_part($e, -1);
printf "%sok 2\n", $entity ? "" : "not ";

my $filter = Mail::IspMailGate::Filter::VirScan->new({});

printf "%sok 3\n", $filter ? "" : "not ";

my $entity2 = $entity->dup();

my $main = Mail::IspMailGate->new({'debug' => 1,
				   'tmpDir' => 'output/tmp'});
my $result = $filter->doFilter({'entity' => $entity2,
				'parser' => $parser,
				'main' => $main});
printf "%sok 4\n", $result ? "not " : "";

my $entity3 = $entity2->dup();
$entity3->attach('Path' => 't/eicar.com',
		 'Type' => 'application/x-dos-binary',
		 'Encoding' => 'base64');
$result = $filter->doFilter({'entity' => $entity3,
			     'parser' => $parser,
			     'main' => $main});
if ($result) {
    print "ok 5\n";
} else {
    print "not ok 5\n";
}

if (-x $gzip  &&  -x $tar) {
    system "$tar cf output/t.tar t; $gzip -f output/t.tar";
    system "$tar cf output/examples.tar examples;"
	. " $gzip -f output/examples.tar";
    system "$tar cf output/t2.tar examples output/t.tar.gz;"
	. " $gzip -f output/t2.tar";


    $entity3 = $entity2->dup();
    $entity3->attach('Path' => "output/t.tar.gz",
		     'Type' => 'application/x-tar',
		     'Encoding' => 'base64');
    $result = $filter->doFilter({'entity' => $entity3,
				 'parser' => $parser,
				 'main' => $main});
    printf "%sok 6\n", $result ? "" : "not ";

    $entity3 = $entity2->dup();
    $entity3->attach('Path' => "output/examples.tar.gz",
		     'Type' => 'application/x-tar',
		     'Encoding' => 'base64');
    $result = $filter->doFilter({'entity' => $entity3,
				 'parser' => $parser,
				 'main' => $main});
    printf "%sok 7\n", $result ? "not " : "";

    $entity3 = $entity2->dup();
    $entity3->attach('Path' => "output/t2.tar.gz",
		     'Type' => 'application/x-tar',
		     'Encoding' => 'base64');
    $result = $filter->doFilter({'entity' => $entity3,
				 'parser' => $parser,
				 'main' => $main});
    printf "%sok 8\n", $result ? "" : "not ";
} else {
    print "ok 6 # Skip\n";
    print "ok 7 # Skip\n";
    print "ok 8 # Skip\n";
}
