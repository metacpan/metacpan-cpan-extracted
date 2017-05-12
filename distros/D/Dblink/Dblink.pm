package Dblink;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Dblink ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '1.0';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Dblink macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Dblink $VERSION;

# Preloaded methods go here.

use strict;

sub new
{
	my ($Proto, $Obj_Handler) = @_;
	my ($Class, $Self);
	
	$Self  = {};
	$Class = ref($Proto) || $Proto;
	bless($Self, $Class);
	
	return $Self;
}

sub Dprint
{
  if ($main::DEBUG) 
	{ 
		print @_; 
	  if ($main::STDIN)
		{
			print "Press <Enter> To Continue .. \n";
		  <STDIN>;
		};
	}
}

sub create_remote_view
{
	my ($Pack, $SDbh, $DDbh, $Prepend, $Table) = @_;
	my ($Ret, $Viewname, $Select_Query, $Records);
	my ($Dbh);

	if (!$SDbh || !$DDbh || !$Table)
	{
		print "DBLINK-ERROR: create_remote_view() Invalid parameters\n";
		return 'ERROR';
	}

  $Prepend  = "dbl_" if (!$Prepend);
	$Viewname = $Prepend . $Table;

	($Ret, @{$Records})	=	$Pack->_get_fields_and_types($SDbh, $Table);
	return $Ret if ($Ret eq 'ERROR');

	($Ret, $Select_Query)	=	$Pack->_dblink_select_query($Table, $Records, '');
	return $Ret if ($Ret eq 'ERROR');

  print "Creating remote view for $Table ... ";
	$Ret	=	$Pack->_create_view($DDbh, $Viewname, $Select_Query);
  if ($Ret eq 'ERROR')
  {
    print "failed.\n";
    print "$DBI::errstr\n";
    return $Ret;
  }
  else
  {
    print "success.\n";
    return $Ret;
  }
}

# This function returns the fields, types of a particular table.
sub _get_fields_and_types
{
	my ($Pack, $Dbh, $Table) = @_;
	my ($Ret, $Sth, $Sql, $Records);

	if (!$Table)
	{
		print "DBLINK-ERROR: Get_Fields() Invalid parameters\n";
		return 'ERROR';
	}

	$Sql 	= "SELECT a.attname, t.typname from pg_attribute a, pg_class c, pg_type t where a.attrelid = c.oid and c.relkind = 'r' and a.attnum > 0 and c.relname = '$Table' and a.atttypid = t.oid and a.attisdropped is false ORDER BY attnum ASC";
  Dprint "Table :$Table:\n";
	$Sth = $Dbh->prepare($Sql);
	$Sth->execute();
	$Records = $Sth->fetchall_arrayref;
	$Sth->finish();

	return wantarray() ? ('SUCCESS', @{$Records}) : 'SUCCESS';
}

sub _dblink_select_query
{
	my ($Pack, $Table, $Records, $Distinct)	=	@_;
	my ($Ret, $Sql, $Pointer, $Select_Query, $Record);

	if (!$Table || !$Records)
	{
		print "DBLINK-ERROR: Dblink_Select_Query() Invalid parameters\n";
		return 'ERROR';
	}

	($Ret, $Sql, $Pointer)		=	$Pack->_dblink_selects($Distinct, $Table, $Records);
	return $Ret if ($Ret eq 'ERROR');

	$Select_Query	=	"SELECT ";
	foreach $Record (@{$Records}) { $Select_Query	.=	$Record->[0]. ', '; }
	$Select_Query	=~ s/,\s*$//g;

	$Select_Query .= " FROM dblink('$Sql') as t($Pointer)";

	return wantarray() ? ('SUCCESS', $Select_Query) : 'SUCCESS';
}

