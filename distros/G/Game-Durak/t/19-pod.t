#!perl
use strict;
use warnings;
use Test::More;

# t/pod.t and t/pod-coverage.t are author tests and they SKIP for anybody who
# has not installed Test::Pod. A skipped check is one nobody notices is not
# running, so the sections every module in this distribution promises are
# checked here, with nothing but core Perl.

my @SECTIONS = qw(NAME VERSION SYNOPSIS DESCRIPTION AUTHOR);

my @PARAGRAPHS = (
    [ 'lib/Game/Durak/Card.pm',
      qr/third rank order/,
      'the three rank orders in the tree' ],
    [ 'lib/Game/Durak/Card.pm',
      qr/the order between them is the rule/,
      'why beats() answers in the order it does' ],
    [ 'lib/Game/Durak/Deck.pm',
      qr/sixteenth copy/,
      'which copy of the shuffle this is' ],
    [ 'lib/Game/Durak/Bout.pm',
      qr/Read that again for the word/,
      'the cap being the hand BEFORE the bout' ],
    [ 'lib/Game/Durak.pm',
      qr/B<At any time> is the departure/,
      'the exchange, against the source own sentence' ],
    [ 'lib/Game/Durak.pm',
      qr/no choice in it is resolved by the engine/,
      'why done and take are conditional' ],
    [ 'lib/Game/Durak.pm',
      qr/The discard is a count because the rules say/,
      'the heap being a count' ],
    [ 'lib/Game/Durak/Search.pm',
      qr/judgements the measurement threw out/,
      'what the ladder measured and removed' ],
);

opendir my $dh, 'lib/Game/Durak' or die "lib/Game/Durak: $!";
my @modules = ('lib/Game/Durak.pm',
               map { "lib/Game/Durak/$_" } sort grep { /\.pm\z/ } readdir $dh);
closedir $dh;

cmp_ok(scalar @modules, '>=', 9, scalar(@modules) . ' modules');

for my $file (@modules) {
    open my $fh, '<', $file or die "$file: $!";
    my $pod = do { local $/; <$fh> };
    close $fh;

    for my $section (@SECTIONS) {
        like($pod, qr/^=head1 \Q$section\E$/m, "$file has $section");
    }

    like($pod, qr/^=head1 LICENSE AND COPYRIGHT$/m, "$file has its licence");
    like($pod, qr/^=cut$/m, "$file closes its pod");

    # The prose only: a decrementing loop is not an em dash, and the '--'
    # that introduces a citation is an attribution and not one either.
    my ($prose) = $pod =~ /^__END__$(.*)\z/ms;
    $prose = '' unless defined $prose;
    unlike($prose, qr/\x{2014}|\xe2\x80\x94/,
           "$file has no em dashes in its prose");
}

for my $want (@PARAGRAPHS) {
    my ($file, $pattern, $what) = @$want;
    open my $fh, '<', $file or die "$file: $!";
    my $pod = do { local $/; <$fh> };
    close $fh;
    like($pod, $pattern, "$file still explains $what");
}

# The bin scripts are documentation too: a measurement nobody can reproduce
# is a number in a plan file.
for my $script (qw(bin/durak bin/soak bin/ladder)) {
    open my $fh, '<', $script or die "$script: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    like($text, qr/^=head1 NAME$/m, "$script says what it is");
    like($text, qr/^=head1 (SYNOPSIS|DESCRIPTION)$/m, "$script says how to run it");
}

done_testing();
