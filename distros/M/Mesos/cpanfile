author_requires 'Async::Interrupt';
author_requires 'ExtUtils::CppGuess';
author_requires 'ExtUtils::ParseXS', '3.18';
author_requires 'ExtUtils::Typemaps';
author_requires 'ExtUtils::Typemaps::ObjectMap';
author_requires 'ExtUtils::Typemaps::STL';
author_requires 'FindBin';
author_requires 'Future::Mojo';
author_requires 'IO::Async::Handle';
author_requires 'List::Util';
author_requires 'Module::Install::AuthorTests';
author_requires 'Module::Install::CPANfile';
author_requires 'Module::Install::ReadmePodFromPod';
author_requires 'Module::Install::XSUtil';
author_requires 'Mojolicious';
author_requires 'POE';
author_requires 'POE::Future';

configure_requires 'ExtUtils::CppGuess';
configure_requires 'ExtUtils::ParseXS', '3.18';
configure_requires 'ExtUtils::Typemaps::ObjectMap';
configure_requires 'ExtUtils::Typemaps::STL';
configure_requires 'File::Temp';
configure_requires 'List::Util';

feature 'async-interrupt', 'Async::Interrupt support' => sub {
    recommends 'Async::Interrupt';
};
feature 'io-async', 'IO::Async support' => sub {
    recommends 'IO::Async::Handle';
};
feature 'mojo', 'Mojolicious support' => sub {
    recommends 'Mojolicious';
    recommends 'Future::Mojo';
};
feature 'poe', 'POE support' => sub {
    recommends 'POE';
    recommends 'POE::Future';
};

requires 'namespace::autoclean', '0.16';
requires 'AnyEvent';
requires 'Carp';
requires 'Digest::SHA';
requires 'Google::ProtocolBuffers';
requires 'Module::Runtime';
requires 'Moo';
requires 'Scalar::Util';
requires 'Scope::Guard';
requires 'Type::Tiny';
requires 'XSLoader';

test_requires 'AnyEvent::Future';
test_requires 'Test::Class::Moose', '0.55';
test_requires 'Test::LeakTrace';
test_requires 'Test::More';
test_requires 'Test::Pod';
test_requires 'Test::Strict';
test_requires 'Try::Tiny';
