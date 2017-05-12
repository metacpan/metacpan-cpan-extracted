=head1 NAME

HTML::FormEngine::DBSQL - create html/xhtml forms for adding, updating
and removing records to / in / from sql database tables

=cut

######################################################################

package HTML::FormEngine::DBSQL;
require 5.004;

# Copyright (c) 2003-2004, Moritz Sinn. This module is free software;
# you can redistribute it and/or modify it under the terms of the
# GNU GENERAL PUBLIC LICENSE, see COPYING for more information

use strict;
use vars qw(@ISA $VERSION);
use HTML::FormEngine;
@ISA = qw(HTML::FormEngine);
$VERSION = '1.01';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	Carp 1.01

=head2 Nonstandard Modules

        HTML::FormEngine 1.0
        Clone 0.13
        Hash::Merge 0.07
        Locale::gettext 1.01
        Digest::MD5 2.24
        DBI 1.42

=head1 REQUIREMENTS

  This class was only tested with PostgreSQL. Please tell me about
  your experiences with other DBMS. Thanks!

=cut

######################################################################

use Carp;
use Clone qw(clone);
use Hash::Merge qw(merge);
use Locale::gettext;
use Digest::MD5 qw(md5_hex);
use HTML::FormEngine::DBSQL::SkinClassic;

######################################################################

=head1 SYNOPSIS

=head2 Example Code

    #!/usr/bin/perl -w

    use strict;
    use HTML::FormEngine::DBSQL;
    use DBI;
    use CGI;
    #use POSIX; #for setlocale
    #setlocale(LC_MESSAGES, 'german'); #for german error messages

    my $q = new CGI;
    print $q->header;

    my $dbh = DBI->connect('dbi:Pg:dbname=test', 'test', 'test');
    my $Form = HTML::FormEngine::DBSQL->new(scalar $q->Vars, $dbh);
    $Form->dbsql_conf('user');
    $Form->make();
    print $q->start_html('FormEngine-dbsql example: User Administration');
    if($Form->ok) {
	if($_ = $Form->dbsql_insert()) {
	    print "Sucessfully added $_ user(s)!<br>";
	    $Form->clear;
	}
    }
    print $Form->get,
	  $q->end_html;
    $dbh->disconnect;

=head2 Example Database Table

Execute the following (Postgre)SQL commands to create the tables I used when developing the examples:

    CREATE SEQUENCE user_uid_seq;

    CREATE TABLE "user" (
	uid integer DEFAULT nextval('user_uid_seq'::text) NOT NULL,
	name character varying(40) NOT NULL,
	forename character varying(40) NOT NULL,
	street character varying(40) NOT NULL,
	zip integer NOT NULL,
	town character varying(40) NOT NULL,
	email character varying(40) NOT NULL,
	phone character varying(15)[] DEFAULT '{"",""}'::character varying[],
	birthday date NOT NULL,
	newsletter boolean DEFAULT true
    );

    CREATE TABLE login (
	uid integer DEFAULT currval('user_uid_seq'::text) NOT NULL,
	username character varying(30) DEFAULT '-'::character varying NOT NULL,
	"password" character varying(30) DEFAULT '-'::character varying NOT NULL
    );


    ALTER TABLE ONLY "user"
	ADD CONSTRAINT user_pkey PRIMARY KEY (uid);

    ALTER TABLE ONLY login
	ADD CONSTRAINT login_pkey PRIMARY KEY (uid);

    ALTER TABLE ONLY login
	ADD CONSTRAINT "$1" FOREIGN KEY (uid) REFERENCES "user"(uid) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

    COMMENT ON COLUMN "user".zip IS 'ERROR=digitonly;';

    COMMENT ON COLUMN "user".email IS 'ERROR=rfc822;';

    COMMENT ON COLUMN "user".phone IS 'display_as={{,}};ERROR_IN={{{not_null,digitonly},{not_null,digitonly}}};SUBTITLE={{,/}};SIZE={{5,10}};';
    COMMENT ON COLUMN login.username IS 'ERROR={{regex,"must only contain A-Z, a-z and 0-9","^[A-Za-z0-9]+$"},unique,dbsql_unique};';

    COMMENT ON COLUMN login."password" IS 'TYPE=password;VALUE=;ERROR={{regex,"must have more than 4 chars",".{5,}"}};';

Of course you can use any other table(s) as well. The file C<user.sql> in the examples directory contains the whole database dump.

=head2 Example Output

This output is produced by FormEngine::DBSQL when using the example
code, the example table and no data was submitted:

    <form action="/cgi-bin/formengine-dbsql/createuser.cgi" method="post" name="FormEngine" accept="*" enctype="application/x-www-form-urlencoded" target="_self" id="FormEngine" >
    <table border=0 cellspacing=1 cellpadding=1 align="center" >
    <tr >
    <td colspan=3>
    <table border=0 summary="">
    <tr><input type="hidden" name="uid" value="" /><input type="hidden" name="uid" value="f29e202fda026b18561398f7879cdf37" /></tr>
    <tr>
       <td valign="top" align="left" ><label for="name" accesskey="">Name</label><span ></span></td>
       <td >

	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >
		      <input type="text" value="" name="name" id="name" maxlength="40" size="20"  />

		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>

    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="name" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>
       <td valign="top" align="left" ><label for="forename" accesskey="">Forename</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >

		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >
		      <input type="text" value="" name="forename" id="forename" maxlength="40" size="20"  />
		    </td>
		    <td > &nbsp; </td>
		  </tr>

		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="forename" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>
       <td valign="top" align="left" ><label for="street" accesskey="">Street</label><span ></span></td>

       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >

		      <input type="text" value="" name="street" id="street" maxlength="40" size="20"  />
		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>

	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="street" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>
       <td valign="top" align="left" ><label for="zip" accesskey="">Zip</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >

		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >
		      <input type="text" value="" name="zip" id="zip" maxlength="" size="20"  />
		    </td>
		    <td > &nbsp; </td>

		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="zip" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>

       <td valign="top" align="left" ><label for="town" accesskey="">Town</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>

		    <td >
		      <input type="text" value="" name="town" id="town" maxlength="40" size="20"  />
		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>

	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="town" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>
       <td valign="top" align="left" ><label for="email" accesskey="">Email</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >

	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >
		      <input type="text" value="" name="email" id="email" maxlength="40" size="20"  />
		    </td>
		    <td > &nbsp; </td>

		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="email" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>

       <td valign="top" align="left" ><label for="phone" accesskey="">Phone</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>

		    <td >
		      <input type="text" value="" name="phone" id="phone" maxlength="15" size="5"  />
		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>

	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" ><label for="phone" accesskey="">/</label><span ></span> &nbsp; </td>
		    <td >
		      <input type="text" value="" name="phone" id="phone" maxlength="15" size="10"  />
		    </td>

		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
    </td>

       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="phone" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>
       <td valign="top" align="left" ><label for="birthday" accesskey="">Birthday</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >

		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >
		      <input type="text" value="" name="birthday" id="birthday" maxlength="10" size="10"  />
		    </td>
		    <td > &nbsp; </td>
		  </tr>

		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="birthday" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>
       <td valign="top" align="left" ><label for="newsletter" accesskey="">Newsletter</label><span ></span></td>

       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >


	 <select size="" name="newsletter" id="newsletter"  >
	    <option value="1" label="Yes"  >Yes</option> 
	    <option value="0" label="No"  >No</option> 
	 </select>
		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>

		</table>
	      </td>
	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="newsletter" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr>
       <td colspan=3>&nbsp;</td>
    </tr>
    </table>

    </td>
    </tr>
    <tr >
       <td align="right" colspan=3 >
	  <input type="submit" value="Ok" name="FormEngine" />
       </td>
    </tr>
    </table>

    </form>

=head1 DESCRIPTION

