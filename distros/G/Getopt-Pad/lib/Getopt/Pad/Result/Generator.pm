package Getopt::Pad::Result::Generator;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Object::Pad qw(:experimental(mop));
use Getopt::Pad::Result;

our $VERSION = '0.03';

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

Getopt::Pad::Result::Generator - runtime result class builder

=head1 DESCRIPTION

Builds one Object::Pad class per distinct reader set via Object::Pad::MOP::Class, with a :param :reader field for every declared option and arg. Classes are cached, so repeated parses and levels with identical readers share one class and long-running processes do not grow their symbol table.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
