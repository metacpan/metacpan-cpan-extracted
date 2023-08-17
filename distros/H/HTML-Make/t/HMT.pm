# HTML::Make test module.

package HMT;
use warnings;
use strict;
use utf8;
use Carp;
use Test::More;
use HTML::Make;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = (@Test::More::EXPORT);
my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

sub import
{
    my ($class) = @_;

    strict->import ();
    utf8->import ();
    warnings->import ();
    Test::More->import ();
    HTML::Make->import ();
    HMT->export_to_level (1);
}

1;
