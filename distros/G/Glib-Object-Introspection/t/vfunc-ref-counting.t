#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;
use Scalar::Util;

plan skip_all => 'Need gobject-introspection 1.35.5'
  unless check_gi_version (1, 35, 5);
plan tests => 68;

my @packages = qw/WeakNonFloater WeakFloater StrongNonFloater StrongFloater/;
my %package_to_subclass = (
  WeakNonFloater => 'NonFloatingObjectSubclass',
  WeakFloater => 'FloatingObjectSubclass',
  StrongNonFloater => 'NonFloatingObjectSubclass',
  StrongFloater => 'FloatingObjectSubclass',
);
my %package_to_warner = (
  WeakNonFloater => sub { die $_[0] if -1 == index $_[0], 'Asked to hand out object' },
  WeakFloater => sub { die $_[0] if -1 == index $_[0], 'Asked to hand out object' },
  StrongNonFloater => sub { die $_[0] },
  StrongFloater => sub { die $_[0] },
);
my %package_to_ref_count_offset = (
  WeakNonFloater => 0,
  WeakFloater => 0,
  StrongNonFloater => 1,
  StrongFloater => 1,
);
my %package_to_ref_gone = (
  WeakNonFloater => Glib::TRUE,
  WeakFloater => Glib::TRUE,
  StrongNonFloater => Glib::FALSE,
  StrongFloater => Glib::FALSE,
);
my %package_to_floating = (
  WeakNonFloater => Glib::FALSE,
  WeakFloater => Glib::TRUE,
  StrongNonFloater => Glib::FALSE,
  StrongFloater => Glib::TRUE,
);

# Test that the invocant is not leaked.
foreach my $package (@packages) {
  {
    my $nf = $package->new;
    $nf->get_ref_info_for_vfunc_return_object_transfer_full;
    Scalar::Util::weaken ($nf);
    is ($nf, undef, "no leak for $package");
  }
}

# Test transfer-none&return/out semantics.
foreach my $package (@packages) {
  local $SIG{__WARN__} = $package_to_warner{$package};
  foreach my $method (qw/get_ref_info_for_vfunc_return_object_transfer_none
                         get_ref_info_for_vfunc_out_object_transfer_none/)
  {
    my $nf = $package->new;
    my ($ref_count, $is_floating) = $nf->$method;
    is ($ref_count, 1, "transfer-none&return/out: ref count for $package");
    ok (!$is_floating, "transfer-none&return/out: floating for $package");
  }
}

# Test transfer-full&return/out semantics.
foreach my $package (@packages) {
  foreach my $method (qw/get_ref_info_for_vfunc_return_object_transfer_full
                         get_ref_info_for_vfunc_out_object_transfer_full/)
  {
    my $nf = $package->new;
    my ($ref_count, $is_floating) = $nf->$method;
    is ($ref_count, 1 + $package_to_ref_count_offset{$package},
        "transfer-full&return/out: ref count for $package");
    ok (!$is_floating, "transfer-full&return/out: floating for $package");
    is ($nf->is_ref_gone, $package_to_ref_gone{$package},
        "transfer-full&return/out: ref gone for $package");
  }
}

# Test transfer-none&in semantics.
foreach my $package (@packages) {
  {
    my $nf = $package->new;
    my ($ref_count, $is_floating) =
      $nf->get_ref_info_for_vfunc_in_object_transfer_none ($package_to_subclass{$package});
    TODO: {
      local $TODO = $package =~ /^Weak/
        ? 'ref count test unreliable due to unpredictable behavior of perl-Glib'
        : undef;
      is ($ref_count, 1 + $package_to_ref_count_offset{$package},
          "transfer-none&in: ref count for $package");
    }
    is ($is_floating, $package_to_floating{$package},
        "transfer-none&in: floating for $package");
    is ($nf->is_ref_gone, $package_to_ref_gone{$package},
        "transfer-none&in: ref gone for $package");
  }
}

# Test transfer-full&in semantics.
foreach my $package (@packages) {
  {
    my $nf = $package->new;
    my ($ref_count, $is_floating) =
      $nf->get_ref_info_for_vfunc_in_object_transfer_full ($package_to_subclass{$package});
    TODO: {
      local $TODO = $package =~ /^Weak/
        ? 'ref count test unreliable due to unpredictable behavior of perl-Glib'
        : undef;
      is ($ref_count, 0 + $package_to_ref_count_offset{$package},
          "transfer-full&in: ref count for $package");
    }
    ok (!$is_floating, "transfer-full&in: floating for $package");
    is ($nf->is_ref_gone, $package_to_ref_gone{$package},
        "transfer-full&in: ref gone for $package");
  }
}

# --------------------------------------------------------------------------- #

{
  package NonFloatingObjectSubclass;
  use Glib::Object::Subclass 'Glib::Object';
}

{
  package FloatingObjectSubclass;
  use Glib::Object::Subclass 'Glib::InitiallyUnowned';
}

{
  package Base;
  use Glib::Object::Subclass 'GI::Object';

  sub VFUNC_RETURN_OBJECT_TRANSFER_NONE {
    my ($self) = @_;
    my $o = $self->_create;
    $self->_store ($o);
    return $o;
  }
  sub VFUNC_RETURN_OBJECT_TRANSFER_FULL {
    my ($self) = @_;
    my $o = $self->_create;
    $self->_store ($o);
    return $o;
  }
  sub VFUNC_OUT_OBJECT_TRANSFER_NONE {
    my ($self) = @_;
    my $o = $self->_create;
    $self->_store ($o);
    return $o;
  }
  sub VFUNC_OUT_OBJECT_TRANSFER_FULL {
    my ($self) = @_;
    my $o = $self->_create;
    $self->_store ($o);
    return $o;
  }
  sub VFUNC_IN_OBJECT_TRANSFER_NONE {
    my ($self, $o) = @_;
    $self->_store ($o);
  }
  sub VFUNC_IN_OBJECT_TRANSFER_FULL {
    my ($self, $o) = @_;
    $self->_store ($o);
  }

  sub is_ref_gone {
    my ($self) = @_;
    not defined $self->_retrieve;
  }
}
{
  package WeakNonFloater;
  use Glib::Object::Subclass 'Base';

  sub _create {
    NonFloatingObjectSubclass->new;
  }
  sub _store {
    my ($self, $o) = @_;
    Scalar::Util::weaken ($self->{_ref} = $o);
  }
  sub _retrieve {
    my ($self) = @_;
    $self->{_ref};
  }
}
{
  package WeakFloater;
  use Glib::Object::Subclass 'Base';

  sub _create {
    FloatingObjectSubclass->new;
  }
  sub _store {
    my ($self, $o) = @_;
    Scalar::Util::weaken ($self->{_ref} = $o);
  }
  sub _retrieve {
    my ($self) = @_;
    $self->{_ref};
  }
}
{
  package StrongNonFloater;
  use Glib::Object::Subclass 'Base';

  sub _create {
    NonFloatingObjectSubclass->new;
  }
  sub _store {
    my ($self, $o) = @_;
    $self->{_ref} = $o;
  }
  sub _retrieve {
    my ($self) = @_;
    $self->{_ref};
  }
}
{
  package StrongFloater;
  use Glib::Object::Subclass 'Base';

  sub _create {
    FloatingObjectSubclass->new;
  }
  sub _store {
    my ($self, $o) = @_;
    $self->{_ref} = $o;
  }
  sub _retrieve {
    my ($self) = @_;
    $self->{_ref};
  }
}
