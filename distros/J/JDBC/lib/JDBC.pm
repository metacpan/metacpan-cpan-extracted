package JDBC;

use warnings;
use strict;

=head1 NAME

JDBC - Perl 5 interface to Java JDBC (via Inline::Java)

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use JDBC;

    JDBC->load_driver("org.apache.derby.jdbc.EmbeddedDriver");

    my $con = JDBC->getConnection($url, "test", "test");

    my $s = $con->createStatement();

    $s->executeUpdate("create table foo (foo int, bar varchar(200), primary key (foo))");
    $s->executeUpdate("insert into foo (foo, bar) values (42,'notthis')");
    $s->executeUpdate("insert into foo (foo, bar) values (43,'notthat')");

    my $rs = $s->executeQuery("select foo, bar from foo");
    while ($rs->next) {
	my $foo = $rs->getInt(1);
	my $bar = $rs->getString(2);
	print "row: foo=$foo, bar=$bar\n";
    }

=head1 DESCRIPTION

This JDBC module provides an interface to the Java C<java.sql.*> and
C<javax.sql.*> JDBC APIs.

=cut

our @ISA = qw(Exporter java::sql::DriverManager);

{   # the Inline package needs to be use'd in main in order to
    # get the studied classes to be rooted in main
    package main;
    use Inline ( Java => q{ }, AUTOSTUDY => 1 );
}

use Inline::Java qw(cast caught study_classes);

our @EXPORT_OK = qw(cast caught study_classes);

our $debug = $ENV{PERL_JDBC_DEBUG} || 0;

#java.sql.ParameterMetaData 
my @classes = (qw(
    java.sql.Array 
    java.sql.BatchUpdateException 
    java.sql.Blob 
    java.sql.CallableStatement 
    java.sql.Clob 
    java.sql.Connection 
    java.sql.DataTruncation 
    java.sql.DatabaseMetaData 
    java.sql.Date 
    java.sql.Driver 
    java.sql.DriverManager 
    java.sql.DriverPropertyInfo 
    java.sql.PreparedStatement 
    java.sql.Ref 
    java.sql.ResultSet
    java.sql.ResultSetMetaData 
    java.sql.SQLData 
    java.sql.SQLException 
    java.sql.SQLInput 
    java.sql.SQLOutput 
    java.sql.SQLPermission 
    java.sql.SQLWarning 
    java.sql.Savepoint 
    java.sql.Statement 
    java.sql.Struct 
    java.sql.Time 
    java.sql.Timestamp 
    java.sql.Types 
    javax.sql.ConnectionEvent 
    javax.sql.ConnectionEventListener 
    javax.sql.ConnectionPoolDataSource 
    javax.sql.DataSource 
    javax.sql.PooledConnection 
    javax.sql.RowSet 
    javax.sql.RowSetEvent 
    javax.sql.RowSetInternal 
    javax.sql.RowSetListener 
    javax.sql.RowSetMetaData 
    javax.sql.RowSetReader 
    javax.sql.RowSetWriter 
    javax.sql.XAConnection 
    javax.sql.XADataSource 
));

warn "studying classes\n" if $debug;
study_classes(\@classes, 'main');

#Fix a long-standing bug due to changes in @ISA caching introduced in perl 5.10.0.
#See  http://perldoc.perl.org/perl5100delta.html (search for "mro").
#RT 1/5/14.
#
#force a reset of the @ISA cache after injecting java.sql.DriverManager, which we inherit from:
@ISA = @ISA;

# Driver => java.sql.Driver, RowSet => javax.sql.RowSet etc
my %class_base   = map { m/^(.*\.(\w+))$/ or die; (  $2  => $1) } @classes;

# :Driver => java::sql::Driver, :RowSet => javax::sql::RowSet etc
my %import_class = map {
    (my $pkg = $class_base{$_}) =~ s/\./::/g;
    (":$_" => $pkg)
} keys %class_base;


