package JS::JSLint;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

1;

__END__

=head1 NAME

JS-JSLint - JSLint (for JS): The JavaScript code quality tool

=head1 VERSION

This document describes JS-JSLint version 0.03.

=cut

=head1 SYNOPSIS

    var result = JSLINT(source, options);

=head1 DESCRIPTION

JSLint is a code quality tool for JavaScript.  This distribution packages
JSLint version 2011-11-16 for use with the L<JS> framework on CPAN.

=head1 SEE ALSO

=over

=item * L<JS>

=item * JSLint: L<http://www.jslint.com/>

=item * JSLint repository: L<https://github.com/douglascrockford/JSLint/>

=item * L<JavaScript::JSLint>

=back

=head1 AUTHORS

Nick Patch <patch@cpan.org> is the packager of JS-JSLint

Douglas Crockford <douglas@crockford.com> is the author of JSLint

=head1 COPYRIGHT & LICENSE

Copyright 2011 Nick Patch

This program is free software; you can redistribute it and/or modify it
under the same terms as JSLint itself.

=cut
