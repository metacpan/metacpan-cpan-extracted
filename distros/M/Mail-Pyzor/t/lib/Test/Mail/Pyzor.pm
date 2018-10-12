package Test::Mail::Pyzor;

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;
use autodie;

use FindBin;

use File::Slurp;
use File::Which;

use constant _SUPPORT_DIR => "$FindBin::Bin/support";
use constant _EMAILS_DIR  => _SUPPORT_DIR() . '/digest_email';

# cf. https://github.com/SpamExperts/pyzor/blob/master/tests/functional/test_digest.py
use constant EMAIL_DIGEST => {
    pyzor_functional_bad_encoding => '2b4dbf2fb521edd21d997f3f04b1c7155ba91fff',

    # sha1('Thisisatestmailing')
    pyzor_functional_text_attachment_w_contenttype_null => 'faaaf3e31637eb4c5bfeb0a915e5cc48e4221ebb',
    pyzor_functional_text_attachment_w_multiple_nulls   => 'faaaf3e31637eb4c5bfeb0a915e5cc48e4221ebb',
    pyzor_functional_text_attachment_w_null             => 'faaaf3e31637eb4c5bfeb0a915e5cc48e4221ebb',
};

sub get_test_emails_hr {
    my %name_content;

    opendir my $dh, _EMAILS_DIR();
    while (my $name = readdir $dh) {
        next if $name =~ m<\A\.>;

        $name_content{$name} = \(q<> . File::Slurp::read_file( _EMAILS_DIR() . "/$name" ));
    }

    return \%name_content;
}

my $_python_bin;

sub python_bin {
    return $_python_bin ||= File::Which::which('python');
}

my $_python_can_load_pyzor;

sub python_can_load_pyzor {
    if (!defined $_python_can_load_pyzor) {
        if ( my $python = python_bin() ) {
            system($python, '-c', 'import pyzor');
            $_python_can_load_pyzor = !$?;
        }
        else {
            print STDERR "This process cannot find “python”.\n";
            $_python_can_load_pyzor = 0;
        }
    }

    return $_python_can_load_pyzor;
}

sub dump {
    my (@stuff) = @_;

    Data::Dumper->new( \@stuff )->Useqq(1)->Indent(0)->Terse(1)->Dump();
}

1;
