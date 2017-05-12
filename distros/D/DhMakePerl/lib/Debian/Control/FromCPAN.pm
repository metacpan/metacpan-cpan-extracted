=head1 NAME

Debian::Control::FromCPAN - fill F<debian/control> from unpacked CPAN distribution

=head1 SYNOPSIS

    my $c = Debian::Control::FromCPAN->new();
    $c->discover_dependencies( { ... } );
    $c->prune_perl_deps;

    Debian::Control::FromCPAN inherits from L<Debian::Control>.
=cut

package Debian::Control::FromCPAN;

use strict;
use warnings;

our $VERSION = '0.77';

use Carp qw(croak);

use base 'Debian::Control';

use CPAN ();
use DhMakePerl::Utils qw( is_core_module find_cpan_module nice_perl_ver split_version_relation apt_cache );
use File::Spec qw( catfile );
use Module::Depends ();

use constant oldstable_perl_version => '5.10.1';

=head1 METHODS

=over

=item discover_dependencies( [ { options hash } ] )

Discovers module dependencies and fills the dependency fields in
F<debian/control> accordingly.

Options:

=over

=item apt_contents

An instance of L<Debian::AptContents> to be used when locating to which package
a required module belongs.

=item dpkg_available
An instance of L<DPKG::Parse::Available> to be used when checking whether
the locally available package is the required version. For example:

    my $available = DPKG::Parse::Available->new;
    $available->parse;

=item dir

The directory where the cpan distribution was unpacked.

=item intrusive

