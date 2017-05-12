package File::VirusScan::Engine::Command::FPROT::Fpscan;
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
	return [ qw( --report --archive=5  --scanlevel=4 --heurlevel=3 ) ];
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

	# bit 1 (1)   ==> At least one virus-infected object was found (and
	#                 remains).
	if( $exitcode & 0b1 ){
		my ($virus_name) = $scan_response =~  m/^\[Found\s+[^\]]*\]\s+<([^ \t\(>]*)/m;
		$virus_name ||= 'unknown-FPSCAN-virus';
		return File::VirusScan::Result->virus($virus_name);
	}

	# bit 2 (2)   ==> At least one suspicious (heuristic match) object
	#                 was found (and remains).
	if ($exitcode & 0b10) {
		return File::VirusScan::Result->virus('FPSCAN-suspicious');
	}

	# bit 3 (4)   ==> Interrupted by user (SIGINT, SIGBREAK).
	if ($exitcode & 0b100) {
		return File::VirusScan::Result->error('Interrupted by user');
	}

	# bit 4 (8)   ==> Scan restriction caused scan to skip files
	#                 (maxdepth directories, maxdepth archives,
	#                 exclusion list, etc).

	if ($exitcode & 0b1000) {
		return File::VirusScan::Result->error('Scanning restrictions triggered abort due to skipped files');
	}

	# bit 5 (16)  ==> Platform error (out of memory, real I/O errors,
	#                 insufficient file permission etc.)

	if ($exitcode & 0b10000) {
		return File::VirusScan::Result->error('Platform error (out of memory, I/O errors, etc)');
	}

	# bit 6 (32)  ==> Internal engine error (whatever the engine fails
	#                 at)
	if ($exitcode & 0b100000) {
		return File::VirusScan::Result->error('Internal virus engine error');
	}

	# bit 7 (64)  ==> At least one object was not scanned (encrypted
	#                 file, unsupported/unknown compression method,
	#                 corrupted or invalid file).
	if ($exitcode & 0b1000000) {
		return File::VirusScan::Result->error('At least one object not scannable');
	}

	# bit 8 (128) ==> At least one object was disinfected (clean now).
	# Should not happen as we aren't requesting disinfection ( at least
	# in this version).
	if ($exitcode & 0b10000000) {
		return File::VirusScan::Result->virus('Scanner claims to have cleaned a virus, but cannot in this mode');
	}

	return File::VirusScan::Result->error("Unknown return code: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::FPROT::Fpscan - File::VirusScan backend for scanning with fpscan

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::FPROT::Fpscan' => {
			command => '/path/to/fpscan',
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
