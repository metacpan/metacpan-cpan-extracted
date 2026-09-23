use strict;
use warnings;
use Test::More;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

use EV::Telegram::TDLib;

# All mixins are flattened into one class through @ISA, which picks the first
# match silently: two mixins defining the same public name is a bug that ships
# without a warning of any kind.
# from the files on disk, not from @ISA: the module now derives its dispatch
# table from @ISA too, so checking one against the other would only compare
# the same walk with itself and could not see a mixin dropped from the list
my @MIXINS = grep { $_ ne 'Schema' && $_ ne 'Cookbook' }
             map  { m{([^/]+)\.pm\z} ? $1 : () }
             glob 'lib/EV/Telegram/TDLib/*.pm';

my %where;
for my $m (@MIXINS) {
    no strict 'refs';
    my $stash = \%{"EV::Telegram::TDLib::${m}::"};
    next unless %$stash;
    for my $name (keys %$stash) {
        next if $name =~ /\A_/ || $name !~ /\A[a-z]/;
        next if $name eq 'croak' || $name eq 'carp' || $name eq 'confess';
        my $glob = $stash->{$name};
        next unless ref \$glob eq 'GLOB' && defined *{$glob}{CODE};
        push @{ $where{$name} }, [ $m, *{$glob}{CODE} ];
    }
}

ok scalar(keys %where), 'the scan found public methods to check';

# The shared helpers are aliased into every mixin from the core, so the same
# name appears in fifteen stashes while being one and the same sub. Only two
# different subs under one name can shadow each other, so compare the code
# refs rather than the names.
my @dup = grep {
    my %cv; $cv{ $_->[1] } = 1 for @{ $where{$_} };
    keys %cv > 1;
} sort keys %where;
$where{$_} = [ map { $_->[0] } @{ $where{$_} } ] for keys %where;

# the assertion must not hang off a statement-modifier for: EXPR for LIST loops
# the whole expression, so with nothing duplicated is_deeply would never run and
# the file would report 1..0 and exit non-zero
is_deeply \@dup, [], 'no public method name is defined in two mixins';
diag "collides: $_ in @{ $where{$_} }" for @dup;

# A mixin whose %UPDATES never reaches the dispatch table still answers every
# method call, so the omission is invisible until an update goes unhandled.
my (%declared, %update_dup);
for my $m (@MIXINS) {
    no strict 'refs';
    for my $type (keys %{"EV::Telegram::TDLib::${m}::UPDATES"}) {
        push @{ $update_dup{$type} }, $m;
        $declared{$type} = 1;
    }
}

cmp_ok scalar(@MIXINS), '>', 10, 'the scan found mixins on disk';
ok scalar(keys %declared), 'the scan found update handlers to check';

is_deeply [sort @MIXINS],
          [sort map { /::([^:]+)\z/ ? $1 : $_ } @EV::Telegram::TDLib::ISA],
    'every mixin on disk is in @ISA';

is_deeply [sort keys %EV::Telegram::TDLib::UPDATE_HANDLERS], [sort keys %declared],
    'every mixin update handler reaches the dispatch table';

my @utd = grep { @{ $update_dup{$_} } > 1 } sort keys %update_dup;
is_deeply \@utd, [], 'no update type is handled by two mixins';
diag "update collides: $_ in @{ $update_dup{$_} }" for @utd;

done_testing;
