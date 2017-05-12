# -*- perl -*-
#
# Check the banner filter.
#

use strict;

sub BuildEntity ($) {
    my $part = shift;

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

    if (!ref($part)) {
	$entity->attach('Path' => $part,
			'Type' => 'text/plain',
			'Encoding' => 'quoted-printable');
    } else {
	$entity->add_part($part);
    }

    $entity->add_part($e);
    $entity;
}


# The following would better be done with regexp's, but Perl is giving
# us a "regexp too big". (5.004)
sub Match ($$@) {
    my($str, $ws, @args) = @_;

    while (my $start = shift @args) {
	if (substr($str, 0, length($start)) eq $start) {
	    $str = substr($str, length($start));
	} else {
	    return 0;
	}
	$str =~ s/^$ws//;
    }
    return 1;
}


use Mail::IspMailGate::Test;
require Mail::IspMailGate::Filter::Banner;
require File::Copy;

$| = 1;
print "1..9\n";


my $parser = MiParser();


# First test: Text mail

File::Copy::copy("MANIFEST", "output/MANIFEST");
my $entity = BuildEntity('output/MANIFEST');
MiTest($entity, undef, "Building the entity\n");

my $plain_banner = 'Hello, this is the banner!';
my $filter = Mail::IspMailGate::Filter::Banner->new({
    'plain' => IO::Scalar->new(\"$plain_banner"),
    'html' => IO::Scalar->new(\"<H1>$plain_banner</H1>")
});
MiTest($filter, undef, "Creating the filter\n");

my $input = $entity->as_string();
my($result, $entity2) = MiParse($parser, $filter, $entity,
                                "15b1.in", "15b1.out");
MiTest(!$result);
my $output = $entity2->as_string();
my $ws = '(?:\s|\=0D)*';
my($start, $end) = ($output =~ /(.*?)$ws\Q$plain_banner\E$ws(.*)/s);
MiTest(Match($input, $ws, $start, $end))
    or print "Remaining: $input\n";


# Second test: HTML mail

{ my $html = q[
<HTML><HEAD><TITLE>Test mail</TITLE></HEAD>
<BODY>
This is a very simple HTML document.
</BODY>
</HTML>
];
  my $fh = Symbol::gensym();
  if (!open($fh, ">output/test.html")  ||
      !(print $fh $html)  ||  !close($fh)) {
      die "Error while creating HTML document: $!";
  }
}

File::Copy::copy("MANIFEST", "output/MANIFEST");
my $e = MIME::Entity->build('Type' => 'multipart/alternative');
$e->attach('Path' => 'output/MANIFEST',
	   'Type' => 'text/plain',
	   'Encoding' => 'quoted-printable');
$e->attach('Path' => 'output/test.html',
           'Type' => 'text/html',
           'Encoding' => 'quoted-printable');
$entity = BuildEntity($e);
MiTest($entity, undef, "Building the HTML entity\n");

$filter = Mail::IspMailGate::Filter::Banner->new({
    'plain' => IO::Scalar->new(\"$plain_banner"),
    'html' => IO::Scalar->new(\"<H1>$plain_banner</H1>")
});
MiTest($filter, undef, "Creating the filter\n");

$input = $entity->as_string();
($result, $entity2) = MiParse($parser, $filter, $entity,
                                "15b2.in", "15b2.out");
MiTest(!$result);
$output = $entity2->as_string();
my $middle;
($start, $middle, $end) = ($output =~ /(.*?)$ws\Q$plain_banner\E$ws(.*?)$ws\<H1\>\Q$plain_banner\E\<\/H1\>$ws(.*)/s);
MiTest(Match($input, $ws, $start, $middle, $end))
    or print "Remaining: $input\n";

