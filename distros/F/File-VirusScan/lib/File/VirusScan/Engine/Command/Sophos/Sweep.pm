package File::VirusScan::Engine::Command::Sophos::Sweep;
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
	return [qw( -f -mime -all -archive -ss)];
}

sub scan
{
	my ($self, $path) = @_;

        my $abs = abs_path($path);
        if ($abs && $abs ne $path) {
                $path = $abs;
        }

	my ($exitcode, $scan_response) = eval { $self->_run_commandline_scanner(join(' ', $self->{command}, @{ $self->{args} }, $path, '2>&1'), qr/(?:>>> Virus)|(?:Password)|(?:Could not check)/,); };

	if($@) {
		return File::VirusScan::Result->error($@);
	}

	if(0 == $exitcode) {
		return File::VirusScan::Result->clean();
	}

	if(1 == $exitcode) {
		return File::VirusScan::Result->error('Virus scan interrupted');
	}

	if(2 == $exitcode) {

		# This is technically an error code, but Sophos chokes
		# on a lot of M$ docs with this code, so we let it
		# through...
		# TODO: Legacy commment from MIMEDefang. Figure this
		# out and see if this is sane behaviour.
		return File::VirusScan::Result->clean();
	}

	if(3 == $exitcode) {
		my ($virus_name) = $scan_response =~ m/\s*>>> Virus '(\S+)'/;
		$virus_name ||= 'unknown-Sweep-virus';
		return File::VirusScan::Result->virus($virus_name);
	}

	return File::VirusScan::Result->error("Unknown return code from sweep: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::Sophos::Sweep - File::VirusScan backend for scanning with Sophos Sweep

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::Sophos::Sweep' => {
			command => '/path/to/sweep',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using Sophos sweep command-line scanner.

This class inherits from, and follows the conventions of,
File::VirusScan::Engine::Command.  See the documentation of that module for
more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item command

Fully-qualified path to the 'sweep' binary.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the sweep binary provided to the
constructor.  Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<Cwd>, L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.sophos.com>

=head1 AUTHOR

Dianne Skoll (dianne@skoll.ca)

Dave O'Neill (dmo@roaringpenguin.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
