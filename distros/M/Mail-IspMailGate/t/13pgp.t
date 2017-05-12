# -*- perl -*-
#
# Check the PGP module
#
use strict;

BEGIN {$| = 1;  $^W = 1};

use MIME::Entity ();
use Mail::IspMailGate ();
use Mail::IspMailGate::Parser ();
use Mail::IspMailGate::Filter ();
use Mail::IspMailGate::Filter::PGP ();
use File::Path ();

my $cfg = $Mail::IspMailGate::Config::config;
if (!$cfg->{'pgp_path'}) {
    print "1..0\n";
    exit 0;
}

my $tmp_dir = $cfg->{'tmp_dir'} = "output/tmp";
$cfg->{'pgp'}->{'uid'} = 'Jochen Wiedmann <joe@ispsoft.de>';
$cfg->{'pgp'}->{'uids'} =
    { 'Jochen Wiedmann <joe@ispsoft.de>' => 'blafasel'
    };

print "1..7\n";
File::Path::mkpath($tmp_dir, 0, 0755) unless -d $tmp_dir;
&Sys::Syslog::openlog('13pgp.t', 'pid', $cfg->{'facility'});
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

my $inFilter = Mail::IspMailGate::Filter::PGP->new({'direction' => 'pos'});
printf "%sok 3\n", $inFilter ? "" : "not ";

my $outFilter = Mail::IspMailGate::Filter::PGP->new({'direction' => 'neg'});
printf "%sok 4\n", $outFilter ? "" : "not ";

my $entity2 = $entity->dup();
my $main = Mail::IspMailGate->new({'debug' => 1,
				   'tmpDir' => $tmp_dir});
$@ = '';
my $result;
eval { $result = $inFilter->doFilter({'entity' => $entity2,
				      'parser' => $parser,
				      'main' => $main});
   };
if ($@ =~ /method \"head\" without a package or object/) {
    print STDERR q{

Your MIME-tools seem to have a minor bug that makes the MIME::Decoder::PGP
module fail. Please apply the patch described in the docs, reinstall the
MIME-modules and reinstall the test. See

    perldoc lib/Mail/IspMailGate/Filter/PGP.pm

for details.

};
}
printf "%sok 5\n", $result ? "not " : "";

my $entity3 = $entity2->dup();
eval { $result = $outFilter->doFilter({'entity' => $entity3,
				       'parser' => $parser,
				       'main' => $main});
   };
if ($@ =~ /method \"head\" without a package or object reference/) {
    print STDERR q{

Your MIME-tools seem to have a minor bug that makes the MIME::Decoder::PGP
module fail. Please apply the patch described in the docs, reinstall the
MIME-modules and reinstall the test. See

    perldoc lib/Mail/IspMailGate/Filter/PGP.pm

for details.

};
    print "not ok 6\n";
} else {
    printf "%sok 6\n", $result ? "not " : "";
}


my $str1 = $entity->as_string();
my $str2 = $entity3->as_string();
if ($str1 eq $str2) {
    print "ok 7\n";
} else {
    print "not ok 7\n";

    if (open(OUT, ">output/13pgp.input")) {
	print OUT $str1;
	close(OUT);
    }
    if (open(OUT, ">output/13pgp.encrypted")) {
	print OUT $entity2->as_string();
	close(OUT);
    }
    if (open(OUT, ">output/13pgp.output")) {
	print OUT $str2;
	close(OUT);
    }
}
