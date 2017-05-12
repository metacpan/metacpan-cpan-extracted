package LEOCHARRE::DBI;
use base 'DBI';
use base 'LEOCHARRE::Database::Base';

1;




=pod

=head1 NAME

LEOCHARRE::DBI - extra dbi methods

=head1 DESCRIPTION

adds LEOCHARRE::Database::Base to DBI

=head1 SYNOPSIS

   use LEOCHARRE::DBI;

   my $dbh = DBI::connect_sqlite('/home/myself/stuff.db');
	my $dbh = DBI::connect_mysql($dnbane, $user, $pass, $host);
	
=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO


LEOCHARRE::Database::Base
DBI

=cut



