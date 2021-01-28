package Test::Most::Exception;

use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = ('throw_failure');

our $VERSION = '0.37';
$VERSION = eval $VERSION;

use Exception::Class 'Test::Most::Exception' => {
    alias       => 'throw_failure',
    description => 'Test failed.  Stopping test.',
};

1;

__END__

=head1 NAME

Test::Most::Exception - Internal exception class

=head1 VERSION

Version 0.34

=head1 SYNOPSIS

This is the exception thrown by C<die_on_fail> by C<Test::Most>.

=head1 EXPORT

We export only one function:

=head2 C<throw_failure>

This is the exception for C<die_on_fail>.

=cut

=head1 AUTHOR

Curtis Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-extended at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Most>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Most

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Most>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Most>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Most>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Most>

=back

=head1 CAVEATS

The stack trace is likely useless due to how C<Test::Builder> internals work.
Sorry 'bout that.

=head1 ACKNOWLEDGEMENTS

Many thanks to C<perl-qa> for arguing about this so much that I just went
ahead and did it :)

Thanks to Aristotle for suggesting a better way to die or bailout.

Thanks to 'swillert' (L<http://use.perl.org/~swillert/>) for suggesting a
better implementation of my "dumper explain" idea
(L<http://use.perl.org/~Ovid/journal/37004>).

=head1 COPYRIGHT & LICENSE

Copyright 2008 Curtis Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
