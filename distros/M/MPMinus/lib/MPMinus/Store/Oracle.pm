package MPMinus::Store::Oracle; # $Id: Oracle.pm 266 2019-04-26 15:56:05Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Store::Oracle - Oracle MPMinus::Store::DBI interface

=head1 VERSION

Version 1.53

=head1 SYNOPSIS

    use MPMinus::Store::Oracle;

    # Oracle connect
    my $oracle = new MPMinus::Store::Oracle (
        -m          => $m, # OPTIONAL
        -host       => '192.168.1.1',
        -database   => 'TEST',
        -user       => 'login',
        -pass       => 'password',
        -attr       => {
                RaiseError => 0,
                PrintError => 0,
            },
    )

    my $dbh = $oracle->connect;

    my $pingstat = $oracle->ping if $oracle;

    # Table select (as array)
    my @result = $oracle->table($sql, @inargs);

    # Table select (as hash)
    my %result = $oracle->tableh($key, $sql, @inargs); # $key - primary index field name

    # Record (as array)
    my @result = $oracle->record($sql, @inargs);

    # Record (as hash)
    my %result = $oracle->recordh($sql, @inargs);

    # Fiels (as scalar)
    my $result = $oracle->field($sql, @inargs);

    # SQL/PL-SQL
    my $sth = $oracle->execute($sql, @inargs);
    ...
    $sth->finish;

=head1 DESCRIPTION

Oracle MPMinus::Store::DBI interface

See L<MPMinus::Store::DBI>

=head2 new

See L<MPMinus::Store::DBI>

=head1 EXAMPLE

    use MPMinus::Store::Oracle;

    my $oracle = new MPMinus::Store::Oracle (
            -name => 'mylocaldb',
            -user => 'root',
            -password => 'password'
      );

    my @table = $oracle->table("select * from tablename where date = ?", "01.01.2000")

=head1 HISTORY

=over 8

=item B<1.00 / 11.04.2007>

Init version

=item B<1.10 / 26.03.2008>

OOP style supported

=item B<1.20 / 01.04.2008>

Module movied to global level

=item B<1.40 / 27.02.2009>

Module movied to MPMinus level

=item B<1.51 / 19.04.2010>

Added in MPMinus poject

=item B<1.41 / Wed Apr 24 14:53:38 2013 MSK>

General refactoring

=back

See C<CHANGES> file

=head1 DEPENDENCIES

L<MPMinus::Store::DBI>, L<DBD::Oracle>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<MPMinus::Store::DBI>, L<DBD::Oracle>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = 1.53;

use MPMinus::Store::DBI;
use CTK::Util qw/ :API /;

sub new {
    my $class = shift;
    my @in = read_attributes(MPMinus::Store::DBI::ATTR_NAMES,@_);
    my %args = (
            -driver => 'Oracle',
            -host   => $in[2],
            -name   => $in[3],
            -user   => $in[5],
            -pass   => $in[6],
            -attr   => $in[10],
        );
    return new MPMinus::Store::DBI(%args);
}

1;
