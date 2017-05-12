package Gearman::Driver::Loader;

use Moose::Role;
use Module::Runtime;
use Module::Find;
use Try::Tiny;

=head1 NAME

Gearman::Driver::Loader - Loads worker classes

=head1 DESCRIPTION

This module is responsible for loading worker classes and doing
the introspection on them (looking for job method attributes etc).
All methods and attributes are internally used in L<Gearman::Driver>
but this module (implemented as L<Moose::Role>) might be of
interest to use outside of L<Gearman::Driver>.

=head1 ATTRIBUTES

=head2 namespaces

Will be passed to L<Module::Find> C<findallmod> method to load worker
modules. Each one of those modules has to be inherited from
L<Gearman::Driver::Worker> or a subclass of it. It's also possible
to use the full package name to load a single module/file. There is
also a method L<get_namespaces|Gearman::Driver/get_namespaces> which
returns a sorted list of all namespaces.

See also: L</wanted>.

=over 4

=item * isa: C<ArrayRef>

=item * required: C<True>

=back

=cut

has 'namespaces' => (
    default       => sub              { [] },
    documentation => 'Example: --namespaces My::Workers --namespaces My::OtherWorkers',
    handles       => { get_namespaces => 'sort' },
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
    required      => 0,
    traits        => [qw(Array)],
);

=head2 wanted

=over 4

=item * isa: C<CodeRef>

=item * required: C<False>

=back

This CodeRef will be called on each of the modules found in your
L</namespace>. The first and only parameter to this sub is the name
of the module. If a true value is returned, the module will be
loaded and checked if it's a valid L<Gearman::Driver::Worker>
subclass.

Let's say you have a namespace called C<My::Project>:

=over 4

=item * My::Project::Web

=item * My::Project::Web::Controller::Root

=item * My::Project::Web::Controller::Admin

=item * My::Project::Web::Controller::User

=item * My::Project::Web::Model::DBIC

=item * My::Project::Worker::ScaleImage

=item * My::Project::Worker::RemoveUser

=back

To avoid every module being loaded and inspected being a
L<Gearman::Driver::Worker> subclass you can use C<wanted>
to only load classes having C<Worker> in the package name:

    my $driver = Gearman::Driver->new(
        interval   => 0,
        namespaces => [qw(My::Project)],
        wanted     => sub {
            return 1 if /Worker/;
            return 0;
        },
    );

This would only load:

=over 4

=item * My::Project::Worker::ScaleImage

=item * My::Project::Worker::RemoveUser

=back

=cut

has 'wanted' => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_wanted',
);

=head2 lib

This is just for convenience to extend C<@INC> from command line
using C<gearman_driver.pl>:

    gearman_driver.pl --lib ./lib --lib /custom/lib --namespaces My::Workers

=over 4

=item * isa: C<Str>

=back

=cut

has 'lib' => (
    default       => sub { [] },
    documentation => 'Example: --lib ./lib --lib /custom/lib',
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
);

=head2 modules

Every worker module loaded by L<Module::Find> will be added to this
list. There are also two methods:
L<get_modules|Gearman::Driver/get_modules> and
L<has_modules|Gearman::Driver/has_modules>.

=over 4

=item * isa: C<ArrayRef>

=item * readonly: C<True>

=back

=cut

has 'modules' => (
    default => sub { [] },
    handles => {
        add_module  => 'push',
        get_modules => 'sort',
        has_modules => 'count',
    },
    is     => 'ro',
    isa    => 'ArrayRef[Str]',
    traits => [qw(Array)],
);

=head1 METHODS

=head2 get_namespaces

Returns a sorted list of L<namespaces|Gearman::Driver/namespaces>.

=head2 get_modules

Returns a sorted list of L<modules|Gearman::Driver/modules>.

=head2 has_modules

Returns the count of L<modules|Gearman::Driver/modules>.

=head2 is_valid_worker_subclass

Parameters: C<$package>

Checks if the given C<$package> is a valid subclass of
L<Gearman::Driver::Worker>.

=cut

sub is_valid_worker_subclass {
    my ( $self, $package ) = @_;
    return 0 unless $package;
    return 0 unless $package->can('meta');
    return 0 unless $package->meta->can('linearized_isa');
    return 0 unless grep $_ eq 'Gearman::Driver::Worker', $package->meta->linearized_isa;
    return 1;
}

=head2 has_job_method

Parameters: C<$package>

Checks if the given C<$package> has a valid job method.

=cut

sub has_job_method {
    my ( $self, $package ) = @_;
    return 0 unless $package;
    return 0 unless $package->meta->can('get_nearest_methods_with_attributes');
    foreach my $method ( $package->meta->get_nearest_methods_with_attributes ) {
        next unless grep $_ eq 'Job', @{ $method->attributes };
        return 1;
    }
    return 0;
}

=head2 load_namespaces

Loops over all L</namespaces> and uses L<findallmod|Module::Find>
to generate a list of modules to load. It verifies the module is
L</wanted> before it's being loaded using
L<Module::Runtime::use_module|Module::Runtime>. After loading
L</is_valid_worker_subclass> and L<has_wanted> is used to verify it.
After all tests have passed the modules are L<added|/add_module>.
So finally the loader is ready and can be queried with L<get_modules>
for example.

=cut

sub load_namespaces {
    my ($self) = @_;

    my @modules = ();
    foreach my $ns ( $self->get_namespaces ) {
        my @modules_ns = findallmod $ns;

        # Module::Find::findallmod($ns) does not load $ns itself
        push @modules_ns, $ns;

        if ( $self->has_wanted ) {
            @modules_ns = grep { $self->wanted->($_) } @modules_ns;
        }

        push @modules, @modules_ns;
    }

    foreach my $module (@modules) {
        Module::Runtime::use_module($module);
        next unless $self->is_valid_worker_subclass($module);
        next unless $self->has_job_method($module);
        $self->add_module($module);
    }
}

=head1 AUTHOR

See L<Gearman::Driver>.

=head1 COPYRIGHT AND LICENSE

See L<Gearman::Driver>.

=head1 SEE ALSO

=over 4

=item * L<Gearman::Driver>

=item * L<Gearman::Driver::Adaptor>

=item * L<Gearman::Driver::Console>

=item * L<Gearman::Driver::Console::Client>

=item * L<Gearman::Driver::Job>

=item * L<Gearman::Driver::Job::Method>

=item * L<Gearman::Driver::Observer>

=item * L<Gearman::Driver::Worker>

=back

=cut

no Moose::Role;

1;
