package Gruntmaster::App::Command::Rerun;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use Gruntmaster::App '-command';
use Gruntmaster::Data;
use Scalar::Util qw/looks_like_number/;

sub usage_desc { '%c rerun id...' }

sub validate_args {
	my ($self, $opt, $args) = @_;
	my @args = @$args;
	$self->usage_error('Not enough arguments') if @args < 1;
}

sub execute {
	my ($self, $opt, $args) = @_;
	my @args = @$args;

	for my $obj (@args) {
		if (looks_like_number $obj) {
			rerun_job $obj;
		}
		else {
			rerun_problem $obj;
		}
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command::Rerun - rerun some jobs and probles

=head1 SYNOPSIS

  gm rerun 123 124

  gm rerun aplusb aminusb

  gm rerun 12 aplusb

=head1 DESCRIPTION

The rerun command takes some IDs of jobs and problems and reruns them.

=head1 SEE ALSO

L<gm>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
