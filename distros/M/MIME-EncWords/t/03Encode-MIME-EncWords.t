# -*- perl -*-
#
# Borrowed from mime-header.t in Encode module by DANKOGAI@CPAN.
# Modified for Encode::MIME::EncWords by NEZUMI@CPAN.
#

no utf8;
use strict;
use Test::More;

BEGIN {
    if (ord("A") == 193) {
	plan skip_all => 'No Encode::MIME::EncWords on EBCDIC Platforms';
    } elsif ($] < 5.007003) {
	plan skip_all => 'Unicode/multibyte support is not available';
    } else {
	plan tests => 18;
    }
    $| = 1;
}

use_ok("Encode::MIME::EncWords");

my $eheader =<<'EOS';
From: =?US-ASCII?Q?Keith_Moore?= <moore@cs.utk.edu>
To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>
CC: =?ISO-8859-1?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>
Subject: =?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=
 =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=
EOS

my $dheader=<<"EOS";
From: Keith Moore <moore\@cs.utk.edu>
To: Keld J\xF8rn Simonsen <keld\@dkuug.dk>
CC: Andr\xE9 Pirard <PIRARD\@vm1.ulg.ac.be>
Subject: If you can read this you understand the example.
EOS

is(Encode::decode('MIME-EncWords', $eheader), $dheader, "decode ASCII (RFC2047)");

my $uheader =<<'EOS';
From: =?US-ASCII?Q?Keith_Moore?= <moore@cs.utk.edu>
To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>
CC: =?ISO-8859-1?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>
Subject: =?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=
 =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=
EOS

is(Encode::decode('MIME-EncWords', $uheader), $dheader, "decode UTF-8 (RFC2047)");

my $lheader =<<'EOS';
From: =?US-ASCII*en-US?Q?Keith_Moore?= <moore@cs.utk.edu>
To: =?ISO-8859-1*da-DK?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>
CC: =?ISO-8859-1*fr-BE?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>
Subject: =?ISO-8859-1*en?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=
 =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=
EOS

is(Encode::decode('MIME-EncWords', $lheader), $dheader, "decode language tag (RFC2231)");


$dheader=Encode::decode_utf8(<<"EOS");
From: \xe5\xb0\x8f\xe9\xa3\xbc \xe5\xbc\xbe <dankogai\@dan.co.jp>
To: dankogai\@dan.co.jp (\xe5\xb0\x8f\xe9\xa3\xbc=Kogai, \xe5\xbc\xbe=Dan)
Subject: \xe6\xbc\xa2\xe5\xad\x97\xe3\x80\x81\xe3\x82\xab\xe3\x82\xbf\xe3\x82\xab\xe3\x83\x8a\xe3\x80\x81\xe3\x81\xb2\xe3\x82\x89\xe3\x81\x8c\xe3\x81\xaa\xe3\x82\x92\xe5\x90\xab\xe3\x82\x80\xe3\x80\x81\xe9\x9d\x9e\xe5\xb8\xb8\xe3\x81\xab\xe9\x95\xb7\xe3\x81\x84\xe3\x82\xbf\xe3\x82\xa4\xe3\x83\x88\xe3\x83\xab\xe8\xa1\x8c\xe3\x81\x8c\xe4\xb8\x80\xe4\xbd\x93\xe5\x85\xa8\xe4\xbd\x93\xe3\x81\xa9\xe3\x81\xae\xe3\x82\x88\xe3\x81\x86\xe3\x81\xab\xe3\x81\x97\xe3\x81\xa6Encode\xe3\x81\x95\xe3\x82\x8c\xe3\x82\x8b\xe3\x81\xae\xe3\x81\x8b\xef\xbc\x9f
EOS