DBSQL.pm is an exentsion of HTML::FormEngine, that means it inherits
all functionality from HTML::FormEngine and adds some new features.

In web development, form data is mostly used to update a database. For
example most guestbooks or any similar webapplication store the
entered data in a database. Often very large forms are needed,
e.g. when the user should provide his personal data to subscribe to an
certain service.

In most cases a SQL database is used. If you don't know anything about
SQL databases or you're not using such things, this module will hardly
help you. But if you do, you'll know that every record, that you want
to store in a certain SQL database table, has to have certain fields
and these fields must contain data of an certain type (datatype).  So
the tables structure already defines how a form, that wants to add
data to this table, might look like (in case that you don't want to
process the whole data before adding it to the table).

DBSQL.pm reads out the tables structure and creates a form definition
for HTML::FormEngine.

Two examples:

A field of type boolean will only accept 0 or 1, this is represented
in the form as 'Yes' or 'No'.

a field of type VARCHAR(30) will accept strings of maximal 30
characters, so it's represented as an one-line-text-input-field in
which you can put maximal 30 characters.

Of course you can re-adjust the resulting form configuration,
but in most cases you don't have to care about it!

DBSQL.pm also provides methods for adding and updating records. So you
don't have to deal with sql commands.

HTML::FormEngine::DBSQL was only tested with B<PostgreSQL> so far, but
it should also work with other DBMS, like e.g. MySQL.

=head1 OVERVIEW

We expect that you know how to use HTML::FormEngine, if not, please
first read its documentation. Using HTML::FormEngine:DBSQL isn't much
diffrent: the C<conf> method is replaced by C<dbsql_conf> and you may
pass a database handle as second argument to the C<new> method, using
C<dbsql_set_dbh> is possible too. Before calling C<dbsql_conf>, you
may call C<dbsql_preconf> for setting some variables by hand.

To C<dbsql_conf> you pass the tables name and optionally a where
condition (for updating records) and/or a reference to an array with
fieldnames (for setting explicit which fields to show resp. not to
show).

=head1 USING FormEngine::DBSQL

=head2 Configuring The Form Through The Database

=head3 datatype handlers

In DBSQL::DtHandler.pm you'll find all datatype handlers which come
with this module. Which handler to use for which datatype is defined
in DBSQL::SkinClassic, the default FormEngine skin for this module. If
for a certain datatype no handler is defined, the default datatype
handler will be called.

A handler creates the main part of the form field configuration.

You can easily add your own datatype handlers (see below).

=head3 array handling

Though the idea how to store arrays is taken from PostgreSQL, this
should work with any other DBMS too!

