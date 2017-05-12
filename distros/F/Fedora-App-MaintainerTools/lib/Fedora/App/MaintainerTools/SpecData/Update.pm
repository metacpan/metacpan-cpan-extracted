#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
#
# Copyright (c) 2009 - 2010 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools::SpecData::Update;

use Moose;
use namespace::autoclean;
use MooseX::Types::Moose ':all';

#use autodie qw{ system };
#use Fedora::App::MaintainerTools::Types ':all';

use DateTime;
use File::Basename;
use List::MoreUtils qw{ any uniq };
use Path::Class;
use Pod::POM;
use Pod::POM::View::Text;
use Text::Autoformat;
use RPM::VersionSort;

extends 'Fedora::App::MaintainerTools::SpecData';

our $VERSION = '0.006';

# debugging
#use Smart::Comments '###', '####';

has spec => (is => 'ro', isa => 'RPM::Spec', required => 1, coerce => 1);

#############################################################################
# "how"

has is_fully_managed => (is => 'ro', isa => Bool, lazy_build => 1);

sub _build_is_fully_managed { shift->conf->{common}->{is_fully_managed} }

#############################################################################
# build methods

sub _build_name    { shift->spec->name }
sub _build_license { warn 'not checking license'; shift->spec->license }
sub _build_summary { shift->spec->summary }
sub _build_url     { shift->spec->url }

