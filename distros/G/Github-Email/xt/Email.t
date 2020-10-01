use strict;
use warnings;

use Test::More tests => 7;

use_ok('Email::Valid');
use_ok( 'LWP::Online', qw(online) );
use_ok('LWP::UserAgent');
use_ok('JSON');
use_ok( 'List::MoreUtils', qw(uniq) );
use_ok('Github::Email');

sub get_emails {
    my @addresses = Github::Email::get_emails('momozor');

    for my $address (@addresses) {
        return 1 if $address eq 'momozor4@gmail.com';
    }
}

SKIP:
{
    skip "No internet connection", 1 unless online();

    ok( get_emails, 'Momozor\'s email is equal to momozor4@gmail.com' );
}

done_testing;
