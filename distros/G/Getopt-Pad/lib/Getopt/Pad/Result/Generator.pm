package Getopt::Pad::Result::Generator;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Object::Pad qw(:experimental(mop));
use Getopt::Pad::Result;

our $VERSION = '0.06';

my $classCounter = 0;
my %classForReaders;

sub generate($level) {
	my @readers  = sort map { $_->reader } $level->declaredOptions, $level->args;
	my $cacheKey = join("\0", @readers);
	return $classForReaders{$cacheKey} //= mintClass(@readers);
}

sub mintClass(@readers) {
	my $className = 'Getopt::Pad::Result::_' . ++$classCounter;
	my $meta      = Object::Pad::MOP::Class->create_class($className, isa => 'Getopt::Pad::Result');

	foreach my $reader (@readers) {
		$meta->add_field('$' . $reader, param => $reader, default => undef, reader => $reader);
	}

	$meta->seal;
	return $className;
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Result::Generator - Creates the classes of result objects
(internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

C<Getopt::Pad::Result::Generator::generate($level)> returns the name of
an L<Object::Pad> class for the result objects of C<$level>. The class
inherits from L<Getopt::Pad::Result> and has one C<:param :reader> field,
defaulting to C<undef>, per declared option and arg of the level. It is
built with L<Object::Pad::MOP::Class> and sealed.

Classes are cached by their set of readers, so repeated parses, and levels
with the same readers, share one class. A long-running process that
parses many command lines does not keep creating packages. The class
names (C<Getopt::Pad::Result::_1>, ...) are not meaningful.

=head1 SEE ALSO

L<Getopt::Pad::Result>, L<Getopt::Pad::Parser>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
