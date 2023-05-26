package JIP::Mock::Control;

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars);
use Scalar::Util qw(reftype blessed);

use JIP::Mock::Event;

our $VERSION = 'v0.0.4';

sub new {
    my ( $class, %param ) = @ARG;

    if ( my $error = $class->_validate(%param) ) {
        croak 'Cannot instantiate: ' . $error;
    }

    return $class->_instantiate(%param);
}

sub package { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self) = @ARG;

    return $self->{package};
}

sub want_array {
    my ($self) = @ARG;

    return $self->{want_array};
}

sub times { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self) = @ARG;

    return $self->{times};
}

sub events {
    my ($self) = @ARG;

    my @events = map { $self->_extract_event_state($_) } @{ $self->_events() };

    return \@events;
}

sub override {
    my ( $self, %pair ) = @ARG;

    my @pairs;
    foreach my $name ( sort keys %pair ) {
        my $new_sub = $pair{$name};

        if ( my $error = $self->_validate_overriding( $name, $new_sub ) ) {
            croak 'Cannot override: ' . $error;
        }

        push @pairs, [ $name, $new_sub ];
    }

    foreach my $pair (@pairs) {
        my ( $name, $new_sub ) = @{$pair};

        $self->_override( $name, $new_sub );
    }

    return;
} ## end sub override

sub call_original {
    my ( $self, $name, @arguments ) = @ARG;

    if ( my $error = $self->_validate_call_original($name) ) {
        croak 'Cannot call original: ' . $error;
    }

    my $want_array   = wantarray;
    my $original_sub = $self->_get_original($name);

    # void context
    if ( !defined $want_array ) {
        $original_sub->(@arguments);

        return;
    }

    # is looking for a list value
    elsif ($want_array) {
        my @results = $original_sub->(@arguments);

        return @results;
    }

    # is looking for a scalar
    else {
        my $result = $original_sub->(@arguments);

        return $result;
    }
} ## end sub call_original

sub called {
    my ($self) = @ARG;

    return 1 if keys %{ $self->times() };
    return 0;
}

sub not_called {
    my ($self) = @ARG;

    return 1 if !$self->called();
    return 0;
}

sub DESTROY {
    my ($self) = @ARG;

    $self->_restore_all();

    return;
}

sub _validate {
    my ( undef, %param ) = @ARG;

    my $package = $param{package};

    return 'package name is not present!' if !length $package;

    return if _is_package_loaded($package);

    return sprintf 'package "%s" is not loaded!', $package;
}

sub _validate_overriding {
    my ( $self, $name, $new_sub ) = @ARG;

    return 'name is not present!' if !length $name;

    if ( !$self->package->can($name) ) {
        return sprintf 'cannot override non-existent sub "%s"!', $name;
    }

    if ( !$new_sub ) {
        return sprintf 'new sub of "%s" is not present!', $name;
    }

    return if _is_coderef($new_sub);

    return sprintf 'new sub of "%s" is not CODE reference!', $name;
}

sub _validate_call_original {
    my ( $self, $name ) = @ARG;

    return 'name is not present!' if !length $name;

    return if $self->_get_original($name);

    return sprintf 'cannot find sub "%s" by name!', $name;
}

sub _instantiate {
    my ( $class, %param ) = @ARG;

    return bless(
        {
            package    => $param{package},
            want_array => $param{want_array},
            originals  => {},
            times      => {},
            events     => [],
        },
        $class,
    );
}

sub _events {
    my ($self) = @ARG;

    return $self->{events};
}

sub _originals {
    my ($self) = @ARG;

    return $self->{originals};
}

sub _get_original {
    my ( $self, $name ) = @ARG;

    my $originals = $self->_originals();

    my $original_sub = $originals->{$name};

    return $original_sub;
}

sub _add_original {
    my ( $self, $name, $original_sub ) = @ARG;

    my $originals = $self->_originals();

    return if exists $originals->{$name};

    $originals->{$name} = $original_sub;

    return;
}

sub _delete_original {
    my ( $self, $name ) = @ARG;

    my $originals = $self->_originals();

    return delete $originals->{$name};
}

sub _override {
    my ( $self, $name, $new_sub ) = @_;

    $self->_collect_original($name);

    my $new_sub_wrapper = $self->_init_wrapper( $name, $new_sub );

    $self->_monkey_patch( $name, $new_sub_wrapper );

    return;
}

sub _collect_original {
    my ( $self, $name ) = @ARG;

    return if $self->_get_original($name);

    my $original_sub = $self->package->can($name);

    $self->_add_original( $name, $original_sub );

    return;
}

