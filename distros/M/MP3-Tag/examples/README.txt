   Short documentation of tagged.pl, tagit.pl and extractID3v2.pl
=====================================================================

You will find three perl programs as examples in this release. 
You can use them after installing the MP3::Tag module. Look
at the README.txt in the main directory to see, how to do this.

Then simply run tagged.pl or tagit.pl (see description below), 
giving filename(s) on the command line. mp3info.pl expects the
filename(s) on standard input <STDIN>.

To run the examples you need Perl installed, at least 5.x I think. 
I wrote this on Redhat/Debian Linux with Perl 5.6.0, but I think, 
it should run with other versions too.
I didn't test it with windows. If you try to run it with windows,
please send me a short message, either if you had success or not. 

  Thomas  <thg@users.sourceforge.net> 
          http://tagged.sourceforge.net


tagged.pl
#########

tagged.pl demonstrates at the moment the function of MP3::Tag. It
reads the tags of files, which are given on the command line, and
prints them to the console.

Later tagged.pl should be a program to change tags interactivly, to
check them for consistency (is there different information in ID3v1
and ID3v2 tag and/or the filename?), and so on...


mp3info.pl
##########

mp3info demonstrates how easy it can be to extract some main
fields from a mp3-file with the new autoinfo() function.

It expects its input (filenames) on STDIN, so call it like

ls *.mp3 | /path/to/mp3info.pl


tagit.pl
########

tagit.pl is another demo program. It runs at the console and can
change ID3v1/ID3v1.1 tags.  Therefor a lot of command line switches
exist.

It can also set the filename of a mp3 file, according to the
information found in a ID3v1 tag.  For this a format string says how
the filename has to be formed. With this it is for example possible to
set a filename to 'artist - song.mp3' (format string: '%a - %s.mp3'),
or even to put the files in directorys like
'artist/album/track. song.mp3' (format string: './%a/%l/%t. %s.mp3')
And if you want that the track number always consists of two digits,
do a %2:0t instead of the %t. Directorys, which do not exist yet, can
be created on the fly.  try tagit.pl --help to get a list of all
command line options.

Format string:

%a - replaced with artist
%s - replaced with song
%l - replaced with album
%t - replaced with track
%y - replaced with year
%g - replaced with genre
%c - replaced with comment

options for %x: (where x is one of a,s,l,t,y,g,c) 
[only valid with --setfilename]

%nx    => use only first n characters
          eg. artist="artist name"  %5a = "artis"

%n:cx  => use at least n characters, if %x is shorter, 
          fill it with character c
          eg. track=3       %2:0t = '03'  , 
	      artist="abc"  %5:_a = "__abc"

%n!:cx => same as %n:cx, but if %x is longer than n, cut it at n
          eg. artist="abc"      %5:_a = "__abc"  
	      artist="abcdefg"  %5:_a = "abcde"

extractID3v2.pl
###############

This is a small utility to extract ID3v2 headers from a file.
The extracted header will be written to STDOUT.
It's only purpose if for testing/debugging. If you encounter a
problem with a ID3v2 tag, which creates an erroeneus output,
you can extract the header and sent it to me, so that I can
check it (NEVER send a complete mp3 file!).
Because this is an alpha release, you have to realise, that some
frame/tags are not supported yet.


