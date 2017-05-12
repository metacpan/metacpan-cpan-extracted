package LIVR::Contract::Exception;

use strict;
use warnings;

use Carp;
use Data::Dumper;

our @CARP_NOT = (__PACKAGE__, 'LIVR::Contract');

use overload
    'bool'   => sub {1},
    '~~'     => sub { $_[0]->isa($_[1]) },
    '""'     => sub { $_[0]->to_string },
    fallback => 1;


sub new {
    my ($class, %args) = @_;

    local $Carp::Internal{ (__PACKAGE__) } = 1;

    return bless {
        type     => $args{type},
        errors   => $args{errors},
        package  => $args{package},
        subname  => $args{subname},
        longmess => Carp::longmess(),
    }, $class;
}

sub type {
    return shift->{type};
}

sub errors {
    return shift->{errors};
}

sub package {
    return shift->{package};
}

sub subname {
    return shift->{subname};
}

sub longmess {
    return shift->{longmess};
}

sub to_string {
    my $self = shift;

    local $Data::Dumper::Indent = 0;
    my $errors_str = Data::Dumper->Dump([$self->errors], ['errors']);

    return  "Wrong $self->{type} in package=[$self->{package}] subname=[$self->{subname}]. $errors_str";
}

1;
