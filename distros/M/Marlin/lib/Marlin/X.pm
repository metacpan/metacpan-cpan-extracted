use 5.008008;
use strict;
use warnings;

package Marlin::X;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021000';

use Marlin::Util          qw( true false );
use Types::Common         qw( -types );

use Marlin::Role (
	marlin      => { isa => Object,  required => true, },
	try         => { isa => Bool,    default => false, },
);

sub adjust_setup_steps {
	my $plugin = shift;
	my $steps  = shift;
	
	# Override this in your extension.
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::X - role for Marlin extensions

=head1 DESCRIPTION

Marlin extensions should be classes which compose this role.

  package Marlin::X::MyExtension;
  use Marlin -with => 'Marlin::X';

Marlin I<attribute extensions> should not use this role; they are
themselves roles, applied to the L<Marlin::Attribute> class.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

🐟🐟
