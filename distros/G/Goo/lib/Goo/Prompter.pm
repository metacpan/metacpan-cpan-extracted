package Goo::Prompter;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Prompter.pm
# Description:  Prompt the user for info.
#
# Date          Change
# -----------------------------------------------------------------------------
# 06/02/2005    Auto generated file
# 06/02/2005    Needed a modular way of doing this consistently
# 06/03/2005    Added term completion
# 10/08/2005    Added the ability to record a usage Trail - all user input
#               comes via the Prompter so it is a natural place to start.
# 11/08/2005    Added method: askForKey
# 08/11/2005    Added method: editText
# 13/11/2005    Removed delegation to Prompter.pm - decided to trap actions
#               only - i may return to delegation if more information is
#               required for the GooTrail. The Trail recording in Thing.pm is
#               sufficient at the moment.
#
###############################################################################

use strict;

use Data::Dumper;
use Term::ReadKey;
use Term::Complete;
use Text::FormatTable;
use Term::ANSIColor qw(:constants);

my $title     = BLACK ON_GREEN;
my $highlight = WHITE;            # select options in questions
my $lowlight  = BLUE;             # informative options
my $neonlight = GREEN;            # BOLD!
my $reset     = RESET;            # needed for interpolation

my $clear = "";                   # keep a clear cache for faster clears


###############################################################################
#
# pick_command - pick a command from a list
#
###############################################################################

