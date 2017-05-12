package Games::League::Member;

# Last Edit: 2006  2月 11, 07時56分01秒
# $Id: /sched/trunk/lib/Games/League/Member.pm 515 2006-02-10T23:06:55.230562Z dv  $

use warnings;
use strict;

use overload qw/0+/ => 'index', qw/""/ => 'name', fallback => 1;

=head1 NAME

Games::League::Member - Objects which Games::Tournament::RoundRobin can pair

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $foo = Games::League::Member->new( index => '15', name => 'Your New Knicks' );
    ...

=head1 DESCRIPTION

Games::Tournament::RoundRobin supports objects which have an index and a name method accessor, like this members of this class, Games::League::Member.

Games::Tournament::RoundRobin will use this class when constructing a Bye member if the application does not supply one.

=head1 REQUIREMENTS

Module::Build to install.

=head1 METHODS

=head2 new

	Games::League::Member->new( index => '15', name => 'Your New Knicks' )

=cut

sub new
{
	my $class = shift;
	my %args = @_;
	my $index = $args{index};
	my $name = $args{name};
	return bless \%args, $class;
}

=head2 name

	$member->name

Returns the name of the league member, a string that may or may not be unique to the member.

=cut

sub name
{
	my $self = shift;
	return $self->{name};
}

=head2 index

	$member->index

Returns the index of the league member, a number unique to the member in the range 0 .. n-1.

=cut

sub index
{
	my $self = shift;
	return $self->{index};
}

=head1 AUTHOR

Dr Bean, C<< <lang at ms.chinmin.edu.tw> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-league-member at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-RoundRobin-Schedule>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::League::Member

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-RoundRobin-Schedule>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-RoundRobin-Schedule>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-RoundRobin-Schedule>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-RoundRobin-Schedule>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the perl community for (0;$every;1) {
	$stacks .= $i;
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::League::Member