In PostgreSQL every datatype can be arrayed. PostgreSQL arrays have
the following structure: '{firstelem,secondelem}', a two dimensional
array looks like this: '{{one,two},{three,four}}'.  The problem is
that PostgreSQL arrays don't have a fixed size, but FormEngine::DBSQL
need such to represent the array in the form. Here we use a trick: the
size which should be represented in the form is determined by the
default value. So a field with '{,}' as default value will be
represented as an one dimensional array (in case you specify
C<display_as> it'll be displayed according to that, see below). Of
course you can put values between the commas, which will then be
printed as defaults.

The following feature might sound a bit complicated, don't worry about
it, you'll normaly not need it.

There are two special variables which make array handling more
flexible. C<display_as> can be used to specify how a database array
shall be represented in the form, C<save_as> works in the other
direction, it defines in which format an array submitted by the form
is written in the database. This is probably a bit hard to understand,
so here is an example: you could save a telefon number in one database
field which is of type integer[] (integer array). The first element is
the code, the second the number. Of course in the database this is a
one dimensional array. But when the telefon field is now represented
by the form the one dimensional array will probably cause the two
fields to be on two diffrent rows, so you want to turn the one
dimensional array into an two dimensional array just by adding one
more dimension. This is simply done by setting C<display_as={{,}};> in
the database field comment (see L<assigning FormEngine variables in
the database>). Same with C<save_as>. So if you specify
e.g. C<{{,}{,}}> for one of these variables it'll cause an array like
C<[1,2,3,4]> to be turned into C<[[1,2][3,4]]>. The elements are
simply read from left to right and putted into the template also from
left to right.


=head3 NOT NULL fields

The form value of fields which have the NOT NULL property will be
automatically passed to the I<not_null> check method. This means that
their I<ERROR> variable will be set to I<not_null>.

If the I<ERROR> variable was already set through C<dbsql_preconf>,
nothing will be changed. If the variable was set through the fields
comment (see L<assigning FormEngine variables in the database>), the
I<not_null> check will be added in front.

If you called C<dbsql_set_write_null_fields> the not_null check is
probably not added since a field which will just be ignored if empty
doesn't have to be checked whether it is empty. Read
L<dbsql_set_write_null_fields ( INTEGER )> for more information.

=head3 assigning FormEngine variables in the database

PostgreSQL and other DBMS offer to set comments on database
objects. This feature can be used to explicitly set form field
variables in the database.

You might e.g. want to store emailadresses in a certain field of a
database table, it makes sense to validate an address before inserting
it. First possibility is to use C<dbsql_preconf> to set the ERROR
variable to 'email' or 'rfc822', but perhaps you've more than one
script which inserts or updates the table and so you're using several
forms. In every script you now have to call the C<dbsql_preconf>
method and set the ERROR variable for the email field. This isn't
nice, because the necessity to check this field is given by the table
structure and so the check should also be set by the database. You
might set a check constraint, but this will cause an ugly database
error which the user might not understand. So beside defining an
constraint (which is recommended), FormEngine::DBSQL should check the
address before inserting it. Setting the database fields comment to
'ERROR=rfc822;' will force FormEngine::DBSQL to do so. You can still
overwrite this setting with C<dbsql_preconf>.

Below you see the whole command:

  COMMENT ON COLUMN "user".email IS 'ERROR=rfc822;'

Whenever you pass this tables name to the C<new> method of
FormEngine::DBSQL, it'll remember to call the rfc822 check method
before inserting or updating a I<email> field value.

You can even assign array structures to a variable:

  COMMENT ON COLUMN "user".phone IS 'ERROR_IN={{{not_null,digitonly},{not_null,digitonly}}};';

The I<phone> field is a string array, with the above command we
forbid NULL values and demand digits for the first two elements. More
about arrays and their representation in the form is described above
(L<array handling>).

It is possible to assign several variables:

  COMMENT ON COLUMN "user".zip IS 'ERROR=digitonly;TITLE=Postcode;';

Don't forget the ';' at the end of every assignment!

Of course you can still use the comment field to place normal comments
there as well:

  COMMENT ON COLUMN "user".birthday IS 'We\'re really a bit curious!;ERROR=date;';

Note the ';' at the end of the trivial comment!

In quoted areas ("..") '{', '}' and ',' are not interpreted. You can
prevent the parsing of '"' and ';' by putting an '\' (backslash) in
front.

=head2 Methods

=head3 new ([ HASHREF, DBHANDLE ])

Works exactly like L<HTML::FormEngine>s C<new> method but accepts a
second parameter, the database handle. This is needed for
communicating with the database. Alternatively it can be set through
L<dbsql_set_dbh ( DBHANDLE )>.

=head3 dbsql_preconf ( HASHREF, PREPEND, APPEND )

In the referenced hash you can predefine some parts of the form
configuration by hand. The hash keys must be named after the tables
fields. Every element must be a hash reference, in the referenced hash
you can set variables.

You can use the special keys I<prepend> and I<append> to add extra
fields before or after the field.

An example:

    my %preconf = (
		   name => {
                          TITLE => 'Fore- and Surname',
                          ERROR => sub {$_ = shift; m/\w\W\w/ ? return 0 : return 'failed';}
		       },
                   email => {
                          TITLE => 'Your Emailadress',
                          ERROR => 'email'
                       }
		   );
    $Form->dbsql_preconf(\%preconf);


The field definitions passed for PREPEND or APPEND are added to the
top resp. the bottom of the generated form. If you want to add more
than one field, you have to reference an array which contains the
definitions, else you can reference the hash directly. See the
L<HTML::FormEngine> for information about field definitions.

When using the special key format I<__add_VARNAME_last>
resp. I<__add_VARNAME_first> the given values are added at the
beginning resp. the end of the (probably) already existing value
list. Of course you have to replace I<VARNAME> with the name of the
variable to which you want to add something. If the sofar specified
value of the variable is a scalar its automatically turned into an
array.

B<Note:> If you pass more than one table name to C<dbsql_conf>, you
must reference the fields with I<tablename.fieldname>!

=cut

######################################################################

sub dbsql_preconf {
  my ($self,$preconf,$prepend,$append) = @_;
  if(ref($preconf) eq 'HASH') {
    $self->{dbsql_preconf} = merge($preconf, $self->{dbsql_preconf});
  }
  #rettarref returns an array reference
  $self->{dbsql_prepend} = retarref($prepend);
  $self->{dbsql_append} = retarref($append);
}

######################################################################

=head3 dbsql_conf ( ... )

The three dots stand for:
C<TABLENAME|ARRAYREF, [ COUNT|WHERECONDITION|HASHREF, FIELDNAMES|HASHREF ]>

This method creates a FormEngine-form-definition and calls FormEngines
C<conf> method.

Normally you only want to manage records out of one table, then it is
sufficient to give this tables name as first argument. But you can
also pass several table names by using an array reference.

If you provide COUNT, the form fields will be displayed COUNT times,
which means that you can insert COUNT records.

If you want to update records, you should provide WHERECONDITION
instead. This must be a valid where-condition B<without> the C<WHERE>
directive in front, or a hash reference. A hash reference you must
provide if you passed several tablenames and want to define diffrent
where conditions for theses tables. The keys must be the table names
and the elements the complying conditions.

DBSQL then shows input fields for every found record and uses the
current values as defaults. The primary keys are stored in hidden
fields, so that they can't be changed. Later they're used for updating
the records.

If you'd like to set only some of the tables fields, put their names
in an array and pass a reference as third and last argument
(FIELDNAMES). If the first array element is '!', all fields which
B<aren't> found in the array will be displayed. You must use a hash
reference here if you passed more than one table name.

=cut

######################################################################

sub dbsql_conf {
  my ($self,$table,$where,$fields) = @_;

  $self->{dbsql_tables} = retarref($table || $self->{dbsql_tables});

  if(! defined($self->{dbsql_tables}) || ! @{$self->{dbsql_tables}}) {
    croak 'table not defined!';
  }

  $self->{dbsql_where} = $where || $self->{dbsql_where};

  $self->{dbsql_fields} = $fields || $self->{dbsql_fields};

  #if the user references fields out of diffrent tables he must say which fields belong to which table
  if(@{$self->{dbsql_tables}} > 1 && ref($self->{dbsql_fields}) ne 'HASH') {
    croak 'fields must be assigned to tables!';
  }
  #in the case that we've only one table the user can be lazy and we transform into hash notation
  elsif(@{$self->{dbsql_tables}} == 1 && ref($self->{dbsql_fields}) ne 'HASH') {
    $self->{dbsql_fields} = {$self->{dbsql_tables}->[0] => retarref($self->{dbsql_fields})};
  }
  #the user could have setted dbsql_pkey before through dbsql_set_pkey
  #if its not a hash he defined them only for one table
  if(ref($self->{dbsql_pkey}) ne 'HASH') {
    $_ = retarref($self->{dbsql_pkey});
    $self->{dbsql_pkey} = {$self->{dbsql_tables}->[0] => {}};
    foreach $_ (@{$_}) {
      $self->{dbsql_pkey}->{$self->{dbsql_tables}->[0]}->{$_} = 1;
    }
  }

  my ($count, $where_cond);
  #if we have a number we don't have a sql where condition, that means we're just asked to repeat the fields $count time
  if(! ref($self->{dbsql_where}) and $self->{dbsql_where} =~ m/^[0-9]+$/) {
    $count = $self->{dbsql_where};
  } else {
    #since we have a where condition we'll display the fields content and not the default
    $self->dbsql_set_show_default(0) if($self->{dbsql_show_default} == 1);
    #if a scalar was given we've to turn it into a hash ({table => wherecondition})
    if(ref($self->{dbsql_where}) ne 'HASH') {
      $where_cond = $self->{dbsql_where};
      $self->{dbsql_where} = {};
    } else {
      $where_cond = '';
    }
  }

  my %donotuse;
  foreach my $tbl (@{$self->{dbsql_tables}}) {
    #if no fields are given we just take all
    if(ref($self->{dbsql_fields}->{$tbl}) ne 'ARRAY' or ! @{$self->{dbsql_fields}->{$tbl}}) {
      $self->{dbsql_fields}->{$tbl} = [undef];
    }
    #$where_cond is '' if nothing was given or if just a scalar was given it is set to that one
    $self->{dbsql_where}->{$tbl} = $where_cond if(ref($self->{dbsql_where}) eq 'HASH' && ! defined($self->{dbsql_where}->{$tbl}));
    #if the first field of the dbsql_fields array is '!' it means that the following fields should not be selected
    $donotuse{$tbl} = {};
    if(defined($self->{dbsql_fields}->{$tbl}->[0]) and $self->{dbsql_fields}->{$tbl}->[0] eq '!') {
      delete $self->{dbsql_fields}->{$tbl}->[0];
      foreach $_ (@{$self->{dbsql_fields}->{$tbl}}) {
	$donotuse{$tbl}->{$_} = 1;
      }
      #select all, $donotuse will be used later
      $self->{dbsql_fields}->{$tbl} = [undef];
    }

    #no pkey was defined, so we've to get it/them
    if(! defined($self->{dbsql_pkey}->{$tbl})) {
      $self->{dbsql_pkey}->{$tbl} = {};
      foreach $_ ($self->{dbsql}->primary_key(undef, undef, $tbl)) {
    	my $field = (@{$self->{dbsql_tables}} > 1 ? "$tbl.$_" : $_);
	#like this we can prove better whether a certain field is part of the pkey or not
    	$self->{dbsql_pkey}->{$tbl}->{$field} = 1;
      }
    }
  }

  my @fconf;
  #configurations saved in dbsql_prepend must be added to the top
  if(defined($self->{dbsql_prepend})) {
    push @fconf, @{retarref($self->{dbsql_prepend})};
  }

  foreach my $tbl (@{$self->{dbsql_tables}}) {
    #get the tables structure
    my @fields = @{$self->{dbsql_fields}->{$tbl}};
    $self->{dbsql_fields}->{$tbl} = [];
    foreach my $field (@fields) {
      my $sth = $self->{dbsql}->column_info(undef, undef, $tbl, $field);
      $sth->execute;
      while(my $fstruct = $sth->fetchrow_hashref()) {
	#jump over fields that shall not be displayed
	next if($donotuse{$tbl}->{$fstruct->{COLUMN_NAME}});
	#$_ now contains the form configuration for that field
	local $_ = $self->_dbsql_makeconf($fstruct, $tbl);
	#now we push only the fields that we really want
	push @{$self->{dbsql_fields}->{$tbl}}, $_->{fname};
	if(defined($_->{prepend})) {
	  push @fconf, @{retarref($_->{prepend})};
	  delete $_->{prepend};
	}
	push @fconf, $_;
	# in case form field name and db table field name differ
	$self->{dbsql_save_as}->{$_->{NAME}} = $_->{save_as} if(defined($_->{save_as}));
	if(defined($_->{append})) {
	  push @fconf, @{retarref($_->{append})};
	  delete $_->{append};
	}
      }
      $sth->finish;
    }
  }

  if(defined($self->{dbsql_append})) {
    push @fconf, @{retarref($self->{dbsql_append})};
  }

  #delete primary key fields which are not going to be selected
  foreach my $tbl (@{$self->{dbsql_tables}}) {
    foreach my $field (keys(%{$self->{dbsql_pkey}->{$tbl}})) {
      delete $self->{dbsql_pkey}->{$tbl}->{$field} unless(grep {$field eq $_} @{$self->{dbsql_fields}->{$tbl}});
    }
  }
  my %value;
  #seems that we shall get the contents of the table fields
  if(! defined($count)) {
    $count = -254;
    foreach my $tbl (@{$self->{dbsql_tables}}) {
      my $sql = 'SELECT ';
      foreach $_ (@{$self->{dbsql_fields}->{$tbl}}) {
	if(m/^(.+)?\.(.+)/) {
	  $sql .= $self->{dbsql}->quote_identifier($1) . '.' . $self->{dbsql}->quote_identifier($2);
	}
	else {
	  $sql .= $self->{dbsql}->quote_identifier($_);
	}
	$sql .= ',';
      }
      $sql =~ s/,$//;
      $sql .= ' FROM ' . $self->{dbsql}->quote_identifier($tbl);
      if($self->{dbsql_where}->{$tbl} ne '') {
	$sql .= ' WHERE '.$self->{dbsql_where}->{$tbl};
      }
      my $sth = $self->{dbsql}->prepare($sql);
      if(! $sth->execute) {
	carp($self->{dbsql}->errstr);
	$self->_dbsql_sql_error($sth->{Statement});
	return 0;
      }
      else {
	#count was not set so we now set it on the number of data records
	if($count == -254) {
	  $count = $sth->rows;
	}
	#the whole thing cannot work if the results for the tables used for the forms don't have the same count of records
	elsif($count ne $sth->rows) {
	  croak('There must be the same count of records for each table!');
	}
	#only if dbsql_show_value is set we shall display the current value of the db fields
	while($self->{dbsql_show_value} && (my $record = $sth->fetchrow_hashref)) {
	  local $_;
	  foreach $_ (keys(%{$record})) {
	    #we've to prepend the table name in case we've several tables
	    my $field = (@{$self->{dbsql_tables}} > 1 ? "$tbl.$_" : $_);
	    if(ref($value{$field}) ne 'ARRAY') {
	      $value{$field} = [];
	    }
	    #turn db arrays into perl arrays
	    if(defined($record->{$_}) and $record->{$_} =~ m/^\{.*\}$/) {
	      push @{$value{$field}}, $self->_dbsql_parse($record->{$_});
	    }
	    else {
	      push @{$value{$field}}, $record->{$_};
	    }
	  }
	}
      }
      $sth->finish;
    }
  }
  my @conf;
  #dbsql_row says whether to print the fields belonging to one record in one line (1) or one per line (0)
  #if dbsql_row was not explicitly set but the count of records is > 1 the default behaviour shall be to use one line per record
  if($self->{dbsql_row} > 0 or $count > 1 and $self->{dbsql_row} == -254) {
    $self->{dbsql_row} = 1;
    my @title;
    #we've to remove the title out of the configuration and instead use an extra title template which just prints them once at top
    foreach $_ (@fconf) {
      push @title, $_->{TITLE} unless($self->{hidden}->{$_->{templ}});
      $_->{TITLE} = '';
      #we want the error message to be printed underneath and not at the right
      ##$_->{templ} = $self->{skin_obj}->dbsql_errmsg_bottom($_->{templ});
    }
    push @conf, {templ => 'title', TITLE => \@title};
  }

  #get all primary key field names, we'll need that to get all pkey values and then create the md5 hash which ensures that none of the pkeys was altered
  my @pkey = ();
  foreach $_ (keys(%{$self->{dbsql_pkey}})) {
    push @pkey, keys(%{$self->{dbsql_pkey}->{$_}});
  }
  my @pkeyval;
  #the configuration templates for each field is in @fconf, now we create the real form configuration
  for(my $i=0; $i<$count; $i++) {
    @pkeyval = ();
    my $record_conf = clone(\@fconf);
    if(keys(%value) || $self->{skin_obj}->get_dbsql_secret()) {
      foreach my $field (@$record_conf) {
	#we'v to set the default values to the corresponding database record
	if(keys(%value)) {
	  if(defined($field->{fname}) && defined($value{$field->{fname}})) {
	    #we shouldn't overwrite defaults setted by the user or by the database
	    unless(defined($field->{VALUE})) {
	      local $_;
	      $_ = shift @{$value{$field->{fname}}};
	      #display_as describes in which format the value should be displayed
	      if(ref($field->{display_as}) eq 'ARRAY') {
		$_ = [$_] unless(ref($_) eq 'ARRAY');
		($field->{VALUE}) = _array2array($field->{display_as},[$self->_flatten_array(@{$_})]);
	      }
	      else {
		$field->{VALUE} = $_;
	      }
	    }
	  }
	}
	#could be that the pkey value was setted by hand that's why we've to do this also when no value was fetched out of the database
	push @pkeyval, $field->{VALUE} if ($field->{fname} and $self->{skin_obj}->get_dbsql_secret() && grep {$_ eq $field->{fname}} @pkey);
      }
    }

    #create and add the md5hash field which ensures that the pkeys can't be altered
    $_ = md5_hex(join($self->{skin_obj}->get_dbsql_secret(), @pkeyval) . $self->{skin_obj}->get_dbsql_secret());
    push @$record_conf, {templ => 'dbsql_hidden', NAME => 'md5hash', VALUE => $_} if(@pkeyval);
    #we probably shall put all fields belonging to one record in one row
    if($self->{dbsql_row} > 0) {
      #ROWNUM should be replaced by something else in feature releases
      push @conf, {templ => $self->{dbsql_row_tmpl}, ROWNUM => $i+1, sub => $record_conf};
    }
    #one field per row
    else {
      #the empty template should insert space between each line (do we really need that???)
      push @conf, @$record_conf, {templ => $self->{dbsql_empty_tmpl}};
    }
  }
  $self->set_seperate(1);
  #we place all in body because we probably use more than 3 columns (which is expected by the 'main' template)
  $self->conf([{templ => 'body', sub => \@conf}]);
  #DEBUGGING
  if($self->{debug}) {
    foreach $_ (@fconf) {
      print $_->{NAME}, "\n";
    }
  }
}

######################################################################

=head3 dbsql_update

This method can only be used if a where-condition was passed to
L<dbsql_conf ( ... )>.

It updates the found table records to the submitted
values. If an error occurs the update statement and the DBMSs error
message and number is printed. If you want only some of this
information to be displayed, see L<dbsql_set_sqlerr ( INTEGER )>.

Normally you must have defined a secret string if you want to use this
method, else an error message will be printed. See L<dbsql_set_secret ( SECRET )>
for more information.

Before calling this method, you should prove that the form content is 
valid (see L<HTML::FormEngine>, C<ok> method).

=cut

######################################################################

sub dbsql_update {
  my ($self) = @_;
  my ($md5hash, @pkeyval, @pkeyval2, $ok, $val, $tbl);
  local $_ = 0;
  #ensure that there's a primary key defined for every table
  foreach my $tbl (@{$self->{dbsql_tables}}) {
    $_ = $tbl and last unless(keys(%{$self->{dbsql_pkey}->{$tbl}}));
  }
  if($_) {
    #append at the form bottom
    $self->_add_to_output($self->{dbsql_errmsg_tmpl}, {ERRMSG => gettext('Primary key is missing for table') . ' \'' . $_ . '\'!'});
    return 0;
  }

  #if dbsql_hide_pkey was set we must in anycase asure that pkey was not altered
  if($self->{dbsql_hide_pkey}) {
    foreach my $tbl (@{$self->{dbsql_tables}}) {
      local $_;
      foreach $_ (keys(%{$self->{dbsql_pkey}->{$tbl}})) {
	push @pkeyval, $self->get_input($_);
      }
    }
    my $md5hash = $self->get_input('md5hash');
    $self->_add_to_output($self->{dbsql_errmsg_tmpl}, {ERRMSG => gettext('Can\'t update record(s) due to missing primary key checksum').'!'}) and return 0 unless($md5hash);
    my $ok;
    if(ref($md5hash) eq 'ARRAY') {
      $ok = 1;
      #get pkey value for each record and compare
      foreach $_ (@{$md5hash}) {
	@pkeyval2 = ();
	foreach $val (@pkeyval) {push @pkeyval2, shift @{$val} };
	$ok-- && last unless $self->_dbsql_chk_check_sum($_, \@pkeyval2);
      }
    }
    else {
      $ok = $self->_dbsql_chk_check_sum($md5hash, \@pkeyval);
    }
    $self->_add_to_output($self->{dbsql_errmsg_tmpl}, {ERRMSG => gettext('Can\'t update record(s) due to primary key cheksum mismatch').'!'}) and return 0 unless($ok);
  }

  return $self->_dbsql_write(1);
}

######################################################################

=head3 dbsql_insert

This method inserts the transmitted data into the table.  If an error
occurs, the insert statement and the DBMSs error message and number are
printed. If you don't want all or some of this information be
displayed, see L<dbsql_set_sqlerr ( INTEGER )>.
Before calling this method, you should prove that the form content is 
valid (see L<HTML::FormEngine>, C<ok> method).

=cut

######################################################################

sub dbsql_insert {
  my ($self) = @_;
  return $self->_dbsql_write(0);
}

######################################################################

=head3 dbsql_set_dbh ( DBHANDLE )

Use this function to set the internally used database handle. If you
don't call this funtion, you must set it when creating the object with
the L<new ([ HASHREF, DBHANDLE ])> method.

=cut

######################################################################

sub dbsql_set_dbh {
  my ($self, $dbh) = @_;
  $self->{dbsql} = $dbh;
  if(ref($self->{dbsql}) ne 'DBI::db') {
    croak 'No valid database connection!';
  }
}

######################################################################

=head3 dbsql_set_hide_pkey ( BOOLEAN )

By default the primary key fields are represented as I<hidden> form
fields. This makes sense because when updating records they mustn't be
changed. Sometimes, especially when inserting new records, one might
want to set them by hand. Then he should pass false (0) to this method.

Passing false to this method will also disable the primary key md5
checksum check when calling C<dbsql_update>. This means that it'll be
allowed to change the primary keys even when updating records. By
default this is not allowed for security reasons. B<So be carefull with
this method!>. DATA CAN EASILY GET OVERWRITTEN!!!

You can as well set the pkey template by hand using
L<dbsql_preconf ( HASHREF, PREPEND, APPEND )>.

=cut

######################################################################

sub dbsql_set_hide_pkey {
  my $self = shift;
  $self->{dbsql_hide_pkey} = shift;
}

######################################################################

=head3 dbsql_set_show_value ( BOOLEAN )

When you pass a valid where clause to the new method, the contents of
the found records will be read in and displayed as defaults. In
certain situations one might like to have the fields empty
though. Passing false (0) to this method will do it.

=cut

######################################################################

sub dbsql_set_show_value {
  my $self = shift;
  $self->{dbsql_show_value} = shift;
}

######################################################################

=head3 dbsql_set_pkey ( SCALAR|ARRAYREF|HASHREF )

Normally the primary key of a database table is
autodetected. Sometimes someone might like to define other fields as
primary key though (the primary key is important when updating
records). You can pass a fieldname or a reference to an array with
fieldnames to this method. This method should be called before
L<dbsql_conf ( ... )>
(for being sure, call this method as early as possible).

B<Note>: If you pass several table names to dbsql_conf, you must pass
as hash reference here, else the passed pkeys will only be used for
the first table.

=cut

######################################################################

sub dbsql_set_pkey {
  my ($self,$pkey)= @_;
  if($pkey) {
    if(ref($pkey) ne 'HASH') {
      croak "You've to reference a hash since there's more than one table!" if(@{$self->{dbsql_tables}} > 1);
      $self->{dbsql_pkey} = $pkey;
      return 1;
    }
    foreach my $tbl (keys(%{$pkey})) {
      $self->{dbsql_pkey}->{$tbl} = {} if(ref($self->{dbsql_pkey}->{$tbl}) ne 'HASH');
      $pkey->{$tbl} = [$pkey->{$tbl}] if(ref($pkey->{$tbl}) ne 'ARRAY');
      local $_;
      foreach $_ (@{$pkey->{$tbl}}) {
	#in case that we've more than one table we reference fields by table.fieldname
	#is it ok to add the $tbl prefix here in any case or should i check that @{$self->{dbsql_tables}} > 1 ?
	$self->{dbsql_pkey}->{$tbl}->{"$tbl.$_"} = 1;
      }
    }
    return 1;
  }
  return 0;
}

######################################################################

=head3 dbsql_set_show_default ( BOOLEAN )

If you pass true (1) to this method the field defaults defined in the
database are used as defaults in the form. This is the default
behavior in case you don't specify a where condition but a number (or
nothing at all which defaults to 1) (see L<dbsql_conf ( ... )>). In case
that you do specify a where condition its just logical to not use the
database defaults since the real values of the defined database
records are used as default values for the form. So this standard
behaviour should be just fine and you normally don't need this
method. Passing false (0) will force this module to not use the field
defaults defined by the database table structure.

