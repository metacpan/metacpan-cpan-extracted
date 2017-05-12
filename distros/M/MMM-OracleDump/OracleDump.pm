package MMM::OracleDump;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( 
	get_table_list
);
$VERSION = '0.01';



sub get_table_list {
	my $dbh = shift;
	my $sql = qq/ SELECT TABLE_NAME FROM CAT WHERE TABLE_TYPE='TABLE' /;
	my $qh = $dbh->prepare($sql);
	$qh->execute();
	my @tables;
	my $row;
	while ($row = $qh->fetch() ) {
		push @tables, $row->[0];
	}
	$qh->finish;
	return @tables;
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

OracleDump - Perl extension for blah blah blah

=head1 SYNOPSIS

  use OracleDump;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for OracleDump was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
