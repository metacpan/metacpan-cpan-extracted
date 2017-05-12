package Merge::HashRef;

$Merge::HashRef::VERSION = '0.01';

use strict;
use warnings;

use base 'Exporter::Simple';
use Carp;

=head1 NAME

Merge::HashRef - make one hashref out of many!

=head1 SYNOPSIS

	use Merge::HashRef;

	my $hashref = merge_hashref($ref1, $ref2, ...)

=head1 DESCRIPTION

Recently, I found myself turning lots of hashrefs into a single one. 
And, I thought, this would be a nice little function to have.

So now you have it too!

=head2 merge_hashref

	my $hashref = merge_hashref($ref1, $ref2, ...)

This takes a list of hashrefs, and returns you one. Of course, the order 
you pass your hashrefs in IS important, as later key/value pairs will
clobber earlier ones. This is deliberate. This is why I wrote this little
module!

All non-hashrefs get removed from the passed-in list. So don't be doing that.

=cut

sub merge_hashref : Exported { return { map %$_, grep ref $_ eq 'HASH', @_ } }


=head1 SHOWING YOUR APPRECIATION

There was a thread on london.pm mailing list about working
in a vacumn - that it was a bit depressing to keep writing
modules but never get any feedback. So, if you use and
like this module then please send me an email and make my
day.

All it takes is a few little bytes.

(Leon wrote that, not me!)

=head1 AUTHOR

Stray Toaster, E<lt>coder@stray-toaster.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Stray Toaster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
