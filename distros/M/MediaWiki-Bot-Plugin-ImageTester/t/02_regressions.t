# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN{push @INC, "./lib"}

use Test::More tests => 3;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use MediaWiki::Bot;

$wikipedia=MediaWiki::Bot->new ("");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
Ang Tanging Ina N'yong Lahat Movie Poster

==Licensing==
{{Non-free promotional|image_has_rationale=yes}}

===Fair use rationale===
*No free or public domain images have been located for this film.
*Image is a promotional photograph, intended for wide distribution as publicity for the film.
*Image is of considerably lower resolution than the original, and is used for informational purposes only.  Its use does not detract from either the original photograph, or from the film itself.
*It does not limit the copyright owner's rights to market or sell the work in any way.
*This image is used on various websites, so its use on Wikipedia does not make it significantly more accessible or visible than it already is.

== Licensing: ==
{{Non-free poster}}
", undef, "Ang Tanging Ina N'yong Lahat");
is($res, 0, "Regression test #1");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "
== Summary ==
Album cover of [[Articlename]].
== Licensing ==
{{Non-free album cover}}
{{User:Odinn/Templates/Fair use audio|Articlename}}", undef, 'Articlename');
is($res, 0, "Regression test #2");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "{{Non-free use rationale
 |Article           = Elmer Austin Benson
 |Description       = *Official oil painting of Minnesota governor Elmer Benson.
*Painter: Carl Bohnen (1871-1951) 
*Art Collection, Oil 1939 
*Location no. AV1999.187 
*Negative no. 83125 
 |Source            = [http://collections.mnhs.org/visualresources/image.cfm?imageid=64514&Page=11&Keywords=elmer%20benson&SearchType=Basic Original Image] taken from [http://www.mnhs.org/index.htm The Minnesota Historical Society]
 |Portion           = 
 |Low_resolution    = No.
 |Purpose           = This is the state of Minnesota's official oil painting of governor Elmer Benson.
 |Replaceability    = 
 |other_information = 
}}

==Licensing==
{{ Non-free Minnesota Historical Society image
|imgurl=http://collections.mnhs.org/visualresources/image.cfm?imageid=64514&Page=11&Keywords=elmer%20benson&SearchType=Basic
|locationno=AV1999.187 
}}");
is($res, 0, "Regression test #3");

#$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "");
#is($res, 2, "Regression test #");
