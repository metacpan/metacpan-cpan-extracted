package Log::Saftpresse::Input::Stdin;

use Moose;

# ABSTRACT: log input for reading STDIN
our $VERSION = '1.6'; # VERSION


use IO::Handle;
use IO::Select;

use Sys::Hostname;
use Time::Piece;

extends 'Log::Saftpresse::Input';

has 'max_chunk_lines' => ( is => 'rw', isa => 'Int', default => 1024 );

has 'stdin' => (
	is => 'ro', isa => 'IO::Handle', lazy => 1,
	default => sub {
		my $fh = IO::Handle->new_from_fd(fileno(STDIN),"r");
		$fh->blocking(0);
		return $fh;
	},
	handles => {
		'eof' => 'eof',
	},
);

# we only have one handle, just alias
*io_handles = \&stdin;

has 'io_select' => (
	is => 'ro', isa => 'IO::Select', lazy => 1,
	default => sub {
		my $self = shift;
		my $s = IO::Select->new();
		$s->add( $self->stdin );
		return $s;
	},
);

sub read_events {
	my ( $self ) = @_;
	my @events;
	my $cnt = 0;
	while( defined( my $line = $self->stdin->getline ) ) {
		chomp( $line );
		my $event = {
			'host' => hostname,
			'time' => Time::Piece->new,
			'message' => $line,
		};
		push( @events, $event );
		$cnt++;
		if( $cnt > $self->max_chunk_lines ) {
			last;
		}
	}
	return @events;
}

sub can_read {
	my ( $self ) = @_;
	my @can_read = $self->io_select->can_read(0);
	return( scalar @can_read );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Input::Stdin - log input for reading STDIN

=head1 VERSION

version 1.6

=head1 Description

This input plugins reads events from STDIN.

=head1 Synopsis

  <Input stdin>
    module = "Stdin"
  </Input>

=head1 Options

=over

=item max_chunk_lines (default: 1024)

Maximum number of file to read in one chunk.

=back

=head1 Input Format

For each line the plugin will generate an event with the following fields:

=over

=item message

The content of the line.

=item host

The hostname of the system.

=item time

The current time.

=back

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