A flag indicating permission to use L<Module::Depends::Intrusive> for
discovering dependencies in case L<Module::Depends> fails. Since this requires
loading all Perl modules in the distribution (and running their BEGIN blocks
(and the BEGIN blocks of their dependencies, recursively), it is recommended to
use this only when dealing with trusted sources.

=item require_deps

If true, causes the method to die if some a package for some dependency cannot
be found. Otherwise only a warning is issued.

=item verbose

=item wnpp_query

An instance of L<Debian::WNPP::Query> to be used when checking for WNPP bugs of
depended upon packages.

=back

Returns a list of module names for which no suitable Debian packages were
found.

=cut

sub discover_dependencies {
    my ( $self, $opts ) = @_;

    $opts //= {};
    ref($opts) and ref($opts) eq 'HASH'
        or die 'Usage: $obj->{ [ { opts hash } ] )';
    my $apt_contents = delete $opts->{apt_contents};
    my $dpkg_available = delete $opts->{dpkg_available};
    my $dir = delete $opts->{dir};
    my $intrusive = delete $opts->{intrusive};
    my $require_deps = delete $opts->{require_deps};
    my $verbose = delete $opts->{verbose};
    my $wnpp_query = delete $opts->{wnpp_query};

    die "Unsupported option(s) given: " . join( ', ', sort( keys(%$opts) ) )
        if %$opts;

    my $src = $self->source;
    my $bin = $self->binary_tie->Values(0);

    local @INC = ( $dir, @INC );

    # try Module::Depends, but if that fails then
    # fall back to Module::Depends::Intrusive.

    my $finder = Module::Depends->new->dist_dir($dir);
    my $deps;
    do {
        no warnings;
        local *STDERR;
        open( STDERR, ">/dev/null" );
        $deps = $finder->find_modules;
    };

    my $error = $finder->error();
    if ($error) {
        if ($verbose) {
            warn '=' x 70, "\n";
            warn "Failed to detect dependencies using Module::Depends.\n";
            warn "The error given was:\n";
            warn "$error";
        }

        if ( $intrusive ) {
            warn "Trying again with Module::Depends::Intrusive ... \n"
                if $verbose;
            require Module::Depends::Intrusive;
            $finder = Module::Depends::Intrusive->new->dist_dir($dir);
            do {
                no warnings;
                local *STDERR;
                open( STDERR, ">/dev/null" );
                $deps = $finder->find_modules;
            };

            if ( $finder->error ) {
                if ($verbose) {
                    warn '=' x 70, "\n";
                    warn
                        "Could not find the "
                        . "dependencies for the requested module.\n";
                    warn "Generated error: " . $finder->error;

                    warn "Please bug the module author to provide a"
                        . " proper META.yml file.\n"
                        . "Automatic find of" 
                        . " dependencies failed. You may want to \n"
                        . "retry using the '--[b]depends[i]' options\n"
                        . "or just fill the dependency fields in debian/rules"
                        . " by hand\n";

                        return;
                }
            }
        }
        else {
            if ($verbose) {
                warn "If you understand the security implications, try --intrusive.\n";
                warn '=' x 70, "\n";
            }
            return;
        }
    }

    # run-time
    my ( $debs, $missing )
        = $self->find_debs_for_modules( $deps->{requires}, $apt_contents,
            $verbose, $dpkg_available );

    if (@$debs) {
        if ($verbose) {
            print "\n";
            print "Needs the following debian packages: "
                . join( ", ", @$debs ) . "\n";
        }
        $bin->Depends->add(@$debs);
        if ( $bin->Architecture eq 'all' ) {
            $src->Build_Depends_Indep->add(@$debs);
        }
        else {
            $src->Build_Depends->add(@$debs);
        }
    }

    # build-time
    my ( $b_debs, $b_missing ) = $self->find_debs_for_modules(
        {   %{ $deps->{build_requires}     || {} },
            %{ $deps->{test_requires}      || {} },
            %{ $deps->{configure_requires} || {} }
        },
        $apt_contents,
        $verbose,
        $dpkg_available,
    );

    if (@$b_debs) {
        if ($verbose) {
            print "\n";
            print "Needs the following debian packages during building: "
                . join( ", ", @$b_debs ) . "\n";
        }
        if ( $self->is_arch_dep ) {
            $src->Build_Depends->add(@$b_debs);
        }
        else {
            $src->Build_Depends_Indep->add(@$b_debs);
        }
    }

    push @$missing, @$b_missing;

    if (@$missing) {
        my ($missing_debs_str);
        if ($apt_contents) {
            $missing_debs_str
                = "Needs the following modules for which there are no debian packages available:\n";
            for (@$missing) {
                my $bug
                    = $wnpp_query
                    ? ( $wnpp_query->bugs_for_package($_) )[0]
                    : undef;
                $missing_debs_str .= " - $_";
                $missing_debs_str .= " (" . $bug->type_and_number . ')'
                    if $bug;
                $missing_debs_str .= "\n";
            }
        }
        else {
            $missing_debs_str = "The following Perl modules are required and not installed in your system:\n";
            for (@$missing) {
                my $bug
                    = $wnpp_query
                    ? ( $wnpp_query->bugs_for_package($_) )[0]
                    : undef;
                $missing_debs_str .= " - $_";
                $missing_debs_str .= " (" . $bug->type_and_number . ')'
                    if $bug;
                $missing_debs_str .= "\n";
            }
            $missing_debs_str .= <<EOF
You do not have 'apt-file' currently installed, or have not ran
'apt-file update' - If you install it and run 'apt-file update' as
root, I will be able to tell you which Debian packages are those
modules in (if they are packaged).
EOF
        }

        if ($require_deps) {
            die $missing_debs_str;
        }
        else {
            warn $missing_debs_str;
        }

    }

    return @$missing;
}

=item find_debs_for_modules I<dep hash>[, APT contents[, verbose[, DPKG available]]]

Scans the given hash of dependencies ( module => version ) and returns
matching Debian package dependency specification (as an instance of
L<Debian::Dependencies> class) and a list of missing modules.

Perl core is searched first, then installed packages, then the APT contents.

If a DPKG::Parse::Available object is passed, also check the available package version

=cut

sub find_debs_for_modules {

    my ( $self, $dep_hash, $apt_contents, $verbose, $dpkg_available ) = @_;

    my $debs = Debian::Dependencies->new();
    my $aptpkg_cache = apt_cache();

    my @missing;

    while ( my ( $module, $version ) = each %$dep_hash ) {

        my $ver_rel;

        ( $ver_rel, $version ) = split_version_relation($version) if $version;

        $version =~ s/^v// if $version;

        my $dep;

        require Debian::DpkgLists;
        if ( my $ver = is_core_module( $module, $version ) ) {
            $dep = Debian::Dependency->new( 'perl', $ver );
        }
        elsif ( my @pkgs = Debian::DpkgLists->scan_perl_mod($module) ) {
            $dep = Debian::Dependency->new(
                  ( @pkgs > 1 )
                ? [ map { { pkg => $_, ver => $version } } @pkgs ]
                : ( $pkgs[0], $version )
            );

            # Check the actual version available, if we've been passed
            # a DPKG::Parse::Available object
            if ( $dpkg_available ) {
                my @available;
                my @satisfied = grep {
                    if ( my $pkg = $dpkg_available->get_package('name' => $_) ) {
                        my $have_pkg = Debian::Dependency->new( $_, '=', $pkg->version );
                        push @available, $have_pkg;
                        $have_pkg->satisfies($dep);
                    }
                    else {
                        warn qq(Unable to obtain version information for $module. You may need to )
                            .qq(install and run "dselect update");
                    }
                } @pkgs;
                unless ( @satisfied ) {
                    print "$module is available locally as @available, but does not satisify $version"
                        if $verbose;
                    push @missing, $module;
                }
            }
            else {
                warn "DPKG::Parse not available. Not checking version of $module.";
            }
        }

        if (!$dep && $apt_contents) {
            $dep = $apt_contents->find_perl_module_package( $module, $version );

            # Check the actual version in APT, if we've got
            # a AptPkg::Cache object to search
            if ( $dep && $aptpkg_cache ) {
                my $pkg = $aptpkg_cache->{$dep->pkg};
                if ( my $available = $pkg->{VersionList} ) {
                    for my $v ( @$available ) {
                        my $d = Debian::Dependency->new( $dep->pkg, '=', $v->{VerStr} );
                        unless ( $d->satisfies($dep) )
                        {
                            push @missing, $module;
                            print "$module package in APT ($d) does not satisfy $dep"
                                if $verbose;
                        }
                    }
                }
            }
        }


        $dep->rel($ver_rel) if $dep and $ver_rel and $dep->ver;

        my $mod_ver = join( " ", $module, $ver_rel // (), $version || () );
        if ($dep) {
            if ($verbose) {
                if ( $dep->pkg and $dep->pkg eq 'perl' ) {
                    print "= $mod_ver is in core";
                    print " since " . $dep->ver if $dep->ver;
                    print "\n";
                }
                else {
                    print "+ $mod_ver found in $dep\n";
                }
            }

            my $target_perl_version = $^V;
            $target_perl_version =~ s/^v//;
            $target_perl_version = Dpkg::Version->new($target_perl_version);

            if (    $dep->pkg
                and $dep->pkg eq 'perl'
                and $dep->ver
                and $dep->ver > $target_perl_version )
            {
                print "  ! $dep is too new. Adding alternative dependency\n"
                    if $verbose;

                my $alt_dep;

                if ( my @pkgs = Debian::DpkgLists->scan_perl_mod($module) ) {
                    @pkgs = grep {
                                ( $_ ne 'perl-modules' )
                            and ( $_ ne 'perl-base' )
                            and ( $_ ne 'perl' )
                    } @pkgs;

                    $alt_dep = Debian::Dependency->new(
                          ( @pkgs > 1 )
                        ? [ map { { pkg => $_, ver => $version } } @pkgs ]
                        : ( $pkgs[0], $version )
                    ) if @pkgs;
                }

                if ( not $alt_dep and $apt_contents) {
                    $alt_dep
                        = $apt_contents->find_perl_module_package( $module,
                        $version );
                }

                $alt_dep
                    //= Debian::Dependency->new(
                    $self->module_name_to_pkg_name($module),
                    '>=', $version );

                $dep = Debian::Dependency->new("$alt_dep | $dep");
                #print "    $dep\n";
            }
        }
        else {
            print "- $mod_ver not found in any package\n";
            push @missing, $module;

            my $mod = find_cpan_module($module);
            if ( $mod and $mod->distribution ) {
                ( my $dist = $mod->distribution->base_id ) =~ s/-v?\d[^-]*$//;
                my $pkg = $self->module_name_to_pkg_name($dist);

                print "   CPAN contains it in $dist\n";
                print "   substituting package name of $pkg\n";

                $dep = Debian::Dependency->new( $pkg, $ver_rel, $version );
            }
            else {
                print "   - it seems it is not available even via CPAN\n";
            }
        }

        $debs->add($dep) if $dep;
    }

    return $debs, \@missing;
}

=item prune_simple_perl_dep

Input:

=over

=item dependency object

shall be a simple dependency (no alternatives)

=item (optional) build dependency flag

true value indicates the dependency is a build-time one

=back


The following checks are made

=over

=item dependencies on C<perl-modules>

These are replaced with C<perl> as per Perl policy.

=item dependencies on C<perl-base> and build-dependencies on C<perl> or
C<perl-base>

These are removed, unless they specify a version greater than the one available
in C<oldstable> or the dependency relation is not C<< >= >> or C<<< >> >>>.

=back

Return value:

=over

=item undef

if the dependency is redundant.

=item pruned dependency

otherwise. C<perl-modules> replaced with C<perl>.

=back

=cut

sub prune_simple_perl_dep {
    my( $self, $dep, $build ) = @_;

    croak "No alternative dependencies can be given"
        if $dep->alternatives;

    return $dep unless $dep->pkg =~ /^(?:perl|perl-base|perl-modules)$/;

    # perl-modules is replaced with perl
    $dep->pkg('perl') if $dep->pkg eq 'perl-modules';

    my $unversioned = (
        not $dep->ver
            or $dep->rel =~ />/
            and $dep->ver <= $self->oldstable_perl_version
    );

    # if the dependency is considered unversioned, make sure there is no
    # version
    if ($unversioned) {
        $dep->ver(undef);
        $dep->rel(undef);
    }

    # perl-base is (build-)essential
    return undef
        if $dep->pkg eq 'perl-base' and $unversioned;

    # perl is needed in build-dependencies (see Policy 4.2)
    return $dep if $dep->pkg eq 'perl' and $build;

    # unversioned perl non-build-dependency is redundant, because it will be
    # covered by ${perl:Depends}
    return undef
        if not $build
            and $dep->pkg eq 'perl'
            and $unversioned;

    return $dep;
}

=item prune_perl_dep

Similar to L</prune_simple_perl_dep>, but supports alternative dependencies.
If any of the alternatives is redundant, the whole dependency is considered
redundant.

=cut

sub prune_perl_dep {
    my( $self, $dep, $build ) = @_;

    return $self->prune_simple_perl_dep( $dep, $build )
        unless $dep->alternatives;

    for my $simple ( @{ $dep->alternatives } ) {
        my $pruned = $self->prune_simple_perl_dep( $simple, $build );

        # redundant alternative?
        return undef unless $pruned;

        $simple = $pruned;
    }

    return $dep;
}

=item prune_perl_deps

Remove redundant (build-)dependencies on perl, perl-modules and perl-base.

=cut

sub prune_perl_deps {
    my $self = shift;

    # remove build-depending on ancient perl versions
    for my $perl ( qw( perl perl-base perl-modules ) ) {
        for ( qw( Build_Depends Build_Depends_Indep ) ) {
            my @ess = $self->source->$_->remove($perl);
            # put back non-redundant ones (possibly modified)
            for my $dep (@ess) {
                my $pruned = $self->prune_perl_dep( $dep, 1 );

                $self->source->$_->add($pruned) if $pruned;
            }
        }
    }

    # remove depending on ancient perl versions
    for my $perl ( qw( perl perl-base perl-modules ) ) {
        for my $pkg ( $self->binary_tie->Values ) {
            for my $rel ( qw(Depends Recommends Suggests) ) {
                my @ess = $pkg->$rel->remove($perl);
                for my $dep (@ess) {
                    my $pruned = $self->prune_perl_dep( $dep, 0 );

                    $pkg->$rel->add($pruned) if $pruned;
                }
            }
        }
    }
}

=back

=head1 CLASS METHODS

=over

=item module_name_to_pkg_name

Receives a perl module name like C<Foo::Bar> and returns a suitable Debian
package name for it, like C<libfoo-bar-perl>.

=cut

sub module_name_to_pkg_name {
    my ( $self, $module ) = @_;

    my $pkg = lc $module;

    # ensure policy compliant names and versions (from Joeyh)...
    $pkg =~ s/[^-.+a-zA-Z0-9]+/-/g;

    $pkg =~ s/--+/-/g;

    $pkg = 'lib' . $pkg unless $pkg =~ /^lib/;
    $pkg .= '-perl';

    return $pkg;
}

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009, 2010, 2012 Damyan Ivanov L<dmn@debian.org>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

1;


