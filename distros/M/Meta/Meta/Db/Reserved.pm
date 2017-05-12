#!/bin/echo This is a perl module and should not be run

package Meta::Db::Reserved;

use strict qw(vars refs subs);
use Meta::Ds::Set qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.06";
@ISA=qw();

#sub BEGIN();
#sub check($);
#sub make_sure($);
#sub TEST($);

#__DATA__

our($set);

sub BEGIN() {
	$set=Meta::Ds::Set->new();

	$set->insert("ABS");
	$set->insert("ABSOLUTE");
	$set->insert("ACCESS");
	$set->insert("ACTION");
	$set->insert("ADA");
	$set->insert("ADD");
	$set->insert("ADMIN");
	$set->insert("AFTER");
	$set->insert("AGGREGATE");
	$set->insert("ALIAS");
	$set->insert("ALL");
	$set->insert("ALLOCATE");
	$set->insert("ALTER");
	$set->insert("ANALYSE");
	$set->insert("ANALYZE");
	$set->insert("AND");
	$set->insert("ANY");
	$set->insert("ARE");
	$set->insert("ARRAY");
	$set->insert("AS");
	$set->insert("ASC");
	$set->insert("ASENSITIVE");
	$set->insert("ASSERTION");
	$set->insert("ASSIGNMENT");
	$set->insert("ASYMMETRIC");
	$set->insert("AT");
	$set->insert("ATOMIC");
	$set->insert("AUTHORIZATION");
	$set->insert("AVG");
	$set->insert("BACKWARD");
	$set->insert("BEFORE");
	$set->insert("BEGIN");
	$set->insert("BETWEEN");
	$set->insert("BINARY");
	$set->insert("BIT");
	$set->insert("BITVAR");
	$set->insert("BIT_LENGTH");
	$set->insert("BLOB");
	$set->insert("BOOLEAN");
	$set->insert("BOTH");
	$set->insert("BREADTH");
	$set->insert("BY");
	$set->insert("C");
	$set->insert("CACHE");
	$set->insert("CALL");
	$set->insert("CALLED");
	$set->insert("CARDINALITY");
	$set->insert("CASCADE");
	$set->insert("CASCADED");
	$set->insert("CASE");
	$set->insert("CAST");
	$set->insert("CATALOG");
	$set->insert("CATALOG_NAME");
	$set->insert("CHAIN");
	$set->insert("CHAR");
	$set->insert("CHARACTER");
	$set->insert("CHARACTERISTICS");
	$set->insert("CHARACTER_LENGTH");
	$set->insert("CHARACTER_SET_CATALOG");
	$set->insert("CHARACTER_SET_NAME");
	$set->insert("CHARACTER_SET_SCHEMA");
	$set->insert("CHAR_LENGTH");
	$set->insert("CHECK");
	$set->insert("CHECKED");
	$set->insert("CHECKPOINT");
	$set->insert("CLASS");
	$set->insert("CLASS_ORIGIN");
	$set->insert("CLOB");
	$set->insert("CLOSE");
	$set->insert("CLUSTER");
	$set->insert("COALESCE");
	$set->insert("COBOL");
	$set->insert("COLLATE");
	$set->insert("COLLATION");
	$set->insert("COLLATION_CATALOG");
	$set->insert("COLLATION_NAME");
	$set->insert("COLLATION_SCHEMA");
	$set->insert("COLUMN");
	$set->insert("COLUMN_NAME");
	$set->insert("COMMAND_FUNCTION");
	$set->insert("COMMAND_FUNCTION_CODE");
	$set->insert("COMMENT");
	$set->insert("COMMIT");
	$set->insert("COMMITTED");
	$set->insert("COMPLETION");
	$set->insert("CONDITION_NUMBER");
	$set->insert("CONNECT");
	$set->insert("CONNECTION");
	$set->insert("CONNECTION_NAME");
	$set->insert("CONSTRAINT");
	$set->insert("CONSTRAINTS");
	$set->insert("CONSTRAINT_CATALOG");
	$set->insert("CONSTRAINT_NAME");
	$set->insert("CONSTRAINT_SCHEMA");
	$set->insert("CONSTRUCTOR");
	$set->insert("CONTAINS");
	$set->insert("CONTINUE");
	$set->insert("CONVERT");
	$set->insert("COPY");
	$set->insert("CORRESPONDING");
	$set->insert("COUNT");
	$set->insert("CREATE");
	$set->insert("CREATEDB");
	$set->insert("CREATEUSER");
	$set->insert("CROSS");
	$set->insert("CUBE");
	$set->insert("CURRENT");
	$set->insert("CURRENT_DATE");
	$set->insert("CURRENT_PATH");
	$set->insert("CURRENT_ROLE");
	$set->insert("CURRENT_TIME");
	$set->insert("CURRENT_TIMESTAMP");
	$set->insert("CURRENT_USER");
	$set->insert("CURSOR");
	$set->insert("CURSOR_NAME");
	$set->insert("CYCLE");
	$set->insert("DATA");
	$set->insert("DATABASE");
	$set->insert("DATE");
	$set->insert("DATETIME_INTERVAL_CODE");
	$set->insert("DATETIME_INTERVAL_PRECISION");
	$set->insert("DAY");
	$set->insert("DEALLOCATE");
	$set->insert("DEC");
	$set->insert("DECIMAL");
	$set->insert("DECLARE");
	$set->insert("DEFAULT");
	$set->insert("DEFERRABLE");
	$set->insert("DEFERRED");
	$set->insert("DEFINED");
	$set->insert("DEFINER");
	$set->insert("DELETE");
	$set->insert("DELIMITERS");
	$set->insert("DEPTH");
	$set->insert("DEREF");
	$set->insert("DESC");
	$set->insert("DESCRIBE");
	$set->insert("DESCRIPTOR");
	$set->insert("DESTROY");
	$set->insert("DESTRUCTOR");
	$set->insert("DETERMINISTIC");
	$set->insert("DIAGNOSTICS");
	$set->insert("DICTIONARY");
	$set->insert("DISCONNECT");
	$set->insert("DISPATCH");
	$set->insert("DISTINCT");
	$set->insert("DO");
	$set->insert("DOMAIN");
	$set->insert("DOUBLE");
	$set->insert("DROP");
	$set->insert("DYNAMIC");
	$set->insert("DYNAMIC_FUNCTION");
	$set->insert("DYNAMIC_FUNCTION_CODE");
	$set->insert("EACH");
	$set->insert("ELSE");
	$set->insert("ENCODING");
	$set->insert("END");
	$set->insert("END-EXEC");
	$set->insert("EQUALS");
	$set->insert("ESCAPE");
	$set->insert("EVERY");
	$set->insert("EXCEPT");
	$set->insert("EXCEPTION");
	$set->insert("EXCLUSIVE");
	$set->insert("EXEC");
	$set->insert("EXECUTE");
	$set->insert("EXISTING");
	$set->insert("EXISTS");
	$set->insert("EXPLAIN");
	$set->insert("EXTEND");
	$set->insert("EXTERNAL");
	$set->insert("EXTRACT");
	$set->insert("FALSE");
	$set->insert("FETCH");
	$set->insert("FINAL");
	$set->insert("FIRST");
	$set->insert("FLOAT");
	$set->insert("FOR");
	$set->insert("FORCE");
	$set->insert("FOREIGN");
	$set->insert("FORTRAN");
	$set->insert("FORWARD");
	$set->insert("FOUND");
	$set->insert("FREE");
	$set->insert("FROM");
	$set->insert("FULL");
	$set->insert("FUNCTION");
	$set->insert("G");
	$set->insert("GENERAL");
	$set->insert("GENERATED");
	$set->insert("GET");
	$set->insert("GLOBAL");
	$set->insert("GO");
	$set->insert("GOTO");
	$set->insert("GRANT");
	$set->insert("GRANTED");
	$set->insert("GROUP");
	$set->insert("GROUPING");
	$set->insert("HANDLER");
	$set->insert("HAVING");
	$set->insert("HIERARCHY");
	$set->insert("HOLD");
	$set->insert("HOST");
	$set->insert("HOUR");
	$set->insert("IDENTITY");
	$set->insert("IGNORE");
	$set->insert("ILIKE");
	$set->insert("IMMEDIATE");
	$set->insert("IMPLEMENTATION");
	$set->insert("IN");
	$set->insert("INCREMENT");
	$set->insert("INDEX");
	$set->insert("INDICATOR");
	$set->insert("INFIX");
	$set->insert("INHERITS");
	$set->insert("INITIALIZE");
	$set->insert("INITIALLY");
	$set->insert("INNER");
	$set->insert("INOUT");
	$set->insert("INPUT");
	$set->insert("INSENSITIVE");
	$set->insert("INSERT");
	$set->insert("INSTANCE");
	$set->insert("INSTANTIABLE");
	$set->insert("INSTEAD");
	$set->insert("INT");
	$set->insert("INTEGER");
	$set->insert("INTERSECT");
	$set->insert("INTERVAL");
	$set->insert("INTO");
	$set->insert("INVOKER");
	$set->insert("IS");
	$set->insert("ISNULL");
	$set->insert("ISOLATION");
	$set->insert("ITERATE");
	$set->insert("JOIN");
	$set->insert("K");
	$set->insert("KEY");
	$set->insert("KEY_MEMBER");
	$set->insert("KEY_TYPE");
	$set->insert("LANCOMPILER");
	$set->insert("LANGUAGE");
	$set->insert("LARGE");
	$set->insert("LAST");
	$set->insert("LATERAL");
	$set->insert("LEADING");
	$set->insert("LEFT");
	$set->insert("LENGTH");
	$set->insert("LESS");
	$set->insert("LEVEL");
	$set->insert("LIKE");
	$set->insert("LIMIT");
	$set->insert("LISTEN");
	$set->insert("LOAD");
	$set->insert("LOCAL");
	$set->insert("LOCALTIME");
	$set->insert("LOCALTIMESTAMP");
	$set->insert("LOCATION");
	$set->insert("LOCATOR");
	$set->insert("LOCK");
	$set->insert("LOWER");
	$set->insert("M");
	$set->insert("MAP");
	$set->insert("MATCH");
	$set->insert("MAX");
	$set->insert("MAXVALUE");
	$set->insert("MESSAGE_LENGTH");
	$set->insert("MESSAGE_OCTET_LENGTH");
	$set->insert("MESSAGE_TEXT");
	$set->insert("METHOD");
	$set->insert("MIN");
	$set->insert("MINUTE");
	$set->insert("MINVALUE");
	$set->insert("MOD");
	$set->insert("MODE");
	$set->insert("MODIFIES");
	$set->insert("MODIFY");
	$set->insert("MODULE");
	$set->insert("MONTH");
	$set->insert("MORE");
	$set->insert("MOVE");
	$set->insert("MUMPS");
	$set->insert("NAME");
	$set->insert("NAMES");
	$set->insert("NATIONAL");
	$set->insert("NATURAL");
	$set->insert("NCHAR");
	$set->insert("NCLOB");
	$set->insert("NEW");
	$set->insert("NEXT");
	$set->insert("NO");
	$set->insert("NOCREATEDB");
	$set->insert("NOCREATEUSER");
	$set->insert("NONE");
	$set->insert("NOT");
	$set->insert("NOTHING");
	$set->insert("NOTIFY");
	$set->insert("NOTNULL");
	$set->insert("NULL");
	$set->insert("NULLABLE");
	$set->insert("NULLIF");
	$set->insert("NUMBER");
	$set->insert("NUMERIC");
	$set->insert("OBJECT");
	$set->insert("OCTET_LENGTH");
	$set->insert("OF");
	$set->insert("OFF");
	$set->insert("OFFSET");
	$set->insert("OIDS");
	$set->insert("OLD");
	$set->insert("ON");
	$set->insert("ONLY");
	$set->insert("OPEN");
	$set->insert("OPERATION");
	$set->insert("OPERATOR");
	$set->insert("OPTION");
	$set->insert("OPTIONS");
	$set->insert("OR");
	$set->insert("ORDER");
	$set->insert("ORDINALITY");
	$set->insert("OUT");
	$set->insert("OUTER");
	$set->insert("OUTPUT");
	$set->insert("OVERLAPS");
	$set->insert("OVERLAY");
	$set->insert("OVERRIDING");
	$set->insert("OWNER");
	$set->insert("PAD");
	$set->insert("PARAMETER");
	$set->insert("PARAMETERS");
	$set->insert("PARAMETER_MODE");
	$set->insert("PARAMETER_NAME");
	$set->insert("PARAMETER_ORDINAL_POSITION");
	$set->insert("PARAMETER_SPECIFIC_CATALOG");
	$set->insert("PARAMETER_SPECIFIC_NAME");
	$set->insert("PARAMETER_SPECIFIC_SCHEMA");
	$set->insert("PARTIAL");
	$set->insert("PASCAL");
	$set->insert("PASSWORD");
	$set->insert("PATH");
	$set->insert("PENDANT");
	$set->insert("PLI");
	$set->insert("POSITION");
	$set->insert("POSTFIX");
	$set->insert("PRECISION");
	$set->insert("PREFIX");
	$set->insert("PREORDER");
	$set->insert("PREPARE");
	$set->insert("PRESERVE");
	$set->insert("PRIMARY");
	$set->insert("PRIOR");
	$set->insert("PRIVILEGES");
	$set->insert("PROCEDURAL");
	$set->insert("PROCEDURE");
	$set->insert("PUBLIC");
	$set->insert("READ");
	$set->insert("READS");
	$set->insert("REAL");
	$set->insert("RECURSIVE");
	$set->insert("REF");
	$set->insert("REFERENCES");
	$set->insert("REFERENCING");
	$set->insert("REINDEX");
	$set->insert("RELATIVE");
	$set->insert("RENAME");
	$set->insert("REPEATABLE");
	$set->insert("RESET");
	$set->insert("RESTRICT");
	$set->insert("RESULT");
	$set->insert("RETURN");
	$set->insert("RETURNED_LENGTH");
	$set->insert("RETURNED_OCTET_LENGTH");
	$set->insert("RETURNED_SQLSTATE");
	$set->insert("RETURNS");
	$set->insert("REVOKE");
	$set->insert("RIGHT");
	$set->insert("ROLE");
	$set->insert("ROLLBACK");
	$set->insert("ROLLUP");
	$set->insert("ROUTINE");
	$set->insert("ROUTINE_CATALOG");
	$set->insert("ROUTINE_NAME");
	$set->insert("ROUTINE_SCHEMA");
	$set->insert("ROW");
	$set->insert("ROWS");
	$set->insert("ROW_COUNT");
	$set->insert("RULE");
	$set->insert("SAVEPOINT");
	$set->insert("SCALE");
	$set->insert("SCHEMA");
	$set->insert("SCHEMA_NAME");
	$set->insert("SCOPE");
	$set->insert("SCROLL");
	$set->insert("SEARCH");
	$set->insert("SECOND");
	$set->insert("SECTION");
	$set->insert("SECURITY");
	$set->insert("SELECT");
	$set->insert("SELF");
	$set->insert("SENSITIVE");
	$set->insert("SEQUENCE");
	$set->insert("SERIAL");
	$set->insert("SERIALIZABLE");
	$set->insert("SERVER_NAME");
	$set->insert("SESSION");
	$set->insert("SESSION_USER");
	$set->insert("SET");
	$set->insert("SETOF");
	$set->insert("SETS");
	$set->insert("SHARE");
	$set->insert("SHOW");
	$set->insert("SIMILAR");
	$set->insert("SIMPLE");
	$set->insert("SIZE");
	$set->insert("SMALLINT");
	$set->insert("SOME");
	$set->insert("SOURCE");
	$set->insert("SPACE");
	$set->insert("SPECIFIC");
	$set->insert("SPECIFICTYPE");
	$set->insert("SPECIFIC_NAME");
	$set->insert("SQL");
	$set->insert("SQLCODE");
	$set->insert("SQLERROR");
	$set->insert("SQLEXCEPTION");
	$set->insert("SQLSTATE");
	$set->insert("SQLWARNING");
	$set->insert("START");
	$set->insert("STATE");
	$set->insert("STATEMENT");
	$set->insert("STATIC");
	$set->insert("STDIN");
	$set->insert("STDOUT");
	$set->insert("STRUCTURE");
	$set->insert("STYLE");
	$set->insert("SUBCLASS_ORIGIN");
	$set->insert("SUBLIST");
	$set->insert("SUBSTRING");
	$set->insert("SUM");
	$set->insert("SYMMETRIC");
	$set->insert("SYSID");
	$set->insert("SYSTEM");
	$set->insert("SYSTEM_USER");
	$set->insert("TABLE");
	$set->insert("TABLE_NAME");
	$set->insert("TEMP");
	$set->insert("TEMPLATE");
	$set->insert("TEMPORARY");
	$set->insert("TERMINATE");
	$set->insert("THAN");
	$set->insert("THEN");
	$set->insert("TIME");
	$set->insert("TIMESTAMP");
	$set->insert("TIMEZONE_HOUR");
	$set->insert("TIMEZONE_MINUTE");
	$set->insert("TO");
	$set->insert("TOAST");
	$set->insert("TRAILING");
	$set->insert("TRANSACTION");
	$set->insert("TRANSACTIONS_COMMITTED");
	$set->insert("TRANSACTIONS_ROLLED_BACK");
	$set->insert("TRANSACTION_ACTIVE");
	$set->insert("TRANSFORM");
	$set->insert("TRANSFORMS");
	$set->insert("TRANSLATE");
	$set->insert("TRANSLATION");
	$set->insert("TREAT");
	$set->insert("TRIGGER");
	$set->insert("TRIGGER_CATALOG");
	$set->insert("TRIGGER_NAME");
	$set->insert("TRIGGER_SCHEMA");
	$set->insert("TRIM");
	$set->insert("TRUE");
	$set->insert("TRUNCATE");
	$set->insert("TRUSTED");
	$set->insert("TYPE");
	$set->insert("UNCOMMITTED");
	$set->insert("UNDER");
	$set->insert("UNION");
	$set->insert("UNIQUE");
	$set->insert("UNKNOWN");
	$set->insert("UNLISTEN");
	$set->insert("UNNAMED");
	$set->insert("UNNEST");
	$set->insert("UNTIL");
	$set->insert("UPDATE");
	$set->insert("UPPER");
	$set->insert("USAGE");
	$set->insert("USER");
	$set->insert("USER_DEFINED_TYPE_CATALOG");
	$set->insert("USER_DEFINED_TYPE_NAME");
	$set->insert("USER_DEFINED_TYPE_SCHEMA");
	$set->insert("USING");
	$set->insert("VACUUM");
	$set->insert("VALID");
	$set->insert("VALUE");
	$set->insert("VALUES");
	$set->insert("VARCHAR");
	$set->insert("VARIABLE");
	$set->insert("VARYING");
	$set->insert("VERBOSE");
	$set->insert("VERSION");
	$set->insert("VIEW");
	$set->insert("WHEN");
	$set->insert("WHENEVER");
	$set->insert("WHERE");
	$set->insert("WITH");
	$set->insert("WITHOUT");
	$set->insert("WORK");
	$set->insert("WRITE");
	$set->insert("YEAR");
	$set->insert("ZONE");

	#new reserved I found by myself
	$set->insert("CHANGE");
}

sub check($) {
	my($word)=@_;
	# spaces are not allowed
	if($word=~/\s/) {
		return(0);
	}
	# convert to upper case
	my($upcase)=CORE::uc($word);
	return($set->hasnt($upcase));
}

sub make_sure($) {
	my($word)=@_;
	if(!check($word)) {
		throw Meta::Error::Simple("word [".$word."] is an SQL reserved word");
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Reserved - checks for db related reserved words.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Reserved.pm
	PROJECT: meta
	VERSION: 0.06

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Reserved qw();
	my($result)=Meta::Db::Reserved::check("SELECTED");
	or
	Meta::Db::Reserved::make_sure("SELECTORS");

=head1 DESCRIPTION

This class is here to help you make sure that things like
database names, table names and field names are such that
databases will not have problems with them. For instance
if you call your table SELECT you can bet your life the
database will kick you out of the room. But other - more
subtle things exist. For instance - imagine that db vendor
A has a builtin function "calculate" and db vendor B
hasn't got it. You start your application using vendor B's
database and write lots of code where one of your tables
is called "calculate". Later you are required to migrate
to vendor A and the database refuses to analyze your SQL
statements because of the reserved name. Wouldn't it be
nice if you got an error about it from your development
environment right from the start ?

This is what this module is here to do. I will collect
the reserved words of many database vendors in here and
force you to select names which will be ok across all
db vendors.

The list of reserved words currently contains:
1. PostgreSQL reserved words out of the PostgreSQL
documentation.
2. MySQL reserved words out of the MySQL documentation

You are most welcome to contribute patches with lists
of words from other DB vendors (Oracle, SYBASE, DB2).

This is a tag placed in this module for source control
reasons (don't ask): SPECIAL STDERR FILE

=head1 FUNCTIONS

	BEGIN()
	check($)
	make_sure($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is an initialization method which sets up the hash
table of all the reserved words.

This is a constructor for the Meta::Db::Reserved object.

=item B<check($)>

This method will return an error code (0) if the word
given to it is a reserved word.

=item B<make_sure($)>

This method will make sure (raise an exception if not)
that a certain word is not reserved.

=item B<TEST($)>

Test suite for this object.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV import tests
	0.01 MV more thumbnail issues
	0.02 MV website construction
	0.03 MV web site automation
	0.04 MV SEE ALSO section fix
	0.05 MV web site development
	0.06 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Set(3), Meta::Error::Simple(3), strict(3)

=head1 TODO

-add sets of words and ability to select which sets to work with. do the sets according to the PostgreSQL documentation (postgress, SQL 92, SQL 99).

-make the general functionality (of reserved words and sets of words) in a papa class.

-make this class use a proper Set class and not a perl hash.

-make this class read everything from an XML files.
