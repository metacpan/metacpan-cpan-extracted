package Games::Solitaire::Verify::Solution::ExpandMultiCardMoves;
$Games::Solitaire::Verify::Solution::ExpandMultiCardMoves::VERSION = '0.2202';
use warnings;
use strict;
use 5.014;


use parent 'Games::Solitaire::Verify::Solution::Base';

# TODO : Merge with lib/Games/Solitaire/Verify/Solution.pm

use POSIX qw( ceil );

use Games::Solitaire::Verify::Exception ();
use Games::Solitaire::Verify::Card      ();
use Games::Solitaire::Verify::Column    ();
use Games::Solitaire::Verify::Move      ();
use Games::Solitaire::Verify::State     ();

use List::Util qw( min );

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _move_line
            _output_fh
            )
    ]
);


sub _init
{
    my ( $self, $args ) = @_;

    $self->SUPER::_init($args);

    $self->_st(undef);
    $self->_reached_end(0);
    $self->_output_fh( $args->{output_fh} );

    return 0;
}

sub _out
{
    my ( $self, $text ) = @_;

    $self->_output_fh()->print($text);

    return;
}

sub _out_line
{
    my ( $self, $line ) = @_;

    return $self->_out($line);
}

sub _assign_read_new_state
{
    my ( $self, $str ) = @_;

    my $new_state = Games::Solitaire::Verify::State->new(
        {
            string => $str,
            @{ $self->_V },
        }
    );

    if ( !defined( $self->_st() ) )
    {
        # Do nothing.

    }
    else
    {
        if ( $self->_st()->to_string() ne $str )
        {
            die "States don't match";
        }
    }
    $self->_st($new_state);

    return;
}

sub _read_state
{
    my $self = shift;

    my $line = $self->_l();

    if ( $line ne "\n" )
    {
        die "Non empty line before state";
    }

    $self->_out_line($line);

    my $str = "";

    while ( ( $line = $self->_l() ) && ( $line ne "\n" ) )
    {
        $str .= $line;
    }

    $self->_assign_read_new_state($str);

    $self->_out($str);

    $self->_out_line("\n");
    while ( defined( $line = $self->_l() ) && ( $line eq "\n" ) )
    {
        $self->_out_line($line);
    }

    if ( $line !~ m{\A={3,}\n\z} )
    {
        die "No ======== separator";
    }
    $self->_out_line($line);

    return;
}

sub _read_move
{
    my $self = shift;

    my $line = $self->_l();

    if ( $line ne "\n" )
    {
        die "No empty line before move";
    }

    $self->_out_line($line);

    $line = $self->_l();

    if ( $line eq "This game is solveable.\n" )
    {
        $self->_reached_end(1);
        $self->_out_line($line);

        while ( defined( $line = $self->_l() ) )
        {
            $self->_out_line($line);
        }

        return "END";
    }

    chomp($line);

    $self->_move_line($line);

    $self->_move(
        Games::Solitaire::Verify::Move->new(
            {
                fcs_string => $line,
                game       => $self->_variant(),
            }
        )
    );

    return;
}


sub _find_max_step
{
    my ( $self, $n ) = @_;

    my $x = 1;

    while ( ( $x << 1 ) < $n )
    {
        $x <<= 1;
    }

    return $x;
}

