package JCT;
use warnings;
use strict;
use utf8;
use Test::More;
use JSON::Create;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = (
    @Test::More::EXPORT,
    @JSON::Create::EXPORT_OK,
);

sub import
{
    strict->import ();
    utf8->import ();
    warnings->import ();

    Test::More->import ();
    JSON::Create->import (':all');

    JCT->export_to_level (1);
}

my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

1;
