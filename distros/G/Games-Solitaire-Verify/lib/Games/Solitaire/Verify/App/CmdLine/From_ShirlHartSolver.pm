package Games::Solitaire::Verify::App::CmdLine::From_ShirlHartSolver;
$Games::Solitaire::Verify::App::CmdLine::From_ShirlHartSolver::VERSION = '0.2601';
use strict;
use warnings;
use autodie;

use parent 'Games::Solitaire::Verify::FromOtherSolversBase';

use List::Util qw(first);

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _move_was_performed
            _input_move_index
            _st
            _filename
            _sol_filename
            _variant_params
            _buffer_ref
        )
    ]
);

my $COL_RE      = qr/[1-8]/;
my $FREECELL_RE = qr/[abcd]/;

sub _perform_and_output_move_wrapper
{
    my $self = shift;

    $self->_perform_and_output_move(shift);
    return $self->_move_was_performed(1);
}

sub _analyze_shirl_hart_move
{
    my ( $self, $src_char, $dest_char, $move_line, $src_card, $dest ) = @_;
    my %fc                  = ( a => 0, b => 1, c => 2, d => 3 );
    my $is_invalid_dest_col = sub {
        my ($dest_col_idx) = @_;
        my $dcol = $self->_st->get_column($dest_col_idx);
        return (
            $dest eq 'e'
            ? ( $dcol->len() > 0 )
            : ( $dest ne $dcol->top->to_string )
        );
    };
    my $try_col = sub {
        my $c = shift;
        if ( $c =~ /\A$COL_RE\z/ )
        {
            return $c - 1;
        }
        return undef;
    };
    my $try_foundation = sub {
        if ( $dest_char eq 'h' )
        {
            if ( $dest ne 'h' )
            {
                die "wrong move foundations - $move_line";
            }
            return 1;
        }
        return;
    };
    my $try_fc = sub {
        my $c = shift;
        return $fc{$c};
    };
    if ( defined( my $src_col_idx = $try_col->($src_char) ) )
    {
        if ( defined( my $dest_fc_idx = $try_fc->($dest_char) ) )
        {
            if ( $dest ne 'f' )
            {
                die "wrong move to freecell - $move_line";
            }
            if ( $src_card ne
                $self->_st->get_column($src_col_idx)->top->to_string )
            {
                die "wrong move to freecell - $move_line";
            }

            return $self->_perform_and_output_move_wrapper(
                sprintf(
                    "Move a card from stack %d to freecell %d",
                    $src_col_idx, $dest_fc_idx,
                ),
            );
        }
        if ( defined( my $dest_col_idx = $try_col->($dest_char) ) )
        {
            $src_card = substr( $src_card, 0, 2 );
            my $col = $self->_st->get_column($src_col_idx);
            my $idx = first { $col->pos($_)->to_string eq $src_card }
                ( 0 .. $col->len - 1 );
            if ( !defined $idx )
            {
                die "wrong move stack to stack - $move_line";
            }
            if ( $is_invalid_dest_col->($dest_col_idx) )
            {
                die "wrong move stack to stack - $move_line";
            }

            return $self->_perform_and_output_move_wrapper(
                sprintf(
                    "Move %d cards from stack %d to stack %d",
                    $col->len() - $idx,
                    $src_col_idx, $dest_col_idx,
                ),
            );
        }

        if ( $try_foundation->() )
        {
            if ( $src_card ne
                $self->_st->get_column($src_col_idx)->top->to_string )
            {
                die "wrong move stack to foundations - $move_line";
            }

            return $self->_perform_and_output_move_wrapper(
                sprintf( "Move a card from stack %d to the foundations",
                    $src_col_idx ),
            );
        }
    }
    elsif ( defined( my $src_fc_idx = $try_fc->($src_char) ) )
    {
        if ( $src_card ne $self->_st->get_freecell($src_fc_idx)->to_string )
        {
            die "wrong freecell card - $move_line";
        }
        if ( $try_foundation->() )
        {
            return $self->_perform_and_output_move_wrapper(
                sprintf( "Move a card from freecell %d to the foundations",
                    $src_fc_idx ),
            );
        }

        if ( defined( my $dest_col_idx = $try_col->($dest_char) ) )
        {
            if ( $is_invalid_dest_col->($dest_col_idx) )
            {
                die "wrong move freecell to stack - $move_line";
            }

            return $self->_perform_and_output_move_wrapper(
                sprintf(
                    "Move a card from freecell %d to stack %d",
                    $src_fc_idx, $dest_col_idx,
                ),
            );
        }
    }
    die "wrong move - $move_line";
}