=cut

######################################################################

sub dbsql_set_show_default {
  my ($self, $set) = @_;
  #ensure to not set it to 1 since that is the default and it indicates that this function was NOT called
  $set++ if($set == 1);
  $self->{dbsql_show_default} = $set;
}

######################################################################

=head3 dbsql_set_write_null_fields ( INTEGER )

With this method you can define whether the value of form fields for
which the user didn't specify any value (he submitted them empty)
should be interpreted as NULL and thus null will be written in the
database or whether they should be ignored so that the default is used
by the database (in case of an insert) resp. the value is not changed
(in case of an update).

The default is to interpret empty fields as NULL fields.

B<0> forces the module to not pass empty fields to the database. This
will cause problems when you perform an insert and a certain field is
defined as not_null field and also doesn't have a default value. So
its a bad idea to pass 0 in case you want to make an insert. Also when
doing an update it doesn't make much sense normaly.

B<1> forces the module to only ignore the null value if it was
specified for a I<not_null> field (the table structure forbids the
null value for the field). This will cause the same problems as
described for I<0> (see above). But this can be a good idea if your
planning to make an update.

B<2> forces the module to only ignore an empty field in case it is
defined as I<not_null> by the database and a default value is
defined. This makes e.g. sense when you want to make an insert and the
database shall just set the default values for fields which were not
fill out by the user. Perhaps you also want to use
I<dbsql_set_show_default ( BOOLEAN )> to prevent the default values
from being displayed.

