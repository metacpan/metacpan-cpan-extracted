package FormValidator::Nested::Validator::File;
use strict;
use warnings;
use utf8;

sub _size {
    my ($req, $name) = @_;

    if ( ref $req eq 'CGI' ) {
        my $file = $req->param($name);
        return unless $file;

        return $req->uploadInfo($file)->{'Content-Length'};
    }
    elsif ( $req->can('upload') ) {
        my $upload = $req->upload($name);
        return unless $upload;

        return $upload->size;
    }
    return;
}


sub max_size {
    my ( $value, $options, $req, $name ) = @_;

    my $size = _size($req, $name);

    if ( !defined($size) ) {
        return 1;
    }

    if ( $size > $options->{max} ) {
        return 0;
    }
    return 1;
}


1;
