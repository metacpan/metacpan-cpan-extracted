# $File: //member/autrijus/AIBots/lib/Games/AIBot.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 692 $ $DateTime: 2002/08/17 09:29:13 $

require 5.005;
package Games::AIBot;
$Games::AIBot::VERSION = '0.01';

use strict;
use integer;

=head1 NAME

Games::AIBot - An AI Bot object

=head1 VERSION

This document describes version 0.01 of Locale::Maketext::Fuzzy.

=head1 SYNOPSIS

    use Games::AIBot;
    my $bot = Games::AIBot->new($botfile);
    $bot->tick;

=head1 DESCRIPTION

This module exists exclusively for the purpose of the F<aibots>
script bundled in the distribution.  Please see L<aibots> for
an explanation of the game's mechanics, rules and tips.

=cut

use fields qw/max_fuel  max_ammo  max_life
              fuel      ammo      life
              x         y         h         score
              enemy_x   enemy_y   enemy_h   enemy_l
              snode_x   snode_y
              friend_x  friend_y  friend_h  friend_l
              bumped_x  bumped_y
              shield    cloak     laymine
              bumped    found     burn
              id        dead      botcount
              lastcmd   state     var       pic
              name      author    team      stack
              queue     missiles  cmds      line
              lineidx   stateidx  condidx/;


# ===========
# Constructor
# ===========

