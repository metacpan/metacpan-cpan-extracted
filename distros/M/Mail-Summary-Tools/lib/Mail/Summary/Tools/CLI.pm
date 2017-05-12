#!/usr/bin/perl

package Mail::Summary::Tools::CLI;
use base qw/App::Cmd/;

use Class::Autouse (<<'#\'END_USE' =~ m!(\w+::[\w:]+)!g);
#\

use Mail::Summary::Tools::CLI::Context;
use Mail::Summary::Tools::CLI::Config;

#'END_USE

use strict;
use warnings;

use constant global_opt_spec => (
	[ "verbose|v!" => "Verbose output" ],
);

use constant plugin_search_path => __PACKAGE__;

sub _module_pluggable_options {
	return (
		only   => qr/CLI::\w+$/x, # no nested commands
		except => qr/CLI::(?:Context|Config|Command)$/,
	);
}

sub config {
	my $self = shift;
	$self->{config} ||= Mail::Summary::Tools::CLI::Config->new();
}

sub context {
	my $self = shift;
	$self->{context} ||= Mail::Summary::Tools::CLI::Context->new();
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::CLI - App::Cmd based mailing list summarization tool.

=head1 SYNOPSIS

	use Mail::Summary::Tools::CLI;

=head1 DESCRIPTION

=cut


