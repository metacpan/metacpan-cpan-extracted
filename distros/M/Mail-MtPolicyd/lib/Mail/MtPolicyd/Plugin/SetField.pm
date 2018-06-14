package Mail::MtPolicyd::Plugin::SetField;

use Moose;
use namespace::autoclean;

our $VERSION = '2.03'; # VERSION
# ABSTRACT: mtpolicyd plugin which just sets and key=value in the session


extends 'Mail::MtPolicyd::Plugin';

use Mail::MtPolicyd::Plugin::Result;

has 'key' => ( is => 'rw', isa => 'Str', required => 1 );
has 'value' => ( is => 'rw', isa => 'Str', required => 1 );

sub run {
	my ( $self, $r ) = @_;
	$r->session->{$self->key} = $self->value;
	return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::SetField - mtpolicyd plugin which just sets and key=value in the session

=head1 VERSION

version 2.03

=head1 DESCRIPTION

This plugin can be used to set key/values within the session.

=head1 EXAMPLE

  <Plugin set-scanned>
    module = "SetField"
    key=mail-is-scanned
    value=1
  </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
