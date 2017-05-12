package Marathon::Remote;

use strict;
use warnings;

sub _bail {
    die "cannot manipulate unproperly initialised Marathon::Remote object (App or Group). Make sure to pass in an instance of Marathon when calling Marathon::App/Group->new(\$conf, \$parent)";
}

sub id {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{id} = $val;
    }
    return $self->{data}->{id};
}

sub version {
    my $self = shift;
    return $self->{data}->{version};
}

sub dependencies {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{dependencies} = $val;
    }
    return $self->{data}->{dependencies};
}


1;
