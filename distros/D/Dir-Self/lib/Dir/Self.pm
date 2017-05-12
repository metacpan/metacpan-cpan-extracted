package Dir::Self;

$VERSION = '0.11';

use 5.005;
use strict;

use File::Spec ();


sub __DIR__ () {
	my $level = shift || 0;
	my $file = (caller $level)[1];
	File::Spec->rel2abs(join '', (File::Spec->splitpath($file))[0, 1])
}

sub _const {
	my $value = shift;
	sub () { $value }
}

sub import {
	my $class = shift;
	my $caller = caller;

	@_ or @_ = '__DIR__';

	for my $item (@_) {
		if ($item eq '__DIR__') {
			no strict 'refs';
			*{$caller . '::__DIR__'} = \&__DIR__;
		} elsif ($item eq ':static') {
			no strict 'refs';
			*{$caller . '::__DIR__'} = _const &__DIR__(1);
		} else {
			require Carp;
			Carp::croak(qq{"$item" is not exported by the $class module});
		}
	}
}

1
__END__

=head1 NAME

Dir::Self - a __DIR__ constant for the directory your source file is in

=head1 SYNOPSIS

  use Dir::Self;
  
  use lib __DIR__ . "/lib";
  
  my $conffile = __DIR__ . "/config";

=head1 DESCRIPTION

Perl has two pseudo-constants describing the current location in your source
code, C<__FILE__> and C<__LINE__>. This module adds C<__DIR__>, which expands
to the directory your source file is in, as an absolute pathname.

This is useful if your code wants to access files in the same directory, like
helper modules or configuration data. This is a bit like L<FindBin> except
it's not limited to the main program, i.e. you can also use it in modules. And
it actually works.

As of version 0.10 each use of C<__DIR__> recomputes the directory name; this
ensures that files in different directories that share the same package name
get correct results. If you don't want this, C<use Dir::Self qw(:static)> will
create a true C<__DIR__> constant in your package that contains the directory
name at the point of C<use>.

=head1 AUTHOR

Lukas Mai E<lt>l.mai @web.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, 2008, 2013 by Lukas Mai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
