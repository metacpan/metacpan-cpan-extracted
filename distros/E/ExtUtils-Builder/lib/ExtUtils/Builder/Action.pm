package ExtUtils::Builder::Action;
$ExtUtils::Builder::Action::VERSION = '0.018';
use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless { %args }, $class;
}

sub preference {
	my ($self, @possibilities) = @_;
	my $map = $self->_preference_map;
	my @keys = @possibilities ? @possibilities : keys %{$map};
	my ($ret) = reverse sort { $map->{$a} <=> $map->{$b} } @keys;
	return $ret;
}

sub to_code_hash {
	my ($self, %opts) = @_;
	return {
		code => $self->to_code(%opts),
	}
}

1;

#ABSTRACT: The ExtUtils::Builder Action role

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Action - The ExtUtils::Builder Action role

=head1 VERSION

version 0.018

=head1 SYNOPSIS

 $_->execute for @actions;
 
 open my $script, '>', 'foo.sh';
 print $script shell_quote(@{$_}) for map { $_->to_command } @actions;

=head1 DESCRIPTION

Actions are the cornerstone of the ExtUtils::Builder framework. They provide an interface between build tools (L<ExtUtils::MakeMaker|ExtUtils::MakeMaker>, L<Module::Build|Module::Build>) and building extensions. This allows both sides to be completely independent from each other. It is a flexible abstraction around pieces of work, this work can be a piece of perl code, an external command, a mix of those or possibly other things.

=head1 OVERVIEW

An action can be consumed in many ways. It can be C<execute>d, which is often the simplest way to deal with them. It can be serialized to commands that can be passed on to system or strings that can be C<eval>led. If a consumer can deal with multiple of these, the C<preference> method can be used to choose between options. On L<composite|ExtUtils::Builder::Action::Composite> actions, C<flatten> can be called to retrieve the constituent actions, on L<primitive|ExtUtils::Builder::Action::Primitive> actions it's just an identity operator. This is particularly useful before calling preference, because different sub-actions are likely to have different preferences.

=head1 METHODS

=head2 execute(%arguments)

Execute this action immediately. This may throw an exception on errors, but doesn't otherwise return anything. C<%arguments> may be used by the command.

=over 4

=item * quiet

If true, this suppresses logging.

=back

=head2 to_command(%options)

Convert the action into a set of platform appropriate commands. It returns a list of array-refs, each array-ref being an individual command that can be passes to C<system> or equivalent. C<%options> can influence how something is serialized in action-type specific ways, but shouldn't fundamentally affect the action that is performed. All options are optional.

=over 4

=item perl

This contains the path to the current perl interpreter.

=item config

This should contain an ExtUtils::Config object, or equivalent.

=back

=head2 to_code(%options)

This returns a list of strings that can be evalled to sub-refs. C<%options> can influence how something is serialized in action-type specific ways, but shouldn't fundamentally affect the action that is performed.

=head2 to_code_hash(%options)

This returns a list of hashes that can be used to create L<Action::Code|ExtUtils::Builder::Action::Code> objects.

=head2 preference(@possibilities)

This action returns the favored out of C<@possibilities>. Valid values are C<execute>, C<code>, C<command>, C<flatten>. If no arguments are given, the favorite from all valid values is given.

=head2 flatten

This action returns all actions behind this action. It may return itself, it may return a long list of actions, it may even return an empty list.

=for Pod::Coverage new

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