B<3> this is the default behaviour. Empty field values are passed as
NULL to the database.

=cut

######################################################################

sub dbsql_set_write_null_fields {
  my ($self, $set) = @_;
  $self->{dbsql_write_null_fields} = $set;
}

######################################################################

=head3 dbsql_set_errmsg_templ ( TEMPLATENAME )

If you want to modifiy the output of the system error messages, create
a new template (e.g. copy the default and fit it to your needs) and
pass the new templates name to this method. By default the template
called I<errmsg> of the configured skin ist used (the default skin is
L<HTML::FormEngine::DBSQL::SkinClassic>).

=cut

######################################################################

sub dbsql_set_errmsg_templ {
  my($self, $set) = @_;
  $self->{dbsql_errmsg_tmpl} = $set if($set);
}

######################################################################

=head3 dbsql_set_sqlerr ( INTEGER )

Perhaps you already read that whenever a database error occurs, the
error message, error number and query command is printed out by
default. Sometimes you might prove displaying the sql query a security
lack. With the help of this method, you can define which information
will be printed.

Listing of the bits and their influence:

1 error number

2 error message

4 sql command

So if you pass 3 to this method the error number and message will be
printed, but not the sql command.

=cut

######################################################################

sub dbsql_set_sqlerr {
  my($self, $set) = @_;
  $self->{dbsql_sqlerr_show} = $set;
}

######################################################################

=head3 dbsql_set_sqlerr_templ ( TEMPLATENAME )

If you want to modifiy the output of the sql error messages, create a
new template (e.g. copy the default and fit it to your needs) and pass
the new templates name to this method. By default the template called
I<sqlerror> of the configured skin is used (the default skin is
L<HTML::FormEngine::DBSQL::SkinClassic>).

=cut

######################################################################

sub dbsql_set_sqlerr_templ {
  my($self, $set) = @_;
  $self->{dbsql_sqlerr_tmpl} = $set if($set);
}

######################################################################

=head3 dbsql_set_row ( BOOLEAN )

If you provided a I<where condition> and more than one record was
found, or you provided a number instead and it was higher than 1, then
by default it'll be used only one line per record, which means that
fields belonging to the same record will be printed on the same line.

By passing 0 (false) to this method you can force the object to use
one line per field, 1 (true) is the default.

=cut

######################################################################

sub dbsql_set_row {
  my($self,$set) = @_;
  $set -- if($set == -254);
  $self->{dbsql_row} = $set;
}

######################################################################

=head3 dbsql_set_row_tmpl ( TEMPLATENAME )

By default the I<row> template is used. If you want to use another
template for placing the fields which belong to one record into one
line, pass it to this method.

=cut

######################################################################

sub dbsql_set_row_tmpl {
  my ($self,$set) = @_;
  $self->{dbsql_row_tmpl} = $set if($set);
}

######################################################################

=head3 dbsql_set_empty_tmpl ( TEMPLATENAME )

By default the I<empty> template is used for inserting space between
the records, If you want to use another template pass its name to this
method.  The space is only inserted if every field takes one line.

=cut

######################################################################

sub dbsql_set_empty_tmpl {
  my ($self,$set) = @_;
  $self->{dbsql_empty_tmpl} = $set if($set);
}

######################################################################

=head3 dbsql_get_sqlerr

This method returns an array with the error number and error message
from the last database error. The sql command which caused the error
will be the third and last element.

=cut


######################################################################

sub dbsql_get_sqlerr {
  my $self = shift;
  return @{$self->{dbsql_sqlerr}};
}

######################################################################

=head3 dbsql_add_extra_sql(SQLCOMMAND, ARRAY)

This method can be used to define some more sql commands which then
will be executed for each record when C<insert> or <update> is called.

The sql command might contain '?' (question marks). These will be
replaced with the values of the fields defined by the second
argument. The first '?' is replaced with the value of the first
element and so on.

A backslash before a question mark will prevent it from being parsed.

=cut

######################################################################

sub dbsql_add_extra_sql {
  my($self,$sql,@vars) = @_;
  push @{$self->{dbsql_extra_sql}}, [$sql, @vars] if($sql);
}

######################################################################
# INTERNAL METHODS                                                   #
######################################################################

#this method is called by HTML::FormEngine s constructor
sub _initialize_child {
  my $self = shift;
  # the remaining arguments are forwarded by HTML::FormEngine s new method
  $self->dbsql_set_dbh(shift);
  $self->{dbsql_preconf} = {};
  $self->{dbsql_where} = 1;
  $self->{dbsql_pkey} = {};
  $self->{dbsql_tables} = [];
  $self->{dbsql_fields} = {};
  $self->{dbsql_hide_pkey} = 1;
  $self->{dbsql_show_value} = 1;
  #-254 shall indicate that the value was not touched by the user
  $self->{dbsql_show_default} = 1;
  $self->{dbsql_write_null_fields} = 3;
  $self->{dbsql_sqlerr} = [];
  $self->{dbsql_sqlerr_show} = 7;
  $self->{dbsql_sqlerr_tmpl} = 'sqlerr';
  $self->{dbsql_errmsg_tmpl} = 'errmsg';
  $self->{dbsql_row_tmpl} = 'row';
  $self->{dbsql_empty_tmpl} = 'empty';
  #-254 shall indicate that the value was not touched by the user
  $self->{dbsql_row} = -254;
  $self->{dbsql_extra_sql} = [];
  $self->{dbsql_save_as} = {};
  $self->{dbsql_not_null_fields} = {};
  $self->{dbsql_has_default_fields} = {};

  #HTML::FormEngine::DBSQL::SkinClassic is the default skin for FormEngine::DBSQL
  $self->set_skin_obj(new HTML::FormEngine::DBSQL::SkinClassic);

  #just in case someone wants to inherit from this method
  $self->_dbsql_initialize_child;
}

sub _dbsql_initialize_child {
}

#this method writes the submitted values into the database
sub _dbsql_write {
  my ($self,$update) = @_;
    
  my (%fields,$count);
  foreach my $tbl (@{$self->{dbsql_tables}}) {
    $fields{$tbl} = {};
    foreach $_ (@{$self->{dbsql_fields}->{$tbl}}) {
      my $val = $self->_get_input($_);
      $val = [$val] if(ref($val) ne 'ARRAY');
      #$count shall contain the count of submitted records
      $count = @{$val} if(!defined($count) || @{$val} > $count);
      $fields{$tbl}->{$_} = $val;
    }
  }

  $self->{dbsql}->begin_work;
  my $rec;
  #for each record..
  for($rec = 0; $rec<$count; $rec ++) {
    my @sql = ();
    my %tblvalues = ();
    foreach my $tbl (@{$self->{dbsql_tables}}) {
      my %values = ();
      my %pkey = ();
      local $_;
      foreach $_ (keys(%{$fields{$tbl}})) {
	#we can delete fields which don't have any value left
	if(! @{$fields{$tbl}->{$_}}) {
	  delete $fields{$tbl}->{$_};
	}
	my $value = $fields{$tbl}->{$_}->[$rec];
	$value = undef if($value eq '');

	#save_as describes in which format the value should be saved to the database
	if(defined($self->{dbsql_save_as}->{$_}) and ref($self->{dbsql_save_as}->{$_}) eq 'ARRAY') {
	  $value = [$value] unless(ref($value) eq 'ARRAY');
	  ($value) = _array2array($self->{dbsql_save_as}->{$_},$value);
	}

	#turn perl arrays into database arrays
	$value = $self->_dbsql_arr2psql($value) if(ref($value) eq 'ARRAY');
       
	#we only write null fields according to the settings made through dbsql_set_write_null_fields resp. the default
	#but primary keys must never be set to NULL!
	if(
	   (defined($value) and $value ne '') or !$self->{dbsql_pkey}->{$tbl}->{$_} &&
	   ($self->{dbsql_write_null_fields} > 2 || (
						     $self->{dbsql_write_null_fields} > 0 && (
											      ! defined($self->{dbsql_not_null_fields}->{$_} || (
																		 $self->{dbsql_write_null_fields} > 1 && ! defined($self->{dbsql_has_default_fields}->{$_})
																		)
												       )
											     )
						    )
	   )
	  ) {
	  #filter out the real field name (remove the table name which was added to distinguish the fields)
	  (my $key = $_) =~ s/^(.+)\.(.+)$/$2/;
	  #quote the key (fieldname) probably
	  $key = $self->{dbsql}->quote_identifier($key);
	  if($self->{dbsql_pkey}->{$tbl}->{$_}) {
	    $pkey{$key} = $self->{dbsql}->quote($value);
	  }
	  $values{$key} = $self->{dbsql}->quote($value);
	  $tblvalues{$_} = $values{$key};
	}
      }

      #create an update statement
      if($update) {
	push @sql, $self->_dbsql_mk_update([keys(%values)], [values(%values)], \%pkey, $tbl);
      }
      #create an insert statement (here we don't need any primary keys)
      else {
	push @sql, $self->_dbsql_mk_insert([keys(%values)], [values(%values)], $tbl);
      }
    }

    #add the specified extra sql statements which should be executed for every record (in most cases the user didn't specify any)
    foreach $_ (@{$self->{dbsql_extra_sql}}) {
      my $sql = $_->[0];
      #replace the ? with the corresponding field value
      for(my $x=1; $x<@{$_}; $x++) {
	$sql =~ s/(?!\\)(.)\?/$1.$tblvalues{$_->[$x]}/e;
      }
      $sql =~ s/\\\?/?/g;
      push @sql, $sql;
    }
    foreach my $sql (@sql) {
      if($self->{debug}) {
	print $sql, "\n";
      }
      my $sth = $self->{dbsql}->prepare($sql);
      #execute statements
      if(! $sth->execute) {
	$self->_dbsql_sql_error($sql);
	return 0;
      }
    }
  }
  $self->{dbsql}->commit;
  return $rec;
}


