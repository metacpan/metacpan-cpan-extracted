package Mail::Pyzor::SHA;

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use constant _ORDER => ( 'Digest::SHA1', 'Digest::SHA' );

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
