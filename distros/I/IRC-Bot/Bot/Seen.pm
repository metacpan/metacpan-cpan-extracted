package IRC::Bot::Seen;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);
use Cache::FileCache;
use Carp;

require Exporter;
@ISA     = qw(Exporter AutoLoader);
@EXPORT  = qw();
$VERSION = '0.02';

my $cache = new Cache::FileCache( { 'namespace' => 'BotSeen' } );

# Set us up the bomb
sub new {

    my $class = shift;
    my $self  = {};
    return bless $self, $class;

}

# Store seen data
sub log_seen {

    my ( $self, $who, $message ) = @_;
    $message = $message . " on " . scalar(localtime);
    $cache->set( $who, $message, "never" );

}

# Recieves list of names from your script
# to load current channel users.
sub load_current {

    my ( $self, $names, $channel ) = @_;
    my @names = split ( / /, $names );
    $channel =~ s/=//;
    $channel =~ s/\s+//;
    $channel =~ s/\n+//;
    my $msg   = "On $channel as of " . scalar(localtime);

    foreach my $name (@names) {
        $name =~ s/^@//;
        $name =~ s/^\+//;
        $name =~ s/^\%//;
        $cache->set( $name, $msg, "never" );
    }

}

# Got a seen request, handle it.
sub get_seen {

    my ( $self, $who ) = @_;

    $who =~ s/\s+//;

    my $mesg = $cache->get($who);

    if ( defined $mesg ) {
        return "Saw $who $mesg";
    }
    else {
        return "Haven't Seen $who";
    }
}

# Clear cache of unwanted seen data
sub clear_seen {

    my $self = shift;
    $cache->clear();

}

1;
__END__

=head1 NAME

Seen.pm - A module for handling seen requests for IRC::Bot.

=head1 SYNOPSIS

  use IRC::Bot::Seen;
  my $seen = IRC::Bot::Seen->new();

  # later on...

  # Log join event, assuming Poe::Component::IRC use..
  sub on_join {
    my ( $kernel, $who, $where ) = @_[ KERNEL, ARG0, ARG1 ];
    my $nick = ( split /!/, $who )[0];
    
    # Do Stuff...

    $seen->log_seen( $nick, "Joining $where" );

  }

=head1 DESCRIPTION

Provides seen functionality for an IRC bot.

=head1 METHODS

=over 4

=item log_seen()

B<log_seen()> takes two arguments, stores info into cache.  Returns 
nothing.

Use like so:

 $seen->log_seen( $nick, $msg );

=item get_seen()

B<get_seen()> takes a nickname as an argument.  Checks to see if nick is 
defined in the cache and returns the results.

Use like so:

 $seen->get_seen( $nick );

=item load_current()

B<load_current()> takes list from irc_353 (names command) as an argument 
and loads it into the cache, so current users on the channel are seen.

Use like so:

 $seen->load_current( $names );

=item clear_seen()

B<clear_seen()> clears the cache, takes no args.

=back

=head1 CREDITS

See IRC::Bot

=head1 AUTHOR

Benjamin Smith  defitro@just-another.net

=head1 SEE ALSO

IRC::Bot POE::Component::IRC Cache::FileCache

=cut
