package Game::Fanorona::Variant;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

use Game::Fanorona::Engine ();
use Game::Fanorona::Rules ();

our $VERSION = '0.03';

our @NAMES;
our @FIELDS;
BEGIN {
    @NAMES  = qw(sivy dimy telo);
    @FIELDS = qw(cols rows quiet_limit repeat ply_cap start);
}

has name => (is => 'ro');

has [@FIELDS] => (is => 'ro');

my $MAKING = 0;

my %DEFAULT;

my $defaults = sub {
    return \%DEFAULT if %DEFAULT;
    my $game = Game::Fanorona::Rules->new(board => 'telo');
    %DEFAULT = (
        quiet_limit => $game->quiet_limit,
        repeat      => $game->repeat,
        ply_cap     => $game->ply_cap,
    );
    return \%DEFAULT;
};

sub BUILD {
    my ($self) = @_;
    Carp::croak('Game::Fanorona::Variant: a variant is made by named, custom or from_string')
        unless $MAKING;
    return;
}

my $whole = sub { defined $_[0] && !ref $_[0] && $_[0] =~ /\A(?:0|[1-9][0-9]{0,5})\z/ };

my $make = sub {
    my ($class, %all) = @_;
    my ($cols, $rows) = @all{qw(cols rows)};
    Carp::croak('Game::Fanorona::Variant: a board is cols and rows')
        unless defined $cols && defined $rows;
    Carp::croak("Game::Fanorona::Variant: no board is $cols by $rows")
        unless $whole->($cols) && $whole->($rows) && Game::Fanorona::Engine->size_ok($cols, $rows);

    my $default = $defaults->();
    for my $limit (qw(quiet_limit repeat ply_cap)) {
        $all{$limit} = $default->{$limit} unless defined $all{$limit};
        Carp::croak("Game::Fanorona::Variant: $limit is a whole number, not '$all{$limit}'")
            unless $whole->($all{$limit});
    }
    Carp::croak('Game::Fanorona::Variant: repeat is 0, for never, or 2 and up')
        if $all{repeat} == 1;
    Carp::croak('Game::Fanorona::Variant: ply_cap is 1 or more')
        if $all{ply_cap} < 1;

    my $setup = Game::Fanorona::Engine->new(cols => $cols, rows => $rows)->to_string;
    if (defined $all{start}) {
        my ($board, $err) = Game::Fanorona::Engine->of_string($all{start});
        Carp::croak("Game::Fanorona::Variant: '$all{start}' is not a position") unless $board;
        Carp::croak("Game::Fanorona::Variant: the start is not a position of a board $cols by $rows")
            unless $board->cols == $cols && $board->rows == $rows;
        $all{start} = $board->to_string;
    }
    else {
        $all{start} = $setup;
    }

    my ($name) = grep { my @size = Game::Fanorona::Engine->size_of($_); $size[0] == $cols && $size[1] == $rows } @NAMES;
    $name = "${cols}x${rows}" unless defined $name;

    $MAKING = 1;
    my $made = eval { $class->new(name => $name, map { $_ => $all{$_} } @FIELDS) };
    my $died = $@;
    $MAKING = 0;
    Carp::croak($died) unless $made;
    return $made;
};

sub named {
    my ($class, $name) = @_;
    $name = 'sivy' unless defined $name;
    my ($cols, $rows) = Game::Fanorona::Engine->size_of($name);
    Carp::croak("Game::Fanorona::Variant: no board is called '$name'") unless $cols;
    return $make->($class, cols => $cols, rows => $rows);
}

sub custom {
    my ($class, @fields) = @_;
    Carp::croak('Game::Fanorona::Variant: custom takes field => value pairs') if @fields % 2;
    my %given = @fields;
    my %known = map { $_ => 1 } @FIELDS, 'board';
    for my $field (sort keys %given) {
        Carp::croak("Game::Fanorona::Variant: no field is called '$field'") unless $known{$field};
        Carp::croak("Game::Fanorona::Variant: $field has no value") unless defined $given{$field};
    }
    if (defined(my $board = delete $given{board})) {
        Carp::croak('Game::Fanorona::Variant: give a board by name or by cols and rows, not both')
            if defined $given{cols} || defined $given{rows};
        my ($cols, $rows) = Game::Fanorona::Engine->size_of($board);
        Carp::croak("Game::Fanorona::Variant: no board is called '$board'") unless $cols;
        @given{qw(cols rows)} = ($cols, $rows);
    }
    return $make->($class, %given);
}

sub from_string {
    my ($class, $string) = @_;
    return undef unless defined $string && !ref $string && length $string;
    my ($board, @pairs) = split /,/, $string, -1;
    my %given;
    if ($board =~ /\A([0-9])x([0-9])\z/) { @given{qw(cols rows)} = ($1, $2) }
    else                                 { $given{board} = $board }
    for my $pair (@pairs) {
        return undef unless $pair =~ /\A(quiet_limit|repeat|ply_cap|start)=(.+)\z/;
        return undef if exists $given{$1};
        $given{$1} = $2;
    }
    my $made = eval { $class->custom(%given) };
    return $made;
}

