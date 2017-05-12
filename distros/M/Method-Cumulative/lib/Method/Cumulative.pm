package Method::Cumulative;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.05';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Sub::Attribute;
use XS::MagicExt;
use XS::MRO::Compat;

1;
__END__

=head1 NAME

Method::Cumulative - Accumulates the effect of methods in a class hierarchy

=head1 VERSION

This document describes Method::Cumulative version 0.05.

=head1 SYNOPSIS

	package A;
	use parent qw(Method::Cumulative);
	sub foo{
		print "A";
	}
	sub bar{
		print "A";
	}

	package B;
	use parent -norequire => qw(A);
	sub foo :CUMULATIVE{
		print "B";
	}
	sub bar :CUMULATIVE(BASE FIRST){
		print "B";
	}

	package C;
	use parent -norequire => qw(A);
	sub foo :CUMULATIVE{
		print "C";
	}
	sub bar :CUMULATIVE(BASE FIRST){
		print "C";
	}

	package D;
	use parent -norequire => qw(C B);
	use mro 'c3';
	sub foo :CUMULATIVE{
		print "D";
	}
	sub bar :CUMULATIVE(BASE FIRST){
		print "D";
	}

	D->foo(); # => DCBA
	D->bar(); # => ABCD

=head1 DESCRIPTION

Method::Cumulative provides an attribute that makes methods cumulative.

Cumulative methods are methods which accumulate the effect of the methods in a
class hierarchy. 

=head1 INTERFACE

=head2 The C<CUMULATIVE> subroutine attribute

Makes methods cumulative.

	# derived-first order (like destructors)
	sub foo :CUMULATIVE{
		# ...
	}

	# base-first order (like constructors)
	sub bar :CUMULATIVE(BASE FIRST){
		# ...
	}

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C Compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<Class::Std>.

L<Sub::Attribute>.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
