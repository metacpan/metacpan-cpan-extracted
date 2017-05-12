#!/usr/bin/perl

package Mail::Summary::Tools::Output::TT;
use Moose;

use Template;

has template_config => (
	isa => "HashRef",
	is  => "rw",
	default => sub { return {} },
);

has template_obj => (
	isa => "Template",
	is  => "rw",
	lazy => 1,
	default => sub { Template->new( $_[0]->template_config ) },
);

has template_output => (
	isa => "Any",
	is  => "rw",
	default => sub { \*STDOUT },
);

has template_input => (
	isa => "Any",
	is  => "rw",
	required => 1,
);

sub process {
	my ( $self, $summary, $vars, @args ) = @_;

	$self->template_obj->process(
		$self->template_input,
		{
			summary   => $summary,
			processor => $self,
			%{ $vars || {} },
		},
		$self->template_output,
	) || die $self->template_obj->error;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::Output::TT - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::Output::TT;

=head1 DESCRIPTION

=cut


