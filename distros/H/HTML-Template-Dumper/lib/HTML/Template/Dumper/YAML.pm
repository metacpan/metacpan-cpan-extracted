
=head1 COPYRIGHT

Copyright 2003, American Society of Agronomy. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software 
Foundation; either version 2, or (at your option) any later version, or

b) the "Artistic License" which comes with Perl.

=cut


package HTML::Template::Dumper::YAML;
use strict;
use warnings;
use YAML;
use base 'HTML::Template::Dumper::Format';

our $VERSION = 0.1;


sub dump 
{
	my $self = shift; 
	my $ref  = shift || return;

	return Dump( $ref );
}

sub parse 
{
	my $self = shift;
	my $data = shift || return;
	
	return Load( $data );
}


1;
__END__


