use warnings;
use strict;

use Test::More;
use IPC::Shareable ();

# -- Expected exports by tag --

my %expected = (
    all         => [qw(LOCK_EX LOCK_SH LOCK_NB LOCK_UN SEM_MARKER SEM_READERS SEM_WRITERS SEM_PROTECTED SEM_TESTING)],
    lock        => [qw(LOCK_EX LOCK_SH LOCK_NB LOCK_UN)],
    flock       => [qw(LOCK_EX LOCK_SH LOCK_NB LOCK_UN)],
    semaphores  => [qw(SEM_MARKER SEM_READERS SEM_WRITERS SEM_PROTECTED SEM_TESTING)],
);

# Unique, sorted list of every exportable symbol
my @all_unique = sort keys %{ { map { $_ => 1 } map { @$_ } values %expected } };

# -- Structural integrity --

subtest 'structural integrity' => sub {
    # All expected tags exist in the module
    is_deeply(
        [sort keys %IPC::Shareable::EXPORT_TAGS],
        [sort keys %expected],
        'All expected export tags are defined in %EXPORT_TAGS',
    );

    # @EXPORT_OK must have no duplicates and match the union of all tag exports
    {
        my %seen;
        my @dupes = grep { $seen{$_}++ } @IPC::Shareable::EXPORT_OK;
        ok(!@dupes, '@EXPORT_OK has no duplicate symbols')
            or diag "Duplicates: @dupes";

        is_deeply(
            [sort @IPC::Shareable::EXPORT_OK],
            [sort @all_unique],
            '@EXPORT_OK contains exactly the union of all tag exports',
        );
    }

    # Every symbol in @EXPORT_OK is covered by at least one tag
    {
        my %tag_items = map { $_ => 1 } map { @$_ } values %IPC::Shareable::EXPORT_TAGS;
        my @uncovered = sort grep { !$tag_items{$_} } keys %{ { map { $_ => 1 } @IPC::Shareable::EXPORT_OK } };
        ok(!@uncovered, 'Every symbol in @EXPORT_OK is covered by at least one tag')
            or diag "Uncovered: @uncovered";
    }

    # No tag references symbols outside @EXPORT_OK
    {
        my %ok = map { $_ => 1 } @IPC::Shareable::EXPORT_OK;
        for my $tag (sort keys %{ $IPC::Shareable::EXPORT_TAGS }) {
            my @extra = grep { !$ok{$_} } @{ $IPC::Shareable::EXPORT_TAGS{$tag} };
            ok(!@extra, ":$tag contains only symbols from \@EXPORT_OK")
                or diag "Extra in :$tag: @extra";
        }
    }
};

# -- :lock and :flock are equivalent --

subtest ':lock and :flock are equivalent' => sub {
    is_deeply(
        [sort @{ $IPC::Shareable::EXPORT_TAGS{lock} }],
        [sort @{ $IPC::Shareable::EXPORT_TAGS{flock} }],
        ':lock and :flock contain identical symbols',
    );
};

# -- Each tag imports exactly what it should, with correct values --

for my $tag (sort keys %expected) {
    subtest ":${tag} tag" => sub {
        my @want = sort @{ $expected{$tag} };
        my $pkg  = fresh_pkg();

        _do_import($pkg, ":$tag");

        my @got = sort(imported_from($pkg));
        is_deeply(\@got, \@want, ":$tag imports exactly the expected symbols")
            or diag explain { want => \@want, got => \@got };

        for my $sym (@want) {
            my ($got_val, $want_val) = symbol_values($pkg, $sym);
            is $got_val, $want_val, "$sym == $want_val";
        }
    };
}

# -- Each symbol can be imported individually --

for my $sym (@all_unique) {
    subtest "import '$sym'" => sub {
        my $pkg = fresh_pkg();
        _do_import($pkg, $sym);

        my @got = sort(imported_from($pkg));
        is_deeply(\@got, [$sym], "importing '$sym' exports only '$sym'");

        my ($got_val, $want_val) = symbol_values($pkg, $sym);
        is $got_val, $want_val, "$sym == $want_val";
    };
}

# -- Importing everything at once (as a whole) --

subtest 'import all symbols individually in one use statement' => sub {
    my $pkg = fresh_pkg();
    _do_import($pkg, @all_unique);

    my @got = sort(imported_from($pkg));
    is_deeply(\@got, [sort @all_unique], 'importing all symbols individually gives complete set');

    for my $sym (@all_unique) {
        my ($got_val, $want_val) = symbol_values($pkg, $sym);
        is $got_val, $want_val, "$sym == $want_val";
    }
};

subtest 'import via multiple tags at once' => sub {
    my $pkg = fresh_pkg();
    _do_import($pkg, ':lock', ':semaphores');

    my @got = sort(imported_from($pkg));
    is_deeply(\@got, [sort @all_unique], 'importing :lock + :semaphores gives the full set');

    for my $sym (@all_unique) {
        my ($got_val, $want_val) = symbol_values($pkg, $sym);
        is $got_val, $want_val, "$sym == $want_val";
    }
};

done_testing;

# -- helpers --

{
    my $n = 0;
    sub fresh_pkg { 'IPC_Shareable_Test_Exports_' . ++$n }
}

sub _do_import {
    my ($pkg, @args) = @_;
    my $args_str = join ', ', map { "'$_'" } @args;
    eval qq{
        package $pkg;
        require IPC::Shareable;
        IPC::Shareable->import($args_str);
        1;
    } or die "$@";
}

sub imported_from {
    my ($pkg) = @_;
    no strict 'refs';
    return grep { $pkg->can($_) } @all_unique;
}

sub symbol_values {
    my ($pkg, $sym) = @_;
    no strict 'refs';
    return ($pkg->can($sym)->(), IPC::Shareable->can($sym)->());
}