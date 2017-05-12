#
# $Id: Uniq.pm 4496 2010-06-18 15:19:43Z james $
#

=head1 NAME

List::Uniq - extract the unique elements of a list

=head1 SYNOPSIS

  use List::Uniq ':all';

  @uniq = uniq(@list);

  $list = [ qw|foo bar baz foo| ];
  $uniq = uniq($list);

=head1 DESCRIPTION

List::Uniq extracts the unique elements of a list.  This is a commonly
re-written (or at least re-looked-up) idiom in Perl programs.

=cut

package List::Uniq;
use base 'Exporter';

use strict;
use warnings;

our $VERSION = '0.20';

# set up exports
our @EXPORT;
our @EXPORT_OK;
our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [ qw|uniq| ];
Exporter::export_ok_tags('all');

=head1 FUNCTIONS

=head2 uniq( { OPTIONS }, ele1, ele2, ..., eleN )

uniq() takes a list of elements and returns the unique elements of the list. 
Each element may be a scalar value or a reference to a list.

If the first element is a hash reference it is taken to be a set of options
that alter the way in which the unique filter is applied.  The keys of the
option set are:

=over 4

=item * sort

If set to a true value, the unique elements of the list will be returned
sorted.  Perl's default sort will be used unless the B<compare> option is
also passed.

B<sort> defaults to false.

=item * flatten

If set to a true value, array references in the list will be recursively
flattened, such that

  ( 'foo', [ [ 'bar' ] ], [ [ [ 'baz', 'quux' ] ] ] )

becomes

  ( 'foo', 'bar', 'baz', 'quux' )

B<flatten> defaults to true.

=item * compare

A code reference that will be used to sort the elements of the list if the
B<sort> option is set.  Passing a non-coderef will cause B<uniq> to throw an
exception.

The code ref will be passed a pair of list elements to be compared and
should return the same values as the L<cmp|perlop/"Equality Operators">
operator.

Using a custom sort slows things down because the sort routine will be
outside of the List::Uniq package.  This requires that the pairs to be
compared be passed as parameters to the sort routine, not set as package
globals (see L<perlfunc/sort>).  If speed is a concern, you are better off
sorting the return of B<uniq> yourself.

=back

The return value is a list of the unique elements if called in list context
or a reference to a list of unique elements if called in scalar context.

=cut

my %default_opts = ( sort => 0, flatten => 1 );

sub uniq
{

    # pull options off the front of the list
    my $opts;
    if( ref $_[0] eq 'HASH' ) {
        $opts = shift @_;
    }
    for my $opt( keys %default_opts ) {
      unless( defined $opts->{$opt} ) {
        $opts->{$opt} = $default_opts{$opt};
      }
    }
    
    # flatten list references
    if( $opts->{flatten} ) {
      my $unwrap;
      $unwrap = sub { map { 'ARRAY' eq ref $_ ? $unwrap->( @$_ ) : $_ } @_ };
      @_ = $unwrap->( \@_ );
    }
    
    # uniq the elements
    my @elements;
    my %seen;
    {
        no warnings 'uninitialized';
        @elements = grep { ! $seen{$_} ++ } @_;
    }
    
    # sort before returning if so desired
    if( $opts->{sort} ) {
        if( $opts->{compare} ) {
            unless( 'CODE' eq ref $opts->{compare} ) {
                require Carp;
                Carp::croak("compare option is not a CODEREF");
            }
            @elements = sort { $opts->{compare}->($a,$b) } @elements;
        }
        else {
            @elements = sort @elements;
        }
    }
    
    # return a list or list ref
    return wantarray ? @elements : \@elements;

}

# keep require happy
1;


__END__


=head1 EXAMPLES

=head1 EXPORTS

Nothing by default.

Optionally the B<uniq> function.

Everything with the B<:all> tag.

=head1 SEE ALSO

If you want to unique a list as you insert into it, see L<Array::Unique> by
Gabor Szabo.

This module was written out of a need to unique an array that was
auto-vivified and thus not easily tied to Array::Unique.

=head1 AUTHOR

James FitzGibbon
<james+perl@nadt.net>

=head1 CREDITS

The idioms used to unique lists are taken from recipe 4.7 in the I<Perl
Cookbook, 2e.>, published by O'Reilly and Associates and from the Perl FAQ
section 5.4.

I pretty much just glued it together in a way that I find easy to use. 
Hopefully you do too.

=head1 COPYRIGHT

Copyright (c) 2004-2008 Primus Telecommunications Canada Inc.

Copyright (c) 2008-2010 James FitzGibbon

All Rights Reserved.

This library is free software; you may use it under the same
terms as perl itself.

=cut

#
# EOF
