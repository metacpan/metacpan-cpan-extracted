
=head1 COPYRIGHT

Copyright 2003, American Society of Agronomy. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software 
Foundation; either version 2, or (at your option) any later version, or

b) the "Artistic License" which comes with Perl.

=cut


package HTML::Template::Dumper::Format;
use strict;
use warnings;

our $VERSION = 0.1;

sub new 
{
	my $class = shift;
	my $self = '';
	bless \$self, $class;
}

sub dump 
{
	my $self   = shift;
	my $class  = ref $self || $self;
	die "$class did not override dump()";
}

sub parse 
{
	my $self   = shift;
	my $class  = ref $self || $self;
	die "$class did not override parse()";
}


1;
__END__


