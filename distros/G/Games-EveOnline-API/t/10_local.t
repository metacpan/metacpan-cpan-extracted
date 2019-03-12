#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

{
    package Games::EveOnline::API::LocalTest;
    use Moo;
    extends 'Games::EveOnline::API';

    sub _retrieve_xml {
        my ($self, %args) = @_;

        my $file = $args{path};

        $file =~ s{/}{-}g;
        $file =~ s{\.aspx$}{};

        $file = "t/$file";

        die "Cannot find $file" if !-f $file;

        open( my $fh, '<', $file );
        my $xml = do { local $/; <$fh> };

        return $xml;
    }
}

my $api = Games::EveOnline::API::LocalTest->new(
    character_id => 1234,
);

my $feeds = [qw(
    skill_tree
    ref_types
    sovereignty
    characters
    character_sheet
    skill_in_training
    api_key_info
    account_status
    character_info
    asset_list
    contact_list
    wallet_transactions
    wallet_journal
    mail_lists
    mail_bodies
    mail_messages
    character_name
    character_ids
    station_list
    corporation_sheet
)];

my $args = {
    'mail_bodies'       => { ids => '331477595,331477591' },
    'character_name'    => { ids => '90922771,94701913' },
    'character_ids'     => { names => 'Chips Merkaba, libzar, Krion'},
    'corporation_sheet' => { corporation_id => 1043735888 },
};

foreach my $feed (@$feeds) {
    my $api_data = $api->$feed( %{ $args->{$feed} } );

    my $file = "t/$feed.dump";
    die "Cannot find $file" if !-f $file;

    open( my $fh, '<', $file );
    my $dump = do { local $/; <$fh> };

    my $dump_data = do {
        local $@;
        my $data = eval( $dump );
        die("Unable to eval $feed dump: $@") if !$data;
        $data;
    };

    is_deeply(
        $api_data, $dump_data,
        "API result matches dumped result for $feed",
    );
}

done_testing;
