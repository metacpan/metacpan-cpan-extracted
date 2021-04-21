package Test::Mail::Pyzor;

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# <@LICENSE>
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# </@LICENSE>
#

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
    return $_python_bin ||= File::Which::which('python') || File::Which::which('python2');
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
