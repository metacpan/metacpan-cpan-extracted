
package Devel::InheritNamespace;
use Moose;
use Module::Pluggable::Object;
use Class::Load;
use namespace::clean -except => qw(meta);

our $VERSION = '0.00003';

has search_options => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_search_options'
);
    
has on_class_found => (
    is => 'ro',
    isa => 'CodeRef',
    predicate => 'has_on_class_found',
);

has except => (
    is => 'ro',
    isa => 'RegexpRef',
    lazy_build => 1,
);

sub _build_except {
    return qr/::SUPER$/;
}

# from a given list of namespaces, load everything
# however, if names clash, the first one to be loaded wins

sub search_components_in_namespace {
    my ($self, $namespace) = @_;

    my @search_path = ($namespace);
    my %config;
    if ($self->has_search_options) {
        %config = %{ $self->search_options };
    }

    my $locator = Module::Pluggable::Object->new(
        %config,
        search_path => [ @search_path ],
    );

    my @comps;
    my $except = $self->except;
    if ($except) {
        @comps = sort grep { !/$except/ } $locator->plugins;
    } else {
        @comps = sort $locator->plugins;
    }

    return @comps;
}


sub all_modules {
    my ($self, @namespaces) = @_;

    my @comps;
    my $main_namespace = $namespaces[0];
    foreach my $namespace (@namespaces) {
        push @comps,
            map {
                [ $namespace, $_ ]
            }
            $self->search_components_in_namespace( $namespace );
    }

    my %comps;
    foreach my $comp (@comps) {
        my ($comp_namespace, $comp_class) = @$comp;

        my $is_virtual;
        my $base_class;

        if ($comp_namespace eq $main_namespace ) {
            if (! Class::Load::is_class_loaded($comp_class)) {
                Class::Load::load_class($comp_class);
            }
        } else {
            $base_class = $comp_class;

            # see if we can make a subclass out of it
            $comp_class =~ s/^$comp_namespace/$main_namespace/;

            next if $comps{ $comp_class };
            eval { Class::Load::load_class($comp_class) };
            if (my $e = $@) {
                if ($e =~ /Can't locate/) {
                    # if the module is NOT found in the current app ($class),
                    # then we build a virtual component. But don't do this
                    # if $base_class is a role
                    Class::Load::load_class($base_class);
                    next if $base_class->can('meta') && $base_class->meta->isa('Moose::Meta::Role');

                    my $meta = Moose::Meta::Class->create(
                        $comp_class => ( superclasses => [ $base_class ] )
                    );
                    $is_virtual = 1;
                } else {
                    confess "Failed to load class $comp_class: $e";
                }
            }
        }
        $comps{ $comp_class } = {
            is_virtual => $is_virtual,
            base_class => $base_class
        };

        if ($self->has_on_class_found) {
            $self->on_class_found->( $comp_class );
        }
    }
    return \%comps;
}

1;

__END__

=head1 NAME

Devel::InheritNamespace - Inherit An Entire Namespace

=head1 SYNOPSIS

    use Devel::InheritNamespace;

    my $din = Devel::InheritNamespace->new(
        on_class_found => sub { ... },
    );
    my @modules = 
        $din->all_modules( 'MyApp', 'Parent::Namespace1', 'Parent::Namespace2' );

=head1 DESCRIPTION

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

=head1 METHODS

=head2 C<< $class->new(%options) >>

Constructs a new Devel::InheritNamespace instance. You may pass the following
options:

=over 4

=item except

Regular expression to stop certain modules to be included in the search list.
Note: This option will probably be deleted in the future releases: see
C<search_options> and Module::Pluggable for a way to achieve this.

=item on_class_found

Callback that gets called when a new class was loaded.

=item search_options

Extra arguments to pass to Module::Pluggable::Object to search for modules.

=back

=head2 C<< $self->all_modules( $main_namespace, @namespaces_to_inherit ) >>;

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

=head1 TODO

Documentation. Samples. Tests.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

