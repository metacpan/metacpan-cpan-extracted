package Kephra::Edit::History;
our $VERSION = '0.03';
=head1 NAME

Kephra::App::History - undo, redo and so on

=head1 DESCRIPTION

=cut

use strict;
use warnings;

# undo, redo etc.

sub _ep_ref { Kephra::App::EditPanel::_ref() }
sub _config { Kephra::API::settings()->{editpanel}{history} }

sub undo { _ep_ref()->Undo }
sub redo { _ep_ref()->Redo }

sub undo_several {
	my $ep = _ep_ref();
	$ep->Undo for 1 .. _config->{fast_undo_steps};
}

sub redo_several {
	my $ep = _ep_ref();
	$ep->Redo for 1 .. _config->{fast_undo_steps};
}

sub undo_begin {
	my $ep = _ep_ref();
	$ep->Undo while $ep->CanUndo;
}

sub redo_end {
	my $ep = _ep_ref();
	$ep->Redo while $ep->CanRedo;
}

sub clear_history { 
	_ep_ref()->EmptyUndoBuffer;
	Kephra::EventTable::trigger('document.savepoint');
}

sub can_undo  { _ep_ref()->CanUndo }
sub can_redo  { _ep_ref()->CanRedo }

1;