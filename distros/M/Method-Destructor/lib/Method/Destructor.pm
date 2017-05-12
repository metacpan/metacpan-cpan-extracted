package Method::Destructor;

use 5.008_001;
use strict;

our $VERSION = '0.02';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=for stopwords destructor destructors

=head1 NAME

Method::Destructor - Cumulative destructors

=head1 VERSION

This document describes Method::Destructor version 0.02.

=head1 SYNOPSIS

	package Base;
	use Method::Destructor;

	sub DEMOLISH{
		# ...
	}

	package Derived;
	use parent -norequire => qw(Base);
	use Method::Destructor -optional;

	sub DEMOLISH{
		# ...
	}

	# ...

	my $x = Derived->new();
	# when $x is released,
	# Derived::DEMOLISH and Base::DEMOLISH will be called respecively.

=head1 DESCRIPTION

C<Method::Destructor> provides cumulative destructors, or B<DEMOLISH> methods,
which are introduced by I<Perl Best Practices> and implemented in modules
such as C<Class::Std> or C<Moose>. C<DEMOLISH> is a destructor like
C<DESTROY>, but acts as a cumulative method.

To use the cumulative destructors, say C<< use Method::Destructor >> and
replace C<DESTROY> with C<DEMOLISH>. You can also say
C<< use Method::Destructor -optional >> if the destructor does not touch
external resources. Optional destructors will not be called if objects
are released in global destruction.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<Class::Std>.

L<Moose>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji. Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
