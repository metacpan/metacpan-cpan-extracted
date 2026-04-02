use v5.20;
use warnings;
package Log::Fmt::XS 0.001;

use parent 'Log::Fmt';

# ABSTRACT: XS components to speed up Log::Fmt

#pod =head1 OVERVIEW
#pod
#pod There isn't much to say!  It's a subclass of L<Log::Fmt> with XS components to
#pod make emitting logfmt logs faster.
#pod
#pod See L<Log::Fmt> for more information.
#pod
#pod =cut

use XSLoader;
XSLoader::load('Log::Fmt::XS', $Log::Fmt::XS::VERSION);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Fmt::XS - XS components to speed up Log::Fmt

=head1 VERSION

version 0.001

=head1 OVERVIEW

There isn't much to say!  It's a subclass of L<Log::Fmt> with XS components to
make emitting logfmt logs faster.

See L<Log::Fmt> for more information.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 AUTHOR

Rob Mueller <cpan@robm.fastmail.fm>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
