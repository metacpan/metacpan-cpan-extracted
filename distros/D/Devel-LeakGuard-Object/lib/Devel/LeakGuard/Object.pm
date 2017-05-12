package Devel::LeakGuard::Object;

use 5.008;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Scalar::Util qw( blessed refaddr weaken );

use Devel::LeakGuard::Object::State;

use base qw( Exporter );

our @EXPORT_OK = qw( track leakstate status leakguard );

our %OPTIONS = (
    at_end => 0,
    stderr => 0
);

our ( %DESTROY_NEXT, %DESTROY_ORIGINAL, %DESTROY_STUBBED, %OBJECT_COUNT,
    %TRACKED );

=encoding utf8

=head1 NAME

Devel::LeakGuard::Object - Scoped checks for object leaks

=head1 VERSION

This document describes Devel::LeakGuard::Object version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

  # Track a single object
  use Devel::LeakGuard::Object;
  my $obj = Foo::Bar->new;
  Devel::LeakGuard::Object::track($obj);

  # Track every object
  use Devel::LeakGuard::Object qw( GLOBAL_bless );

  # Track every object, summary at exit
  use Devel::LeakGuard::Object qw( GLOBAL_bless :at_end );

  # Track a block of code, warning on leaks
  leakguard {
      # your potentially leaky code here
  };

  # Track a block of code, die on leaks
  leakguard {
      # your potentially leaky code here
  }
  on_leak => 'die';

=head1 DESCRIPTION

This module provides tracking of objects, for the purpose of
detecting memory leaks due to circular references or innappropriate
caching schemes.

It is derived from, and backwards compatible with Adam Kennedy's
L<Devel::Leak::Object>. Any errors are mine.

It works by overridding C<bless> and adding a synthetic C<DESTROY>
method to any tracked classes so that it can maintain a count of blessed
objects per-class.

Object tracking can be enabled:

=over

=item * for an individual object

=item * for a block of code

=item * globally

=back

=head2 Tracking an individual object

Track individual objects like this:

  use Devel::LeakGuard::Object qw( track );

  # Later...
  track( my $obj = new Foo );

=head2 Tracking object leaks in a block of code

To detect any object leaks in a block of code:

  use Devel::LeakGuard::Object qw( leakguard );

  leakguard {
      # your code here.
  };

=head2 Tracking global object leaks

  use Devel::LeakGuard::Object qw( GLOBAL_bless );

=head2 Finding out what leaked

If you use C<leakguard> (recommended) then by default a warning is
thrown when leaks are detected. You can customise this behaviour by
passing options to C<leakguard>; see the documentation for L</leakguard>
for more information.

If you use C<GLOBAL_bless> or C<track> then you can also specify the
C<:at_end> option

  use Devel::LeakGuard::Object qw( GLOBAL_bless :at_end );

in which case a summary of leaks will be displayed at program exit.

=head2 Load early!

C<Devel::LeakGuard::Object> can only track allocations of objects
compiled after it is loaded - so load it as early as possible.

=head2 What is a leak?

This module counts the number of blessed instances of each tracked
class. When we talk about a 'leak' what we really mean here is an
imbalance in the number of allocated objects across some boundary. Using
this definition we see a leak even in the case of expected imbalances.

When interpreting the results you need to remember that it may be quite
legitimate for certain allocations to live beyond the scope of the code
under test.

You can use the various options that C<leakguard> supports to filter
out such legitimate allocations that live beyond the life of the block
being checked.

=head2 Performance

As soon as C<Devel::LeakGuard::Object> is loaded C<bless> is overloaded.
That means that C<bless> gets a little slower everywhere. When not
actually tracking the overloaded C<bless> is quite fast - but still
around four times slower than the built-in C<bless>.

Bear in mind that C<bless> is fast and unless your program is doing a
huge amount of blessing you're unlikely to notice a difference. On my
machine core bless takes around 0.5 μS and loading
C<Devel::LeakGuard::Object> slows that down to around 2 μS.

=head1 INTERFACE

=cut

