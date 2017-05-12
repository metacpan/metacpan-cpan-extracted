package Language::Lisp;

use strict;

our $VERSION = '0.20';

require XSLoader;
XSLoader::load('Language::Lisp', $VERSION);

1;

__END__

=head1 NAME

Language::Lisp - Perl extension for connecting to existing common lisp
implementation

=head1 SYNOPSIS

  use Language::Lisp;

=head1 DESCRIPTION

Given Lisp implementation, this module provides a connection to Perl, much
like Tcl module, at C level. The way the connection works is very different,
however.

Lisp should be executed first, then it looks for the Perl's shared library,
and then uses functions from it. This approach is seemingly unavoidable,
because usually Lisp implementations are used from large single executable,
so there is no way to use Lisp as some kind of library out from Perl.

=head1 SEE ALSO

Stuart Sierra's page for perl-in-lisp
at http://stuartsierra.com/software/perl-in-lisp/ is where this Perl module
come from.

See also related common lisp resources at http://cliki.net

=head1 AUTHOR

Vadim Konovalov vkon@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Vadim Konovalov vkon@cpan.org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
