package Games::LMSolve::Numbers;
$Games::LMSolve::Numbers::VERSION = '0.14.1';
use strict;
use warnings;

use Games::LMSolve::Base;

use vars qw(@ISA);

@ISA = qw(Games::LMSolve::Base);

my %cell_dirs = (
    'N' => [ 0,  -1 ],
    'S' => [ 0,  1 ],
    'E' => [ 1,  0 ],
    'W' => [ -1, 0 ],
);

sub input_board
{
    my $self = shift;

    my $filename = shift;

    my $spec = {
        'dims'   => { 'type' => "xy(integer)", 'required' => 1 },
        'start'  => { 'type' => "xy(integer)", 'required' => 1 },
        'layout' => { 'type' => "layout",      'required' => 1 },
    };

    my $input_obj    = Games::LMSolve::Input->new();
    my $input_fields = $input_obj->input_board( $filename, $spec );
    my ( $width, $height ) =
        @{ $input_fields->{'dims'}->{'value'} }{ 'x', 'y' };
    my ( $start_x, $start_y ) =
        @{ $input_fields->{'start'}->{'value'} }{ 'x', 'y' };
    my (@board);

    my $line;
    my $line_number = 0;
    my $lines_ref   = $input_fields->{'layout'}->{'value'};

    my $read_line = sub {
        if ( scalar(@$lines_ref) == $line_number )
        {
            return 0;
        }
        $line = $lines_ref->[$line_number];
        $line_number++;
        return 1;
    };

    my $gen_exception = sub {
        my $text = shift;
        die "$text on $filename at line "
            . ( $input_fields->{'layout'}->{'line_num'} + $line_number + 1 )
            . "!\n";
    };

    my $y = 0;

INPUT_LOOP: while ( $read_line->() )
    {
        if ( length($line) != $width )
        {
            $gen_exception->("Incorrect number of cells");
        }
        if ( $line =~ /([^\d\*])/ )
        {
            $gen_exception->("Unknown cell type $1");
        }
        push @board, [ split( //, $line ) ];
        $y++;
        if ( $y == $height )
        {
            last;
        }
    }

    if ( $y != $height )
    {
        $gen_exception->("Input terminated prematurely after reading $y lines");
    }

    if ( !defined($start_x) )
    {
        $gen_exception->("The starting position was not defined anywhere");
    }

    $self->{'height'} = $height;
    $self->{'width'}  = $width;
    $self->{'board'}  = \@board;

    return [ $start_x, $start_y ];
}

# A function that accepts the expanded state (as an array ref)
# and returns an atom that represents it.
sub pack_state
{
    my $self         = shift;
    my $state_vector = shift;
    return pack( "cc", @{$state_vector} );
}

# A function that accepts an atom that represents a state
# and returns an array ref that represents it.
sub unpack_state
{
    my $self  = shift;
    my $state = shift;
    return [ unpack( "cc", $state ) ];
}

# Accept an atom that represents a state and output a
# user-readable string that describes it.
sub display_state
{
    my $self  = shift;
    my $state = shift;
    my ( $x, $y ) = @{ $self->unpack_state($state) };
    return sprintf( "X = %i ; Y = %i", $x + 1, $y + 1 );
}

sub check_if_final_state
{
    my $self = shift;

    my $coords = shift;
    return $self->{'board'}->[ $coords->[1] ][ $coords->[0] ] eq "*";
}

# This function enumerates the moves accessible to the state.
# If it returns a move, it still does not mean that it is a valid
# one. I.e: it is possible that it is illegal to perform it.
sub enumerate_moves
{
    my $self = shift;

    my $coords = shift;

    my $x = $coords->[0];
    my $y = $coords->[1];

    my $step = $self->{'board'}->[$y][$x];

    my @moves;

    if ( $x + $step < $self->{'width'} )
    {
        push @moves, "E";
    }

    # The ranges are [0 .. ($width-1)] and [0 .. ($height-1)]
    if ( $x - $step >= 0 )
    {
        push @moves, "W";
    }

    if ( $y + $step < $self->{'height'} )
    {
        push @moves, "S";
    }

    if ( $y - $step >= 0 )
    {
        push @moves, "N";
    }

    return @moves;
}

# This function accepts a state and a move. It tries to perform the
# move on the state. If it is succesful, it returns the new state.
#
# Else, it returns undef to indicate that the move is not possible.
sub perform_move
{
    my $self = shift;

    my $coords = shift;
    my $m      = shift;

    my $step = $self->{'board'}->[ $coords->[1] ][ $coords->[0] ];

    my $offsets    = [ map { $_ * $step } @{ $cell_dirs{$m} } ];
    my @new_coords = @$coords;
    $new_coords[0] += $offsets->[0];
    $new_coords[1] += $offsets->[1];

    return [@new_coords];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::LMSolve::Numbers - driver for solving the number
mazes.

=head1 VERSION

version 0.14.1

=head1 SYNOPSIS

NA - should not be used directly.

=head1 METHODS

=head2 $self->input_board()

Overrided.

=head2 $self->pack_state()

Overrided.

=head2 $self->unpack_state()

Overrided.

=head2 $self->display_state()

Overrided.

=head2 $self->check_if_unsolvable()

Overrided.

=head2 $self->check_if_final_state()

Overrided.

=head2 $self->enumerate_moves()

Overrided.

=head2 $self->perform_move()

Overrided.

=head1 SEE ALSO

L<Games::LMSolve::Base>.

L<http://www.logicmazes.com/n1mz.html>

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-LMSolve>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-LMSolve>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-LMSolve>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Games-LMSolve>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Games-LMSolve>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Games::LMSolve>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-games-lmsolve at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Games-LMSolve>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/lm-solve-source>

  git clone git://github.com/shlomif/lm-solve-source.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/lm-solve-source/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
