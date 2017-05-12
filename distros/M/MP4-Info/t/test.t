#!perl -w
#
# Copyright (c) 2004, 2005, Jonathan Harris <jhar@cpan.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the the same terms as Perl itself.
#

use strict;
use Test;

BEGIN { plan tests => 538 }

use MP4::Info;

my @mp4tags = qw(ALB APID ART CMT CPIL CPRT DAY DISK GNRE GRP NAM RTNG TMPO TOO TRKN WRT);

my @mp4info = qw(VERSION LAYER BITRATE FREQUENCY SIZE SECS MM SS MS TIME COPYRIGHT ENCODING ENCRYPTED);

my %mp4s =
    (
     't/faac.m4a'   => {
		ALB	=> 'Album',
		#APID	=>
		ART	=> 'Artist',
		CMT	=> 'This is a Comment',
		#COVR	=>
		CPIL	=> 1,
		#CPRT	=>
		DAY	=> '2004',
		DISK	=> [3,4],
		GNRE	=> 'Acid Jazz',
		#GRP	=>
		NAM	=> 'Name',
		#RTNG	=>
		#TMPO	=>
		TOO	=> 'FAAC 1.24+ (Jul 14 2004) UNSTABLE',
		TRKN	=> [1,2],
		WRT	=> 'Composer',
		VERSION	=> 4,
		LAYER	=> 1,
		BITRATE	=> 16,
		FREQUENCY => 8,
		SIZE	=> 2353,
		SECS	=> 1,
		MM	=> 0,
		MS	=> 178,
		SS	=> 1,
		TIME	=> '00:01',
		COPYRIGHT => 0,
		ENCODING  => 'mp4a',
		ENCRYPTED => 0,
	},
     't/iTunes.m4a' => {
		ALB	=> 'Album',
		#APID	=>
		ART	=> 'Artist',
		CMT	=> "Comment\r\n2nd line",
		#COVR	=>
		CPIL	=> 0,
		#CPRT	=>
		DAY	=> '2004',
		DISK	=> [3,4],
		GNRE	=> 'Acid Jazz',
		GRP	=> 'Grouping',
		NAM	=> 'Name',
		#RTNG	=>
		TMPO	=> 100,
		TOO	=> 'iTunes v4.6.0.15, QuickTime 6.5.1',
		TRKN	=> [1,2],
		WRT	=> 'Composer',
		VERSION	=> 4,
		LAYER	=> 1,
		BITRATE	=> 51,
		FREQUENCY => 44.1,
		SIZE	=> 6962,
		SECS	=> 1,
		MM	=> 0,
		SS	=> 1,
		MS	=> 90,
		TIME	=> '00:01',
		COPYRIGHT => 0,
		ENCODING  => 'mp4a',
		ENCRYPTED => 0,
	},
     't/lossless.m4a' => {
		ALB	=> 'Album',
		#APID	=>
		ART	=> 'Artist',
		CMT	=> "Comment\r\n2nd line",
		#COVR	=>
		CPIL	=> 0,
		#CPRT	=>
		DAY	=> '2004',
		DISK	=> [3,4],
		GNRE	=> 'Acid Jazz',
		GRP	=> 'Grouping',
		NAM	=> 'Name',
		#RTNG	=>
		TMPO	=> 100,
		TOO	=> 'iTunes v6.0.5.20',
		TRKN	=> [1,2],
		WRT	=> 'Composer',
		VERSION	=> 4,
		LAYER	=> 1,
		BITRATE	=> 194,
		FREQUENCY => 44.1,
		SIZE	=> 25345,
		SECS	=> 1,
		MM	=> 0,
		SS	=> 1,
		MS	=> 43,
		TIME	=> '00:01',
		COPYRIGHT => 0,
		ENCODING  => 'alac',
		ENCRYPTED => 0,
	},
     't/nero.mp4' =>   {
		#ALB	=>
		#APID	=>
		ART	=> 'Artist',
		#CMT	=>
		#COVR	=>
		CPIL	=> 0,
		#CPRT	=>
		#DAY	=>
		#DISK	=>
		#GNRE	=>
		#GRP	=>
		NAM	=> 'Name',
		#RTNG	=>
		#TMPO	=>
		TOO	=> 'Nero AAC Codec 2.9.9.91',
		#TRKN	=>
		#WRT	=>
		VERSION	=> 4,
		LAYER	=> 1,
		BITRATE	=> 21,
		FREQUENCY => 8,
		SIZE	=> 3030,
		SECS	=> 1,
		MM	=> 0,
		SS	=> 1,
		MS	=> 153,
		TIME	=> '00:01',
		COPYRIGHT => 0,
		ENCODING  => 'mp4a',
		ENCRYPTED => 0,
	},
     't/real.m4a' =>   {
		ALB	=> 'Album',
		#APID	=>
		ART	=> 'A®tist',
		CMT	=> 'Comment',
		#COVR	=>
		CPIL	=> 0,
		#CPRT	=>
		DAY	=> 2004,
		#DISK	=>
		GNRE	=> 'Acid Jazz',
		#GRP	=>
		NAM	=> 'Nªme',
		#RTNG	=>
		#TMPO	=>
		TOO	=> 'Helix Producer SDK 10.0 for Windows, Build 10.0.0.240',
		TRKN	=> [1,0],
		#WRT	=>
		VERSION	=> 4,
		LAYER	=> 1,
		BITRATE	=> 95,
		FREQUENCY => 1,	# What part of "the sampling rate of the audio should be ... documented in the samplerate field" don't Real understand?
		SIZE	=> 131682,
		SECS	=> 11,
		MM	=> 0,
		SS	=> 11,
		MS	=> 53,
		TIME	=> '00:11',
		COPYRIGHT => 0,
		ENCODING  => 'mp4a',
		ENCRYPTED => 0,
	},
    );


# Basic data
foreach my $file (sort keys %mp4s)
{
    my $ref = $mp4s{$file};

    # Tags
    my $tags = get_mp4tag ($file);
    ok (defined($tags), 1, "file='$file'");

    foreach my $tag (@mp4tags)
    {
	dodata ($tags, $ref, $tag);
    }

    # Mp3::Info compatibility
    ok ($tags->{TITLE},    $tags->{NAM});
    ok ($tags->{ARTIST},   $tags->{ART});
    ok ($tags->{ALBUM},    $tags->{ALB});
    ok ($tags->{YEAR},     $tags->{DAY});
    ok ($tags->{COMMENT},  $tags->{CMT});
    ok ($tags->{GENRE},    $tags->{GNRE});
    ok ($tags->{TRACKNUM}, $tags->{TRKN}[0]);

    # File info
    my $info = get_mp4info ($file);
    ok (defined($info));

    foreach my $tag (@mp4info)
    {
	dodata ($tags, $ref, $tag);
    }

    # OO
    my $mp4 = new MP4::Info $file;
    ok (defined($mp4));

    my @mbr = @mp4tags;
    push @mbr, @mp4info;
    foreach my $tag (@mbr)
    {
	dofunc ($mp4, $ref, $tag)
    }
}

# Non-ASCII chars - utf encoding
my $tags = get_mp4tag ('t/iTunes_utf8.m4a');
ok (defined($tags));
ok ($tags->{ALB},  "A\x{03bb}bum");	# small Lamda
ok ($tags->{ART},  "\x{05d0}®tist");	# Alef
ok ($tags->{CMT},  "Comm\x{212e}nt");	# Estimated symbol
ok ($tags->{GNRE}, "\x{1eb4}cid Jazz");	# A with Breve And Tilde
ok ($tags->{GRP},  "Grou¶ing");
ok ($tags->{NAM},  "Nªme");
ok ($tags->{WRT},  "©omposer");

# Non-ASCII chars - latin1 encoding
MP4::Info::use_mp4_utf8(0);
$tags = get_mp4tag ('t/iTunes_utf8.m4a');
ok (defined($tags));
ok ($tags->{ALB},  "AÎ»bum");
ok ($tags->{ART},  "×Â®tist");
ok ($tags->{CMT},  "Commâ„®nt");
ok ($tags->{GNRE}, "áº´cid Jazz");
ok ($tags->{GRP},  "GrouÂ¶ing");
ok ($tags->{NAM},  "NÂªme");
ok ($tags->{WRT},  "Â©omposer");


sub dodata
{
    my ($tags, $refdata, $tag) = @_;

    if ((($tag eq 'TRKN') || ($tag eq 'DISK')) && defined($refdata->{$tag}))
    {
	ok (@{$tags->{$tag}}, 2, "tag='$tag'");
	ok ($tags->{$tag}[0], $refdata->{$tag}[0], "tag='$tag'");
	ok ($tags->{$tag}[1], $refdata->{$tag}[1], "tag='$tag'");
    }
    else
    {
	ok ($tags->{$tag}, $refdata->{$tag}, "tag='$tag'");
    }
}


sub dofunc
{
    my ($mp4, $refdata, $tag) = @_;

    for my $fn ($tag, lc $tag)
    {
	if ((($tag eq 'TRKN') || ($tag eq 'DISK')) &&
	    defined($refdata->{$tag}))
	{
	    ok (@{$mp4->$fn}, 2, "fn='$fn'");
	    ok (${$mp4->$fn}[0], $refdata->{$tag}[0], "fn='$fn'");
	    ok (${$mp4->$fn}[1], $refdata->{$tag}[1], "fn='$fn'");
	}
	else
	{
	    ok ($mp4->$fn, $refdata->{$tag}, "fn='$fn'")
		unless ($fn eq 'VERSION');
	}
    }
}

# Local Variables:
# cperl-set-style: BSD
# End:
