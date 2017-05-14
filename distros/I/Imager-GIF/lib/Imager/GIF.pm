use strict;
use warnings;
use 5.010;
use Imager;
package Imager::GIF;
use Carp 'croak';

# ABSTRACT: a handy module for animated GIF processing

sub new {
    my ($class, @args) = @_;
    bless { images => \@args }, $class;
}

sub read {
    my ($class, %args) = @_;
    croak "No filename specified" unless $args{file};
    my @images = Imager->read_multi(file => $args{file});
    return Imager::GIF->new(@images);
}

sub write {
    my ($self, $file) = @_;
    my $img = Imager->new;
    $img->write_multi({ file => $file, type => 'gif' }, @{$self->{images}})
        or die $img->errstr;
}

sub scale {
    my ($self, %args) = @_;
    my $ratio = $args{scalefactor} // 1;
    $self->_mangle(sub {
        my $img = shift;
        my $ret = $img->scale(%args, qtype => 'mixing');
        my $h = $img->tags(name => 'gif_screen_height');
        my $w = $img->tags(name => 'gif_screen_width');
        unless ($ratio) {
            if (defined $args{xpixels}) {
                $ratio = $args{xpixels} / $w;
            }
            if (defined $args{ypixels}) {
                $ratio = $args{ypixels} / $h;
            }
        }
        $ret->settag(name => 'gif_left',
                     value => int($ratio * $img->tags(name => 'gif_left')));
        $ret->settag(name => 'gif_top',
                     value => int($ratio * $img->tags(name => 'gif_top')));
        $ret->settag(name => 'gif_screen_width',  value => int($ratio * $w));
        $ret->settag(name => 'gif_screen_height', value => int($ratio * $h));
        return $ret;
    });
}

sub _mangle {
    my ($self, $action) = @_;
    my @out;
    for my $in (@{$self->{images}}) {
        my $mangled = $action->($in);
        for my $tag (qw/gif_delay gif_user_input gif_loop gif_disposal/) {
            $mangled->settag(name => $tag, value => $in->tags(name => $tag));
        }
        if ($in->tags(name => 'gif_local_map')) {
            $mangled->settag(name => 'gif_local_map', value => 1);
        }
        push @out, $mangled;
    }
    return Imager::GIF->new(@out);
}

1;

__END__

=pod

=head1 NAME

Imager::GIF - a handy module for animated GIF processing

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $sonic = Imager::GIF->new(file => 'sonic.gif');
    my $small_sonic = $sonic->scale(scalefactor => 0.5);
    $small_sonic->write(file => 'small_sonic.gif');

=head1 DESCRIPTION

This module will attempt to Do The Right Things regarding transformations on
animated gifs.

Imager, as compared to Imagemagick is far less magical; animated gifs
aren't treated in any special way, they're just the sequence of ordinary
images. In order to perform any transformation on them (scaling etc.)
one has to transform all the images separately. Besides, transforming
images removes all the metadata from them, which breaks animated gifs
even more. This module attempts to fix it and make it easy to transform
animated gifs without breaking them.

=head1 METHODS

=over 4

=item C<new(@images)> (class method)

Create a new Imager::GIF object from a sequence of images. One would
probably want to use C<read> method instead.

=item C<< read(file => $filename) >> (class method)

Reads an animated gif from the specified location, returns a newly
created Imager::GIF object.

=item C<< write(file => $filename) >>

Writes the invocant object to a speficied file.

=item C<scale()>

Works exactly like C<Imager->scale>, but does the right thing for
animated gifs.

=back

=head1 TODO

Implement the rest of the transformations (cropping, rotating etc).

=head1 CAVEATS

C<scale()>, given some weird combination of C<xpixels> and/or C<ypixels>
may produce funny-looking images. Using C<scalefactor> is usually safer.

=head1 AUTHOR

Tadeusz Sośnierz <tsosnierz@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Opera Software ASA.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
