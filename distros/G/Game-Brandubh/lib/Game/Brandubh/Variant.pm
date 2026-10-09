package Game::Brandubh::Variant;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

our (@FIELDS, %DEFAULT, %NAMED);
BEGIN {
    @FIELDS = qw(
        escape
        king_everywhere_two
        king_strong
        throne_reentry
        throne_pass
        repeat
        ply_cap
    );
    %DEFAULT = (
        escape              => 'corner',
        king_everywhere_two => 0,
        king_strong         => 0,
        throne_reentry      => 0,
        throne_pass         => 1,
        repeat              => 3,
        ply_cap             => 400,
    );
    %NAMED = (
        brandubh => {},
    );
}

use constant PLY_CAP_MAX => 4096;

has name => (is => 'ro', default => 'brandubh');

has escape => (is => 'ro', default => 'corner');

has king_everywhere_two => (is => 'ro', default => 0);

has king_strong => (is => 'ro', default => 0);

has throne_reentry => (is => 'ro', default => 0);

has throne_pass => (is => 'ro', default => 1);

has repeat => (is => 'ro', default => 3);

has ply_cap => (is => 'ro', default => 400);

my $MAKING = 0;

sub BUILD {
    my ($self) = @_;
    Carp::croak('Game::Brandubh::Variant: a rule set is made by named, custom or from_string')
        unless $MAKING;
    return;
}

my $checked = sub {
    my ($class, %fields) = @_;

    for my $field (sort keys %fields) {
        Carp::croak("Game::Brandubh::Variant: no field is called '$field'")
            unless exists $DEFAULT{$field};
        Carp::croak("Game::Brandubh::Variant: $field has no value")
            unless defined $fields{$field} && !ref $fields{$field};
    }
    my %all = (%DEFAULT, %fields);

    Carp::croak("Game::Brandubh::Variant: escape is 'corner' or 'edge', not '$all{escape}'")
        unless $all{escape} eq 'corner' || $all{escape} eq 'edge';
    for my $flag (qw(king_everywhere_two king_strong throne_reentry throne_pass)) {
        Carp::croak("Game::Brandubh::Variant: $flag is 0 or 1, not '$all{$flag}'")
            unless $all{$flag} =~ /\A[01]\z/;
        $all{$flag} += 0;
    }
    Carp::croak("Game::Brandubh::Variant: repeat is a whole number from 2 up, not '$all{repeat}'")
        unless $all{repeat} =~ /\A[0-9]{1,6}\z/ && $all{repeat} >= 2;
    Carp::croak("Game::Brandubh::Variant: ply_cap is a whole number from 1 to " . PLY_CAP_MAX . ", not '$all{ply_cap}'")
        unless $all{ply_cap} =~ /\A[0-9]{1,5}\z/ && $all{ply_cap} >= 1 && $all{ply_cap} <= PLY_CAP_MAX;
    $all{$_} += 0 for qw(repeat ply_cap);

    Carp::croak('Game::Brandubh::Variant: king_everywhere_two and king_strong contradict each other')
        if $all{king_everywhere_two} && $all{king_strong};

    my $name = 'custom';
    for my $known (sort keys %NAMED) {
        my %set = (%DEFAULT, %{ $NAMED{$known} });
        next if grep { $set{$_} ne $all{$_} } @FIELDS;
        $name = $known;
        last;
    }

    $MAKING = 1;
    my $made = eval { $class->new(name => $name, %all) };
    my $died = $@;
    $MAKING = 0;
    Carp::croak($died) unless $made;
    return $made;
};

sub named {
    my ($class, $name) = @_;
    $name = 'brandubh' unless defined $name;
    Carp::croak("Game::Brandubh::Variant: no rule set is called '$name'")
        unless !ref $name && exists $NAMED{$name};
    return $checked->($class, %{ $NAMED{$name} });
}

sub custom {
    my ($class, @fields) = @_;
    Carp::croak('Game::Brandubh::Variant: custom takes field => value pairs') if @fields % 2;
    return $checked->($class, @fields);
}

sub from_string {
    my ($class, $text) = @_;
    return undef unless defined $text && !ref $text;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return eval { $class->named($text) } if exists $NAMED{$text};

    my ($list) = $text =~ /\Acustom(?:[ \t]+(\S+))?\z/ or return undef;
    my %fields;
    for my $pair (split /,/, defined $list ? $list : '') {
        my ($field, $value) = $pair =~ /\A(\w+)=(\w+)\z/ or return undef;
        return undef if exists $fields{$field};
        $fields{$field} = $value;
    }
    return eval { $checked->($class, %fields) };
}

