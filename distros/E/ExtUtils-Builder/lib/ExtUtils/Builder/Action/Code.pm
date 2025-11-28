package ExtUtils::Builder::Action::Code;
$ExtUtils::Builder::Action::Code::VERSION = '0.018';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Action::Perl';

use Carp ();
use ExtUtils::Builder::Util 'get_perl';

sub new {
	my ($class, %args) = @_;
	Carp::croak('Need to define code') if !$args{code};
	$args{modules} //= [];
	my $self = $class->SUPER::new(%args);
	return $self;
}

sub modules {
	my $self = shift;
	return @{ $self->{modules} };
}

sub execute {
	my ($self, %opts) = @_;
	my $code = $self->to_code();
	if (!$opts{quiet}) {
		my $message = $self->{message} // $code;
		print "$message\n";
	}
	eval $code . '; 1' or die $@;
	return;
}

sub to_code {
	my ($self, %opts) = @_;
	my @modules = $opts{skip_loading} ? () : map { "require $_" } $self->modules;
	return join '; ', @modules, $self->{code};
}

sub to_command {
	my ($self, %opts) = @_;
	my @modules = map { "-M$_" } $self->modules;
	my $perl = $opts{perl} // get_perl(%opts);
	return [ $perl, @modules, '-e', $self->to_code(skip_loading => 'main') ];
}

1;

#ABSTRACT: Action objects for perl code

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Action::Code - Action objects for perl code

=head1 VERSION

version 0.018

=head1 SYNOPSIS

 my $action = ExtUtils::Builder::Action::Code->new(
     code      => 'Frob::nicate(@_)',
     modules   => ['Frob'],
     message   => 'frobnicateing foo',
 );
 $action->execute(target => 'bar');
 say "Executed: ", join ' ', @$_, target => 'bar' for $action->to_command;

=head1 DESCRIPTION

This is a primitive action object wrapping a piece of perl code. The easiest way to use it is to execute it immediately. For more information on using actions, see L<ExtUtils::Builder::Action|ExtUtils::Builder::Action>. The core attributes are code and serialized, though only one of them must be given, both is strongly recommended.

=head1 ATTRIBUTES

=head2 code

This is a code-ref containing the action. On execution, it is passed the arguments of the execute method; when run as command it is passed @ARGV. In either case, C<arguments> is also passed. Of not given, it is C<eval>ed from C<serialized>.

=head2 modules

This is an optional list of modules that will be dynamically loaded before the action is run in any way. This attribute is optional.

=for Pod::Coverage new
to_code
modules

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
