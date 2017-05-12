package Hypatia::Chart::Clicker;
{
  $Hypatia::Chart::Clicker::VERSION = '0.026';
}
use Moose;
use Moose::Util::TypeConstraints;
use Hypatia::Chart::Clicker::Types qw(Options);
use Hypatia::Chart::Clicker::Options;
use namespace::autoclean;

extends 'Hypatia::Base';

#ABSTRACT: Hypatia Bindings for Chart::Clicker


has '+input_data'=>(isa=>'HashRef[ArrayRef[Num]]',is=>'ro');    





has 'data_series_names'=>(isa=>'Str|ArrayRef[Str]',is=>'ro',predicate=>'has_data_series_names');



has 'options'=>(isa=>Options, is=>"ro", coerce=>1, default=>sub{ Hypatia::Chart::Clicker::Options->new });



sub BUILD
{
	my $self=shift;
	
	if($self->has_input_data)
	{
		#dying instead of confessing so that the warning messages are easier to spot
		die "Validation of input_data unsuccessful" unless $self->_validate_input_data($self->input_data);
	}
}


__PACKAGE__->meta->make_immutable;
1; 

__END__

=pod

=head1 NAME

Hypatia::Chart::Clicker - Hypatia Bindings for Chart::Clicker

=head1 VERSION

version 0.026

=head1 SYNOPSIS

This module extends L<Hypatia::Base>, so all of the methods and attributes are inherited. The currently-supported C<graph_type>s are:

=over 4

=item * Area (stacked or not)

=item * Bar (stacked or not)

=item * Bubble

=item * Line (stacked or not)

=item * Pie

=item * Point

=back

=head1 ATTRIBUTES

=head2 input_data (overridden from L<Hypatia>)

This data, if provided, must be a hash reference of array references, where the keys represent the "column names" and the array references represent the (numeric) values of the given column.  Furthermore, if this attribute is set, then each column type in the C<columns> attribute must appear in the keys of C<input_data> and all of the array references must be of the same length and cannot contain any C<undef> entries.

=head2 data_series_names

In C<Chart::Clicker>, every chart has one or more data set (ie L<Chart::Clicker::Data::Set>) and each data set has one or more data series (ie L<Chart::Clicker::Data::Series>).  Each data series has an optional C<name> attribute.  The value(s) for this attribute (either a string or an array reference of strings) is passed directly into the C<name> attribute for each data series.  This attribute is optional, and if it's not used, then a submodule-dependent default will be supplied (usually the relevant C<y> column name).

=head2 options

This is a hash reference of options. Check out L<Hypatia::Chart::Clicker::Options> for more information.

=head1 EXAMPLES

Take a look at the C<examples> folder included with this distribution.

=head1 KNOWN ISSUES

For reasons I don't understand, not all systems seem to render the C<Chart::Clicker> objects correctly. I've tested the examples on Open SuSE, Windows 7, and CentOS. The first system rendered the graphics correctly, the second renders almost correctly save for missing axis ticks, and the third only seems to render blank white rectangles.

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
