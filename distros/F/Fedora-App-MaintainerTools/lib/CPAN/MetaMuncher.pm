#############################################################################
#
# Digest a META.yml so we can get at the good parts easily :)
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 05/11/2009 11:32:18 PM PDT
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package CPAN::MetaMuncher;

use Moose;

use MooseX::AttributeHelpers;
use MooseX::Types::Path::Class ':all';

use Path::Class;
use JSON;
use YAML::Tiny;

use namespace::clean -except => 'meta';

our $VERSION = '0.006';

# debugging
#use Smart::Comments '###', '####';

has module => (is => 'rw', required => 1, isa => 'CPANPLUS::Module');

# FIXME -- we should check to make sure we're supported, etc, etc
#has _meta => (is => 'ro', isa => 'YAML::Tiny', lazy_build => 1);
#has _meta => (is => 'ro', isa => 'ArrayRef[HashRef]|YAML::Tiny', lazy_build => 1);
has _meta => (is => 'ro', lazy_build => 1);

sub _build__meta {
    my $self = shift @_;

    $self->module->fetch;
    my $meta_file = file $self->module->extract, 'META.yml';
    #YAML::Tiny->read(file($self->module->extract, 'META.yml'));
    my $m;
    local $@;
    eval { $m = YAML::Tiny->read(file($self->module->extract, 'META.yml'))     };
    warn "Eval error (yaml::tiny): $@" if $@;
    #return $m if defined $m;
    return $m unless $@;
    eval { $m = from_json(file($self->module->extract, 'META.yml')->slurp) };

    # FIXME we really should just drop the indexing above.  sigh.
    return [ $m ] if defined $m;
    die "Eval error reading META: $@";
}

sub data { shift->_meta->[0] }

# simple

has version => (is => 'rw', isa => 'Str', lazy_build => 1);

sub _build_version { shift->_meta->[0]->{version} }

# complex

has _rpm_build_requires => (
    metaclass => 'Collection::ImmutableHash',

    is         => 'ro',
    isa        => 'HashRef[Str]',
    lazy_build => 1,

    provides => {
        #'' => '_rpm_build_requires',
        'count'  => 'num_rpm_build_requires',
        'empty'  => 'has_any_rpm_build_requires',
        'exists' => 'has_rpm_br_on',
        'keys'   => 'rpm_build_requires',
        'get'    => 'rpm_build_require_version',
        'kv'     => 'rpm_build_requires_kv_pairs',

        elements => 'full_rpm_build_requires',
    },
);

sub _build__rpm_build_requires {
    shift->_rpm_requires_from_meta_keys(
        qw(requires configure_requires build_requires)
    );
}

has _rpm_requires => (
    metaclass => 'Collection::ImmutableHash',

    is         => 'ro',
    isa        => 'HashRef[Str]',
    lazy_build => 1,

    provides => {
        #'' => '_rpm_build_requires',
        'count'  => 'num_rpm_requires',
        'empty'  => 'has_rpm_requires',
        'exists' => 'has_rpm_require_on',
        'keys'   => 'rpm_requires',
        'get'    => 'rpm_require_version',
        'kv'     => 'rpm_requires_kv_pairs',

        elements => 'full_rpm_requires',
    },
);

sub _build__rpm_requires {
    shift->_rpm_requires_from_meta_keys('requires')
}

sub _rpm_requires_from_meta_keys {
    my $self = shift @_;
    my @keys = @_;

    my %req = ();
    BR_LOOP:
    for my $key (@keys) {

        next BR_LOOP unless exists $self->_meta->[0]->{$key};
        my %more = %{ $self->_meta->[0]->{$key} };
        $req{"perl($_)"} = $more{$_} foreach keys %more;
        #%req = (%req, %more);
    }

    # until we figure out what to do with this...
    do{ delete $req{"perl($_)"} if exists $req{"perl($_)"} }
        foreach qw{ perl strict warnings overload attributes };

    ### %req
    return \%req;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

CPAN::MetaMuncher - Digest a META.yml

=head1 SYNOPSIS

    use CPAN::MetaMuncher;

    # ...
    my $mm = CPAN::MetaMuncher->new(module => $cpanplus_module);


=head1 DESCRIPTION

B<WARNING: This is VERY early code.>

An abstraction layer for META.yml, and possibly others.

=head1 SEE ALSO

L<CPANPLUS::Backend>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

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



