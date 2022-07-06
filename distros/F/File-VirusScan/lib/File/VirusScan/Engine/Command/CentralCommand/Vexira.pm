package File::VirusScan::Engine::Command::CentralCommand::Vexira;
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
	return [qw(-qqq --log=/dev/null --all-files -as)];
}

sub scan
{
	my ($self, $path) = @_;

        my $abs = abs_path($path);
        if ($abs && $abs ne $path) {
                $path = $abs;
        }

	my ($exitcode, $scan_response) = eval { $self->_run_commandline_scanner(join(' ', $self->{command}, @{ $self->{args} }, $path, '2>&1'), qr/: (?:virus|iworm|macro|mutant|sequence|trojan) /,); };

	if($@) {
		return File::VirusScan::Result->error($@);
	}

	if(        0 == $exitcode
		|| 9 == $exitcode)
	{

		# 0 == OK
		# 9 == Unknown file type (treated as "ok" for now)
		return File::VirusScan::Result->clean();
	}

	if(        3 == $exitcode
		|| 5 == $exitcode)
	{
		return File::VirusScan::Result->virus('vexira-password-protected-zip');
	}

	if(        1 == $exitcode
		|| 2 == $exitcode)
	{
		my ($virus_name) = $scan_response =~ m/: (?:virus|iworm|macro|mutant|sequence|trojan) (\S+)/;
		$virus_name ||= 'unknown-Vexira-virus';
		return File::VirusScan::Result->virus($virus_name);
	}

	return File::VirusScan::Result->error("Unknown return code from vexira: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::CentralCommand::Vexira - File::VirusScan backend for scanning with vexira

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::CentralCommand::Vexira' => {
			command => '/path/to/vexira',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using Central Command's Vexira command-line scanner.

File::VirusScan::Engine::Command::CentralCommand::Vexira inherits from, and follows the
conventions of, File::VirusScan::Engine::Command.  See the documentation of
that module for more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item command

Fully-qualified path to the 'vexira' binary.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the vexira binary provided to the
constructor.  Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<Cwd>, L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.centralcommand.com/ts/dl/pdf/scanner_en_vexira.pdf>

=head1 AUTHOR

Dianne Skoll (dianne@skoll.ca)

Dave O'Neill (dmo@roaringpenguin.com)

John Rowan Littell

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