#my $bheader =<<'EOS';
#From:=?UTF-8?B?IOWwj+mjvCDlvL4g?=<dankogai@dan.co.jp>
#To: dankogai@dan.co.jp (=?UTF-8?B?5bCP6aO8?==Kogai,=?UTF-8?B?IOW8vg==?==
# Dan)
#Subject:
# =?UTF-8?B?IOa8ouWtl+OAgeOCq+OCv+OCq+ODiuOAgeOBsuOCieOBjOOBquOCkuWQq+OCgA==?=
# =?UTF-8?B?44CB6Z2e5bi444Gr6ZW344GE44K/44Kk44OI44Or6KGM44GM5LiA5L2T5YWo?=
# =?UTF-8?B?5L2T44Gp44Gu44KI44GG44Gr44GX44GmRW5jb2Rl44GV44KM44KL44Gu44GL?=
# =?UTF-8?B?77yf?=
#EOS
my $bheader =<<'EOS';
From: =?UTF-8?B?5bCP6aO8IOW8vg==?= <dankogai@dan.co.jp>
To: dankogai@dan.co.jp =?UTF-8?B?KOWwj+mjvD1Lb2dhaSwg5by+PURhbik=?=
Subject: =?UTF-8?B?5ryi5a2X44CB44Kr44K/44Kr44OK44CB44Gy44KJ44GM44Gq44KS?=
 =?UTF-8?B?5ZCr44KA44CB6Z2e5bi444Gr6ZW344GE44K/44Kk44OI44Or6KGM44GM5LiA?=
 =?UTF-8?B?5L2T5YWo5L2T44Gp44Gu44KI44GG44Gr44GX44GmRW5jb2Rl44GV44KM44KL?=
 =?UTF-8?B?44Gu44GL77yf?=
EOS

#my $qheader=<<'EOS';
#From:=?UTF-8?Q?=20=E5=B0=8F=E9=A3=BC=20=E5=BC=BE=20?=<dankogai@dan.co.jp>
#To: dankogai@dan.co.jp (=?UTF-8?Q?=E5=B0=8F=E9=A3=BC?==Kogai,
# =?UTF-8?Q?=20=E5=BC=BE?==Dan)
#Subject:
# =?UTF-8?Q?=20=E6=BC=A2=E5=AD=97=E3=80=81=E3=82=AB=E3=82=BF=E3=82=AB?=
# =?UTF-8?Q?=E3=83=8A=E3=80=81=E3=81=B2=E3=82=89=E3=81=8C=E3=81=AA=E3=82=92?=
# =?UTF-8?Q?=E5=90=AB=E3=82=80=E3=80=81=E9=9D=9E=E5=B8=B8=E3=81=AB=E9=95=B7?=
# =?UTF-8?Q?=E3=81=84=E3=82=BF=E3=82=A4=E3=83=88=E3=83=AB=E8=A1=8C=E3=81=8C?=
# =?UTF-8?Q?=E4=B8=80=E4=BD=93=E5=85=A8=E4=BD=93=E3=81=A9=E3=81=AE=E3=82=88?=
# =?UTF-8?Q?=E3=81=86=E3=81=AB=E3=81=97=E3=81=A6Encode=E3=81=95?=
# =?UTF-8?Q?=E3=82=8C=E3=82=8B=E3=81=AE=E3=81=8B=EF=BC=9F?=
#EOS
my $qheader=<<'EOS';
From: =?UTF-8?Q?=E5=B0=8F=E9=A3=BC_=E5=BC=BE?= <dankogai@dan.co.jp>
To: dankogai@dan.co.jp =?UTF-8?Q?=28=E5=B0=8F=E9=A3=BC=3DKogai=2C_?=
 =?UTF-8?Q?=E5=BC=BE=3DDan=29?=
Subject: =?UTF-8?Q?=E6=BC=A2=E5=AD=97=E3=80=81=E3=82=AB=E3=82=BF=E3=82=AB?=
 =?UTF-8?Q?=E3=83=8A=E3=80=81=E3=81=B2=E3=82=89=E3=81=8C=E3=81=AA=E3=82=92?=
 =?UTF-8?Q?=E5=90=AB=E3=82=80=E3=80=81=E9=9D=9E=E5=B8=B8=E3=81=AB=E9=95=B7?=
 =?UTF-8?Q?=E3=81=84=E3=82=BF=E3=82=A4=E3=83=88=E3=83=AB=E8=A1=8C=E3=81=8C?=
 =?UTF-8?Q?=E4=B8=80=E4=BD=93=E5=85=A8=E4=BD=93=E3=81=A9=E3=81=AE=E3=82=88?=
 =?UTF-8?Q?=E3=81=86=E3=81=AB=E3=81=97=E3=81=A6Encode=E3=81=95=E3=82=8C?=
 =?UTF-8?Q?=E3=82=8B=E3=81=AE=E3=81=8B=EF=BC=9F?=
EOS

is(Encode::decode('MIME-EncWords', $bheader), $dheader, "decode B");
is(Encode::decode('MIME-EncWords', $qheader), $dheader, "decode Q");
#is(Encode::encode('MIME-EncWords-B', $dheader)."\n", $bheader, "encode B");
is(Encode::encode('MIME-EncWords-B', $dheader), $bheader, "encode B");
#is(Encode::encode('MIME-EncWords-Q', $dheader)."\n", $qheader, "encode Q");
is(Encode::encode('MIME-EncWords-Q', $dheader), $qheader, "encode Q");

$dheader = "What is =?UTF-8?B?w4RwZmVs?= ?";
$bheader = "What is =?UTF-8?B?PT9VVEYtOD9CP3c0UndabVZzPz0=?= ?";
#$qheader = "What is =?UTF-8?Q?=3D=3FUTF=2D8=3FB=3Fw4RwZmVs=3F=3D?= ?";
$qheader = "What is =?UTF-8?Q?=3D=3FUTF-8=3FB=3Fw4RwZmVs=3F=3D?= ?";
is(Encode::encode('MIME-EncWords-B', $dheader), $bheader, "Double decode B");
is(Encode::encode('MIME-EncWords-Q', $dheader), $qheader, "Double decode Q");
{
    # From: Dave Evans <dave@rudolf.org.uk>
    # Subject: Bug in Encode::MIME::Header
    # Message-Id: <3F43440B.7060606@rudolf.org.uk>
    use charnames ":full";
    my $pound_1024 = "\N{POUND SIGN}1024";
    is(Encode::encode('MIME-EncWords-Q' => $pound_1024), '=?UTF-8?Q?=C2=A31024?=',
       'pound 1024');
}

is(Encode::encode('MIME-EncWords-Q', "\x{fc}"), '=?UTF-8?Q?=C3=BC?=', 'Encode latin1 characters');

# RT42627

#my $rt42627 = Encode::decode_utf8("\x{c2}\x{a3}xxxxxxxxxxxxxxxxxxx0");
#is(Encode::encode('MIME-EncWords-Q', $rt42627), 
#   '=?UTF-8?Q?=C2=A3xxxxxxxxxxxxxxxxxxx?= =?UTF-8?Q?0?=',
#   'MIME-EncWords-Q encoding does not truncate trailing zeros');
my $rt42627;
Encode::MIME::EncWords->config(MaxLineLen => 37);
$rt42627 = Encode::decode_utf8("\xc2\xa3xxxxxxxxxxxxxxxxxxx00");
is(Encode::encode('MIME-EncWords-Q', $rt42627),
   "=?UTF-8?Q?=C2=A3xxxxxxxxxxxxxxxxxxx?=\n =?UTF-8?Q?00?=",
   'MIME-EncWords-Q encoding does not truncate trailing zeros');
$rt42627 = Encode::decode_utf8("\xc2\xa3xxxxxxxxxxxxxxxxxxx.0");
is(Encode::encode('MIME-EncWords-Q', $rt42627),
   "=?UTF-8?Q?=C2=A3xxxxxxxxxxxxxxxxxxx?=\n =?UTF-8?Q?=2E0?=",
   'MIME-EncWords-Q encoding does not truncate trailing zeros');
$rt42627 = Encode::decode_utf8("\xc2\xa3xxxxxxxxxxxxxxxxxxx0.");
is(Encode::encode('MIME-EncWords-Q', $rt42627),
   "=?UTF-8?Q?=C2=A3xxxxxxxxxxxxxxxxxxx?=\n =?UTF-8?Q?0=2E?=",
   'MIME-EncWords-Q encoding does not truncate trailing zeros');
Encode::MIME::EncWords->config(MaxLineLen => 38);
$rt42627 = Encode::decode_utf8("\xc2\xa3xxxxxxxxxxxxxxxxxxx00");
is(Encode::encode('MIME-EncWords-Q', $rt42627),
   "=?UTF-8?Q?=C2=A3xxxxxxxxxxxxxxxxxxx?=\n =?UTF-8?Q?00?=",
   'MIME-EncWords-Q encoding does not truncate trailing zeros');
$rt42627 = Encode::decode_utf8("\xc2\xa3xxxxxxxxxxxxxxxxxxx.0");
is(Encode::encode('MIME-EncWords-Q', $rt42627),
   "=?UTF-8?Q?=C2=A3xxxxxxxxxxxxxxxxxxx?=\n =?UTF-8?Q?=2E0?=",
   'MIME-EncWords-Q encoding does not truncate trailing zeros');
$rt42627 = Encode::decode_utf8("\xc2\xa3xxxxxxxxxxxxxxxxxxx0.");
is(Encode::encode('MIME-EncWords-Q', $rt42627),
   "=?UTF-8?Q?=C2=A3xxxxxxxxxxxxxxxxxxx0?=\n =?UTF-8?Q?=2E?=",
   'MIME-EncWords-Q encoding does not truncate trailing zeros');
__END__;
