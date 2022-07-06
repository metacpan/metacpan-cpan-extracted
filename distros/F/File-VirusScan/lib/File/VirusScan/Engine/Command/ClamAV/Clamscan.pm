package File::VirusScan::Engine::Command::ClamAV::Clamscan;
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
	return [qw(--stdout --no-summary --infected)];
}

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

	if(0 == $exitcode) {
		return File::VirusScan::Result->clean();
	}

	if(1 == $exitcode) {

		# TODO: what if more than one virus found?
		# TODO: can/should we capture infected filenames?
		if($scan_response =~ m/: (.+) FOUND/) {
			return File::VirusScan::Result->virus($1);
		} elsif($scan_response =~ m/: (.+) ERROR/) {
			my $err_detail = $1;
			return File::VirusScan::Result->error("clamscan error: $err_detail");
		}
	}

	return File::VirusScan::Result->error("Unknown return code from clamscan: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::ClamAV::Clamscan - File::VirusScan backend for scanning with clamscan

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::ClamAV::Clamscan' => {
			command => '/path/to/clamscan',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using ClamAV's clamscan command-line scanner.

This class inherits from, and follows the conventions of,
File::VirusScan::Engine::Command.  See the documentation of that module for
more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item command

Fully-qualified path to the 'clamscan' binary.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the clamscan binary provided to the
constructor.  Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<Cwd>, L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.clamav.net/>

=head1 AUTHOR

Dianne Skoll (dianne@skoll.ca)
Dave O'Neill (dmo@roaringpenguin.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
