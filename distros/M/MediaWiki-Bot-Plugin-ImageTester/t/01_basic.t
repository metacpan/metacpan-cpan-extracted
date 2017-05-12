# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN{push @INC, "./lib"}

use Test::More tests => 16;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use MediaWiki::Bot;

$wikipedia=MediaWiki::Bot->new ("");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
the source : http://www.the-avenues.com
== Licensing: ==
{{Non-free logo}}");
is($res, 2, "Parser test #1");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "{{Information
|Description=
|Source=I created this work entirely by myself.
|Date=
|Author=[[User:Test|Test]] ([[User talk:Test|talk]])
|other_versions=
}}");
is($res, 1, "Parser test #2");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
image copyright of queensland qoverment
== Licensing: ==
{{Non-free logo}}");
is($res, 2, "Parser test #3");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
uncc.edu
== Licensing: ==
{{Non-free logo}}");
is($res, 2, "Parser test #4");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "{{Information
|Description=
|Source= Ramz Trinidad
|Date= 12-27-2008
|Author= Ramz Trinidad
|Permission= SJDM City
|other_versions=
}}");
is($res, 1, "Parser test #5");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "'White Squad V', acrylic on linen painting by Leon Golub, 1984

==Licensing==
'''Fair use rationale:'''
# This is a historically significant work that could not be conveyed in words.
# Inclusion is for information, education and analysis only.
# Its inclusion in the article(s) adds significantly to the article(s) because it shows the subject, or the work of the subject, of the article(s).
# The image is a low resolution copy of the original work and would be unlikely to impact sales of prints or be usable as a desktop backdrop.
{{Non-free 2D art}}", undef, "Leon Golub");
is($res, 0, "Parser test #6");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Licensing ==
{{Non-free album cover}}
==Fair use rationale for the article on the audio recording==
<div class=\"boilerplate\" style=\"margin:0.5em auto;width:80%;background-color:#f7f8ff;border:2px solid #8888aa; padding:4px;font-size:85%;min-height:64px;vertical-align:center\" id=\"imageLicense\">
<div style=\"float:left\" id=\"imageLicenseIcon\">[[Image:Fair use logo.svg|64px|Fair Use]]</div>
<div style=\"text-align:left;margin-left:68px\" id=\"imageLicenseText\">

'''Fair use rationale for an image of an audio recording cover'''
*It is believed that the use of this image on the English-language Wikipedia to illustrate an article on the audio recording in question falls under the \"Non-profit educational\" clause of the Fair Use doctrine currently upheld by United States law. ([http://www.law.cornell.edu/uscode/html/uscode17/usc_sec_17_00000107----000-.html 17 U.S.C. § 107])
*The image is irreplaceable; a free analogue is impossible to produce as the original will be covered by copyright for the foreseeable future.
*Owing to the limited web-resolution of the image, only a small portion of a copyrighted work is used.
*For the same reasons, the portion of the copyrighted work used is of inherently lower quality than the original, reducing the risk of competitiveness and therefore the effects of this copy on the market for or value of versions held by the owner of the copyright.

</div></div>", undef, "Random Album");
is($res, 5.1, "Parser test #7");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
{{Information
|Description=Geometric Akan goldweight. Early Period. SFU Museum Collection
|Source=self-made
|Date=April 7th 2008
|Location=
|Author=[[User:Mesobones|Mesobones]] ([[User talk:Mesobones|talk]])
|other_versions=
}}
== Licensing: ==
{{self|cc-by-3.0}}");
is($res, -1, "Parser test #8");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
(c) universal pictures

www.impawards.com

== Licensing ==
{{Non-free poster}}

== Fair use in [[The Chamber (film)]] ==
Though this image is subject to copyright, its use is covered by the U.S. fair use laws because:
# It's a low resolution copy of a Film Poster / VHS or DVD Cover.
# It doesn't limit the copyright owner's rights to sell the film in any way, in fact, it may encourage sales. 
# Because of the low resolution, copies could not be used to make illegal copies of the artwork/image.
# The image is itself a subject of discussion in the article or used in the infobox thereof.
# The image  is significant because it was used to promoted a notable film.
==Source==
#Derived from a digital capture (photo/scan) of the Film Poster/ VHS or DVD Cover  (creator of this digital version is irrelevant as the copyright in all equivalent images is still held by the same party). Copyright held by the film company or the artist.  Claimed as fair use regardless.
[[Category:Film poster images|The Chamber (film)]]");
is($res, 0, "Parser test #9");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
From The Story of The China Inland Mission By Geraldine Guinness 1893; London; Morgan & Scott
== Licensing ==
{{PD-US}}");
is($res, -1, "Parser test #10");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "==Summary==
{{PBB Image citation|gene=DLG3}}

== Licensing == 
{{GFDL}}
{{cc-by-sa-3.0|[[Genomics Institute of the Novartis Research Foundation]]}}");
is($res, 3, "Parser test #11");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
Mother and Daughter Black rhinos. Photo taken in Masai Mara, Kenya and i release it into the public domain.
== Licensing ==
{{PD-self}}");
is($res, -1, "Parser test #12");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
Author: Nuno Nogueira
Shot outside the Central Station in Antwerp, Belgium.

== Licensing ==
{{PD-self}}

[[Category:Images of graffiti and unauthorised signage]]");
is($res, -1, "Parser test #13");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "{{Non-free reduce}}

:''Cecil Layne.''
:''Little Rock Nine and Daisy Bates pose in living room, ca. 1957-1960.''
:''Gelatin silver print.''
:''Visual Materials from the NAACP Records,''
:''Prints and Photographs Division (128)''
:''Courtesy of the NAACP''

''Bottom Row, Left to Right: Thelma Mothershed, Minnijean Brown, Elizabeth Eckford, Gloria Ray''
''Top Row, Left to Right: Jefferson Thomas, Melba Pattillo, Terrence Roberts, Carlotta Walls, Daisy Bates (NAACP President), Ernest Green''

{{non-free fair use in|Little Rock Nine}}
{{LOC-image|cph.3c19154}}", undef, "Cecil Layne");
ok((($res==2) or ($res==0)), "Parser test #14");
isnt($res, 5, "non-free fair use in, test #15");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
{{Information
|Description=
|Source=I created this work entirely by myself.
|Date=
|Author='''Will Taylor''' (Vector Converter)
|other_versions=
}}
== Licensing: ==
{{Non-free logo}}
{{SVG-Logo}}");
is($res, 2, "svg-logo, test #16");

#$number++;
#$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "");
#is($res, 2, "Parser test #$number");

