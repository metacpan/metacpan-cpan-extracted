package Log::Saftpresse::Output;

use Moose;

# ABSTRACT: base class for outputs
our $VERSION = '1.6'; # VERSION

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

sub output {
	my ( $self, $event ) = @_;
	die('not implemented');
}

sub init { return; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Output - base class for outputs

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
