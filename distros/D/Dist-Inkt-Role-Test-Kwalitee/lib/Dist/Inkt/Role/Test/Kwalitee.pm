use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Test::Kwalitee;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use Types::Standard -types;
use namespace::autoclean;

with qw(Dist::Inkt::Role::Test);

has skip_kwalitee_test => (is => "ro", isa => Bool, default => 0);

after BUILD => sub {
	my $self = shift;
	
	$self->setup_tarball_test(sub {
		my $tarball = $_[1];
		require App::CPANTS::Lint;
		my $app = App::CPANTS::Lint::->new(colour => 1);
		my $res = $app->lint($tarball);
		$app->output_report;
		unless ($res or $self->skip_kwalitee_test) {
			die "Needs more kwalitee";
		}
	});
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Inkt::Role::Test::Kwalitee - check a distribution's kwalitee at build time

=head1 DESCRIPTION

After building a distribution tarball, check its kwalitee.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Dist-Inkt-Role-Test-Kwalitee>.

=head1 SEE ALSO

L<Dist::Inkt>, L<App::CPANTS::Lint>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
