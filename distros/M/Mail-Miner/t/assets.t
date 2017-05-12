#!perl -w
use strict;
use blib;
use Test::More tests => 5;
BEGIN { use_ok('Mail::Miner') };

use MIME::Entity;
use MIME::Parser;

eval {
    require Test::Differences;
    no warnings 'redefine';
    *is_deeply = \&Test::Differences::eq_or_diff;
};


my $message;
my $parser = new MIME::Parser;
$parser->output_to_core(1);
isa_ok( $message = $parser->parse_open("test-message"), "MIME::Entity");

my @got = Mail::Miner::Assets->analyse(
    gethead => sub {$message->head->as_string},
    getbody => sub {$message->bodyhandle->as_string},
   );

my @expected = (
    {
        'creator' => 'Mail::Miner::Recogniser::Phone',
        'asset' => '+44 118 9500110',
    },
    {
        'creator' => 'Mail::Miner::Recogniser::Phone',
        'asset' => '+44 118 9508311 ext 2250',
    },
    {
        'creator' => 'Mail::Miner::Recogniser::Address',
        'asset' => join( "\n",
                         'Andrew Josey                                The Open Group  ',
                         'Austin Group Chair                          Apex Plaza,Forbury Road,',
                         'Email: a.josey@opengroup.org                Reading,Berks.RG1 1AX,England'
                        ),
    },
);

is_deeply([ sort { $a->{asset} cmp $b->{asset} }
            grep { $_->{creator} !~ /Spam|Entity|Keywords/ } @got ],
          \@expected, "Correct assets with MIME::Entity");

Mail::Miner::Assets->analyse(
    gethead => sub {$message->head->as_string},
    getbody => sub {$message->bodyhandle->as_string},
    store   => sub {
        ok(1, "Store passes us stuff");
        is_deeply([ sort { $a->{asset} cmp $b->{asset} }
                      grep { $_->{creator} !~ /Spam|Entity|Keywords/ } @_ ],
                  \@expected,
                  "Store passes us accurate stuff");
    },
   );
