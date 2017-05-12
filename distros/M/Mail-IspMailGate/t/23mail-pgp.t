# -*- perl -*-
#
# Check the PGP module
#

use strict;

BEGIN {$| = 1; $^W = 1};
use Symbol ();
use MIME::Entity ();
use Mail::IspMailGate ();
use Mail::IspMailGate::Parser ();
use Mail::IspMailGate::Filter ();
use Mail::IspMailGate::Filter::PGP ();
use Mail::IspMailGate::Filter::Packer ();

my $cfg = $Mail::IspMailGate::Config::config;
my $pgp = $cfg->{'pgp_path'} || '';
unless (-x $pgp) {
    print "1..0\n";
    exit 0;
}
&Sys::Syslog::openlog('23mail-pgp.t', 'pid', $cfg->{'facility'});
eval { Sys::Syslog::setlogsock('unix'); };

my $tmp_dir = $cfg->{'tmp_dir'} = "output/tmp";
File::Path::mkpath($tmp_dir, 0, 0755) unless -d $tmp_dir;
$cfg->{'pgp'}->{'uid'} = 'Jochen Wiedmann <joe@ispsoft.de>';
$cfg->{'pgp'}->{'uids'} =
    { 'Jochen Wiedmann <joe@ispsoft.de>' => 'blafasel'
    };


print "1..5\n";

my $inFilter = Mail::IspMailGate::Filter::PGP->new
    ({ 'uid'       => 'Jochen Wiedmann <joe@ispsoft.de>',
       'direction' => 'pos'
     });
printf "%sok 1\n", $inFilter ? "" : "not ";

my $outFilter = Mail::IspMailGate::Filter::Packer->new
    ({ 'packer'    => 'gzip',
       'direction' => 'neg'
     });
printf "%sok 2\n", $outFilter ? "" : "not ";

$cfg->{'recipients'} =
    [ { 'recipient' => 'joe-pgp-in@ispsoft.de',
	'filters' => [ $inFilter ] },
      { 'recipient' => 'joe-pgp-out@ispsoft.de',
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
my $fh = Symbol::gensym();
(open($fh, ">output/23mp.in")  &&  (print $fh $str)  &&  close($fh))
    or die "Error while creating input file output/23mp.in: $!";
open($fh, "<output/23mp.in")
    or die "Error while opening input file output/23mp.in: $!";
my $str2 = '';
my $parser = Mail::IspMailGate->new({'debug' => 1,
				     'tmpDir' => $tmp_dir,
				     'noMails' => \$str2});
printf "%sok 4\n", $parser ? "" : "not ";

$parser->Main($fh, 'joe@ispsoft.de', ['joe-pgp-in@ispsoft.de']);
undef $fh;
print "ok 5\n";

(open($fh, ">output/23mp.tmp")  &&  (print $fh $str2)  &&  close($str))
    or die "Error while creating input file output/23mp.tmp: $!";
open($fh, "<output/23mp.tmp")
    or die "Error while opening input file output/23mp.tmp: $!";
my $str3 = '';
$parser->{'noMails'} = \$str3;
$parser->Main($fh, 'joe@ispsoft.de', ['joe-pgp-out@ispsoft.de']);
undef $fh;
print "ok 6\n";

if ($str eq $str3) {
    print "ok 7\n";
} else {
    print "not ok 7\n";
    open(OUT, ">output/21mp.out") and (print OUT $str3) and close(OUT);
}
