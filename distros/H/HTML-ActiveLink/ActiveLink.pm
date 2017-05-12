
package HTML::ActiveLink;
use 5.004;

use Carp;
use strict;
use vars qw($VERSION);
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

# These are default option settings. We use an array so
# we can coax it into a hash easily - see new().
my @OPT = (
   image             => 1,
   image_prefix      => '',
   image_suffix      => '_on',
   image_rmlink      => 1,
   text              => 1,
   text_prefix       => '<font color="red">',
   text_suffix       => '</font>',
   text_rmlink       => 1,
   imagemap          => 1,
   imagemap_prefix   => '',
   imagemap_suffix   => '_on',
   imagemap_joinchar => '_',
   imagemap_rootname => 'home',
   imagemap_dirdepth => 2
);

=head1 NAME

HTML::ActiveLink - dynamically activate HTML links based on URL

=head1 SYNOPSIS

   use HTML::ActiveLink;

   my $al = new HTML::ActiveLink;

   print $al->activelink(@html_doc);

=head1 DESCRIPTION

I don't know about you, but one of the main problems I have with
HTML content is getting images and links to "turn on" depending
on the current URL location. That is, I like authoring one set
of templates, something like this:

   [ <a href="/">Home</a> | <a href="/faq/">FAQ</a>
   | <a href="/about/">About Us</a> ]

And then having the appropriate link turned on, so that if I'm
running inside the /home/ directory, the above turns into this:

   [ <font color="red">Home</font> | <a href="/faq/">FAQ</a>
   | <a href="/about/">About Us</a> ]

Without having to write a whole bunch of if's, or writing a
bunch of different sets of templates, etc.

This module handles the above process automatically. By default,
it will activate any text or images with E<lt>a hrefE<gt> tags
around them by stripping the link off and changing the appearance
of text and names of images. All transformations are fully customizable,
allowing you to choose how your active text should look. HTML::ActiveLink
can even automatically construct imagemaps depending on your location.

In the simplest case, all you have to do is create a new object
by a call to new(), and then call the main activelink() function
which takes care of the transformation. To customize what the
output HTML looks like, keep reading...

=head1 FUNCTIONS

=head2 new()

This is the constructor method, and it takes a number of parameters
that determine how the output HTML looks:

   text              -  transform text links?  [1]
   text_prefix       -  prefix to add to text  [<font color="red">]
   text_suffix       -  suffix to add to text  [</font>]
   text_rmlink       -  remove <a href=> tag?  [1]

   image             -  transform image links? [1]
   image_prefix      -  prefix to add to image []
   image_suffix      -  suffix to add to image [_on]
   image_rmlink      -  remove <a href=> tag?  [1]

   imagemap          -  create URL imagemaps?  [1]
   imagemap_prefix   -  prefix for imagemaps   []
   imagemap_suffix   -  suffix for imagemaps   [_on]
   imagemap_joinchar -  join parts with char   [_]
   imagemap_rootname -  imagemap name for /    [home]
   imagemap_dirdepth -  max dir levels to use  [2]

The first set of args determines how to transform text links. By
default, any text links will be changed into red text when you're
in the directory or document that they point to (see below for more
explicit details). To change this, just change the prefix and suffix,
for example:

   my $al = HTML::ActiveLink->new(text_prefix => '<b>',
                                  text_suffix => ' &gt;</b>');

This will make the active links bold, with a E<gt> sign after them
as well. A similar principle works for images. By default, an image
link like so:

   <a href="/home/"><img src="/images/home.gif"></a>

Will be transformed to:

   <img src="/images/home_on.gif">

Notice that the file type suffix is preserved, and that the image
suffix is properly applied to the name of the image. Again, to
change the suffix or prefix simply change the image_ parameters.

Finally, this module will automatically B<construct> imagemaps
based on the current URL. Unlike the two above methods, which
involve parsing and modifying existing content, the imagemap
creation instead creates the name of the imagemap dynamically.
This is done since imagemaps contain multiple links, so each
one represents many areas to click on.

For example, if you are running in the directory /faq/, and you
have an imagemap that looks like this:

   <img src="/images/tab.gif" usemap="#nav">

Then the image src will be rewritten as:

   <img src="/images/tab_faq_on.gif" usemap="#nav">

Here, the name of the imagemap is rewritten similarly to images,
only depending on your location. The directory information is inserted
in after the name of the image that exists, along with the suffix. The
imagemap name is created by joining together the directory name(s) for
your current location, up to 2 deep by default. More examples:

   /faq/            = tab_faq_on.gif
   /                = tab_home_on.gif (depending on _rootname)
   /name/g.html     = tab_name_on.gif
   /id/N/NW/NWIGER/ = tab_id_N_on.gif (note only first 2 used)

The second one depends on what you've set imagemap_rootname to,
since this is what is used to determine the name for /. In the
last example, notice that only 2 dir levels are used by default,
meaning that huge dir trees do not result in tons of different
imagemap names. To change this, set imagemap_dirdepth.

=cut

######################
# PUBLIC FUNCTIONS
######################

sub new {
    my $class = shift;
    my %opt = (@OPT, @_);
    return bless \%opt, $class;
}

=head2 activelink()

This is the function that actually parses the document and
activates all the necessary links. It joins its arguments into
a scalar representation of the file and returns that, which
can then be printed out or manipulated further. Examples:

   print $al->activelink(@doc);
   print $al->activelink($part1, $part2, $part3);
   $doc = $al->activelink(<STDIN>);

And so on. To change how it works, pass different values to
the new() function described above.

The activelink() function uses regular expressions to match
the location so that anything deeper than a link is activated.
So, assuming this link:

   <a href="/news/today/">Today's News</a>

Then any of the following locations would cause it to be active:

   /news/today/
   /news/today/presidential_election_still_undecided.html
   /news/today/regional/san_diego_headlines.html

But none of these would:

   /news/
   /news/today.html
   /news/today

Just like with Apache configs, the path needs to be matched
completely, and then anything beneath that path works as well.

=cut

sub activelink {

    my $self = shift;
    my $document = join '', @_;   # scalar easier
    
    # first get info about our server to make sure that the links really match
    my $server_port = $self->server_port;
    my $server_name = $self->server_name;
    my $http = ($server_port == 443) ? 'https' : 'http';
    my $port = ($server_port == 443 || $server_port == 80 || $self->{ignore_port})
                ? "(?:\:$server_port)?" : ":$server_port";

    # urls as listed in an actual HTML document might be relative,
    # so we need to check for that
    # also need to compare the other way, since the actual url we
    # might be viewing could be MORE specific than what we're
    # trying to match (hence the $self->match_path() function)
    my $self_url    = $self->self_url;

    if ($self->{image}) {
       my $imageonprefix = $self->{image_prefix};
       my $imageonsuffix = $self->{image_suffix};
       $document =~ s#(<\s*a.*?href\s*=\s*"?)([^">]*)(\"?[^>]*>)(<\s*img.*?src\s*=\s*"?)(.*/?)(.+?)(\.[\w]+"?.*?>)#
                $self->match_path($2, $self->self_url, "$1$2$3$4$5$6$7",
                        "$1$2$3$4$5$imageonprefix$6$imageonsuffix$7")#gie;
    }

    if ($self->{text}) {
       my $textonprefix  = $self->{text_prefix};
       my $textonsuffix  = $self->{text_suffix};
       if ($self->{text_rmlink}) {
          $document =~ s#(<\s*a.*?href\s*=\s*"?)([^">]*)("?[^>]*>)(<.*?>)?([^<]*)(<.*?>)?(<\s*/a\s*>)#
                                $self->match_path($2, $self->self_url, "$1$2$3$4$5$6$7",
                                        "$4$textonprefix$5$textonsuffix$6")#gie;
       } else {
          $document =~ s#(<\s*a.*?href\s*=\s*"?)([^">]*)("?.*>)(.+)(<\s*/a\s*>)#
                                $self->match_path($2, $self->self_url, "$1$2$3$4$5",
                                        "$1$2$3$textonprefix$4$textonsuffix$5")#gie;
       }
    }

    if ($self->{imagemap}) {
       # look for "usemap" or "ismap" in any <img> tags
       my $imagemapprefix = $self->{imagemap_prefix};
       my $imagemapsuffix = $self->{imagemap_suffix};
       my $char = $self->{imagemap_joinchar};
       (my $imagemapname  = $self->script_name) =~ s#\W+#$char#g;
       $imagemapname .= $self->{imagemap_rootname} if $imagemapname eq $char;      # / dir
       if (my $levels = $self->{imagemap_dirdepth}) {
          # chop down the imagemapname
          my @save = split $char, $imagemapname, $levels + 2;    # null leader and junk trailer
          pop @save;
          $imagemapname = join $char, @save;
       }
       $document =~ s#(<\s*img.*?src\s*=\s*"?)(.*/)(.*?)(\.[\w]+"?.*?)(usemap|ismap)(.*?>)#$1$2$imagemapprefix$3$imagemapname$imagemapsuffix$4$5$6#gi;
    }

    return $document;
}

######################
# PRIVATE FUNCTIONS
######################

# Usage: $self->match_path($path, $test, $default, $ifmatches)
#
# Private function for matching and transforming urls on the fly.
# External usage is not allowed (please).

sub match_path {

    # This takes four arguments
    my $self = shift;
    my($path, $test, $default, $ifmatches) = @_;

    # Strip trailing / present on directories
    $path =~ s#(\w+)/+$#$1#;

    # Special catch for /, since that will match everything
    if ($path eq '/') {
       return $ifmatches if ($test =~ m#^/[^/]*$#);
       return $default;
    }

    # Simple match - don't use eq because we want it to
    # match /dir, /dir/, and /dir/index.html
    if ($test =~ m#^$path#) {
       return $ifmatches;
    }

    return $default;     # no matches above
}

# Extremely stripped down versions from CGI.pm
# Hah, calling them stripped down is probably inaccurate!! :-)

sub script_name {
    return $ENV{SCRIPT_NAME} || $0;
}

sub self_url {
    return $ENV{REQUEST_URI} || $ENV{SCRIPT_NAME} || $0;
}

sub server_name {
    return $ENV{HTTP_HOST} || $ENV{SERVER_NAME} || 'localhost';
}

sub server_port {
    return $ENV{HTTP_PORT} || $ENV{SERVER_PORT} || '80';
}

=head1 APPLICATIONS

One simple use of this module that I like is creating a simple
script called "header.cgi" that just looks something like this:

   use HTML::ActiveLink;
   my $al = HTML::ActiveLink->new(text_prefix => '<b>',
                                  text_suffix => '</b>');

   my $header = '/path/to/header.html';
   open(HEADER, "<$header") or die $!;
   print $al->activelink(<HEADER>);

Then, I can use this in my SSI documents like so:

   <!--#include "../cgi-bin/header.cgi"-->

And presto! All my SSI .shtml documents have a header which has
links that are automatically activated based on the document location.
You could, of course, beef up the "header.cgi" script so that it
used the name of a file passed as a parameter, etc, depending on
what you want to do.

=head1 VERSION

$Id: ActiveLink.pm,v 1.2 2000/11/27 23:46:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2000 Nathan Wiger, Nateware, Inc. <nate@nateware.com>.
All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

