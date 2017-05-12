#!/usr/bin/perl
#
# Method Test Login
#

=pod

=head1 NAME

flickr_method_test_echo.pl

a login example for using either OAuth or Old School Flickr

=cut

use warnings;
use strict;
use Flickr::API;
use Getopt::Long;


=pod

=head1 DESCRIPTION

This script uses either the Flickr or OAuth parameters to call
the flickr.test.login method.

=head1 USAGE

  flickr_method_test_login.pl --use_api=[oauth, flickr] \
    --key="24680beef13579feed987654321ddcc6" \
    --secret="de0cafe4feed0242" \
    --token="72157beefcafe3582-1ad0feedface0e60" \
   [--token_secret="33beef1face212d"]

Depending on what you specify with B<--use_api> the flickr.test.login
call will use the appropriate parameter set. The B<--token_secret> is
used by OAuth, but not by the original Flickr.


=cut

my $config = {};
my $api;

my %args;

GetOptions(
    $config,
    'use_api=s',
    'key=s',
    'secret=s',
    'token=s',
    'token_secret=s',
);


=head1 CALL DIFFERENCES

    if ($config->{use_api} =~ m/flickr/i) {
        $api = Flickr::API->new({
            'key'        => $config->{key},
            'secret'     => $config->{secret},
            'auth_token' => $config->{token},
        });

        $args{'api_key'}    = $config->{key};
        $args{'auth_token'} = $config->{token};
    }
    elsif ($config->{use_api} =~ m/oauth/i) {
        $api = Flickr::API->new({
            'consumer_key'    => $config->{key},
            'consumer_secret' => $config->{secret},
            'token'           => $config->{token},
            'token_secret'    => $config->{token_secret},
        });

        $args{'consumer_key'} = $config->{key};
        $args{'token'} = $config->{token};
    }
    else {
        die "\n --use_api must be either 'flickr' or 'oauth' \n";
    }

=cut

if ($config->{use_api} && $config->{use_api} eq 'flickr') {
    $api = Flickr::API->new({
        'key'        => $config->{key},
        'secret'     => $config->{secret},
        'auth_token' => $config->{token},
    });

    $args{'api_key'}    = $config->{key};
    $args{'auth_token'} = $config->{token};
}
elsif ($config->{use_api} && $config->{use_api} eq 'oauth') {
    $api = Flickr::API->new({
        'consumer_key'    => $config->{key},
        'consumer_secret' => $config->{secret},
        'token'           => $config->{token},
        'token_secret'    => $config->{token_secret},
    });

    $args{'consumer_key'} = $config->{key};
    $args{'token'} = $config->{token};
}
else {
    die "\n --use_api must be either 'flickr' or 'oauth'\n";
}


my $response = $api->execute_method('flickr.test.login', \%args);

my $ref = $response->as_hash();

if ($api->is_oauth) {
    print "\nOAuth formated login status: ",$ref->{stat},"\n";
}
else {
    print "\nFlickr formated login status: ",$ref->{stat},"\n";
}

exit;

__END__

=pod

=head1 AUTHOR

Louis B. Moore <lbmoore at cpan.org>  Based on the code in Flickr::API.

=head1 LICENSE AND COPYRIGHT

Copyright 2014, Louis B. Moore

This program is released under the Artistic License 2.0 by The Perl Foundation.

=cut
