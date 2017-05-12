package Games::Tournament::Swiss::Config;
$Games::Tournament::Swiss::Config::VERSION = '0.21';
# Last Edit: 2016 Jan 01, 13:44:43
# $Id: $

use warnings;
use strict;

=head1 NAME

Games::Tournament::Swiss::Config - Swiss Competition Configuration

=cut

=head1 SYNOPSIS

    use constant ROLES => @Games::Tournament::Swiss::Config::roles = qw/Black White/;
    use constant ROLES => @Games::Tournament::Swiss::Config::ROLES;
    $Games::Tournament::Swiss::Config::firstRound = 11;

=head1 DESCRIPTION

Actually, a swiss tournament is not just one kind of tournament, but a whole genre of tournaments. If you are using Games::Tournament::Swiss for other than chess tournaments, where the players take black and white roles, and score 0,0.5, or 1, for example, you probably want to configure it. You also might want to start swiss pairing at a random round in the tournament, in which case you will set firstround.

The roles, scores, firstround, algorithm methods in this module are here just to stop perl warning about 'only one use, possible typo' warnings, with the use of fully qualified Games::Tournament::Swiss::Config package variables. (Is that actually true? Anyway I want the methods (class and object) to return values, default and assigned.)

=head1 METHODS

=head2 new

Getter/setter of the genre of competition, eg chess, basketball, football, school exam, etc, the tournament is being held as.

=cut

sub new {
    my $self = shift;
    my %args = @_;
    $args{roles} ||= [ Games::Tournament::Swiss::Config->roles ];
    return bless \%args, $self;
}


=head2 frisk

Die if the configuration contains anything but [A-Za-z0-9:,.]

=cut

sub frisk {
    my $self    = shift;
    my @suspects = @_;
    for my $suspect ( @suspects )
    {
	unless ( ref $suspect ) {
	    die "We are afraid you may be importing nasty characters with
$suspect. Please use only [A-Za-z0-9:.,] in your configuration files"
	      unless $suspect =~ m/^[A-Za-z0-9:.,]*$/;
	}
	elsif ( ref($suspect) eq "ARRAY" ) {
	    for (@$suspect) { $self->frisk($_); }
	}
	elsif ( ref($suspect) eq 'HASH' ) {
	    for ( keys %$suspect ) { $self->frisk( $suspect->{$_} ); }
	}
	else {
	    die "We are afraid you may be importing nasty objects with $suspect.
Please use only arrays and hashes in your configuration files";
	}
    }
    return;
}


=head2 roles

Getter/setter of the roles the 2 players take, eg Black, White, or Home, Away. The default is White, Black. Both object and class method.

=cut

sub roles {
    my $self  = shift;
    my $roles = shift;
    if (ref $self eq "Games::Tournament::Swiss::Config" and $roles) {
        $self->{roles} = $roles; return;
    }
    if ( ref $self eq "Games::Tournament::Swiss::Config" and $self->{roles} )
    { return @{ $self->{roles} }; }
    else { return qw/White Black/; }
}


=head2 scores

Getter/setter of the scores the 2 players can get, eg win: 1, loss: 0, draw: 0.5, absent: 0, bye: 1, which is the default. Both object and class method.

=cut

sub scores {
    my $self   = shift;
    my $scores = shift;
    if (ref $self eq "Games::Tournament::Swiss::Config" and $scores)
    { $self->{scores} = $scores; }
    elsif (ref $self eq "Games::Tournament::Swiss::Config" and $self->{scores})
    { return %{ $self->{scores} }; }
    else { return ( win => 1, loss => 0, draw => 0.5, absent => 0, bye => 1,
	unpaired => 0, tardy => 0.5, forfeit => 0 ) }
}


=head2 abbreviation

Getter/setter of the abbreviations used and their full translations. The default is W: White, B: Black, 1: Win, 0: Loss, '0.5': Draw, '=': Draw. Both object and class method. Also Absolute, Strong and Mild preferences, and Down, Up, and Not floats.

=cut

sub abbreviation {
    my $self   = shift;
    my $abbreviation = shift;
    if (ref $self eq "Games::Tournament::Swiss::Config" and $abbreviation)
    { $self->{abbreviation} = $abbreviation; return; }
    elsif (ref $self eq "Games::Tournament::Swiss::Config" and
		$self->{abbreviation} )
    { return %{ $self->{abbreviation} }; }
    else { return ( W => 'White', B => 'Black', 1 => 'Win', 0 => 'Loss',
    0.5 => 'Draw', '=' => 'Draw', A => 'Absolute', S => 'Strong', M => 'Mild', D => 'Down', U => 'Up', N => 'Not' ); }
}


=head2 algorithm

Getter/setter of the algorithm by which swiss pairing is carried out. There is no default. Pass a name as a string. I recommend Games::Tournament::Swiss::Procedure::FIDE. Make sure something is set.

=cut

sub algorithm {
    my $self      = shift;
    my $algorithm = shift;
    die "$algorithm name is like Games::Tournament::Swiss::Procedure::AlgoName"
      unless $algorithm =~ m/^Games::Tournament::Swiss::Procedure::\w+$/;
    if ($algorithm) { $self->{algorithm} = $algorithm; }
    elsif ( $self->{algorithm} ) { return @{ $self->{algorithm} }; }
    else { return 'Games::Tournament::Swiss::Procedure::FIDE' };
}


=head2 firstround

Getter/setter of the first round in which swiss pairing started. Perhaps some other pairing method was used in rounds earlier than this. The default is 1. Both object and class method.

=cut

sub firstround {
    my $self       = shift;
    my $first = shift;
    if (ref $self eq "Games::Tournament::Swiss::Config" and $first)
    { $self->{firstround} = $first; }
    elsif (ref $self eq "Games::Tournament::Swiss::Config" and $self->{first} )
    { return @{ $self->{firstround} }; }
    else { return 1; }
}

=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-swiss at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament-Swiss>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament::Swiss::Config

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

See L<http://www.fide.com/official/handbook.asp?level=C04> for the FIDE's Swiss rules.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament::Swiss::Config

# vim: set ts=8 sts=4 sw=4 noet:
