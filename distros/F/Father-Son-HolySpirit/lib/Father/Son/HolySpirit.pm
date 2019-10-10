package Father::Son::HolySpirit;

require Exporter;
our @ISA = "Exporter";

our @EXPORT = qw(
	amen
);

our $VERSION = '1.00';

sub amen { 1 }

amen;

__END__

=head1 NAME

Father::Son::HolySpirit - write modules like a true Perl monk.

=head1 SYNOPSIS

	use Father::Son::HolySpirit;

	# an explicit constructor is recommended
	sub baptize
	{
		my ($church, $child) = @_;
		bless $child, $church;
	}

	# end your module the proper way
	amen;

=head1 DESCRIPTION

Give your modules some syntactic sugar with proper start and end. No more 1; at the end.
Best paired with bless and confess.

=head2 EXPORTS

=head3 amen

Returns a true value (1). Best used at the end of a module.

=head1 AUTHOR

Bartosz Jarzyna, E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.06.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
