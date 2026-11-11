package Gears::Role::HasContext;
$Gears::Role::HasContext::VERSION = '0.105';
use v5.40;
use Mooish::Base -standard, -role;

use Devel::StrictMode;

has param 'context' => (
	(STRICT ? (isa => InstanceOf ['Gears::Context']) : ()),
	weak_ref => 1,
);

__END__

=head1 NAME

Gears::Role::HasContext - A role for classes needing context backreference

=head1 SYNOPSIS

	# first ...
	package My::Class;

	use Mooish::Base;
	with qw(Gears::role::HasContext);

	# then...
	My::Class->new(context => $context);

=head1 DESCRIPTION

This package is a simple role for classes that need a weak reference to
L<Gears::Context>. This is designed to be used for classes like requests and
responses, which context subclass should hold.

=head1 ADDED INTERFACE

=head2 Attributes

=head3 context

A weak reference to an object of L<Gears::Context> class or subclass.

I<Required in constructor>

