package File::VirusScan::Engine::Command::FPROT::FPROT;
use strict;
use warnings;
use Carp;

use File::VirusScan::Engine::Command;
use vars qw( @ISA );
@ISA = qw( File::VirusScan::Engine::Command );

use Cwd 'abs_path';

use File::VirusScan::Result;

sub default_arguments
{
	return [ qw( -DUMB -ARCHIVE -PACKED ) ];
}

sub scan
{
	my ($self, $path) = @_;

	if(abs_path($path) ne $path) {
		return File::VirusScan::Result->error("Path $path is not absolute");
	}

	my ($exitcode, $scan_response) = eval { $self->_run_commandline_scanner(join(' ', $self->{command}, @{ $self->{args} }, $path, '2>&1')); };

	if($@) {
		return File::VirusScan::Result->error($@);
	}

	if(0 == $exitcode) {
		return File::VirusScan::Result->clean();
	}

	if(1 == $exitcode) {
		return File::VirusScan::Result->error('Unrecoverable error');
	}

	if(2 == $exitcode) {
		return File::VirusScan::Result->error('Driver integrity check failed');
	}

	if(3 == $exitcode) {
		my ($virus_name) = $scan_response =~ m/Infection\: (\S+)/;
		$virus_name ||= 'unknown-FPROT-virus';
		return File::VirusScan::Result->virus($virus_name);
	}

	if(5 == $exitcode) {
		return File::VirusScan::Result->error('Abnormal scanner termination');
	}

	if(7 == $exitcode) {
		return File::VirusScan::Result->error('Memory error');
	}

	if(8 == $exitcode) {
		return File::VirusScan::Result->virus('FPROT-suspicious');
	}

	return File::VirusScan::Result->error("Unknown return code: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::FPROT::FPROT - File::VirusScan backend for scanning with fprot

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::FPROT::FPROT' => {
			command => '/path/to/fprot',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using F-PROT's commandline scanner

This class inherits from, and follows the conventions of,
File::VirusScan::Engine::Command.  See the documentation of that module for
more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item command

Required.

Path to scanner executable.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the configured command.

Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<Cwd>, L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.f-prot.com/>

=head1 AUTHOR

Dianne Skoll (dfs@roaringpenguin.com)

Dave O'Neill (dmo@roaringpenguin.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
