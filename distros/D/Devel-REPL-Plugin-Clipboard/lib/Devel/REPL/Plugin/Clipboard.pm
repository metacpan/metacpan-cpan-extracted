package Devel::REPL::Plugin::Clipboard;

# ABSTRACT: #clip output to clipboard

use Devel::REPL::Plugin;
use namespace::autoclean;
use Clipboard;
use Term::ANSIColor 2.01 qw(colorstrip);


sub BEFORE_PLUGIN {
	my $self = shift;
	$self->load_plugin('Turtles');
	return;
}

has last_output => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	default => '',
);

around 'format_result' => sub {
	my $orig = shift;
	my $self = shift;

	my @ret;
	if (wantarray) {
		@ret = $self->$orig(@_);
	}
	else {
		$ret[0] = $self->$orig(@_);
	}

	# Remove any color control characters that plugins like
	# Data::Printer may have added
	my $output = colorstrip( join( "\n", map { $_ // '' } @ret ) );

	$self->last_output($output);

	return wantarray ? @ret : $ret[0];
};

sub command_clip {
	my ($self) = @_;
	Clipboard->copy( $self->last_output );
	return 'Output copied to clipboard';
}

1;

__END__

=pod

=head1 NAME

Devel::REPL::Plugin::Clipboard - #clip output to clipboard

=head1 VERSION

version 0.004

=head1 COMMANDS

This module provides the following command to your Devel::REPL shell:

=head2 #clip

The C<#clip> puts the output of the last command on your clipboard.

=head1 AUTHOR

Steve Nolte <mcsnolte@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steve Nolte.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
