package Games::Solitaire::Verify::App::CmdLine::From_Patsolve;
$Games::Solitaire::Verify::App::CmdLine::From_Patsolve::VERSION = '0.2202';
use strict;
use warnings;

use autodie;

use parent 'Games::Solitaire::Verify::Base';

use Games::Solitaire::Verify::VariantsMap;
use Games::Solitaire::Verify::Solution;
use Games::Solitaire::Verify::State;
use Games::Solitaire::Verify::State::LaxParser;
use Games::Solitaire::Verify::Move;

use List::MoreUtils qw(firstidx);

use Getopt::Long qw(GetOptionsFromArray);

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _st
            _filename
            _sol_filename
            _variant_params
            _buffer_ref
            )
    ]
);

sub _init
{
    my ( $self, $args ) = @_;

    my $argv = $args->{'argv'};

    my $variant_map = Games::Solitaire::Verify::VariantsMap->new();

    my $variant_params = $variant_map->get_variant_by_id("freecell");

    GetOptionsFromArray(
        $argv,
        'g|game|variant=s' => sub {
            my ( undef, $game ) = @_;

            $variant_params = $variant_map->get_variant_by_id($game);

            if ( !defined($variant_params) )
            {
                die "Unknown variant '$game'!\n";
            }
        },
        'freecells-num=i' => sub {
            my ( undef, $n ) = @_;
            $variant_params->num_freecells($n);
        },
        'stacks-num=i' => sub {
            my ( undef, $n ) = @_;
            $variant_params->num_columns($n);
        },
        'decks-num=i' => sub {
            my ( undef, $n ) = @_;

            if ( !( ( $n == 1 ) || ( $n == 2 ) ) )
            {
                die "Decks should be 1 or 2.";
            }

            $variant_params->num_decks($n);
        },
        'sequences-are-built-by=s' => sub {
            my ( undef, $val ) = @_;

            my %seqs_build_by = (
                ( map { $_ => $_ } (qw(alt_color suit rank)) ),
                "alternate_color" => "alt_color",
            );

            my $proc_val = $seqs_build_by{$val};

            if ( !defined($proc_val) )
            {
                die "Unknown sequences-are-built-by '$val'!";
            }

            $variant_params->seqs_build_by($proc_val);
        },
        'empty-stacks-filled-by=s' => sub {
            my ( undef, $val ) = @_;

            my %empty_stacks_filled_by_map =
                ( map { $_ => 1 } (qw(kings any none)) );

            if ( !exists( $empty_stacks_filled_by_map{$val} ) )
            {
                die "Unknown empty stacks filled by '$val'!";
            }

            $variant_params->empty_stacks_filled_by($val);
        },
        'sequence-move=s' => sub {
            my ( undef, $val ) = @_;

            my %seq_moves = ( map { $_ => 1 } (qw(limited unlimited)) );

            if ( !exists( $seq_moves{$val} ) )
            {
                die "Unknown sequence move '$val'!";
            }

            $variant_params->sequence_move($val);
        },
    ) or die "Cannot process command line arguments";

    my $filename = shift(@$argv);

    if ( !defined($filename) )
    {
        $filename = "-";
    }

    my $sol_filename = shift(@$argv);

    if ( !defined($sol_filename) )
    {
        die "Solution filename not specified.";
    }

    $self->_variant_params($variant_params);
    $self->_filename($filename);
    $self->_sol_filename($sol_filename);

    my $s = '';
    $self->_buffer_ref( \$s );

    return;
}

sub _append
{
    my ( $self, $text ) = @_;

    ${ $self->_buffer_ref } .= $text;

    return;
}

sub _get_buffer
{
    my ($self) = @_;

    return ${ $self->_buffer_ref };
}

sub _slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

sub _read_initial_state
{
    my $self = shift;

    $self->_st(
        Games::Solitaire::Verify::State::LaxParser->new(
            {
                string           => scalar( _slurp( $self->_filename ) ),
                variant          => 'custom',
                'variant_params' => $self->_variant_params(),
            }
        )
    );

    $self->_append("-=-=-=-=-=-=-=-=-=-=-=-\n\n");

    $self->_out_running_state;

    return;
}

sub _out_running_state
{
    my ($self) = @_;

    $self->_append( $self->_st->to_string() . "\n\n====================\n\n" );

    return;
}

sub _perform_and_output_move
{
    my ( $self, $move_s ) = @_;

    $self->_append("$move_s\n\n");

    $self->_st->verify_and_perform_move(
        Games::Solitaire::Verify::Move->new(
            {
                fcs_string => $move_s,
                game       => $self->_st->_variant(),
            },
        )
    );
    $self->_out_running_state;

    return;
}

