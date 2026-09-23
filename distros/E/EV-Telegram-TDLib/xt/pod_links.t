use strict;
use warnings;
use Test::More;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# An internal L</section> must name a heading's full text, not a substring of
# one. A link into a grouped =head3 that lists several methods has to quote the
# whole line, so renaming one signature silently breaks every link to its group.
my @FILES = ('lib/EV/Telegram/TDLib.pm', 'lib/EV/Telegram/TDLib/Cookbook.pod');

sub slurp { open my $h, '<', $_[0] or die "$_[0]: $!"; local $/; <$h> }

my %heading;
for my $f (@FILES) {
    for my $line (split /\n/, slurp($f)) {
        next unless $line =~ /\A=head[1-4]\s+(.*\S)/;
        my $h = $1;
        $h =~ s/[A-Z]<([^<>]*)>/$1/g;      # strip simple formatting codes
        $heading{$h} = 1;
    }
}

ok scalar(keys %heading), 'found headings to link against';

my @broken;
my $links = 0;
for my $f (@FILES) {
    my $src = slurp($f);
    # L</target> and L<text|/"target">, with or without quotes
    while ($src =~ m{L<(?:[^<>|]*\|)?/(?:"([^"]+)"|([^<>"]+))>}g) {
        my $target = defined $1 ? $1 : $2;
        next unless defined $target && length $target;
        $links++;
        push @broken, "$f: L</$target>" unless $heading{$target};
    }
}

# without this the check passes by finding nothing: a link regex that stops
# matching leaves @broken empty and reports every link sound
cmp_ok $links, '>', 20, 'the link scan found links to check';

is_deeply \@broken, [], 'every internal POD link names a real heading';
diag $_ for @broken;

done_testing;
