package File::VirusScan::Engine::Command::BitDefender::BDC;
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
	return [qw( --mail --arc)];
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

	if($exitcode == 0) {
		return File::VirusScan::Result->clean();
	}

	if($exitcode == 1) {
		my ($virus_name) = $scan_response =~ m/(?:suspected|infected)\: (\S+)/;

		if(!$virus_name) {
			$virus_name = 'unknown-bdc-virus';
		}
		return File::VirusScan::Result->virus($virus_name);
	}

	return File::VirusScan::Result->error("Unknown return code from bitdefender: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::BitDefender::BDC - File::VirusScan backend for scanning with Bitdefender BDC

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::BitDefender::BDC' => {
			command => '/path/to/bdc',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using the Bitdefender command-line scanner.

File::VirusScan::Engine::Command::BitDefender::BDC inherits from, and follows the
conventions of, File::VirusScan::Engine::Command.  See the documentation of
that module for more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item command

Fully-qualified path to the 'bdc' binary.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the command provided to the constructor.
Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<Cwd>, L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.bitdefender.com/>

=head1 AUTHOR

Dianne Skoll (dfs@roaringpenguin.com)

Dave O'Neill (dmo@roaringpenguin.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