sub import {
    my $pkg = shift;
    my $callpkg = caller($Exporter::ExportLevel);

    # deal with :ClassName imports as a special case
    my %done;
    for my $symbol (@_) {
	# is it a valid JDBC class?
	next unless my $java_pkg = $import_class{$symbol};

	no strict 'refs';
	# get list of "constants" which I've defined as symbols with
	# all-uppercase names that also have defined scalar values
	# (which also avoids perl baggage like ISA, TIEHASH, DESTROY)
	my @const = grep {
	    /^[A-Z][_A-Z0-9]*$/ and defined ${$java_pkg.'::'.$_}
	} keys %{ $java_pkg.'::' };

	# now export those as real perl constants
	warn "import $symbol ($java_pkg): @const" if $debug;
	for my $const (@const) {
	    no strict 'refs';
	    my $scalar = ${"$java_pkg\::$const"};
	    *{"$callpkg\::$const"} = sub () { $scalar };
	}
	++$done{$symbol};
    }
    @_ = grep { !$done{$_} } @_; # remove symbols we've now dealt with

    return if !@_ and %done; # we've dealt with all there was
    # else call standard import to handle anything else
    local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
    return $pkg->SUPER::import(@_);
}

=head1 METHODS

=head2 load_driver

The load_driver() method is used to load a driver class.

  JDBC->load_driver($driver_class)

is equivalent to the Java:

  java.lang.Class.forName(driver_class).newInstance();

=cut

sub load_driver {
    my ($self, $class) = @_;
    study_classes([$class], 'main');
}

# override getDrivers to return an Enumeration (not private class)

sub getDrivers {
    return cast('java.util.Enumeration', shift->SUPER::getDrivers)
}

=head1 FUNCTIONS

=head2 cast

=head2 caught

=head2 study_classes

The cast(), caught(), and study_classes() functions of Inline::Java are also
optionally exported by the JDBC module.

=cut

=head1 IMPORTING CONSTANTS

Java JDBC makes use of constants defined in 

  import java.sql.*;
  ...
  stmt = con.prepareStatement(PreparedStatement.SELECT);

the package can also be specified with the C<import> which then avoids the need
to prefix the constant with the class:

  import java.sql.PreparedStatement;
  ...
  stmt = con.prepareStatement(SELECT);

In Perl the corresponding code can be either:

  use JDBC;
  ...
  $stmt = $con->prepareStatement($java::sql::PrepareStatement::SELECT);

or, the rather more friendly:

  use JDBC qw(:PreparedStatement);
  ...
  $stmt = $con->prepareStatement(SELECT);

When importing a JDBC class in this way the JDBC module only imports defined
scalars with all-uppercase names, and it turns them into perl constants so the
C<$> is no longer needed.

All constants in all the java.sql and javax.sql classes can be imported in this way.

=cut

warn "running\n" if $debug;

1; # End of JDBC

__END__

=head1 WHY

=head2 Why did I create this module?

Because it will help the design of DBI v2.

=head2 How will it help the design of DBI v2?

Well, "the plan" is to clearly separate the driver interface from the Perl DBI.
The driver interface will be defined at the Parrot level and so, it's hoped,
that a single set of drivers can be shared by all languages targeting Parrot.

Each language would then have their own thin 'adaptor' layered over the Parrot
drivers. For Perl that'll be the Perl DBIv2.

So before getting very far designing DBI v2 there's a need to design the
underlying driver interface. Java JDBC can serve as a useful role model.
(Many of the annoyances of Java JDBC and actually annoyances of Java and so
cease to be relevant for Parrot.)

As part of the DBI v2 work I'll probably write a "PDBC" module as a layer over
this JDBC module. Then DBI v2 will target the PDBC module and the PDBC module
will capture the differences between plain JDBC API and the Parrot driver API.

=head1 SEE ALSO

L<Inline::Java>

=head1 AUTHOR

Tim Bunce, C<< <Tim.Bunce@pobox.com> >>

=head1 BUGS

Firstly try to determine if the problem is related to the JDBC module itself
or, more likely, the underlying Inline::Java module.

Please report any bugs or feature requests for JDBC to
C<bug-jdbc@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JDBC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Please report any bugs or feature requests for Inline::Java to the Inline::Java
mailing list.

C<Inline::Java>'s mailing list is <inline@perl.org>.
To subscribe, send an email to <inline-subscribe@perl.org>

C<Inline::Java>'s home page is http://inline.perl.org/java/

=head1 ACKNOWLEDGEMENTS

Thanks to Patrick LeBoutillier for creating Inline::Java.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Tim Bunce, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
# vim: sw=4
