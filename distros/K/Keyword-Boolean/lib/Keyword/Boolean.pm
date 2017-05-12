package Keyword::Boolean;

use 5.011_002;
use strict;
use warnings;

our $VERSION = '0.001';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

Keyword::Boolean - The real boolean keywords

=head1 VERSION

This document describes Keyword::Boolean version 0.001.

=head1 SYNOPSIS

    use 5.11.2;
    use Keyword::Boolean;

    my $t = true;
    my $f = false;

    ...;

=head1 DESCRIPTION

Keyword::Boolean provides two keywords: B<true> and B<false>.

They are I<real> keywords introduced by the C<PL_keyword_plugin> mechanism,
not by constant subroutines nor by source filters, so you cannot I<call>
them as subroutines.

=head1 DEPENDENCIES

Perl 5.11.2 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<perl5112delta>

L<perlapi>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
