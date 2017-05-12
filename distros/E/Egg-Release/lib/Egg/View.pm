package Egg::View;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: View.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Base /;
use Carp qw/ croak /;

our $VERSION= '3.00';

sub template {
	my $e= shift->e;
	my $template= $e->template || do {
		my $path= join('/', @{$e->action}) || do {
			$e->debug_out(__PACKAGE__. q{ - $e->template is empty. });
			return do { $e->finished('404 Not Found'); (undef) };
		  };
		"$path.". $e->config->{template_extention};
	  };
	$e->debug_out("# + template file : $template");
	$template;
}

1;

__END__

=head1 NAME

Egg::View - Base class for view.

=head1 DESCRIPTION

It is a base class for the view component.

This module has succeeded to L<Egg::Base>.

=head1 METHODS

=head2 template

If this is undefined, passing and the file name of the template are generated
from $e-E<gt>action though $e-E<gt>template is returned.
And, when the template is not obtained from $e-E<gt>action,
it is $e-E<gt>finished(404) and undefined is returned.

  my $template= $e->view->template || return 0;

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Base>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

