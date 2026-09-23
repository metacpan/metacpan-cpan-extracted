use strict;
use warnings;
use Test::More;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# An option the code reads but no entry names is invisible: the reader cannot
# guess it, and most of them rename the TL field they set, so working it out
# from Telegram's own documentation does not help either.

# Every sub is tracked, private ones included. Matching only ^sub [a-z] would
# leave the name pointing at the previous public method while scanning a
# private helper, and blame the helper's reads on it -- which is exactly the
# mistake that made an earlier scan report twice as many gaps as there were.
my %reads;
for my $f (glob 'lib/EV/Telegram/TDLib.pm lib/EV/Telegram/TDLib/*.pm') {
    next if $f =~ /Schema|Cookbook/;
    open my $h, '<', $f or die "$f: $!";
    my ($sub, $in_pod) = ('', 0);
    while (my $l = <$h>) {
        $in_pod = 1 if $l =~ /^=\w/;
        $in_pod = 0 if $l =~ /^=cut/;
        next if $in_pod;
        $sub = $1 if $l =~ /^sub (\w+)/;
        next unless $sub && $sub !~ /^_/;
        $reads{$sub}{$1} = 1 while $l =~ /\$opt(?:->)?\{(\w+)\}/g;
    }
    close $h;
}
cmp_ok scalar(keys %reads), '>', 100, 'the scan found methods that read options';

# these are documented once in CONVENTIONS rather than in every entry
my %general = map { $_ => 1 }
    qw(parse_mode reply_markup business_connection_id limit offset);

open my $fh, '<', 'lib/EV/Telegram/TDLib.pm' or die $!;
my (@blocks, $cur);
while (my $l = <$fh>) {
    if ($l =~ /^=head3\s+(.*)/) {
        push @blocks, $cur if $cur;
        my @m; my $sig = $1;
        push @m, $1 while $sig =~ /(\w+)\(/g;
        # the signature line is not part of the body, so an option has to be
        # described rather than merely named in a sibling's parameter list
        $cur = { methods => \@m, body => '' };
        next;
    }
    $cur->{body} .= $l if $cur;
}
push @blocks, $cur if $cur;
close $fh;
cmp_ok scalar(@blocks), '>', 100, 'and entries to check them against';

my (@undoc, $checked);
for my $b (@blocks) {
    for my $m (@{ $b->{methods} }) {
        next unless $reads{$m};
        $checked++;
        for my $o (sort keys %{ $reads{$m} }) {
            next if $general{$o};
            # as C<name>, not as a bare word: prose mentioning the same word
            # for another reason is not a description of the option
            push @undoc, "$m: $o" unless $b->{body} =~ /C<+\s*\Q$o\E\b/;
        }
    }
}
cmp_ok $checked, '>', 150, 'and matched them up';
is_deeply \@undoc, [], 'every option a method reads is named where it is documented';
diag "undocumented: $_" for @undoc;

done_testing;
