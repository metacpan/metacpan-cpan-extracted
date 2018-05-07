package Games::LMSolve;
$Games::LMSolve::VERSION = '0.12.0';
use strict;
use warnings;

use 5.008;

use Getopt::Long;
use Pod::Usage;

# You can think of this module as a Factory[1] for the solver classes.
# It reads the -g/--game/--preset [variant name] command line option
# and determines which class to instantiate based on it.
#
# Note that it does not touch the other command line options so the
# GetOptions() called by the main() function of the class will be
# able to process them.
#
# [1] - Refer to the book "Design Patterns" by Erich Gamma et. al.
#


sub new
{
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->_initialize(@_);

    return $self;
}

sub _initialize
{
    my $self = shift;

    my %args = @_;

    $self->{'games_solvers'} = {};

    $self->register_all_solvers();

    if (exists($args{'default_variant'}))
    {
        $self->set_default_variant($args{'default_variant'});
    }

    return 0;
}


sub set_default_variant
{
    my $self = shift;

    my $variant = shift;

    $self->{'default_variant'} = $variant;

    return 0;
}


sub register_solvers
{
    my $self = shift;

    my $games = shift;

    $self->{'games_solvers'} = { %{$self->{'games_solvers'}}, %$games};

    return 0;
}


sub register_all_solvers
{
    my $self = shift;

    return 0;
}


sub main
{
    my $self = shift;

    my $variant = $self->{'default_variant'};
    my $help = 0;
    my $man = 0;

    Getopt::Long::Configure('pass_through');
    GetOptions(
        "g|game=s" => \$variant,
        'help|h|?' => \$help,
        'man' => \$man
        ) or pod2usage(2);

    pod2usage(1) if $help;
    pod2usage(-exitstatus => 0, -verbose => 2) if $man;

    if (!exists($self->{'games_solvers'}->{$variant}))
    {
        die "Unknown game variant \"$variant\"";
    }

    my $class = $self->{'games_solvers'}->{$variant};
    my $game;
    if (ref($class) eq "CODE")
    {
        $game = $class->();
    }
    else
    {
        $game = $class->new();
    }
    $game->main();
}
1;

__END__

=pod

=head1 NAME

Games::LMSolve - base class for LM-Solve solvers factories

=head1 VERSION

version 0.12.0

=head1 SYNOPSIS

    package MyReg;

    use Games::LMSolve;

    @ISA = qw(Games::LMSolve);

    use MyPuzzle::Solver;

    sub register_all_solvers
    {
        my $self = shift;

        $self->register_solvers({ 'mypuzzle' => "MyPuzzle::Solver"});

        $self->set_default_variant("mypuzzle");

        return 0;
    }

    package main;

    my $r = MyReg->new();
    $r->main();

=head1 DESCRIPTION

This class is a registry of L<Games::LMSolve::Base>-derived solvers. It
maps variants IDs to the classes. To use it, sub-class it and over-ride
the register_all_solvers() function. In it use register_solvers while
passing a reference to a hash that contains the variant IDs as keys
and the class names, or constructor functions as values.

You can also use set_default_variant() to set the default variant.

After all that, in your main script initialize a registry object, and
call the main() method.

=head1 VERSION

version 0.12.0

=head1 METHODS

=head2 new

The constructor. Accepts the following named arguments:

=over 4

=item * 'default_variant'

The default variant for the registry to be used in case one is not specified.

=back

=head2 $registry->set_default_variant($variant)

Sets the default variant to $variant.

=head2 $self->register_solvers(\%solvers)

Adds the %solvers map of names to class names to the registry.

=head2 $self->register_all_solvers()

To be sub-classes to register all the solvers that the registry wants
to register. Does nothing here.

=head2 $self->main()

the main function that handles the command line arguments and runs the
program.

=head1 SEE ALSO

L<Games::LMSolve::Base>

L<http://www.shlomifish.org/lm-solve/> - the LM-Solve homepage.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-lmsolve at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-LMSolve>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::LMSolve

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-LMSolve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-LMSolve>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-LMSolve>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-LMSolve>

=back

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2002 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/lm-solve-source/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Games::LMSolve

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-LMSolve>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Games-LMSolve>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-LMSolve>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Games-LMSolve>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Games-LMSolve>

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

=cut
