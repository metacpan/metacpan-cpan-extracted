package File::VirusScan::Engine::Command::Authentium::CommandAntivirus;
use strict;
use warnings;
use Carp;

use File::VirusScan::Engine::Command;
use vars qw( @ISA );
@ISA = qw( File::VirusScan::Engine::Command );

use IO::Socket::UNIX;
use IO::Select;
use Cwd 'abs_path';

use File::VirusScan::Result;

sub scan
{
	my ($self, $path) = @_;

        my $abs = abs_path($path);
        if ($abs && $abs ne $path) {
                $path = $abs;
        }

	my ($exitcode, $scan_response) = eval { $self->_run_commandline_scanner(join(' ', $self->{command}, @{ $self->{args} }, $path, '2>&1')); };

	if($@) {
		return File::VirusScan::Result->error($@);
	}

	if(50 == $exitcode) {
		return File::VirusScan::Result->clean();
	}

	if(5 == $exitcode) {
		return File::VirusScan::Result->error('Scan interrupted');
	}

	if(101 == $exitcode) {
		return File::VirusScan::Result->error('Out of memory');
	}

	if(52 == $exitcode) {

		# 52 == "suspicious" files
		return File::VirusScan::Result->virus('suspicious-CSAV-files');
	}

	if(53 == $exitcode) {

		# Found and disinfected
		return File::VirusScan::Result->virus('unknown-CSAV-virus disinfected');
	}

	if(51 == $exitcode) {
		my ($virus_name) = $scan_response =~ m/infec.*\: (\S+)/i;
		if(!$virus_name) {
			$virus_name = 'unknown-CSAV-virus';
		}
		return File::VirusScan::Result->virus($virus_name);
	}

	# Other codes, bail out.
	return File::VirusScan::Result->error("Unknown return code from Command Antivirus: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::Authentium::CommandAntivirus - File::VirusScan backend for scanning with Authentium's Command Antivirus

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::Authentium::CommandAntivirus' => {
			command => '/path/to/scan/command',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using Authentium's Command Antivirus command-line scanner.

File::VirusScan::Engine::Command::Authentium::CommandAntivirus inherits from, and follows the
conventions of, File::VirusScan::Engine.  See the documentation of
that module for more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item command

Fully-qualified path to the scan command.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the command provided to the constructor.
Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<IO::Socket::UNIX>, L<IO::Select>, L<Scalar::Util>, L<Cwd>,
L<File::VirusScan::Result>,

=head1 AUTHOR

Dave O'Neill (dmo@roaringpenguin.com)

Dianne Skoll (dianne@skoll.ca)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
