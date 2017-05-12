package Log::Saftpresse::Input::Command;

use Moose;

# ABSTRACT: log input for slurping the output of a command
our $VERSION = '1.6'; # VERSION


use Log::Saftpresse::Input::Command::Child;
use Log::Saftpresse::Log4perl;

use Time::Piece;
use Sys::Hostname;

extends 'Log::Saftpresse::Input';

has 'command' => ( is => 'ro', isa => 'Str', required => 1);
has 'max_chunk_lines' => ( is => 'rw', isa => 'Int', default => 1024 );

has '_child' => (
  is => 'rw', isa => 'Log::Saftpresse::Input::Command::Child', lazy => 1,
  default => sub {
    my $self = shift;
    my $c = Log::Saftpresse::Input::Command::Child->new(
      command => $self->command,
      blocking => 0,
    );
    $c->start;
    return $c;
  },
  clearer => '_reset_child',
);

has 'io_select' => (
	is => 'ro', isa => 'IO::Select', lazy => 1,
	default => sub {
		my $self = shift;
		my $s = IO::Select->new();
		$s->add( $self->_child->stdout );
		return $s;
	},
);

sub io_handles {
	my $self = shift;
	return $self->_child->stdout;
}

sub read_events {
	my ( $self ) = @_;
	my @events;
	my $cnt = 0;
	while( defined( my $line = $self->_child->stdout->getline ) ) {
		my $event = {
			'host' => hostname,
			'time' => Time::Piece->new,
			$self->process_line( $line ),
		};
		push( @events, $event );
		$cnt++;
		if( $cnt > $self->max_chunk_lines ) {
			last;
		}
	}
  if( ! $cnt ) {
    $log->warn('input command "'.$self->command.'" at EOF...restarting it');
    $self->_reset_child;
  }
	return @events;
}

sub process_line {
  my ( $self, $line ) = @_;
  chomp( $line );
  return message => $line;
}

sub eof {
	my $self = shift;
	return 0;
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

Log::Saftpresse::Input::Command - log input for slurping the output of a command

=head1 VERSION

version 1.6

=head1 Description

This input watches executes a command and will follow its output.

=head1 Synopsis

  <Input alive>
    module = "Command"
    command = "journalctl -f"
  </Input>

=head1 Format

Foreach line appended to the file a event with the following fields is generated:

=over

=item message

Content of the line.

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
