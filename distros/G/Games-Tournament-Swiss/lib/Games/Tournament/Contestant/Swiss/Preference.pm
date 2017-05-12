package Games::Tournament::Contestant::Swiss::Preference;
$Games::Tournament::Contestant::Swiss::Preference::VERSION = '0.21';
# Last Edit: 2016 Jan 01, 13:45:02
# $Id: $

use warnings;
use strict;
use Carp;

use List::Util qw/first/;
use List::MoreUtils qw/any/;

use Games::Tournament::Swiss::Config;

use constant ROLES => @Games::Tournament::Swiss::Config::roles?
			@Games::Tournament::Swiss::Config::roles:
			Games::Tournament::Swiss::Config->roles;

use base qw/Games::Tournament/;

# use overload qw/0+/ => 'next', qw/""/ => 'value', fallback => 1;

=head1 NAME

Games::Tournament::Contestant::Swiss::Preference  A competitor's right to a role.

=cut

=head1 SYNOPSIS

    pray if $preference->role eq 'Black' and $preference->strength eq 'Strong';

=head1 DESCRIPTION

The preference, or expectation/right/duty one has with reference to a role, eg White, in the next round depends on the difference between the number of games previously played in it and in the alternative roles, and is either Mild, Strong, or Absolute. The more games played in other roles than in this role, the greater the right/duty to play the next game in this role. The FIDE Swiss Rules (C04.1) represent the difference as the number of Games as White minus the number as Black, so a greater number of games as Black is a negative number and of White a positive number. For equal number of games, +0 indicates the last game was as White, and -0 indicates the last game was as Black. So +0 represents a Mild preference for Black and -0 for White. This implementation uses a 'sign' field to perform the same function as the +/- sign.
As an API, the strength method returns 'Mild', 'Strong', or 'Absolute' and the role method returns 'Black', 'White', or whatever the preferred role is, respecting the 2 consecutive games in the same role rule. A7

=head1 METHODS

=head2 new

    $pref = Games::Tournament::Contestant::Swiss::Preference->new(
	difference => 0, sign => 'Black', round => 0 );

The default difference is 0. The default sign is ''.

=cut

sub new {
    my $self = shift;
    my %args = @_;
    $args{sign}  = '' unless $args{sign};
    $args{difference} = 0  unless $args{difference};
    my $pref = bless \%args, $self;
    return $pref;
}


=head2 update

	$pref->update( \@oldRoles  )

	Updates the difference (ie, the internal representation of preference) on the basis of the last role (and second-last role) in \@oldRoles. A minimal sanity check is performed. \@oldRoles is a history of roles in previous rounds, and it is expected only the last role of this history has not yet been used to update the preference. That is, this method must be used round-by-round to keep a players preference up to date. However, the second-last role (in addition to the last role) is also needed to determine the preference in cases when the same role was taken in the last 2 games. So for updates after the second round, make sure the history is at least 2 elements long. Byes and unplayed games have no effect on the preference, so make sure that roles in unplayed games don't make it into oldRoles A5, F2 .

=cut

sub update {
    my $self     = shift;
    my $roles = shift;
    my $message = "Preference update: ";
    return unless $roles->[-1] and any { $roles->[-1] eq $_ } ROLES;
    my @reverseRoles = reverse @$roles;
    my $lastRole       = $reverseRoles[0];
    my $before         = $reverseRoles[1];
    my $oneBeforeThat = $reverseRoles[2];
    $message .= "3-game run as $lastRole\n" if $before and $oneBeforeThat and
		    $oneBeforeThat eq $before and $before eq $lastRole;
    my $difference     = $self->difference;
    my $sign      = $self->sign;
    my $otherDirection = first { $_ ne $sign } ROLES;
    if ( not $sign or not defined $difference ) {
        $sign  = $lastRole;
        $difference = 1;
    }
    elsif ( $lastRole eq $otherDirection ) {
        if ( $difference > 0 ) {
            $difference--;
	    if ( $difference == 0 ) {
		$sign  = $otherDirection;
	    }
        }
        elsif ( $difference == 0 ) {
            $sign  = $lastRole;
            $difference = 1;
        }
        else {
            die "$difference games more as $sign after $lastRole role?";
        }
    }
    elsif ( $lastRole eq $sign ) {
	$difference++;
        if ( $difference > 2 ) {
            $message .= "$difference games more as $lastRole\n";
        }
    }
    else {
        die
	"$lastRole role update on ${difference}-game difference in $sign role?";
    }
    $self->sign($sign);
    $self->difference($difference);
    if ($before) { $self->lastTwo( [ $before, $lastRole ] ); }
    else { $self->lastTwo( [$lastRole] ); }
}


