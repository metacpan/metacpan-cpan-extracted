package Gapp::Actions::Form;
{
  $Gapp::Actions::Form::VERSION = '0.60';
}

use Gapp::Actions -declare => [qw(
Cancel
Ok
Apply
)];


action Apply => (
    name => 'Apply',
    label => 'Apply',
    mnemonic => '_Apply',
    tooltip => 'Apply',
    icon => 'gtk-apply',
    code => sub {
        my ( $action, $widget, $userargs, $gtkw, $gtkargs ) = @_;
        
        my $form = $widget->form;
        
        $form->apply;
    }
);

action Cancel => (
    name => 'Cancel',
    label => 'Cancel',
    mnemonic => '_Cancel',
    tooltip => 'Cancel',
    icon => 'gtk-cancel',
    code => sub {
        my ( $action, $widget, $userargs, $gtkw, $gtkargs ) = @_;
        my $form = $widget->form;
        $form->cancel;
    }
);

action Ok => (
    name => 'Ok',
    label => 'Ok',
    mnemonic => '_Ok',
    tooltip => 'Ok',
    icon => 'gtk-ok',
    code => sub {
        my ( $action, $widget, $userargs, $gtkw, $gtkargs ) = @_;
        my $form = $widget->form;
        $form->ok;
    }
);

1;
