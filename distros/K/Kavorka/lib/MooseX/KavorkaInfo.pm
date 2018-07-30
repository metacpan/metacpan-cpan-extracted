use 5.014;
use strict;
use warnings;

use Moose ();
use Kavorka ();
use Kavorka::Signature ();
use Sub::Util ();

{
	package MooseX::KavorkaInfo::DummyInfo;
	use Moose; with 'Kavorka::Sub';
}

{
	package MooseX::KavorkaInfo;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.039';
	
	sub import
	{
		my $meta = Class::MOP::class_of(scalar caller);
		Moose::Util::MetaRole::apply_metaroles(
			for             => $meta,
			role_metaroles  => {
				method          => ['MooseX::KavorkaInfo::Trait::Method'],
			},
			class_metaroles => {
				method          => ['MooseX::KavorkaInfo::Trait::Method'],
				wrapped_method  => ['MooseX::KavorkaInfo::Trait::WrappedMethod'],
			},
		);
	}
}

{
	package MooseX::KavorkaInfo::Trait::Method;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.039';
	
	use Moose::Role;
	
	has _info => (
		is        => 'ro',
		lazy      => 1,
		builder   => '_build_info',
		handles   => {
			declaration_keyword  => 'keyword',
			signature            => 'signature',
		},
	);
	
	sub _build_info
	{
		my $self = shift;
		Kavorka->info( $self->body )
		or MooseX::KavorkaInfo::DummyInfo->new(
			keyword         => 'sub',
			qualified_name  => Sub::Util::subname( $self->body ),
			body            => $self->body,
			signature       => 'Kavorka::Signature'->new(params => [], yadayada => 1),
		);
	}
}

{
	package MooseX::KavorkaInfo::Trait::WrappedMethod;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.039';
	
	use Moose::Role;
	with 'MooseX::KavorkaInfo::Trait::Method';
	
	around _build_info => sub
	{
		my $orig = shift;
		my $self = shift;
		Kavorka->info( $self->get_original_method->body )
		or MooseX::KavorkaInfo::DummyInfo->new(
			keyword         => 'sub',
			body            => $self->body,
			signature       => 'Kavorka::Signature'->new(params => [], yadayada => 1),
		);
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::KavorkaInfo - make Kavorka->info available through Moose meta objects

=head1 SYNOPSIS

   package Foo {
      use Moose;
      use MooseX::KavorkaInfo;
      use Kavorka qw( -default -modifiers );
      method xxx (Int $x) { return $x ** 3 }
   }
   
   package Foo::Verbose {
      use Moose;
      use MooseX::KavorkaInfo;
      use Kavorka qw( -default -modifiers );
      extends "Foo";
      before xxx { warn "Called xxx" }
   }
   
   my $method = Foo::Verbose->meta->get_method("xxx");
   say $method->signature->params->[1]->type->name;  # says "Int"

=head1 DESCRIPTION

MooseX::KavorkaInfo adds two extra methods to the Moose::Meta::Method
meta objects associated with a class.

It "sees through" method modifiers to inspect the original method
declaration.

=head2 Methods

=over

=item C<signature>

Returns a L<Kavorka::Signature> object.

=item C<declaration_keyword>

Returns a string indicating what keyword the method was declared with.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Kavorka>.

=head1 SEE ALSO

L<Kavorka::Manual::API>,
L<Moose::Meta::Method>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

