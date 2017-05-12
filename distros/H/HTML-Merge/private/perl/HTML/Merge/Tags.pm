package HTML::Merge::Tags;
1;
__END__

=head1 NAME

HTML::Merge::Tags - A summary of the available tags in Merge

=head1 DATABASE TAGS

=over 4

=item *

E<lt>$RDB='[B<Database type>:]B<Database name>[:B<Host>][,B<User>[,B<Password>]]'E<gt>

Connect to alternative database. Defaults are taken from the configuration 
file. If two parameters are given in the first token, the database type takes
precedence.

Predefined databases from merge.conf can be used like this:

E<lt>$RDB='SYSTEM'E<gt> for system database
If system database (SESSION_DB) is not defined in merge.conf a system wide 
definition will apply.

E<lt>$RDB='DEFAULT'E<gt> for the application database as defined 
in merge.conf

=item *

E<lt>$RS='B<SQL statement>'E<gt>

Perform a non query SQL statement.

=item *

E<lt>$RQ='SELECT B<SQL statement>'E<gt>

Perform a query. First row of result is immediately available.
Query can be iterated with E<lt>$RLOOPE<gt> tags.

=item *

E<lt>$RERUNE<gt>

Re-performs the query.

=item *

E<lt>$RLOOP[.LIMIT=B<number>]E<gt>

E<lt>/$RLOOPE<gt>

E<lt>$RENDE<gt>

Performs a loop over fetched query elements. Last row remains valid after
iteration.
Iteration number can be limited.

=item *

E<lt>$RSQL.B<variable>E<gt>

Dereferences a column from the current fetch. Or in other words
the variable holds the data fetched from data base.

=item *

E<lt>$RINDEXE<gt>

Substitutes for the number of the row currently fetched.

=item *

E<lt>$RFETCHE<gt>

Fetches another row. Increments the index.

=item *

E<lt>$RSTATEE<gt>

Returns the SQL state of the last statement.

=item *

E<lt>$REMPTYE<gt>

Returns a boolean value of whether the last query yielded an empty set.

=item *

E<lt>$RDISCONNECTE<gt>

Destroy an engine. This is used if the DB_DATABASE configuration
variable has been changed using the E<lt>$RCFGSETE<gt> tag to 
recreate the engine with the new parameters.

=back

=head1 FLOW TAGS

=over 4

=item *

E<lt>$RITERATION.LIMIT=B<number>E<gt>

E<lt>/$RITERATIONE<gt>

Performs a counted loop.

=item *

E<lt>$RIF.'B<perl code>'E<gt>

E<lt>$RELSEE<gt> (optional)

E<lt>$REND_IFE<gt>

E<lt>/$RIFE<gt>

E<lt>$RELSIF.'B<perl code>'E<gt>

Perform the code if the Perl code evaluates to true.


=item *

E<lt>$RWHILE.'B<perl code>'E<gt>

E<lt>/$RWHILEE<gt>

E<lt>$REND_WHILEE<gt>

Perform a while loop.

=item *

E<lt>$RBREAKE<gt>

Break out of a loop.

=item *

E<lt>$RCONTE<gt>

Jump to the next iteration of the loop.

=item *

E<lt>$RCOUNT.B<variable>=B<from>:B<to>[,B<step>]E<gt>

E<lt>/$RCOUNTE<gt>

Perform a classic variable iteration loop. All parameters are mandatory.

=item *

E<lt>$REXITE<gt>

Exit a template in the middle.

=item *

E<lt>$RENUMREQ.B<iterator variable>=B<value variable>E<gt>

Iterate over all request parameters; each time having the first variable contain the parameter name and the second contain the value.

=item *

E<lt>$RENUMQUERY.B<iterator variable>=B<value variable>E<gt>

Iterate over all the columns of a query result. each time having the first variable contain the column name and the second contain the data.

=back

=head1 FUNCTIONAL TAGS

=over 4

=item *

E<lt>$RPIC.B<picture type>(B<instruction set>).'B<string>'E<gt>

E<lt>$RPIC.F(B<char>).'B<string>'E<gt>

Replace all white spaces by the given char.
e.g., E<lt>$RPIC.F(+).'Banana, a yellow energy bomb'E<gt>
will yield: Banana,+a+yellow+energy+bomb and so on.

E<lt>$RPIC.R(B<find>=B<replace>, ...).'B<string>'E<gt>

Replace tuples of string-to-find/string-to-replace in the
given string.
e.g., E<lt>$RPIC.R('na'='ta').'Banana'E<gt> will
yield Batata and so on.

E<lt>$RPIC.C(B<find>=B<replace>, ...).'B<string>'E<gt>

Change words  word-to-find/word-to-replace in the
given string.
e.g., E<lt>$RPIC.C('Banana'='Orange').'Banana'E<gt> will
yield Orange and so on.

E<lt>$RPIC.N(B<width>.B<fraction positions>).'B<number>'E<gt>

Left space pad the number, with a fixed number of decimal places.

E<lt>$RPIC.N(0<width>).'B<number>'E<gt>

Left zero pad the number, with a fixed number of decimal places.

(Hint, the instruction is equal to I<printf>ing with %B<string>f)

E<lt>$RPIC.NZ(<format>).'B<number>'E<gt>

Substitute a blank for zero. (Mnemonic: zero suppress)

E<lt>$RPIC.NF(<format>).'B<number>'E<gt>

After formatting the number, add commas.

Z and F may be combined.

E<lt>$RPIC.A(<width>).'B<alphanumeric string>'E<gt>

Left space pad the number to achieve a width. (Right justify)

E<lt>$RPIC.A(-<width>).'B<alphanumeric string>'E<gt>

Right space pad the number to achieve a width. (Left justify)

E<lt>$RPIC.AC(<format>).'B<alphanumeric string>'E<gt>

Capitalize string.

E<lt>$RPIC.AS(<format>).'B<alphanumeric string>'E<gt>

Convert string to lower case. (Mnemonic: Small)

E<lt>$RPIC.AP(<format>).'B<alphanumeric string>'E<gt>

Convert string to 'proper' case, ie, first and only first letter 
of each word capitalized.

E<lt>$RPIC.AW(<format>).'B<alphanumeric string>'E<gt>

Trim redundant spaces, ie, convert bulk spaces to one space.

E<lt>$RPIC.AR(<format>).'B<alphanumeric string>'E<gt>

Trim right spaces.

E<lt>$RPIC.AL(<format>).'B<alphanumeric string>'E<gt>

Trim left spaces.

L, R and W may be combined, and all combinations may be combined with either
C, S or P.

E<lt>$RPIC.D(B<format>).'B<date>'E<gt>

Format a POSIX time string, requires Date::Format.

E<lt>$RPIC.X(B<number>).'B<string>'E<gt>

Repeats a string the required number of times.

=item *

E<lt>$RDECIDE.'B<perl code>'?'B<string>':'B<string>'E<gt>

Evaluates the code. If true, yields the first string, otherwise the second.

=item *

<$RMAIL.'B<From address>','B<To address>'[,'B<Subject>']> 

E<lt>/$RMAILE<gt>

Send email, using SMTP to a host configured in merge.conf.

=item *

<$RPERL> 

E<lt>/$RPERLE<gt>

Embedded Perl code. print() may be used to write HTML or javascript. 

you may set HTML::Merge variables (E<lt>$RVARE<gt>) using 
the setvar function e.g : 

C<setvar('test_var',$test1);>

E<lt>$RVAR.test_varE<gt> will hold the value of Perl variable $test1.

All B<merge.conf> settings are available to your Perl code in the
HTML::Merge::Ini name space e.g. :

C<my $path = $HTML::Merge::Ini::MERGE_ABSOLUTE_PATH;>


=item *

E<lt>$RPERL.BE<gt>

E<lt>/$RPERLE<gt>

Embedded Perl with B<before> processing.

Your Perl code can have HTML::Merge output tags and HTML::Merge::Compile will expand your code before it will be passed to Perl. e.g.:

C<my $buf="E<lt>$RVAR.picE<gt>";>

=item *

E<lt>$RPERL.AE<gt>

E<lt>/$RPERLE<gt>

Embedded Perl with B<after> processing. 
HTML::Merge::Compile will process the value returned by your Perl code. e.g.:

C<return "E<lt>\$RSET.pic=' \"$buf\" 'E<gt>";>

You can use the merge function to enter input to HTML::Merge e.g.:

C<my $data = 'E<lt>$RSET.full_date =\'' . scalar(localtime()) . '\'E<gt>';>

C<merge($data);>

=item *

E<lt>$RPERL.CE<gt>

E<lt>/$RPERLE<gt>

Embedded Perl with after and before processing B<combined>. 

see E<lt>$RPERL.BE<gt> for information about before processing and E<lt>$RPERL.AE<gt> for about after processing.

=item *

<$REVAL.'B<perl code>'>

Evaluates the code.

=back

=head1 SOURCE TAGS

=over 4

=item *

E<lt>$REM.'B<string>'E<gt>

