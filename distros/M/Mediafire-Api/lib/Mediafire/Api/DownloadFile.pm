package Mediafire::Api::DownloadFile;

use 5.008001;
use utf8;
use strict;
use warnings;
use open qw(:std :utf8);
use Carp qw/croak carp/;
use URI::Escape;
use LWP::UserAgent;
use File::Basename;
use HTTP::Request;
use JSON::XS;

use Mediafire::Api::File;

our $VERSION = '0.01';

my $DEFAULT_BUFF_SIZE           = 1048576;

######################### PRIVATE METHODS ##################################################
my ($getDonwloadLink, $download);

$getDonwloadLink = sub {
    my ($self, $url) = @_;

    my %headers = (
        'Accept'                        => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Encoding'               => 'gzip, deflate',
        'Accept-Language'               => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
        'Cache-Control'                 => 'max-age=0',
        'Upgrade-Insecure-Requests'     => '1',
    );

    my $res = $self->{ua}->get($url, %headers);
    my $code = $res->code;
    if ($code ne '200') {
        croak "Wrong response code on request to '$url'. Code: $code";
    }
    # Find div with download link
    my $content = $res->decoded_content;
    if ($content =~ /<div[^>]+id="download_link".+<a[^>]+aria-label="Download file"[^>]*href="(.+?)".*<\/div>/s) {
        return $1;
    }
    else {
        "Can't found download link";
    }

};

$download = sub {
    my ($self, $download_url, $dest_file) = @_;

    my %headers = (
        ':content_file'                 => $dest_file,
        ':read_size_hint'               => $self->{buff_size},
        'Accept'                        => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Encoding'               => 'gzip, deflate',
        'Accept-Language'               => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
        'Upgrade-Insecure-Requests'     => '1',
    );

    my $res = $self->{ua}->get($download_url, %headers);
    my $code = $res->code;
    if ($code ne '200') {
        croak "Can't download file by url '$download_url' to file '$dest_file'. Code: $code";
    }
    return 1;

};

sub new {
    my ($class, %opt)       = @_;
    my $self = {};
    $self->{ua}             = $opt{-ua}                 // croak "You must specify param '-ua' for method new";
    $self->{buff_size}      = $opt{-buff_size}          // $DEFAULT_BUFF_SIZE;
    bless $self, $class;
    return $self;
}

sub downloadFile {
    my ($self, %opt)        = @_;
    my $mediafire_file      = $opt{-mediafire_file}     // croak "You must specify '-mediafire_file' param";
    my $dest_file           = $opt{-dest_file}          // croak "You must specify '-dest_file' param";

    if (ref($mediafire_file) ne 'Mediafire::Api::File') {
        croak "Param '-mediafire_file' must be Mediafire::Api::File object";
    }

    my $file_name = $mediafire_file->name // croak "Can't get file name of downloaded file";
    my $file_key = $mediafire_file->key // croak "Can't get key from upload file '" . $mediafire_file->name . "'";
    my $download_page_url = 'http://www.mediafire.com/file/' . $file_key . '/' . $file_name . '/file';

    my $download_link = $self->$getDonwloadLink($download_page_url);

    $self->$download($download_link, $dest_file);

}



1;
