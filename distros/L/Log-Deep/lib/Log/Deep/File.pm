package Log::Deep::File;

# Created on: 2009-05-30 22:58:50
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp qw/carp croak confess/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;
use overload '""' => \&name;
use Time::HiRes qw/sleep/;

our $VERSION     = version->new('0.3.5');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub new {
	my $caller = shift;
	my $class  = ref $caller ? ref $caller : $caller;
	my ($name) = @_;
	my $self   = { name => $name };

	bless $self, $class;

	open $self->{handle}, '<', $name or warn "Could not open $name: $OS_ERROR\n" and return;

	return $self;
}

sub line {
	my ($self) = @_;

	my $fh   = $self->{handle};
	my $line = <$fh>;
	my $count = 0;

	if (defined $line) {
		while ( $line !~ /\n$/xms ) {
			# guarentee that we have a full log line, ie if we read a line before it has been completely written
			$line .= <$fh>;

			if ($count++ > 200) {
				# give up if after 2s we still don't have a full line
				last;
			}
			else {
				# sleep a little to give the logging process time to write the rest of the line
				sleep 0.01;
				# reset the handle so that we can read more
				$self->reset;
			}
		}
	}

	$self->{count}++;

	return $line;
}

sub name { $_[0]->{name} }

sub reset {
	my ($self) = @_;

	# reset the file handle so that it can be read again;
	seek $self->{handle}, 0, 1;

	$self->{count} = 0;

	return;
}

1;

__END__

=head1 NAME

Log::Deep::File - Object for keeping track of info related to a log file.

=head1 VERSION

This documentation refers to Log::Deep::File version 0.3.5.

=head1 SYNOPSIS

   use Log::Deep::File;

   # Create a new object
   my $file = Log::Deep::File->new('deep.log');

   # read the log file
   while ( my $line = $file->line ) {
       # so stuff
       ...
   }

   # use the file name in a string
   print "Finished reading the file '$file'\n";

   # reset the handle so that we can start again
   $file->reset;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<new ( $name )>

Param: C<$name> - string - The log file name to be tracked

Return: Log::Deep::File - A new object

Description: Creates a new object and opens the specified file.

=head3 C<line ( )>

Return: The next line read from the log file or undef if the end of the file
has been reached

Description: Reads the next line of the log file.

=head3 C<name ( )>

Return: The name of the log file

=head3 C<reset ( )>

Description: Resets the file handle so that it can be attempted to be read
again at a later time.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
