package Hash::Wrap::Base::LValue;

use strict;
use warnings;

use 5.01600;

our $VERSION = '0.03';

use Hash::Wrap ();
use parent 'Hash::Wrap::Base';

our $generate_signature = sub { ': lvalue' };

our $AUTOLOAD;
sub AUTOLOAD : lvalue {
    goto &{ Hash::Wrap::_autoload( $AUTOLOAD, $_[0] ) };
}

1;

__END__

=pod

=head1 NAME

Hash::Wrap::Base::LValue

=head1 VERSION

version 0.03

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Wrap> or by email
to L<bug-Hash-Wrap@rt.cpan.org|mailto:bug-Hash-Wrap@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/hash-wrap>
and may be cloned from L<git://github.com/djerius/hash-wrap.git>

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