sub _init_wrapper {
    my ( $self, $name, $new_sub ) = @ARG;

    return sub {
        my @arguments  = @ARG;
        my $want_array = wantarray;

        if ( my $first_argument = $arguments[0] ) {
            my $package = $self->package();

            #<<< no perltidy
            my $is_class_or_object = (
                ( $first_argument eq $package )
                || ( ( blessed($first_argument) // q{} ) eq $package )
            );
            #>>>

            if ($is_class_or_object) {
                shift @arguments;
            }
        }

        my %event = (
            method    => $name,
            arguments => \@arguments,
            times     => $self->_increment_times($name),
        );

        if ( $self->want_array() ) {
            $event{want_array} = $want_array;
        }

        my $event = JIP::Mock::Event->new(%event);

        $self->_collect_event($event);

        # void context
        if ( !defined $want_array ) {
            $new_sub->($event);

            return;
        }

        # is looking for a list value
        elsif ($want_array) {
            my @results = $new_sub->($event);

            return @results;
        }

        # is looking for a scalar
        else {
            my $result = $new_sub->($event);

            return $result;
        }
    };
} ## end sub _init_wrapper

sub _monkey_patch {
    my ( $self, $name, $sub ) = @ARG;

    my $target = $self->package() . q{::} . $name;

    no strict 'refs';       ## no critic (ProhibitNoStrict)
    no warnings 'redefine'; ## no critic (TestingAndDebugging::ProhibitNoWarnings)

    *{$target} = $sub;

    return;
}

sub _restore_all {
    my ($self) = @ARG;

    my $originals = $self->_originals();

    foreach my $name ( sort keys %{$originals} ) {
        $self->_restore($name);
    }

    return;
}

sub _restore {
    my ( $self, $name ) = @ARG;

    my $original_sub = $self->_delete_original($name);

    $self->_monkey_patch( $name, $original_sub );

    return;
}

sub _increment_times {
    my ( $self, $name ) = @ARG;

    my $times = $self->times();

    my $count = $times->{$name};

    $count //= 0;

    $count += 1;

    $times->{$name} = $count;

    return $count;
}

sub _collect_event {
    my ( $self, $event ) = @ARG;

    push @{ $self->_events() }, $event;

    return;
}

sub _extract_event_state {
    my ( $self, $event ) = @ARG;

    my %state = (
        method    => $event->method(),
        arguments => $event->arguments(),
    );

    if ( $self->want_array() ) {
        $state{want_array} = $event->want_array();
    }

    return \%state;
}

sub _is_coderef {
    my ($sub) = @ARG;

    my $reftype = reftype($sub);

    $reftype //= q{};

    return 1 if $reftype eq 'CODE';
    return 0;
}

sub _is_package_loaded {
    my ($package) = @ARG;

    $package .= q{::};

    no strict 'refs'; ## no critic (ProhibitNoStrict)

    return 1 if %{$package};
    return 0;
}

1;

__END__

=head1 NAME

JIP::Mock::Control - Override subroutines in a module

=head1 VERSION

This document describes L<JIP::Mock::Control> version C<v0.0.4>.

=head1 SYNOPSIS

Testing module:

    use JIP::Mock::Control;

    # 42
    TestMe::tratata();

    my $control = JIP::Mock::Control->new( package => 'TestMe' );

    $control->override(
        tratata => sub {
            return 24;
        },
    );

    # 24
    TestMe::tratata();

    # { tratata => 1 }
    $control->times();

    # [
    #     { method => 'tratata', arguments => [] }
    # ]
    $control->events();

    undef $control;

    # 42
    TestMe::tratata();

Testing class:

    use JIP::Mock::Control;

    # 42
    $sut->tratata();

    my $control = JIP::Mock::Control->new( package => 'TestMe' );

    $control->override(
        tratata => sub {
            return 24;
        },
    );

    # 24
    $sut->tratata();

    # { tratata => 1 }
    $control->times();

    # [
    #     { method => 'tratata', arguments => [] }
    # ]
    $control->events();

    undef $control;

    # 42
    $sut->tratata();

When want_array is turning on:

    use JIP::Mock::Control;

    my $control = JIP::Mock::Control->new( package => 'TestMe', want_array => 1 );

    $control->override(
        tratata => sub {
            return 24;
        },
    );

    # 24
    $sut->tratata();

    # [
    #     { method => 'tratata', arguments => [], want_array => undef }
    # ]
    $control->events();

FizzBuzz example:

    use JIP::Mock::Control;

    my $control = JIP::Mock::Control->new( package => 'TestMe' );

    $control->override(
        tratata => sub {
            my ($event) = @_;

            my $times = $event->times();

            return 'Fizz' if $times % 3 == 0;
            return 'Buzz' if $times % 5 == 0;
            return $times;
        },
    );

    # 1
    $sut->tratata();

    # 2
    $sut->tratata();

    # Fizz
    $sut->tratata();

    # 4
    $sut->tratata();

    # Buzz
    $sut->tratata();

=head1 ATTRIBUTES

L<JIP::Mock::Control> implements the following attributes.

=head2 package

    $string = $control->package();

Get the name of the package controlled by this object.

=head2 events

    $arrayref = $control->events();

Returns an array of all the calls to the mocked module.

=head2 times

    $hashref = $control->times();

Returns a hash where keys are method names, and values are the number of times the method has been called.

=head2 want_array

    $bool = $control->want_array();

Track (or not track) invocation context. Disabled by default.

=head1 SUBROUTINES/METHODS

=head2 new

    $control = JIP::Mock::Control->new();

Build new L<JIP::Mock::Control> object.

=head2 override

    $control->override( name => sub { ... } );

Temporarily replaces one or more subroutines in the mocked module.

=head2 call_original

    $control->call_original( 'name', @arguments );

Calls the original (unmocked) subroutine.

=head2 called

    $bool = $control->called();

Returns true if C<times> returns non-empty hash.

=head2 not_called

    $bool = $control->not_called();

Returns true if C<times> returns an empty hash.

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

Perl 5.10.1 or later.

=head1 CONFIGURATION AND ENVIRONMENT

L<JIP::Mock::Control> requires no configuration files or environment variables.

=head1 SEE ALSO

L<Mock::Quick>, L<Test::MockModule>, L<Test::MockClass>, L<Test::MockObject>

=head1 AUTHOR

Volodymyr Zhavoronkov, C<< <flyweight at yandex dot ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Volodymyr Zhavoronkov.

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