sub _build_dist    { (my $_ = shift->name) =~ s/^perl-//; s/\s*$//; $_ }

sub _build__changelog {
    [ "- update by Fedora::App::MaintainerTools $Fedora::App::MaintainerTools::VERSION" ]
}

sub _build_version {
    my $self = shift @_;

    my $new = $self->mm->data->{version};
    my $old = $self->spec->version;

    $self->add_changelog("- updating to latest GA CPAN version ($new)")
        if $new ne $old;

    return $new;
}

sub _build_description { shift->conf->{spec_description}->{content} // '%{summary}.' }

{
    my $build = sub {
        my ($self, $part) = @_;

        return $self->conf->{"spec_$part"}->{use_custom}
            ? [ split "\n", $self->conf->{"spec_$part"}->{custom} ]
            : [ ]
            ;
    };

    # FIXME prep is a special case
    #sub _build__prep    { $build->($self, 'prep')    }
    sub _build__build   { $build->(shift, 'build')   }
    sub _build__install { $build->(shift, 'install') }
    sub _build__check   { $build->(shift, 'check')   }
    sub _build__clean   { $build->(shift, 'clean')   }
    sub _build__files   { $build->(shift, 'files')   }
}

#############################################################################
# rpm metadata build methods

# these are pretty much just pulled over from the old Plugins system...  They
# need refactoring, but work for now.

sub _build_epoch   {
    my $self = shift @_;

    my $epoch = $self->spec->epoch;

    ##############################################################
    # epoch checking

    my ($old_v, $v) = ($self->spec->version, $self->version);

    if ($old_v eq $v) {

        # if they're actually equivalent, that means we're updating a spec
        # file that doesn't have a new upstream release.  Don't touch the
        # epoch, but do bump the requires by one.
        $self->release($self->spec->release + 1);
        return;
    }

    if (rpmvercmp($old_v, $v) == 1) {

        # rpm is going to think that the old version is larger than the new
        # one, so we're going to need to fiddle with the epoch here
        if ($epoch) {

            $epoch++;
            #@lines = map { /^Epoch:/i && $_ =~ s/\S+$/$e/; $_ } @lines;
            $self->add_changelog("- Bump epoch to $epoch ($old_v => $v)");
        }
        else {

            #@lines = map { /^Version:/i ? ('Epoch: 1', $_) : $_ } @lines;
            $epoch = 1;
            $self->add_changelog("- Add epoch of 1 ($old_v => $v)");
        }
    }

    return $epoch;
}

sub _build__build_requires {
    #my ($self, $data) = @_;
    my $self = shift @_;

    # lazy, and on a monday even
    my $data = $self;

    ##############################################################
    # BR info (should be refactored)

    my $mm     = $self->mm;
    my $spec   = $self->spec;
    my $module = $self->module;

    my %brs = $self->spec->full_build_requires;

    my (@new_brs, @cl);
    NEW_BR_LOOP:
    for my $br (sort $mm->rpm_build_requires) {

        my $new = $mm->rpm_build_require_version($br);

        if ($spec->has_build_require($br)) {
        #if (exists $brs{$br})) {

            my $old = $spec->build_require_version($br);
            next NEW_BR_LOOP if $new eq '0' || $old eq $new;

            #$data->build_require_this($br => $new);
            $brs{$br} = $new;
            push @cl, "- altered br on $br ($old => $new)";
            next NEW_BR_LOOP;
        }

        # if we're here, it's a new BR
        #push @new_brs, _br($br => $new);
        #$data->build_require_this($br => $new);
        $brs{$br} = $new;
        push @cl, "- added a new br on $br (version $new)";
    }

    # Ensure that EU::MM is _always_ BR'ed
    unless (exists $brs{'perl(ExtUtils::MakeMaker)'}) {

        $brs{'perl(ExtUtils::MakeMaker)'} = 0;
        push @cl, '- force-adding ExtUtils::MakeMaker as a BR';
    }

    # delete stale build requirements
    PURGE_BR_LOOP:
    #for my $br ($data->build_requires) {
    for my $br (sort keys %brs) {

        # not ideal, but WFN.
        next PURGE_BR_LOOP
            if $br !~ /^perl\(/ || $br eq 'perl(CPAN)';

        next PURGE_BR_LOOP if $br =~ /^perl\(:MODULE_COMPAT/;
        next PURGE_BR_LOOP if $br eq 'perl(ExtUtils::MakeMaker)';
        next PURGE_BR_LOOP if exists $data->conf->{add_build_requires}->{$br};

        # check to see META.yml lists it as a dep.  if not, purge.
        unless ($mm->has_rpm_br_on($br)) {

            delete $brs{$br};
            push @cl, "- dropped old BR on $br";
        }
    }

    for my $manual_br (keys %{$data->conf->{add_build_requires}}) {

        # FIXME should check versioning too
        next if exists $brs{$manual_br};

        my $ver = $data->conf->{add_build_requires}->{$manual_br};
        $brs{$manual_br} = $ver;
        push @cl, "- added manual BR on $manual_br";
    }

    # check for inc::Module::AutoInstall; force br CPAN if so *sigh*
    my $mdir = dir($module->status->extract || $module->extract);
    if (file($mdir, qw{ inc Module AutoInstall.pm })->stat) {

        warn "inc::Module::AutoInstall found; BR'ing CPAN\n";

        if (not exists $brs{'perl(CPAN)'}) {

            #push @new_brs, _br('perl(CPAN)');
            $brs{'perl(CPAN)'} = 0;
            push @cl, '- added a new br on CPAN (inc::Module::AutoInstall found)';
        }
    }

    $self->add_changelog(@cl);
    return \%brs;
}

sub _build__requires {
    my $self = shift @_;

    my $mm     = $self->mm;
    my $spec   = $self->spec;
    my $module = $self->module;

    my %require = $self->spec->full_requires;

    my (@cl, @new_reqs);
    NEW_REQ_LOOP:
    for my $r (sort $mm->rpm_requires) {

        my $new = $mm->rpm_require_version($r);

        if ($self->is_suspect_require($r)) {

            next NEW_REQ_LOOP if $self->has_build_require($r);

            $self->build_require_this($r => $new);
            $self->add_changelog("- suspect requires as BR ($r $new)");
            next NEW_REQ_LOOP;
        }


        #if ($data->has_require($r)) {
        if (exists $require{$r}) {

            my $old = $require{$r}; #$data->require_version($r);
            next NEW_REQ_LOOP if $new eq '0' || $old eq $new;

            $require{$r} = $new;
            push @cl, "- altered req on $r ($old => $new)";
            next NEW_REQ_LOOP;
        }

        # if we're here, it's a new BR
        $require{$r} = $new;
        push @cl, "- added a new req on $r (version $new)";
        #$self->add_changelog("- added a new req on $r (version $new)");
    }

    # delete stale requirements
    PURGE_R_LOOP:
    for my $req (sort keys %require) {

        # make sure it's a _perl_ requires
        next PURGE_R_LOOP unless $req =~ /^perl\(/;
        next PURGE_R_LOOP if exists $self->conf->{add_requires}->{$req};

        # check to see META.yml lists it as a dep.  if not, purge.
        unless ($mm->has_rpm_require_on($req)) {

            delete $require{$req};
            push @cl, "- dropped old requires on $req";
        }
    }

    for my $manual_req (keys %{$self->conf->{add_requires}}) {

        # FIXME should check versioning too
        next if exists $require{$manual_req};

        my $ver = $self->conf->{add_requires}->{$manual_req};
        $require{$manual_req} = $ver;
        push @cl, "- added manual requires on $manual_req";
    }

    $self->add_changelog(@cl);
    return \%require;
}

has middle => (is => 'rw', isa => 'ArrayRef[Str]', lazy_build => 1);

sub _build_middle {
    my $self = shift @_;

    # fix up middle -- PERL_INSTALL_ROOT mainly
    my @middle = $self->spec->middle;

    return \@middle;

    # FIXME not even trying right now with this one
    #for my $line ($self->all_middle) {
    for my $line (@middle) {

        if ($line eq 'make pure_install PERL_INSTALL_ROOT=%{buildroot}') {

            $line = 'make pure_install DESTDIR=%{buildroot}';
            $self->add_changelog('- PERL_INSTALL_ROOT => DESTDIR');
        }

        push @middle, $line;
    }

    $self->middle(\@middle);
    return;
}

sub _suspect_req { shift =~ /^perl\(Test::/ }

#############################################################################
# RPM metadata filtering (and other) macros

around _build__macros => sub {
    my ($orig, $self) = @_;

    my @macros = @{ $self->$orig() };

    return \@macros unless exists $self->conf->{metadata_filtering};

    # FIXME we need to switch to Config::MVP or some such, that allows
    # multiple values in the conf file.

    my $filters = $self->conf->{metadata_filtering};
    for my $macro (sort keys %$filters) {

        unshift @macros, '%{?' . $macro . ': %' . "$macro $filters->{$macro} }";
    }

    return \@macros;
};

#############################################################################
# Generate our template

# FIXME rework middle into the template and drop the method below

sub _build_output {
    my $self = shift @_;

    my $output;
    my $res = $self->_tt2->process(
        $self->template->stringify, {
            data      => $self,
            rpm_date  => DateTime->now->strftime('%a %b %d %Y'),
            middle => join("\n", @{$self->middle}),
        },
        \$output,
    );

     die $self->_tt2->error . "\n" unless $res;
     return $output;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools::SpecData::New - Data to update a specfile

=head1 DESCRIPTION

This package extends L<Fedora::App::MaintainerTools::SpecData> to gather data
from the CPAN (and a dist's META.yml) to update a RPM specfile.

=head1 ATTRIBUTES

We define the additional attributes: ...

=head2 description

=head1 SEE ALSO

L<Fedora::App::MaintainerTools>, L<Fedora::App::MaintainerTools::SpecData>,
L<CPANPLUS::Dist::RPM>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut

