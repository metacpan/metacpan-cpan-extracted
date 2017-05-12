sub main::abort {
    return <<'EOABRT';
*** WOAH! ***
To run the tests, I need to make a copy of the included file Dream.mp3 to
also test the write-abilities of MP3::Mplib. But I could not create this copy.

You can do this manually by creating this copy:
    
    # UNIXish systems
    cp t/test.mp3 t/test_cp.mp3

    # Windows
    copy t\test.mp3 t\test_cp.mp3
EOABRT
}

sub main::do_copy {

    my $orig = File::Spec->catfile("t", "test.mp3");
    my $copy = File::Spec->catfile("t", "test_cp.mp3");

    if (-s $orig == -s $copy) {
        return 1;
    }

    # make copy of mp3
    open MP3ORIG, $orig or do {
        diag(abort());
        return 0;
    };
    open MP3COPY, ">$copy" or do {
        diag(abort());
        return 0;
    };

    binmode MP3ORIG; binmode MP3COPY;
    print MP3COPY do { local $/; <MP3ORIG> };
    close MP3ORIG;
    close MP3COPY;

    if (-s $orig == -s $copy) {
        return 1;
    } else {
        diag(<<'EOABRT');
    ** WOAH! **
    To run the tests, I need to make a copy of the included file test.mp3 to
    also test the write-abilities of MP3::Mplib. Even though I could create 
    *some* copy, the copy does not appear to be an identical copy (the size 
    differed).

    Please try to fix this manually by using some means of your operating 
    system to do the copy:

    # UNIXish systems
    cp t/test.mp3 t/test_cp.mp3

    # Windows
    copy t\test.mp3 t\test_cp.mp3
EOABRT
        return 0;
    }
}

do_copy();

