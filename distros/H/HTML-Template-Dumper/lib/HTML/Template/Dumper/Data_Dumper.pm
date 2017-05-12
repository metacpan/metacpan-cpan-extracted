
=head1 COPYRIGHT

Copyright 2003, American Society of Agronomy. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software 
Foundation; either version 2, or (at your option) any later version, or

b) the "Artistic License" which comes with Perl.

=cut 


package HTML::Template::Dumper::Data_Dumper;
use strict;
use warnings;
use Data::Dumper;
use base 'HTML::Template::Dumper::Format';

our $VERSION = 0.1;


# 
# Code taken from Data::Serializer::Data::Dumper
# 
sub dump 
{

	my $self = shift;
	my $val = shift || return;
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Purity = 1;
	local $Data::Dumper::Terse = 1;
	return Data::Dumper::Dumper($val);
}

sub parse 
{
	my $self = shift;
	my $val  = shift || return;
	my $M = "";
	# Disambiguate hashref (perl may treat it as a block)
	my $N = eval($val =~ /^\{/ ? '+'.$val : $val);
	return $M ? $M : $N unless $@;
	die "HTML::Template::Dumper::Data_Dumper error: $@" . 
		"\twhile evaluating:\n $val";
}

# avoid used only once warnings
{
	local $Data::Dumper::Terse;
}

1;
__END__


