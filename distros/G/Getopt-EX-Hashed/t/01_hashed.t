use strict;
use warnings;
use Test::More;
use lib './t';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my @argv = qw(
    --string Alice
    Life
    --number 42
    --list mostly --list harmless
    Universe and
    --hash animal=dolphin --hash fish=babel
    --implicit
    -s -42
    --end 999
    --trillian=mcmillan
    --beeblebrox
    --so-long
    --both 99
    Everything
    --paranoid Marvin
    );

BEGIN {
    $App::Foo::TAKE_IT_ALL = 1;
}

use App::Foo;
@argv = (my $app = App::Foo->new)->run(@argv);

is_deeply($app->{string}, "Alice", "String");
is_deeply($app->{say}, "Hello", "String (default)");
is_deeply($app->{number}, 42, "Number");
is_deeply($app->{implicit}, 42, "Default parameter");
is_deeply($app->{start}, -42, "alias (short)");
is_deeply($app->{finish}, 999, "alias (long)");
is_deeply($app->{tricia}, "mcmillan", "alias (mixed with spec)");
is_deeply($app->{zaphord}, 1, "alias (separate)");
is_deeply($app->{so_long}, 1, "convert underscore");
is_deeply($app->{list}, [ qw(mostly harmless) ], "List");
is_deeply($app->{hash}, { animal => 'dolphin', fish => 'babel' }, "Hash");
is_deeply($app->{left}, 99, "coderef");
is_deeply($app->{android}, "Marvin", "action");
if ($App::Foo::TAKE_IT_ALL) {
    is_deeply($app->{ARGV}, [ qw(Life Universe and Everything) ], '<>');
} else {
    is_deeply(\@argv, [ qw(Life Universe and Everything) ], '@argv');
}

done_testing;
