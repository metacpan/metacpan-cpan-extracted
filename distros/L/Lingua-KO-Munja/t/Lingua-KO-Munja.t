use warnings;
use strict;
use Test::More;
use utf8;
BEGIN { use_ok('Lingua::KO::Munja') };
use Lingua::KO::Munja ':all';

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

# This was missing a final l when converted with the kanji2hanja.pl
# script.

# http://www.sori.org/hangul/conv2kr.cgi?q=yeol&m=0

#TODO: {
#    local $TODO = 'final l bug';
    is (roman2hangul ('yeol'), '열');
#};

done_testing ();

exit;

# Local variables:
# mode: perl
# End:
