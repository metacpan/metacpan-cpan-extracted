package Fry::Dump::DataDumper;
use strict;
use Data::Dumper;
sub setup {}
$Data::Dumper::Indent = 0;
#$Data::Dumper::Purity = 1;
sub dump { my $class = shift; Dumper(@_) }
1;

__END__	

=head1 NAME

Fry::Dump::DataDumper - Dump plugin for Fry::Shell which uses Data::Dumper.

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
