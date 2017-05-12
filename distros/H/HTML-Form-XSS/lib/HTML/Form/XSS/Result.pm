package HTML::Form::XSS::Result;

=pod

=head1 NAME

HTML::Form::XSS::Result - Result of XSS HTML form test.

=head1 SYNOPSIS

	my $result = HTML::Form::XSS::Result->new(	#using are modified result class
		form => $form,
		names => \@names,
		check => '<script>alert(1);</script>'
	);

=head1 DESCRIPTION

Please see <HTML::XSSLint::Result> for details, as this object inherits
all of its functions.

=head1 METHODS

=cut

use strict;
use warnings;
use parent qw(HTML::XSSLint::Result);
###############################################

=pod

=head2 example();

	my $exampleUrl $result->example();

Returns a full URL with query string to get an example for
a vulnerable result. Returns undef if the result is not vulnerable.

=cut

###############################################
sub example {	#we show the actual check that we picked up
    my $self = shift;
    return undef unless $self->vulnerable;
    my $uri = URI->new($self->action);
    $uri->query_form(map { $_ => $self->_getCheck() } $self->names);
    return $uri;
}
##############################################
#
# private methods
#
##############################################
sub _getCheck{	#accessor
	my $self = shift;
	return $self->{'check'};
}
##############################################

=pod

=head1 AUTHOR

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 COPYRIGHT

Copyright (c) 2011 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

####################################################
return 1;
