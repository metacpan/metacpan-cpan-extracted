package IRC::Bot::Help;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);
use Carp;

require Exporter;

@ISA     = qw(Exporter AutoLoader);
@EXPORT  = qw();
$VERSION = '0.03';

my %help = (

    join => "\cB.join\cB #<chan> Joins Specfied channel",
    op => "\cB.op\cB #<chan> <nick> Ops specified nick on specified channel",
    deop  => "\cB.deop\cB #<chan> <nick> Deops Specified user on channel",
    hop   => "\cB.hop\cB #<chan> <nick> Gives specified user a %(Half Op)",
    dehop => "\cB.dehop\cB #<chan> <nick> DeHops Specified user on Channel",
    voice => "\cB.voice\cB #<chan> <nick> Gives the user a voice for +m chan",
    devoice =>
      "\cB.devoice\cB #<chan> <nick> Devoices specified user on channel",
    kick =>
"\cB.kick\cB #<chan> <nick> <reason> Kicks the user with specified reason",
    ban   => "\cB.ban\cB #<chan> <user\@host> Bans user\@host from chan",
    unban => "\cB.unban\cB #<chan> <user\@host> Un-Ban user\@host from chan",
    say   => "\cB.say\cB #<chan> <text> Say something witty to the chan",
    part  => "\cB.part\cB #<chan> Part Specified Channel",
    away  => "\cB.away\cB <msg> Put the bot in away status",
    back  => "\cB.back\cB Leave away status",
    nick  => "\cB.nick\cB <newnick> Change nick to <newnick>",
    identify => "\cB.identify\cB <password> Identify yourself with NickServ",
    msg   => "\cB.msg\cB <nick> <msg> Send a message to <nick>.",
    clear   =>
"\cB.clear\cB <logname> Clears Log File.  Bot, Server, and Channel are the aliases for logfiles that can be cleared",
    clearseen => "\cB.clearseen\cB Clears seen data from cache",
    topic => "\cB.topic\cB #<chan> <text> Set the topic of a channel",
    help => "\cB.help\cB Prints this help message.",

);

my %pub_help = (

    help   => "\cB!help\cB prints this help message.",
    uptime => "\cB!uptime\cB displays current bot uptime.",
    seen   => "\cB!seen <nick>\cB will display the last seen info for <nick>",
    quoteadd  => "\cB\!quote add <nick> \"<quote>\"\cB will add <quote> for <nick>.  If a quote exists, this will overwrite the current quote.",
    quotedel => "\cB\!quote del <nick>\cB will remove any quote for <nick>",
    quote => "\cB\!quote <nick>\cB will return quote for <nick> if one exists",

);

# Set us up the bomb
sub new {

    my $class = shift;
    my $self = {};
    return bless $self, $class;

}

# Someone asked a question, lets respond.
sub ask_help {

    my ( $self, $command ) = @_;

    if ( defined $command ) {
        if ( exists $help{$command} ) {
            return $help{$command};
        }
        else {
            return "Sorry! There is no help available for $command";
        }
    }
    else {
        return %help;
    }
}

# Someone asked for help in a chan, return list.
sub pub_help {

    my ( $self, $command ) = @_;

    if ( defined $command ) {
        if ( exists $pub_help{$command} ) {
            return $pub_help{$command};
        }
        else {
            return "Sorry! There is no help available for $command";
        }
    }
    else {
        return %pub_help;
    }
}

1;

__END__

=head1 NAME

Help.pm -  A module to dispatch help for IRC::Bot.

=head1 SYNOPSIS

  use IRC::Bot::Help;
  my $seen = IRC::Bot::Help->new();

  # later on...

  # User asks for help in DCC CHAT
  sub on_dcc_chat {
    my ( $kernel, $id, $who, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG3 ];
	     
    my $nick = ( split /!/, $who )[0];

    # Do Stuff...
    if ( $msg =~ m/^.help/i ) {
    
        my $topic = $help->ask_help('all');
        $kernel->post( NICK, 'dcc_chat', $id, $topic );

    }

  }

=head1 DESCRIPTION

Basically holds a list of help topics and dispatches them on demand.

=head1 METHODS

=over 2

=item ask_help()

B<ask_help()> Answers a question based on the argument given.  
If no arg is given, returns a list of all available help topics.

Use like so:

 my $topic = $help->ask_help('topic');

=item pub_help()

B<pub_help()> Pretty much does the same thing as ask_help(), only for
public commands.

Use like so:

 my %pubhelp = $help->pub_help();

=back

=head1 CREDITS

See IRC::Bot

=head1 AUTHOR

Benjamin Smith defitro@just-another.net

=head1 SEE ALSO

IRC::Bot POE::Component::IRC

=cut

