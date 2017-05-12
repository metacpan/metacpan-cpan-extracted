use Test::Base;
use Makefile::AST::StemMatch;

plan tests => 8 * blocks() + 1;

my $match = Makefile::AST::StemMatch->new(
    { pattern => '%.o', target => 'foo.c' }
);
ok !defined $match, 'match failed expectedly';

run {
    my $block = shift;
    my $name = $block->name;

    my $pattern = $block->pattern;
    my $target  = $block->target;
    my $stem    = $block->stem;
    my $dir     = $block->dir;
    my $notdir  = $block->notdir;

    my $match = Makefile::AST::StemMatch->new(
        { pattern => $pattern,
          target => $target }
    );
    ok $match, "$name - obj ok";
    isa_ok $match, 'Makefile::AST::StemMatch', "$name - class ok";
    is $match->pattern, $pattern, "$name - pattern ok";
    is $match->target, $target, "$name - target ok";
    is $match->stem, $stem, "$name - stem ok";
    is $match->dir, $dir, "$name - dir ok";
    is $match->notdir, $notdir, "$name - notdir ok";

    my @prereqs = split /\s+/, $block->in_prereqs;
    map { $_ = $match->subs_stem($_) } @prereqs;
    is join(' ', @prereqs), $block->out_prereqs, "$name - subs_stem ok";
};

__DATA__

=== TEST 1:
--- pattern: %.o
--- target: foo.o
--- stem: foo
--- dir:
--- notdir: foo.o
--- in_prereqs: %.c lib/%.cpp
--- out_prereqs: foo.c lib/foo.cpp



=== TEST 2: slash in target
--- pattern: %.o
--- target: lib/foo.o
--- stem: foo
--- dir: lib/
--- notdir: foo.o
--- in_prereqs: %.c lib/%.cpp
--- out_prereqs: lib/foo.c lib/lib/foo.cpp

