package Games::Wumpus::Room;

use 5.010;

use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2009112401';

#
# Room in the cave of a Wumpus game.
#

use Hash::Util::FieldHash qw [fieldhash];
use Games::Wumpus::Constants;

fieldhash my %name;    # 'Name' of the room; typically a positive integer.
fieldhash my %hazard;  # 'Hazards' the room may contain.
fieldhash my %exit;    # 'Tunnels' to other rooms. List of objects.

sub new  {bless \do {my $var} => shift}

sub init {
    my $self = shift;

    $hazard {$self} = 0;
    $exit   {$self} = [];

    $self;
}

#
# Accessors
#
sub   set_name         {$name   {$_ [0]}  =  $_ [1]; $_ [0]}
sub       name         {$name   {$_ [0]}}

sub   set_hazard       {$hazard {$_ [0]} |=  $_ [1]; $_ [0]}
sub       hazards      {$hazard {$_ [0]}}
sub clear_hazard       {$hazard {$_ [0]} &= ~$_ [1]; $_ [0]}
sub clear_hazards      {$hazard {$_ [0]}  =  0;      $_ [0]}
sub   has_hazard       {$hazard {$_ [0]} &   $_ [1]}

sub   add_exit         {push @{$exit {$_ [0]}} => $_ [1]; $_ [0]}
sub       exits        {     @{$exit {$_ [0]}}}
sub       exit_by_name {
    my $self = shift;
    my $name = shift;
    my ($e)  = grep {$_ -> name eq $name} $self -> exits;
    return $e;
}

#
# Hazards nearby?
#

sub near_hazard {
    my $self   = shift;
    my $hazard = shift;
    foreach my $exit ($self -> exits) {
        return 1 if $exit -> has_hazard ($hazard);
    }
    return 0;
}

1;

__END__

=head1 NAME

Games::Wumpus::Room - Cave room used for Hunt the Wumpus

=head1 SYNOPSIS

 my $room = Games::Wumpus::Room -> new -> init;

 $room -> set_hazard ($WUMPUS);
 @exits = $room -> exits;

=head1 DESCRIPTION

C<< Games::Wumpus::Room >> is used to create objects representing
rooms in the Hunt the Wumpus cave system. It's used from
C<< Games::Wumpus::Cave >>.

The following methods are implemented:

=over 4

=item C<< new >>

Class method returning an unintialized object.

=item C<< init >>

Initializes the room. 

=item C<< name >>

Accessor returning the name of the room.

=item C<< set_name >>

Accessor setting the name of the room.

=item C<< set_hazard >>

Accessor setting one or more hazards in the room. Multiple hazards should
be C<< or >>red. Note that existing hazards aren't cleared.

=item C<< hazards >>

Accessor returning a bitfield with the hazards of the room.

=item C<< clear_hazards >>

Accessor removing all hazards from the room.

=item C<< clear_hazard >>

Accessor clearing the given hazard from the room.

=item C<< has_hazard >>

Accessor returning true if the room contains the given hazard.

=item C<< exits >>

Accessor returning all the exits (rooms with tunnels leading to them) of
the room.

=item C<< add_exit >>

Accessor adding the given exit to the room.

=item C<< exit_by_name >>

Accessor returning the exit which was passed by name. Returns undefined
if the exit doesn't exist.

=item C<< near_hazard >>

Returns true if one of the exits leads to the given hazard.


=back

=head1 BUGS

None known.

=head1 TODO

Configuration of the game should be possible.

=head1 SEE ALSO

L<< Games::Wumpus:: >>, L<< Games::Wumpus::Cave >>,
L<< Games::Wumpus::Constants >>

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Games--Wumpus.git >>.

=head1 AUTHOR

Abigail, L<< mailto:wumpus@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2009 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
