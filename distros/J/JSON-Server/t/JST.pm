package JST;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = 'utf8_check';
use warnings;
use strict;
use utf8;
use Carp;

use Test::More;
use JSON::Server;
use JSON::Client;
use JSON::Parse;
use JSON::Create;

push @EXPORT, (
    @Test::More::EXPORT,
    @JSON::Parse::EXPORT_OK,
    @JSON::Create::EXPORT_OK,
);

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

sub import
{
    strict->import ();
    utf8->import ();
    warnings->import ();

    Test::More->import ();
    JSON::Parse->import (':all');
    JSON::Create->import (':all');

    JST->export_to_level (1);
}

sub utf8_check
{
    my ($thing) = @_;
    my @keys = keys %$thing;
    for my $key (@keys) {
	ok (utf8::is_utf8 ($key), "Correctly upgraded key $key");
	ok (utf8::is_utf8 ($thing->{$key}),
	    "Correctly upgraded value $thing->{$key}");
    }
}

1;
