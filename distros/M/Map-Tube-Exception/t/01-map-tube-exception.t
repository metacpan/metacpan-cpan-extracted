#!perl -T

package T;

use Map::Tube::Exception::MissingStationId;
use Map::Tube::Exception::MissingStationName;
use Map::Tube::Exception::MissingLineId;
use Map::Tube::Exception::InvalidLineId;
use Map::Tube::Exception::MissingLineName;
use Map::Tube::Exception::InvalidStationId;
use Map::Tube::Exception::InvalidStationName;
use Map::Tube::Exception::DuplicateStationId;
use Map::Tube::Exception::DuplicateStationName;
use Map::Tube::Exception::InvalidNodeObject;
use Map::Tube::Exception::MissingNodeObject;
use Map::Tube::Exception::InvalidSupportedObject;
use Map::Tube::Exception::MissingSupportedObject;
use Map::Tube::Exception::FoundSelfLinkedStation;
use Map::Tube::Exception::FoundMultiLinkedStation;
use Map::Tube::Exception::FoundMultiLinedStation;
use Map::Tube::Exception::MissingPluginGraph;
use Map::Tube::Exception::MissingSupportedMap;
use Map::Tube::Exception::FoundUnsupportedMap;
use Map::Tube::Exception::FoundUnsupportedObject;

use Moo;
use namespace::clean;

sub test_missing_line_id {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingLineId->throw({
        method      => __PACKAGE__."::test_missing_line_id",
        message     => "ERROR: Missing line id.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_invalid_line_id {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::InvalidLineId->throw({
        method      => __PACKAGE__."::test_invalid_line_id",
        message     => "ERROR: Invalid line id.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_missing_station_id {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingStationId->throw({
        method      => __PACKAGE__."::test_missing_station_id",
        message     => "ERROR: Missing Station Id.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_missing_station_name {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingStationName->throw({
        method      => __PACKAGE__."::test_missing_station_name",
        message     => "ERROR: Missing Station Name.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_invalid_station_id {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::InvalidStationId->throw({
        method      => __PACKAGE__."::test_invalid_station_id",
        message     => "ERROR: Invalid Station Id.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_invalid_station_name {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::InvalidStationName->throw({
        method      => __PACKAGE__."::test_invalid_station_name",
        message     => "ERROR: Invalid Station Name.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_duplicate_station_id {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::DuplicateStationId->throw({
        method      => __PACKAGE__."::test_duplicate_station_id",
        message     => "ERROR: Duplicate Station Id.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_duplicate_station_name {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::DuplicateStationName->throw({
        method      => __PACKAGE__."::test_duplicate_station_name",
        message     => "ERROR: Duplicate Station Name.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_missing_line_name {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingLineName->throw({
        method      => __PACKAGE__."::test_missing_line_name",
        message     => "ERROR: Missing Line Name.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_missing_node_object {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingNodeObject->throw({
        method      => __PACKAGE__."::test_missing_node_object",
        message     => "ERROR: Missing Node Object.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_invalid_node_object {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::InvalidNodeObject->throw({
        method      => __PACKAGE__."::test_invalid_node_object",
        message     => "ERROR: Invalid Node Object.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_missing_supported_object {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingSupportedObject->throw({
        method      => __PACKAGE__."::test_missing_supported_object",
        message     => "ERROR: Missing Supported Object.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_invalid_supported_object {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::InvalidSupportedObject->throw({
        method      => __PACKAGE__."::test_invalid_supported_object",
        message     => "ERROR: Invalid Supported Object.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_found_self_linked_station {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::FoundSelfLinkedStation->throw({
        method      => __PACKAGE__."::test_found_self_linked_station",
        message     => "ERROR: Found Self Linked Station.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_found_multi_linked_station {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::FoundMultiLinkedStation->throw({
        method      => __PACKAGE__."::test_found_multi_linked_station",
        message     => "ERROR: Found Multi Linked Station.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_found_multi_lined_station {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::FoundMultiLinedStation->throw({
        method      => __PACKAGE__."::test_found_multi_lined_station",
        message     => "ERROR: Found Multi Lined Station.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

sub test_missing_plugin_graph {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingPluginGraph->throw({
        method      => __PACKAGE__."::test_missing_plugin_graph",
        message     => "ERROR: Missing Plugin Graph.",
        filename    => $caller[1],
        line_number => $caller[2] });
}
sub test_missing_supported_map {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingSupportedMap->throw({
        method      => __PACKAGE__."::test_missing_supported_map",
        message     => "ERROR: Missing Supported Map.",
        filename    => $caller[1],
        line_number => $caller[2] });
}
sub test_found_unsupported_map {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::FoundUnsupportedMap->throw({
        method      => __PACKAGE__."::test_found_unsupported_map",
        message     => "ERROR: Found Unsupported Map.",
        filename    => $caller[1],
        line_number => $caller[2] });
}
sub test_found_unsupported_object {
    my @caller  = caller(0);
    @caller     = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::FoundUnsupportedObject->throw({
        method      => __PACKAGE__."::test_found_unsupported_object",
        message     => "ERROR: Found Unsupported Object.",
        filename    => $caller[1],
        line_number => $caller[2] });
}

package main;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval { T->new->test_missing_line_id; };
like($@, qr/Missing line id/);

eval { T->new->test_invalid_line_id; };
like($@, qr/Invalid line id/);

eval { T->new->test_missing_station_id; };
like($@, qr/Missing Station Id/);

eval { T->new->test_missing_station_name; };
like($@, qr/Missing Station Name/);

eval { T->new->test_invalid_station_id; };
like($@, qr/Invalid Station Id/);

eval { T->new->test_invalid_station_name; };
like($@, qr/Invalid Station Name/);

eval { T->new->test_duplicate_station_id; };
like($@, qr/Duplicate Station Id/);

eval { T->new->test_duplicate_station_name; };
like($@, qr/Duplicate Station Name/);

eval { T->new->test_missing_line_name; };
like($@, qr/Missing Line Name/);

eval { T->new->test_missing_node_object; };
like($@, qr/Missing Node Object/);

eval { T->new->test_invalid_node_object; };
like($@, qr/Invalid Node Object/);

eval { T->new->test_missing_supported_object; };
like($@, qr/Missing Supported Object/);

eval { T->new->test_invalid_supported_object; };
like($@, qr/Invalid Supported Object/);

eval { T->new->test_found_self_linked_station; };
like($@, qr/Found Self Linked Station/);

eval { T->new->test_found_multi_linked_station; };
like($@, qr/Found Multi Linked Station/);

eval { T->new->test_found_multi_lined_station; };
like($@, qr/Found Multi Lined Station/);

eval { T->new->test_missing_plugin_graph; };
like($@, qr/Missing Plugin Graph/);

eval { T->new->test_missing_supported_map; };
like($@, qr/Missing Supported Map/);

eval { T->new->test_found_unsupported_map; };
like($@, qr/Found Unsupported Map/);

eval { T->new->test_found_unsupported_object; };
like($@, qr/Found Unsupported Object/);

done_testing();
