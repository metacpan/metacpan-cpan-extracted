use strict;
use warnings;
use Test::More;
use FindBin;

use_ok('Game::Senet');
use_ok('Game::Senet::Engine');
use_ok('Game::Senet::Sticks');
use_ok('Game::Senet::Move');
use_ok('Game::Senet::Rules');
use_ok('Game::Senet::Notation');
use_ok('Game::Senet::Variant');
use_ok('Game::Senet::Error');
use_ok('Game::Senet::Result');
use_ok('Game::Senet::Bot');
use_ok('Game::Senet::Terminal');

# The XS loaded, which is the only thing this file is really asking: a pure-Perl
# fallback does not exist, so a failure here is a build failure and every other
# file after it would report a confusing shape of the same thing.
can_ok('Game::Senet::Engine', qw(new of_string clone at put lift side set_side
                                 pieces count home consistent ply set_ply
                                 to_string key_hex));
can_ok('Game::Senet::Engine', qw(house_of row_of col_of is_marked all_houses
                                 marked_houses rules rules_named rules_id
                                 abi_version live other piece_of
                                 chances extra moves));
can_ok('Game::Senet::Engine', qw(apply forfeit unapply status how winner ply_cap walk));
can_ok('Game::Senet::Sticks', qw(throw_for light_of roll_of roll_for extra_throw));
can_ok('Game::Senet::Move', qw(side roll from to swap back off walk trace));
can_ok('Game::Senet::Rules', qw(new rules side only ply position key board home status how winner
                               is_over moves apply forfeit undo depth));
can_ok('Game::Senet::Notation', qw(house_ok parse_move format_move format_display format_forfeit
                                   validate_position parse_record format_record));
can_ok('Game::Senet', qw(new side sticks throw roll legal play play_or_die error undo resign is_over result
                         turn side_of seat_of variant first seed throws ply position key home at chances
                         log forfeits_since to_record to_text from_text replay));
can_ok('Game::Senet::Variant', qw(new named custom of names fields name describe as_hash equals exit_for));
can_ok('Game::Senet::Error', qw(of code message detail codes message_for));
can_ok('Game::Senet::Result', qw(winner loser how is_draw final home plies throws));
can_ok('Game::Senet::Bot', qw(new choose think level budget levels rung));
can_ok('Game::Senet::Terminal', qw(new run start options board_lines screen show candidates steer pick
                                   command readout sticks_text roll_words events save take_back play_again));
can_ok('Game::Senet::Engine', qw(evaluate greedy search expect));

for my $module (qw(Engine Sticks Move Rules Notation Variant Error Result Bot Terminal)) {
    no strict 'refs';
    is(${"Game::Senet::${module}::VERSION"}, $Game::Senet::VERSION, "Game::Senet::$module carries the dist's version");
}

# THE DIST PINS ITS OWN ABI EXACTLY; a CONSUMER uses >=, never ==, which is the
# rule sen_abi.h states. This assertion exists to catch an UNINTENDED bump:
# version 1 is the board and the rule sets as data, version 2 appended the
# chance of a roll, version 3 what a roll allows, version 4 a move made and
# how a game ends, version 5 the evaluation and the search.
is(Game::Senet::Engine->abi_version, 5, 'the ABI is at version 5');
cmp_ok(Game::Senet::Engine->abi_version, '>=', 1, 'and a consumer written against 1 accepts it');
ok(Game::Senet::Engine::_abi_ptr(), 'the table has an address');

my @versions = map { no strict 'refs'; $_ . ' ' . (${"${_}::VERSION"} // 'none') }
    qw(Game::Senet Game::Senet::Engine Game::Senet::Sticks Game::Senet::Move Game::Senet::Rules
       Game::Senet::Notation Game::Senet::Variant Game::Senet::Error Game::Senet::Result
       Game::Senet::Bot Game::Senet::Terminal);
my @wrong = grep { !/ \Q$Game::Senet::VERSION\E\z/ } @versions;
is("@wrong", '', "every module is version $Game::Senet::VERSION, moved together");
my @stale;
for my $module (map { (split / /)[0] } @versions) {
    (my $path = "$module.pm") =~ s{::}{/}g;
    open my $pm, '<', $INC{$path} or die "cannot read $INC{$path}: $!";
    my ($said) = do { local $/; <$pm> } =~ /^=head1 VERSION\n\nVersion (\S+)$/m;
    push @stale, "$module " . ($said // 'none') unless ($said // '') eq $Game::Senet::VERSION;
}
is("@stale", '', '  and so does the Version line of every POD');
{
    open my $bin, '<', "$FindBin::Bin/../bin/senet" or die "cannot read bin/senet: $!";
    my ($line) = grep { /\Aour \$VERSION/ } <$bin>;
    like($line // '', qr/\Aour \$VERSION = '\Q$Game::Senet::VERSION\E';/, '  and bin/senet with them');
}

diag("Testing Game::Senet $Game::Senet::VERSION, Perl $], $^X");

done_testing();
