=pod

=encoding utf-8

=head1 PURPOSE

Test what happens when trying to import symbols and tags that don't exist
or aren't marked as suitable for exporting.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 4;

sub exception ($) {
	local $@;
	eval shift;
	return $@;
}

BEGIN {
	package My::Exporter;
	use Exporter::Shiny qw( $Foo Bar Bam wibble );
	our $Foo = 42;
	sub Bar { 666 }
	sub Baz { 999 }
	our $Bat = 69;
	sub _generate_wibble {
		my $class = shift;
		my ($name, $arg, $globals) = @_;
		return sub { $globals };
	}
};

like(
	exception q{ use My::Exporter qw(Baz) },
	qr/Could not find sub/,
	'sub that is not marked for export'
);

like(
	exception q{ use My::Exporter qw(Bam) },
	qr/Could not find sub/,
	'sub that cannot be found'
);

like(
	exception q{ use My::Exporter qw($Bat) },
	qr/Could not find sub/,  # this error should probably be changed
	'non-code symbol that is not marked for export'
);

use My::Exporter -wobble => { butt => 88 }, qw(wibble);

is_deeply(
	wibble->{wobble},
	{ butt => 88 },
	'unknown tags get added to globals'
);