sub _dblink_selects
{
	my ($Pack, $Distinct, $Table, $Records)	=	@_;
	my ($Field, $Fieldnum, $Fieldname, $Datatype, $Sql, $Pointer);

	if (!$Records)
	{
		print "DBLINK-ERROR: Dblink_Selects() Invalid parameters\n";
		return 'ERROR';
	}
	
	if ($Distinct) { $Sql = "SELECT DISTINCT "; }
	else           { $Sql = "SELECT ";          }

	foreach $Fieldnum ( 0 .. $#$Records)
	{
		$Fieldname	=	$$Records[$Fieldnum][0];
		$Datatype   =	$$Records[$Fieldnum][1];

		$Sql     .= "$Fieldname, ";
		$Pointer .= "$Fieldname $Datatype, ";
	}
	$Sql     =~ s/,\s*$//g;
	$Pointer =~ s/,\s*$//g;

	$Sql .= " FROM $Table";
	return wantarray() ? ('SUCCESS', $Sql, $Pointer) : 'SUCCESS';
}

sub _get_field_number
{
	my ($Pack, $Dbh, $Table, $Fieldname) = @_;
	my ($Ret, $Sql, $Fields);

	if (!$Table || !$Fieldname)
	{
		print "DBLINK-ERROR: Get_Field_Number() Invalid parameters\n";
		return 'ERROR';
	}
	
	$Sql  = "select a.attnum from pg_attribute a, pg_class b where a.attname = '$Fieldname' and a.attrelid = b.oid and b.relname = '$Table'";
	$Fields = $Dbh->selectcol_arrayref($Sql);
	return wantarray() ? ('SUCCESS', $$Fields[0]) : 'SUCCESS';
}

sub _create_view
{
	my ($Pack, $Dbh, $Viewname, $Select_Query)	=	@_;
	my ($Ret, $Sth, $Viewsql);

	if (!$Viewname || !$Select_Query)
	{
		print "DBLINK-ERROR: Create_View() Invalid parameters\n";
		return 'ERROR';
	}

	$Viewsql	=	"CREATE VIEW $Viewname AS " .  $Select_Query;
	Dprint "Viewsql :$Viewsql:\n";

	$Sth = $Dbh->prepare($Viewsql);
  $Ret = $Sth->execute();
	if (!$Ret) { return 'ERROR'; 	 }
	else       { return 'SUCCESS'; }
}

sub _dblink_connect
{
	my ($Pack, $id) = @_;
	my ($Ret, $Sth, $Dbh, $Sql);
  my ($Params);

  $Params = $Pack->get_db_params($id);
	$Sql = "SELECT dblink_connect($Params)";
	$Sth = $Dbh->prepare($Sql);
	$Ret = $Sth->execute($Sql);
	$Sth->finish();

	if ($Ret == -1 || !$Ret) { return 'ERROR'; }
	print "dblink_connect() is successful\n";
	return 'SUCCESS';
}

sub get_db_params
{
  my ($Pack, $index) = @_;
  my ($host, $port, $db, $user, $pass, $db_params, @content);

  open (CFILE, $main::CFILE) || die "$main::CFILE: $!";
  @content = <CFILE>;
  close(CFILE);

  $db_params = $content[$index];
  chop($db_params);
  ($host, $port, $db, $user, $pass) = split(/:/, $db_params);

  $host = 'localhost' if (!$host);
  $port = 5432 if (!$port);
  $db   = $ENV{'LOGNAME'} if (!$db);
  $user = $ENV{'LOGNAME'} if (!$user);

	return wantarray() ? ($host, $port, $db, $user, $pass) : 
  "hostaddr=$host port=$port dbname=$db user=$user password=$pass";
}

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Dblink - Perl Wrapper for postgresql dblink contrib module

=head1 SYNOPSIS

  use Dblink;

Dblink is a perl wrapper for postgresql dblink contrib module. Refer the document on dblink contrib which is shipped with the source of postgresql for details.

=head1 DESCRIPTION

Before using this module, please ensure to install dblink 0.5 contrib module in the destination postgresql database. If it is not installed, the creation of the remote view would fail.

This module is available along with the source code of postgresql. If you have not yet downloaded the source code of postgresql, you can visit the below link to know the postgresql mirror websites. Locate one of the nearest mirror and download postgresql.

www.postgresql.org/mirrors-ftp.html

create_remote_view(sdbh, ddbh, prepend, table);

  sdbh 
    source database handle (returned by DBI->connect)
  ddbh 
    dest. database handle (returned by DBI->connect)
  prepend 
    text to be prepended to the view (default: dbl_)
  table 
    table for which the view is to be created

If the table is foo, then the name of the view is dbl_foo.

Should you require further clarification, please contact me.

=head1 AUTHOR

A.Bhuvaneswaran <bhuvan@symonds.net>

Feel free to contact me. Please don't forget to mention the version you use.

=head1 SEE ALSO

L<perl(1)>, L<DBI(1)>, 

README.dblink which is shipped with postgresql source

=cut
