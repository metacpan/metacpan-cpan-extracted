package MailPyzorTestBase;

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# Apache 2.0 license.

use strict;
use warnings;

use parent 'Test::Class';

use Test::More;

use Test::Mail::Pyzor ();

sub _skip_if_no_python_pyzor {
    my ($self, $num_tests) = @_;

    if (!Test::Mail::Pyzor::python_can_load_pyzor()) {
        my $msg;

        if ( my $bin = Test::Mail::Pyzor::python_bin() ) {
            $msg = "“$bin” can’t load pyzor.";
        }
        else {
            $msg = "No “python” binary found.";
        }

        skip $msg, $num_tests;
    }

    return;
}

1;
