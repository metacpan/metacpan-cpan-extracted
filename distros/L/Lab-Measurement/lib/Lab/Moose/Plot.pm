
=head1 NAME

Lab::Moose::Plot - Frontend to L<PDL::Graphics::Gnuplot>.

=head1 SYNOPSIS

 use PDL;
 use Lab::Moose::Plot;

 # use default terminal 'qt'
 my $plot = Lab::Moose::Plot->new();

 # simple 2-D plot
 my $x = sequence(10);
 my $y = 2 * $x;

 $plot->plot(
     plot_options => {title => 'linear function'},
     curve_options => {legend => '2 * x'},
     data => [$x, $y]
 );

 # pm3d plot
 my $z = sin(rvals(300, 300) / 10);
 my $x = xvals($z);
 my $y = yvals($z);

 $plot->splot(
     plot_options => {
         title => 'a pm3d plot',
	 pm3d => 1,
	 view => 'map',
	 surface => 0,
         palette => "model RGB defined ( 0 'red', 1 'yellow', 2 'white' )",
     },
     data => [$x, $y, $z],
 );

 
 # use a different terminal with default plot options

 my $plot = Lab::Moose::Plot(
     terminal => 'svg',
     terminal_options => {output => 'file.svg', enhanced => 0},
     plot_options => {pm3d => 1, view => 'map', surface => 0}
 );

=head1 DESCRIPTION

This is a small wrapper around L<PDL::Graphics::Gnuplot> with the aim to make
it accessible with our hash-based calling convention.

See the documentation of L<PDL::Graphics::Gnuplot> for the allowed values of
terminal-, plot- and curve-options.


=cut

package Lab::Moose::Plot;

use warnings;
use strict;
use 5.010;

use Moose;
use Moose::Util::TypeConstraints qw/union class_type/;
use MooseX::Params::Validate;
use Carp;

use PDL::Graphics::Gnuplot ();

# need to load for ClassName type constraint.
use PDL ();

our $VERSION = '3.543';

has terminal => (
    is      => 'ro',
    isa     => 'Str',
    default => 'qt'
);

has terminal_options => (
    is      => 'ro',
    isa     => 'HashRef',
    builder => 'build_terminal_options',
    lazy    => 1,
);

has plot_options => (
    is      => 'ro',
    isa     => 'HashRef',
    builder => 'build_plot_options',
    lazy    => 1,
);

has curve_options => (
    is      => 'ro',
    isa     => 'HashRef',
    builder => 'build_curve_options',
    lazy    => 1,
);

has gpwin => (
    is       => 'ro',
    isa      => 'PDL::Graphics::Gnuplot',
    init_arg => undef,
    writer   => '_gpwin',
);

sub build_terminal_options {
    my $self = shift;
    my $term = $self->terminal();

    if ( $term =~ /^(qt|x11)$/ ) {
        return { persist => 1, raise => 0 };
    }
    else {
        return {};
    }
}

sub build_plot_options {
    return {};
}

sub build_curve_options {
    return {};
}

=head1 METHODS

=head2 new

 my $plot = Lab::Moose::Plot->new(
     terminal => $terminal,
     terminal_options => \%terminal_options,
     plot_options => \%plot_options,
     curve_options => \%curve_options,
 );

Construct a new plotting backend. All arguments are optional. The default for
C<terminal> is 'qt'. For the 'qt' and 'x11' terminals, C<terminal_options>
defaults to C<< {persist => 1, raise => 0 } >>. The default for
C<plot_options> and C<curve_options> is the empty hash.

=cut

sub BUILD {
    my $self  = shift;
    my $gpwin = PDL::Graphics::Gnuplot->new(
        $self->terminal(),
        %{ $self->terminal_options() },
        $self->plot_options()
    );
    $self->_gpwin($gpwin);
}

# Cannot simply put 'isa => 'PDL|ArrayRef[Num]'. See
# http://stackoverflow.com/questions/5196294/why-can-i-use-a-class-name-as-a-moose-type-but-not-when-part-of-a-type-union

union 'Lab::Moose::Plot::DataArg', [ class_type('PDL'), 'ArrayRef[Num]' ];

sub _parse_options {
    my $self = shift;
    my ( $plot_options, $curve_options, $data ) = validated_list(
        \@_,
        plot_options  => { isa => 'HashRef', default  => {} },
        curve_options => { isa => 'HashRef', optional => 1 },
        data => { isa => 'ArrayRef[Lab::Moose::Plot::DataArg]' },
    );

    if ( @{$data} == 0 ) {
        croak "missing data columns";
    }

    if ( not defined $curve_options ) {
        $curve_options = $self->curve_options();
    }

    return ( $plot_options, $curve_options, $data );
}

sub _plot {
    my $self = shift;
    my ( $plot_options, $curve_options, $data, $plot_function ) = @_;

    my $gpwin = $self->gpwin();

    $gpwin->$plot_function( $plot_options, %{$curve_options}, @{$data} );
}

=head2 plot

 $plot->plot(
     plot_options => \%plot_options,
     curve_options => \%curve_options,
     data => [$x, $y, $z],
 );

Call L<PDL::Graphics::Gnuplot>'s plot function.
The data array can contain either PDLs ore 1D arrad refs. The required number
of elements in the array depends on the used plotting style.

=head2 splot

=head2 replot

splot and replot call L<PDL::Graphics::Gnuplot>'s splot and replot functions.
Otherwise they behave like plot.

=cut

my $meta = __PACKAGE__->meta();

for my $func (qw/plot splot replot/) {
    $meta->add_method(
        $func => sub {
            my $self = shift;
            my ( $plot_options, $curve_options, $data )
                = $self->_parse_options(@_);

            $self->_plot( $plot_options, $curve_options, $data, $func );
        }
    );
}

__PACKAGE__->meta->make_immutable();

1;
