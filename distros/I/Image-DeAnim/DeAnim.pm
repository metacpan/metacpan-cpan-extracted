package Image::DeAnim;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK $gif_in $gif_out);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(gif);

$VERSION = '0.02';

sub gif {
    my $nullstr     = "";
    my $nullstr_ref = \$nullstr;

    my $gif_in_ref = shift || return \$nullstr_ref;

    $gif_out = "";
    $gif_in = $$gif_in_ref;
 
    # header
    my $header = &safe_read(6);
    unless ($header =~ /^GIF\d\d[a-z]/) {
        warn "not a GIF header: $header";
        return $nullstr_ref;
    }
    $gif_out .= "GIF89a";
 
# logical screen description
    my $ls_desc = &safe_read(7);
    my ($ls_size, $ls_flag, $ls_misc) = unpack("A4 C A2", $ls_desc);
    $gif_out .= $ls_desc;
    
    if ($ls_flag & 0x80) { # check for global color table
        $gif_out .= &get_colormap($ls_flag & 0x07);
    }
    
    my $data_block;
    
    while (1) {
        my $ext_label;
        my $block_label = &safe_read(1);
 
        # if we detect end of file marker, $gif_out .= last block and return
        if ($block_label eq "\x3b") {
            $gif_out .= $data_block . "\x3b";
            return \$gif_out;
        }
 
        if ($block_label eq "\x2c") { # found image descriptor
            $data_block = "\x2c" . &get_image;
            next;
        }
 
        unless ($block_label eq "\x21") {
            warn "Illegal block label found: " . ord($block_label);
            return $nullstr_ref;
        }
 
        $ext_label = &safe_read(1);
        if ($ext_label eq "\xf9") { # graphic control; keep and then get image
            $data_block = "\x21\xf9" . &safe_read(6);
            unless (&safe_read(1) eq "\x2c") {
                warn "graphic control extension not followed by image";
                return $nullstr_ref;
            }
            $data_block .= "\x2c" . &get_image;
            next;
        }
 
        if ($ext_label eq "\xff") { # application extension; skip
            &safe_read(12);
            &get_data_block;
        } elsif ($ext_label eq "\xfe") { # comment extension; skip
            &get_data_block;
        } elsif ($ext_label eq "\x01") { # plain text extension; skip
            &safe_read(13);
            &get_data_block;
        } else {
            warn "Illegal extension label found: " . ord($ext_label);
            return $nullstr_ref;
        }
    }
    
    warn "exit abnormally";
    return $nullstr_ref;
}
##########################################################################
 
sub safe_read {
    # read from $fh_in with error checking.
    my $len = shift;
    my $buf;

    unless (length($gif_in) >= $len) {
        die "read error: unsafe read";
    }

    ($buf, $gif_in) = unpack("a$len a*", $gif_in);
     
    return $buf;
}
 
sub get_data_block {
    my ($byte, $size);
    my $block = "";
 
    do {
        $byte = &safe_read(1);
        $size = ord($byte);
 
        if ($size) {
            $block .= $byte . &safe_read($size);
        }
    } while ($size);
 
    return $block . "\x00";
}    
 
sub get_colormap {
    my $size = shift;
    
    my $bytes = 3 * 2**($size+1);
    return &safe_read($bytes);
}
 
sub get_image {
    my $id_bytes = &safe_read(9);
    my $block = $id_bytes;
 
    my ($id_info, $id_flag) = unpack("A8 C", $id_bytes);
    if ($id_flag & 0x80) {
        $block .= &get_colormap($id_flag & 0x07);
    }
 
    $block .= &safe_read(1); # LZW minimum code size
    $block .= &get_data_block;
 
    return $block;
}

1;
__END__

=head1 NAME

Image::DeAnim - create static GIF file from animated GIF

=head1 SYNOPSIS

   use Image::DeAnim;
   
   open(G,"animated.gif") or die;
   undef $/;
   $gif = <G>;
   $newgif = Image::DeAnim::gif(\$gif); 
   print $$newgif;

   # Using HTTP::Response

   if ($self -> content_type eq 'image/gif') {
      my $gif = $self -> content;
      $self -> content (${&Image::DeAnim::gif(\$gif)});
   }

=head1 DESCRIPTION

Image::DeAnim::gif takes a reference to a scalar conatining a GIF
image, and returns a scalar reference to a filtered GIF image.  If the
input is an animated GIF, the output will be a static GIF of the last
frame of the animation.  If the input is already a static GIF, the
output file should be (mostly) identical.

Image::DeAnim is intended for use with a HTTP proxy server, in order to
de-animate GIFs before they reach the browser window.

=head1 BUGS

Currently only outputs last frame.  Options for first/other shouldn't
be too difficult, though.

If the last image of the animation is not the same size as the first,
the remaining image is blacked out (no overlay).  It doesn't bother
me, but it may for others.

Doesn't work with cached animations, although as images work their way
out of the cache, this shouldn't be a problem.

Not very Perl-ish; can probably use lots of fixing, and better
documentation.  OO in place of references seems to be the next logical
step.

=head1 AUTHOR

Ken MacFarlane, <ksm+cpan@universal.dca.net>

=head1 COPYRIGHT

Copyright 1999.  This program may be distributed under the Perl
Artistic License.

=cut
