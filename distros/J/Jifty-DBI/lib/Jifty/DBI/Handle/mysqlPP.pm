package Jifty::DBI::Handle::mysqlPP;
use Jifty::DBI::Handle::mysql;
@ISA = qw(Jifty::DBI::Handle::mysql);

use vars qw($VERSION @ISA $DBIHandle $DEBUG);
use strict;

1;

__END__

=head1 NAME

Jifty::DBI::Handle::mysqlPP - A mysql specific Handle object

=head1 DESCRIPTION

A Handle subclass for the "pure perl" mysql database driver.

This is currently identical to the Jifty::DBI::Handle::mysql class.

=head1 AUTHOR



=head1 SEE ALSO

Jifty::DBI::Handle::mysql

=cut