sub _apply_move
{
    my $self = shift;

    if (   ( $self->_move->source_type eq "stack" )
        && ( $self->_move->dest_type eq "stack" )
        && ( $self->_move->num_cards > 1 )
        && ( $self->_variant_params->sequence_move() eq "limited" ) )
    {
        my $ultimate_num_cards = $self->_move->num_cards;
        my $ultimate_source    = $self->_move->source;
        my $ultimate_dest      = $self->_move->dest;

        # Need to process this move.
        my @empty_fc_indexes;
        my @empty_stack_indexes;

        foreach my $idx ( 0 .. ( $self->_st->num_freecells() - 1 ) )
        {
            if ( !defined( $self->_st->get_freecell($idx) ) )
            {
                push @empty_fc_indexes, $idx;
            }
        }

        foreach my $idx ( 0 .. ( $self->_st->num_columns() - 1 ) )
        {
            if (   ( $idx != $ultimate_dest )
                && ( $idx != $ultimate_source )
                && ( !$self->_st->get_column($idx)->len() ) )
            {
                push @empty_stack_indexes, $idx;
            }
        }

        my @num_cards_moved_at_each_stage;

        my $num_cards = 0;
        push @num_cards_moved_at_each_stage, $num_cards;
        my $step_width = 1 + @empty_fc_indexes;
        while (
            (
                $num_cards =
                min( $num_cards + $step_width, $ultimate_num_cards )
            ) < $ultimate_num_cards
            )
        {
            push @num_cards_moved_at_each_stage, $num_cards;
        }
        push @num_cards_moved_at_each_stage, $num_cards;

        # Initialised to the null sub.
        my $output_state_promise = sub {
            return;
        };

        my $past_first_output_state_promise = sub {
            $self->_out(
                "\n" . $self->_st->to_string . "\n\n====================\n\n" );

            return;
        };

        my $add_move = sub {
            my ($move_line) = @_;

            $output_state_promise->();

            $self->_out_line( $move_line . "\n" );

            if (
                my $verdict = $self->_st()->verify_and_perform_move(
                    Games::Solitaire::Verify::Move->new(
                        {
                            fcs_string => $move_line,
                            game       => $self->_variant(),
                        }
                    )
                )
                )
            {
                Games::Solitaire::Verify::Exception::VerifyMove->throw(
                    error   => "Wrong Move",
                    problem => $verdict,
                );
            }

            $output_state_promise = $past_first_output_state_promise;

            return;
        };

        my $move_using_freecells = sub {
            my ( $source, $dest, $count ) = @_;

            my $num_cards_thru_freecell = $count - 1;
            for my $i ( 0 .. $num_cards_thru_freecell - 1 )
            {
                $add_move->(
"Move a card from stack $source to freecell $empty_fc_indexes[$i]"
                );
            }
            $add_move->("Move 1 cards from stack $source to stack $dest");

            for my $i ( reverse( 0 .. $num_cards_thru_freecell - 1 ) )
            {
                $add_move->(
"Move a card from freecell $empty_fc_indexes[$i] to stack $dest"
                );
            }

            return;
        };

        my $recursive_move;
        $recursive_move = sub {
            my ( $source, $dest, $num_cards, $empty_cols ) = @_;

            if ( $num_cards <= 0 )
            {
                # Do nothing - the no-op.
                #$move_using_freecells->($source, $dest,
                #    $num_cards_moved_at_each_stage[$depth] -
                #    $num_cards_moved_at_each_stage[$depth-1]
                #);
                return;
            }
            else
            {
                my @running_empty_cols = @$empty_cols;
                my @steps;

                while ( ceil( $num_cards / $step_width ) > 1 )
                {
                    # Top power of two in $num_steps
                    my $rec_num_steps = $self->_find_max_step(
                        ceil( $num_cards / $step_width ) );
                    my $count_cards = $rec_num_steps * $step_width;
                    my $temp_dest   = shift(@running_empty_cols);
                    $recursive_move->(
                        $source, $temp_dest, $count_cards,
                        [@running_empty_cols],
                    );

                    push @steps,
                        +{
                        'source' => $source,
                        'dest'   => $temp_dest,
                        count    => $count_cards
                        };
                    $num_cards -= $count_cards;
                }
                $move_using_freecells->( $source, $dest, $num_cards );

                foreach my $s ( reverse(@steps) )
                {
                    $recursive_move->(
                        $s->{dest}, $dest, $s->{count}, [@running_empty_cols]
                    );
                    @running_empty_cols =
                        ( sort { $a <=> $b } @running_empty_cols, $s->{dest} );
                }
                return;
            }
        };

        $recursive_move->(
            $ultimate_source, $ultimate_dest,
            $ultimate_num_cards, [@empty_stack_indexes],
        );
    }
    else
    {
        $self->_out_line( $self->_move_line . "\n" );
        if ( my $verdict =
            $self->_st()->verify_and_perform_move( $self->_move() ) )
        {
            Games::Solitaire::Verify::Exception::VerifyMove->throw(
                error   => "Wrong Move",
                problem => $verdict,
            );
        }
    }

    return;
}


sub verify
{
    my $self = shift;

    eval {

        my $line = $self->_l();

        if ( $line !~ m{\A(-=)+-\n\z} )
        {
            die "Incorrect start";
        }
        $self->_out_line($line);

        $self->_read_state();

        while ( !defined( scalar( $self->_read_move() ) ) )
        {
            $self->_apply_move();
            $self->_read_state();
        }
    };

    my $err;
    if ( !$@ )
    {
        # Do nothing - no exception was thrown.
    }
    elsif (
        $err = Exception::Class->caught(
            'Games::Solitaire::Verify::Exception::VerifyMove')
        )
    {
        return { error => $err, line_num => $self->_ln(), };
    }
    else
    {
        $err = Exception::Class->caught();
        ref $err ? $err->rethrow : die $err;
    }

    return;
}

1;    # End of Games::Solitaire::Verify::Solution::ExpandMultiCardMoves

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::Solution::ExpandMultiCardMoves - expand
the moves in a solution from multi-card moves into individual single-card
moves.

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    use Games::Solitaire::Verify::Solution::ExpandMultiCardMoves;

    my $input_filename = "freecell-24-solution.txt";

    open (my $input_fh, "<", $input_filename)
        or die "Cannot open file $!";

    # Initialise a column
    my $solution = Games::Solitaire::Verify::Solution::ExpandMultiCardMoves->new(
        {
            input_fh => $input_fh,
            variant => "freecell",
            output_fh => \*STDOUT,
        },
    );

    my $ret = $solution->verify();

    close($input_fh);

    if ($ret)
    {
        die $ret;
    }
    else
    {
        print "Solution is OK";
    }

=head1 METHODS

=head2 Games::Solitaire::Verify::Solution->new({variant => $variant, input_fh => $input_fh})

Constructs a new solution verifier with the variant $variant (see
L<Games::Solitaire::Verify::VariantsMap> ), and the input file handle
$input_fh.

If $variant is C<"custom">, then the constructor also requires a
C<'variant_params'> key which should be a populated
L<Games::Solitaire::Verify::VariantParams> object.

=begin notes

=head1 Planning.

Let's supppose we are moving 7 cards from col 1 to col 6, with one
empty freecell and two empty columns.

* 8 7 6 5 4 3 2 1

* 8

We first move [2 1] to an empty column, then move [4 3] there, then move
[2 1] on top of the [4 3] to form a [4 3 2 1]. Then we move [6 5]
to the other empty column, and then we move 7 across and do the reverse
moves.

=end notes

=head2 $solution->verify()

Traverse the solution verifying it.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fc-solve/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Games::Solitaire::Verify::Solution::ExpandMultiCardMoves

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-Solitaire-Verify>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Games-Solitaire-Verify>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Solitaire-Verify>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Games-Solitaire-Verify>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Games-Solitaire-Verify>

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

=cut