#this method turns a perl array into a database array ('{field1, field2, {subfield1, subfield2}, ...}')
#it works recursive
sub _dbsql_arr2psql {
  my ($self,$elem) = @_;
  my $res = '';
  if(ref($elem) eq 'ARRAY') {
    $res = '{';
    foreach $_ (@{$elem}) {
      $res .= $self->_dbsql_arr2psql($_) . ',';
    }
    $res =~ s/,$/\}/;
  }
  else {
    $res = $elem;
  }
  return $res;
}

#this method creates an insert statement
sub _dbsql_mk_insert {
  my ($self,$fields,$values,$table) = @_;
  if(ref($fields) eq 'ARRAY' && ref($values) eq 'ARRAY' && $table ne '') {
    return 'INSERT INTO ' . $self->{dbsql}->quote_identifier($table) . ' ('.join(', ', @{$fields}).') VALUES ('.join(', ', @{$values}).')';
  }
  else {
    return '';
  }
}

#this method creates an update statement
sub _dbsql_mk_update {
  my ($self,$fields,$values,$pkey,$table) = @_;
  my $sql = '';

  if(ref($fields) eq 'ARRAY' && ref($values) eq 'ARRAY' && ref($pkey) eq 'HASH' && $table ne '') {
    $sql =  'UPDATE ' . $self->{dbsql}->quote_identifier($table) . ' SET ';
    my $i = 0;
    foreach $_ (@{$fields}) {
      $sql .= "$_=" . $values->[$i] . ', ';
      $i ++;
    }
    $sql =~ s/, $//;
    $sql .= ' WHERE ';
    foreach $_ (keys(%{$pkey})) {
      $sql .= "$_=" . $pkey->{$_} . ' AND ';
    }
    $sql =~ s/ AND $//;
  }
  
  return $sql;
}

#this method creates a field configuration with the help of the database table structure information
sub _dbsql_makeconf {
  my ($self,$info,$tbl) = @_;
  my %res = ();
  if(ref($info) eq 'HASH') {
    #($res{TITLE} = $info->{name}) =~ s/^([a-z]{1})/uc($1)/e; does raise an endless loop
    #by default the title shall be the name but with the first letter being capital
    $_ = $info->{COLUMN_NAME} and s/^([a-z]{1})/uc($1)/e and $res{TITLE} =  $_;
    #attach $tbl in front so that fields with same names (out of diffrent tables) don't get confused
    $info->{COLUMN_NAME} = $tbl . '.' . $info->{COLUMN_NAME} if(@{$self->{dbsql_tables}} > 1);
    #fname is just a copy of name, i forgott what for :(
    $res{fname} = $info->{COLUMN_NAME};
    $res{NAME} = $info->{COLUMN_NAME};
    #parse the default
    #we should only use the default value if dbsql_show_default is true, primary keys should not be touched
    if($info->{COLUMN_DEF} && $self->{dbsql_show_default} > 0 && ! $self->{dbsql_pkey}->{$tbl}->{$res{NAME}}) {
      #removing the explizit datatype cast (this is new in postgres 7.4)
      $info->{COLUMN_DEF} =~ s/::[a-z ]+(\[\])?//g;
      $info->{COLUMN_DEF} =~ s/^'(.*)'$/$1/;
      #default can also be an array
      if($info->{COLUMN_DEF} =~ m/^\{.*,.*\}$/) {
	($res{VALUE}) = $self->_dbsql_parse($info->{COLUMN_DEF});
      }
      else {
	$res{VALUE} = $info->{COLUMN_DEF};
      }
    }
    #call the datatype handlers
    $info->{TYPE_NAME} =~ s/\[\]$//;
    my $handler;
    if(ref($self->{skin_obj}->get_dbsql_dthandler($info->{TYPE_NAME})) eq 'CODE') {
      $handler = $self->{skin_obj}->get_dbsql_dthandler($info->{TYPE_NAME});
    }
    else {
      $handler = $self->{skin_obj}->get_dbsql_dthandler('default');
    }
    &$handler($self, \%res, $info);
    #hide primary keys
    if($self->{dbsql_pkey}->{$tbl}->{$info->{COLUMN_NAME}} && $self->{dbsql_hide_pkey}) {
      $res{templ} = 'dbsql_hidden';
      $res{TITLE} = '';
    }

    #the user can define configuration variables in the fields description
    #we parse the description here and ensure that the form configuration gets completed
    if($info->{REMARKS}) {
      while($info->{REMARKS} =~ m/\G.*?([A-Za-z_]+)\=(?:;|(.*?[^\\]{1});)/g) {
	my $var = $1;
	local $_;
	if(defined($2)) {
	  ($_ = $2) =~ s/\\;/;/g;
	}
	else {
	  $_ = '';
	}
	($res{$var}) = $self->_dbsql_parse($_);
	$res{$var} = '' unless(defined($res{$var}));
      }
    }

    #display_as describes in which format the value should be displayed
    if(defined($res{display_as}) and defined($res{VALUE}) and ref($res{display_as}) eq 'ARRAY') {
      $res{VALUE} = [$res{VALUE}] unless(ref($res{VALUE}) eq 'ARRAY');
      my @test = $self->_flatten_array(@{$res{VALUE}});
      ($res{VALUE}) = _array2array($res{display_as},[$self->_flatten_array(@{$res{VALUE}})]);
    }

    # only if null fields are going to be written we set the not_null check, see dbsql_set_write_null_fields for better understanding
    if($self->{dbsql_write_null_fields} > 2 || ($self->{dbsql_write_null_fields} > 1 && !$info->{COLUMN_DEF}) and !$info->{NULLABLE}) {
      $res{ERROR} = ($res{ERROR} ? [$res{ERROR}] : []) unless(ref($res{ERROR}) eq 'ARRAY');
      push @{$res{ERROR}}, 'not_null';
    }

    #we need the following later to distinguish whether a field which was submitted with an empty value shall be written into database or not
    $self->{dbsql_not_null_fields}->{$res{fname}} = 1 unless($info->{NULLABLE});
    $self->{dbsql_has_default_fields}->{$res{fname}} = 1 unless(defined($info->{COLUMN_DEF}));
    #add the preconf settings made by the user
    if(ref($self->{dbsql_preconf}->{$info->{COLUMN_NAME}}) eq 'HASH') {
      foreach $_ (keys(%{$self->{dbsql_preconf}->{$info->{COLUMN_NAME}}})) {
	#the given values shall not overwrite but complete the default settings
	if($_ =~ m/^__add_(.+)_(first|last)$/) {
	  my $varname = $1;
	  my $pos = $2;
	  $res{$varname} = [] if(!defined($res{$varname}));
	  $res{$varname} = [$res{$varname}] if(ref($res{$varname}) ne 'ARRAY');
	  my $addvalue = $self->{dbsql_preconf}->{$info->{COLUMN_NAME}}->{$_};
	  $addvalue = [$addvalue] unless(ref($addvalue) eq 'ARRAY');
	  if($pos eq 'last') {
	    push @{$res{$varname}}, @$addvalue;
	  }
	  elsif($pos eq 'first') {
	    #why not use unshift?
	    @{$res{$varname}} = (@$addvalue, @{$res{$varname}});
	  }
	}
	else {
	  $res{$_} = $self->{dbsql_preconf}->{$info->{COLUMN_NAME}}->{$_};
	}
      }
    }

  }
  return \%res;
}