{
    my $magic = 0;

    my $plain_bless = sub {
        my $ref = shift;
        my $class = @_ ? shift : scalar caller;
        return CORE::bless( $ref, $class );
    };

    my $magic_bless = sub {
        my $ref    = shift;
        my $class  = @_ ? shift : scalar caller;
        my $object = CORE::bless( $ref, $class );
        unless ( $class->isa( 'Devel::LeakGuard::Object::State' ) ) {
            Devel::LeakGuard::Object::track( $object );
        }
        return $object;
    };

    sub import {
        my $class  = shift;
        my @args   = @_;
        my @import = ();

        unless ( *CORE::GLOBAL::bless eq $plain_bless ) {
            # We don't actually need to install our version of bless here but
            # it'd be nice if any problems that it caused showed up sooner
            # rather than later.
            local $SIG{__WARN__} = sub {
                warn "It looks as if something else is already "
                . "overloading bless; there may be troubles ahead";
            };
            *CORE::GLOBAL::bless = $plain_bless;
        }

        for my $a ( @args ) {
            if ( 'GLOBAL_bless' eq $a ) {
                _adj_magic( 1 );
            }
            elsif ( $a =~ /^:(.+)$/ ) {
                croak "Bad option: $1" unless exists $OPTIONS{$1};
                $OPTIONS{$1}++;
            }
            else {
                push @import, $a;
            }
        }

        return __PACKAGE__->export_to_level( 1, $class, @import );
    }

    sub _adj_magic {
        my $adj       = shift;
        my $old_magic = $magic;
        $magic = 0 if ( $magic += $adj ) < 0;
        {
            no warnings 'redefine';
            if ( $old_magic > 0 && $magic == 0 ) {
                *CORE::GLOBAL::bless = $plain_bless;
            }
            elsif ( $old_magic == 0 && $magic > 0 ) {
                *CORE::GLOBAL::bless = $magic_bless;
            }
        }
    }
}

=head2 C<< leakguard >>

Run a block of code tracking object creation and destruction and report
any leaks at block exit.

At its simplest C<leakguard> runs a block of code and warns if leaks
are found:

  leakguard {
      my $foo = Foo->new;
      $foo->{me} = $foo; # leak
  };

  # Displays this warning:
  Object leaks found:
    Class Before  After  Delta
    Foo        3      4      1
  Detected at foo.pl line 23

If you really don't want to leak you can die instead of warning:

  leakguard {
      my $foo = Foo->new;
      $foo->{me} = $foo; # leak
  }
  on_leak => 'die';

If you need to do something more complex you can pass a coderef to the
C<on_leak> option:

  leakguard {
      my $foo = Foo->new;
      $foo->{me} = $foo; # leak
      my $bar = Bar->new;
      $bar->{me} = $bar; # leak again
  }
  on_leak => sub {
      my $report = shift;
      for my $pkg ( sort keys %$report ) {
        printf "%s %d %d\n", $pkg, @{ $report->{$pkg} };
      }
      # do something
  };

In the event of a leak the sub will be called with a reference to a
hash. The keys of the hash are the names of classes that have leaked;
the values are refs to two-element arrays containing the bless count for
that class before and after the block so the example above would print:

  Foo 0 1
  Bar 0 1

=head3 Options

Other options are supported. Here's the full list:

=over

=item C<on_leak>

What to do if a leak is detected. May be 'warn' (the default), 'die',
'ignore' or a code reference. If C<on_leak> is set to 'ignore' no leak
tracking will be performed.

=item C<only>

If you need to concentrate on a subset of classes use C<only> to limit
leak tracking to a subset of classes:

  leakguard {
      # do stuff
  }
  only => 'My::Stuff::*';

The pattern to match can be a string (with '*' as a shell-style
wildcard), a C<Regexp>, a coderef or a reference to an array of any of
the above. This (improbable) example illustrates all of these:

  leakguard {
      # do stuff
  }
  only => [
      'My::Stuff::*',
      qr{Leaky},
      sub { length $_ > 20 }
  ];

That would track classes beginning with 'My::Stuff::', containing
'Leaky' or whose length is greater than 20 characters.

=item C<exclude>

To track all classes apart from a few exceptions use C<exclude>. The
C<exclude> spec is like an C<only> spec but classes that match will be
excluded from tracking.

=item C<expect>

Sometimes a certain amount of 'leakage' is acceptable. Imagine, for
example, an application that maintains a single cached database
connection in a class called C<My::DB>. The connection is created on
demand and deleted after it has been used 100 times - to be created
again next time it's needed.

We could use C<exclude> to ignore this class - but then we'd miss the
case where something goes wrong and we create 5 connections at a time.

Using C<exclude> we can specify that no more than one C<My::DB> should
be created or destroyed:

  leakguard {
      # do stuff
  }
  expect => {
      'My::DB' => [ -1, 1 ]
  };

=back

=cut

use Devel::Peek;

sub leakguard(&@) {
    my $block     = shift;
    my $leakstate = Devel::LeakGuard::Object::State->new( @_ );
    $block->();
    $leakstate->done();
    return;
}

=head2 C<< leakstate >>

Get the current allocation counts for all tracked objects. If
C<GLOBAL_bless> is in force this will include all blessed objects. If
you are using the finer-grained tracking tools (L</track> and
L</leakguard>) then only allocations that they cover will be included.

Returns a reference to a hash with package names as keys and allocation
counts as values.

=cut

sub leakstate { return {%OBJECT_COUNT} }

