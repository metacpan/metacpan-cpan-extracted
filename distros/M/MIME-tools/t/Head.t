#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 20;

use MIME::Head;

#------------------------------------------------------------
##diag("Read a bogus file (this had better fail...)");
#------------------------------------------------------------
my $WARNS = $SIG{'__WARN__'}; $SIG{'__WARN__'} = sub { };
my $head = MIME::Head->from_file('BLAHBLAH');
ok(!$head, "parse failed as expected?");
$SIG{'__WARN__'} = $WARNS;

#------------------------------------------------------------
##diag("Parse in the crlf.hdr file:");
#------------------------------------------------------------
# TODO: use lives_ok from Test::Exception ?
($head = MIME::Head->from_file('./testin/crlf.hdr'))
    or die "couldn't parse input";  # stop now
ok('HERE', 
	"parse of good file succeeded as expected?");

#------------------------------------------------------------
##diag("Did we get all the fields?");
#------------------------------------------------------------
my @actuals = qw(path
		 from
		 newsgroups
		 subject
		 date
		 organization
		 lines
		 message-id
		 nntp-posting-host
		 mime-version
		 content-type
		 content-transfer-encoding
		 x-mailer
		 x-url
		 );
push(@actuals, "From ");
my $actual = join '|', sort( map {lc($_)} @actuals);
my $parsed = join '|', sort( map {lc($_)} $head->tags);
is($parsed, $actual, 'got all fields we expected?');

#------------------------------------------------------------
##diag("Could we get() the 'subject'? (it'll end in \\r\\n)");
#------------------------------------------------------------
my $subject;
($subject) = ($head->get('subject',0));    # force array context, see if okay
is($subject, "EMPLOYMENT: CHICAGO, IL UNIX/CGI/WEB/DBASE\r\n", "got the subject okay?" );

#------------------------------------------------------------
##diag("Could we replace() the 'Subject', and get it as 'SUBJECT'?");
#------------------------------------------------------------
my $newsubject = "Hellooooooo, nurse!\r\n";
$head->replace('Subject', $newsubject);
$subject = $head->get('SUBJECT');
is($subject, $newsubject, 'able to set Subject, and get SUBJECT?');

#------------------------------------------------------------
##diag("Does the count() method work?");
#------------------------------------------------------------
ok($head->count('NNTP-Posting-Host')
   && $head->count('nntp-POSTING-HOST')
   && !$head->count('Doesnt-Exist'), 'count method working?');

#------------------------------------------------------------
##diag("Create a custom structured field, and extract parameters");
#------------------------------------------------------------
$head->replace('X-Files', 
	       'default ; name="X Files Test"; LENgth=60 ;setting="6"');
my $params;
$params = $head->params('X-Files');
ok($params,					"got the parameter hash?");
is($params->{_}        , 'default',    	"got the default field?");
is($params->{'name'}   , 'X Files Test',	"got the name?");
is($params->{'length'} , '60',		"got the length?");
is($params->{'setting'}, '6',		"got the setting?");

#------------------------------------------------------------
##diag("Output to a desired file");
#------------------------------------------------------------
open TMP, ">./testout/tmp.head" or die "open: $!";
$head->print(\*TMP);
close TMP;
ok((-s "./testout/tmp.head") > 50,
	"output is a decent size?");      # looks okay

#------------------------------------------------------------
##diag("Parse in international header, decode and unfold it");
#------------------------------------------------------------
($head = MIME::Head->from_file('./testin/encoded.hdr'))
    or die "couldn't parse input";  # stop now
$head->decode;
$head->unfold;
$subject = $head->get('subject',0); $subject =~ s/\r?\n\Z//; 
my $to   = $head->get('to',0);      $to      =~ s/\r?\n\Z//; 
my $tsubject = "If you can read this you understand the example... cool!";
my $tto      = "Keld J\370rn Simonsen <keld\@dkuug.dk>";
is($to, $tto,      "Q decoding okay?");
is($subject, $tsubject, "B encoding and compositing okay?");

#------------------------------------------------------------
##diag("Parse in header with 'From ', and check field order");
#------------------------------------------------------------

# Prep:
($head = MIME::Head->from_file('./testin/third.hdr'))
    or die "couldn't parse input";  # stop now
my @orighdrs;
my @realhdrs = qw(From 
		  Path:	
		  From:		
		  Newsgroups:
		  Subject:
		  Date:
		  Organization:
		  Lines:
		  Message-ID:
		  NNTP-Posting-Host:
		  Mime-Version:
		  Content-Type:
		  Content-Transfer-Encoding:
		  X-Mailer:
		  X-URL:);
my @curhdrs;

# Does it work?
@orighdrs = map {/^\S+:?/ ? $& : ''} (split(/\r?\n/, $head->stringify));
@curhdrs  = @realhdrs;
is(lc(join('|',@orighdrs)), lc(join('|',@curhdrs)),
      "field order preserved under stringify?");

# Does it work if we add/replace fields?
$head->replace("X-New-Addition", "Hi there!");
$head->replace("Subject",        "Hi there again!");
@curhdrs  = (@realhdrs, "X-New-Addition:");
@orighdrs = map {/^\S+:?/ ? $& : ''} (split(/\r?\n/, $head->stringify));
is(lc(join('|',@orighdrs)), lc(join('|',@curhdrs)),
      "field order preserved under stringify after fields added?");

# Does it work if we decode the header?
$head->decode;
@orighdrs = map {/^\S+:?/ ? $& : ''} (split(/\r?\n/, $head->stringify));
is(lc(join('|',@orighdrs)), lc(join('|',@curhdrs)),
      "field order is preserved under stringify after decoding?");

{
	my $h = MIME::Head->new();

	$h->replace('Content-disposition', 'inline; filename=good.file');
	is($h->recommended_filename(), 'good.file', 'Simple case, good filename');

	$h->replace('Content-disposition', 'inline; filename="  "');
	$h->replace('Content-type', 'text/x-fake; name="second.choice"');
	is($h->recommended_filename(), 'second.choice', 'Simple case, second-best choice of filename');

	$h->replace('Content-type', 'text/x-fake; name="      "');
	is($h->recommended_filename(), undef, 'no filenames found');
}

1;
