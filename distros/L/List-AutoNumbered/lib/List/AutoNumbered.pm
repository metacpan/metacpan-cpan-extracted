package List::AutoNumbered;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.000005';

# Exports
use parent 'Exporter';
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw(LSKIP);
    @EXPORT_OK = qw(*TRACE);    # can be localized
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

# Documentation ======================================================== {{{1

=head1 NAME

List::AutoNumbered - Add sequential numbers to lists while creating them

=head1 SYNOPSIS

This module adds sequential numbers to lists of lists so you don't have to
type all the numbers.  Its original use case was for adding line numbers
to lists of testcases.  For example:

    use List::AutoNumbered;                             # line 1
    my $list = List::AutoNumbered->new(__LINE__);       # line 2
    $list->load("a")->                                  # line 3
        ("b")                                           # line 4
        ("c")                                           # line 5
        ("d");                                          # line 6

    # Now $list->arr is [ [3,"a"], [4,"b"], [5,"c"], [6,"d"] ]

In general, you can pass any number to the constructor.  For example:

    use List::AutoNumbered;
    use Test::More tests => 1;

    my $list = List::AutoNumbered->new;     # First entry will be number 1
    $list->load("a")->      # Yes, trailing arrow
        ("b")               # Magic!  Don"t need any more arrows!
        ("c")
        ("d");

    is_deeply($list->arr, [
        [1, "a"], [2, "b"], [3, "c"], [4, "d"]
    ]);     # Yes, it is!

=cut

our $TRACE = 0; # Documented below

=head1 METHODS

=cut

# }}}1

# Internal helpers {{{1

# Defined-or
sub _dor { (defined $_[0]) ? $_[0] : $_[1] }

# }}}1

=head2 new

Constructor.  Call as C<< $class->new($number) >>.  Each successive element
will have the next number, unless you say otherwise (e.g., using
L<LSKIP()|/LSKIP>).  Specifically, the first item in the list will have
C<$number+1>.

=cut

sub new {
    my $class = shift;
    my $self = bless {num => _dor(shift, 0), arr => []}, $class;

    # Make a loader that adds an item and returns itself --- not $self.
    # Note that $self is captured --- the loader function does not take
    # a $self argument.
    $self->{loader} = sub { $self->_L(@_); return $self->{loader} };

    print "# Created - now $self->{num}\n" if $TRACE;
    return $self;
} #new()

# Accessors {{{1

=head2 size

Returns the size of the array.  Like C<scalar @arr>.

=cut

sub size { scalar @{ shift->{arr} }; }

=head2 last

Returns the index of the last element in the array.  Like C<$#array>.

=cut

sub last { shift->size-1; }

=head2 arr

Returns a reference to the array being built.  Please do not modify this
array directly until you are done loading it.  List::AutoNumbered may not
work if you do.

=cut

sub arr { shift->{arr}; }

=head2 last_number

Returns the current number stored by the instance.  This is the number
of the most recently preceding L<new()|/new> or L<load()|/load> call.
This is B<not> the number that will be given to the next record, since that
depends on whether or not the next record has a skip (L<LSKIP()|/LSKIP>).

=cut

sub last_number { shift->{num} }

# }}}1
# Loading {{{1

=head2 load

Push a new record with the next number on the front.  Usage:

    $instance->load(whatever args you want to push);

Or, if the current record isn't associated with the number immediately after
the previous record,

    $instance->load(LSKIP $n, args);

where C<$n> is the number of lines between this C<load()> call and the last one.

Returns a coderef that you can call to chain loads.  For example, this works:

    $instance->load(...)->(...)(...)(...) ... ;
    # You need an arrow ^^ here, but don't need any after that.

=cut

sub load { goto &{ shift->{loader} } }  # kick off loading

# _L: Implementation of load()
sub _L {
    my $self = shift;

    shift if $self->_update_lnum(@_);   # Check for skipped lines from LSKIP()

    push @{ $self->{arr} }, [$self->{num}, @_];
    return $self;
} #_L()

=head2 add

Add to the array being built, B<without> inserting the number on the front.
Does increment the number and respect skips, for consistency.

Returns the instance.

=cut

sub add {   # just add it
    my $self = shift;
    shift if $self->_update_lnum(@_);   # Check for skipped lines from LSKIP()
    push @{ $self->{arr} }, [@_];
    return $self;
} #add

# }}}1
# Skipping {{{1

=head1 FUNCTIONS

=head2 LSKIP

A convenience function to create a skipper.  Prototyped as C<($)> so you can
use it conveniently with L<load()|/load>:

    $instance->load(LSKIP 1, whatever args...);

If you are using line numbers, the parameter to C<LSKIP> should be the number
of lines above the current line and below the last L<new()|/new> or
L<load()|/load> call.  For example:

    my $instance = List::AutoNumbered->new(__LINE__);
    # A line
    # Another one
    $instance->load(LSKIP 2,    # two comment lines between new() and here
                    'some data');

=cut

sub LSKIP ($) {
    List::AutoNumbered::Skipper->new(@_);
} #LSKIP()

# _update_lnum: Increment the line number, and run a skip if there is one.
# Call from a method as:
#   my $self = shift;
#   shift if $self->_update_lnum(@_);

sub _update_lnum {
    my $self = shift;

    if(ref $_[0] eq 'List::AutoNumbered::Skipper') {    # implies scalar @_
        $self->{num} += $_[0]->{how_many} + 1;
        print "# Skipped $_[0]->{how_many} - now $self->{num}\n" if $TRACE;
        return 1;   # We do need to shift

    } else {
        ++$self->{num};
        print "# Incremented - now $self->{num}\n" if $TRACE;
        return 0;       # No skipper, so don't shift it off.
    }
} #_update_lnum()

=head1 INTERNAL PACKAGES

=head2 List::AutoNumbered::Skipper

This package represents a skip and is created by L<LSKIP()|/LSKIP>.
No user-serviceable parts inside.

=cut

{
    package List::AutoNumbered::Skipper;
    use Scalar::Util qw(looks_like_number);

=head3 new

Creates a new skipper.  Parameters are for internal use only and are not
part of the public API.

=cut

    sub new {
        my $class = shift;
        die "Need a single number" unless @_==1 and looks_like_number $_[0];
        bless {how_many => $_[0]}, $class;
    }
} #List::AutoNumbered::Skipper

# }}}1

1; # End of List::AutoNumbered

# Rest of the docs {{{1
__END__

=head1 GLOBALS

=head2 $TRACE

(Default falsy) If truthy, print trace output.  Must be accessed directly
unless requested on the C<use> line.  Either of the following works:

    use List::AutoNumbered; $List::AutoNumbered::TRACE=1;
    use List::AutoNumbered q(*TRACE); $TRACE=1;

=head1 AUTHOR

Christopher White, C<< <cxwembedded at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/cxw42/List-AutoNumbered/issues>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::AutoNumbered

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/pod/List::AutoNumbered>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/List-AutoNumbered>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<zdim|https://stackoverflow.com/users/4653379/zdim>
for discussion and ideas in the
L<Stack Overflow question|https://stackoverflow.com/q/50510809/2877364>
that was the starting point for this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Christopher White.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

# }}}1
# vi: set fdm=marker: #
