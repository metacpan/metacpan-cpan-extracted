package ExtUtils::Builder::Action::Function;
$ExtUtils::Builder::Action::Function::VERSION = '0.017';
use strict;
use warnings;

use Carp 'croak';
use ExtUtils::Builder::Util 'get_perl';

use parent 'ExtUtils::Builder::Action::Perl';

sub new {
	my ($class, %args) = @_;
	croak 'Attribute module is not defined' if not defined $args{module};
	croak 'Attribute function is not defined' if not defined $args{function};
	$args{fullname} = join '::', $args{module}, $args{function};
	$args{exports} ||= !!0;
	$args{arguments} //= [];
	my $self = $class->SUPER::new(%args);
	return $self;
}

sub modules {
	my ($self) = @_;
	return $self->{module};
}

sub module {
	my ($self) = @_;
	return $self->{module};
}

sub function {
	my ($self) = @_;
	return $self->{function};
}

sub arguments {
	my ($self) = @_;
	return @{ $self->{arguments} };
}

sub execute {
	my ($self, %args) = @_;
	my $module = $self->{module};
	(my $filename = $module) =~ s{::}{/}g;
	require "$filename.pm";

	if (!$args{quiet}) {
		my $message = $self->{message} // sprintf "%s(%s)", $self->{fullname}, join ", ", $self->arguments;
		print "$message\n";
	}

	my $code = do { no strict 'refs'; \&{ $self->{fullname} } };
	$code->($self->arguments);
}

sub to_code {
	my ($self, %args) = @_;
	my $shortcut = $args{skip_loading} && $args{skip_loading} eq 'main' && $self->{exports};
	my $name = $shortcut ? $self->{function} : $self->{fullname};
	my @modules = $args{skip_loading} ? () : "require $self->{module}";
	my $arguments = $self->arguments ? do {
		require Data::Dumper; (Data::Dumper->new([ [ $self->arguments ] ])->Terse(1)->Indent(0)->Dump =~ /^ \[ (.*) \] $/x)[0]
	} : '';
	return join '; ', @modules, sprintf '%s(%s)', $name, $arguments;
}

sub to_command {
	my ($self, %opts) = @_;
	my $module = $self->{exports} eq 'explicit' ? "-M$self->{module}=$self->{function}" : "-M$self->{module}";
	my $perl = $opts{perl} // get_perl(%opts);
	return [ $perl, $module, '-e', $self->to_code(skip_loading => 'main') ];
}

1;

#ABSTRACT: Actions for perl function calls

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Action::Function - Actions for perl function calls

=head1 VERSION

version 0.017

=head1 SYNOPSIS

 my $action = ExtUtils::Builder::Action::Function->new(
     module    => 'Frob',
     function  => 'nicate',
     arguments => [ target => 'bar' ],
 );
 $action->execute();
 say "Executed: ", join ' ', @$_, target => 'bar' for $action->to_command;

=head1 DESCRIPTION

This Action class is a specialization of L<Action::Perl|ExtUtils::Builder::Action::Perl> that makes the common case of calling a simple function easier. The first statement in the synopsis is roughly equivalent to:

 my $action = ExtUtils::Builder::Action::Code->new(
     code       => 'Frob::nicate(target => 'bar')',
     module     => ['Frob'],
     message    => 'Calling Frob::nicate',
 );

Except that it serializes more cleanly.

=head1 ATTRIBUTES

=head2 arguments

These are additional arguments to the action, that are passed on regardless of how the action is run. This attribute is optional.

=head2 module

The module to be loaded.

=head2 function

The name of the function to be called.

=head2 exports 

If C<"always">, the function is assumed to be exported by the module. If C<"explicit">, it's assumed to need explicit exporting (e.g. C<use Module 'function';>).

=for Pod::Coverage to_code

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
