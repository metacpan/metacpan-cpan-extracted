package Exception::Class::Nested;
use strict;
use warnings;
no warnings qw(uninitialized);
use Carp;
use Exception::Class;
our @ISA = qw(Exception::Class);

our $VERSION = '0.01';

sub import {
	my $class = shift;

	my @classes;
	my %functions;
	while (1) {
		my ($name, $opt) = (shift(), shift());
		last if !defined($name);

#print "Root processing ($name, $opt)\n";

		unless (ref($opt) eq 'HASH') {
			unshift(@_,$opt);
			$opt = {};
		}
		push @classes, _process_class($name, $opt, undef, \%functions);
	}

	Exception::Class->import(@classes);

	{
		no strict 'refs';
		while (my ($name, $code) = each %functions) {
			*{$name} = $code;
#print "Defined \&$name\n";
		}
	}
}

sub _process_class {
	my ($name, $opt, $parent, $functions) = @_;
#print "Processing ($name, $opt)\n";
	my @classes;
	$opt->{isa} = $parent if defined($parent);

	while (my ($subname, $subopt) = each %$opt) {
		next unless ref($subopt);
		if (ref($subopt) eq 'HASH') {
#print "Found subclass $subname\n";
			push @classes, _process_class($subname, $subopt, $name, $functions);
			delete $opt->{$subname};
		} elsif (ref($subopt) eq 'CODE') {
#print "Later will define " . $name . '::' . $subname . "\n";
			$functions->{$name . '::' . $subname} = $subopt;
			delete $opt->{$subname};
		}
	}
	return ($name, $opt, @classes);
}

1;

=head1 NAME

Exception::Class::Nested - Nested declaration of Exception::Class classes

=head1 SYNOPSIS

	use Exception::Class::Nested (
		'MyException' => {
			description => 'This is mine!',

			'YetAnotherException' => {
				description => 'These exceptions are related to IPC',

				'ExceptionWithFields' => {
					fields => [ 'grandiosity', 'quixotic' ],
					alias => 'throw_fields',
					full_message => sub {
						my $self = shift;
						my $msg = $self->message;
						$msg .= " and grandiosity was " . $self->grandiosity;
						return $msg;
					}
				}
			}
		},
	);

=head1 DESCRIPTION

This is little more than a thin wrapper around the C<use Exception::Class> call. It allows you do nest the class
declarations instead of having to repeat the class names in the isa=> parameters. It also allows you to
define/overload methods in the classes.

=head1 SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Exception%3A%3AClass%3A%3ANested or
via email at bug-exception-class-nested@rt.cpan.org.

=head1 AUTHOR

Jenda Krynicky, <jenda@krynicky.cz>

=head1 COPYRIGHT

Copyright (c) 2008 Jenda Krynicky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut

