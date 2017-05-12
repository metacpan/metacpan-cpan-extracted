#!/usr/bin/perl

package Mail::Summary::Tools::CLI::Command;
use base qw/App::Cmd::Command/;

use strict;
use warnings;

sub opt_spec {
	my ( $self, $app ) = @_;

	my @options = $self->options;

	foreach my $option ( @options ) {
		my $opts = $option->[2] ||= {};
		my ($name) = ($option->[0] =~ /^(\w+)/);
		if ( defined( my $default = $self->option_config( $app, $name ) ) ) {
			$opts->{default} = $default; # clobber the default one with the user's value
		}
	}

	unshift @options, $self->extra_options;

	return @options;
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;
	print $self->_usage_text and exit if $opt->{help};
	$self->validate( $opt, $args );
}

sub extra_options {
	my ( $self, $app ) = @_;
    [ help => 'This help screen' ];
}

sub option_config {
	my ( $self, $app, $option ) = @_;
	my ( $cmd ) = $self->command_names;
	( $app->config || $app->app->config )->option_value( $cmd => $option );
}

sub diag {
	my ( $self, @message ) = @_;
	return unless $self->app->global_options->{verbose};
	my $message = "@message";
	chomp $message;
	warn "$message\n";
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::CLI::Command - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::CLI::Command;

=head1 DESCRIPTION

=cut


