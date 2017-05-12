package Mail::MtPolicyd::Plugin::ClearFields;

use Moose;
use namespace::autoclean;

our $VERSION = '2.02'; # VERSION
# ABSTRACT: mtpolicyd plugin to unset session variables


extends 'Mail::MtPolicyd::Plugin';

use Mail::MtPolicyd::Plugin::Result;

has 'fields' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'fields_prefix' => ( is => 'rw', isa => 'Maybe[Str]' );

sub clear_fields {
	my ( $self, $r ) = @_;
	my @fields = split(/\s*,\s*/, $self->fields);

	$self->log($r, 'clearing fields '.join(', ', @fields));
	foreach my $field ( @fields ) {
		delete $r->session->{$field};
	}
	return;
}

sub clear_fields_prefix {
	my ( $self, $r ) = @_;
	my @prefixes = split(/\s*,\s*/, $self->fields_prefix);

	$self->log($r, 'clearing fields with prefixes: '.join(', ', @prefixes));
	foreach my $prefix ( @prefixes ) {
		foreach my $field ( keys %{$r->session} ) {
			if( $field !~ /^\Q$prefix\E/) {
				next;
			}
			delete $r->session->{$field};
		}
	}
	return;
}

sub run {
	my ( $self, $r ) = @_;

	if( defined $self->fields) {
		$self->clear_fields( $r );
	}
	if( defined $self->fields_prefix) {
		$self->clear_fields_prefix( $r );
	}

	return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::ClearFields - mtpolicyd plugin to unset session variables

=head1 VERSION

version 2.02

=head1 DESCRIPTION

This plugin could be used to reset some session variables.

=head1 PARAMETERS

=over

=item fields (default: empty)

A comma separated list of session variables to unset.

=item fields_prefix (default: empty)

A comma separated list of prefixes.
All session variables with this prefixes will be unset.

=back

=head1 EXAMPLE

  <Plugin cleanup>
    module = "ClearFields"
    fields = "spamhaus-rbl,spamhaus-dbl"
  </Plugin>

Will remove both fields from the session.

  <Plugin cleanup>
    module = "ClearFields"
    fields_prefix = "spamhaus-"
  </Plugin>

Will also remove both fields and everything else starting with "spamhaus-" from the session.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
