package EPUB::Parser::Util::EpubLoad;
use strict;
use warnings;
use Carp;
use Archive::Zip qw/:ERROR_CODES/;

sub load_file {
    my $class = shift;
    my $args  = shift || {};
    my $file_path = $args->{file_path} or croak "mandatory parameter 'file_path'";

    my $zip = Archive::Zip->new();
    ( $zip->read( $file_path ) == AZ_OK() ) or die 'read error';

    return $zip;
}

sub load_binary {
    my $class = shift;
    my $args  = shift || {};
    my $zip_data = $args->{data} or croak "mandatory parameter 'data'";

    require IO::String;
    my $zip = Archive::Zip->new();
    ( $zip->readFromFileHandle( IO::String->new($zip_data) ) == AZ_OK() ) or die 'open error';

    return $zip;
}



1;
