package Image::TextMode::Loader;

use strict;
use warnings;

use Module::Pluggable::Object;
use Image::TextMode::SAUCE;

use Carp 'croak';

sub load {
    my ( $self, @files ) = @_;
    my @result;

    my $base    = 'Image::TextMode::Format';
    my $default = 'Image::TextMode::Format::ANSI';
    my $finder  = Module::Pluggable::Object->new(
        search_path => [ $base ],
        require     => 1
    );

    my %exts;
    for my $format ( $finder->plugins ) {
        $exts{ $_ } = $format for $format->extensions;
    }

    for my $file ( @files ) {
        my $read_options = {};
        if ( ref $file ) {
            ( $file, $read_options ) = @$file;
        }

        my ( $ext ) = $file =~ m{([^.]+?)$}s;
        $ext = lc $ext;
        my $format = $exts{ $ext } || $default;

# if we get ANSI, we need to see if it's ansimation or not from the SAUCE data.
        if ( $format eq $default ) {
            my $sauce = Image::TextMode::SAUCE->new;
            open( my $fh, '<', $file )
                or croak "Unable to read SAUCE data for '$file': $!";
            $sauce->read( $fh );
            close( $fh ) or croak "Unable to close '$file': $!";
            if (   $sauce->has_sauce
                && $sauce->datatype
                && $sauce->filetype
                && $sauce->filetype eq 'ANSiMation' )
            {
                $format = 'Image::TextMode::Format::ANSIMation';
            }
        }

        my $image = $format->new;
        $image->read( $file, $read_options );
        push @result, $image;
    }

    return wantarray ? @result : $result[ 0 ];
}

=head1 NAME

Image::TextMode::Loader - Load text mode images by best-guess

=head1 SYNOPSIS

    my $img = Image::TextMode::Loader->load( $filename );

=head1 DESCRIPTION

This module allows you to load a set of images without having to explicitly
specify the format before-hand.

=head1 METHODS

=head2 load( @files )

Attempts to load C<@files> based on some filetype guessing. Returns the first
result in scalar context.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
