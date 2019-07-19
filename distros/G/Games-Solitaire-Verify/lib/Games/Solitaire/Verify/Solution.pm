package Games::Solitaire::Verify::Solution;
$Games::Solitaire::Verify::Solution::VERSION = '0.2202';
use warnings;
use strict;

use 5.008;


use parent 'Games::Solitaire::Verify::Solution::Base';

use Games::Solitaire::Verify::Exception;
use Games::Solitaire::Verify::Card;
use Games::Solitaire::Verify::Column;
use Games::Solitaire::Verify::Move;
use Games::Solitaire::Verify::State;


sub _init
{
    my ( $self, $args ) = @_;

    $self->SUPER::_init($args);

    $self->_st(undef);
    $self->_reached_end(0);

    return 0;
}

sub _read_state
{
    my $self = shift;

    my $line = $self->_l();

    if ( $line ne "\n" )
    {
        die "Non empty line before state";
    }

    my $str = "";

    while ( ( $line = $self->_l() ) && ( $line ne "\n" ) )
    {
        $str .= $line;
    }

    if ( !defined( $self->_st() ) )
    {
        $self->_st(
            Games::Solitaire::Verify::State->new(
                {
                    string => $str,
                    @{ $self->_V },
                }
            )
        );
    }
    else
    {
        if ( $self->_st()->to_string() ne $str )
        {
            die "States don't match";
        }
    }

    while ( defined( $line = $self->_l() ) && ( $line eq "\n" ) )
    {
    }

    if ( $line !~ m{\A={3,}\n\z} )
    {
        die "No ======== separator";
    }

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

    $line = $self->_l();

    if ( $line eq "This game is solveable.\n" )
    {
        $self->_reached_end(1);

        return "END";
    }

    chomp($line);

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

sub _apply_move
{
    my $self = shift;

    if ( my $verdict = $self->_st()->verify_and_perform_move( $self->_move() ) )
    {
        Games::Solitaire::Verify::Exception::VerifyMove->throw(
            error   => "Wrong Move",
            problem => $verdict,
        );
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

        $self->_read_state();
        $self->_st->verify_contents( { max_rank => $self->_max_rank } );

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

1;    # End of Games::Solitaire::Verify::Solution

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::Solution - verify an entire solution
of Freecell Solver (or a similar solver)

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    use Games::Solitaire::Verify::Solution;

    my $input_filename = "freecell-24-solution.txt";

    open (my $input_fh, "<", $input_filename)
        or die "Cannot open file $!";

    # Initialise a column
    my $solution = Games::Solitaire::Verify::Solution->new(
        {
            input_fh => $input_fh,
            variant => "freecell",
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

One can specify a numeric C<'max_rank'> argument to be lower than 13
(new in 0.1900).

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

  perldoc Games::Solitaire::Verify::Solution

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
