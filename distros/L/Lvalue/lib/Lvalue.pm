package Lvalue;
    use warnings;
    use strict;
    use Carp;
    use Scalar::Util qw/reftype/;
    require overload;
    require Exporter;
    our @ISA = 'Exporter';
    our %EXPORT_TAGS = (all => [
      our @EXPORT_OK = qw/wrap lvalue unwrap rvalue/
    ]);
    our $VERSION = '0.21';

=head1 NAME

Lvalue - add lvalue getters and setters to existing objects

=head1 VERSION

version 0.21

=head1 SYNOPSIS

Lvalue takes an object produced by some other package and wraps it with lvalue
functionality implemented with the object's original getter and setter routines.
Lvalue assumes its object uses the relatively standard getter / setter idiom
where any arguments is a setter, and no arguments is a getter.

By wrapping an existing object's getters and setters, Lvalue gives you the
syntactic niceties of lvalues, without the inherent encapsulation violations of
the :lvalue subroutine attribute.

    my $obj = NormalObject->new();

    $obj->value(5);

    print $obj->value(); # prints 5

    use Lvalue;

    Lvalue->wrap( $obj );

    $obj->value = 10;

    print $obj->value;   # prints 10

    $_ += 2 for $obj->value;

    print $obj->value;   # prints 12

=head1 EXPORT

this module does not export anything by default but can export the functions
below (which can all also be called as methods of Lvalue)

    use Lvalue qw/lvalue/; # or 'wrap', also 'unwrap'/'rvalue'

    lvalue my $obj = SomePackage->new;

    $obj->value = 5;

    Lvalue->unwrap( $obj );

    $obj->value = 6; # dies

=head1 FUNCTIONS

=over 4

=cut

    sub overload {
        my ($object, $proxy) = @_;
        my $pkg = ref $object;
        my $overloader = sub {
            my $op = shift;
            sub {
                if (my $sub = overload::Method($pkg, $op)) {
                    @_ = ($object, @_[1, 2]);
                    goto &$sub;
                }
                Carp::croak "no overload method '$op' in $pkg";
            }
        };
        no strict 'refs';
        my $fallback = ${$pkg.'::()'};

        my $overload = join ', ' =>
            defined $fallback ? 'fallback => $fallback' : (),
            map "'$_' => \$overloader->('$_')" =>
                grep s/^\((?=..)// => keys %{$pkg.'::'};

        eval qq {package $proxy;
            our \@ISA = 'Lvalue::Loader';
            use overload $overload;
        } or Carp::carp "Lvalue: overloading not preserved for $pkg, "
                      . "bug reports or patches welcome.\n  $@";
    }

=item C<wrap OBJECT>

=item C<lvalue OBJECT>

wrap an object with lvalue getters / setters

    my $obj = Lvalue->wrap( SomePackage->new );

or in a constructor:

    sub new {
        my $class = shift;
        my $self  = {@_};
        Lvalue->wrap( bless $self => $class );
    }

in void context, an in-place modification is done:

    my $obj = SomePackage->new;

    Lvalue->wrap( $obj );

    $obj->value = 5;

the alias C< lvalue > is provided for C< wrap > which when you export it as a
function, can lead to some nice code:

    use NormalObject;
    use Lvalue 'lvalue';

    lvalue my $obj = NormalObject->new;

    $obj->value = 5;

=cut
    {my $num = 0;
    sub wrap {
        my ($object, $proxy) = ($_[$#_], 'Lvalue::Loader');

        if (overload::Overloaded $object) {
            overload $object
                  => $proxy = 'Lvalue::Loader::_' . $num++
        }
        bless my $wrapped = \$object => $proxy;
        defined wantarray
            ? $wrapped
            : $_[$#_] = $wrapped
    }}


=item C<unwrap LVALUE_OBJECT>

=item C<rvalue LVALUE_OBJECT>

returns the original object

=cut

    sub unwrap {
        my $wrapped = $_[$#_];

        croak "unwrap only takes objects wrapped by this module"
            unless (ref $wrapped) =~ /^Lvalue::Loader (?: ::_\d )? $/x;

        defined wantarray
            ? $$wrapped
            : $_[$#_] = $$wrapped
    }

    BEGIN {
        *lvalue = \&wrap;
        *rvalue = \&unwrap;
    }

    my $no = sub {
        local $Carp::CarpLevel = 1;
        Carp::croak "no method '$_[1]' on '$_[0]'"
    };

{package
    Lvalue::Loader;
    sub AUTOLOAD :lvalue {
        die unless (my $method) = our $AUTOLOAD =~ /([^:]+)$/;
        my $object = ${+shift};

        if ($method eq 'DESTROY') {
            $object->DESTROY if $object->can('DESTROY');
            return
        }
        if (@_ or not defined wantarray) {
            unshift @_, $object;
            goto &{$object->can($method)
              or   $object->$no($method)}
        }
        tie my $tied => 'Lvalue::Tied', [$object, $method];
        $tied
    }

    for my $method qw(can isa DOES VERSION) {
        no strict 'refs';
        *$method = sub {
            my $object = ${+shift};
            unshift @_, $object;
            goto &{$object->can($method)
              or   $object->$no($method)}
        }
    }
}

{package
    Lvalue::Tied;
    use Carp;
    sub TIESCALAR {bless pop}
    sub STORE {
        my ($object, $method) = @{$_[0]};
        splice @_, 0, 1, $object;

        goto &{$object->can($method)
          or   $object->$no($method)}
    }
    BEGIN {*FETCH = \&STORE}
}

=back

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

special care is taken to ensure that overloaded objects still work properly.
if you encounter an error please let me know.

Please report any bugs or feature requests to C<bug-lvalue at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lvalue>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Eric Strom.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__ if 'first require'
