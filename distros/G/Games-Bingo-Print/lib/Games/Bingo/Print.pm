package Games::Bingo::Print;

# $Id: Print.pm 1835 2007-03-17 17:36:20Z jonasbn $

use strict;
use warnings;
use integer;
use Carp qw(croak);
use PDFLib;
use vars qw($VERSION);

use Games::Bingo::Card;

$VERSION = '0.04';

sub new {
    my ( $class, %opts ) = @_;

    my $self = bless {
        text => $opts{text} ? $opts{text} : 'by jonasbn <jonasbn@cpan.org>',
        heading   => $opts{heading}   ? $opts{heading}   : 'Games::Bingo',
        papersize => $opts{papersize} ? $opts{papersize} : 'a4',
    }, $class || ref $class;

    eval {
        $self->{pdf} = PDFLib->new(
            filename => $opts{filename} ? $opts{filename} : 'bingo.pdf',
            papersize => $self->{papersize},
            creator   => 'Games::Bingo::Print',
            author    => 'Jonas B. Nielsen',
            title     => 'Bingo!',
        );
        $self->{pdf}->start_page;
    };

    if ($@) {
        croak 'Unable to construct object - '.$@;
    } else {
        return $self;
    }
}

sub print_pages {
    my ( $self, $pages, $cards ) = @_;

    eval {
        foreach my $i ( 1 .. $pages )
        {

            if ($cards) {
                if ( $cards > 3 ) {
                    $cards = 3;
                }
            } else {
                $cards = 3;
            }

            $self->{pdf}->set_font(
                face => 'Helvetica',
                size => 40,
                bold => 1
            );
            $self->{pdf}->print_boxed(
                $self->{heading},
                mode => 'center',
                'x'  => 0,
                'y'  => 740,
                'w'  => 595,
                'h'  => 50
            );
            $self->{pdf}->set_font(
                face => 'Helvetica',
                size => 12,
                bold => 1
            );
            $self->{pdf}->print_boxed(
                $self->{text},
                'mode' => 'center',
                'x'    => 0,
                'y'    => 685,
                'w'    => 595,
                'h'    => 50
            );

            my $y_start_cordinate = 685;
            my $x_start_cordinate = 30;
            my $size              = 60;
            my $yec;
            my $ysc;
            my $cardsize = $size * 3;

            for ( my $card = 1; $card <= $cards; $card++ ) {

                $ysc = $y_start_cordinate - $cardsize;
                $yec = $ysc + $cardsize;

                $self->_print_card(
                    size              => $size,
                    x_start_cordinate => $x_start_cordinate,
                    y_start_cordinate => $ysc,
                    y_end_cordinate   => $yec,
                );
                $y_start_cordinate = $ysc - 50;
            }
        }
        $self->{pdf}->stroke;
        $self->{pdf}->finish;
    };

    if ($@) {
        carp ('Unable to generate page - '.$@);
        return 0;
    } else {
        return 1;
    }
}

sub _print_card {
    my $self = shift;
    my %args = @_;

    my $p = Games::Bingo::Card->new();
    $p = $p->populate();

    my $ysc  = $args{'y_start_cordinate'};
    my $yec  = $args{'y_end_cordinate'};
    my $xsc  = $args{'x_start_cordinate'};
    my $size = $args{'size'};

    my $y = 3;
    for ( my $ry = $ysc; $ry < $yec; $ry += $size ) {
        my @numbers;
        for ( my $x = 0; $x <= 9; $x++ ) {
            push( @numbers, $p->[ $x - 1 ]->[ $y - 1 ] );
        }
        $self->_print_row(
            size              => $size,
            x_start_cordinate => $xsc,
            y_start_cordinate => $ry,
            x_end_cordinate   => 540,
            numbers           => \@numbers,
        );
        $y--;
    }
    return 1;
}

sub _print_row {
    my $self = shift;
    my %args = @_;

    my $ysc     = $args{'y_start_cordinate'};
    my $xsc     = $args{'x_start_cordinate'};
    my $xec     = $args{'x_end_cordinate'};
    my $size    = $args{'size'};
    my $numbers = $args{'numbers'};

    my $x;
    for ( my $rx = $xsc; $rx <= $xec; $rx += $size ) {
        ++$x;
        my $label = $numbers->[$x] ? $numbers->[$x] : '';

        $self->{pdf}->rect(
            'x' => $rx,
            'y' => $ysc,
            'w' => $size,
            'h' => $size
        );
        $self->{pdf}->stroke;
        $self->{pdf}->set_font(
            face => 'Helvetica',
            size => 40,
            bold => 1
        );
        $self->{pdf}->print_at(
            $label,
            'mode' => 'right',
            'w'    => $size,
            'h'    => $size,
            'x'    => $rx + 8,
            'y'    => $ysc + 13
        );

    }
    return 1;
}

1;

__END__

=pod

=head1 NAME

Games::Bingo::Print - a PDF Generation Class for Games::Bingo

=head1 SYNOPSIS

	use Games::Bingo::Print;

	my $bp = Games::Bingo::Print-E<gt>new();

	$bp-E<gt>print_pages(2);

	my $bp = Games::Bingo::Print->new(
		heading  => 'Jimmys bingohalle',
		text     => 'its all in the game!'
		filename => 'jimmys.pdf
	);

=head1 VERSION

This documentation describes version 0.03 of Games::Bingo::Print

=head1 DESCRIPTION

This is that actual printing class. It generates a PDF file with pages
containing bingo cards.

