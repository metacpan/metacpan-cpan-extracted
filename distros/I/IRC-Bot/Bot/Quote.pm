package IRC::Bot::Quote;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);
use Carp;
use Cache::FileCache;

require Exporter;

@ISA     = qw(Exporter AutoLoader);
@EXPORT  = qw();
$VERSION = '0.01';

my $cache = Cache::FileCache->new(
    {
        'namespace'          => 'BotQuote'
    }
);

# Set us up the bomb
sub new {

    my $class = shift;
    my $self = {};
    return $self, $class;

}

# Set quote in cache
sub quote_set {

    my ( $self, $who, $quote ) = @_;
    $cache->set( $who, $quote );
    return "Saved quote for $who";
    
}

# Check for existing quote, pass it to channel 
sub quote_query {

    my ( $self, $who ) = @_;

    my $user = $cache->get($who);

    if ( defined $user ) {
        return "<$who> said: \"$user\"";
    }
    else {
        return "I don't know who $who is.";
    }
    
}

# Forget user i.e. remove from cache 
sub quote_forget {

    my ( $self, $who ) = @_;
    my $nick = $cache->clear($who);
    return "Forgot $who";
    
}

# Blow it to hell.
sub DESTROY {

    my $self = shift;
    $cache->purge();

}

1; # Goodnight, folks.

__END__

=head1 NAME

Quote.pm - A module to record user quotes for IRC::Bot.


=head1 SYNOPSIS

  use Bot::Quote
  my $quote = Bot::Quote->new();

  # later on...

  # Lets look and see if they have a quote recorded.
  sub on_public {
    my ( $kernel, $who, $where, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];

    # Do Stuff...

        elsif ( $msg =~ m/^!quote/i ) {
           my @arg  = split ( / /, $msg );
	   my $name = $arg[1];

	   if ($name) {
	       my $said = $quote->quote_query( $name );
	       $kernel->post( 'privmsg', $where, $said ); 
	   }
	   else { 
               $kernel->post( 'privmsg', $where, "Need help, $nick?"); 
           }

  }

=head1 DESCRIPTION

Provides methods for recording quotes for users on a channel

=head1 METHODS

=over 3

=item quote_set()

B<quote_set()> takes two arguments, users nick and the quote to record.

Use like so:

 my $set = $quote->set_quote( $nick, $text );
 $kernel->post( 'privmsg', $where, $set );

=item quote_query()

B<quote_query()> Takes one argument, a nick.  Checks to see if nick has quote recorded.  If so, it will return the quote, otherwise it will let you know if it was not found.

Use like so:

 my $get = $quote->quote_query( $nick );
 $kernel->post( 'privmsg', $where, $get );
 
=item quote_forget()

B<quote_forget()> Takes one argumet, a nick.  This will remove the nick from the cache.  Returns a message letting you know nick has been removed.

Use like so:

 my $forget = $quote->quote_forget( $nick );
 $kernel->post( 'privmsg', $where, $forget );
 
=back

=head1 CREDITS

See Bot

=head1 AUTHOR

Benjamin Smith defitro@just-another.net

=head1 SEE ALSO

Bot POE::Component::IRC Cache::FileCache

=cut
