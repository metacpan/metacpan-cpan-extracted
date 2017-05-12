package Log::Saftpresse::Input;

use Moose;

# ABSTRACT: base class for a log input
our $VERSION = '1.6'; # VERSION

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

sub io_handles {
	my $self = shift;
	die('not implemented');
	return;
}

sub can_read {
	my $self = shift;
	die('not implemented');
	return 0;
}

sub read_events {
	my ( $self, $counters ) = @_;
	die('not implemented');
	return( { message => 'hello world' } );
}

sub eof {
	my $self = shift;
	die('not implemented');
	return 0;
}

sub init { return; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Input - base class for a log input

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
