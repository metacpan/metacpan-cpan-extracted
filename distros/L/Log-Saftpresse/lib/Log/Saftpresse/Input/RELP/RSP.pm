package Log::Saftpresse::Input::RELP::RSP;

use Moose;

our $VERSION = '1.6'; # VERSION
# ABSTRACT: class for building RELP RSP records

has 'code' => ( is => 'rw', isa => 'Int', required => 1 );
has 'message' => ( is => 'rw', isa => 'Str', required => 1 );
has 'data' => ( is => 'rw', isa => 'Str', default => '' );

sub as_string {
	my $self = shift;
	return join(' ', $self->code, $self->message)."\n".$self->data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Input::RELP::RSP - class for building RELP RSP records

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
