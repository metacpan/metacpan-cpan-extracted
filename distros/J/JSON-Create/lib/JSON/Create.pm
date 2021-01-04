package JSON::Create;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/create_json create_json_strict write_json/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
our $VERSION = '0.30';

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
    $jc->set (%args);
    return $jc;
}

sub write_json
{
    my ($filename, $obj, %options) = @_;
    my $json = create_json ($obj, %options);
    # create_json's output is either ASCII or it is marked as utf8, so
    # the following is always safe.
    my $encoding = ':encoding(utf8)';
    if ($options{downgrade_utf8}) {
	$encoding = ':raw';
    }
    open my $out, ">$encoding", $filename or die $!;
    print $out $json;
    close $out or die $!;
}

1;

