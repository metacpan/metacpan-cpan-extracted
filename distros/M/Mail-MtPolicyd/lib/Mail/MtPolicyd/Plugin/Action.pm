package Mail::MtPolicyd::Plugin::Action;

use Moose;
use namespace::autoclean;

our $VERSION = '2.02'; # VERSION
# ABSTRACT: mtpolicyd plugin which just returns an action


extends 'Mail::MtPolicyd::Plugin';

use Mail::MtPolicyd::Plugin::Result;

has 'action' => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
	my ( $self, $r ) = @_;

	return Mail::MtPolicyd::Plugin::Result->new(
		action => $self->action,
		abort => 1,
	);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::Action - mtpolicyd plugin which just returns an action

=head1 VERSION

version 2.02

=head1 DESCRIPTION

This plugin just returns the specified string as action.

=head1 PARAMETERS

=over

=item action (required)

A string with the action to return.

=back

=head1 EXAMPLE

  <Plugin reject-all>
    module = "action"
    # any postfix action will do
    action=reject no reason
  </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
