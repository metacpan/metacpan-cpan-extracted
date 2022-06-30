#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

=encoding utf8

=head1 NAME

get_filehandle.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/get_filehandle.t

	# run a single test
	% prove t/get_filehandle.t

=head1 AUTHORS

Original author: brian d foy C<< <bdfoy@cpan.org> >>

=head1 SOURCE

This file was originally in https://github.com/briandfoy/mac-propertylist

=head1 COPYRIGHT

Copyright © 2002-2022, brian d foy, C<< <bdfoy@cpan.org> >>

=head1 LICENSE

This file is licenses under the Artistic License 2.0. You should have
received a copy of this license with this distribution.

=cut

my $class = 'Mac::PropertyList::ReadBinary';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

can_ok( $class, qw(new _get_filehandle) );
use Scalar::Util qw(openhandle);

{
my $self = bless { source => 'Makefile.PL'  }, $class;
my $fh = $self->_get_filehandle;
ok( openhandle( $fh ), 'Got a defined filehandle' );
}

{
my $self = bless { source => 'not_there'  }, $class;
my $fh = eval { $self->_get_filehandle };
ok( ! openhandle( $fh ), q(Didn't get a defined filehandle) );
}


{
my $string    = '<xml>';
open my $string_fh, '<', \ $string;
my $self = bless { source => $string_fh  }, $class;
my $fh = $self->_get_filehandle;
ok( openhandle( $fh ), 'Got a defined filehandle' );
}


{
my $self = bless { source => \ '<xml>'   }, $class;
my $fh = $self->_get_filehandle;
ok( openhandle( $fh ), 'Got a defined filehandle' );
}

done_testing();
