package MARC::Xform;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.02';

sub new {
    my $cls = shift;
    my $self = bless { @_ }, $cls;
    $self->init;
}

sub init { @_ }

sub apply {
    my ($self, $f) = @_;
    my $fh;
    if (ref $f) {
        $fh = $f;
    }
    else {
        open $fh, '<', $f or die "Can't open $f: $!";
    }
}

sub apply_to_record {
    die "Abstract method";
}

1;
