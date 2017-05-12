#!/usr/bin/perl

# This is based on a test case sent to gtk-perl-list by Giuliano.

package ClassFoo;
use strict;
use warnings;
use Glib;

use Glib::Object::Subclass
  Glib::Object::,
  properties => [
    Glib::ParamSpec->boxed('title',
                           'title',
                           'The title',
                           'Glib::Scalar',
                           [qw/writable readable/]),
  ];

sub INIT_INSTANCE {
    my $self = shift;
    $self->{prop_title} = undef;
}

sub SET_PROPERTY {
    my ($self, $pspec, $val) = @_;
    my $propname = $pspec->get_name;
    if ($propname eq 'title') {
        $self->{prop_title} = $val;
    } else {
        die "unknown property ``$propname''";
    }
}

sub GET_PROPERTY {
    my ($self, $pspec) = @_;
    my $propname = $pspec->get_name;
    if ($propname eq 'title') {
        return $self->{prop_title};
    } else {
        die "unknown property ``$propname''";
    }
}

# --------------------------------------------------------------------------- #

package main;
use strict;
use warnings;
use Tie::Hash;
use Test::More tests => 1;

my $hashref = {};
tie %$hashref, 'Tie::StdHash';
$hashref->{Title} = 'foo';

my $w = ClassFoo->new;
$w->set_property ('title', $hashref->{Title});
is ($w->get_property ('title'), $hashref->{Title});