sub _perform_move
{
    my ( $self, $move_line ) = @_;
    $self->_move_was_performed(0);

    my @fields = ( split /\|/, $move_line, -1 );
    if ( @fields != 5 )
    {
        die "Wrong $move_line";
    }
    my $idx = shift @fields;
    if ( $idx ne $self->_input_move_index )
    {
        die "wrong move index - $move_line";
    }

    my ( $move_s, $src_card, $dest, $found_moves ) = @fields;

    my @src_dest = ( $move_s =~ /(.)/gms );
    if ( @src_dest != 2 )
    {
        die "bad length in move <<$move_s>>!";
    }
    my ( $src_char, $dest_char ) = @src_dest;
    $self->_analyze_shirl_hart_move( $src_char, $dest_char, $move_line,
        $src_card, $dest );
    die "wrong move - $move_line" if not $self->_move_was_performed;
    $self->_perform_autoflush_to_foundation_moves( $found_moves, $move_line );

    $self->_input_move_index( $self->_input_move_index + 1 );
    return;
}

sub _perform_autoflush_to_foundation_moves
{
    my ( $self, $found_moves, $move_line ) = @_;
    return if ( not length $found_moves );
    my $map;
    my %suits;
    $map = sub {
        my $s = shift;
        if ( length($s) == 2 )
        {
            return $map->("$s-$s");
        }
        my ( $start, $end ) = $s =~ /\A(\S\S)-(\S\S)\z/
            or die "wrong found_moves <<$s>>!";
        my $sc = Games::Solitaire::Verify::Card->new( { string => $start } );
        my $ec = Games::Solitaire::Verify::Card->new( { string => $end } );
        if ( $sc->suit ne $ec->suit )
        {
            die "uiui";
        }
        if ( exists $suits{ $sc->suit } )
        {
            die "duplicate";
        }
        if ( $sc->rank > $ec->rank )
        {
            die "foo";
        }
        $suits{ $sc->suit } = { start => $sc, end => $ec };
        return;
    };
    foreach my $f ( split /;/, $found_moves, -1 )
    {
        $map->($f);
    }
    my $count = 1;
FOUNDATION:
    while ( $count > 0 )
    {
        $count = 0;
        foreach my $suit ( sort( keys %suits ) )
        {
            my @src_s;
            my $rec   = $suits{$suit};
            my $start = $rec->{start};
            eval { @src_s = $self->_find_card_src_string( $start->to_string ); };
            if ( !$@ )
            {
                ++$count;
                my $rank = $start->rank;
                if ( $rank == $rec->{end}->rank )
                {
                    delete $suits{$suit};
                }
                else
                {
                    $start->rank( 1 + $rank );
                }
                $self->_perform_and_output_move(
                    sprintf( "Move a card from %s to the foundations",
                        $src_s[1] ),
                );
                next FOUNDATION;
            }
        }
    }
    if (%suits)
    {
        die "cannot move to foundations - $move_line";
    }
}

sub _process_main
{
    my $self = shift;

    $self->_read_initial_state;
    $self->_input_move_index(1);

    open my $in_fh, '<', $self->_sol_filename;

    my $l;
FIRST_lines:
    while ( $l = <$in_fh> )
    {
        chomp($l);
        last FIRST_lines if ( $l =~ /\|/ );
    }

    while ( $l =~ /\|/ )
    {
        $self->_perform_move($l);
        $l = <$in_fh>;
        chomp $l;
    }
    close($in_fh);

    $self->_append("This game is solveable.\n");

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::App::CmdLine::From_ShirlHartSolver - a modulino for
converting from Shirl Hart's solver's solutions to fc-solve ones.

=head1 VERSION

version 0.2601

=head1 SYNOPSIS

    $ perl -MGames::Solitaire::Verify::App::CmdLine::From_Patsolve -e 'Games::Solitaire::Verify::App::CmdLine::From_Patsolve->new({argv => \@ARGV})->run()' -- [ARGS]

=head1 DESCRIPTION

This is a a modulino for
converting from Shirl Hart's solver's solutions to fc-solve ones.

L<https://github.com/shlomif/shirl-hart-freecell-solver/> .

=head1 METHODS

=head2 run()

Actually execute the command-line application.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-Solitaire-Verify>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Solitaire-Verify>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-Solitaire-Verify>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Games-Solitaire-Verify>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Games-Solitaire-Verify>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Games::Solitaire::Verify>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-games-solitaire-verify at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Games-Solitaire-Verify>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/fc-solve>

  git clone git://github.com/shlomif/fc-solve.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fc-solve/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
