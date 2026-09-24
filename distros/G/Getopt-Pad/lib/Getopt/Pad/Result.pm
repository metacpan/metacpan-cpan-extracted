use v5.26;
use Object::Pad qw(:experimental(mop));

class Getopt::Pad::Result {
	use Carp qw(croak);

	our $VERSION = '0.02';

	# Names Perl looks up on an object by itself; a Reader by one of these
	# would run at the wrong time with the wrong arguments.
	my %isPerlHook = map { $_ => 1 } qw(DESTROY AUTOLOAD);

	field $command    :param :reader = undef;
	field $subcommand :param :reader = undef;
	field $helper     :param         = undef;

	# Whether a Reader named $name would clash with what every Result
	# already answers to: a method (including the ones Object::Pad and
	# UNIVERSAL provide), a constructor param, or a Perl hook. Derived from
	# the class itself, so nothing here can drift from it.
	method reservesReader :common ($name) {
		return 1 if $isPerlHook{$name};
		return 1 if $class->can($name);
		my @params = map { $_->get_attribute_value('param') } grep { $_->has_attribute('param') } Object::Pad::MOP::Class->for_class($class)->fields;
		return (grep { $_ eq $name } @params) ? 1 : 0;
	}

	method help() {
		croak 'Getopt::Pad: no help renderer attached to this result' unless defined $helper;
		$helper->printHelp;
		exit 0;
	}

	method version() {
		croak 'Getopt::Pad: no help renderer attached to this result' unless defined $helper;
		$helper->printVersion;
		exit 0;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Result - result object base class

=head1 DESCRIPTION

Base class of all generated result objects: the command/subcommand readers and the help/version methods. It also decides which reader names are free: the class method reservesReader($name) answers whether a reader would clash with a method every result has (including what Object::Pad and UNIVERSAL provide), with one of the base class constructor params, or with a name Perl calls on its own (DESTROY, AUTOLOAD). Option and arg specs ask it instead of keeping a copy of the list.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