# transform array string-notation (database) into perl array
# this method works recursive
sub _dbsql_parse {
  my ($self,$struc) = @_;
  return [$self->_dbsql_parse($1,1)] if($struc =~ m/^\{([^{}]*)\}$/);
  my $struc2 = $struc;
  #just delete quoted (" ... ") sections since they shouldn't be parsed!
  while($struc2 =~ s/(\G|[^\\]{1})"(?!.*\\).*?"/$1/){};
  if($struc2 =~ m/^[^{\,}]*$/) {
    #remove the quotations, they're only for preventing certain parts of being parsed but not meant to be really part of the array in the end
    while($struc =~ s/(^|[^\\]{1})"/$1/g){};
    #to be able to print " in a quotated section the \ before an " marks it for not being interpreted
    #now we should remove those \ so that in the end everything looks normal again
    $struc =~ s/\\"/"/g;
    return $struc;
  }
  my @res = ();
  #we've a normal list of values here (seperated by ,), no subarrays, so we can easily split the list and just return the resulting array
  if($struc =~ m/^([^"{}]*\,[^"{}]*)$/) {
    local $_ = $1;
    push @res, split(/,/, $_) if($_);
    push @res, '' if($struc =~ m/,$/);
    push @res, '' if($struc =~ m/^,$/);
    return @res;
  }

  my ($off,$lbr,$rbr,$quot) = (0,0,0,0,0,0,0);
  my $last = $_ = '';
  for(my $i=0; $i<length($struc); $i++) {
    $last = $_;
    $_ = substr($struc, $i, 1);
    last unless defined($_);
    #we found a quotation mark, now we've to wait till we reach the end
    ++ $quot && $i<length($struc)-1 ? next : $i++ if($_ eq '"' and $last ne '\\');
    #we're not in a quoted area if $quot % 2 == 0
    unless($quot % 2) {
      ++ $lbr and next if($_ eq '{');
      #if we're at the end of the string we mustn't do a next because that would cause a break of the loop
      ++ $rbr and $i<length($struc)-1 ? next : $i++ if($_ eq '}');
      #when we find a ',' or we're at the end of the string and there are as may '{' as '}' we shall parse the piece from the last ',' or beginning till here
      if($_ eq ',' || $i >= length($struc)-1 and $lbr == $rbr) {
	# when we're at the end we must add 1 more because $i wasn't increased because we didn't do a 'next'
	local $_ = substr($struc,$off,$i-$off);
	#remove brackets
	if(m/^{(.*)}$/) {
	  push @res, [$self->_dbsql_parse($1)];
	}
	else {
	  push @res, $self->_dbsql_parse($_);
	}
	$off=$i+1;
	next;
      }
    }
  }
  return @res;
}

#compare given checksum with the checksum of the given value
sub _dbsql_chk_check_sum {
  my($self,$md5hash,$val) = @_;
  return 1 if($md5hash eq md5_hex(join($self->{skin_obj}->get_dbsql_secret(), @{$val}) . $self->{skin_obj}->get_dbsql_secret()));
  return 0;
}

#gets error string and error number from dbi object, the sqlstatement which causes the error should be passed to the method. it then adds part of this information (depending on dbsql_sqlerr_show) to the bottom of the form using a special template which name is provided by dbsql_sqlerr_tmpl (can be changed by method dbsql_set_sqlerr_templ)
sub _dbsql_sql_error {
  my($self, $sql) = @_;
  $self->{dbsql_sqlerr} = [$self->{dbsql}->errstr, $sql, $self->{dbsql}->err];
  my %errconf = (
		 ERRNUM => $self->{dbsql_sqlerr_show} & 1 ? $self->{dbsql}->err : gettext('can\'t be displayed'),
		 ERRMSG => $self->{dbsql_sqlerr_show} & 2 ? $self->{dbsql}->errstr : gettext('can\'t be displayed'),
		 SQLSTAT => $self->{dbsql_sqlerr_show} & 4 ? $sql : gettext('can\'t be displayed')
		);
  $self->_add_to_output($self->{dbsql_sqlerr_tmpl},\%errconf);
}

#this method is for internal use only, it just ensures that the given value is an array reference, if not it turns it into one
sub retarref {
  my $arr = shift;
  defined($arr) ? return [$arr] : return [] if(ref($arr) ne 'ARRAY');
  return $arr;
}

# expects 2 array references. it then takes the first arrays structure as a template in which it puts the values of the second array. the result is returned.
sub _array2array {
  my($arr1,$arr2,$i) = @_;
  $i = 0 unless($i);
  my (@res,$elem);
  foreach $elem (@$arr1) {
    if(ref($elem) eq 'ARRAY') {
      local $_;
      ($_,$i) = _array2array($elem,$arr2,$i);
      push @res, $_;
    }
    else {
      push @res, defined($arr2->[$i]) ? $arr2->[$i] : '';
      $i ++;
    }
  }
  return (\@res, $i);
}

######################################################################

=head1 EXTENDING FORMENGINE::DBSQL

=head2 Write A Handler For Another Datatype

Have a look at DtHandler.pm and read
L<HTML::FormEngine::DBSQL::DtHandler>.

=head2 Suiting the Layout

For this task you should create a new skin. For general information
about FormEngine skins, have a look at L<HTML::FormEngine> and its
submodules. You should also read
L<HTML::FormEngine::DBSQL::SkinClassic> and its source code, the
templates which are defined there are necessary for DBSQL.pm and you
should at least implement replacements for them in your new skin. Use
C<set_skin_obj> to load your skin.

=head1 MORE INFORMATION

Have a look at ...

=over

=item

L<HTML::FormEngine::DBSQL::DtHandler> and its source code for
information about writing datatype handlers.

=item

L<HTML::FormEngine::DBSQL::SkinClassic> and its source code for
information about the DBSQL.pm specific templates.

=back

=head1 BUGS

Please use
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormEngine-DBSQL> to
inform you about reported bugs and to report bugs.

If it doesn't work feel free to email directly to
moritz@freesources.org.

Thanks!

=head1 AUTHOR

(c) 2003-2004, Moritz Sinn. This module is free software; you can
redistribute it and/or modify it under the terms of the GNU General
Public License (see http://www.gnu.org/licenses/gpl.txt) as published
by the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

I am always interested in knowing how my work helps others, so if you
put this module to use in any of your own code please send me the
URL. If you make modifications to the module because it doesn't work
the way you need, please send me a copy so that I can roll desirable
changes into the main release.

Please use
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormEngine-DBSQL> for
comments, suggestions and bug reports. If it doesn't work feel free to
mail to moritz@freesources.org.

=head1 CREDITS

Special thanks to Mark Stosberg, he helped a lot by reporting bugs,
contributing new ideas and sending patches.

=head1 SEE ALSO

HTML::FormEngine by Moritz Sinn

HTML::FormTemplate by Darren Duncan

=cut

1;

__END__
