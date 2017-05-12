package IRC::Bot::Auth;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);
use Carp;
use Cache::FileCache;

require Exporter;

@ISA     = qw(Exporter AutoLoader);
@EXPORT  = qw();
$VERSION = '0.02';

my $cache = new Cache::FileCache(
    {
        'namespace'          => 'BotAuth',
        'default_expires_in' => 3600
    }
);

# Set us up the bomb
sub new {

    my $class = shift;
    my $self = {};
    return $self, $class;

}

# Set authorization Session.
sub auth_set {

    my ( $self, $who ) = @_;

    $cache->set( $who, $who );

}

# Check for existing Auth Session
sub is_auth {

    my ( $self, $who ) = @_;

    my $user = $cache->get($who);

    if ( defined $user ) {
        return 1;
    }
    else {
        return 0;
    }
}

# If session exists, grab it, and return it.
sub get_ses {

    my ( $self, $who ) = @_;
    my $nick = $cache->get($who);
    return $nick;

}

# Break it down now...
sub de_auth {

    my ( $self, $who ) = @_;

    if ( defined $who ) {
        $cache->clear($who);
    }
    else {
        $cache->clear();
    }
}

# Blow it to hell.
sub DESTROY {

    my $self = shift;
    $cache->purge();

}

1; # Goodnight, folks.

__END__

=head1 NAME

Auth.pm - A module to handle sessions for IRC::Bot.

=head1 SYNOPSIS

  use IRC::Bot::Auth
  my $seen = IRC::Bot::Auth->new();

  # later on...

  # Check to see if $nick has existing session
  sub on_public {
    my ( $kernel, $who, $where, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];

    # Do Stuff...

    my $check = $auth->is_auth( $nick );
    if ( $check != 1 ) {
        # Do stuff...
    }
    else {
        # Denied
    }

  }

=head1 DESCRIPTION

Provides session handling for IRC::Bot.

=head1 METHODS

=over 4

=item is_auth()

B<is_auth()> takes one argument, users nick, and checks to see if 
they are authed.  Returns 0 if authed, 1 if otherwise.

Use like so:

 my $check = $auth->is_auth( $nick );

=item get_ses()

B<get_ses()> takes a nickname as an argument.  Checks to see if user 
is authed and returns data from session.

Use like so:

 my $nick_ses = $auth->get_ses( $nick );

=item auth_set()

B<auth_set()> Sets users session.  Takes a nick for an argument, sets 
session time at one hour.

Use like so:

 $auth->auth_set( $nick );
 
=item de_auth()

B<de_auth()> clears the session, takes a nick for an argument.

Use like so:

 $auth->de_auth( $nick );
 
=back

=head1 CREDITS

See IRC::Bot

=head1 AUTHOR

Benjamin Smith defitro@just-another.net

=head1 SEE ALSO

IRC::Bot POE::Component::IRC Cache::FileCache

=cut
