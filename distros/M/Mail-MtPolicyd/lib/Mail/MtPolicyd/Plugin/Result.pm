package Mail::MtPolicyd::Plugin::Result;

use Moose;
use namespace::autoclean;

our $VERSION = '2.02'; # VERSION
# ABSTRACT: result returned by a plugin

has 'action' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'abort' => ( is => 'rw', isa => 'Bool', default => 0 );

sub new_dunno {
	my $class = shift;
		
	my $obj = $class->new(
		action => 'dunno',
		abort => 1,
	);
	return($obj);
}

sub new_header {
	my ( $class, $header, $value ) = @_;
		
	my $obj = $class->new(
		action => 'PREPEND '.$header.': '.$value,
		abort => 1,
	);
	return($obj);
}

sub new_header_once {
	my ( $class, $is_done, $header, $value ) = @_;

	if( $is_done ) {
		return $class->new_dunno;
	}
	return $class->new_header($header, $value);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::Result - result returned by a plugin

=head1 VERSION

version 2.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
