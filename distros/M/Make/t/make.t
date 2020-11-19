use strict;
use warnings;
use Test::More;
use Make;
use File::Spec;
use File::Temp qw(tempfile);

my @LINES = (
    [ "all : one \\\n  two\n",     [ 'all : one two', "all : one \\\n  two" ] ],
    [ "all : one \\\r\n  two\r\n", [ 'all : one two', "all : one \\\r\n  two" ] ],
    [ "all : one \\\n\t two\n",    [ 'all : one two', "all : one \\\n two" ] ],
);
for my $l (@LINES) {
    my ( $in, $expected ) = @$l;
    open my $fh, '+<', \$in or die "open: $!";
    is_deeply [ Make::get_full_line($fh) ], $expected;
}

my @ASTs = (
    [ "vpath %.c src/%.c othersrc/%.c\n", [ [ 'vpath', '%.c', 'src/%.c', 'othersrc/%.c' ], ], ],
    [
        "\n.SUFFIXES: .o .c .y .h .sh .cps # comment\n\n.c.o :\n\t\$(CC) \$(CFLAGS) \$(CPPFLAGS) -c -o \$@ \$<\n\n",
        [
            [ 'rule', '.SUFFIXES', ':', '.o .c .y .h .sh .cps', [], [] ],
            [
                'rule', '.c.o', ':', '',
                ['$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<'],
                ['$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<']
            ],
        ],
    ],
    [
        "# header\n.c.o :\n\techo hi\n# comment\n\n\techo yo\n",
        [ [ 'comment', 'header' ], [ 'rule', '.c.o', ':', '', [ 'echo hi', 'echo yo' ], [ 'echo hi', 'echo yo' ] ], ],
    ],
    [ "all : other ; echo hi # keep\n", [ [ 'rule', 'all', ':', 'other', ['echo hi # keep'], ['echo hi # keep'] ] ], ],
    [ "all : other # drop ; echo hi\n", [ [ 'rule', 'all', ':', 'other', [],                 [] ] ], ],
    [ "x = y\n",                        [ [ 'var',  'x',   'y', ] ], ],
    [ "x = y\r\n",                      [ [ 'var',  'x',   'y', ] ], ],
);
for my $l (@ASTs) {
    my ( $in, $expected ) = @$l;
    open my $fh, '+<', \$in or die "open: $!";
    my $got = Make::parse_makefile($fh);
    is_deeply $got, $expected, $in or diag explain $got;
}

my @TOKENs = (
    [ "a b c",    [qw(a b c)] ],
    [ " a b c",   [qw(a b c)] ],
    [ " a: b c",  [qw(a b c)] ],
    [ " a  b c",  [qw(a b c)] ],
    [ ' a\\ b c', [ 'a b', 'c' ] ],
);
for my $l (@TOKENs) {
    my ( $in, $expected, $err ) = @$l;
    my ($got) = eval { Make::tokenize( $in, ':' ) };
    like $@,        $err || qr/^$/;
    is_deeply $got, $expected or diag explain $got;
}

