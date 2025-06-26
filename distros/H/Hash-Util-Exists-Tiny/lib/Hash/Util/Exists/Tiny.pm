package Hash::Util::Exists::Tiny;

use 5.010_001;
use strict;
use warnings FATAL => 'all';

use Exporter 'import';

our $VERSION = '1.03';


our @EXPORT_OK   = qw(exists_one_of
                      list_exists list_exists_unique
                      num_exists  num_exists_unique
                      defined_one_of
                      list_defined list_defined_unique
                      num_defined  num_defined_unique);
our %EXPORT_TAGS = (all => \@EXPORT_OK);



sub exists_one_of {
  return !!grep(exists($_[0]->{$_}), @_);
}


sub list_exists {
  return grep(exists($_[0]->{$_}), @_);
}


sub list_exists_unique {
  my %seen;
  return grep(exists($_[0]->{$_}), grep(!$seen{$_}++, @_));
}


sub num_exists {
  return scalar grep(exists($_[0]->{$_}), @_);
}


sub num_exists_unique {
  my %seen;
  return scalar grep(exists($_[0]->{$_}), grep(!$seen{$_}++, @_));
}


sub defined_one_of {
  return !!grep(defined($_[0]->{$_}), @_);
}


sub list_defined {
  return grep(defined($_[0]->{$_}), @_);
}


sub list_defined_unique {
  my %seen;
  return grep(defined($_[0]->{$_}), grep(!$seen{$_}++, @_));
}


sub num_defined {
  return scalar grep(defined($_[0]->{$_}), @_);
}


sub num_defined_unique {
  my %seen;
  return scalar grep(defined($_[0]->{$_}), grep(!$seen{$_}++, @_));
}



1;

__END__


=head1 NAME

Hash::Util::Exists::Tiny - Some hash helper functions related to perl's "exists" function.


=head1 VERSION

Version 1.03


=head1 SYNOPSIS

   use Hash::Util::Exists::Tiny qw(exists_one_of
                                   list_exists  list_exists_unique
                                   num_exists   num_exists_unique
                                   defined_one_of
                                   list_defined list_defined_unique
                                   num_defined  num_defined_unique
                                   );

or

    use Hash::Util::Exists::Tiny qw(:all);


=head1 DESCRIPTION

This module provides some funtions for hashes, related to perl's
C<exists> function. All functions are exported on demand, you can use tag
C<:all> to export all functions at once.

The functions do not perform parameter checks.


=head2 FUNCTIONS

=over

=item C<exists_one_of HASH_REF [, LIST]>

Returns I<true> if one of the elements in C<LIST> is a key in C<HASH_REF>,
otherwise false. Example:

   my $flag = exists_one_of($href, qw(foo bar baz));


=item C<list_exists HASH_REF [, LIST]>

Returns the list of entries of C<LIST> that are keys in C<HASH_REF>. Note that
duplicate keys in C<LIST> are also duplicate in the result.

=item C<list_exists_unique HASH_REF [, LIST]>

Like C<list_exists>, but each duplicated element is only counted once.

=item C<num_exists HASH_REF [, LIST]>

Returns the number of entries in C<LIST> that are keys in C<HASH_REF>.  Note
that duplicate entries are counted twice.

=item C<num_exists_unique HASH_REF [, LIST]>

Like C<num_exists>, but each duplicated element is only counted once.


=item C<defined_one_of HASH_REF [, LIST]>

Like C<exists_one_of>, but looks for defined values.

=item C<list_defined HASH_REF [, LIST]>

Like C<list_exists>, but looks for defined values.

=item C<list_defined_unique HASH_REF [, LIST]>

Like C<list_exists_unique>, but looks for defined values.


=item C<num_defined HASH_REF [, LIST]>

Like C<num_exists>, but looks for defined values.


=item C<num_defined_unique HASH_REF [, LIST]>

Like C<num_exists_unique>, but looks for defined values.

=back



=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-util-exists-tiny at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Util-Exists-Tiny>.  I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SEE ALSO

L<Exporter>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Util::Exists::Tiny


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Util-Exists-Tiny>

=item * Search CPAN

L<https://metacpan.org/release/Hash-Util-Exists-Tiny>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-Hash-Util-Exists-Tiny.git>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.


=cut
