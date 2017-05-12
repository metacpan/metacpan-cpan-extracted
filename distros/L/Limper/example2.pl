#!/usr/bin/env perl

# more complex example returning JSON or static content

use 5.10.0;
use strict;
use warnings;

use Limper;
use File::Slurp;
use JSON;

my $document_root = './public/';

my $static = sub {
    my $file = request->{uri};
    $file =~ s{^/}{$document_root};
    if ($file =~ qr{/\.\./}) {
        status 403;
        return 'lolnope';
    }
    if (-e $file and -r $file and -f $file) {
        $file =~ /\.html$/ and headers 'Content-Type' => 'text/html';
        scalar read_file $file;
    } elsif (-e $file and -r $file and -d $file) {
        opendir my($dh), $file;
        my @files = sort grep { !/^\./ } readdir $dh;
        @files = map { "<a href=\"$_\">$_</a><br>" } @files;
        headers 'Content-Type' => 'text/html';
        join "\n", '<html><head><title>Directory listing of ' . request->{uri} . '</title></head><body>', @files, '</body></html>';
    } else {
        status 404;
        'blegh';
    }
};

my $generic = sub {
    headers('Content-Type' => 'application/json');
    JSON->new->encode({status => 'OK'});
};

get qr{^/} => $static;
post qr{^/} => $generic;

limp(LocalAddr => '0.0.0.0');
