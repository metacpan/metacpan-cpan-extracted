=pod

=encoding utf-8

=head1 PURPOSE

Test new readonly var feature.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;

BEGIN {
	package Local::Package;
	use Exporter::Almighty -setup => {
		const => {
			colours => { RED => 'red', BLUE => 'blue', GREEN => 'green' },
		},
	};
	1;
};

{
	use Local::Package -lexical, qw( $RED $BLUE $GREEN );
	is( $RED, 'red' );
	is( $BLUE, 'blue' );
	is( $GREEN, 'green' );

	my $e = do {
		local $@;
		eval '$BLUE = 42';
		$@
	};
	isnt( $e, undef, 'exception writing to read-only variable' );
}

done_testing;