sub pick_command {

    my ($commands, $default) = @_;

    $default = $default || "";

    # pull out all the command tokens - those that match [
    my @commands = grep { $_ =~ /\[/ } split(/\s+/, $commands);

    my %valid_options;

    foreach my $command (@commands) {

        my ($option) = $command =~ m/\[(.)\]/g;    # grab the command [k]ey = k

        next unless ($option);

        $command =~ s/\W//g;                       # remove the [] in the command word

        $valid_options{$option} = ucfirst(lc($command));

        # highlight the option in the question
        if ($option eq $default) {

            # highlight the keys in the question
            $commands =~ s/\[($option)/\[$neonlight$1/g;
            $commands =~ s/($option)\]/$1$reset\]/g;
        } else {
            $commands =~ s/\[($option)/\[$highlight$1/g;
            $commands =~ s/($option)\]/$1$reset\]/g;
        }
    }

    print $commands . ": ";

    # wait for a valid keystroke
    while (my $key = get_key()) {

        # no command selected
        if ($key =~ /\n/) {
            say();
            if ($default) {
                return $default;
            }
            return "";
        }

        # matches a lowercase key
        if ($key =~ /[a-z0-9]/) {
            say();
            return $key;

        }

        # valid options
        if (exists $valid_options{$key}) {

            # go to a newline
            say();
            return $key;
        }
    }

}


###############################################################################
#
# pick_some - pick more than one answer to a question
#
###############################################################################

sub pick_some {

    my ($question, @answers) = @_;

    my @selected_answers;

    while (my $answer = pick_one($question, @answers)) {

        say("Selected $answer.");

        # remove this answer from the list
        @answers = grep { $_ ne $answer } @answers;

        # remember the user selected it
        push(@selected_answers, $answer);

    }

    return @selected_answers;

}


###############################################################################
#
# pick_one - pick one from the list?
#
###############################################################################

sub pick_one {

    my ($question, @answers) = @_;

    $question =~ s/\?//g;

    print $question . " ";

    my $counter = 1;
    my $options = {};

    foreach my $answer (@answers) {

        print "\n[", $highlight, $counter, RESET, "]$answer ";
        $options->{$counter} = $answer;
        $counter++;

    }

    print "? ";

    my $choice = get_response();

    return $options->{$choice} || "";

}

###############################################################################
#
# confirm - yes or no? - default to "y"es
#
###############################################################################

sub confirm {

    my ($question, $default) = @_;

    $default = $default || "Y";

    $question =~ s/\s+$//;

    my $yes_or_no = $default eq "Y" ? "Y/n" : "y/N";

    print $question . " [", $highlight, $yes_or_no, RESET, "] ";

    my $answer = get_response();

    # if no specific answer then set to default
    if (not $answer) { $answer = $default; }

    # if the answer matches yes then confirm
    return $answer =~ /^[Yy]/;

}

###############################################################################
#
# insist - ask a question and insist on an answer
#
###############################################################################

sub insist {

    my ($question) = @_;

    while (1) {
        my $response = ask($question);
        if ($response ne "") {
            return $response;
        }
    }

}

###############################################################################
#
# ask - ask a question
#
###############################################################################

sub ask {

    my ($question, $default_answer) = @_;

    $question =~ s/\s+$//;
    print $question . " ";

    if ($default_answer) {
        print "[$default_answer] ";
    }

    return get_response() || $default_answer || "";

}

###############################################################################
#
# keep_asking - keep asking the same question
#
###############################################################################

sub keep_asking {

    my ($question) = @_;

    my @answers;

    while (1) {

        print $question. " ";

        if (scalar(@answers) > 0) {
            print " [", $lowlight, join(', ', @answers), RESET, "] ";
        }

        my $answer = get_response();
        if ($answer eq "") { last; }
        push(@answers, $answer);
    }

    return @answers;

}


###############################################################################
#
# say - say something
#
###############################################################################

sub say {

    my ($something) = @_;

    $something = $something || "";

    print $something . "\n";

}


###############################################################################
#
# show_title - say something on a green background! - this is the goo!
#
###############################################################################

sub show_title {

    my ($something) = @_;

    print $title . $something . $reset . "\n";

}

###############################################################################
#
# stop - do a die
#
###############################################################################

sub stop {

    my ($reason) = @_;

    # say it in NEON
    yell($reason);
    exit;

}


###############################################################################
#
# clear - clear the screen
#
###############################################################################

sub clear {

    if ($clear) {

        # re-use if cached
        print $clear;
    } else {
        $clear = system("/usr/bin/clear");
    }
}

###############################################################################
#
# yell - say something loudly!!!
#
###############################################################################

sub yell {

    my ($something) = @_;

    # say it in NEON
    say($neonlight . $something . RESET);

}


###############################################################################
#
# highlight_options - take a string and highlight any options you find
#
###############################################################################

sub highlight_options {

    my ($string) = @_;

    # highlight everything after [
    $string =~ s/\[/\[$highlight/g;
    $string =~ s/\]/$reset\]/g;

    return $string;

}


###############################################################################
#
# trace - debugging aid
#
###############################################################################

sub trace {

    my ($message) = @_;

    notify(caller() . " - $message");

}


###############################################################################
#
# dump - debugging aid
#
###############################################################################

sub dump {

    my ($variable) = @_;

    trace(Dumper($variable));

}


###############################################################################
#
# prompt - prompt for something loudly!!!
#
###############################################################################

sub prompt {

    my ($prompt) = @_;

    # say it in NEON
    print $neonlight . $prompt . RESET . "> ";

    return get_response();

}

###############################################################################
#
# notify - say something and pause for a while
#
###############################################################################

sub notify {

    my ($string) = @_;

    say($string);

    # pause for a keystroke
    get_key();

}

###############################################################################
#
# get_key - return a single keystroke
#
###############################################################################

sub get_key {

    # see recipe 15.6 Perl Cookbook
    ReadMode('cbreak');
    my $char = ReadKey(0);
    ReadMode('normal');
    return $char;

}

###############################################################################
#
# ask_with_completion - ask with tab completion - <cntrl d> for a list of possibles
#
###############################################################################

sub ask_with_completion {

    my ($question, @list) = @_;

    return Complete($question, @list);

}

###############################################################################
#
# get_response - return a response
#
###############################################################################

sub get_response {

    # restore line reading mode - turned off by WebDBLite?
    $/ = "\n";

    my $response = <STDIN>;

    # strip leading and trailing spaces
    $response =~ s/^\s+//g;
    $response =~ s/\s+$//g;

    return $response;

}

###############################################################################
#
# ask_for_key - prompt for a single key
#
###############################################################################

sub ask_for_key {

    my ($question) = @_;

    print $question . " ";

    my $key = get_key();

    print "\n";

    return $key;

}

1;


__END__

=head1 NAME

Goo::Prompter - Prompt the user for info.

=head1 SYNOPSIS

use Goo::Prompter;

=head1 DESCRIPTION

=head1 METHODS

=over

=item pick_command

pick a command from a list

=item pick_some

pick more than one answer to a question

=item pick_one

pick one from the list?

=item confirm

yes or no? - default to "y"es

=item insist

ask a question and insist on an answer

=item ask

ask a question

=item keep_asking

keep asking the same question

=item say

say something like in Perl6

=item show_title

say something on a green background! - this is The Goo!

=item stop

say something and then stop

=item clear

clear the screen

=item yell

say something loudly!!!

=item highlight_options

take a string and highlight any options you find

=item trace

print a trace message as a debugging aid

=item dump

use Data::Dumper to show the contents of a variable

=item prompt

prompt for something loudly!!!

=item notify

say something and pause for a while

=item get_key

return a single keystroke

=item ask_with_completion

ask with tab completion - <cntrl d> shows a list of possible alternatives

=item get_response

return a response

=item ask_for_key

prompt for a single key

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