my $FUNCTIONS = ['Make::Functions'];
my $VARS      = {
    k1    => 'k2',
    k2    => 'hello',
    files => 'a.o b.o c.o',
    empty => '',
    space => ' ',
    comma => ',',
};
my $fsmap = make_fsmap( { Changes => [ 1, 'hi' ], README => [ 1, 'there' ], NOT => [ 1, 'in' ] } );
my @SUBs  = (
    [ 'none',                                 'none' ],
    [ 'this $(k1) is',                        'this k2 is' ],
    [ 'this $$(k1) is not',                   'this $(k1) is not' ],
    [ 'this ${k1} is',                        'this k2 is' ],
    [ 'this $($(k1)) double',                 'this hello double' ],
    [ '$(empty)',                             '' ],
    [ '$(empty) $(empty)',                    ' ' ],
    [ '$(subst .o,.c,$(files))',              'a.c b.c c.c' ],
    [ '$(subst $(space),$(comma),$(files))',  'a.o,b.o,c.o' ],
    [ 'not $(absent) is',                     'not  is' ],
    [ 'this $(files:.o=.c) is',               'this a.c b.c c.c is' ],
    [ '$(shell echo hi)',                     'hi' ],
    [ "\$(shell \"$^X\" -pe 1 \$(mktmp hi))", 'hi' ],
    [ '$(wildcard Chan* RE* NO*)',            'Changes README NOT' ],
    [ '$(addprefix x/,1 2)',                  'x/1 x/2' ],
    [ '$(notdir x/1 x/2)',                    '1 2' ],
    [ '$(dir x/1 y/2 3)',                     'x y ./' ],
    [ ' a ${dir $(call}',                     undef, qr/Syntax error/ ],
    [ ' a ${dir $(k1)',                       undef, qr/Syntax error/ ],
);
for my $l (@SUBs) {
    my ( $in, $expected, $err ) = @$l;
    my ($got) = eval { Make::subsvars( $in, $FUNCTIONS, [$VARS], $fsmap ) };
    like $@, $err || qr/^$/;
    is $got, $expected;
}

my @CMDs = (
    [ ' a line',      { line => 'a line' } ],
    [ 'a line',       { line => 'a line' } ],
    [ '@echo shhh',   { line => 'echo shhh',  silent   => 1 } ],
    [ '- @echo hush', { line => 'echo hush',  silent   => 1, can_fail => 1 } ],
    [ '-just do it',  { line => 'just do it', can_fail => 1 } ],
);
for my $l (@CMDs) {
    my ( $in, $expected, $err ) = @$l;
    my ($got) = eval { Make::parse_cmdline($in) };
    like $@,        $err || qr/^$/;
    is_deeply $got, $expected;
}

SKIP: {
    skip '', 2 if !$ENV{AUTHOR_TESTING};    # avoid blowing up on dmake
    my $m = Make->new;
    isa_ok $m, 'Make';
    $m->parse;
    eval { $m->Make('all') };
    is $@, '',;
}

{
    my $m = Make->new;
    $m->parse( \"all: sbar sfoo\n\techo larry\n\techo howdy\n" );
    is $m->{Vars}{'.DEFAULT_GOAL'}, 'all';
}

my ( undef, $tempfile ) = tempfile;
my $m = Make->new;
$m->parse( \sprintf <<'EOF', $tempfile );
var = value
tempfile = %s
targets = other

all: $(targets)

other: Changes README
	@echo $@ $^ $< $(var) \
	   >"$(tempfile)"
EOF
ok !$m->target('all')->has_recipe, 'all has no recipe';
ok $m->target('other')->has_recipe, 'other has recipe';
ok !$m->has_target('not_there'), 'has_target';
ok $m->has_target('all'), 'has_target existing';
$m->Make('all');
my $contents = do { local $/; open my $fh, '<', $tempfile; <$fh> };
like $contents, qr/^other Changes README Changes value/;
my ($other_rule) = @{ $m->target('other')->rules };
my $got = $other_rule->recipe;
is_deeply $got, ['@echo $@ $^ $< $(var) >"$(tempfile)"'] or diag explain $got;
$got = $other_rule->recipe_raw;
is_deeply $got, [qq{\@echo \$@ \$^ \$< \$(var) \\\n   >"\$(tempfile)"}] or diag explain $got;
my $all_target = $m->target('all');
my ($all_rule) = @{ $all_target->rules };
$got = $all_rule->prereqs;
is_deeply $got, ['other'] or diag explain $got;
$got = $all_rule->auto_vars($all_target);
ok exists $got->{'@'}, 'Rules.Vars.EXISTS';
is_deeply [ keys %$got ], [qw( @ * ^ ? < )] or diag explain $got;