Add a server side comment.

=item *

E<lt>$RTRACE.'B<string>'E<gt>

Send a string to the log file.

=item *

E<lt>$RINCLUDE.'B<template name>'E<gt>

Include a template in compile time.

=item *

E<lt>$RWEBINCLUDE.'B<url>'E<gt>

Include an external web page in run time.

=item *

E<lt>$RSOURCE.'B<template>'E<gt>

E<lt>/$RSOURCEE<gt>

Generate an Anchor for a source view for a template. e.g,
E<lt>$RSOURCE.'E<lt>$RTEMPLATEE<gt>'E<gt>Click here to view
the source for this templateE<lt>/$RSOURCEE<gt>

=back

=head1 VARIABLE TAGS

=over 4

=item *

E<lt>$RVAR.B<variable>E<gt>

Dereferences a local variable, or a CGI variable. (Precedence to the former).

=item *

E<lt>$RSET.B<variable>='B<perl code>'E<gt>

Set a variable to the result of a perl code segment.
CGI variables may be overwritten.

=item *

E<lt>$RINC.B<variable>E<gt>

=item *

E<lt>$RINC.B<variable>+B<number>E<gt>

E<lt>$RINC.B<variable>-B<number>E<gt>

Modify a variable.

=item *

E<lt>$RPSET.B<variable>='B<perl code>'> 

E<lt>$RPGET.B<variable>E<gt>

Store and retrieve session variables. Must be configured in the configuration
file manually.

=item *

E<lt>$RPIMPORT.B<variable>E<gt>

Copy a persistent variable to a local variable, for faster retrieving.
Memory variables work much faster than session variables.

=item *

E<lt>$RPEXPORT.B<variable>E<gt>

Copy a regular variable to a persistent variable of the same name.

=item *

E<lt>$RPCLEARE<gt>

Erases all session variables.

=item *

E<lt>$RCFG.B<variable>E<gt>

Retrieve a variable from Merge configuration.

=item *

E<lt>$RCFGSET.B<variable>='B<perl code>'E<gt>

Forge a temporary value instead of a configuration variable. Does B<NOT> change the configuration file!

=item *

E<lt>$RCOOKIE.B<name>E<gt>

Retrieve a cookie.

=item *

E<lt>$RCOOKIESET.B<name>='B<perl expression>'E<gt>

E<lt>$RCOOKIESET.B<name>='B<perl expression>',B<minutes>E<gt>

E<lt>$RCOOKIESET.B<name>='B<perl expression>',B<non numeric>E<gt>

Set a cookie using a HTTP-EQUIV E<lt>METAE<gt> HTML tag.
The notations are used for setting a permanent cookie,
a cookie with an expire date, and a temporary cookie
that will disappear when the browser exits.

=item *

E<lt>$RENV.B<variable>E<gt>

Get an environment variable.

=item *

E<lt>$RENVSET.B<variable>='B<perl code>'E<gt>

Set an environment variable.

=back

=head1 SECURITY TAGS

These tags are valid only if the merge database exists.

IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT 
These tags are to be used with the Merge security backend which is not written yet.
IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT 

=over 4

=item *

E<lt>$RLOGIN.'B<user>','B<password>'E<gt>

Logs in. Tag outputs a boolean value to notify if login was successful or failed.

=item *

E<lt>$RAUTH.'B<realm>'E<gt>

Check if the user has permission to a specific realm/key.

=item * 

E<lt>$RCHPASS.'B<new password>'E<gt>

Change password for the logged in user.

=item *

E<lt>$RADDUSER.'B<user>','B<password>'E<gt>

Add a new user. Use with CAUTION! Any user running the page could create a user with this tag.
If Merge is running on a user shell machine, configuration and templates should be readable to the web server but not world readable!
Pages using E<lt>$RADDUSERE<gt> *must* be protected.

=item *

E<lt>$RDELUSER.'B<user>'E<gt>

Remove a user.

=item *

E<lt>$RJOIN.'B<user>','B<group>'E<gt>

E<lt>$RPART.'B<user>','B<group>'E<gt>

Add a user to a group and remove a user from a group, accordingly.

=item *

E<lt>$RGRANT.U.'B<user>','B<realm>'E<gt>

E<lt>$RGRANT.G.'B<group>','B<realm>'E<gt>

Grant a permission over a realm to a group or a user.

=item *

E<lt>$REVOKE.U.'B<user>','B<realm>'E<gt>

E<lt>$REVOKE.G.'B<group>','B<realm>'E<gt>

Revoke a permission over a realm from a group or a user.

=item *

E<lt>$REQUIRE.'B<template name>','B<list of possible realms>'E<gt>

Require users of a specific template to have access for at least one of the templates in the list. (Comma separated)

=item *

E<lt>$RUSERE<gt>

Returns the user name of the currently logged in user.

=item *

E<lt>$RNAMEE<gt>

Yield the real name of the currently logged in user.

=item *

E<lt>$RTAGE<gt>

Yield the tag string of the currently logged in user.

=item *

E<lt>$RATTACH.'B<template>','B<subsite>'E<gt>

Attach a template to a subsite.

=item *

E<lt>$RDETACH.'B<template>','B<subsite>'E<gt>

Detach a template from a subsite.

=back
 
=head1

=head1 DATE TAGS

=over 4

=item *

E<lt>$RDATEE<gt>

E<lt>$RDATE,'B<number of days ahead>'E<gt>

Return the date as a YYMDHmS string. For example: 199912312359 is December 31, 1999, at one minute before midnight.
The second parameter gives the date for a few days ahead, or beyond, if given negative.

=item *

E<lt>$RSECOND.'B<date>'E<gt>

E<lt>$RMINUTE.'B<date>'E<gt>

E<lt>$RHOUR.'B<date>'E<gt>

E<lt>$RDAY.'B<date>'E<gt>

E<lt>$RMONTH.'B<date>'E<gt>

E<lt>$RYEAR.'B<date>'E<gt>

Return the corresponding part of the date given.

=item *

E<lt>$RDATEDIFF.D.'B<earlier date>','B<later date>'E<gt>

E<lt>$RDATEDIFF.H.'B<earlier date>','B<later date>'E<gt>

E<lt>$RDATEDIFF.M.'B<earlier date>','B<later date>'E<gt>

E<lt>$RDATEDIFF.S.'B<earlier date>','B<later date>'E<gt>

Return the difference between dates, in days, hours, minutes and seconds, correspondingly.

=item *

E<lt>$RLASTDAY.'B<date>'E<gt>

Give the last day of month related to the specific date.

=item *

E<lt>$RADDDATE.'B<date>','B<day>','B<month>','B<year>'E<gt>

Add the given number of days, then the given number of months and years to the date. Returns a new date.

=item *

E<lt>$RDATE2UTC.'B<date>'E<gt>

E<lt>$RUTC2DATE.'B<UNIX epoch time>'E<gt>

Convert between a date string and a universal UNIX time.

=back

=head1 FORM AND HTML ENHANCEMENT TAGS

=over 4

=item *

E<lt>$RSUBMIT[.'B<javascript validation code>']E<gt>

E<lt>/$RSUBMITE<gt>

Create the HTML code for a POST form pointed at the same merge template
it is called from. An optional parameter is passed to the onSubmit
attribute; a typical value would be 'return I<function>()' where I<function>
returns a boolean value.

=item *

E<lt>$RTRANSFER.B<field name>E<gt>

Create a HIDDEN input tag, for the parameter with the corresponding name, based on the values the server side parameter with the same name has.
Useful to transfer input fields among pages.

=item *

E<lt>$RMULTI.'B<iterator variable>'='B<form field>'E<gt>

Iterate over multiple input form fields.

=item *

E<lt>$RMERGEE<gt>

The name of the Merge CGI.

=item *

E<lt>$RTEMPLATEE<gt>

The name of the current template.

=back

=head1 FILE TAGS

=over 4

=item *

E<lt>$RGLOB.F.'B<iterator variable>'='B<base directory or *>'E<gt>

E<lt>$RGLOB.D.'B<iterator variable>'='B<base directory>'E<gt>

Iterate over a directory. Produces either files only or directories only, accordingly.

=item *

E<lt>$RFTS.'B<iterator variable>'='B<base directory>'E<gt>

Iterate over a subtree of files.

=item *

E<lt>$RDIVERT.'B<buffer name>'E<gt>
E<lt>/$RDIVERTE<gt>

Divert the output into a named buffer. Buffers are store in temporary
files and do not overlap between processes.
Subsequent diverting is appended to the existing buffer.

=item *

E<lt>$RDUMP.'B<buffer name>'E<gt>

Dump the named buffer.

=back 4

=head1 META TAGS

=over 4

=item *

E<lt>$RVERSIONE<gt>

Returns Merge version.

=back 4


=head1 COPYRIGHT

Copyright (c) 1999 -  2005 Raz Information Systems Ltd.
http://www.raz.co.il/

This package is distributed under the same terms as Perl itself, see the
Artistic License on Perl's home page.

=cut

