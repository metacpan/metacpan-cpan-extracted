# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 004-Round.t'

#########################

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 9;
use Carp;

use_ok('Games::Go::AGA::Parse::Round');

my $parser = Games::Go::AGA::Parse::Round->new();
isa_ok ($parser, 'Games::Go::AGA::Parse::Round', 'create object');

my $result = $parser->parse_line("tmp02 tmp01 ? 2  7.7  #  a comment\n");
is ($result->{white_id},   'TMP2',  'white player');
is ($result->{black_id},   'TMP1',  'black player');
is ($result->{handicap},   2,       'handicap');
is ($result->{komi},       7.7,     'komi');
is ($result->{result},     '?',     'winner not known');
throws_ok {
    $result = $parser->parse_line("tmp02 tmp01 ? 2  #  an early comment\n");
}
    qr/^got comment, expected komi/, 'early comment throws exception';

SKIP: {

    skip 'because re-throwing an exception fails under Test::More?', 1, unless 0;

    eval {
        $result = $parser->parse_line("tmp02 tmp01 ? 2  #  an early comment\n");
        croak "invalid line failed to throw exception\n";
    };

    if (my $x = Exception::Class->caught('Games::Go::AGA::Parse')) {
        eval {
            Games::Go::AGA::Parse->throw(   # rethrow with new fields
                error => $x->error,
                filename => 'foo',
                line  => 321,
            );
        };
        croak "failed to re-throw exception\n";
    }
    if (my $x = Exception::Class->caught('Games::Go::AGA::Parse')) {
        is ($x->full_message, "got comment, expected komi at line 321 in foo\n",   'exception rethrown');
    }
}

__END__
