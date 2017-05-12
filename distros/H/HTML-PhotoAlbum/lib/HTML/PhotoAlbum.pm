
# Copyright (c) 2001 Nathan Wiger <nate@wiger.org>
# Use "perldoc PhotoAlbum.pm" for documentation

package HTML::PhotoAlbum;

=head1 NAME

HTML::PhotoAlbum - Create web photo albums and slideshows

=head1 SYNOPSIS

    use HTML::PhotoAlbum;

    # Create a new album object, specifying the albums we have

    my $album = HTML::PhotoAlbum->new(
                      albums => {
                         sf_trip => 'San Francisco Trip',
                         sjc_vac => 'San Jose Vacation',
                         puppy_1 => 'Puppy - First Week',
                         puppy_2 => 'Puppy - Second Week'
                      }
                );

    # By using the "selected" method, we can change what each one
    # looks like. However, note these if statements are optional!

    if ($album->selected eq 'sf_trip') {
        print $album->render(
                         header => 1,
                         eachrow => 3,
                         eachpage => 12
                      );
    } elsif ($album->selected eq 'sjc_vac') {
        print $album->render(
                         header => 1,
                         eachrow => 5,
                         eachpage => 20,
                         font_face => 'times'
                         body_bgcolor => 'silver',
                      );
    } else {
        # Standard album just uses the defaults
        # You can leave out the if's above and just use this
        print $album->render(header => 1);
    }

=head1 REQUIREMENTS

This module requires B<CGI::FormBuilder 3.0> or later.

=head1 DESCRIPTION

Admittedly a somewhat special-purpose module, this is designed to
dynamically create and display a photo album. Actually, it manages
multiple photo albums, each of which can be independently formatted
and navigated.

Basic usage of this module amounts to the examples shown above. This
module supports table-based thumbnail pages, auto-pagination, and slideshows.
The HTML produced is fully-customizable. It should be all you need for
creating online photo albums (besides the pictures, of course).

The directory structure of a basic album looks like this:

    albums/
        index.cgi           (your script)
        hawaii_trip/
            captions.txt    (optional)
            intro.html      (optional)
            image001.jpg 
            image001.sm.jpg 
            image002.gif
            image002-mini.jpg
            pict0003.jpeg
            pict0003.sm.png
            dsc00004.png
            dsc00004.thumb.gif
        xmas_2001/
            captions.txt
            pic0001.jpg
            pic0001.sm.jpg
            pic0002.jpg
            pic0002.sm.jpg
            pic0004.png
            pic0004.mini.png

You'll probably end up choosing just one naming scheme for your images,
but the point is that C<HTML::PhotoAlbum> is flexible enough to handle
all of them or any combination thereof. What happens is that the
module looks in the dir that you specify and does an ASCII sort
on the files. Anything that looks like a valid web image (ends in
C<.jpe?g>, C<.gif>, or C<.png>) will be indexed and displayed.
Then, it does basenames on the images and looks for their
thumbnails, if present. If there are no thumbnails you get a generic
link that says "Image 4" or whatever.

An optional C<captions.txt> file can be included in the directory as
well. If this file is present, you can specify captions that will be
placed beneath each of the images. For example:

    # Sample captions.txt file
    image001    Us atop Haleakala
    image002    Sunset from Maui
    pict0003    Hiking on Kauai
    dsc00004    Snorkeling on Hawaii

Also, if the optional C<intro.html> file is present in the directory,
then that will be shown as the first page, with a link at the bottom
that says "See the Pictures". This allows you to put introductory HTML
to tell about your photos. You can put any HTML you want into this file.

This module attempts to give you a lot of fine-grained control over
image placement and layout while still keeping it simple. You should
be able to place images and cells in tables fairly precisely. 

=cut

use 5.004;
use Carp;
use strict;
use vars qw($VERSION);
$VERSION = do { my @r=(q$Revision: 1.20 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

# Must twiddle CGI a lot so must include this
use CGI;
use CGI::FormBuilder;

# The global %CONFIG hash contains pairs of key/value thingies
# that serve as defaults if stuff is not specified.

my %CONFIG = (
   dir       => '.',
   header    => 0,
   eachrow   => 4,
   eachpage  => 16,
   navbar    => 1,
   navwrap   => 0,
   navfull   => 1,
   prevtext  => 'Prev',
   nexttext  => 'Next',
   linktext  => 'Image',

   # Preset HTML options 
   body_bgcolor   => 'white',
   font_face      => 'arial,helvetica',
   div_align      => 'center',
   td_align       => 'center',
   td_valign      => 'top',

   # These are technically options but completely unsupported
   thumbs    => [qw( .thumb .mini .sm
                     -thumb -mini -sm 
                     _thumb _mini _sm )],
   images    => [qw( .jpg .jpeg .gif .png
                     .mpg .mpeg .avi .mpa )],
   intro     => 'intro.html',
   captions  => 'captions.txt',

);

# Internal tag routines stolen from CGI::FormBuilder, which
# in turn stole them from CGI.pm

sub _escapeurl ($) {
    # minimalist, not 100% correct, URL escaping
    my $toencode = shift || return undef;
    $toencode =~ s!([^a-zA-Z0-9_,.-/])!sprintf("%%%02x",ord($1))!eg;
    return $toencode;
}

sub _escapehtml ($) {
    defined(my $toencode = shift) or return;
    # must do these in order or the browser won't decode right
    $toencode =~ s!&!&amp;!g;
    $toencode =~ s!<!&lt;!g;
    $toencode =~ s!>!&gt;!g;
    $toencode =~ s!"!&quot;!g;
    return $toencode;
}

sub _tag ($;@) {
    # called as _tag('tagname', %attr)
    # creates an HTML tag on the fly, quick and dirty
    my $name = shift || return;
    my @tag = ();
    my @args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    while (@args) {
        # this cleans out all the internal junk kept in each data
        # element, returning everything else (for an html tag)
        my $key = shift @args;
        my $val = _escapehtml shift @args;    # minimalist HTML escaping
        next unless $key && $val;
        push @tag, qq($key="$val");
    }
    return '<' . join(' ', $name, sort @tag) . '>';
}

sub _round (@) {
    my($int,$dec) = split '\.', shift;
    $int++ if $dec >= 5;
    return $int;
}

sub error_404 {
    my $self = shift;
    my $mesg = shift || "The requested album or image was not found.";
    my $real = shift;
    my $mail = $ENV{SERVER_ADMIN} =~ /\@/
                    ? qq(<a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a>)
                    : "the webmaster";
    print <<EOH;
Status: 404 Not Found
Content-type: text/html

<html><head><title>404 Not Found</title></head>
<body bgcolor="white"><font face="arial,helvetica">
<h3>404 Not Found</h3>
$mesg
<p>
<a href="$self->{script}">Click here</a> to start over, or hit "Back" on your browser.
<p>
Please contact $mail for more details.
</font></body></html>
EOH
    carp "[HTML::PhotoAlbum] $real" if $real;   # optional message
    exit 0;
}

sub file2hash ($) {
	my $self = shift;
    my $file = shift;
    my %data = ();
    open FILE, "<$file"
        or $self->error_404("Sorry, cannot access photo albums.", "Can't read $file: $!");
    while (<FILE>) {
		warn "<FILE> $file= $_";
        next if /^\s*#/ || /^\s*$/;
        chomp;
        my($k,$v) = split /\s+/, $_, 2;
        #$c =~ s!$image_pat!!;       # lose any file suffix - slow
        # fix encoding of path
        
        carp "[HTML::PhotoAlbum] Warning: duplicate value for '$k' found in $file" if $data{$k};
        warn "\$data{$k} = $v;";
        $data{$k} = $v;
    }
    close FILE;
    return wantarray ? %data : \%data;
}

=head1 FUNCTIONS

=head2 new(opt => val, opt => val)

Create a new C<HTML::PhotoAlbum> object. Typically, the only option
you need to specify is the C<albums> option, which tells this module
which albums you're going to allow indexing:

    my $album = HTML::PhotoAlbum->new(
                      albums => {
                           dir1 => "My First Album",
                           dir2 => "My Second Album"
                      }
                );

The C<new()> method accepts the following options:

=over

=item albums => { dir => 'Title', dir => 'Title' }

This accepts a hashref holding subdir and title pairs. Each of
the subdirs must live beneath C<"."> (or whatever you set C<dir>
to below). The title is what will be displayed as the album
title both in the thumbnails page as well as the navigation bar.

You can also specify a filename, in which case it will be read
for the names of the albums. The format is the same as the
C<captions.txt> file:

    # Sample albums.txt file
    sf_trip     San Francisco Trip
    sjc_vac     San Jose Vacation

You would then use this like so:

    my $album = HTML::PhotoAlbum->new(albums => 'albums.txt');

If you have a lot of albums, this will allow less code maintenance
in the long run.

=item dir => $path

The directory holding the images. This defaults to C<".">, meaning
it assumes your CGI script lives at the top level of your albums
directory (as shown above). If you mess with this, you must 
understand that this directory must be visible from the web as a
URL. It is recommended that you don't mess with this.

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;
    $self->{opt} = { %CONFIG, @_ };        # remainder of args are key/val
    $self->{data} = [];                    # holds all the images/etc
    push @{$self->{data}}, [];             # blank first element so data @ 1

    $self->{cgi} = new CGI;
    $self->{script} = $self->{cgi}->script_name;

    # Check for whether our 'albums' option is a hashref or not; if not,
    # assume it's a filename and read it in verbatim
    unless (ref $self->{opt}{albums} eq 'HASH') {
        $self->{opt}{albums} = $self->file2hash($self->{opt}{albums});
    }

    # Populate our data if we have an album
    if (my $album = $self->{cgi}->param('album')) {

		use Data::Dumper;
		warn Dumper($self->{opt}{albums}{$album});

        # If not allowed, show forbidden
        $self->error_404("Sorry, that is not a valid photo album.",
                   "Album $album not specified in albums option to new()")
            unless $self->{opt}{albums}{$album};

        # Always need the album dir
        my $albumdir = $self->{cgi}->unescape("$self->{opt}{dir}/$album");

        # Now, try to get to directory and populate all our data
        # We must populate data before our navbar or else we won't
        # be able to know what we should be generating...
        opendir ALBUM, $albumdir or $self->error_404("Sorry, that is not a valid photo album.",
                                               "Cannot read directory $albumdir: $!");

        # We want to just get our images out
        my $image_pat = join '|', @{ $self->{opt}{images} };
        my $thumb_pat = join '|', @{ $self->{opt}{thumbs} };

        # Real quick - any captions.txt file?
        my %captions = ();
        if (-s "$albumdir/$self->{opt}{captions}") {
            %captions = $self->file2hash("$albumdir/$self->{opt}{captions}");
        }

        for my $image (sort grep /(?:$image_pat)$/, readdir ALBUM) {

            # skip thumbs (get below)
            next if $image =~ /(?:$thumb_pat)(?:$image_pat)$/;

            # chop apart the image name into a basename and suffix
            my($basename, $suffix) = $image =~ /(.*?)($image_pat)$/;

            # Look for a thumbnail
            my $image = "$basename$suffix";
            my $thumb = '';
            for my $thsuf ( @{$self->{opt}{thumbs}} ) {
                if ( -s "$albumdir/$basename$thsuf$suffix" ) {
                    $thumb = "$albumdir/$basename$thsuf$suffix";
                }
            }

            # check to see if we have a caption
            my $caption = $captions{$basename} || $self->{opt}{nocaption};

            # put all our thumbs onto an ordered array
            # each element of the array is an array ref which points
            # to the thumbnail name, the image name, and the caption
            push @{$self->{data}}, [ $thumb, $image, $caption ];
        }
        closedir ALBUM;
    }

    return $self;
}

=head2 render(opt => val, opt => val)

The C<render()> method is responsible for formatting the HTML
for the actual pages. It returns a string, which can then be
printed out like so:

    print $album->render(header => 1);

This method takes a number of options which allow you to tweak
the formatting of the HTML produced:

=over

=item eachrow => $num

The number of images to put in each row of the thumbnail page.
Defaults to 4.

=item eachpage => $num

The number of images to display on each thumbnail page.
Defaults to 16. This should be a multiple of C<eachrow>, but
doesn't have to be.

=item header => 1 | 0

If set to 1, a "Content-type" header and HTML title will be
printed out, meaning you don't have to do this yourself.
Defaults to 0.

=item navwrap => 1 | 0

If set to 1, the navigation bar will wrap from last page to
the first for both thumbnails and full-size images. Defaults
to 0.

=item navfull => 1 | 0

If set to 0, then a navigation page will I<not> be created 
for the full-size images. Instead, the thumbnail pages will
link to the full-size images directly.

=item linktext => $string

Printed out followed by a number if no thumbnail is found.
Defaults to "Image".

=item nexttext => $string

The text for the "next page" link. Defaults to "Next". Note
you can do snazzy navigation by doing something tricky like
this:

    nexttext => "<img src=/images/next.gif>"

But don't tell anyone I said that.

=item prevtext => $string

The text for the "previous page" link. Defaults to "Prev".

=back

In addition, you can specify tags for any HTML element in one
of two ways. This is stolen directly from L<HTML::QuickTable>.
First, you can specify them as "tag_attr", for example:

    body_alink => 'silver'      # <body alink="silver">

    td_bgcolor => 'white'       # <td bgcolor="white">

    font_face  => 'arial',      # <font face="arial" size="3">
    font_size  => '3'

Or, you can point the tag name to an attr hashref. These would
have the same effect as the above:

    body => { alink => 'silver' }

    td => { bgcolor => 'white' }

    font => { face => 'arial', size => 3 }

These tags will then be changed appropriately in the HTML, allowing
you to completely manipulate what the HTML that is printed out looks
like. Several of these options are set by default to make the standard
HTML look as nice as possible.

=cut

sub render {
    my $self = shift;
    carp "Odd number of arguments passed into \$album->render" unless @_ % 2 == 0;
    my %opt = ( %{$self->{opt}}, @_ );  # rest are option => 'value' pairs

    # lose fucking uninitialized warnings
    local $^W = 0;

    # We print out a navigational form up top of each page
    my $navform = CGI::FormBuilder->new(fields => [qw/album/], params => $self->{cgi});

    # What will be printed out
    my @print = ();

    # Re-parse our %opt to look for things that resemble HTML tags,
    # since all our options are single words. Note that "htmltag => { hashref }"
    # is already implicitly handled by the simple %opt = assign way at the top.
    # All the "||=" parts are needed so that our defaults don't kill customs

    while (my($key, $value) = each %opt) {
        if ($key =~ /^([a-zA-Z]+)_(\w+)/) {
            # split up based on _
            $opt{$1}{$2} ||= $value;
        } elsif ($key eq 'font') {
            $opt{font}{face} ||= $value;
       	} elsif ($key eq 'bgcolor') {
            $opt{body}{bgcolor} ||= $value;
        } elsif ($key eq 'width') {
            $opt{table}{width} ||= $value;
        } elsif ($key eq 'align') {
            $opt{div}{align} ||= $value;
        } elsif ($key eq 'center') {
            # super-special, undocumented for a reason
            $opt{div}{align} ||= $value ? 'center' : 'left';
        }
    }

    # Get any album if present via CGI
    my $album = $navform->field('album') || '';

    # See if we have a name text
    my $name = $album ? $self->{opt}{albums}{$album} || ucfirst $album
                      : 'Select a Photo Album';

    # Extra meta gunk if slideshow
    my $head = '';
    # Print a header if requested
    if ($opt{header}) {
        push @print, <<EOF;
Content-type: text/html

<html>
<head>$head<title>$name</title></head>
EOF
        push @print, _tag('body', $opt{body}),
                     _tag('div', $opt{div}),
                     _tag('font', $opt{font});
    }

    # Closing copyright message 
    my $close = _tag('div', $opt{div}) . <<EOF;
<p><font size="-1"><i>Generated by 
<a href="http://search.cpan.org/search?mode=module&query=HTML::PhotoAlbum">HTML::PhotoAlbum</a>
by <a href="http://www.nateware.com">Nateware</a>
</i></font></div></body></html>
EOF

    # Add album select form
    $navform->field(name => 'album', options => $self->{opt}{albums}, type => 'select');
    push @print, $navform->render(reset => 0, submit => 'View');

    # Do we have an album? If so, keep going, otherwise print generic text
    if (! $album) {
        push @print, qq(Please select a photo album from the list above and click "View".\n);
    } else {

        # Always need the album dir
        my $albumdir = "$self->{opt}{dir}/$album";

        if ($self->{cgi}->param('image') || $self->{cgi}->param('slideshow')) {
            my $img = $self->{cgi}->param('image') || ($opt{eachpage} * ($self->{cgi}->param('page') - 1) + 1);

            # Print a single image out
            my $data = $self->{data}[$img];

            # If the image doesn't exist, show 404
            $self->error_404("Sorry, image $img was not found in the $name photo album.")
                unless ref $data;

            # Boundary checks for min/max image
            my $nextimg = $img + 1;
            my $previmg = $img - 1;
            my $numimgs = @{$self->{data}} - 1;     # length

            # Setup links just like for pages
            my($prevlink, $nextlink);
            if ($nextimg > $numimgs) {
                if ($opt{navwrap}) {
                    $nextimg = 1;
                    $nextlink = qq(<a href="$self->{script}?album=$album&image=1">$opt{nexttext}</a>);
                } else {
                    $nextimg = undef;
                    $prevlink = qq($opt{nexttext});
                }
            } else {
                $nextlink = qq(<a href="$self->{script}?album=$album&image=$nextimg">$opt{nexttext}</a>);
            }

            # Setup links just like for pages
            if ($previmg < 1){
                if ($opt{navwrap}) {
                    $previmg = $numimgs;
                    $prevlink = qq(<a href="$self->{script}?album=$album&image=$numimgs">$opt{prevtext}</a>);
                } else {
                    $previmg = undef;
                    $prevlink = qq($opt{prevtext});
                }
            } else {
                $prevlink = qq(<a href="$self->{script}?album=$album&image=$previmg">$opt{prevtext}</a>);
            }

            # Print out slideshow stuff
            if ($self->{cgi}->param('slideshow') && $nextimg && $self->{cgi}->param('submit') ne 'Stop') {
                my $sec = $self->{cgi}->param('slideshow');
                push @print, qq(<meta http-equiv="refresh" content="$sec; )
                           . qq(url=$self->{script}?album=$album&image=$nextimg&slideshow=$sec">);
            }

            # Figure out what page we'd be one
            my $page = int(($img - 1) / $opt{eachpage}) + 1;

            # Now print out HTML, nice and simple
            my $caption = $data->[2] ? "<p>$data->[2]" : '';
            push @print, <<EOF;
<h3>$name - Image $img of $numimgs</h3>
<b>$prevlink | <a href="$self->{script}?album=$album&page=$page">Back to Page $page</a> | $nextlink </b><p>
<a href="$albumdir/$data->[1]"><img src="$albumdir/$data->[1]"></a>$caption
EOF

        } else {

            # Print the whole album w/ thumbs out
            my $numpages = _round @{$self->{data}} / $opt{eachpage};

            # Setup a couple vars and a title
            my $page = 0;
            unless ($page = $self->{cgi}->param('page')) {
                if (-f "$albumdir/$opt{intro}") {
                    if (open INTRO, "<$albumdir/$opt{intro}") {
                        push @print, '</div>', <INTRO>;
                        push @print, _tag('div', $opt{div}),
                            qq(<p><a href="$self->{script}?album=$album&page=1"><b>See the Pictures</b></a></div>\n);
                        push @print, $close;
                        close INTRO;
                        return wantarray ? @print : join '', @print;
                    } else {
                        carp "[HTML::PhotoAlbum] Warning: $albumdir/$opt{intro} present but unreadable: $!";
                    }
                }
                $page = 1;
            }

            $self->error_404("Sorry, we could not find page $page of the $name photo album.")
                unless $page >= 0 && $page <= $numpages;
            push @print, "\n<h3>$name - Page $page of $numpages</h3>\n";

            # Print a navbar?
            if ($opt{navbar}) {

                # We setup our pages, tweak our page CGI param, then generate query_string
                my $nextpage = $page + 1;
                my $prevpage = $page - 1;
                #push @print, "<!-- numpages = $numpages -->\n";

                # Sanity check: See if the previous page is less than 1,
                my($prevlink, $nextlink);
                if ($page - 1 > 0) {
                    $prevlink = qq(<a href="$self->{script}?album=$album&page=$prevpage">$opt{prevtext}</a>);
                } elsif ($opt{navwrap}) {
                    $prevlink = qq(<a href="$self->{script}?album=$album&page=$numpages">$opt{prevtext}</a>);
                } else {
                    $prevlink = qq($opt{prevtext});
                }

                # And if the next page is bigger than how many we have
                if ($page == $numpages) {
                    if ($opt{navwrap}) {
                        $nextlink = qq(<a href="$self->{script}?album=$album&page=1">$opt{nexttext}</a>); 
                    } else {
                        $nextlink = qq($opt{nexttext});
                    }
                } else {
                    $nextlink = qq(<a href="$self->{script}?album=$album&page=$nextpage">$opt{nexttext}</a>); 
                }

                # Finally, push together a list of page numbers
                my $pagelinks;
                for (my $i=1; $i <= $numpages; $i++) {
                    #push @print, "<!-- look for " . ($opt{eachpage} * $i - 1) . " -->\n";
                    if ($i == $page) {
                        $pagelinks .= qq( | $i);
                    } else {
                        $pagelinks .= qq( | <a href="$self->{script}?album=$album&page=$i">$i</a>);
                    }
                }

                push @print, qq(<b>$prevlink $pagelinks | $nextlink </b><p>\n);
            }

            # Browsers should always render tables correctly based
            # on the individual <td> and <tr> widths
            push @print, _tag('table', $opt{table});

            # Here we take a slice of the data based on our
            # page and eachpage definitions
            my $first_img = $opt{eachpage} * ($page - 1) + 1;
            my $last_img = $opt{eachpage} + $first_img - 1;
            #push @print, "<!-- first_img = $first_img, last_img = $last_img -->\n";

            my $i = 0;
            for my $data ( @{$self->{data}}[$first_img .. $last_img] ) {
                push @print, _tag('tr', $opt{tr}), "\n" if $i % $opt{eachrow} == 0;

                # The for loop w/ slice will autoviv array elements if needed, so
                # we must explicitly check to see if there's really any data first
                if (ref $data) {
                    my $n = $first_img + $i;
                    my $thlink = $data->[2] || "$opt{linktext} $n";
                    my $caption = '';
                    if ($data->[0]) {
                        $opt{img}{src} = $data->[0]; 
                        $thlink = _tag('img', $opt{img});
                        $caption = qq(<br><font size="-1">$data->[2]</font>);
                    }
                    # This is the td for each image w/ a link to display
                    push @print, _tag('td', $opt{td}), _tag('font', $opt{font});

                    # We change from an HTML nav page to a direct img link based on navfull
                    my $imglink = $opt{navfull}
                                    ? qq(<a href="$self->{script}?album=$album&image=$n">)
                                    : qq(<a href="$albumdir/$data->[1]">);

                    # Create the link
                    push @print, qq($imglink$thlink</a>$caption</font></td>\n);
                } else {
                    push @print, qq(<td><!-- image $i not found --></td>\n);
                }
                $i++;
                push @print, "</tr>" if $i % $opt{eachrow} == 0;
            }

            # Close image table
            push @print, "</table>\n";

        } # end if for $image param

        # Add on things at the end for slideshow
        my $sliform = CGI::FormBuilder->new(fields => { slideshow => 3 }, keepextras => 1);
        $sliform->field(name => 'slideshow', comment => 'seconds', size => 2);
        push @print, $sliform->render(reset => 0, submit => [qw/Start Stop/]);

    }   # end huge if for $album

    # Close the document w/ a source note
    push @print, "\n", $close;

    return wantarray ? @print : join '', @print;
}

=head2 selected

This returns the name of the selected album, allowing you to
conditionally change its layout:

    if ($album->selected eq 'sf_trip') { ... }

If no album is selected, this will return undef.

=cut

sub selected {
    my $self = shift;
    return $self->{cgi}->param('album');
}

=head1 EXAMPLE

Here's a simple photo album script that I use to manage my albums.
Note that it dynamically builds a list of the albums from a file in 
the top-level albums directory, since I have a lot of albums.

    #!/usr/bin/perl -w

    use HTML::PhotoAlbum;

    my $album = HTML::PhotoAlbum->new(
                      albums => 'albums.txt',
                      nexttext => '&gt;&gt;',   # >>
                      prevtext => '&lt;&lt;',   # <<
                      font_color => 'white',
                      body => {
                           bgcolor => 'black',
                           link  => 'orange',
                           alink => 'silver',
                           vlink => 'gray',
                      },
                      table_width => '95%'
                );



    if ($album->selected eq 'sf_trip') {
        # Larger images in this album
        print $album->render(header  => 1, table_width => '100%',
                             eachrow => 3, eachpage => 9);
    } else {
        # All other albums standard
        print $album->render(header => 1, table_width => '100%');
    }

If you put this script in C<~/public_html/albums>, then people would
access your photo albums via C<http://yourserver/~yourname/albums>.
Easy enough.

=head1 NOTES

On an error condition, a 404 Not Found page will be printed in the browser.
If the error is suspected to be the programmer's fault, a message will be
printed to the error_log. Some errors are not logged because they can be
triggered by users trying to screw around (specifying a large page number
or image number, for example).

There are a number of other photo albums on CPAN that are worth looking
at, and the PHP "Gallery" alternative is nice too (albeit SLOW).

=head1 VERSION

$Id: PhotoAlbum.pm,v 1.20 2005/07/13 20:48:42 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2000-2005, Nathan Wiger, <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of the
GNU General Public License, or the Artistic License, copies of which
should have accompanied your Perl kit.

=cut

