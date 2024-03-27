package Games::Solitaire::Verify::App::CmdLine::From_Patsolve;
$Games::Solitaire::Verify::App::CmdLine::From_Patsolve::VERSION = '0.2600';
use strict;
use warnings;
use autodie;

use parent 'Games::Solitaire::Verify::FromOtherSolversBase';

use List::Util qw(first);

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

sub _perform_move
{
    my ( $self, $move_line ) = @_;

    if ( my ($src_card_s) = $move_line =~ /\A(.[HCDS]) to temp\z/ )
    {
        my $src_col_idx = $self->_find_col_card($src_card_s);
        if ( not defined($src_col_idx) )
        {
            die "Cannot find card.";
        }

        my $dest_fc_idx = first { !defined( $self->_st->get_freecell($_) ) }
            ( 0 .. $self->_st->num_freecells - 1 );

        if ( not defined($dest_fc_idx) )
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
            sprintf( "Move a card from %s to the foundations", $src_s[1] ), );
    }
    elsif ( ($src_card_s) = $move_line =~ /\A(.[HCDS]) to empty pile\z/ )
    {
        my $dest_col_idx = $self->_find_empty_col;
        if ( not defined($dest_col_idx) )
        {
            die "Cannot find empty col.";
        }
        my @src_s = $self->_find_card_src_string($src_card_s);

        $self->_perform_and_output_move(
            sprintf( "Move %s from %s to stack %d", @src_s, $dest_col_idx ), );
    }
    elsif ( ( $src_card_s, ( my $dest_card_s ) ) =
        $move_line =~ /\A(.[HCDS]) to (.[HCDS])\z/ )
    {
        my $dest_col_idx = $self->_find_col_card($dest_card_s);
        if ( not defined($dest_col_idx) )
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::App::CmdLine::From_Patsolve - a modulino for
converting from patsolve solutions to fc-solve ones.

=head1 VERSION

version 0.2600

=head1 SYNOPSIS

    $ perl -MGames::Solitaire::Verify::App::CmdLine::From_Patsolve -e 'Games::Solitaire::Verify::App::CmdLine::From_Patsolve->new({argv => \@ARGV})->run()' -- [ARGS]

=head1 DESCRIPTION

This is a a modulino for
converting from patsolve solutions to fc-solve ones.

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