=head2 asString

	$pref->asString

	The difference as a string, ^[+-][012]$. '0' represents a mild preference, '1' a strong one and '2' an absolute one. '-' represents a preference for White, or the first element of @Games::Tournament::Swiss::Config::roles, and '+' represents a preference for Black or the second element. A player may have an absolute preference even if the difference is 0, because it played the previous 2 rounds in the other color.

=cut


sub asString {
    my $self   = shift;
    my $string = $self->sign eq (ROLES)[0] ? '+' :
		$self->sign eq (ROLES)[1] ? '-' : '';
    $string .= $self->difference;
}


=head2 difference

	$pref->difference(2)

	Sets/gets the value of the difference in games played in one role over those played in other alternative roles. Equals either 0,1,2.

=cut


sub difference {
    my $self       = shift;
    my $difference = shift();
    $self->{difference} = $difference if defined $difference;
    return $self->{difference};
}


=head2 sign

	$pref->sign('Black')
	$pref->sign('-')

Sets/gets the role which the player has taken more often, or more recently, than other alternative roles. The preference is thus for the other role.

=cut

sub sign {
    my $self = shift;
    my $sign = shift() || $self->{sign};
    my %abbrev = ( White => '+', Black => '-' );
    my %expando = reverse %abbrev;
    $sign = $expando{$sign} if $expando{$sign};
    $self->{sign} = $sign;
    return $sign;
}


=head2 strength

	$pref->strength

Gets the strength of the preference, 'Mild,' 'Strong,' or 'Absolute.'

=cut

sub strength {
    my $self      = shift;
    my @degree     = qw/Mild Strong Absolute/;
    my $diff      = $self->difference;
    my $strength  = $degree[$diff];
    $strength = 'Absolute' if $diff > 2 ;
    my @lastRoles = @{ $self->lastTwo };
    if ( @lastRoles == 2 ) {
        $strength = 'Absolute' if $lastRoles[0] eq $lastRoles[1];
    }
    return $strength;
}


=head2 role

	$pref->role

Gets the role which the preference entitles/requires the player to take in the next round. Not defined if sign is ''.

=cut

sub role {
    my $self = shift;
    my $role;
    $role = first { $_ ne $self->sign } ROLES if $self->sign;
    my @lastRoles = @{ $self->lastTwo };
    if ( @lastRoles == 2 and $lastRoles[0] eq $lastRoles[1] )
    {
	$role = first { $_ ne $lastRoles[0] } ROLES;
    }
    return $role;
}


=head2 round

	$pref->round

Sets/gets the round in this game up to which play is used to calculate the preference . The default is 0.

=cut

sub round {
    my $self = shift;
    my $round = shift() || $self->{round};
    $self->{round} = $round;
    return $round;
}


=head2 lastTwo

	$pref->lastTwo

Sets/gets a list of the roles in the last 2 games. If the 2 roles are the same, there is an absolute preference for the other role.

=cut

sub lastTwo {
    my $self    = shift;
    my $lastTwo = shift;
    if ( defined $lastTwo ) { $self->{lastTwo} = $lastTwo; }
    elsif ( $self->{lastTwo} ) { return $self->{lastTwo}; }
    else { return []; }
}

=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-contestant at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament-Swiss>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament::Contestant::Swiss::Preference

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament-Swiss>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament-Swiss>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament-Swiss>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament-Swiss>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament::Contestant::Preference

# vim: set ts=8 sts=4 sw=4 noet:
