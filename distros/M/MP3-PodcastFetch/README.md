		 MP3::PodcastFetch and fetch_pods.pl

Author: Lincoln D. Stein <lstein@cshl.edu>
First Release Date: January 1, 2007

Description
-----------

Fetch_pods.pl is a Perl script to fetch and maintain a directory of
podcast subscriptions. Information about which podcasts to fetch are
stored in a configuration file. You control how many podcast files to
keep, where to keep them, whether to rationalize their ID3 tags, and
whether to delete older files. This script will also create playlists
for recently-fetched podcasts.

MP3::PodcastFetch is a set of Perl modules used for the backend of
this script. You can use this library to write your own Podcast
maintenance system.

Installation
------------

To install, you will need Perl version 5.8 or higher and recent
versions of the following additional modules, all of which can be
found on CPAN (www.cpan.org):

 LWP
 Date::Parse
 HTML::Parser
 Config::IniFiles

In addition, if you wish to update the ID3 tags in downloaded
podcasts, you will need one or more of the following ID3-writing
libraries (also on CPAN):

 Audio::TagLib (from CPAN, also requires taglib from http://developer.kde.org/~wheeler/taglib.html)
 MP3::Tag (from CPAN)
 MP3::Info (from CPAN)

Audio::TagLib is the most capable of the libraries, and is able to
write tags through ID3 version 2.4. ID3::Tag can write tags through
ID3 version 2.3, while MP3::Info can only write version 1
tags. Audio::TagLib is a bit more trouble to install because it
requires the taglib C++ library to be installed first, but I recommend
using it, if you can.

If you do not have any of these libraries installed, then you will
still be able to download podcasts, but you will not be able to
normalize their ID3 tags.

Now run the following commands from the top level of this
distribution:

 % perl Build.PL
 % ./Build
 % ./Build test
 % ./Build install

You may need to perform the last step as the superuser. Run "perldoc
Module::Build" for information on how to odify the build and install
process, such as how to specify a non-standard installation location.

The build process will install the command fetch_pods.pl somewhere on
your executable path. Please run the command "perldoc fetch_pods.pl"
to learn about how to configure and run the fetch_pods.pl script. Use
"perldoc MP3::PodcastFetch" to learn more about the underlying Perl
library.

Contributing
------------

The source code for this module is maintained on GitHub at
https://github.com/lstein/MP3-PodcastFetch. You are encouraged to
check out the latest improvements to the source code and to contribute
your own ideas and features.
