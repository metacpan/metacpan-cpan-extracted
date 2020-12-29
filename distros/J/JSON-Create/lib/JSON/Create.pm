package JSON::Create;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/create_json create_json_strict/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
our $VERSION = '0.29';

# Are we running as XS?

our $noxs;

# The environment variable JSONCreatePP controls whether this runs as
# XS or purely Perl.

$noxs = $ENV{JSONCreatePP};

# Did the XS load OK?

our $xsok;

if (! $noxs) {
    eval {
	require XSLoader;
	XSLoader::load ('JSON::Create', $VERSION);
	$xsok = 1;
    };
    if ($@) {
	$xsok = 0;
    }
}

if (! $xsok || $noxs) {
    require JSON::Create::PP;
    JSON::Create::PP->import (':all');
}

sub set_fformat
{
    my ($obj, $fformat) = @_;
    if (! $fformat) {
	$obj->set_fformat_unsafe (0);
	return;
    }
    if ($fformat =~ /^%(?:(?:([0-9]+)?(?:\.([0-9]+)?)?)?[fFgGeE])$/) {
	my $d1 = $1;
	my $d2 = $2;
	if ((defined ($d1) && $d1 > 20) || (defined ($d2) && $d2 > 20)) {
	    warn "Format $fformat is too long";
	    $obj->set_fformat_unsafe (0);
	}
	else {
	    $obj->set_fformat_unsafe ($fformat);
	}
    }
    else {
	warn "Format $fformat is not OK for floating point numbers";
	$obj->set_fformat_unsafe (0);
    }
}

sub bool
{
    my ($obj, @list) = @_;
    my $handlers = $obj->get_handlers ();
    for my $item (@list) {
	$handlers->{$item} = 'bool';
    }
}

sub obj
{
    my ($obj, %handlers) = @_;
    my $handlers = $obj->get_handlers ();
    for my $item (keys %handlers) {
	my $value = $handlers{$item};
	# Check it's a code reference somehow.
	$handlers->{$item} = $value;
    }
}

sub del
{
    my ($obj, @list) = @_;
    my $handlers = $obj->get_handlers ();
    for my $item (@list) {
	delete $handlers->{$item};
    }
}

sub validate
{
    my ($obj, $value) = @_;
    if ($value) {
	require JSON::Parse;
	JSON::Parse->import ('assert_valid_json');
    }
    $obj->set_validate ($value);
}

sub set
{
    my ($jc, %args) = @_;
    for my $k (keys %args) {
	my $value = $args{$k};

	# Options are in alphabetical order

	if ($k eq 'bool') {
	    $jc->bool (@$value);
	    next;
	}
	if ($k eq 'cmp') {
	    $jc->cmp ($value);
	    next;
	}
	if ($k eq 'downgrade_utf8') {
	    $jc->downgrade_utf8 ($value);
	    next;
	}
	if ($k eq 'escape_slash') {
	    $jc->escape_slash ($value);
	    next;
	}
	if ($k eq 'fatal_errors') {
	    $jc->fatal_errors ($value);
	    next;
	}
	if ($k eq 'indent') {
	    $jc->indent ($value);
	    next;
	}
	if ($k eq 'no_javascript_safe') {
	    $jc->no_javascript_safe ($value);
	    next;
	}
	if ($k eq 'non_finite_handler') {
	    $jc->non_finite_handler ($value);
	    next;
	}
	if ($k eq 'obj_handler') {
	    $jc->obj_handler ($value);
	    next;
	}
	if ($k eq 'replace_bad_utf8') {
	    $jc->replace_bad_utf8 ($value);
	    next;
	}
	if ($k eq 'sort') {
	    $jc->sort ($value);
	    next;
	}
	if ($k eq 'strict') {
	    $jc->strict ($value);
	    next;
	}
	if ($k eq 'unicode_upper') {
	    $jc->unicode_upper ($value);
	    next;
	}
	if ($k eq 'validate') {
	    $jc->validate ($value);
	    next;
	}
	warn "Unknown option '$k'";
    }
}

sub new
{
    my ($class, %args) = @_;
    my $jc;
    if ($xsok) {
	$jc = bless jcnew (), $class;
    }
    else {
	$jc = JSON::Create::PP->new ();
    }
    # "set" is pure perl, and this JSON::Create:: prefix makes the
    # following work in either PP or XS mode.
    JSON::Create::set ($jc, %args);
    return $jc;
}

sub create_json
{
    my ($obj, %args) = @_;
    my $jc = JSON::Create->new (%args);
    return $jc->run ($obj);
}

sub create_json_strict
{
    my ($obj, %args) = @_;
    $args{strict} = 1;
    my $jc = JSON::Create->new (%args);
    return $jc->run ($obj);
}

1;

