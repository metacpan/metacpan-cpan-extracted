package JIP::ClassField;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);
use English qw(-no_match_vars);

our $VERSION = '0.05';

my $maybe_set_subname = sub { $ARG[1]; };

# Supported on Perl 5.22+
eval {
    require Sub::Util;

    if (my $set_subname = Sub::Util->can('set_subname')) {
        $maybe_set_subname = $set_subname;
    }
};

sub attr {
    my ($self, $attr, %param) = @ARG;

    my $class = ref $self || $self;

    croak q{Class not defined}
        unless defined $class && length $class;

    croak q{Attribute not defined}
        unless defined $attr && length $attr;

    my @patches;

    for my $each_attr (@{ ref $attr eq 'ARRAY' ? $attr : [$attr] }) {
        croak sprintf(q{Attribute "%s" invalid}, $each_attr)
            unless $each_attr =~ m{^[a-zA-Z_]\w*$}x;

        my %patch;

        $patch{_define_name_of_getter($each_attr, \%param)} = sub {
            my $self = shift;
            return $self->{$each_attr};
        };

        {
            my $method_name = _define_name_of_setter($each_attr, \%param);

            if (exists $param{'default'}) {
                my $default_value = $param{'default'};

                $patch{$method_name} = sub {
                    my $self = shift;

                    if (@ARG == 1) {
                        $self->{$each_attr} = shift;
                    }
                    else {
                        $self->{$each_attr} = ref($default_value) eq 'CODE' ?
                            $default_value->($self) : $default_value;
                    }

                    return $self;
                };
            }
            else {
                $patch{$method_name} = sub {
                    my ($self, $value) = @ARG;
                    $self->{$each_attr} = $value;
                    return $self;
                };
            }
        }

        push @patches, \%patch;
    }

    monkey_patch($class, %{ $_ }) for @patches;
}

sub monkey_patch {
    my ($class, %patch) = @ARG;

    no strict 'refs';
    no warnings 'redefine';

    while (my ($method_name, $value) = each %patch) {
        my $full_name = $class .q{::}. $method_name;

        *{$full_name} = $maybe_set_subname->($full_name, $value);
    }

    return 1;
}

sub cleanup_namespace {
    my @names  = @ARG;
    my $caller = caller;

    no strict 'refs';
    my $ref = \%{ $caller .'::' };

    map { delete $ref->{$_} } @names;

    return 1;
}

sub import {
    my $caller = caller;

    return monkey_patch($caller, 'has', sub { attr($caller, @ARG) });
}

sub _define_name_of_getter {
    my ($attr, $param) = @ARG;

    my $method_name;

    if (exists $param->{'get'}) {
        my $getter = $param->{'get'};

        if ($getter eq q{+}) {
            $method_name = $attr;
        }
        elsif ($getter eq q{-}) {
            $method_name = q{_}. $attr;
        }
        else {
            $method_name = $getter;
        }
    }
    else {
        $method_name = $attr;
    }

    return $method_name;
}

sub _define_name_of_setter {
    my ($attr, $param) = @ARG;

    my $method_name;

    if (exists $param->{'set'}) {
        my $setter = $param->{'set'};

        if ($setter eq q{+}) {
            $method_name = q{set_}. $attr;
        }
        elsif ($setter eq q{-}) {
            $method_name = q{_set_}. $attr;
        }
        else {
            $method_name = $setter;
        }
    }
    else {
        $method_name = q{set_}. $attr;
    }

    return $method_name;
}

1;

__END__

=head1 NAME

JIP::ClassField - Create attribute accessor for hash-based objects

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Test::More;
    use JIP::ClassField;

    my $self = bless {}, __PACKAGE__;

    # Public access
    has foo => (get => '+', set => '+');
    is($self->set_foo(42)->foo, 42);

    # or
    has 'foo';
    is($self->set_foo(42)->foo, 42);


    # Private access
    has bar => (get => '-', set => '-');
    is($self->_set_bar(42)->_bar, 42);


    # Declaring multiple attributes in a single declaration
    has [qw(tratata ololo)] => (get => '+', set => '+');


    # Methods with user defined names
    has wtf => (get => 'wtf_getter', set => 'wtf_setter');
    is($self->wtf_setter(42)->wtf_getter, 42);


    # Pass an optional first argument of setter to set
    # a default value, it should be a constant or callback.
    has baz => (get => '+', set => '+', default => 42);
    is($self->set_baz->baz, 42);


    has qux => (get => '+', set => '+', default => sub {
        my $self = shift;
        return $self->baz;
    });
    is($self->set_qux->qux, 42);


    JIP::ClassField::cleanup_namespace('has');
    ok(not __PACKAGE__->can('has'));


    done_testing();

=head1 SEE ALSO

Class::Accessor and Mojo::Base.

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Vladimir Zhavoronkov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


