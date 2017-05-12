# NAME

Devel::InheritNamespace - Inherit An Entire Namespace

# SYNOPSIS

    use Devel::InheritNamespace;

    my $din = Devel::InheritNamespace->new(
        on_class_found => sub { ... },
    );
    my @modules = 
        $din->all_modules( 'MyApp', 'Parent::Namespace1', 'Parent::Namespace2' );

# DESCRIPTION

WARNING: YMMV using this module.

This module allows you to dynamically "inherit" an entire namespace.

For example, suppose you have a set of packages under MyApp::Base:

    MyApp::Base::Foo
    MyApp::Base::Bar
    MyApp::Base::Baz

Then some time later you start writing MyApp::Extend.
You want to reuse MyApp::Base::Foo and MyApp::Base::Bar by subclassing
(because somehow the base namespace matters -- say, in Catalyst), but
you want to put a little customization for MyApp::Base::Baz

Normally you achieve this by manually creating MyApp::Extended:: modules:

    # in MyApp/Extended/Foo.pm
    package MyApp::Extended::Foo;
    use Moose;
    extends 'MyApp::Base::Foo';

    # in MyApp/Extended/Bar.pm
    package MyApp::Extended::Bar;
    use Moose;
    extends 'MyApp::Base::Bar';

    # in MyApp/Extended/Baz.pm
    package MyApp::Extended::Baz;
    use Moose;
    extends 'MyApp::Base::Baz';

    ... whatever customization you need ...

This is okay for a small number of modules, or if you are only doing this once
or twice. But perhaps you have tens of these modules, or maybe you do this
on every new project you create to inherit from a base applicatin set.

In that case you can use Devel::InheritNamespace. 

# METHODS

## `$class->new(%options)`

Constructs a new Devel::InheritNamespace instance. You may pass the following
options:

- except

    Regular expression to stop certain modules to be included in the search list.
    Note: This option will probably be deleted in the future releases: see
    `search_options` and Module::Pluggable for a way to achieve this.

- on\_class\_found

    Callback that gets called when a new class was loaded.

- search\_options

    Extra arguments to pass to Module::Pluggable::Object to search for modules.

## `$self->all_modules( $main_namespace, @namespaces_to_inherit )`;

Loads modules based on the following heuristics:

    1. Search all modules in $main_namespace using Module::Pluggable.
    2. Load those modules
    3. Repease searching in namespaces declared in the @namespaces_to_inherit
    4. Check if the corresponding module in the $main_namespace exists.
       (we basically do $class =~ s/^$current_namespace/$main_namespace/)
    5. If the module is already loaded, skip and check the module
    6. If the module has not been loaded, dynamically create a module in
       the $main_namespace, inheriting from the original one.
    7. Repeat above for all namespaces.

# TODO

Documentation. Samples. Tests.

# AUTHOR

Daisuke Maki `<daisuke@endeworks.jp>`

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
