package File::VirusScan::Engine::Command::Kaspersky::AVP5;
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
	# TODO: should /var/run/aveserver be hardcoded?
	return [ qw( -s -p /var/run/aveserver ) ];
}

sub scan
{
	my ($self, $path) = @_;

	if(abs_path($path) ne $path) {
		return File::VirusScan::Result->error("Path $path is not absolute");
	}

	my ($exitcode, $scan_response) = eval { $self->_run_commandline_scanner(join(' ', $self->{command}, @{ $self->{args} }, $path, '2>&1'), 'INFECTED',); };

	if($@) {
		return File::VirusScan::Result->error($@);
	}

	if(        0 == $exitcode
		|| 5 == $exitcode
		|| 6 == $exitcode)
	{

		# 0 == clean
		# 5 == disinfected
		# 6 == viruses deleted
		return File::VirusScan::Result->clean();
	}

	if(1 == $exitcode) {

		# 1 == scan incomplete
		return File::VirusScan::Result->error('Scanning interrupted');
	}

	if(        2 == $exitcode
		|| 4 == $exitcode)
	{

		# 2 == "modified or damaged virus"
		# 4 == virus
		my ($virus_name) = $scan_response =~ m/INFECTED (\S+)/;
		$virus_name ||= 'unknown-AVP5-virus';
		return File::VirusScan::Result->virus($virus_name);
	}

	if(        3 == $exitcode
		|| 8 == $exitcode)
	{

		# 3 == "suspicious" object found
		# 8 == corrupt objects found (treat as suspicious
		return File::VirusScan::Result->virus('AVP5-suspicious');
	}

	if(7 == $exitcode) {

		# 7 == AVPLinux corrupt or infected
		return File::VirusScan::Result->error('AVPLinux corrupt or infected');
	}

	return File::VirusScan::Result->error("Unknown return code from aveclient: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::Kaspersky::AVP5 - File::VirusScan backend for scanning with aveclient

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::Kaspersky::AVP5' => {
			command => '/path/to/aveclient',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using Kaspersky's aveclient command-line scanner.

This class inherits from, and follows the conventions of,
File::VirusScan::Engine::Command.  See the documentation of that module for
more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item command

Fully-qualified path to the 'aveclient' binary.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the aveclient binary provided to the
constructor.  Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<Cwd>, L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.kaspersky.com/>

=head1 AUTHORS

Dianne Skoll (dfs@roaringpenguin.com)

Dave O'Neill (dmo@roaringpenguin.com)

Enrico Ansaloni

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
