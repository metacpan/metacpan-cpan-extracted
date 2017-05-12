#!/usr/bin/perl

use lib 'lib', '../lib';

# Use module and create needed exceptions
use Exception::Base
    'Exception::IO',
    'Exception::FileNotFound' => {
        isa => 'Exception::IO',
        has => 'filename',
        string_attributes => [ 'message', 'filename' ],
    };

sub func1 {
    eval {
        my $filename = '/notfound';
        open my $fh, $filename
            or throw Exception::FileNotFound
                     message=>'Can not open file', filename=>$filename;
    };

    if ($@) {
        my $e = Exception::IO->catch;
        # $e is an exception object for sure, no need to check if is blessed
        warn "*** Exception caught";
        if ($e->isa('Exception::FileNotFound')) {
            warn "*** Exception caught for file " . $e->filename;
        }
        # rethrow the exception
        warn "*** Rethrow exception";
        $e->throw;
    }
}

sub func2 {
    func1(1);
}

sub func3 {
    func2(2,2);
}

func3(3,3,3);
