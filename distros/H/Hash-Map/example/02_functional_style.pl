#!perl ## no critic (TidyCode)
use strict;
use warnings;

use Hash::Map qw(hash_map);
require Data::Dumper;

our $VERSION = '0.001';

# example form data
my $form = { qw(
    country      Germany
    country_code D
    city         Examplecity
    zip          01234
    street       Examplestreet
    first_name   Steffen
    family_name  Winkler
) };

# example user object
my $user = {
    account => ( bless { account  => 'STEFFENW' }, __PACKAGE__ ),
};
sub get_account { my $self = shift; return $self->{account} }

# example mail data
my $mail = {
    name    => 'Steffen Winkler',
    address => 'steffenw@example.com',
    subject => 'Example',
};

my %hash_map = (
    hash_map(
        # source_ref,
        $form,
        # copy_keys
        [ qw(street city country_code) ],
        {
            # modify
            country_code => sub {
                return $_ eq 'D' ? 'DE' : $_;
            },
            # map_keys
            zip => 'zip_code',
        },
    ),
    # merge_hash
    name => "$form->{first_name} $form->{family_name}",
    hash_map(
        $user,
        # copy_keys
        [ qw(account) ],
        {
            # modify
            account => sub {
                return $_->get_account;
            },
        },
    ),
    hash_map(
        $mail,
        [
            # copy_keys
            qw(name address),
            sub {
                return "mail_$_";
            },
        ],
    ),
);

() = print { *STDOUT } Data::Dumper ## no critic (LongChainsOfMethodCalls)
    ->new([\%hash_map], ['hash_map'])
    ->Indent(1)
    ->Sortkeys(1)
    ->Dump;

# $Id$
