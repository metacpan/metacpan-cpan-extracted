package App::Horris::CLI::Command::run;
# ABSTRACT: Horris runner


use Moose;
use Horris;
use namespace::autoclean;
extends 'MooseX::App::Cmd::Command';
with qw/MooseX::SimpleConfig/;

has '+configfile' => (
	default => '/etc/horris.conf'
);

has config => (
	traits => ['NoGetopt'], 
	is => 'ro', 
	isa => 'HashRef', 
);

around _usage_format => sub {
	return "usage: %c %o (run 'perldoc " . __PACKAGE__ . "' for more info)";
};

sub config_any_args {
	return {
		driver_args => {
			General => {
				-LowerCaseNames => 1, 
			}
		}
	};
}

sub execute {
    my ( $self, $opt, $args ) = @_;
	my $horris = Horris->new(config => $self->config);
	$horris->run;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

App::Horris::CLI::Command::run - Horris runner

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    horris run --configfile /path/to/botname.conf

=head1 OPTIONS

=head2 configfile

The location to find the config file. The default path is /etc/horris.conf

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

