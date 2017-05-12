=pod

=encoding utf-8

=head1 PURPOSE

Tests we don't trigger an annoying weird Sub::Defer edge case.

=head1 AUTHOR

Toby Inkster.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use lib qw( lib t/lib );

use Test::More;
use Test::Requires { Moops => '0.033' };
use Test::Fatal;

use Moops -strict;

class Rectangle :ro {
	has height => (required => true);
	has width  => (required => true);
	
	around BUILDARGS {
		my $params = $self->$next(@_);
		$params->{height} //= $params->{width};
		$params->{width}  //= $params->{height};
		return $params;
	}
}

is( Rectangle->new(height => 12)->width, 12 );
is( Rectangle->new(width => 12)->height, 12 );

my $e = eval { require Local::Bad };

unlike($e, qr/^Eval went very, very wrong/);

done_testing();
