package Gapp::Actions::Basic;
{
  $Gapp::Actions::Basic::VERSION = '0.60';
}

use Gapp::Actions -declare => [qw(
HideWindow
DestroyWindow
Quit
)];


use Gtk2;

action HideWindow => (
    label => 'Hide',
    tooltip => 'Hide',
    code => sub {
        my ( $action, $widget, $args, $gtkw, $gtkargs ) = @_;
        $gtkw->hide;
        return 1;
    }
);

action DestroyWindow => (
    label => 'Close',
    tooltip => 'Close',
    icon => 'gtk-cancel',
    code => sub {
        my ( $action,  $widget, $args, $gtkw, $gtkargs ) = @_;
        $gtkw->destroy;
    }
);

action Quit => (
    label => 'Quit',
    tooltip => 'Quit',
    icon => 'gtk-quit',
    code => sub {
        Gtk2->main_quit;
    }
);



1;
