package Logfile::EPrints::Filter::Session;

use strict;

use vars qw( %SESSIONS $AUTOLOAD $TIDY_ON $TIDY_COUNT );

$TIDY_ON = 10000;
$TIDY_COUNT = 0;

sub new
{
	my ($class,%self) = @_;
	$self{session} ||= 'Logfile::EPrints::Session';
	$TIDY_COUNT = 0;
	bless \%self, ref($class) || $class;
}

sub AUTOLOAD
{
	return if $AUTOLOAD =~ /[A-Z]$/;
	$AUTOLOAD =~ s/^.*:://;
	my( $self, $hit ) = @_;
	my $address = $hit->address;
	if( exists $SESSIONS{$address} and
		$SESSIONS{$address}->expired_by( $hit ) )
	{
		delete($SESSIONS{$address})->end_session;
	}
	my $session = $SESSIONS{$address} ||=
		$self->{session}->new(
			filter => $self,
			address => $address,
		);
	$session->$AUTOLOAD( $hit );
	
	$self->_tidyup( $hit ) if ++$TIDY_COUNT > $TIDY_ON;
	
	$hit->{session} = $session;
	return $self->{handler}->$AUTOLOAD($hit);
}

sub _tidyup
{
	my( $self, $hit ) = @_;
	$TIDY_COUNT = 0;
	for(keys %SESSIONS)
	{
		if( $SESSIONS{$_}->expired_by( $hit ) )
		{
			delete($SESSIONS{$_})->end_session;
		};
	}
}

package Logfile::EPrints::Session;

=head1 NAME

Logfile::EPrints::Session - Simple session class

=head1 METHODS

=over 4

=cut

use strict;
use warnings;

use vars qw( $AUTOLOAD $MAX_SESSION_GAP );

$MAX_SESSION_GAP = 60*10; # 10 minutes

sub new
{
	my( $class, %self ) = @_;
	bless \%self, $class;
}

=item $session->expired_by( $hit )

Returns true if this session would be expired before $hit occurred. NOTE for the purposes of tidyup $hit may not be from the same address as the session.

=cut

sub expired_by { ($_[1]->utime - $_[0]->{last_seen}) > $MAX_SESSION_GAP }

=item $session->start_session( $hit )

A new session has started with $hit.

=cut

sub start_session {}

=item $session->end_session

The session has expired/finished.

=cut

sub end_session { delete $_[0]->{last_abstract} }

=item $session->total( [ $type ] )

Return the total number of requests in this session or, if $type is given, total unique requests (by identifier) for $type.

=cut

sub total
{
	my( $self, $type ) = @_;

	return @_ == 2 ?
		scalar keys %{$self->{requests}->{$type}} :
		$self->{requests}->{total};
}

sub AUTOLOAD
{
	return if $AUTOLOAD =~ /[A-Z]$/;
	$AUTOLOAD =~ s/^.*:://;
	my( $self, $hit ) = @_;

	if( !defined $self->{last_seen} )
	{
		$self->{first_seen} = $hit->utime;
		$self->start_session( $hit );
	}

	if( $AUTOLOAD eq 'abstract' )
	{
		$self->{last_abstract} = $hit; # creates a loop in this hit
	}
	elsif( $AUTOLOAD eq 'fulltext' and exists $self->{last_abstract} )
	{
		if( $self->{last_abstract}->identifier eq $hit->identifier )
		{
			$hit->{abstract_referrer} = $self->{last_abstract};
		}
		else
		{
			delete $self->{last_abstract};
		}
	}
	
	$self->{last_seen} = $hit->utime;
	
	if( $AUTOLOAD eq 'abstract' or $AUTOLOAD eq 'fulltext' )
	{
		$self->{requests}->{total}++;
		$self->{requests}->{$AUTOLOAD}->{$hit->identifier}++;
	}
}

package Logfile::EPrints::Filter::MaxPerSession;

use strict;
use warnings;

our @ISA = qw( Logfile::EPrints::Filter );

use vars qw( $AUTOLOAD );

sub AUTOLOAD
{
	return if $AUTOLOAD =~ /[A-Z]$/;
	$AUTOLOAD =~ s/^.*:://;
	my( $self, $hit ) = @_;
	if( defined($self->{$AUTOLOAD}) and
		$hit->{session}->total($AUTOLOAD) > $self->{$AUTOLOAD} )
	{
		return undef if $hit->{session}->{__PACKAGE__ . '_removed'};
		$hit->{session}->{__PACKAGE__ . '_removed'} = 1;
		return Logfile::EPrints::Hit::Negate->new(
			address => $hit->address,
			start_utime => $hit->{session}->{first_seen},
			end_utime => $hit->{session}->{last_seen},
		);
	}
	else
	{
		return $self->{handler}->$AUTOLOAD( $hit );
	}
}

1;

__END__

=back
