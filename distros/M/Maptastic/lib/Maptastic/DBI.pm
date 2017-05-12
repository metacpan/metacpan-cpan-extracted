
package Maptastic::DBI;

use strict;
use 5.004;   # for ->(), thanks Chip+Randal! :)

use Carp;
use Exporter;
use vars qw(@ISA @EXPORT);

BEGIN {
	@ISA = qw(Exporter);
	@EXPORT = qw(row_iter);
}

sub row_iter {
        my $dbh = shift;
	ref($dbh) && UNIVERSAL::can($dbh, "prepare") or
		croak "row_iter requires a database handle";
        my $sql = pop;
        my @args = @_;
        my $sth;
        my @putback;
        my $deplete;
        sub {
                if ( @_ ) {
                        push @putback, @_;
                        return ();
                }
                elsif ( @putback ) {
                        return pop @putback;
                }
                if ( !$sth and !$sql ) {
                        return undef;
                }
                if ( !$sth ) {
                        if ( ref $sql ) {
                                $sth = $sql;
                        }
                        else {
                                $sth = $dbh->prepare($sql)
                                        or die $dbh->errstr;
                        }
                        $sth->execute(@args) or die $sth->errstr;
                }
                my $rv = $sth->fetchrow_hashref;
                if ( !$rv ) {
                        $sth->finish;
                        undef($sth);
                        undef($sql);
                };
                $rv;
        }
}

1;

__END__

=head1 NAME

Maptastic::DBI - a trivial little wrapper for a row iterator

=head1 SYNOPSIS

 use Maptastic::DBI;

 # the SQL statement (or DBI statement handle, if you prefer)
 # is the last argument
 my $ri = row_iter($dbh, $box, <<SQL);
 select item
 from   boxes
 where  box = ?
 SQL

 while ( my $row = $ri->() ) {
     #...
 }

 # you can also put items back
 $ri->($item);

 # With Maptastic, grab all the rows at once.
 use Maptastic;
 my @rows = slurp row_iter($dbh, $sql);


=head1 DESCRIPTION

This module contains a very simple wrapper for DBI calls, designed for
fans of I<iterators>.  It just wraps the usual:

  my $sth = $dbh->prepare(<<SQL);
  select
     foo
  from
     bar
  where
     baz = ?
  SQL
  $sth->execute($baz);
  while (my $row = $sth->fetchrow_hashref) {

  }

into:

  my $ri = row_iter($dbh, $baz, <<SQL);
  while (my $row = $ri->()) {

  }

=head1 SEE ALSO

_Higher Order Perl_, Mark Jason Dominus.

=head1 AUTHOR AND LICENSE

Copyright (c) 2007, Catalyst IT (NZ) Ltd.  All rights reserved.  This
program is free software; you may use it, and/or distribute it under
the same terms as Perl itself.

=cut
