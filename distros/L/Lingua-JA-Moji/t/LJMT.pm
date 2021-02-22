package LJMT;
require Exporter;
use Test::More;
use Lingua::JA::Moji ':all';
our @ISA = qw(Exporter);
our @EXPORT = (@Test::More::EXPORT, @Lingua::JA::Moji::EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp;
use FindBin '$Bin';
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

sub import
{
    my ($class) = @_;

    strict->import ();
    utf8->import ();
    warnings->import ();
    Test::More->import ();
    Lingua::JA::Moji->import (':all');
    LJMT->export_to_level (1);
}


1;
