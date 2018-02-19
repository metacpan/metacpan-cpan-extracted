package Hush::Memo;
use strict;
use warnings;
use Try::Tiny;
use Hush::Util qw/barf/;
use Hush::Logger qw/debug/;
use Data::Dumper;
use JSON;

sub new {
    my ($rpc,$options) = @_;
    my $memo           = {
        txid   => $options->{txid}   || 0,
        amount => $options->{amount} || 0.00,
        memo   => $options->{memo}   || "",
    };

    return bless $memo, 'Hush::Memo';
}

1;