=head2 C<< track >>

Track an individual object. Tracking an object increases the allocation
count for its package by one. When the object is destroyed the
allocation count is decreased by one. Current allocation counts may be
retrieved using L</leakstate>.

If the object is reblessed into a different package the count for the
new package will be incremented and the count for the old package
decremented.

=cut

sub track {
    my $object = shift;
    my $class  = blessed $object;

    carp "Devel::LeakGuard::Object::track was passed a non-object"
    unless defined $class;

    my $address = refaddr $object;
    if ( $TRACKED{$address} ) {

        # Reblessing into the same class, ignore
        return $OBJECT_COUNT{$class}
        if $class eq $TRACKED{$address};

        # Reblessing into a different class
        $OBJECT_COUNT{ $TRACKED{$address} }--;
    }

    $TRACKED{$address} = $class;

    unless ( $DESTROY_STUBBED{$class} ) {
        no strict 'refs';
        no warnings 'redefine';

        if ( exists ${ $class . '::' }{DESTROY}
                and *{ $class . '::DESTROY' }{CODE} ) {
            $DESTROY_ORIGINAL{$class} = \&{ $class . '::DESTROY' };
        }

        $DESTROY_STUBBED{$class} = 1;

        *{"${class}::DESTROY"} = _mk_destroy( $class );

        _mk_next( $class );
    }

    $OBJECT_COUNT{ $TRACKED{$address} }++;
}

sub _mk_destroy {
    my $pkg = shift;

    return sub {
        my $self    = $_[0];
        my $class   = blessed $self;
        my $address = refaddr $self;

        die "Unexpected error: First param to DESTROY is no an object"
        unless defined $class;

        # Don't do anything unless tracking for the specific object is set
        my $original = $TRACKED{$address};
        if ( $original ) {

            warn "Object class '$class' does",
            " not match original $TRACKED{$address}"
            if $class ne $original;

            $OBJECT_COUNT{$original}--;

            warn "Object count for $TRACKED{$address}",
            " negative ($OBJECT_COUNT{$original})"
            if $OBJECT_COUNT{$original} < 0;

            delete $TRACKED{$address};

            goto &{ $DESTROY_ORIGINAL{$original} }
            if $DESTROY_ORIGINAL{$original};
        }
        else {
            $original = $class;
        }

        # If we don't have the DESTROY_NEXT for this class, populate it
        _mk_next( $original );
        my $super = $DESTROY_NEXT{$original}{$pkg};
        goto &{"${super}::DESTROY"} if $super;
        return;
    };
}

sub _mk_next {
    my $class = shift;

    no strict 'refs';
    return if $DESTROY_NEXT{$class};

    $DESTROY_NEXT{$class} = {};

    my @stack = ( $class );
    my %seen  = ( UNIVERSAL => 1 );
    my @queue = ();

    while ( my $c = pop @stack ) {
        next if $seen{$c}++;

        my $has_destroy
        = $DESTROY_STUBBED{$c}
        ? exists $DESTROY_ORIGINAL{$c}
        : ( exists ${"${c}::"}{DESTROY} and *{"${c}::DESTROY"}{CODE} );

        if ( $has_destroy ) {
            $DESTROY_NEXT{$class}{$_} = $c for @queue;
            @queue = ();
        }
        else {
            push @queue, $c;
        }

        push @stack, reverse @{"${c}::ISA"};
    }

    $DESTROY_NEXT{$class}{$_} = '' for @queue;
}

=head2 C<status>

Print out a L<Devel::Leak::Object> style summary of current object
allocations. If you

  use Devel::LeakGuard::Object qw( GLOBAL_bless :at_end );

then C<status> will be called at program exit to dump a summary of
outstanding allocations.

=cut

sub status {
    my $fh = $OPTIONS{stderr} ? *STDERR : *STDOUT;
    print $fh "Tracked objects by class:\n";
    for ( sort keys %OBJECT_COUNT ) {
        next unless $OBJECT_COUNT{$_};    # Don't list class with count zero
        print $fh sprintf "%-40s %d\n", $_, $OBJECT_COUNT{$_};
    }
}

END { status() if $OPTIONS{at_end} }

1;

__END__

=head1 DEPENDENCIES

L<List::Util>, L<Scalar::Util>, L<Test::Differences>, L<Test::More>

=head1 SEE ALSO

L<Devel::Leak::Object>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests via
C<https://github.com/AndyA/Devel--LeakGuard--Object/issues>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

Based on code taken from Adam Kennedy's L<Devel::Leak::Object> which
carries this copyright notice:

  Copyright 2007 Adam Kennedy.

  Rewritten from original copyright 2004 Ivor Williams.

  Some documentation also copyright 2004 Ivor Williams.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009-2015, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: expandtab shiftwidth=4
