#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Header;
use Mail::AuthenticationResults::Header::AuthServID;
use Mail::AuthenticationResults::Header::Base;
use Mail::AuthenticationResults::Header::Comment;
use Mail::AuthenticationResults::Header::Entry;
use Mail::AuthenticationResults::Header::Group;
use Mail::AuthenticationResults::Header::SubEntry;
use Mail::AuthenticationResults::Header::Version;

my ( $Header, $Base, $Comment, $Entry, $Group, $SubEntry, $AuthServID, $Version );
my ( $Header2, $Base2, $Comment2, $Entry2, $Group2, $SubEntry2, $AuthServID2, $Version2 );

sub setup {

    $Header = Mail::AuthenticationResults::Header->new();
    $Base = Mail::AuthenticationResults::Header::Base->new();
    $Comment = Mail::AuthenticationResults::Header::Comment->new();
    $Entry = Mail::AuthenticationResults::Header::Entry->new();
    $Group = Mail::AuthenticationResults::Header::Group->new();
    $SubEntry = Mail::AuthenticationResults::Header::SubEntry->new();
    $AuthServID = Mail::AuthenticationResults::Header::AuthServID->new();
    $Version = Mail::AuthenticationResults::Header::Version->new();

    $Header2 = Mail::AuthenticationResults::Header->new();
    $Base2 = Mail::AuthenticationResults::Header::Base->new();
    $Comment2 = Mail::AuthenticationResults::Header::Comment->new();
    $Entry2 = Mail::AuthenticationResults::Header::Entry->new();
    $Group2 = Mail::AuthenticationResults::Header::Group->new();
    $SubEntry2 = Mail::AuthenticationResults::Header::SubEntry->new();
    $AuthServID2 = Mail::AuthenticationResults::Header::AuthServID->new();
    $Version2 = Mail::AuthenticationResults::Header::Version->new();
}

subtest 'orphan' => sub{
    setup();
    dies_ok( sub{ $Header->orphan() }, 'Cannot orphan Header' );
    dies_ok( sub{ $Base->orphan() }, 'Cannot orphan Header' );
    dies_ok( sub{ $Comment->orphan() }, 'Cannot orphan Header' );
    dies_ok( sub{ $Entry->orphan() }, 'Cannot orphan Header' );
    dies_ok( sub{ $Group->orphan() }, 'Cannot orphan Header' );
    dies_ok( sub{ $Header->orphan() }, 'Cannot orphan Header' );
    dies_ok( sub{ $Header->orphan() }, 'Cannot orphan Header' );
    dies_ok( sub{ $Header->orphan() }, 'Cannot orphan Header' );
};

subtest 'self' => sub{
    setup();
    dies_ok( sub{ $Header->add_child( $Header ) }, 'Header Header self dies' );
    dies_ok( sub{ $Base->add_child( $Base ) }, 'Base Base self dies' );
    dies_ok( sub{ $Comment->add_child( $Comment ) }, 'Comment Comment self dies' );
    dies_ok( sub{ $Entry->add_child( $Entry ) }, 'Entry Entry self dies' );
    dies_ok( sub{ $Group->add_child( $Group ) }, 'Group Group self dies' );
    dies_ok( sub{ $SubEntry->add_child( $SubEntry ) }, 'SubEntry SubEntry self dies' );
    dies_ok( sub{ $AuthServID->add_child( $AuthServID ) }, 'AuthServID AuthServID self dies' );
    dies_ok( sub{ $Version->add_child( $Version ) }, 'Version Version self dies' );
};

subtest 'self type' => sub{
    setup();
    dies_ok( sub{ $Header->add_child( $Header2 ) }, 'Header Header dies' );
    dies_ok( sub{ $Header->add_child( $Base2 ) }, 'Header Base dies' );
    lives_ok( sub{ $Header->add_child( $Comment2 ) }, 'Header Comment lives' );
    lives_ok( sub{ $Header->add_child( $Entry2 ) }, 'Header Entry lives' );
    dies_ok( sub{ $Header->add_child( $Group2 ) }, 'Header Group dies' );
    dies_ok( sub{ $Header->add_child( $Entry2 ) }, 'Header Entry repeat dies' );
    dies_ok( sub{ $Header->add_child( $SubEntry2 ) }, 'Header SubEntry dies' );
    dies_ok( sub{ $Header->add_child( $AuthServID) }, 'Header AuthServID dies' );
    dies_ok( sub{ $Header->add_child( $Version ) }, 'Header Version dies' );

    lives_ok( sub{ $Header->remove_child( $Comment2 ) }, 'Header Comment remove lives' );
    lives_ok( sub{ $Header->remove_child( $Entry2 ) }, 'Header Entry remove lives' );
    lives_ok( sub{ $Header->add_child( $Comment2 ) }, 'Header Comment lives' );
    lives_ok( sub{ $Header->add_child( $Entry2 ) }, 'Header Entry lives' );
};

subtest 'base' => sub{
    setup();
    dies_ok( sub{ $Base->add_child( $Header2 ) }, 'Base Header dies' );
    dies_ok( sub{ $Base->add_child( $Base2 ) }, 'Base Base dies' );
    dies_ok( sub{ $Base->add_child( $Comment2 ) }, 'Base Comment dies' );
    dies_ok( sub{ $Base->add_child( $Entry2 ) }, 'Base Entry dies' );
    dies_ok( sub{ $Base->add_child( $Group2 ) }, 'Base Group dies' );
    dies_ok( sub{ $Base->add_child( $SubEntry2 ) }, 'Base SubEntry dies' );
    dies_ok( sub{ $Base->add_child( $AuthServID) }, 'Base AuthServID dies' );
    dies_ok( sub{ $Base->add_child( $Version ) }, 'Base Version dies' );
};

subtest 'comment' => sub{
    setup();
    dies_ok( sub{ $Comment->add_child( $Header2 ) }, 'Comment Header dies' );
    dies_ok( sub{ $Comment->add_child( $Base2 ) }, 'Comment Base dies' );
    dies_ok( sub{ $Comment->add_child( $Comment2 ) }, 'Comment Comment dies' );
    dies_ok( sub{ $Comment->add_child( $Entry2 ) }, 'Comment Entry dies' );
    dies_ok( sub{ $Comment->add_child( $Group2 ) }, 'Comment Group dies' );
    dies_ok( sub{ $Comment->add_child( $SubEntry2 ) }, 'Comment SubEntry dies' );
    dies_ok( sub{ $Comment->add_child( $AuthServID) }, 'Comment AuthServID dies' );
    dies_ok( sub{ $Comment->add_child( $Version ) }, 'Comment Version dies' );
};

subtest 'entry' => sub{
    setup();
    dies_ok( sub{ $Entry->add_child( $Header2 ) }, 'Entry Header dies' );
    dies_ok( sub{ $Entry->add_child( $Base2 ) }, 'Entry Base dies' );
    lives_ok( sub{ $Entry->add_child( $Comment2 ) }, 'Entry Comment lives' );
    dies_ok( sub{ $Entry->add_child( $Comment2 ) }, 'Entry Comment repeat dies' );
    dies_ok( sub{ $Entry->add_child( $Entry2 ) }, 'Entry Entry dies' );
    dies_ok( sub{ $Entry->add_child( $Group2 ) }, 'Entry Group dies' );
    lives_ok( sub{ $Entry->add_child( $SubEntry2 ) }, 'Entry SubEntry lives' );
    dies_ok( sub{ $Entry->add_child( $AuthServID) }, 'Entry AuthServID dies' );
    lives_ok( sub{ $Entry->add_child( $Version ) }, 'Entry Version lives' );

    lives_ok( sub{ $Entry->remove_child( $Comment2 ) }, 'Entry Comment remove lives' );
    lives_ok( sub{ $Entry->remove_child( $SubEntry2 ) }, 'Entry SubEntry remove lives' );
    lives_ok( sub{ $Entry->remove_child( $Version ) }, 'Entry Version remove lives' );
    lives_ok( sub{ $Entry->add_child( $Comment2 ) }, 'Entry Comment lives' );
    lives_ok( sub{ $Entry->add_child( $SubEntry2 ) }, 'Entry SubEntry lives' );
    lives_ok( sub{ $Entry->add_child( $Version ) }, 'Entry Version lives' );
};

subtest 'group' => sub{
    setup();
    lives_ok( sub{ $Group->add_child( $Header2 ) }, 'Group Header lives' );
    dies_ok( sub{ $Group->add_child( $Base2 ) }, 'Group Base dies' );
    lives_ok( sub{ $Group->add_child( $Comment2 ) }, 'Group Comment lives' );
    lives_ok( sub{ $Group->add_child( $Entry2 ) }, 'Group Entry lives' );
    lives_ok( sub{ $Group->add_child( $Group2 ) }, 'Group Group lives' );
    lives_ok( sub{ $Group->add_child( $SubEntry2 ) }, 'Group SubEntry lives' );
    lives_ok( sub{ $Group->add_child( $AuthServID) }, 'Group AuthServID lives' );
    lives_ok( sub{ $Group->add_child( $Version ) }, 'Group Version lives' );

    # Group repeats should not die, but should not result in duplicates
    is( scalar @{$Group->children()}, 6, 'Has 6 children' );
    lives_ok( sub{ $Group->add_child( $Header2 ) }, 'Group Header repeat lives' );
    lives_ok( sub{ $Group->add_child( $Comment2 ) }, 'Group Comment repeat lives' );
    lives_ok( sub{ $Group->add_child( $Entry2 ) }, 'Group Entry repeat lives' );
    lives_ok( sub{ $Group->add_child( $Group2 ) }, 'Group Group repeat lives' );
    lives_ok( sub{ $Group->add_child( $SubEntry2 ) }, 'Group SubEntry repeat lives' );
    lives_ok( sub{ $Group->add_child( $AuthServID) }, 'Group AuthServID repeat lives' );
    lives_ok( sub{ $Group->add_child( $Version ) }, 'Group Version repeat lives' );
    is( scalar @{$Group->children()}, 6, 'Still has 6 children' );

    lives_ok( sub{ $Group->remove_child( $Header2 ) }, 'Group Header remove lives' );
    lives_ok( sub{ $Group->remove_child( $Comment2 ) }, 'Group Comment remove lives' );
    lives_ok( sub{ $Group->remove_child( $Entry2 ) }, 'Group Entry remove lives' );
    lives_ok( sub{ $Group->remove_child( $SubEntry2 ) }, 'Group SubEntry remove lives' );
    lives_ok( sub{ $Group->remove_child( $AuthServID) }, 'Group AuthServID remove lives' );
    lives_ok( sub{ $Group->remove_child( $Version ) }, 'Group Version remove lives' );
    is( scalar @{$Group->children()}, 0, 'Now has 0 children' );
};

