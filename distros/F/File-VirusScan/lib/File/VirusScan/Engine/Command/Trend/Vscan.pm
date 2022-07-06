package File::VirusScan::Engine::Command::Trend::Vscan;
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
	return [qw(-za -a)];
}

sub scan
{
	my ($self, $path) = @_;

        my $abs = abs_path($path);
        if ($abs && $abs ne $path) {
                $path = $abs;
        }

	my ($exitcode, $scan_response) = eval { $self->_run_commandline_scanner(join(' ', $self->{command}, @{ $self->{args} }, $path, '2>&1'), 'Found',); };

	if($@) {
		return File::VirusScan::Result->error($@);
	}

	if(0 == $exitcode) {
		return File::VirusScan::Result->clean();
	}

	if(        $exitcode >= 1
		&& $exitcode < 10)
	{
		my ($virus_name) = $scan_response =~ m/^\*+ Found virus (\S+)/;
		$virus_name ||= 'unknown-Trend-virus';
		return File::VirusScan::Result->virus($virus_name);
	}

	return File::VirusScan::Result->error("Unknown return code: $exitcode");
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Command::Trend::Vscan - File::VirusScan backend for scanning with Trend Micro vscan

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Command::Trend::Vscan' => {
			command => '/path/to/fprot',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using Trend's commandline scanner

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

L<http://www.trendmicro.com/>

=head1 AUTHOR

Dianne Skoll (dianne@skoll.ca)

Dave O'Neill (dmo@roaringpenguin.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
