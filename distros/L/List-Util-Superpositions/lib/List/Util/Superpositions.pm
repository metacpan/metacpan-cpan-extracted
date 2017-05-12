package List::Util::Superpositions;

use warnings;
use strict;

use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use Quantum::Superpositions qw(any all);

use base qw( List::Util Quantum::Superpositions );
use vars qw( @EXPORT @EXPORT_OK );

use Exporter::Lite;
@EXPORT       = qw();
@EXPORT_OK    = qw(any all first max maxstr min minstr reduce shuffle sum);

=head1 NAME

List::Util::Superpositions - Provides 'any' and 'all' for lists

=head1 Version

Version 1.2

=cut

our $VERSION = '1.2';

=head1 Synopsis

This module extends the methods provided by List::Util to offer the
C<any()> and C<all()> operators from L<Quantum::Superpositions> as part
of the List::Util feature set.

    use List::Util::Superpositions;

    my $foo = List::Util::Superpositions->new();
    ...

=head1 Exports & Inheritances

=head2 Quantum::Superpositions

=over 4

=item * any

=item * all

=back

=head2 List::Util

=over 4

=item * first

=item * max

=item * maxstr

=item * min

=item * minstr

=item * reduce

=item * shuffle

=item * sum

=back

=head1 Author

Richard Soderberg, C<< <RSOD@cpan.org> >>

=head1 Story

It seemed handy to link L<Quantum::Superpositions> into L<List::Util>, after
a discussion in IRC triggered the thought.  I'm reasonably sure I didn't
cover all the possible List::Util exports, and there's got to be a more
generic way to do it -- perhaps using @EXPORT_OK.

=head1 Bugs

Please report any bugs or feature requests to
C<bug-List-Util-Superpositions@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 Copyright & License

Copyright 2004, 2008 Richard Soderberg, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of List::Util::Superpositions
