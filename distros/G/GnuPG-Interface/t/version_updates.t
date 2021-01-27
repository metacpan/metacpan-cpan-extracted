#!/usr/bin/perl -w

use strict;

use lib './t';
use MyTest;
use MyTestSpecific;

TEST
{
    my $gpg = GnuPG::Interface->new(call => './test/fake-gpg-v1');
    return ($gpg->version() eq '1.4.23');
};


TEST
{
    my $gpg = GnuPG::Interface->new(call => './test/fake-gpg-v2');
    return ($gpg->version() eq '2.2.12');
};

TEST
{
    my $gpg = GnuPG::Interface->new(call => './test/fake-gpg-v1');
    my $v1 = $gpg->version();
    $gpg->call('./test/fake-gpg-v2');
    my $v2 = $gpg->version();

    return ($v1 eq '1.4.23' && $v2 eq '2.2.12');
}