sub as_string {
    my ($self) = @_;
    return $self->name if exists $NAMED{ $self->name };
    my @differ = grep { $self->$_ ne $DEFAULT{$_} } @FIELDS;
    return 'custom ' . join(',', map { "$_=" . $self->$_ } @differ);
}

sub as_hash {
    my ($self) = @_;
    return { map { $_ => $self->$_ } @FIELDS };
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref $other && ref $other eq ref $self;
    return (grep { $self->$_ ne $other->$_ } @FIELDS) ? 0 : 1;
}

sub fields { @FIELDS }

sub names { sort keys %NAMED }

1;

__END__

=head1 NAME

Game::Brandubh::Variant - the rule set a game of brandubh is played under

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Brandubh::Variant;

    my $rules = Game::Brandubh::Variant->named('brandubh');
    my $house = Game::Brandubh::Variant->custom(repeat => 2, throne_reentry => 1);

    print $house->as_string, "\n";          # custom throne_reentry=1,repeat=2
    my $same = Game::Brandubh::Variant->from_string($house->as_string);
    print "equal\n" if $same->equals($house);

    my $game = Game::Brandubh->new(variant => $house);

=head1 DESCRIPTION

A value: seven fields that between them say which game of brandubh is being
played. It cannot be changed once made. Two with the same fields are equal.

The rules of brandubh were never written down, and every set in use is a
reconstruction. This distribution follows one of them by default, described in
L<Game::Brandubh>, and each field here is a point at which a table might
reasonably play it another way.

=head2 Made by C<named>, C<custom> or C<from_string>

B<Not by C<new>>, which croaks. The three constructors check every field's
name and value; a misspelt field would otherwise be dropped without a word and
the default game played in its place.

=head2 Only one set has a name

C<brandubh> is the default, and is the only set this version publishes under a
name. The fields that make the other sets are all here and all work, and a set
built from them is called C<custom>. A name is a promise that the set has been
checked against a written source for that set, and that has been done for one.

=head1 FIELDS

Each is also a method that returns its value.

=over 4

=item C<escape>

C<corner> by default: the king wins on a corner. C<edge>: on any square of the
edge.

=item C<king_everywhere_two>

0 by default. With 1 the king is captured by two attackers like any other
piece wherever he stands, the throne included.

=item C<king_strong>

0 by default. With 1 the king is captured only when every side of him is
closed, by an attacker or by the empty throne, wherever he stands. It
contradicts C<king_everywhere_two>, and a set with both croaks.

=item C<throne_reentry>

0 by default: once the king has left the throne he may not return.

=item C<throne_pass>

1 by default: a piece may slide across the empty throne, though none may stop
on it.

=item C<repeat>

3 by default: the game is drawn when a position occurs for the third time. A
whole number from 2 up.

=item C<ply_cap>

400 by default: the game is drawn after this many moves, counting both sides'.
A whole number from 1 to 4096.

=back

=head1 CONSTANTS

=head2 PLY_CAP_MAX

4096, the largest C<ply_cap>.

=head1 METHODS

=head2 named

    my $rules = Game::Brandubh::Variant->named('brandubh');
    my $rules = Game::Brandubh::Variant->named;

A published rule set. B<Croaks> on a name that is not one.

=head2 custom

    my $rules = Game::Brandubh::Variant->custom(%fields);

A rule set from fields, each left out being the default. B<Croaks> on a field
that does not exist, on a value the field cannot take, and on a set that
contradicts itself. When the fields happen to be exactly those of a published
set, the result carries that set's name.

=head2 from_string

    my $rules = Game::Brandubh::Variant->from_string('custom repeat=2');

A rule set from the string C<as_string> writes. C<undef> for anything else,
without dying: the string usually comes from a file somebody else wrote.

=head2 as_string

The name of a published set, or C<custom> followed by the fields that differ
from the default, C<field=value> with commas between.

=head2 as_hash

A hash reference of all seven fields, the form L<Game::Brandubh::Rules> and
L<Game::Brandubh::Engine> take.

=head2 equals

    if ($rules->equals($other)) { ... }

True when the other is a rule set with the same seven fields.

=head2 name

C<brandubh>, or C<custom>.

=head2 escape

=head2 king_everywhere_two

=head2 king_strong

=head2 throne_reentry

=head2 throne_pass

=head2 repeat

=head2 ply_cap

The value of the field. See L</FIELDS>.

=head2 fields

    my @names = Game::Brandubh::Variant->fields;

The names of the seven fields.

=head2 names

    my @names = Game::Brandubh::Variant->names;

The names of the published sets.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
