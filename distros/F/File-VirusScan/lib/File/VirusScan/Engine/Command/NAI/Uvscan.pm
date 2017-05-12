package File::VirusScan::Engine::Command::NAI::Uvscan;
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
	return [ qw( --mime --noboot --secure --allole ) ];
}

sub scan
{
	my ($self, $path) = @_;

	if(abs_path($path) ne $path) {
		return File::VirusScan::Result->error("Path $path is not absolute");
	}

	my ($exitcode, $scan_response) = eval { $self->_run_commandline_scanner(join(' ', $self->{command}, @{ $self->{args} }, $path, '2>&1'), qr/Found/,); };

	if($@) {
		return File::VirusScan::Result->error($@);
	}

	if(0 == $exitcode) {
		return File::VirusScan::Result->clean();
	}

	if(2 == $exitcode) {
		return File::VirusScan::Result->error('Driver integrity check failed');
	}

	if(6 == $exitcode) {

		# "A general problem occurred" -- idiot Windoze
		# programmers... nothing else to do but pass it on
		return File::VirusScan::Result->error('General problem occurred');
	}

	if(8 == $exitcode) {
		return File::VirusScan::Result->error('Could not find a driver');
	}

	if(12 == $exitcode) {
		return File::VirusScan::Result->error('Scanner tried to clean file, but failed');
	}

	if(13 == $exitcode) {

		# Finally, the virus-hit case
		#
		# TODO: what if more than one virus found?
		# TODO: can/should we capture infected filenames?

		# Sigh... stupid NAI can't have a standard message.  Go
		# through hoops to get virus name.
		$scan_response =~ s/ !+//;
		$scan_response =~ s/!+//;

		my $virus_name = '';

		for ($scan_response) {
			m/Found: EICAR test file/i && do {
				$virus_name = 'EICAR-Test';
				last;
			};
			m/^\s+Found the (\S+) .*virus/i && do {
				$virus_name = $1;
				last;
			};
			m/Found the (.*) trojan/i && do {
				$virus_name = $1;
				last;
			};
			m/Found .* or variant (.*)/i && do {
				$virus_name = $1;
				last;
			};
		}

		if($virus_name eq '') {
			$virus_name = 'unknown-NAI-virus';
		}

		return File::VirusScan::Result->virus($virus_name);
	}

	if(19 == $exitcode) {
		return File::VirusScan::Result->error('Self-check failed');
	}

	if(102 == $exitcode) {
		return File::VirusScan::Result->error('User quit using --exit-on-error');
	}

	return File::VirusScan::Result->error("Unknown return code from uvscan: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::NAI::Uvscan - File::VirusScan backend for scanning with uvscan

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'Command::NAI::Uvscan' => {
			command => '/path/to/uvscan',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using NAI's uvscan command-line scanner.

File::VirusScan::Engine::Command::NAI::Uvscan inherits from, and follows the
conventions of, File::VirusScan::Engine::Command.  See the documentation of
that module for more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item command

Fully-qualified path to the 'uvscan' binary.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the command provided to the constructor.
Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<Cwd>, L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.nai.com/>

=head1 AUTHOR

Dianne Skoll (dfs@roaringpenguin.com)

Dave O'Neill (dmo@roaringpenguin.com)

uvscan exit code information provided by Anthony Giggins

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
