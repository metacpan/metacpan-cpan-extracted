package Gapp::Actions::Test;
use Gapp::Actions -declare => [qw( New Edit Delete )];

action New => (
    label => 'New',
    tooltip => 'New',
    icon => 'gtk-new',
    code => sub { ${$_[1]} = 1; },
);

action Edit => (
    label => 'Edit',
    tooltip => 'Edit',
    icon => 'gtk-edit',
    code => sub { ${$_[1]} = 2; },
);

action Delete => (
    label => 'Delete',
    tooltip => 'Delete',
    icon => 'gtk-delete',
    code => sub { ${$_[1]} = 3; },
);


1;