subtest 'subentry' => sub{
    setup();
    dies_ok( sub{ $SubEntry->add_child( $Header2 ) }, 'SubEntry Header dies' );
    dies_ok( sub{ $SubEntry->add_child( $Base2 ) }, 'SubEntry Base dies' );
    lives_ok( sub{ $SubEntry->add_child( $Comment2 ) }, 'SubEntry Comment lives' );
    dies_ok( sub{ $SubEntry->add_child( $Comment2 ) }, 'SubEntry Comment repeat dies' );
    dies_ok( sub{ $SubEntry->add_child( $Entry2 ) }, 'SubEntry Entry dies' );
    dies_ok( sub{ $SubEntry->add_child( $Group2 ) }, 'SubEntry Group dies' );
    dies_ok( sub{ $SubEntry->add_child( $SubEntry2 ) }, 'SubEntry SubEntry dies' );
    dies_ok( sub{ $SubEntry->add_child( $AuthServID) }, 'SubEntry AuthServID dies' );
    lives_ok( sub{ $SubEntry->add_child( $Version ) }, 'SubEntry Version lives' );

    lives_ok( sub{ $SubEntry->remove_child( $Comment2 ) }, 'SubEntry Comment remove lives' );
    lives_ok( sub{ $SubEntry->remove_child( $Version ) }, 'SubEntry Version remove lives' );
    lives_ok( sub{ $SubEntry->add_child( $Comment2 ) }, 'SubEntry Comment lives' );
    lives_ok( sub{ $SubEntry->add_child( $Version ) }, 'SubEntry Version lives' );
};

subtest 'authservid' => sub{
    setup();
    dies_ok( sub{ $AuthServID->add_child( $Header2 ) }, 'AuthServID Header dies' );
    dies_ok( sub{ $AuthServID->add_child( $Base2 ) }, 'AuthServID Base dies' );
    lives_ok( sub{ $AuthServID->add_child( $Comment2 ) }, 'AuthServID Comment lives' );
    dies_ok( sub{ $AuthServID->add_child( $Comment2 ) }, 'AuthServID Comment repeat dies' );
    dies_ok( sub{ $AuthServID->add_child( $Entry2 ) }, 'AuthServID Entry dies' );
    dies_ok( sub{ $AuthServID->add_child( $Group2 ) }, 'AuthServID Group dies' );
    lives_ok( sub{ $AuthServID->add_child( $SubEntry2 ) }, 'AuthServID SubEntry lives' );
    dies_ok( sub{ $AuthServID->add_child( $AuthServID) }, 'AuthServID AuthServID dies' );
    lives_ok( sub{ $AuthServID->add_child( $Version ) }, 'AuthServID Version lives' );

    lives_ok( sub{ $AuthServID->remove_child( $Comment2 ) }, 'AuthServID Comment remove lives' );
    lives_ok( sub{ $AuthServID->remove_child( $SubEntry2 ) }, 'AuthServID SubEntry remove lives' );
    lives_ok( sub{ $AuthServID->remove_child( $Version ) }, 'AuthServID Version remove lives' );
    lives_ok( sub{ $AuthServID->add_child( $Comment2 ) }, 'AuthServID Comment lives' );
    lives_ok( sub{ $AuthServID->add_child( $SubEntry2 ) }, 'AuthServID SubEntry lives' );
    lives_ok( sub{ $AuthServID->add_child( $Version ) }, 'AuthServID Version lives' );
};

subtest 'version' => sub{
    setup();
    dies_ok( sub{ $Version->add_child( $Header2 ) }, 'Version Header dies' );
    dies_ok( sub{ $Version->add_child( $Base2 ) }, 'Version Base dies' );
    dies_ok( sub{ $Version->add_child( $Comment2 ) }, 'Version Comment dies' );
    dies_ok( sub{ $Version->add_child( $Comment2 ) }, 'Version Comment repeat dies' );
    dies_ok( sub{ $Version->add_child( $Entry2 ) }, 'Version Entry dies' );
    dies_ok( sub{ $Version->add_child( $Group2 ) }, 'Version Group dies' );
    dies_ok( sub{ $Version->add_child( $SubEntry2 ) }, 'Version SubEntry dies' );
    dies_ok( sub{ $Version->add_child( $AuthServID) }, 'Version AuthServID dies' );
    dies_ok( sub{ $Version->add_child( $Version ) }, 'Version Version dies' );
};

done_testing();

