package Medusa::Logger;

use strict;
use warnings;

sub new {
	my ($pkg, %args) = (shift, @_ > 1 ? @_ : %{$_[1] || {}});
	$args{file} ||= 'audit.log';
	my $self = bless \%args, $pkg;
	open my $fh, '>', $self->{file} or die $!;
	$self->{fh} = $fh;
	return $self;
}

sub debug {
	my ($self, $line) = @_;
	$self->log('DEBUG', $line);
}

sub error {
	my ($self, $line) = @_;
	$self->log('ERROR', $line);
}

sub info {
	my ($self, $line) = @_;
	$self->log('INFO', $line);
}

sub log {
	my ($self, $level, $line) = @_;
	my $time = gmtime;
	flock($self->{fh}, 1);
	my $fh = $self->{fh};
	print $fh sprintf("%s %s %s\n",$time, $level, $line);
	flock($self->{fh}, 0);
	print $time;

}


sub DESTROY {
	close $_[0]->{fh};
}

1;

__END__

=head1 NAME

Medusa::Logger - Simple file-based logger for Medusa audit logging

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Medusa::Logger;

    my $logger = Medusa::Logger->new( file => 'audit.log' );
    
    $logger->debug("Starting process");
    $logger->info("User logged in: user123");
    $logger->error("Failed to connect to database");

=head1 DESCRIPTION

Medusa::Logger is a lightweight file-based logger designed for use with the
L<Medusa> audit framework. It provides simple timestamped logging to a file
with file locking to ensure safe concurrent writes.

=head1 METHODS

=head2 new

    my $logger = Medusa::Logger->new( file => 'audit.log' );
    my $logger = Medusa::Logger->new( { file => 'audit.log' } );

Creates a new logger instance. Accepts arguments as a hash or hashref.

=over 4

=item B<file>

The path to the log file. Defaults to C<audit.log> if not specified.
The file will be created (or truncated) when the logger is instantiated.

=back

=head2 debug

    $logger->debug("Debug message here");

Writes a debug-level message to the log file with a GMT timestamp.

=head2 info

    $logger->info("Informational message");

Writes an info-level message to the log file with a GMT timestamp.

=head2 error

    $logger->error("Error message");

Writes an error-level message to the log file with a GMT timestamp.

=head1 LOG FORMAT

Each log entry is written in the following format:

    <timestamp> <message>

Where C<timestamp> is the GMT time when the message was logged.

=head1 FILE LOCKING

The logger uses C<flock> to ensure thread-safe writes to the log file,
preventing interleaved output when multiple processes write simultaneously.

=head1 SEE ALSO

L<Medusa>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
