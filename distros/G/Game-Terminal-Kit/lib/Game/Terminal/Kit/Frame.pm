package Game::Terminal::Kit::Frame;

use 5.014;
use strict;
use warnings;
use utf8;

our $VERSION = '0.05';

my @PARTS = qw/tl t tr l r bl b br/;

my %LINE = (
	light  => [ split //, '┌─┐││└─┘' ],
	double => [ split //, '╔═╗║║╚═╝' ],
	heavy  => [ split //, '┏━┓┃┃┗━┛' ],
);

my %PLAIN = (
	light  => [ split //, '+-+||+-+' ],
	double => [ split //, '#=#||#=#' ],
	heavy  => [ split //, '+=+||+=+' ],
);

my @MARKS = qw/cursor from target recent plain/;

my %WEIGHT = (
	plain  => 'light',
	recent => 'double',
	cursor => 'heavy',
	from   => 'light',
	target => 'light',
);

my %BRACKET = (
	plain  => [ ' ', ' ' ],
	recent => [ '{', '}' ],
	cursor => [ '[', ']' ],
	from   => [ '(', ')' ],
	target => [ '<', '>' ],
);

sub marks { return @MARKS }

sub parts { return @PARTS }

sub known {
	my ($mark) = @_;
	return defined $mark && $WEIGHT{$mark} ? $mark : 'plain';
}

sub box {
	my ($mark, $ascii) = @_;
	my $weight = $WEIGHT{ known($mark) };
	my $glyphs = ($ascii ? \%PLAIN : \%LINE)->{$weight};
	my %box;
	@box{@PARTS} = @{$glyphs};
	return \%box;
}

sub brackets {
	my ($mark) = @_;
	return @{ $BRACKET{ known($mark) } };
}

sub strongest {
	my (@given) = @_;
	my %given = map { known($_) => 1 } @given;
	for my $mark (@MARKS) {
		return $mark if $given{$mark};
	}
	return 'plain';
}

sub around {
	my ($mark, $ascii, @lines) = @_;
	my $box = box($mark, $ascii);
	my ($width) = sort { $b <=> $a } map { length } @lines, '';
	return (
		$box->{tl} . ($box->{t} x $width) . $box->{tr},
		(map { $box->{l} . $_ . (' ' x ($width - length)) . $box->{r} } @lines),
		$box->{bl} . ($box->{b} x $width) . $box->{br},
	);
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Terminal::Kit::Frame - marks that are shapes, not colours

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Frame;

    my @tile = Game::Terminal::Kit::Frame::around('cursor', $ascii, ' 6 ', ' 4 ');
    #  ┏━━━┓        +===+
    #  ┃ 6 ┃   or   | 6 |
    #  ┃ 4 ┃        | 4 |
    #  ┗━━━┛        +===+

    my ($open, $close) = Game::Terminal::Kit::Frame::brackets('recent');
    my $compact = $open . '6|4' . $close;      # {6|4}

=head1 DESCRIPTION

A game that is played with a cursor shows two kinds of marked piece at once:
the one the cursor is on, which is what would change, and the ones played
since the player last looked, which is what did change. They answer different
questions and are never on screen apart, so they need two looks. Colour
cannot be the difference, because a mark has to survive C<NO_COLOR>, a
terminal without colour and output sent to a file.

So each mark is a shape. A boxed piece gets a box of a different weight; a
piece on one line gets different brackets. Every glyph is one column wide, in
Unicode and in ASCII, so a marked piece is exactly the size of a plain one
and nothing shifts when the cursor moves. Colour then goes on top, from the
game, as a second way of saying the same thing.

=head2 The marks

    mark      box                ASCII box       brackets
    plain     light   ┌─┐│└┘     +-+|            none
    recent    double  ╔═╗║╚╝     #=#|            { }
    cursor    heavy   ┏━┓┃┗┛     +=+|            [ ]
    from      light                              ( )
    target    light                              < >

C<plain> is a piece with nothing to say. C<recent> is one that changed since
the player last looked. C<cursor> is the one a key would act on. C<from> and
C<target> are for a move in two steps: the piece taken up, and where it may
go. A name that is none of these is C<plain>.

=head1 FUNCTIONS

None is exported.

=head2 box

    my $box = Game::Terminal::Kit::Frame::box($mark, $ascii);

The eight glyphs of the mark's box, as a hash reference with the keys C<tl>,
C<t>, C<tr>, C<l>, C<r>, C<bl>, C<b> and C<br>. In ASCII when the second
argument is true.

=head2 around

    my @lines = Game::Terminal::Kit::Frame::around($mark, $ascii, @lines);

The lines inside the mark's box: two lines more and two columns wider, with
short lines padded to the longest.

=head2 brackets

    my ($open, $close) = Game::Terminal::Kit::Frame::brackets($mark);

The two characters to put either side of a piece drawn on one line. Two
spaces for C<plain>, so a row of pieces stays in step.

=head2 strongest

    my $mark = Game::Terminal::Kit::Frame::strongest(@marks);

The one to draw when a piece has several: C<cursor>, then C<from>,
C<target>, C<recent>, and C<plain> when there are none.

=head2 marks

=head2 parts

=head2 known

The names of the marks, strongest first; the eight keys of a box, in the
order a box is read; and a mark's own name, or C<plain> for anything else.

=head1 SEE ALSO

L<Game::Terminal::Kit>, L<Game::Terminal::Kit::Canvas>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