The page contains space for 3 bingo cards, each consisting of 3 rows
and 10 columns like this:

=begin text

+--+--+--+--+--+--+--+--+--+
|  |  |  |  |  |  |  |  |  |
+--+--+--+--+--+--+--+--+--+
|  |  |  |  |  |  |  |  |  |
+--+--+--+--+--+--+--+--+--+
|  |  |  |  |  |  |  |  |  |
+--+--+--+--+--+--+--+--+--+

=end text

=begin html

E<lt>preE<gt>
+--+--+--+--+--+--+--+--+--+
|  |  |  |  |  |  |  |  |  |
+--+--+--+--+--+--+--+--+--+
|  |  |  |  |  |  |  |  |  |
+--+--+--+--+--+--+--+--+--+
|  |  |  |  |  |  |  |  |  |
+--+--+--+--+--+--+--+--+--+
E<lt>/preE<gt>

=end html

So a filled out example card could look like this:

=begin text

+--+--+--+--+--+--+--+--+--+
| 4|13|  |30|  |  |62|  |  |
+--+--+--+--+--+--+--+--+--+
|  |  |22|  |41|53|  |78|  |
+--+--+--+--+--+--+--+--+--+
|  |14|27|  |  |  |65|  |80|
+--+--+--+--+--+--+--+--+--+

=end text

=begin html

<pre>

+--+--+--+--+--+--+--+--+--+
| 4|13|  |30|  |  |62|  |  |
+--+--+--+--+--+--+--+--+--+
|  |  |22|  |41|53|  |78|  |
+--+--+--+--+--+--+--+--+--+
|  |14|27|  |  |  |65|  |80|
+--+--+--+--+--+--+--+--+--+

</pre>

=end html

=head1 SUBROUTINES/METHODS

=head2 new

The constructor

The constructor can take several options, all these are optional.

=over 4

=item * heading

The heading on the generated bingo card PDF.

=item * text 

The smaller text on the generated bingo card PDF, the default is the
authors name (SEE AUTHOR section below).

=item * filename

The name of the file containing the generated bingo card PDF, the
default is 'bingo.pdf'

=back

If it is not possible to create an object the constructor dies with the diagnostic
'Unable to construct object' and some additional diagnostic depending on the
problem, which might relate to third party components used. See DEPENDENCIES.

=head2 print_pages

The B<print_pages> is the main method it takes two arguments, the
number of pages you want to print and optionally the number of cards
you want to print on a page. 

The default is 3 cards on a page which also is the maximum.

The B<print_pages> method returns 1 on success and 0 on failure, failure issues
a warning.

B<print_pages> calls B<_print_card>.

=head2 _print_card

This is the method used to print the actual card, it calls B<_print_row> 3
times.

=over 4

=item * y_start_cordinate

The B<Y> start cordinate (we print botton up for now, please see the TODO file).

=item * y_end_cordinate

The B<Y> end cordinate (we print botton up for now, please see the TODO file).

=item * x_start_cordinate

The B<X> start cordinate (we print botton up for now, please see the TODO file).

=item * size

The pixel size of the box containg the number,

=back

=head2 _print_row

This method prints a single row.

=over 4
	
=item * y_start_cordinate

The B<Y> start cordinate (we print botton up for now, please see the TODO file).

=item * x_start_cordinate

The B<X> start cordinate (we print botton up for now, please see the TODO file).

=item * x_end_cordinate

The B<X> end cordinate (we print botton up for now, please see the TODO file),

=item * size

The pixel size of the box containg the number.

=item * numbers

The numbers to be inserted into the row as an reference to an array.

=back

=head1 DIAGNOSTICS

=over

=item * 'Unable to construct object', a dianostic from the constructor (L<new>)
and some additional diagnostic depending on the problem, which might relate to
third party components used. See DEPENDENCIES.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Games::Bingo::Print requires no special configuration or environment apart from
what is listed in the DEPENDENCIES section.

=head1 DEPENDENCIES

=over 4

=item * L<Games::Bingo>

=item * L<Games::Bingo::Card>

=item * L<PDFLib>

=back

=head1 INCOMPATIBILITIES

There are no known incompatibilities.

=head1 BUGS AND LIMITATIONS

The PDF generator only works with L<Games::Bingo>

=head1 BUGREPORTING

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-CPR

or by sending mail to

  bug-Business-DK-CPR@rt.cpan.org

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Bingo::Print

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Bingo-Print>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Bingo-Print>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Bingo-Print>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Bingo-Print>

=back

=head1 TEST

I am currently not able to generate a test coverage report for
Games::Bingo::Print.

Perl::Critic tests (t/critic) are enable by settting the environment variable
TEST_AUTHOR.

Kwalitee tests (t

=head1 SEE ALSO

=over 4

=item * bin/bingo_print.pl

=back

=head1 TODO

The TODO file contains a complete list for the Games::Bingo::Print class.

=head1 AUTHOR

=over 

=item * Jonas B. Nielsen, (jonasbn) C<< <jonasbn@cpan.org> >>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * Thanks to Matt Sergeant for suggesting using PDFLib. 

=back

=head1 LICENSE AND COPYRIGHT

Games::Bingo::Print and related modules are free software and is
released under the Artistic License. See
E<lt>http://www.perl.com/language/misc/Artistic.htmlE<gt> for details.

Games::Bingo::Print is (C) 2003-2007 Jonas B. Nielsen (jonasbn)
E<lt>jonasbn@cpan.orgE<gt>

=cut
