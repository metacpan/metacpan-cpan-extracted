package Form::Tiny::Inline;

use v5.10;
use warnings;
use Moo;
use Types::Standard qw(RoleName Str);

use namespace::clean;

our $VERSION = '1.13';

with "Form::Tiny";

sub is
{
	my ($class, @roles) = @_;

	my $loader = q{ my $n = "Form::Tiny::$_"; eval "require $n"; $n; };
	my $type = RoleName->plus_coercions(Str, $loader);
	@roles = map { $type->assert_coerce($_) } @roles;

	require Moo::Role;
	return Moo::Role->create_class_with_roles($class, @roles);
}

sub build_fields { }

1;

__END__

=head1 NAME

Form::Tiny::Inline - Form::Tiny without hassle

=head1 SYNOPSIS

	my $form = Form::Tiny::Inline->new(
		field_defs => [
			{name => "some_field"},
			...
		],
	);

=head1 DESCRIPTION

Inline forms are designed to cover all the base use cases, but they are not as customizable. Currently, they lack the ability to specify your own I<pre_mangle> and I<pre_validate> methods.

=head1 METHODS

=head2 is

When ran on a Form::Tiny::Inline class, it produces a new class that will have all the given roles mixed in. Given role names will be prepended with I<Form::Tiny::>

	$class_with_roles = Form::Tiny::Inline->is("Filtered", "Strict");
