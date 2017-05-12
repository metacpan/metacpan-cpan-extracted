#!/usr/bin/perl -I../lib

use strict;
use warnings;

use Exception::Base (
    'Exception::IO' => { isa => 'Exception::System' },
);

use Fatal::Exception 'Exception::IO' => 'open';


sub func1 {
    my $file = shift;

    open my($fh), $file;
};


sub func2 {
    eval {
        func1('/filenotfound');
    };
    
    if ($@) {
        my $e = Exception::Base->catch;
        if ($e->isa('Exception::IO')) {
            warn "Caught IO exception with error " . $e->errname
               . "\nFull stack trace:\n" . $e->get_caller_stacktrace;
        };
    };
};


func2(2);
