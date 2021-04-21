package Mail::Pyzor::SHA;

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

use constant _ORDER => ( 'Digest::SHA1', 'Digest::SHA' );

our $VERSION = '0.06';

my $_sha_module;

sub _sha_module {
    if ( !$_sha_module ) {

        # First check if one of the modules is loaded.
        if ( my @loaded = grep { $_->can('sha1') } _ORDER ) {
            $_sha_module = $loaded[0];
        }
        else {
            local $@;

            my @modules = _ORDER();

            while ( my $module = shift @modules ) {
                my $path = "$module.pm";
                $path =~ s<::></>g;

                if ( eval { require $path; 1 } ) {
                    $_sha_module = $module;
                    last;
                }
                elsif ( !@modules ) {
                    die;
                }
            }
        }
    }

    return $_sha_module;
}

sub sha1 {
    return _sha_module()->can('sha1')->(@_);
}

sub sha1_hex {
    return _sha_module()->can('sha1_hex')->(@_);
}

1;