sub as_string {
    my ($self) = @_;
    my $default = $defaults->();
    my $text = $self->name;
    for my $limit (qw(quiet_limit repeat ply_cap)) {
        $text .= ",$limit=" . $self->$limit unless $self->$limit == $default->{$limit};
    }
    $text .= ',start=' . $self->start unless $self->is_setup;
    return $text;
}

sub is_setup {
    my ($self) = @_;
    return $self->start eq Game::Fanorona::Engine->new(cols => $self->cols, rows => $self->rows)->to_string ? 1 : 0;
}

sub limits {
    my ($self) = @_;
    return { map { $_ => $self->$_ } qw(quiet_limit repeat ply_cap) };
}

sub names { @NAMES }

1;

__END__

=head1 NAME

Game::Fanorona::Variant - the board a game is played on, where it starts, and its limits

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Game::Fanorona::Variant;

    my $game  = Game::Fanorona::Variant->named('sivy');
    my $small = Game::Fanorona::Variant->named('telo');
    my $short = Game::Fanorona::Variant->custom(board => 'sivy', quiet_limit => 40);
    my $odd   = Game::Fanorona::Variant->custom(cols => 7, rows => 5);

    print $short->as_string, "\n";                      # sivy,quiet_limit=40
    my $again = Game::Fanorona::Variant->from_string($short->as_string);

=head1 DESCRIPTION

A value: which board, the position the game begins from, and the three limits
that draw a game. It is made once and does not change.

B<Not by C<new>>, which croaks. The three constructors check every field, and
a field that is not one is refused where C<new> would have accepted it in
silence.

=head2 The boards

Fanorona has three traditional sizes, and this distribution names them as the
game does: C<sivy>, nine files by five ranks and the game most people mean;
C<dimy>, five by five; and C<telo>, three by three. Any board of odd width 3
to 9 and height 3 or 5 can be had by its size.

B<The set-up of the nine by five is the traditional one. The set-ups of the
others are derived from it>, by carrying its pattern down: the home ranks
full, the centre empty, the middle rank alternating outward from the centre
with a white stone directly left of it and a black one directly right. No
source this distribution read gives them.

For C<telo> that derivation leaves nothing to choose, because the only other
balanced middle rank is its mirror image and the mirror image is the same
game. And it is checked: worked through with this engine, the three by three
is a win for White, which is what the published solution of the game says.

For C<dimy> the pattern gives C<b w . b w>, and a rank that reads the same
from both ends, C<b w . w b>, is a real alternative that nothing here settles.
A game can be started from it with C<start>.

=head2 The limits

C<quiet_limit>, the number of moves running, both sides counted, that may
take nothing before the game is drawn; C<repeat>, which occurrence of a
position draws it; and C<ply_cap>, the number of moves at which a game is
drawn whatever else. They are what L<Game::Fanorona::Rules> describes, and
its defaults are this class's. A C<quiet_limit> or a C<repeat> of 0 turns
that draw off.

=head1 CONSTRUCTORS

=head2 named

    my $variant = Game::Fanorona::Variant->named('dimy');

One of the three boards from its set-up with the default limits. C<sivy> when
no name is given. Croaks on a name that is not a board.

=head2 custom

    my $variant = Game::Fanorona::Variant->custom(
        board       => 'dimy',              # or cols => 5, rows => 5
        start       => 'bbbbb/bbbbb/bw1wb/wwwww/wwwww w',
        quiet_limit => 40,
        repeat      => 3,
        ply_cap     => 500,
    );

A board by name or by size, and whatever else differs. Croaks on a field that
is not one, a field with no value, a size that cannot be built, a limit that
is not a whole number, a C<repeat> of 1, a C<ply_cap> below 1, or a C<start>
that is not a position of a board that size.

=head2 from_string

    my $variant = Game::Fanorona::Variant->from_string('sivy,quiet_limit=40');

The variant C<as_string> wrote, or C<undef> for a string that is not one.

=head1 METHODS

=head2 name

C<sivy>, C<dimy> or C<telo> for a board of one of those sizes, whatever its
start and limits; otherwise the size, as C<7x5>.

=head2 cols

=head2 rows

The size of the board.

=head2 start

The position the game begins from, as L<Game::Fanorona::Engine> writes it.

=head2 is_setup

True when C<start> is the set-up of the board.

=head2 quiet_limit

=head2 repeat

=head2 ply_cap

The three limits.

=head2 limits

The three limits as a hash reference, which is what
L<Game::Fanorona::Rules/new> takes as its C<variant>.

=head2 as_string

The variant as one line: its name, then each limit that is not the default,
then the start if it is not the set-up. A named board with nothing changed is
just its name.

=head1 CLASS METHODS

=head2 names

The three names: C<sivy>, C<dimy>, C<telo>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
