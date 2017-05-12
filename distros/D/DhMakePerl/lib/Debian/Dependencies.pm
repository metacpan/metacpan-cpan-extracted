package Debian::Dependencies;

use strict;
use warnings;

our $VERSION = '0.67';

use AptPkg::Config;
use Debian::Dependency;

use overload '""'   => \&_stringify,
             '+'    => \&_add,
             'eq'   => \&_eq;

=head1 NAME

Debian::Dependencies - a list of Debian::Dependency objects

=head1 SYNOPSIS

    my $dl = Debian::Dependencies->new('perl, libfoo-perl (>= 3.4)');
    print $dl->[1]->ver;      # 3.4
    print $dl->[1];           # libfoo-perl (>= 3.4)
    print $dl;                # perl, libfoo-perl (>= 3.4)

    $dl += 'libbar-perl';
    print $dl;                # perl, libfoo-perl (>= 3.4), libbar-perl

    print Debian::Dependencies->new('perl') + 'libfoo-bar-perl';
                              # simple 'sum'

    print Debian::Dependencies->new('perl')
          + Debian::Dependencies->new('libfoo, libbar');
                              # add (concatenate) two lists

    print Debian::Dependencies->new('perl')
          + Debian::Dependency->new('foo');
                              # add dependency to a list

=head1 DESCRIPTION

Debian::Dependencies a list of Debian::Dependency objects, with automatic
construction and stringification.

Objects of this class are blessed array references. You can safely treat them
as arrayrefs, as long as the elements you put in them are instances of the
L<Debian::Dependency> class.

When used in string context, Debian::Dependencies converts itself into a
comma-delimited list of dependencies, suitable for dependency fields of
F<debian/control> files.

=head2 CLASS METHODS

=over 4

=item new(dependency-string)

Constructs a new L<Debian::Dependencies> object. Accepts one scalar argument,
which is parsed and turned into an arrayref of L<Debian::Dependency> objects.
Each dependency should be delimited by a comma and optional space. The exact
regular expression is C</\s*,\s*/>.

=cut

sub new {
    my ( $class, $val ) = @_;

    my $self = bless [], ref($class)||$class;

    if ( defined($val) ) {
        $self->add( Debian::Dependency->new($_) )
            for split( /\s*,\s*/s, $val );
    }

    return $self;
}

sub _stringify {
    my $self = shift;

    return join( ', ', @$self );
}

sub _add_dependency {
    my( $self, @deps ) = @_;

    DEP:
    for my $dep(@deps) {
        # see if the new dependency is already satisfied by some of the
        # dependencies we have
        for(@$self) {
            next DEP if $_->satisfies($dep);
        }

        # see if the new dependency is broader than (satisfies) some of the old
        for(@$self) {
            if( $dep->satisfies($_) ) {
                $_ = $dep;
                next DEP;
            }
        }

        # OK, the new dependency doesn't overlap with any of the old, add it
        push @$self, $dep;
    }
}

sub _add {
    my $left = shift;
    my $right = shift;
    my $mode = shift;

    $right = $left->new($right) unless ref($right);
    $right = [ $right ] if $right->isa('Debian::Dependency');

    if ( defined $mode ) {      # $a + $b
        my $result = bless [ @$left ], ref($left);
        $result->_add_dependency(@$right);
        return $result;
    }
    else {                      # $a += $b;
        $left->_add_dependency(@$right);
        return $left;
    }
}

sub _eq {
    my( $left, $right ) = @_;

    # force stringification
    return "$left" eq "$right";
}

=back

=head2 OBJECT METHODS

=over 4

=item add( I<dependency>[, ... ] )

Adds I<dependency> (or a list of) to the list of dependencies. If the new
dependency is a subset of or overlaps some of the old dependencies, it is not
duplicated.

    my $d = Debian::Dependencies('foo, bar (<=4)');
    $d->add('foo (>= 4), bar');
    print "$d";     # foo (>= 4), bar (>= 4)

I<dependency> can be either a L<Debian::Dependency> object, a
L<Debian::Deendencies> object, or a string (in which case it is converted to an
instance of the L<Debian::Dependencies> class).

=cut

sub add {
    my $self = shift;

    while ( defined(my $dep = shift) ) {
        $dep = Debian::Dependencies->new($dep)
            unless ref($dep);

        $self += $dep;
    }
}

=item remove( I<dependency>, ... )
=item remove( I<dependencies>, ... )

Removes a dependency from the list of dependencies. Instances of
L<Debian::Dependency> and L<Debian::Dependencies> classes are supported as
arguments.

Any non-reference arguments are coerced to instances of L<Debian::Dependencies>
class.

Only dependencies that are subset of the given dependencies are removed:

    my $deps = Debian::Dependencies->new('foo (>= 1.2), bar');
    $deps->remove('foo, bar (>= 2.0)');
    print $deps;    # bar

Returns the list of the dependencies removed.

=cut

sub remove {
    my( $self, @deps ) = @_;

    my @removed;

    for my $deps(@deps) {
        $deps = Debian::Dependencies->new($deps)
            unless ref($deps);

        for my $dep(@$deps) {
            my @kept;

            for( @$self ) {
                if( $_->satisfies($dep) ) {
                    push @removed, $_;
                }
                else {
                    push @kept, $_;
                }
            }

            @$self = @kept;
        }
    }

    return @removed;
}

=item has( I<dep> )

Return true if the dependency list contains given dependency. In other words,
this returns true if the list of dependencies guarantees that the given
dependency will be satisfied. For example, C<foo, bar> satisfies C<foo>, but
not C<< foo (>= 5) >>.

=cut

sub has {
    my( $self, $dep ) = @_;

    $dep = Debian::Dependency->new($dep)
        unless eval { $dep->isa('Debian::Dependency') };

    for( @$self ) {
        return 1
            if $_->satisfies($dep);
    }

    return 0;
}

=item prune()

This method is deprecated. If you want to sort the dependency list, either call L</sort> or use normal perl sorting stuff on the dereferenced array.

=cut

sub prune {
    my $self = shift;

    use Carp ();
    Carp::croak("prune() is deprecated and does nothing");
}

=item sort()

Sorts the dependency list by package name, version and relation.

=cut

sub sort {
    my( $self ) = @_;

    @$self = sort { $a <=> $b } @$self;
}

=back

=cut

1;

=head1 SEE ALSO

L<Debian::Dependency>

=head1 AUTHOR

=over 4

=item Damyan Ivanov <dmn@debian.org>

=back

=head1 COPYRIGHT & LICENSE

=over 4

=item Copyright (C) 2008, 2009, 2010 Damyan Ivanov <dmn@debian.org>

=item Copyright (C) 2009 gregor herrmann <gregoa@debian.org>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut
