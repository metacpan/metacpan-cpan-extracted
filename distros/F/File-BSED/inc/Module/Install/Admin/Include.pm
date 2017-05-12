package Module::Install::Admin::Include;

use Module::Install::Base;
@ISA = qw(Module::Install::Base);

$VERSION = '0.67';

sub include {
    my ( $self, $pattern ) = @_;

    foreach my $rv ( $self->admin->glob_in_inc($pattern) ) {
        $self->admin->copy_package(@$rv);
    }
    return $file;
}

sub include_deps {
    my ( $self, $pkg ) = @_;
    my $deps = $self->admin->scan_dependencies($pkg) or return;

    foreach my $key ( sort keys %$deps ) {
        $self->include($key);
    }
}

sub auto_include {
    my $self = shift;
    foreach
        my $module ( map $_->[0], map @$_, grep $_, $self->build_requires )
    {
        $self->include($module);
    }
}

sub auto_include_deps {
    my $self = shift;
    foreach
        my $module ( map $_->[0], map @$_, grep $_, $self->build_requires )
    {
        $self->include_deps($module);
    }
}

=head2 auto_include_dependent_dists

Grabs everything in this module's build_requires and attempts to
include everything (at the whole distribution level) recursively.

=cut

sub auto_include_dependent_dists {
    my $self = shift;
    foreach
        my $module ( map $_->[0], map @$_, grep $_, $self->build_requires )
    {
        $self->include_dependent_dists($module);
    }
}

=head2 include_dependent_dists $package

Given a module package name, recursively include every package that
module needs.

=cut

sub include_dependent_dists {
    my ( $self, $pkg ) = @_;
    return unless ($pkg);
    return if ( $self->_seen_it($pkg) );
    $self->include_one_dist($pkg);

    foreach my $mod ( @{ $self->_dist_to_mods( $self->_pkg_to_dist($pkg) ) } )
    {
        my $deps = $self->admin->scan_dependencies($mod) or return;
        foreach my $key ( sort keys %$deps ) {
            next unless ($key);
            $self->include_dependent_dists($key);
        }
    }
}

=head2 include_one_dist $module

Given a module name, C<$module>, figures out which modules are in the
dist containing that module and copies all those files to ./inc. I bet
there's a way to harness smarter logic from L<PAR>.

=cut

sub include_one_dist {
    my ( $self, $key ) = @_;
    my @mods = $self->_dist_to_mods( $self->_pkg_to_dist($key) );
    foreach my $pattern (@mods) {
        next unless $pattern;
        foreach my $rv ( $self->admin->glob_in_inc($pattern) ) {
            $self->admin->copy_package(@$rv);
        }
    }
}

=for private _pkg_to_dist $modname

Given a module name, returns the file on CPAN containing
its latest version.

=cut

sub _pkg_to_dist {
    my $self = shift;
    my $pkg  = shift;

    require CPAN;

    my $mod = CPAN::Shell->expand( Module => $pkg );
    return unless ($mod);
    $file = $mod->cpan_file;
    return $file;
}

=for private _dist_to_mods $distname

Takes the output of CPAN::Module->cpan_file and return all the modules
that CPAN.pm knows are in that dist. There's probably a beter way using CPANPLUS

=cut

sub _dist_to_mods {
    my $self = shift;
    my $file = shift;
    my $dist = CPAN::Shell->expand( Distribution => $file );
    my @mods = $dist->containsmods();
    return @mods;
}

sub _seen_it {
    my $self    = shift;
    my $pattern = shift;
    if ( $self->{including_dep_dist}{ $self->_pkg_to_dist($pattern) }++ ) {
        return 1;
    }
    return undef;
}

1;
