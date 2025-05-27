package Meow;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Meow', $VERSION);

1;

__END__

=head1 NAME

Meow - Object ฅ^•ﻌ•^ฅ Orientation 

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

This module is experimental. Many basic features do not yet exist.

	package Cat;

	use Meow;
	use Basic::Types::XS qw/Str Num/;

	rw name => Str;

	rw age => Num;

	1;

...

	my $cat = Cat->new(
		name => 'Simba',
		age => 10
	);

	$cat->name; # Simba;
	$cat->age; # 10;
	
	$cat->age(11);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-meow at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Meow>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Meow

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Meow>

=item * Search CPAN

L<https://metacpan.org/release/Meow>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Meow
