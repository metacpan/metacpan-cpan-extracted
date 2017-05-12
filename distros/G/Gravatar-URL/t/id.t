#!/usr/bin/perl -w

use strict;

use Test::More 'no_plan';

BEGIN { use_ok "Gravatar::URL" }

my %email2id = (
    'alfred@example.com'                => '6ffc501bf3b215384ea3abd3b6026735',
    'whatever@wherever.whichever'       => 'a60fc0828e808b9a6a9d50f1792240c8',
    'PHRED@cpan.org'                    => 'c18b1af66a7f62015ecc26707a1321b9',
    'iHaveAn@email.com',                => '3b3be63a4c2a439b013787725dfce802',
);

for my $email (keys %email2id) {
    my $id = $email2id{$email};

    is gravatar_id( $email )            => $id, "$email";
    is gravatar_id( lc $email )         => $id, "lc $email";
    is gravatar_id( uc $email )         => $id, "uc $email";
    is gravatar_id( ucfirst $email )    => $id, "ucfirst $email";
}
