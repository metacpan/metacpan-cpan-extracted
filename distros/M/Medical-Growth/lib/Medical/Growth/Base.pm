#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::Base;

use Scalar::Util qw(openhandle);

our ($VERSION) = '1.00';

sub read_data {
    my ( $callpkg, $file ) = @_;
    my $opened_here = 0;
    my ( $fh, $pos, @lines );
    local ( $., $_ );

    if ( not defined $file ) {
        $callpkg = ref $callpkg if ref $callpkg;
        $fh = do { no strict 'refs'; \*{"${callpkg}::DATA"}; };
        $pos = tell($fh);
    }
    elsif ( openhandle($file) ) {
        $fh = $file;
    }
    else {
        unless ( open $fh, '<', $file ) {
            require Carp;
            Carp::croak("Can't read file \"$file\": $!");
        }
        $opened_here = 1;
    }

    while (<$fh>) {
        last if /^__END__/;

        # Simple comment syntax; we don't allow within line
        # so we don't have to parse for quotes or expressions
        next if /^(?:#.*|\s*)$/;
        push @lines, [split];
    }

    if ($opened_here) {
        close($fh);
    }
    elsif ($pos) {

        # A small twist to restore DATA to initial state when we're done,
        # so it doesn't appear as part of default error messages.
        seek( $fh, $pos, 0 );
    }

    return \@lines;
} ## end sub read_data

sub measure_class_for {
    require Carp;
    Carp::croak("No measure_class_for() method found (called via \"$_[0]\")");
}

1;

__END__

=head1 NAME

Medical::Growth::Base - Base class for measurement system

=head1 SYNOPSIS

  package My::Growth::Charts::Base;

  use Moo::Lax;  # Plain Moo considered harmful
  extends 'Medical::Growth::Base';

=head1 DESCRIPTION

F<Medical::Growth::Base> is designed as an (optional) base on which to
build measurement systems.  It provides a set of basic tools for
constructing parameter tables and handling z scores and percentiles.

=head1 IMPLEMENTING A MEASUREMENT SYSTEM

Fundamentally, a L<Medical::Growth>-compatible measurement system is
simply a class or hierarchy of classes that provide useful information
about clinical measurements (typically relationship to norms), and
provides a C<measure_class_for> that L<Medical::Growth/measure_class_for>
can delegate to in order to identify an actual measurement class.

The top-level class for a measurement system must be named
C<Medical::Growth::>I<Name>.  However, it need not be a subclass of
L<Medical::Growth>; it will be identified via L<Module::Pluggable>.

This top-level class must contain at least one function:

=over 4

=item B<measure_class_for>(I<%criteria>)

This function should evaluate the elements of I<%criteria> and return
a "handle" that the caller can use to call the data methods the
measurement system provides.  For example, if you're implementing a
set of norms for weight gain, your F<measure_class_for> function might
look in I<%criteria> to determine the patient's age and sex, and
return the appropriate class for the caller to get a percentile value
by calling a C<value_to_pct> method.

Each measurement system is free to determine which keys in
I<%criteria> to inspect, though it's considered friendly to see what
existing systems use, and make compatible choices where you can.  As
one example, if this function in your class was called by delegation
from L<Medical::Growth/measure_class_for>, I<%criteria> will contain a
C<system> element with your name; it may be helpful to know by what
name you were called.

It's considered polite for a measurement system's C<measure_class_for>
to accept I<%criteria> as either a hash reference or a list of
key-value pairs.

=back

=head2 UTILITY METHODS

F<Medical::Growth::Base> provides one method to simplify embedding data in a
measurement class's file:

=over 4

=item B<read_data>([I<$file>])

Reads a list of values from a table, typically used by a measure class
to set up parameters needed to generate results.

If called with no arguments, reads the content of the C<DATA>
filehandle in the invoking class.  If I<$file> is an open file handle,
will read from that instead.  If I<$file> is any other value, it will
be used as a file name, and that file will be opened for reading (and
closed when finished).

Lines will be read up to the end of the file or until an C<__END__>
line is encountered.  Lines consisting of whitespace only or beginning
with C<#> are discarded.  Otherwise, the contents of the line are
split on whitespace and stored in an array reference.

If the C<DATA> file handle was read implicitly (i.e. because no
I<$file> was provided), it is repositioned to its starting point. This
trick insures that that it doesn't appear as an active handle in any
future error messages because it was read here.

Returns a reference to an array that in turn contains the array
references for each line containing data.

In many cases, it may be simpler to just embed data that a measurement
class needs in a statically initialized data structure.  But if you
want to defer the cost of parsing data tables until the information is
needed, or use an external configuration file, this method allows you
to store data separately from code.

=back


=head2 EXPORT

None.

=head1 DIAGNOSTICS

Any message produced by an included package.

=over 4

=item B<Can't read file> (F)

You passed a file name to L</read_data>, and the file couldn't be
opened. 

=item B<No measure_class_for() method found> (F)

This is the result of calling
L<Medical::Growth::Base::measure_class_for>; you should override this
message in your measurement system's top-level class.

=back

=head1 BUGS AND CAVEATS

Are there, for certain, but have yet to be cataloged.

=head1 VERSION

version 1.00

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2014 Charles Bailey.

This software may be used under the terms of the Artistic License or
the GNU General Public License, as the user prefers.

=head1 ACKNOWLEDGMENT

The code incorporated into this package was originally written with
United States federal funding as part of research work done by the
author at the Children's Hospital of Philadelphia.

=cut
