package ExtUtils::Builder::Action::Command;
$ExtUtils::Builder::Action::Command::VERSION = '0.012';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Action::Primitive';

sub _preference_map {
	return {
		command => 3,
		execute => 2,
		code    => 1,
		flatten => 0,
	};
}

sub to_code {
	my ($self, %args) = @_;
	require Data::Dumper;
	if (ref $self->{command}) {
		my $serialized = Data::Dumper->new([$self->{command}])->Terse(1)->Indent(0)->Dump;
		$serialized =~ s/ \A \[ (.*?) \] \z /$1/xms;
		return qq{system($serialized) and die "Could not run command " . join ' ', $serialized};
	} else {
		my $serialized = Data::Dumper->new([$self->{command}])->Terse(1)->Indent(0)->Dump;
		return qq{system($serialized) and die "Could not run command $serialized"};
	}
}

sub to_command {
	my $self = shift;
	return ref $self->{command} ? [ @{ $self->{command} } ] : $self->{command};
}

my $quote = $^O eq 'MSWin32' ? do { require Win32::ShellQuote; \&Win32::ShellQuote::quote_system_list } : sub { @_ };
sub execute {
	my ($self, %opts) = @_;
	if (ref $self->{command}) {
		my @command = @{ $self->{command} };
		my $message = join ' ', map { my $arg = $_; $arg =~ s/ (?= ['#] ) /\\/gx ? "'$arg'" : $arg } @command;
		print "$message\n" if not $opts{quiet};
		system($quote->(@command)) and die "Could not run command @command" if not $opts{dry_run};
	} else {
		my $command = $self->{command};
		print "$command\n" if not $opts{quiet};
		system($command) and die "Could not run command $command" if not $opts{dry_run};
	}
	return;
}

1;

#ABSTRACT: An action object for external commands

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Action::Command - An action object for external commands

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 my @cmd = qw/echo Hello World!/;
 my $action = ExtUtils::Builder::Action::Command->new(command => \@cmd);
 $action->execute;
 say "Executed: ", join ' ', @{$_} for $action->to_command;

=head1 DESCRIPTION

This is a primitive action object wrapping an external command. The easiest way to use it is to serialize it to command, though it doesn't mind being executed right away. For more information on actions, see L<ExtUtils::Builder::Action|ExtUtils::Builder::Action>.

=head1 ATTRIBUTES

=head2 command

This is the command that should be run, represented as an array ref.

=for Pod::Coverage execute
to_command
to_code
preference
flatten

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
