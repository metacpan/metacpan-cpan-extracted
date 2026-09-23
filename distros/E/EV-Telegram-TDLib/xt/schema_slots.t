use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
}

require EV::Telegram::TDLib::Schema;
no warnings 'once';
my %SLOT = %EV::Telegram::TDLib::Schema::CLASS_SLOTS;
my %BASE = %EV::Telegram::TDLib::Schema::CLASS_BASE;

plan skip_all => 'schema has no slot table; run author/gen-schema.pl'
    unless keys %SLOT;

# xt/schema_pin.t asks "does this @type name exist?". That passes for an @type
# that exists but is wrong for the slot it sits in, which is what shipped twice
# in 0.03: inputMessageText where draftMessageContentText belonged, and contact
# where importedContact belonged. This test asks the other question.
#
# A slot declared with a lowercase type wants exactly that class; an uppercase
# one is abstract and wants any class whose base is it.
sub slot_ok {
    my ($declared, $actual) = @_;
    $declared =~ s/\Aarray://;
    return 1 if $declared eq $actual;
    return 1 if ($BASE{$actual} // '') eq $declared;
    return 0;
}

# Walk the source tracking brace depth, remembering the '@type' of each open
# block and the key each block was opened under, so a nested literal can be
# checked against its parent's declared slot.
sub scan {
    my ($src) = @_;
    $src =~ s/^=\w+.*?^=cut//msg;          # POD
    $src =~ s/^\s*#.*$//mg;                # whole-line comments
    my @found;
    my @stack = ({ type => undef, key => undef });
    my $key;
    while ($src =~ /\G(.*?)([{}])/gs) {
        my ($text, $brace) = ($1, $2);
        # an '@type' assignment anywhere in this run belongs to the open block
        $stack[-1]{type} = $1
            if $text =~ /'\@type'(?:\s*=>|\}\s*=)\s*'(\w+)'/;
        if ($brace eq '{') {
            # the key this block is being opened under, if any
            my $k = ($text =~ /(\w+)\s*=>\s*\z/) ? $1 : undef;
            push @stack, { type => undef, key => $k };
        }
        else {
            my $blk = pop @stack;
            last unless @stack;
            $stack[-1]{type} = $1
                if $text =~ /'\@type'(?:\s*=>|\}\s*=)\s*'(\w+)'/ && !$blk->{type};
            push @found, [ $stack[-1]{type}, $blk->{key}, $blk->{type} ]
                if $blk->{type} && $blk->{key} && $stack[-1]{type};
        }
    }
    return @found;
}

my @files = ('lib/EV/Telegram/TDLib.pm', glob 'lib/EV/Telegram/TDLib/*.pm');
my ($checked, @bad, @unknown) = (0);
for my $f (@files) {
    next if $f =~ /Schema\.pm\z/;
    open my $h, '<', $f or die "$f: $!";
    my $src = do { local $/; <$h> };
    close $h;
    for my $t (scan($src)) {
        my ($outer, $field, $inner) = @$t;
        my $declared = $SLOT{$outer} && $SLOT{$outer}{$field};
        # the outer class or field may be one we do not model (a plain option
        # hash, not a TDLib object); those are not errors
        unless (defined $declared) { push @unknown, "$f: $outer.$field"; next }
        $checked++;
        push @bad, "$f: $outer.$field declares $declared but is given $inner"
            unless slot_ok($declared, $inner);
    }
}

cmp_ok $checked, '>', 10, "checked $checked nested object slots against the schema";
is_deeply \@bad, [], 'every nested @type is valid for the slot it sits in'
    or diag join "\n", @bad;

diag sprintf '%d nested literals were in slots the schema does not model (option '
    . 'hashes and the like)', scalar @unknown;

done_testing;
