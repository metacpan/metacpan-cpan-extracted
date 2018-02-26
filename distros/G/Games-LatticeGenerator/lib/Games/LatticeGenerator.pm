package Games::LatticeGenerator;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Games::LatticeGenerator::Model::Spaceship;
use Carp;
use GD::Image;

=head1 NAME

Games::LatticeGenerator - The Games::LatticeGenerator for cut&fold.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Games::LatticeGenerator;

    my $f = Games::LatticeGenerator->new(debug => 1);
    
    $f->create_a_random_model("Games::LatticeGenerator::Model::Spaceship", "spaceship");

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new 
{
	my $class = shift;
	my $this = { @_ };
	bless $this, $class;
	($$this{maxx}, $$this{maxy}) = (450, 670);
	return $this;
}


=head2 calculate_the_scale_of

Calculates the maximum scale of the given sheet. 

=cut
sub calculate_the_scale_of
{
	my ($this, $model, $sheet) = @_;
	
	$model->activate_the_planes_of($sheet);
	$$this{scale} = undef;
	
	if (!$model->create_a_lattice())
	{
		croak "lattice has not been created";
	}
	
	$model->determine_the_coordinates();
	
	croak "missing maxx" unless defined $$this{maxx};
	croak "missing maxy" unless defined $$this{maxy};
	
	if ($model->scale_the_lattice(10,30,$$this{maxx}-10,$$this{maxy}-30, undef))
	{
		return $$model{scale};
	}
	return undef;
}

=head2 save_the_lattice_of

Saves the lattice's sheet into a PNG file.

=cut
sub save_the_lattice_of
{
	my ($this, $model, $sheet, $filename) = @_;
	
	$model->activate_the_planes_of($sheet);
	
	$model->determine_the_coordinates();
	
	croak "missing maxx" unless defined $$this{maxx};
	croak "missing maxy" unless defined $$this{maxy};
	
	if ($model->scale_the_lattice(10,30,$$this{maxx}-10,$$this{maxy}-30, $$this{scale}))
	{
		$model->create_png();
		$model->draw_lines();
		$model->save_png("${filename}_${sheet}.png");
	}
	else
	{
		croak "sheet $sheet failed";
	}
}

=head2 create_a_random_model

Creates a model of the given class, calculates the scales of all the sheets, chooses the smallest scale
and saves the sheets into PNG files.

=cut
sub create_a_random_model
{
	my ($this,$class,$filename) = @_;

	my $model = $class->new(
		prefix => "alpha", 
		name => "alpha", 
		add_description => $$this{add_description}, 
		debug => $$this{debug});
	
	carp "missing amount_of_sheets" unless defined $$model{amount_of_sheets};
	
	my @scale = ();
		
	push @scale, $this->calculate_the_scale_of($model, $_) for 1..$$model{amount_of_sheets};

	carp "failed to scale the lattices ".join(",", map { defined($_) ? $_ : "undef" } @scale) if grep { !defined($_) } @scale;
	
	
	@scale = sort grep { defined($_) } @scale;
	croak "no scale" unless defined($scale[0]);

	$$this{scale} = $scale[0]*0.9;
	
	GD::Image->trueColor(1);
	
	if ($filename)
	{
		$this->save_the_lattice_of($model, $_, $filename) for 1..$$model{amount_of_sheets};
	}
	else
	{
		carp "filename undefined";
	}
	
	return $model;
}

=head1 AUTHOR

Pawel Biernacki, C<< <pawel.f.biernacki at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-latticegenerator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-LatticeGenerator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::LatticeGenerator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-LatticeGenerator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-LatticeGenerator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-LatticeGenerator>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-LatticeGenerator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pawel Biernacki.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Games::LatticeGenerator