sub _find_col_card
{
    my ( $self, $card_s ) = @_;

    return firstidx
    {
        my $col = $self->_st->get_column($_);
        ( $col->len == 0 ) ? 0 : $col->top->fast_s eq $card_s
    }
    ( 0 .. $self->_st->num_columns - 1 );
}

sub _find_empty_col
{
    my ($self) = @_;

    return firstidx
    {
        $self->_st->get_column($_)->len == 0
    }
    ( 0 .. $self->_st->num_columns - 1 );
}

sub _find_fc_card
{
    my ( $self, $card_s ) = @_;
    my $dest_fc_idx = firstidx
    {
        my $card = $self->_st->get_freecell($_);
        defined($card) ? ( $card->fast_s eq $card_s ) : 0;
    }
    ( 0 .. $self->_st->num_freecells - 1 );
}

sub _find_card_src_string
{
    my ( $self, $src_card_s ) = @_;

    my $src_col_idx = $self->_find_col_card($src_card_s);

    # TODO : try to find a freecell card.
    if ( $src_col_idx < 0 )
    {
        my $src_fc_idx = $self->_find_fc_card($src_card_s);
        if ( $src_fc_idx < 0 )
        {
            die "Cannot find card <$src_card_s>.";
        }
        return ( "a card", "freecell $src_fc_idx" );
    }
    else
    {
        return ( "1 cards", "stack $src_col_idx" );
    }
}

sub _perform_move
{
    my ( $self, $move_line ) = @_;

    if ( my ($src_card_s) = $move_line =~ /\A(.[HCDS]) to temp\z/ )
    {
        my $src_col_idx = $self->_find_col_card($src_card_s);
        if ( $src_col_idx < 0 )
        {
            die "Cannot find card.";
        }

        my $dest_fc_idx = firstidx
        {
            !defined( $self->_st->get_freecell($_) )
        }
        ( 0 .. $self->_st->num_freecells - 1 );

        if ( $dest_fc_idx < 0 )
        {
            die "No empty freecell.";
        }

        $self->_perform_and_output_move(
            sprintf(
                "Move a card from stack %d to freecell %d",
                $src_col_idx, $dest_fc_idx,
            ),
        );

    }
    elsif ( ($src_card_s) = $move_line =~ /\A(.[HCDS]) out\z/ )
    {
        my @src_s = $self->_find_card_src_string($src_card_s);
        $self->_perform_and_output_move(
            sprintf( "Move a card from %s to the foundations", $src_s[1] ),
        );
    }
    elsif ( ($src_card_s) = $move_line =~ /\A(.[HCDS]) to empty pile\z/ )
    {
        my $dest_col_idx = $self->_find_empty_col;
        if ( $dest_col_idx < 0 )
        {
            die "Cannot find empty col.";
        }
        my @src_s = $self->_find_card_src_string($src_card_s);

        $self->_perform_and_output_move(
            sprintf( "Move %s from %s to stack %d", @src_s, $dest_col_idx ),
        );
    }
    elsif ( ( $src_card_s, ( my $dest_card_s ) ) =
        $move_line =~ /\A(.[HCDS]) to (.[HCDS])\z/ )
    {
        my $dest_col_idx = $self->_find_col_card($dest_card_s);
        if ( $dest_col_idx < 0 )
        {
            die "Cannot find card <$dest_card_s>.";
        }

        my @src_s = $self->_find_card_src_string($src_card_s);
        $self->_perform_and_output_move(
            sprintf( "Move %s from %s to stack %d", @src_s, $dest_col_idx ) );
    }
    else
    {
        die "Unrecognised move_line <$move_line>";
    }
}

sub _process_main
{
    my $self = shift;

    $self->_read_initial_state;

    open my $in_fh, '<', $self->_sol_filename;

    while ( my $l = <$in_fh> )
    {
        chomp($l);
        $self->_perform_move($l);
    }

    close($in_fh);

    $self->_append("This game is solveable.\n");

    return;
}

sub run
{
    my ($self) = @_;

    $self->_process_main;

    print $self->_get_buffer;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::App::CmdLine::From_Patsolve - a modulino for
converting from patsolve solutions to fc-solve ones.

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    $ perl -MGames::Solitaire::Verify::App::CmdLine::From_Patsolve -e 'Games::Solitaire::Verify::App::CmdLine::From_Patsolve->new({argv => \@ARGV})->run()' -- [ARGS]

=head1 DESCRIPTION

This is a a modulino for
converting from patsolve solutions to fc-solve ones.

=head1 METHODS

=head2 run()

Actually execute the command-line application.

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

  perldoc Games::Solitaire::Verify::App::CmdLine::From_Patsolve

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
