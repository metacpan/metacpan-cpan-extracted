package Method::Slice;
use 5.010;
use strict;
use warnings;
use Exporter   qw/import/;
use Carp;
use Want;

our $VERSION = '0.02';
our @EXPORT  = qw/mslice/;

sub mslice : lvalue {
  my ($obj, @meths) = @_;
  if (want('LVALUE')) {
    if (my @rvals = want('ASSIGN')) {
      # call each method as a setter accessor
      for my $i (0 .. $#meths) {
        my $meth = $meths[$i];
        $obj->$meth($rvals[$i]);
      }
      lnoreturn;
    }
    else {
      croak "mslice used in LVALUE context but without ASSIGN .. "
          . "don't know what to do :-(";
    }
  }
  else {
    # call each method as a getter accessor, and gather values
    my @values = map {scalar $obj->$_()} @meths;
    rreturn @values;
  }
  return;
}



__END__

=head1 NAME

Method::Slice - A slice of method calls within an object

=head1 SYNOPSIS

  use Method::Slice;

  # rvalue example: gather several substrings
  my $url = sprintf "http://%s:%d/%s?%s", 
                    mslice($obj, qw/host port path query_string/);

  # lvalue example : transpose point
  my $point = Point->new(x => 11, y => 22);
  (mslice($point, qw/x y/)) = mslice($point, qw/y x/);

  # other lvalue example : move 10 units on x and y axes
  # must use  @{[]} because arg to 'map' is a non-assignment lvalue context
  (mslice($point, qw/x y/)) = map {$_ + 10} @{[mslice($point, qw/x y/)]};

  # unfortunately these won't work
  # $_ += 10 for mslice($point, qw/x y/);      # not in ASSIGN context
  # $_ += 10 for @{[mslice($point, qw/x y/)]}; # assigns to a throwaway copy


=head1 DESCRIPTION

Perl has a very convenient feature called I<slice>, to extract
several pieces of information at once from an array or from a hash
(see L<perldata/"Slices"). It is even possible to assign a list,
to a slice, i.e. to simultaneously update several items within
an array or hash.

Unfortunately, when it comes to objects with accessor methods,
good practice forbids us to directly access the internal
hash or array that stores the object state; so slices are no
longer available, and every attribute of the object must be accessed
in a separate call.

The present module comes the rescue : it exports a single subroutine
C<mslice> (for "method slice"), that takes an object and a collection
of method names, and encapsulates a list of method calls, either to get
a list of attributes, or to set them in a single list operation.

=head1 EXPORTS

=head2 mslice

  my @values = mslice($object, qw/meth1 meth2 .../);
  (mslice($object, qw/meth1 meth2 .../)) = @new_values;

Takes an object reference, and a collection of method names, which
are supposed to be getter/setter methods in the usual sense (i.e.
we should be able to write C<< my $val = $object->meth1() >> for
getting a value, and C<< $object->meth1($new_val) >> for setting
a value within that object).

If C<mslice> is called in an I<rvalue context>, it will return a list
of values obtained by calling the methods as getter accessors (i.e.
without any argument).

If C<mslice> is called in an I<lvalue assign context>, it will call each
accessor in the method list, with a single argument corresponding to
the item in the corresponding position within the list on the
right-hand side. Notice that the C<mslice> call should be enclosed
in parenthesis so that it is in list context, not in scalar context.

Unfortunately C<mslice> cannot be called in a lvalue, non-assign context.
This is typically the case when using it as an argument to another
subroutine (because that other subroutine receives I<aliases> to its arguments
in C<@_>, and might alter those aliases). So for such situations
we have to force an rvalue context by writing

  some_subroutine(@{[mslice($object, qw/meth1 meth2 .../)]})

See L<Want>, L<perldata> and L<perlsub/"Lvalue subroutines"> for more
explanations on lvalue/rvalue contexts.

=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-method-slice at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Method-Slice>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Method::Slice

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-Slice>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Method-Slice>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Method-Slice>

=item * Search MetaCPAN

L<https://metacpan.org/module/Method::Slice>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Belden Lyman for useful fixes.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut


