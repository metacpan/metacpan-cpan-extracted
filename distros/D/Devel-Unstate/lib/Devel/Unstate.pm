package Devel::Unstate;
use 5.010;
use strict;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Devel::Unstate', $VERSION);

1;
__END__

=head1 NAME

Devel::Unstate - Disable 'state' keyword statelessness

=head1 DESCRIPTION

This module makes all B<state> variables behave as if they were
B<my> variables. This can be useful for testing, when you cache
some data in your application, but want to get fresh values on each
test iteration.

The effect of C<Devel::Unstate> is global. But only variable declarations
compiled after it is loaded are affected.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Sergey Aleynikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
