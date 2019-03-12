package Function::Interface;

use v5.14.0;
use warnings;

our $VERSION = "0.02";

use Carp qw(croak confess);
use Keyword::Simple;
use PPR;

use Function::Interface::Info;
use Function::Interface::Info::Function;
use Function::Interface::Info::Function::Param;
use Function::Interface::Info::Function::ReturnParam;

sub import {
    my $class = shift;
    my %args = @_;

    my $pkg = $args{pkg} ? $args{pkg} : caller;

    Keyword::Simple::define 'fun' => _define_interface($pkg, 'fun');
    Keyword::Simple::define 'method' => _define_interface($pkg, 'method');
}

sub unimport {
    Keyword::Simple::undefine 'fun';
    Keyword::Simple::undefine 'method';
}

sub _define_interface {
    my ($pkg, $keyword) = @_;

    return sub {
        my $ref = shift;

        my $match = _assert_valid_interface($$ref);
        my $src = _render_src($pkg, $keyword, $match);

        substr($$ref, 0, length $match->{statement}) = $src;
    }
}

sub _render_src {
    my ($pkg, $keyword, $match) = @_;

    my $src = <<"```";
Function::Interface::_register_info({
    package => '$pkg',
    keyword => '$keyword',
    subname => '$match->{subname}',
    params  => [ @{[ join ',', map {
        my $named    = $_->{named} ? 1 : 0;
        my $optional = $_->{optional} ? 1 : 0;

        qq!{ type => $_->{type}, name => '$_->{name}', named => $named, optional => $optional }!
    } @{$match->{params}} ]} ],
    return  => [ @{[ join ',', @{$match->{return}}] } ],
});
```
    return $src;
}

our %metadata;
sub _register_info {
    my ($args) = @_;

    push @{$metadata{$args->{package}}} => +{
        subname => $args->{subname},
        keyword => $args->{keyword},
        params  => $args->{params},
        return  => $args->{return},
    };
}

sub info {
    my ($interface_package) = @_;
    my $info = $metadata{$interface_package} or return undef;

    Function::Interface::Info->new(
        package   => $interface_package,
        functions => [ map {
            Function::Interface::Info::Function->new(
                subname => $_->{subname},
                keyword => $_->{keyword},
                params  => [ map { _make_function_param($_) } @{$_->{params}} ],
                return  => [ map { _make_function_return_param($_) } @{$_->{return}} ],
            )
        } @{$info}],
    );
}

sub _make_function_param {
    my $param = shift;
    Function::Interface::Info::Function::Param->new(
        type    => $param->{type},
        name    => $param->{name},
        named   => $param->{named},
        optinal => $param->{optional},
    )
}

sub _make_function_return_param {
    my $type = shift;
    Function::Interface::Info::Function::ReturnParam->new(
        type => $type,
    )
}

sub _assert_valid_interface {
    my $src = shift;

    $src =~ m{
        \A
        (?<statement>
            (?&PerlOWS) (?<subname>(?&PerlIdentifier))
            (?&PerlOWS) \((?<params>.*?)\)
            (?&PerlOWS) :Return\((?<return>.*?)\)
            ;
        )
        $PPR::GRAMMAR
    }sx or croak "Invalid interface";

    my %match;
    $match{statement} = $+{statement};
    $match{subname} = $+{subname};
    $match{params}  = $+{params} ? _assert_valid_interface_params($+{params}) : [];
    $match{return}  = $+{return} ? _assert_valid_interface_return($+{return}) : [];

    return \%match;
}

sub _assert_valid_interface_params {
    my $src = shift;

    my @list = grep { defined } $src =~ m{
        ((?&type))         (?&PerlOWS)
        ((?&named))        (?&PerlOWS)
        ((?&PerlVariable)) (?&PerlOWS)
        ((?&optional))

        (?(DEFINE)
            (?<type> (?&PerlIdentifier) | (?&PerlCall) )
            (?<named> :? )
            (?<optional> =? )
        )

        $PPR::GRAMMAR
    }sxg;

    my @params;
    while (my @items = splice @list, 0, 4) {
        confess "invalid param: @items. It should be TYPE VAR."
            unless (@items == 4);

        push @params => {
            type     => $items[0],
            named    => !!$items[1],
            name     => $items[2],
            optional => !!$items[3],
        }
    }
    return \@params;
}

sub _assert_valid_interface_return {
    my $src = shift;

    my @list = grep { defined } $src =~ m{
        ((?&type))

        (?(DEFINE)
            (?<type> (?&PerlIdentifier) | (?&PerlCall) )
        )

        $PPR::GRAMMAR
    }sxg;

    confess "invalid return type: $src. It should be TYPELIST."
        if $src && !@list;

    return \@list;
}

1;
__END__

=encoding utf-8

=head1 NAME

Function::Interface - specify type constraints of subroutines

=head1 SYNOPSIS

    package IFoo {
        use Function::Interface;
        use Types::Standard -types;

        fun hello(Str $msg) :Return(Str);
    }

and implements interface class:

    package Foo {
        use Function::Interface::Impl qw(IFoo);

        use Function::Parameters;
        use Function::Return;
        use Types::Standard -types;

        fun hello(Str $msg) :Return(Str) {
            return "HELLO $msg";
        }
    }


=head1 DESCRIPTION

Function::Interface provides Interface like Java and checks the arguments and return type of the function at compile time.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