$m = Make->new;
$m->parse( \sprintf <<'EOF', $tempfile, $^X );
space = $() $()
tempfile = %s
all: ; @"%s" -e "print shift().qq{\n}" "$(space)" >"$(tempfile)"
.PHONY: all
EOF
ok $m->target('all')->phony,  'all is phony';
is $m->target('a.x.o')->Base, 'a.x';
$m->Make;
$contents = do { local $/; open my $fh, '<', $tempfile; <$fh> };
is $contents, " \n";

$got = [ Make::parse_args(qw(all VAR=value)) ];
is_deeply $got, [ [ [qw(VAR value)] ], ['all'] ] or diag explain $got;

my $inc_mk = sprintf <<'EOF', $tempfile, $^X;
vpath %%.c src/%%.c # double-percent because sprintf
objs = a.o b.o
tempfile = %s
CC = @"%s" -e "print qq[@ARGV\n]" COMPILE >>"$(tempfile)"
.c.o: ; $(CC) -c -o $@ $<
all: $(objs)
.PHONY: all
EOF
my $vfs = {
    'src/a.c'   => [ 2, 'hi' ],
    'a.o'       => [ 1, 'yo' ],
    'b.c'       => [ 2, 'hi' ],
    'b.o'       => [ 1, 'yo' ],
    GNUmakefile => [ 1, "include inc.mk\n-include not.mk\n" ],
    'inc.mk'    => [ 1, $inc_mk ],
};

for my $tuple ( [ undef, undef ], [ undef, 'subdir' ], [qw(GNUmakefile subdir)] ) {
    my ( $mf, $prefix ) = @$tuple;
    truncate $tempfile, 0;
    $m = Make->new( FSFunctionMap => make_fsmap( $vfs, $prefix ), GNU => 1, InDir => $prefix );
    $m->parse($mf);
    $got = $m->target('all')->rules->[0]->prereqs;
    is_deeply $got, [qw(a.o b.o)] or diag explain $got;
    $got = $m->target('a.o')->rules->[0]->prereqs;
    is_deeply $got, ['src/a.c'] or diag explain $got;
    $got = [ sort $m->targets ];
    is_deeply $got, [qw(a.o all b.o)], 'targets' or diag explain $got;
    $m->Make('all');
    $got = [ sort $m->targets ];
    is_deeply $got, [qw(a.o all b.c b.o src/a.c)], 'targets after' or diag explain $got;
    $contents = do { local $/; open my $fh, '<', $tempfile; <$fh> };
    is $contents, "COMPILE -c -o a.o src/a.c\nCOMPILE -c -o b.o b.c\n";
}

done_testing;

sub make_fsmap {
    my ( $vfs, $maybe_prefix ) = @_;
    my %vfs_copy = map +( Make::in_dir( $_, $maybe_prefix ) => $vfs->{$_} ), keys %$vfs;
    my %fh2file_tuple;
    return {
        glob => sub {
            my @results;
            for my $subpat ( split /\s+/, $_[0] ) {
                $subpat =~ s/\*/.*/g;    # ignore ?, [], {} for now
                ## no critic (BuiltinFunctions::RequireBlockGrep)
                push @results, grep /^$subpat$/, sort keys %vfs_copy;
                ## use critic
            }
            return @results;
        },
        fh_open => sub {
            require Carp;
            Carp::confess "open @_: No such file or directory" unless exists $vfs_copy{ $_[1] };
            my $file_tuple = $vfs_copy{ $_[1] };
            open my $fh, "+$_[0]", \$file_tuple->[1];
            $fh2file_tuple{$fh} = $file_tuple;
            return $fh;
        },
        fh_write      => sub { my $fh = shift; $fh2file_tuple{$fh}[0] = time; print {$fh} @_ },
        file_readable => sub { exists $vfs_copy{ $_[0] } },
        mtime         => sub { ( $vfs_copy{ $_[0] } || [] )->[0] },
    };
}