sub new {
    my $class = shift;
    my $bot   = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{$class.'::FIELDS'}], $class };
    $bot->loadfile($_[0]);
    push @{$bot->{'cmds'}}, 'attempt destruct';

    my $count;
    foreach my $line (@{$bot->{'cmds'}}) {
        $count++;
        my $condflag = int($line !~ m/^(?:\$|if|else|elsif|unless|print)/);
        $line =~ s/\$(\w+)/exists($bot->[0]->{$1}) ? "\${\$bot}{$1}" : "\${\$bot}{'var'}{$1}"/eg;
        $line =~ s/\&(?=\w+)/\$bot->_/g;
        $bot->{'lineidx'}     .= $condflag; # and (index($line, '$') > -1));
        $bot->{'stateidx'}{$1} = $count
	    if $line =~ /^sub[\s\t]+(.+)[\s\t]+{/ or $line =~ /^(.+):[\s\t]*{/;
        $bot->{'condidx'}     .= int($line ne '}') +
	    ($line =~ /^(?:if|unless|elsif|else|sub|.+:)[\s\t]/);
    }

    $bot->{'queue'}    = [];
    $bot->{'missiles'} = [];
    $bot->{'line'}     = 0;

    return $bot;
}

sub loadfile {
    my ($bot, $file) = @_;
    my @include;

    open _, $file or die "Cannot load bot $file: $!";

    while (<_>) {
        chomp;
        s/#[\s\t].+//;
        s/^[\s\t]+//;
        s/[\s\t\;]+$//;
        s/^(.+)[\s\t]+(if|unless)[\s\t]+(.+)$/$2 ($3) {\n$1\n}\n/g;
        if (/^require[\s\t]+\'?([^\']+)\'?/) {
            push @include, substr($file, 0, rindex($file, '/')+1).$1;
        }
        else {
            push (@{$bot->{'cmds'}}, split("\n", $_)) if $_;
        }
    }

    close _;

    $bot->loadfile($_) foreach @include;
}

sub cond {
    my $bot = $_[0];
    my $cmd = eval($_[1]);
    if ($@) { die "[Cond $_[1] :".$bot->{'name'}.':'.$bot->{'state'}.'] '.$@ };
    return $cmd;
}

sub tick {
    my $bot = shift;
    my $count;

    while (my $line = $bot->nextline()) {
        next if $line eq '}';
        if ($count++ > 100) {
            warn "recursion too deep";
            return;
        }

        if ($line =~ /^\$[{\w]/) {
            $bot->cond($line);
        }
        elsif ($line =~ /^(?:else|elsif)[\s\t]/) {
            $bot->endif();
        }
        elsif ($line =~ /^sub[\s\t]+(.+)[\s\t]+{$/ or $line =~ /^(.+):[\s\t]*{$/) {
            $bot->{'state'} = $1;
        }
        elsif ($line =~ /^goto[\s\t]+(.+)/) {
            pop @{$bot->{'stack'}};
            $bot->gotostate($1);
        }
        elsif ($line =~ /^call[\s\t]+(.+)/ or $line =~ /^(.+)\(\)$/) {
            push @{$bot->{'stack'}}, [@{$bot}{'state', 'line'}];
            # print "call from line ",$bot->{'line'},"\n";
            $bot->gotostate($1);
        }
        elsif ($line eq 'redo') {
            $bot->gotostate($bot->{'state'});
        }
        elsif ($line eq 'return') {
            warn $bot->{'name'}." cannot return from state ".$bot->{'state'}
		unless ($bot->{'stack'} and @{$bot->{'stack'}});
            eval{@{$bot}{'state', 'line'} = @{pop(@{$bot->{'stack'}})}};
            # print "return to line ",$bot->{'line'},"\n";
        }
        elsif ($line =~ /^(if|unless)[\s\t]+(.+){$/) {
            if ($1 eq 'if' xor $bot->cond($2)) {
                while (my $cond = $bot->elseif()) {
                    ($bot->{'line'}++, last) if ($bot->cond($cond));
                }
                $bot->{'line'}--; # end all blocks
            }
        }
        elsif ($line =~ /^(e|d)(?:nable|isable)[\s\t]+(\w+)/) {
            return $line if ($1 eq 'e' xor $bot->{$2});
        }
        elsif ($line =~ /^print[\s\t]+/) {
            $bot->cond($line);
            print "\n";
        }
        else {
            # command
            my $times = ((int($1) eq $1) ? $1 : $bot->cond($1))
		if ($line =~ s/\s*\*\s*(.+)$//);
            my @cmds;

            push @cmds, $line for (1..($times || 1));
            return @cmds;
        }
    }
}

sub endif {
    my $bot   = shift;
    my $depth = 1;

    while ($bot->{'line'}++) {
        $depth += substr($bot->{'condidx'}, $bot->{'line'} - 1, 1) - 1;
        return unless $depth;
    }

    die ("Unterminated condition block from ".$bot->{'state'});
}

sub elseif {
    my $bot   = shift;
    my $depth = 1;

    $bot->endif();
    my $line = $bot->nextline();

    if ($line eq 'else {') {
        return 1;
    }
    elsif ($line =~ /^(?:elsif[\s\t])(.+){/) {
        return $1;
    }

    return;
}

sub gotostate {
    my $bot   = shift;
    my $state = shift;

    # print "=>$state\n";

    defined($bot->{'line'} = $bot->{'stateidx'}{$state})
        or die ($bot->{'name'}.": cannot goto state $state");

    $bot->{'state'} = $state;
}

sub nextline {
    my $bot = shift;
    my $lineflag = substr($bot->{'lineidx'}, $bot->{'line'}, 1);
    my $line = $bot->{'cmds'}[$bot->{'line'}++];
    return $lineflag ? eval("\"$line\"") : $line;
}


# ===================
# Utility Subroutines
# ===================

sub _nearst {
    my ($bot, $rel) = @_;

    return 99999 unless defined $bot->{"${rel}_x"};
    return abs($bot->{"${rel}_x"} - $bot->{'x'}) +
           abs($bot->{"${rel}_y"} - $bot->{'y'});
}

sub _onnode {
    my $bot = shift;

    return not $bot->_nearst('snode');
}

sub _inperim {
    my ($bot, $rel) = @_;

    return ($bot->{"${rel}_x"} and $bot->{"${rel}_y"}  and
            abs($bot->{"${rel}_x"} - $bot->{'x'}) <= 1 and
            abs($bot->{"${rel}_y"} - $bot->{'y'}) <= 1);
}

sub _distance {
    my ($bot, $x, $y) = @_;

    return abs($x - $bot->{'x'}) + abs($y - $bot->{'y'});
}

sub _ready {
    return Games::AIBots::bot_ready(@_);
}

sub _damaged {
    my $bot = shift;
    return 100 - int($bot->{'life'} / $bot->{'max_life'} * 100);
}

sub _turnto {
    my ($bot, $head) = @_;
    return if !$head or $bot->{'h'} eq $head;

    my $delta = (index('8624', $bot->{'h'})
		- index('8624', $head) + 4) % 4;

    return ('left')     if $delta == 1;
    return ('left * 2') if $delta == 2;
    return ('right')    if $delta == 3;
}

sub _headto {
    my ($bot, $rel) = @_;

    return unless defined $bot->{"${rel}_x"};

    if ($bot->{"${rel}_x"} == $bot->{'x'}) {
        return ('2', '8')[$bot->{"${rel}_y"} < $bot->{'y'}];
    }
    elsif ($bot->{"${rel}_y"} == $bot->{'y'}) {
        return ('6', '4')[$bot->{"${rel}_x"} < $bot->{'x'}];
    }
}

sub _toggle {
    my $bot = shift;
    $bot->{'var'}{'_'.$bot->{'state'}}
	= !$bot->{'var'}{'_'.$bot->{'state'}};
    return !$bot->{'var'}{'_'.$bot->{'state'}};
}

sub _found {
    my $bot = shift;

    return (
        @_ ? (index($_[0], '|') > -1)
               ? $bot->{'found'} =~ /^(?:$_[0])/
               : $bot->{'found'} eq $_[0]
           : $bot->{'found'}
    );
}

sub _bumped {
    my $bot = shift;

    return (
        @_ ? (index($_[0], '|') > -1)
               ? $bot->{'bumped'} =~ /^(?:$_[0])/
               : $bot->{'bumped'} eq $_[0]
           : $bot->{'bumped'}
    );
}

1;

=head1 SEE ALSO

L<aibots>, L<Games::AIBots>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

Files under the F<bots/> directory was contributed by students in
the autonomous learning experimnetal class, Bei'zheng junior high
school, Taipei, Taiwan.

=head1 COPYRIGHT

Copyright 2001, 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
