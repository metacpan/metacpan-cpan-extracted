package KelpX::Hooks;
$KelpX::Hooks::VERSION = '1.03';
use v5.10;
use strict;
use warnings;

use Exporter qw(import);
use Carp qw(croak);
use List::Util qw(any);

our @EXPORT = qw(
	hook
);

my %hooks;
my %hooked;

sub apply_hook
{
	my ($package, $subname, $decorator) = @_;

	my $hooked_method = $package->can($subname);
	return !!0 unless $hooked_method;

	{
		no strict 'refs';
		no warnings 'redefine';

		*{"${package}::$subname"} = sub {
			unshift @_, $hooked_method;
			goto $decorator;
		};
	}

	return !!1;
}

sub install_hooks
{
	my ($package) = @_;

	return if $hooked{$package}++;

	my $build_decorator = sub {
		my $orig = shift;
		my @late;

		foreach my $hook (@{$hooks{$package}}) {
			next if apply_hook($package, @{$hook});

			# not hooked - will try later
			push @late, $hook;
		}

		$orig->(@_);

		foreach my $hook (@late) {
			croak "Trying to hook $hook->[0], which doesn't exist"
				unless apply_hook($package, @{$hook});
		}
	};

	croak "Can't install hooks: no build() method in $package"
		unless apply_hook($package, 'build', $build_decorator);
}

sub hook
{
	my ($subname, $decorator) = @_;
	my $package = caller;

	my @forbidden = qw(new build);

	croak "Hooking $subname() method is forbidden"
		if any { $_ eq $subname } @forbidden;

	install_hooks($package);

	push @{$hooks{$package}}, [$subname, $decorator];

	return;
}

1;

__END__

=head1 NAME

KelpX::Hooks - Override any method in your Kelp application

=head1 SYNOPSIS

	# in your Kelp application
	use KelpX::Hooks;

	# and then...
	hook "template" => sub {
		return "No templates for you!";
	};

=head1 DESCRIPTION

This module allows you to override methods in your Kelp application class. The
provided L</hook> method can be compared to Moose's C<around>, and it mimics
its interface. The difference is in how and when the replacement of the actual
method occurs.

The problem here is that Kelp's modules are modifying the symbol table for the
module at the runtime, which makes common attempts to change their methods`
behavior futile. You can't override them, you can't change them with method
modifiers, you can only replace them with different methods.

This module fights the symbol table magic with more symbol table magic. It will
replace any method with your anonymous subroutine after the application is
built and all the modules have been loaded.

=head2 EXPORT

=head3 hook

	hook "sub_name" => sub {
		my ($original_sub, $self, @arguments) = @_;

		# your code, preferably do this at some point:
		return $self->$original_sub(@arguments);
	};

Allows you to provide your own subroutine in place of the one specified. The
first argument is the subroutine that's being replaced. It won't be run at all
unless you call it explicitly.

Please note that Kelp::Less is not supported.

=head1 CAVEATS

This module works by replacing the C<build> method in symbol tables. Because of
this, you cannot hook the build method itself or any method which is run before
it. The module will verbosely refuse to hook C<new> or C<build>.

Hooks will first try to apply B<before> the build is run. Any modules declared
in configuration will have their upgraded functions available inside C<build>.
Hooks which fail to apply before C<build> will try again after it finished, and
raise an exception if they fail again.

=head1 SEE ALSO

L<Kelp>, L<Moose::Manual::MethodModifiers>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 - 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

