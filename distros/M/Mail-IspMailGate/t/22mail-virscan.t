# -*- perl -*-
#
# Check the virus scanner.
#

use strict;

BEGIN {$| = 1;  $^W = 1};
use Symbol ();
use MIME::Entity ();
use Mail::IspMailGate ();
use Mail::IspMailGate::Filter ();
use Mail::IspMailGate::Filter::VirScan ();
use File::Path ();

my $numFiles = 0;

package MyVirScan;

use vars qw(@ISA);
@ISA = qw(Mail::IspMailGate::Filter::VirScan);

sub HasVirus {
    my $self = shift; my $str = shift;
    ($str =~ /Virus\s+detected\!/) ? $str : '';
}


package main;


sub VScan ($$$) {
    my($entity, $expect, $num) = @_;
    my $input = $entity->as_string();
    my $fh = Symbol::gensym();
    ++$numFiles;
    my $fname = "output/22mv$numFiles.in";
    (open($fh, ">$fname")  &&  (print $fh $input)  &&  close($fh))
	or die "Error while creating input file $fname: $!";
    open($fh, "<$fname") or die "Error while opening input file $fname: $!";
    my $output = '';
    my $parser = Mail::IspMailGate->new({'debug' => 1,
					 'tmpDir' => 'output/tmp',
					 'noMails' => \$output});
    $parser->Main($fh, 'joe@ispsoft.de', ['joe-virscan@ispsoft.de']);
    if ($output =~ /Virus detected/) {
	printf "%sok $num\n", $expect ? "" : "not ";
    } else {
	printf "%sok $num\n", $expect ? "not " : "";
    }
    open($fh, ">output/22mv$numFiles.out")  and  print $fh $output;
}


my $cfg = $Mail::IspMailGate::Config::config;
&Sys::Syslog::openlog('22mail-virscan.t', 'pid', $cfg->{'facility'});
eval { Sys::Syslog::setlogsock('unix'); };
my $gzip = $cfg->{'gzip_path'};
my $tar = $cfg->{'tar_path'};
print "1..7\n";
my $tmp_dir = $cfg->{'tmp_dir'} = "output/tmp";
File::Path::mkpath($tmp_dir, 0, 0755) unless -d $tmp_dir;

$cfg->{'antivir_path'} = 't/virscan';
$cfg->{'virscan'}->{'scanner'} = '$antivir_path $ipaths';
my $filter = MyVirScan->new({});
$cfg->{'recipients'} =
    [ { 'recipient' => 'joe-virscan@ispsoft.de',
	'filters' => [ $filter ] }
    ];
printf "%sok 1\n", $filter ? "" : "not ";


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
printf "%sok 2\n", $entity ? "" : "not ";
VScan($entity, 0, 3);

my $entity2 = $entity->dup();
$entity2->attach('Path' => 't/virscan',
		 'Type' => 'text/plain',
		 'Encoding' => 'base64');
VScan($entity2, 1, 4);

if (-x $gzip  &&  -x $tar) {
    system "$tar cf output/t.tar t; $gzip -f output/t.tar";
    system "$tar cf output/examples.tar examples;"
	. "$gzip -f output/examples.tar";
    system "$tar cf output/t2.tar examples output/t.tar.gz;"
	. " $gzip -f output/t2.tar";


    $entity2 = $entity->dup();
    $entity2->attach('Path' => "output/t.tar.gz",
		     'Type' => 'application/x-tar',
		     'Encoding' => 'base64');
    VScan($entity2, 1, 5);

    $entity2 = $entity->dup();
    $entity2->attach('Path' => "output/examples.tar.gz",
		     'Type' => 'application/x-tar',
		     'Encoding' => 'base64');
    VScan($entity2, 0, 6);

    $entity2 = $entity->dup();
    $entity2->attach('Path' => "output/t2.tar.gz",
		     'Type' => 'application/x-tar',
		     'Encoding' => 'base64');
    VScan($entity2, 1, 7);
} else {
    print "ok 5 # Skip\n";
    print "ok 6 # Skip\n";
    print "ok 7 # Skip\n";
}
