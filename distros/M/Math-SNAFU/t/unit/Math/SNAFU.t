=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Math::SNAFU>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use Test2::V0 -target => 'Math::SNAFU';
use Test2::Tools::Spec;
use Data::Dumper;

describe "class `$CLASS`" => sub {

	tests 'is an Exporter::Tiny' => sub {
	
		ok( $CLASS->isa( 'Exporter::Tiny' ) );
	};
};

describe "function `snafu_to_decimal`" => sub {

	my $name = 'snafu_to_decimal';

	tests 'it works' => sub {
		my $f = $CLASS->can( $name );
		is( $f->( '1121-1110-1=0' ), '314159265' );
	};

	tests 'it can be exported' => sub {
		my $got = !! grep /\Q$name/, @Math::SNAFU::EXPORT_OK;
		ok( $got );
	};
};

describe "function `decimal_to_snafu`" => sub {

	my $name = 'decimal_to_snafu';

	tests 'it works' => sub {
		my $f = $CLASS->can( $name );
		is( $f->( '314159265' ), '1121-1110-1=0' );
	};

	tests 'it can be exported' => sub {
		my $got = !! grep /\Q$name/, @Math::SNAFU::EXPORT_OK;
		ok( $got );
	};
};

done_testing;
