package IM::Engine::Plugin::Dispatcher::ShortcutsDispatch;
use Moose::Role;
with 'IM::Engine::RequiresPlugins' => {
    plugins => 'IM::Engine::Plugin::Dispatcher',
};

requires 'shortcut_dispatch';

1;

