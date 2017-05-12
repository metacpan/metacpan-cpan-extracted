use strict;
$|=1;
use Games::Poker::OPP;
my ($username, $password) = @ARGV;
my $opp = new Games::Poker::OPP (
    username => $username,
    password => $password,
    callback => sub {
        my $game = shift->state();
        print $game->status;
        print "Hole cards: ", $game->hole, "\n";
        print "Board cards: ", $game->board, "\n";
        print "[F]old, [C]all/check [B]et/[R]aise\n";
        print "Your turn: ";
        my $action = <STDIN>;
        if ($action =~ /f/i) { $action = FOLD; }
        elsif ($action =~ /[br]/i) { $action = RAISE; }
        else { $action = CALL; }
        return $action;
    }, 
    status => sub {     
        my ($self, $cmd, @stuff) = @_; 
        if ($cmd == CHATTER || $cmd == INFORMATION) { 
            print @stuff, "\n";
            return;
        }
        return if $cmd == FOLD || $cmd == RAISE || $cmd == CALL
               || $cmd == BLIND;
        my $game = $self->state;
        return unless $game;
        print "\n---\n";
        print $game->status;
        print "Hole cards: ", $game->hole, "\n";
        print "Board cards: ", $game->board, "\n";
        print "---\n";
    }
);

print "Connecting...\n";
$opp->connect; 
print "Authorising...\n";
die "Authorization failed\n" unless $opp->joingame; 
print "Entering room.\n";
$opp->playgame
