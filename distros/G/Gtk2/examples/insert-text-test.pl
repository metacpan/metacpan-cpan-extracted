=doc

Use the insert-text signal to trap and possibly mangle text as the user types,
but before it is committed and displayed.

=cut

use Gtk2 -init;
use Data::Dumper;


$dialog = Gtk2::Dialog->new;
$dialog->add_button ('gtk-close' => 'close');

$entry = Gtk2::Entry->new;
$entry->set_activates_default (1);
$entry->signal_connect ('insert-text' => sub {
			my ($widget, $string, $len, $position) = @_;
			if ($string eq '-') {
				$_[1] = '_';
				$_[3]--;
			} elsif ($string eq 'ee') {
				$_[1] = ' <whee> ';
			} elsif ($string eq '#') {
				# just can't insert these.
				$entry->signal_stop_emission_by_name
							('insert-text');
				warn "NOSOUPFORYOU!!\n";
			}
			() # this callback must return either 2 or 0 items.
		});

$dialog->vbox->pack_start ($entry, 0, 0, 0);
$entry->show;

$label = Gtk2::Label->new;
$label->set_markup ('using a handler for insert-text, this entry
turns dashes into underscores (moved back
one space), turns the string "ee" into
something else (you\'ll have to paste it),
and won\'t let you type a #.');
$dialog->vbox->pack_start ($label, 1,1, 0);
$label->show;


# while we're testing custom marshallers, connect to dialog's response
# signal, which also has a custom marshaller.  if the blue smoke gets
# out, then something i broken deep inside.
$dialog->signal_connect (response => sub {
	print Dumper(\@_);
	Gtk2->main_quit;
});
$dialog->show;
Gtk2->main;
