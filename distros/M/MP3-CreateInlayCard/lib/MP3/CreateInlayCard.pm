package MP3::CreateInlayCard;

our $VERSION = '0.06';

# $Id: CreateInlayCard.pm 535 2009-02-13 23:26:32Z davidp $

use strict;
use warnings;
use File::Find::Rule;
use Music::Tag;
use Cwd;
use HTML::Template;

=head1 NAME

MP3::CreateInlayCard - create a CD inlay label for a directory of MP3 files

=head1 SYNOPSIS

    use MP3::CreateInlayCard;
    print MP3::CreateInlayCard::create_inlay(
        {dir => $dir, template => $template});
    
    # $dir is the directory containing the MP3 files.  If not specified, we'll
    # use the current directory.
    # $template is the filename of a template which HTML::Template should
    # read and populate. Alternatively, it can be a scalar reference, in which
    # case it will be taken to be the template contents to use.  If it's not
    # supplied, a simple default built-in template will be used.
    
    # If you can't be bothered to write a script to call this module, use
    # 'makeinlay.pl' distributed with this package, or just do:
    perl -MMP3::CreateInlayCard -e \
        "print MP3::CreateInlayCard(create_inlay({ (see example above)  });"
        
    # If you're in the directory containing the MP3's, and you want to use the
    # built-in default template, just supply an empty hashref:
    perl -MMP3::CreateInlayCard \
        -e "print MP3::CreateInlayCard(create_inlay({});"
        
    # or, more easily, use the eg/createinlay.pl script supplied with this
    # module.  (Perhaps copy it to somewhere in your path and rename it to
    # 'createinlay', so you can just change directory into the appropriate
    # place and type 'createinlay').
    
    
=head1 DESCRIPTION

Reads a directory of MP3s, and produces a HTML file you can print for a nice
"inlay" for a CD case.  Useful if you're burning a directory full of MP3s
to a CD, and want an inlay label created for you.

=cut


=head1 FUNCTIONS

=over 4

=item create_inlay

Go through the specified directory and produce the inlay.

Takes a hashref of:

=over 4

=item I<dir>

The directory containing the MP3 files

=item I<template> 

A scalar containing the filename of a template which HTML::Template should
read and populate. Alternatively, it can be a scalar reference, in which
case it will be taken to be the template contents to use.  If it's not
supplied, a simple default built-in template will be used.

=back

=cut

sub create_inlay {
    
    my $params = shift;
    if (!$params || ref $params ne 'HASH') {
        die "create_inlay() not passed hashref of params";
    }
    my $startdir = $params->{dir} || getcwd;
    
    if (!-d $startdir) {
        die "$startdir is not a directory";
    }

    
    my @files = File::Find::Rule->file()->name('*.mp3')->in($startdir);
    
    my $track = 1;
    my @tracks;
    
    # remember which artists and titles we saw, so we can work out whether this
    # is a compilation of various artists, a complete album by one artist, or
    # just a random assortment of tracks.
    my %artists;
    my %albums;
    
    for my $file (@files) {

        my $tags = Music::Tag->new($file, { quiet => 1 });
        $tags->get_tag or warn "Error reading tags from $file" and next;

        my $length = sprintf('%02d',$tags->secs / 60) . ':'
            . sprintf('%02d',$tags->secs % 60);

        push @tracks, {
            track => $track,
            title => $params->{prettify} ?
                _prettify($tags->title()) : $tags->title(),
            artist => $params->{pretify} ?
                _prettify($tags->artist()) : $tags->artist(),
            length => $length,
        };

        $artists{ $tags->artist() }++;
        $albums{  $tags->album()  }++;
        $track++;
    }

    # open the html template (this code is rather crufty, refactor someday)
    my $template;
    my $template_opts = { die_on_bad_params => 0 };
    
    if ($params->{template}) {
        if (ref $params->{template} eq 'SCALAR') {
            # we've been given the template content:
            $template = HTML::Template->new(
                scalarref => $params->{template},
                die_on_bad_params => 0
            );
        } else {
            # it must be the filename of a template to use:
            if (-e $params->{template}) {
                $template = HTML::Template->new(
                    filename => $params->{template},
                    die_on_bad_params => 0
                );
            } else {
                die "Failed to open $params->{template} $!";
            }
        }
    } else {
        # no template supplied, so use our default built-in one:
        $template = HTML::Template->new(
            scalarref => \$MP3::CreateInlayCard::default_template,
            die_on_bad_params => 0
        );
    }
    
    if (!$template) {
        die "Uh-oh.. failed to create HTML::Template";
    }
    
    # fill in some parameters
    $template->param(tracks => sort { $a->{track} cmp $b->{track} } \@tracks);
    $template->param(artist => (scalar keys %artists == 1)?  
        (keys %artists)[0] : 'Various Artists');
    $template->param(album => (scalar keys %albums == 1)?
        (keys %albums)[0]  : 'Compilation');
        
    # send the obligatory Content-Type and print the template output
    return $template->output;

} # end of sub create_inlay

=back

=cut

# return a "prettified" version of an artist/title - currently just converts
# to title case, might support more options in future.  Of course, this isn't
# always a good thing, as there are some artist names / song names which are
# supposed to be in all capitals, or "officially" should be all in lowercase
# etc, and will choke on double-barreled names "Dave Two-Names" or Scottish
# names ("Johnny McScottish" or "Old MacDonald").
sub _prettify { join ' ', map { ucfirst $_ } split /\s/, lc shift; }


our $default_template = <<TEMPLATE;
<!-- Created by MP3::CreateInlayCard $VERSION (using default template) -->
<html>
<head>
<style>
BODY, P, TD {
	font-family: Verdana, Helvetica, Arial, sans-serif; font-size: 10px;
	}
	
#holder {
    position: absolute;       width: 12cm;      height: 12cm; 
    border: 1px dashed gray;
}

H1 {
    font-size: 16px;  font-weight: bold;
}
</style>
<title><tmpl_var name="artist"> - <tmpl_var name="album"></title>
</head>
<body>
<div id="holder">

<h1><tmpl_var name="artist"> - <tmpl_var name="album"></h1>

<table width="100%" cellspacing="2">

<tmpl_loop name="tracks">
    <tr>
	<td><tmpl_var name="track"></td>
	<td><tmpl_var name="title"></td>
	<td><tmpl_var name="artist"></td>
	<td><tmpl_var name="length"></td>
    </tr>
</tmpl_loop>

</table>

</body>
</html>
TEMPLATE

1;
__END__

=head1 BUGS

Probably.  If you find any, let me know - raising a ticket on rt.cpan.org is
the recommended way, or you can mail me directly if you prefer.

This module assumes that tracks will be written to the CD in the order they
appear in the directory.



=head1 AUTHOR

David Precious, E<lt>davidp@preshweb.co.ukE<gt>

All bug reports, feature requests, patches etc welcome.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.
