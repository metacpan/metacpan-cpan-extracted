# -*- perl -*-

use strict;

BEGIN { $| = 1;  $^W = 1 };

use MIME::Entity ();
use Mail::IspMailGate ();
use Mail::IspMailGate::Filter ();
use Mail::IspMailGate::Filter::Packer ();
use File::Path ();
use Symbol ();


my $cfg = $Mail::IspMailGate::Config::config;
my $gzip = $cfg->{'gzip_path'};
unless (-x $gzip) {
    print "1..0\n";
    exit 0;
}

&Sys::Syslog::openlog('21mail-packer.t', 'pid', $cfg->{'facility'});
eval { Sys::Syslog::setlogsock('unix'); };
print "1..7\n";
my $tmp_dir = $cfg->{'tmp_dir'} = "output/tmp";
File::Path::mkpath($tmp_dir, 0, 0755);

my $inFilter = Mail::IspMailGate::Filter::Packer->new
    ({ 'packer'    => 'gzip',
       'direction' => 'pos'
     });
printf "%sok 1\n", $inFilter ? "" : "not ";

my $outFilter = Mail::IspMailGate::Filter::Packer->new
    ({ 'packer'    => 'gzip',
       'direction' => 'neg'
     });
printf "%sok 2\n", $outFilter ? "" : "not ";

$cfg->{'recipients'} =
    [{ 'recipient' => 'joe-packer-in@ispsoft.de',
	    'filters' => [ $inFilter ] },
     { 'recipient' => 'joe-packer-out@ispsoft.de',
       'filters' => [ $outFilter ] }
    ];

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
$entity->add_part($e);
printf "%sok 3\n", $entity ? "" : "not ";


my $str = $entity->as_string();

if (!open(OUT, ">output/21mp.in")  ||  !(print OUT $str)  ||  !close(OUT)) {
    die "Error while creating input file 'output/21mp.in': $!";
}
my $fh = Symbol::gensym();
open($fh, "<output/21mp.in")
    or die "Error while opening input file 'output/21mp.in': $!";
my $str2 = '';
my $parser = Mail::IspMailGate->new({'debug' => 1,
				     'tmpDir' => 'output/tmp',
				     'noMails' => \$str2});
printf "%sok 4\n", $parser ? "" : "not ";

$parser->Main($fh, 'joe@ispsoft.de', ['joe-packer-in@ispsoft.de']);
undef $fh;
print "ok 5\n";

(open(OUT, ">output/21mp.tmp")  &&  (print OUT $str)  &&  close(OUT))
    or die "Error while creating input file 'output/21mp.tmp': $!";
$fh = Symbol::gensym();
open($fh, "<output/21mp.tmp")
    or die "Error while opening input file 'output/21mp.tmp': $!";
my $str3 = '';
$parser->{'noMails'} = \$str3;
$parser->Main($fh, 'joe@ispsoft.de', ['joe-packer-out@ispsoft.de']);
undef $fh;
print "ok 6\n";

if ($str eq $str3) {
    print "ok 7\n";
} else {
    print "not ok 7\n";
    if (open(OUT, ">output/21mp.out")) {
	print OUT $str3;
	close(OUT);
    }
}
