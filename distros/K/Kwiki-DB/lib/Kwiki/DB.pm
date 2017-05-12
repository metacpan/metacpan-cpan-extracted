package Kwiki::DB;
use Kwiki::Plugin -Base;
our $VERSION = '0.01';

const id => 'db';

__END__

=head1 NAME

  Kwiki::DB - base class of front-end of DBI engines for Kwiki

=head1 DESCRIPTION

This is nothing but a base class of C<Kwiki::DB::*> modules, and should not be
used directly in your Kwiki plugin code. Please see L<Kwiki::DB::DBI> for some
usage examples.

The other implementation is L<Kwiki::DB::ClassDBI>. More engines are coming in
the way. Helps are galded and wanted :)

=head1 SEE ALSO

L<Kwiki::DB::DBI>, L<Kwiki::DB::ClassDBI>

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

