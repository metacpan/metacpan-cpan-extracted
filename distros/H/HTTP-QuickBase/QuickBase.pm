package HTTP::QuickBase;

#Version $Id: QuickBase.pm,v 1.55 2013/08/09 15:29:23 cvonroes Exp $

( $VERSION ) = '$Revision: 1.55 $ ' =~ /\$Revision:\s+([^\s]+)/;

use strict;
use LWP::UserAgent;
use MIME::Base64 qw(encode_base64);

=pod

=head1 NAME

HTTP::QuickBase - Create a web shareable database in under a minute

=head1 VERSION

$Revision: 1.54 $

=head1 SYNOPSIS

 # see https://www.quickbase.com/up/6mztyxu8/g/rc7/en/ for details of the underlying API.
 
 use HTTP::QuickBase;
 $qdb = HTTP::QuickBase->new();
 
 #If you don't want to use HTTPS or your Perl installation doesn't support HTTPS then
 #make sure you have the "Allow non-SSL access (normally OFF)" checkbox checked on your
 #QuickBase database info page. You can get to this page by going to the database "MAIN"
 #page and then clicking on "Administration" under "SHORTCUTS". Then click on "Basic Properties".
 #To use this module in non-SSL mode invoke the QuickBase object like this:
 
 #$qdb = HTTP::QuickBase->new('http://www.quickbase.com/db');

 $username="fred";
 $password="flinstone";

 $qdb->authenticate($username, $password);
 $database_name= "GuestBook Template";
 
 #I don't recommend using the getIDbyName method because there are many tables with the same name.
 #Instead you can discover the database_id of your table empirically.
 #Read the follwing article to find out how:
 #https://www.quickbase.com/db/6mztyxu8?a=dr&r=w
 
 $database_id = "9mztyxu8";
 $clone_name = "My Guest Book";
 $database_clone_id = $qdb->cloneDatabase($database_id, $clone_name, "Description of my new database.");


  #Let's put something into the new guest book
 $Name = "Fred Flinstone";
 $dphone = "978-533-2189";
 $ephone = "781-839-1555";
 $email = "fred\@bedrock.com";
 $address1 = "Rubble Court";
 $address2 = "Pre Historic Route 1";
 $city = "Bedrock";
 $state = "Stonia";
 $zip = "99999-1234";
 $comments = "Hanna Barbara the king of Saturday morning cartoons.";
 #if you want to attach a file you need to create an array with the first member of the array set to the literal string "file" and the second 
 #member of the array set to the full path of the file.
 $attached_file = ["file", "c:\\my documents\\bedrock.txt"];
 %record_data=("Name" => $Name,"Daytime Phone" => $dphone, "Evening Phone" =>$ephone,"Email Address" => $email, "Street Address 1" => $address1,"Street Address 2" => $address2,"City" => $city,"State"=>$state,"Zip Code"=>$zip, "Comments" => $comments , "Attached File" => $attached_file );

 $record_id = $qdb->AddRecord($database_clone_id, %record_data);

 #Let's get that information back out again
 %new_record=$qdb->GetRecord($database_clone_id, $record_id);
 #Now let's edit that record!
 $new_record{"Daytime Phone"} = "978-275-2189";
 $qdb->EditRecord($database_clone_id, $record_id, %new_record);
 
 #Let's print out all records in the database.

 @records = $qdb->doQuery($database_clone_id, "{0.CT.''}");
 foreach $record (@records){
	foreach $field (keys %$record){
		print "$field -> $record->{$field}\n";
		}
	}

 #Let's save the entire database to a local comma separated values (CSV) file.
 
 open( CSV, ">my_qbd_snapshot.csv");
 print CSV $qdb->getCompleteCSV($database_clone_id);
 close CSV;	
	
 #Where field number 10 contains Wilma (the query)
 #let's print out fields 10, 11, 12 and 15 (the clist)
 #sorted by field 14 (the slist)
 #in descending order (the options)

 @records = $qdb->doQuery($database_clone_id, "{10.CT.'Wilma'}", "10.11.12.15", "14", "sortorder-D");
 foreach $record (@records){
	foreach $field (keys %$record){
		print "$field -> $record->{$field}\n";
		}
	}

 #You can find out what you need in terms of the query, clist, slist and options by
 #going to the View design page of your QuickBase database and filling in the form. Hit the "Display" button and
 #look at the URL in the browser "Address" window. The View design page is accessible from any database home
 #page by clicking on VIEWS at the top left and then clicking on "New View..." in the lower left.

=head1 REQUIRES

Perl5.005, LWP::UserAgent, Crypt::SSLeay (optional unless you want to talk to QuickBase via HTTPS)

=head1 SEE ALSO

https://www.quickbase.com/up/6mztyxu8/g/rc7/en/ for details of the underlying QuickBase HTTP API

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

HTTP::QuickBase allows you to manipulate QuickBase databases.  
Methods are provided for cloning databases, adding records, editing records, deleting records and retrieving records.
All you need is a valid QuickBase account, although with anonymous access you can read from publically accessible QuickBase
databases. To learn more about QuickBase please visit http://www.quickbase.com/
This module supports a single object that retains login state. You call the authenticate method only once. 

=head1 METHODS

=head2 Creation

=over 4

=item $qdb = new HTTP::QuickBase($URLprefix)

Creates and returns a 
new HTTP::QuickBase object. 
Use the optional $URLprefix to connect to QuickBase via HTTP instead of HTTPS.
call the constructor with a URLprefix parameter of "http://www.quickbase.com/db/".
QuickBase databases are by default not accessible via HTTP. To allow HTTP access to a
QuickBase database go to its main page and click on "Administration" under "SHORTCUTS".
Then click on "Basic Properties". Next to "Options" you'll see a checkbox labeled 
"Allow non-SSL access (normally unchecked)". You'll need to check this box to allow HTTP 
access to the database.

=back

=head2 Authentication/Permissions

=over 4

=item $qdb->authenticate($username, $password)

Sets the username and password used for subsequent method invocations

=back

=head2 Finding IDs

=over 4

=item $qdb->getIDbyName($dbName)

Returns the database ID of the database whose full name matches $dbName.
I don't recommend using the getIDbyName method because there are many tables with the same name.
Instead you can discover the database_id of your table empirically.
Read the follwing article to find out how:
https://www.quickbase.com/db/6mztyxu8?a=dr&r=w

=item $qdb->GetRIDs ($QuickBaseID)

Returns an array of all record IDs in the database identified by database ID $QuickBaseID.

=back

=head2 Cloning and Creating from Scratch

=over 4


=item $qdb->cloneDatabase($QuickBaseID, $Name, $Description)

Clones the database identified by $QuickBaseID and gives the clone the name $Name and description $Description

Returns the dbid of the new database.

=back

=over 4

=item $qdb->createDatabase($Name, $Description)

Creates a database with the name $Name and description $Description

Returns the dbid of the new database.

=back

=over 4

=item $qdb->addField($QuickBaseID, $label, $type, $mode)

Creates a field with the label $label of label, a type of $type and if the field is to be a formula field then set $mode to 'virtual' otherwise set it to the empty string.

Returns the fid of the new field.

=back

=over 4

=item $qdb->deleteField($QuickBaseID, $fid)

Deletes the field with the field identifier of $fid.

Returns nothing.

=back

=over 4

=item $qdb->setFieldProperties($QuickBaseID, $fid, %properties)

Modifies the field with the field identifier of $fid using the name-value pairs in %properties. Please see the QuickBase HTTP API document for more details.

Returns nothing.

=back


=head2 Adding Information

=over 4


=item $qdb->AddRecord($QuickBaseID, %recorddata)

Returns the record id of the new record. The keys of the associative array %recorddata are scanned for matches with the 
field names of the database. If the key begins with the number one through nine and contains only numbers
then the field identifiers are scanned for a match instead.
If a particular key matches then the corresponding field in the new record is set to the value associated with the key.
If you want to attach a file you need to create an array with the first member of the array set to the string literal 'file' and the second 
member of the array set to the full path of the file. Then the value of the key corresponding to the file attachment field 
should be set to a reference which points to this two member array.  

=back

=head2 Deleting Information

=over 4

=item $qdb->DeleteRecord($QuickBaseID, $rid)

Deletes the record identified by the record identifier $rid.

=back

=over 4

=item $qdb->PurgeRecords($QuickBaseID, $query)

Deletes the records identified by the query, qname or qid in $query. Use the qid of '1' to delete all the records in a database.

Please refer to https://www.quickbase.com/db/6mztyxu8?a=dr&r=2 for more details on the query parameter.

=back



=head2 Editing Information

=over 4

=item $qdb->EditRecord($QuickBaseID, $rid, %recorddata)

Modifies the record defined by record id $rid in the database defined by database ID $QuickBaseID.

Any field in the database that can be modified and that has its field label or field identifer as a key in the associative array
%recorddata will be modified to the value associated with the key. The keys of the associative array %recorddata are scanned for matches with the 
field names of the database. If the key begins with the number one through nine and contains only numbers
then the field identifiers are scanned for a match instead.
If a particular key matches then the corresponding field in the record is set to the value associated with the key.
If you want to modify a file attachment field, you need to create an array with the first member of the array set to the string literal 'file' and the second 
member of the array set to the full path of the file. Then the value of the key corresponding to the file attachment field 
should be set to a reference which points to this two member array.  


Use $qdb->EditRecordWithUpdateID($QuickBaseID, $rid, $update_id, %recorddata) to take advantage of conflict detection.
If $update_id is supplied then the edit will only succeed if the record's current update_id matches.

Returns the XML response from QuickBase after modifying every valid field refered to in %recorddata.

Not all fields can be modified. Built-in and formula (virtual) fields cannot be modified. If you attempt to 
modify them with EditRecord you will get an error and no part of the record will have been modified. 

=back

=head2 Retrieving Information

=over 4

=item $qdb->GetRecord($QuickBaseID, $rid)

From the database identified by $QuickBaseID, returns an associative array of field names and values of the record identified by $rid.

=back

=over 4

=item $qdb->doQuery($QuickBaseID, $query, $clist, $slist, $options)

From the database identified by $QuickBaseID, returns an array of
associative arrays of field names and values of the records selected by
$query, which can either be an actual query in QuickBase's query
language, or a view name or number (qid or qname).

The columns (fields) returned are determined by $clist, a period delimited list of field identifiers.

The sorting of the records is determined by $slist, a period delimited list of field identifiers.

Ascending or descending order of the sorts defined by $slist is controlled by $options.

Please refer to https://www.quickbase.com/db/6mztyxu8?a=dr&r=2 for more details on the parameters for API_DoQuery.

=back

=over 4

=item $qdb->getCompleteCSV($QuickBaseID)

From the database identified by $QuickBaseID, returns a scalar containing the comma separated values of all fields including built in fields.

The first row of the comma separated values (CSV) contains the field labels.  

=back

=over 4

=item $qdb->GetFile($QuickBaseDBid, $filename, $rid, $fid)

From the database identified by $QuickBaseID, returns an array where the first element is the contents of the file $filename uploaded to
the record identified by record ID $rid in the field identified by field indentifier $fid.

The second element of the returned array is return value from the headers method of the corresponding LWP::UserAgent object. 

=back




=head2 Errors

=over 4

=item $qdb->error()

Retrieve the error code returned from QuickBase.
Please refer to the
<a href="https://www.quickbase.com/up/6mztyxu8/g/rc7/en/">
Appendix A for error code details.

=item $qdb->errortext()

Retrieve the error text returned from QuickBase.
Please refer to
<a href="https://www.quickbase.com/up/6mztyxu8/g/rc7/en/">
Appendix A for all possible error messages.


=back


=head2 New API calls added in 2008




=over 4

=item CreateTable($QuickBaseDBid, $pnoun)

Add a table to an existing application.

Returns the dbid of the new table.

=back



=over 4

=item AddUserToRole($QuickBaseDBid, $userid, $roleid)

Add a user to a role in an application.

=back



=over 4

=item ChangeUserRole($QuickBaseDBid, $userid, $roleid, $newroleid)

Change the role of a user in an application.

=back



=over 4

=item GetDBvar($QuickBaseDBid, $varname)

Retrieve the value of an application variable.

=back

=over 4

=item GetRoleInfo($QuickBaseDBid)

Retrieve the list of Roles defined for an application.

=back

=over 4

=item GetUserInfo($email)

Retrieve a hash containing the login, name, and id of a user, given the user's email address. 

=back


=over 4

=item GetUserRole($QuickBaseDBid,$userid)

Retrieve the Role information for a user

=back

=over 4

=item ProvisionUser($QuickBaseDBid,$roleid, $email, $fname, $lname)

Add the user information to QuickBase in preparation for inviting the user for the first time to view a QuickBase application.

=back


=over 4

=item GetOneTimeTicket

Retrieve a ticket valid for the next 5 minutes only. Designed for uploading files.

=back

=over 4

=item RemoveUserFromRole($QuickBaseDBid, $userid, $roleid)

Remove a user from a role in an application.

=back


=over 4

=item RenameApp($QuickBaseDBid,$newappname)

Change the name of an application.

=back


=over 4

=item SetDBvar($QuickBaseDBid, $varname, $value)

Set the value of an application variable.

=back


=over 4

=item SendInvitation($QuickBaseDBid, $userid)

Send an email from QuickBase inviting a user to an application. 

=back


=over 4

=item UserRoles($QuickBaseDBid)

Returns an Xml Document of information about the roles defined for an application.

=back



=head1 CLASS VARIABLES

None

=head1 DIAGNOSTICS

All errors are reported by the methods error and errortext. For a
complete list of errors, please visit
https://www.quickbase.com/up/6mztyxu8/g/rc7/en/ and scroll
down to Appendix A.

=head1 AUTHOR

Claude von Roesgen, claude_von_roesgen@intuit.com

=head1 COPYRIGHT

Copyright (c) 1999-2008 Intuit, Inc. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut

my %XMLescapes; 

sub new
{
    my $class = shift;
    my $prefix = shift;
    my $self;

	for (0..255) {
    	$XMLescapes{chr($_)} = sprintf("&#%03d;", $_);
	}

	$self = bless {
		'URLprefix' => $prefix || "https://www.quickbase.com/db" ,
		'ticket' => undef,
		'apptoken' => "",
		'error' => undef,
		'errortext' => undef,
		'username' => undef,
		'password' => undef,
		'credentials' => undef,
		'proxy' => undef,
		'realmhost' => undef
		}, $class;

}

sub authenticate ($$)
{
my($self, $username, $password) = @_;
	$self->{'username'} = $username;
	$self->{'password'} = $password;
	$username = $self->xml_escape($username);
	$password = $self->xml_escape($password);
	$self->{'credentials'} = "<username>$username<\/username><password>$password<\/password>";
	$self->{'ticket'}="";
	return "";
}

sub setAppToken($)
{
  my($self,$apptoken) = @_;
  $self->{'apptoken'} = $apptoken;
}

sub getTicket()
{
my($self) = @_;
    #First we have to get the authorization ticket
	#We do this by posting the QuickBase username and password to QuickBase
	#This is where we post the QuickBase username and password
	my $res = $self->PostAPIURL ("main", "API_Authenticate", 
		  "<qdbapi>".
			$self->{'credentials'}.
          "</qdbapi>");
	if ($res->content =~ /<errcode>(.*?)<\/errcode>.*?<errtext>(.*?)<\/errtext>/s)
		{
		$self->{'error'} = $1;
		$self->{'errortext'} = $2;
		}
	if ($res->content =~ /<errdetail>(.*?)<\/errdetail>/s)
		{
		$self->{'errortext'} = $1;
		}		
	if ($self->{'error'} eq '0')
		{
		$res->content =~ /<ticket>(.*?)<\/ticket>/s;
		$self->{'ticket'} = $1;
		$self->{'credentials'} = "<ticket>$self->{'ticket'}<\/ticket>";
		}
	else
		{
		return "";
		}
	return $self->{'ticket'};
}

sub URLprefix()
{
my($self) = shift;
if (@_)
	{
	$self->{'URLprefix'}=shift;
	$self->{'URLprefix'} =~ s/cgi\/sb.exe/db/;
	return $self->{'URLprefix'};
	}
else
	{
	return $self->{'URLprefix'};
	}
}

sub setProxy($)
{
my($self, $proxyserver) = @_;
$self->{'proxy'} = $proxyserver;
return $self->{'proxy'};	
}

sub setRealmHost($)
{
my($self, $realmhost) = @_;
$self->{'realmhost'} = $realmhost;
return $self->{'realmhost'};	
}

sub errortext()
{
my($self) = shift;
return $self->{'errortext'};	
}

sub error()
{
my($self) = shift;
return $self->{'error'};	
}

sub AddRecord($%)
{
my($self, $QuickBaseDBid, %recorddata) = @_;
my $name;
my $content;
my $filecontents;
my $filebuffer;
my $tag;

$content = "<qdbapi>";
foreach $name (keys(%recorddata))
	{
	$tag=$name;
	$tag =~tr/A-Z/a-z/;
	$tag=~s/[^a-z0-9]/_/g;
	$content .= $self->createFieldXML($tag, $recorddata{$name});
	}

$content .= "</qdbapi>";
my $res = $self->PostAPIURL ($QuickBaseDBid, "API_AddRecord", $content);
my $xml = $res->content;

if ($xml =~ /<rid>(.*)<\/rid>/ )
	{
	return $1;
	}
return "";
}

sub AddReplaceDBPage($$$$$)
{
  my($self,$QuickBaseDBid, $pageid, $pagename, $pagetype, $pagebody) = @_;
  
  my $content = "<qdbapi>";
  $content .= "<pageid>$pageid</pageid>" if $pageid ne "";
  $content .= "<pagename>$pagename</pagename>" if $pagename ne "";
  $content .= "<pagetype>$pagetype</pagetype><pagebody>".$self->xml_escape($pagebody)."</pagebody></qdbapi>";
  
  my $res = $self->PostAPIURL ($QuickBaseDBid, "API_AddReplaceDBPage", $content)->content;
  
  if($res =~ /<pageid>(.*)<\/pageid>/ ){
    return $1;
    }
  elsif($res =~ /<pageID>(.*)<\/pageID>/ ){
    return $1;
    }
  else
    {
    return "";
    }
}

sub AddUserToRole($$$)
{
  my($self,$QuickBaseDBid, $userid, $roleid) = @_;
  my $content = "<qdbapi><userid>$userid</userid><roleid>$roleid</roleid></qdbapi>";
  $self->PostAPIURL ($QuickBaseDBid, "API_AddUserToRole", $content);
  return "";
}

sub ChangeUserRole($$$$)
{
  my($self,$QuickBaseDBid, $userid, $roleid, $newroleid) = @_;
  my $content = "<qdbapi><userid>$userid</userid><roleid>$roleid</roleid></qdbapi>";
  $self->PostAPIURL ($QuickBaseDBid, "API_AddUserToRole", $content);
  return "";
}

sub ChangeRecordOwner($$$)
{
    my($self, $QuickBaseDBid, $rid, $newowner);
    
    my $content = "<qdbapi><rid>$rid</rid><newowner>$newowner</newowner></qdbapi>";
    $self->PostAPIURL ($QuickBaseDBid, "API_ChangeRecordOwner", $content);
    return"";
}

sub CreateTable($$)
{
  my($self,$QuickBaseDBid, $pnoun) = @_;
  my $content = "<qdbapi><pnoun>".$self->xml_escape($pnoun)."</pnoun></qdbapi>";
  my $res = $self->PostAPIURL ($QuickBaseDBid, "API_CreateTable", $content)->content;
  if($res =~ /<newdbid>(.*)<\/newdbid>/ ){
    return $1;
    }
  elsif($res =~ /<newDBID>(.*)<\/newDBID>/ ){
    return $1;
    }
  else
    {
    return "";
    }
}

sub DeleteDatabase($)
{
  my($self,$QuickBaseDBid) = @_;
  $self->PostAPIURL($QuickBaseDBid, "API_DeleteDatabase", "");
  return "";
}

sub DeleteRecord($$)
{
my($self, $QuickBaseDBid, $rid) = @_;

my $content =    "<qdbapi>".
              " <rid>$rid</rid>".
              "</qdbapi>";
$self->PostAPIURL ($QuickBaseDBid, "API_DeleteRecord", $content)->content;
}

sub FieldAddChoices($$@)
{
  my($self,$QuickBaseDBid, $fid, @choices) = @_;
  
  my $content = "<qdbapi><fid>$fid</fid>";
  my $choice;
  foreach $choice (@choices)
	  {
		$content .= "<choice>$choice</choice>";
	  }
  $content .= "</qdbapi>";
  
  my $res = $self->PostAPIURL ($QuickBaseDBid, "API_FieldAddChoices", $content)->content;
  
  if($res =~ /<numadded>(.*)<\/numadded>/ ){
    return $1;
    }
  else
    {
    return "";
    }
}

sub FieldRemoveChoices($$@)
{
  my($self,$QuickBaseDBid, $fid, @choices) = @_;
  
  my $content = "<qdbapi><fid>$fid</fid>";
  my $choice;
  foreach $choice (@choices)
	  {
		$content .= "<choice>$choice</choice>";
	  }
  $content .= "</qdbapi>";  
  
  my $res = $self->PostAPIURL ($QuickBaseDBid, "API_FieldRemoveChoices", $content)->content;
  
  if($res =~ /<numremoved>(.*)<\/numremoved>/ ){
    return $1;
    }
  else
    {
    return "";
    }
}

sub GenAddRecordForm($%)
{
  my($self,$QuickBaseDBid,%fields) = @_;
  my $content = "<qdbapi>";
  my $field;
  foreach $field (keys %fields)
	  {
		$content .= "<field name=\'$field\'>$fields{$field}</field>";
	  }
  $content .= "</qdbapi>";  
  $self->PostAPIURL ($QuickBaseDBid, "API_GenAddRecordForm", $content)->content;
}

sub GenResultsTable($$$$$$$)
{
  my($self, $QuickBaseDBid, $query, $clist, $slist, $jht, $jsa, $options) = @_;
  my $content = "<qdbapi>";
  $content .= "<query>$query</query>" if $query ne ""; 
  $content .= "<clist>$clist</clist>" if $clist ne "";  
  $content .= "<slist>$slist</slist>" if $slist ne "" ;
  $content .= "<jht>$jht</jht>" if $jht ne "";  
  $content .= "<jsa>$jsa</jsa>" if $jsa ne "";
  $content .= "<options>$options</options>" if $options ne "";
  $content .= "</qdbapi>";  
  $self->PostAPIURL ($QuickBaseDBid, "API_GenAddRecordForm", $content)->content;
}

sub GetDBInfo($)
{
  my($self,$QuickBaseDBid) = @_;
  
  my $res = $self->PostAPIURL ($QuickBaseDBid, "API_GetDBInfo", "")->content;
  
  my %dbInfo;
  if($res =~ /<dbname>(.*)<\/dbname>/ ){
    $dbInfo{"dbname"} = $1;
    }
  if($res =~ /<version>(.*)<\/version>/ ){
    $dbInfo{"version"} = $1;
    }
  if($res =~ /<lastRecModTime>(.*)<\/lastRecModTime>/ ){
    $dbInfo{"lastRecModTime"} = $1;
    }
  if($res =~ /<lastModifiedTime>(.*)<\/lastModifiedTime>/ ){
    $dbInfo{"lastModifiedTime"} = $1;
    }
  if($res =~ /<createdTime>(.*)<\/createdTime>/ ){
    $dbInfo{"createdTime"} = $1;
    }
  if($res =~ /<lastAccessTime>(.*)<\/lastAccessTime>/ ){
    $dbInfo{"lastAccessTime"} = $1;
    }
  if($res =~ /<numRecords>(.*)<\/numRecords>/ ){
    $dbInfo{"numRecords"} = $1;
    }
  if($res =~ /<mgrID>(.*)<\/mgrID>/ ){
    $dbInfo{"mgrID"} = $1;
    }
  if($res =~ /<mgrName>(.*)<\/mgrName>/ ){
    $dbInfo{"mgrName"} = $1;
    }
  return %dbInfo;  
}

sub GetDBPage($$$)
{
   my($self, $QuickBaseDBid, $pageid, $pagename) = @_;
   
  my $content = "<qdbapi>";
  $content .= "<pageid>$pageid</pageid>" if $pageid ne "";
  $content .= "<pagename>$pagename</pagename>" if $pagename ne "";
  $content .= "</qdbapi>";
  
  $self->PostAPIURL ($QuickBaseDBid, "API_GetDBPage", $content)->content;
}

sub GetDBvar($$)
{
   my($self,$QuickBaseDBid, $varname) = @_;
   my $content = "<qdbapi><varname>$varname</varname></qdbapi>";
   my $res = $self->PostAPIURL($QuickBaseDBid, "API_GetDBvar", $content)->content;
   if($res =~ /<value>(.*)<\/value>/ ){
      return $1;
      }
    else
      {
      return "";
      }
}

sub GetNumRecords($)
{
   my($self,$QuickBaseDBid) = @_;
   my $res = $self->PostAPIURL ($QuickBaseDBid, "API_GetNumRecords", "")->content;
   if($res =~ /<num_records>(.*)<\/num_records>/ ){
      return $1;
      }
    else
      {
      return "";
      }
}

sub GetOneTimeTicket()
{
   my($self) = @_;
   my $res = $self->PostAPIURL ("main", "API_GetOneTimeTicket", "")->content;
   if($res =~ /<ticket>(.*)<\/ticket>/ ){
      return $1;
      }
    else
      {
      return "";
      }
}

sub GetRecord($$)
{
my($self, $QuickBaseDBid, $rid) = @_;
my $content;
my @record;
my %record;
my $true=1;
my $false=0;
my $isFieldname = $false;
my $isFieldvalue = $false;
my $isFieldprintable = $false;
my ($fieldname, $fieldvalue, $fieldprintable) = ("","","");

$content =    "<qdbapi>".
              " <rid>$rid</rid>".
              "</qdbapi>";
	my $res = $self->PostAPIURL ($QuickBaseDBid, "API_GetRecordInfo", $content);
	my $recordXML = $res->content;
	$recordXML =~ s/<br\/>/\n/ig;
	@record = $recordXML =~ /<([A-Z\-\.0-9]+)>([^<]*)<\/\1>/isg;
	my $count = 0;
	my $record;

	foreach $record(@record){
		unless ($count % 2)
			{
			if($record=~/^name$/)
				{
				$isFieldname = $true;
				if ($fieldname)
					{
					$fieldname = $self->xml_unescape($fieldname);
					if($fieldprintable){
						  $record{$fieldname} = $self->xml_unescape($fieldprintable);							   
					}elsif($fieldvalue){
						  $record{$fieldname} = $self->xml_unescape($fieldvalue);
						  }
					}
				$fieldname=""; $fieldvalue=""; $fieldprintable="";
				}
			elsif($record=~/^value$/)
				{
				$isFieldvalue = $true;
				}
			elsif($record=~/^printable$/)
				{
				$isFieldprintable = $true;
				}
			}
		else
			{
			if($isFieldname)
				{
				$fieldname = $record;
				$isFieldname = $false;
				}
			elsif($isFieldvalue)
				{
				$fieldvalue = $record;
				$isFieldvalue = $false;
				}
			elsif($isFieldprintable)
				{
				$fieldprintable = $record;
				$isFieldprintable = $false;
				}
			}
		$count++;
	}
	if ($fieldname)
		{
		$fieldname = $self->xml_unescape($fieldname);
		if($fieldprintable){
		  		   $record{$fieldname} = $self->xml_unescape($fieldprintable);							   
		  }elsif($fieldvalue){
		  			$record{$fieldname} = $self->xml_unescape($fieldvalue);
		  	}
		}

	return %record;
}

sub GetRecordAsHTML($$$)
{
    my($self, $QuickBaseDBid, $rid, $jht) = @_;
    my $content = "<qdbapi><rid>$rid</rid>";
    $content .= "<jht>$jht</jht>" if $jht  ne "";
    $content .= "</qdbapi>";
    $self->PostAPIURL ($QuickBaseDBid, "API_GetRecordAsHTML", $content)->content;
}

sub GetRecordInfo($$)
{
    my($self, $QuickBaseDBid, $rid) = @_;
    my $content = "<qdbapi><rid>$rid</rid></qdbapi>";
    $self->PostAPIURL ($QuickBaseDBid, "API_GetRecordInfo", $content)->content;
}

sub GetRoleInfo($)
{
    my($self, $QuickBaseDBid) = @_;
    $self->PostAPIURL ($QuickBaseDBid, "API_GetRoleInfo", "")->content;
}

sub GetSchema
{
    my($self,$QuickBaseDBid) = @_;
    $self->PostAPIURL ($QuickBaseDBid, "API_GetSchema", "")->content;
}

sub GetUserInfo($)
{
    my($self,$email) = @_;
    
    my $content = "<qdbapi><email>$email</email></qdbapi>";
    
    my $res = $self->PostAPIURL ("main", "API_GetUserInfo", $content)->content;
    
    my %userInfo;
    if($res =~ /<login>(.*)<\/login>/ ){
      $userInfo{"login"} = $1
    }  
    if($res =~ /<name>(.*)<\/name>/ ){
      $userInfo{"name"} = $1
    }  
    if($res =~ /<firstName>(.*)<\/firstName>/ ){
      $userInfo{"firstName"} = $1
    }  
    if($res =~ /<lastName>(.*)<\/lastName>/ ){
      $userInfo{"lastName"} = $1
    }  
    if($res =~ /id=\"(.*)\"/ ){
      $userInfo{"id"} = $1
    }  
    return %userInfo;
}

sub GetUserRole($$)
{
    my($self,$QuickBaseDBid,$userid) = @_;
    my $content = "<qdbapi><userid>$userid</userid></qdbapi>";
    $self->PostAPIURL ($QuickBaseDBid, "API_GetUserRole", $content)->content;
}

sub GrantedDBs()
{
    my($self) = @_;
    $self->PostAPIURL ("main", "API_GrantedDBs", "")->content;
}

sub ProvisionUser($$$$$)
{
   my($self, $QuickBaseDBid,$roleid, $email, $fname, $lname) = @_;
   my $content = "<qdbapi>";
   $content .= "<roleid>$roleid</roleid>";
   $content .= "<email>$email</email>";
   $content .= "<fname>$fname</fname>";
   $content .= "<lname>$lname</lname>";
   $content .= "</qdbapi>";
   my $res = $self->PostAPIURL ($QuickBaseDBid, "API_ProvisionUser", $content)->content;
   if($res =~ /<userid>(.*)<\/userid>/ ){
      return $1;
      }
    else
      {
      return "";
      }
}

sub RemoveUserFromRole($$$)
{
   my($self, $QuickBaseDBid, $userid, $roleid) = @_; 
   my $content = "<qdbapi><userid>$userid</userid><roleid>$roleid</roleid></qdbapi>";
   $self->PostAPIURL ($QuickBaseDBid, "API_RemoveUserFromRole", $content);
   return ""; 
}

sub RenameApp($$)
{
   my($self,$QuickBaseDBid,$newappname) = @_;
   my $content = "<qdbapi><newappname>" . $self->xml_escape($newappname) . "</newappname></qdbapi>";
   $self->PostAPIURL ($QuickBaseDBid, "API_RenameApp", $content);
   return "";
}

sub SendInvitation($$)
{
   my($self, $QuickBaseDBid, $userid) = @_;
   my $content = "<qdbapi><userid>$userid</userid></qdbapi>";
   $self->PostAPIURL ($QuickBaseDBid, "API_SendInvitation", $content);
   return "";
}

sub SetDBvar($$$)
{
   my($self, $QuickBaseDBid, $varname, $value) = @_;
   my $content = "<qdbapi><varname>$varname</varname><value>$value</value></qdbapi>";
   $self->PostAPIURL ($QuickBaseDBid, "API_SetDBvar", $content);
   return "";
}

sub UserRoles($)
{
   my($self,$QuickBaseDBid) = @_;
   $self->PostAPIURL ($QuickBaseDBid, "API_UserRoles", "")->content;
}

sub GetURL($$)
{
my($self, $QuickBaseDBid, $action) = @_;
my $error;

unless( $action =~ /^act=API_|\&act=API_/i)
	{
	$self->{'error'} = "1";
	$self->{'errortext'} = "Error: You're using a QuickBase URL that is not part of the HTTP API. ". $action . "\n"
		. "Please use only actions that start with 'API_' i.e. act=API_GetNumRecords.\n"
		. "Please refer to the <a href='https://www.quickbase.com/up/6mztyxu8/g/rc7/en/'>QuickBase HTTP API documentation</a>.";
	return $self->{'errortext'};
	}


my $ua = new LWP::UserAgent;
$ua->agent("QuickBasePerlAPI/2.0");
if ($self->{'proxy'}){
   $ua->proxy(['http','https'], $self->{'proxy'});
   }
my $req = new HTTP::Request;
$req->method("GET");
$req->uri($self->URLprefix()."/$QuickBaseDBid?$action");
unless ($self->{'ticket'})
	{
	$self->{'ticket'}=$self->getTicket($self->{'username'},$self->{'password'});
	}
$req->header('Cookie' => "TICKET=$self->{'ticket'};");
$req->header('Accept' => 'text/html');
# send request
my $res = $ua->request($req);


# check the outcome
if ($res->is_error) {
	$self->{'error'} = $res->code;
    $self->{'errortext'} =$res->message;
    return "Error: " . $res->code . " " . $res->message;
  }
  return $res->content;
}

sub GetFile($$$$)
{
my($self, $QuickBaseDBid, $filename, $rid, $fid) = @_;
my $error;
my $prefix= $self->URLprefix();
$prefix =~ s/\/db$/\/up/;
my $ua = new LWP::UserAgent;
$ua->agent("QuickBasePerlAPI/1.0");
if ($self->{'proxy'}){
   $ua->proxy(['http','https'], $self->{'proxy'});
   }
my $req = new HTTP::Request;
$req->method("GET");

$req->uri($prefix."/$QuickBaseDBid/g/r".$self->encode32($rid)."/e".$self->encode32($fid)."/");


unless ($self->{'ticket'})
	{
	$self->{'ticket'}=$self->getTicket($self->{'username'},$self->{'password'});
	}
$req->header('Accept' => '*/*');
$req->header('Cookie' => "TICKET=$self->{'ticket'};");

# send request
my $res = $ua->request($req);

# check the outcome
if ($res->is_error) {
	$self->{'error'} = $res->code;
   	$self->{'errortext'} =$res->message;
    return ("Error: " . $res->code . " " . $res->message, $res->headers);
  }
  return ($res->content, $res->headers);
}

sub PostURL($$$$)
{
my $self = shift;
my $QuickBaseDBid = shift;
my $action = shift;
my $content = shift;
my $content_type = shift || 'application/x-www-form-urlencoded';

my $ua = new LWP::UserAgent;
if ($self->{'proxy'}){
   $ua->proxy(['http','https'], $self->{'proxy'});
   }
$ua->agent("QuickBasePerlAPI/1.0");
my $req = new HTTP::Request;
$req->method("POST");
$req->uri($self->URLprefix."/$QuickBaseDBid?$action");
unless ($self->{'ticket'})
	{
	$self->{'ticket'}=$self->getTicket($self->{'username'},$self->{'password'});
	}
$req->header('Cookie' => "TICKET=$self->{'ticket'};");
$req->content_type($content_type);

#This is where we post the info for the new record

$req->content($content);
my $res = $ua->request($req);
if($res->is_error()){
	$self->{'error'} = $res->code;
	$self->{'errortext'} =$res->message;
	return $res;
}
$res->content =~ /<errcode>(.*?)<\/errcode>.*?<errtext>(.*?)<\/errtext>/s ;
$self->{'error'} = $1;
$self->{'errortext'} = $2;
if ($res->content =~ /<errdetail>(.*?)<\/errdetail>/s)
    {
    $self->{'errortext'} = $1;
	}		
return $res;
}

sub PostAPIURL($$$)
{
my($self, $QuickBaseDBid, $action, $content) = @_;
my $ua = new LWP::UserAgent;
$ua->agent("QuickBasePerlAPI/2.0");
if ($self->{'proxy'}){
   $ua->proxy(['http','https'], $self->{'proxy'});
   }
my $req = new HTTP::Request;
$req->method('POST');
if($self->{'realmhost'})
    {
    $req->uri($self->URLprefix()."/$QuickBaseDBid?realmhost=$self->{'realmhost'}");
    }
else
    {
    $req->uri($self->URLprefix()."/$QuickBaseDBid");
    }

$req->content_type('text/xml');
$req->header('QUICKBASE-ACTION' => "$action");

if ($self->{'apptoken'} ne "" && $self->{'credentials'} !~ /<apptoken>/)
   {
      $self->{'credentials'} .= "<apptoken>".$self->{'apptoken'}."</apptoken>";
   }

if($content =~ /^<qdbapi>/)
    {
    $content =~s/^<qdbapi>/<qdbapi>$self->{'credentials'}/;
    }
elsif($content eq "" || !defined($content)) 
    {
    $content ="<qdbapi>$self->{'credentials'}</qdbapi>";
    }
if($content =~ /^<qdbapi>/)
    {
    $content = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>" . $content;
    }
my $res;
if ($self->{'ticket'})
    {
    $req->header('Cookie' => "TICKET=$self->{'ticket'};");
    }
    
$req->content($content);
$res = $ua->request($req);
if($res->is_error()){
        $self->{'error'} = $res->code;
$self->{'errortext'} =$res->message;
        return $res;
        }
if (defined ($res->header('Set-Cookie')) && $res->header('Set-Cookie') =~ /TICKET=(.+?);/)
        {
        $self->{'ticket'} = $1;
        $self->{'credentials'} = "<ticket>$self->{'ticket'}</ticket>";
        }
elsif ($res->content =~ /<ticket>(.+?)<\/ticket>/)
        {
        $self->{'ticket'} = $1;
        $self->{'credentials'} = "<ticket>$self->{'ticket'}</ticket>";
        }

$res->content =~ /<errcode>(.*?)<\/errcode>.*?<errtext>(.*?)<\/errtext>/s;
$self->{'error'} = $1;
$self->{'errortext'} = $2;
if ($res->content =~ /<errdetail>(.*?)<\/errdetail>/s)
    {
    $self->{'errortext'} = $1;
    }
if($self->{'error'} eq '11')
	{
    $self->{'errortext'} .= "\nXML request:\n" . $content;
	}
return $res;
}

sub getoneBaseIDbyName($)
{
my ($self, $dbName)= @_;
return $self->getIDbyName($dbName);
}

sub getIDbyName($)
{
my ($self, $dbName)= @_;
my $content;
$content = "<qdbapi><dbname>".$self->xml_escape($dbName)."</dbname></qdbapi>";
my $res = $self->PostAPIURL ("main", "API_FindDBByName", $content);

if($res->content =~ /<dbid>(.*)<\/dbid>/ ){
	return $1;
	}
else
	{
	return "";
	}
}

sub FindDBByName($)
{
   my ($self, $dbName)= @_;
   $self->getIDbyName($dbName);
}

sub cloneDatabase ($$$)
	{
	my ($self, $QuickBaseID, $Name, $Description)=@_;
	my $content;
	$content = "<qdbapi><newdbname>".$self->xml_escape($Name)."</newdbname><newdbdesc>".$self->xml_escape($Description)."</newdbdesc></qdbapi>";
	my $res = $self->PostAPIURL ($QuickBaseID, "API_CloneDatabase", $content);
	if($res->content =~ /<newdbid>(.*)<\/newdbid>/ ){
		return $1;
		}
	else
		{
		return "";
		}
	}

sub createDatabase ($$)
	{
	my ($self, $Name, $Description)=@_;
	my $content;
	$content = "<qdbapi><dbname>".$self->xml_escape($Name)."</dbname><dbdesc>".$self->xml_escape($Description)."</dbdesc></qdbapi>";
	my $res = $self->PostAPIURL ("main", "API_CreateDatabase", $content);
	if($res->content =~ /<dbid>(.*)<\/dbid>/ ){
    my $dbid  = $1;
	  if($res->content =~ /<appdbid>(.*)<\/appdbid>/ ){
          return ($dbid,$1);
       }
    else
      {    
		     return $1;
		  }
    }   
	else
		{
		return "";
		}
	}	

sub addField ($$$$)
	{
	my ($self, $QuickBaseID, $label, $type, $mode)=@_;
	my $content;
	$content = "<qdbapi><label>".$self->xml_escape($label)."</label><type>$type</type>";
	if ($mode)
	   {
	   $content .= "<mode>virtual</mode></qdbapi>";
	   }
	else
		{
	   $content .= "</qdbapi>";		
		}
	my $res = $self->PostAPIURL ($QuickBaseID, "API_AddField", $content);
	if($res->content =~ /<fid>(.*)<\/fid>/ ){
		return $1;
		}
	else
		{
		return "";
		}	
	}

sub deleteField ($$)
	{
	my ($self, $QuickBaseID, $fid)=@_;
	my $content;
	$content = "<qdbapi><fid>$fid</fid></qdbapi>";
	my $res = $self->PostAPIURL ($QuickBaseID, "API_DeleteField", $content);
	}

sub setFieldProperties ($$%)
	{
	my ($self, $QuickBaseID, $fid, %properties)=@_;
	my $content;
	my $property;
	my $value;
	$content = "<qdbapi><fid>$fid</fid>";
	foreach $property (keys %properties)
			{
			$content .= "<$property>".$self->xml_escape($properties{$property})."</$property>";
			}
   $content .= "</qdbapi>";		
	my $res = $self->PostAPIURL ($QuickBaseID, "API_SetFieldProperties", $content);
	if($res->content =~ /<fid>(.*)<\/fid>/ ){
		return $1;
		}
	else
		{
		return "";
		}	
	}


sub purgeRecords ($$)
	{
	my ($self, $QuickBaseID, $query)=@_;

	my $content;
	if ($query =~ /^\{.*\}$/)
		{
		$content = "<qdbapi><query>$query</query></qdbapi>";
		}
	elsif ($query =~ /^\d+$/)
		{
		$content = "<qdbapi><qid>$query</qid></qdbapi>";
		}
	else 
		{
		$content = "<qdbapi><qname>$query</qname></qdbapi>";
		}
	my $res = $self->PostAPIURL ($QuickBaseID, "API_PurgeRecords", $content);
	if($res->content =~ /<num_records_deleted>(.*)<\/num_records_deleted>/ ){
		return $1;
		}
	else
		{
		return "";
		}	
	}

sub DoQuery ($$$$$)
	{
	my ($self, $QuickBaseID, $query, $clist, $slist, $options)=@_;
	return $self->doQuery ($QuickBaseID, $query, $clist, $slist, $options);
	}	

sub doQuery ($$$$$)
	{
	my ($self, $QuickBaseID, $query, $clist, $slist, $options)=@_;

	my $content;
	my $result;
	my @result;
	my $record={};
	my $field;
	my @labels;
	my $fieldvalue;
	my $counter = 0;
	my $numfields;
	my $i;

	if ($query =~ /^\{.*\}$/)
		{
		$content = "<qdbapi><query>$query</query>";
		}
	elsif ($query =~ /^\d+$/)
		{
		$content = "<qdbapi><qid>$query</qid>";
		}
	else 
		{
		$content = "<qdbapi><qname>$query</qname>";
		}

	$content .= "<fmt>structured</fmt><clist>$clist</clist><slist>$slist</slist><options>$options</options></qdbapi>";
	$result = $self->PostAPIURL ($QuickBaseID, "API_DoQuery", $content)->content;
	@labels = $result =~ /<label>([^<]+)<\/label>/g;
	$numfields = @labels;
	for $i (0 .. $numfields)
		{
		$labels[$i] = $self->xml_unescape($labels[$i]);
		}
	foreach $fieldvalue ( $result =~ /<f id="\d+">(.*?)<\/f>|<f id="\d+"\/>/sg)
		{
		unless ($counter % $numfields)
			{
			if ($counter > 0)
				{
				push (@result, $record);
				}
			$record={};
			}
		$record->{$labels[$counter % $numfields]}=$self->xml_unescape($fieldvalue);
		$counter++;
		}
	if ($counter)
		{	
		push (@result, $record);
		}
	return @result;
	}

sub getCompleteCSV ($)
	{
	my ($self, $QuickBaseID)=@_;
	my $content;
	my $clist="";
	my $fid;
	my @ids;
	my $result;
	$result = $self->PostAPIURL ($QuickBaseID, "API_GetSchema", "<qdbapi></qdbapi>")->content;
	@ids  = $result =~ /<field[^>]*\sid="(\d+)"/sig;
	foreach $fid (@ids){
			$clist .= "$fid.";
			}
	$content .= "<qdbapi><query>{'0'.CT.''}</query><clist>$clist</clist><options>csv</options></qdbapi>";
	return $self->PostAPIURL ($QuickBaseID, "API_GenResultsTable", $content)->content;
	}

sub GetRIDs ($)
{
	my ($self, $QuickBaseID) = @_;
	my $content="<qdbapi></qdbapi>";
	my $fid;
	$self->PostAPIURL($QuickBaseID,"API_GetSchema",$content)->content =~ /<field id="(\d+)".* field_type="recordid" /;
	$fid = $1;
	$content = "<qdbapi><query>{'0'.CT.''}</query><clist>$fid</clist><slist>$fid</slist></qdbapi>";
	my @rids = $self->PostAPIURL($QuickBaseID,"API_DoQuery",$content)->content =~ /<record_id_>([0-9]+)<\/record_id_>/sg;
	return @rids;
}

sub EditRecord ($$%)
{
	my ($self, $QuickBaseID, $rid, %recorddata) = @_;
	my $name;
	my $content = "<qdbapi><rid>$rid</rid>";
	my $tag;

foreach $name (keys(%recorddata))
	{
	$tag=$name;
	$tag =~tr/A-Z/a-z/;
	$tag=~s/[^a-z0-9]/_/g;
	$content .= $self->createFieldXML($tag, $recorddata{$name});
	}
	$content .= "</qdbapi>";
	my $res = $self->PostAPIURL ($QuickBaseID, "API_EditRecord", $content);
	return $res->content;
}

sub EditRecordWithUpdateID ($$$%)
{
	my ($self, $QuickBaseID, $rid, $update_id, %recorddata) = @_;
	my $name;
	my $content = "<qdbapi><rid>$rid</rid>";
	my ($value, $tag);
	$content .= "<update_id>$update_id</update_id>";


foreach $name (keys(%recorddata))
	{
	$value = $recorddata{$name};
	$value = $self->xml_escape($value);
	$tag=$name;
	$tag =~tr/A-Z/a-z/;
	$tag=~s/[^a-z0-9]/_/g;

	$content .= $self->createFieldXML($tag, $recorddata{$name});
	}

	$content .= "</qdbapi>";
	my $res = $self->PostAPIURL ($QuickBaseID, "API_EditRecord", $content);
	return $res->content;
}


sub ImportFromCSV ($$$$)
{
 	my ($self, $QuickBaseID, $CSVData, $clist, $skipfirst) = @_;
	my $content = "<qdbapi><clist>$clist</clist>";

	$content .= "<records_csv><![CDATA[$CSVData]]></records_csv>";
	if($skipfirst)
		{
		$content .= "<skipfirst>1</skipfirst>";
		} 
	$content .= "</qdbapi>";
	my $res = $self->PostAPIURL ($QuickBaseID, "API_ImportFromCSV", $content);
	return $res->content;
}


sub GetNextField ($$$$)
	{
	my ($self, $datapointer, $delim, $offsetpointer, $fieldpointer)=@_;
	my $BEFORE_FIELD=0;
	my $IN_QUOTED_FIELD=1;
	my $IN_UNQUOTED_FIELD=2;
	my $DOUBLE_QUOTE_TEST=3;
	my $c="";
	my $state = $BEFORE_FIELD;
	my $p = $$offsetpointer;
	my $endofdata = length($$datapointer);
	my $false=0;
	my $true=1;


	$$fieldpointer = "";

	while ($true)
		{
		if ($p >= $endofdata)
			{
			# File, line and field are done
			$$offsetpointer = $p;
			return $false;
			}

		$c = substr($$datapointer, $p, 1);

		if($state == $DOUBLE_QUOTE_TEST)
			{
			# These checks are ordered by likelihood */
			if ($c eq $delim)
				{
				# Field is done; delimiter means more to come
				$$offsetpointer = $p + 1;
				return $true;
				}
			elsif ($c eq "\n" || $c eq "\r")
				{
				# Line and field are done
				$$offsetpointer = $p + 1;
				return $false;
				}
			elsif ($c eq '"')
				{
				# It is doubled, so append one quote
				$$fieldpointer .= '"';
				$p++;
				$state = $IN_QUOTED_FIELD;
				}
			else
				{
				# !!! Shouldn't have anything else after an end quote!
				# But do something reasonable to recover: go into unquoted mode
				$$fieldpointer .= $c;
				$p++;
				$state = $IN_UNQUOTED_FIELD;
				}
			}
		elsif($state == $BEFORE_FIELD)
			{
			# These checks are ordered by likelihood */
			if ($c eq $delim)
				{
				# Field is blank; delimiter means more to come
				$$offsetpointer = $p + 1;
				return $true;
				}
			elsif ($c eq '"')
				{
				# Found the beginning of a quoted field
				$p++;
				$state = $IN_QUOTED_FIELD;
				}
			elsif ($c eq "\n" || $c eq "\r")
				{
				# Field is blank and line is done
				$$offsetpointer = $p + 1;
				return $false;
				}
			elsif ($c eq ' ')
				{
				# Ignore leading spaces
				$p++;
				}
			else
				{
				# Found some other character, beginning an unquoted field
				$$fieldpointer.=$c;
				$p++;
				$state = $IN_UNQUOTED_FIELD;
				}
			}
		elsif ($state == $IN_UNQUOTED_FIELD)
			{
			# These checks are ordered by likelihood */
			if ($c eq $delim)
				{
				# Field is done; delimiter means more to come
				$$offsetpointer = $p + 1;
				return $true;
				}
			elsif ($c eq "\n" || $c eq "\r")
				{
				# Line and field are done
				$$offsetpointer = $p + 1;
				return $false;
				}
			else
				{
				# Found some other character, add it to the field
				$$fieldpointer.=$c;
				$p++;
				}
			}
		elsif($state == $IN_QUOTED_FIELD)
			{
			if ($c eq '"')
				{
				$p++;
				$state = $DOUBLE_QUOTE_TEST;
				}
			else
				{
				# Found some other character, add it to the field
				$$fieldpointer.=$c;
				$p++;
				}
			}	
		}
	}

sub GetNextLine ($$$$$$)
	{
	my ($self, $data, $delim, $offsetpointer, $fieldpointer, $line, $lineIsEmptyPtr)=@_;
	my $false=0;
	my $true=1;

	undef(@$line);
	# skip any empty lines
	while ($$offsetpointer < length($$data) && ((substr($$data, $$offsetpointer, 1) eq "\r") || (substr($$data, $$offsetpointer, 1) eq "\n")))
		{
		$$offsetpointer++;
		}	

	if ($$offsetpointer >= length($$data))
		{
		return $false;
		}

	$$lineIsEmptyPtr = $true;
	my $moreToCome;
	do {
		$moreToCome = $self->GetNextField ($data, $delim, $offsetpointer, $fieldpointer);
		push (@$line, $$fieldpointer);
		if ($$fieldpointer)
			{
			$$lineIsEmptyPtr = $false;
			}
		}
	while ($moreToCome);

	return $true;
	}


sub ParseDelimited ($$)
	{
	my ($self, $data, $delim)=@_;
	my @output;
	my @line;
	my $offset =0;

	my $field="";
	my $lineEmpty=1;
	my $maxsize = 0;
	my $numfields=0;
	my $i;

	# Parse lines until the eof is hit
	while ($self->GetNextLine (\$data, $delim, \$offset, \$field, \@line, \$lineEmpty))
		{
		unless($lineEmpty)
			{
			push (@output, [@line]);
			$numfields=@line;
			if ($numfields > $maxsize)
				{
				$maxsize = $numfields;
				}
			}
		}


	# If there are any lines which are shorter than the longest
	# lines, fill them out with "" entries here. This simplifies
	# checking later.
	foreach $i(@output)
		{
		while (@$i < $maxsize)
			{
			push (@$i, "");
			}
		}

	return @output;

	}
sub xml_escape ($) {
    my ($self, $rest) = @_;
	unless(defined($rest)){return "";}
    $rest   =~ s/&/&amp;/g;	
    $rest   =~ s/</&lt;/g;
    $rest   =~ s/>/&gt;/g;
    $rest    =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()# ])/$XMLescapes{$1}/g;
    return $rest;
} 

sub xml_unescape ($) {
    my ($self, $rest) = @_;
	unless(defined($rest)){return "";}
    $rest   =~ s/<br\/>/\n/ig;
    $rest   =~ s/&lt;/</g;
    $rest   =~ s/&gt;/>/g;
    $rest   =~ s/&amp;/&/g;
    $rest   =~ s/&apos;/'/g;
	$rest   =~ s/&quot;/"/g;
	$rest   =~ s/&#([0-9]{2,3});/chr($1)/eg;
	return $rest;
} 

sub encode32 ($){
	my ($self, $number) = @_;
	my $result = "";
	while ($number > 0){
		  my $remainder = $number % 32;
		  $number = ($number - $remainder)/32; 
		  $result = $self->hash32($remainder) . $result;
	}
	return $result;
}

sub hash32 ($){
	my ($self, $number) = @_;
	if($number == 0)  {return 'a';}
    if($number == 1)  {return 'b';}
    if($number == 2)  {return 'c';}
    if($number == 3)  {return 'd';}
    if($number == 4)  {return 'e';}
    if($number == 5)  {return 'f';}
    if($number == 6)  {return 'g';}
    if($number == 7)  {return 'h';}
    if($number == 8)  {return 'i';}
    if($number == 9)  {return 'j';}
    if($number == 10) {return 'k';}
    if($number == 11) {return 'm';}
    if($number == 12) {return 'n';}
    if($number == 13) {return 'p';}
    if($number == 14) {return 'q';}
    if($number == 15) {return 'r';}
    if($number == 16) {return 's';}
    if($number == 17) {return 't';}
    if($number == 18) {return 'u';}
    if($number == 19) {return 'v';}
    if($number == 20) {return 'w';}
    if($number == 21) {return 'x';}
    if($number == 22) {return 'y';}
    if($number == 23) {return 'z';}
    if($number == 24) {return '2';}
    if($number == 25) {return '3';}
    if($number == 26) {return '4';}
    if($number == 27) {return '5';}
    if($number == 28) {return '6';}
    if($number == 29) {return '7';}
    if($number == 30) {return '8';}
    if($number == 31) {return '9';}
}



sub unencode32 ($){
  my ($self, $number) = @_;
  my $result = 0;
  while ($number ne ""){
    my $l = length($number);
    my $firstchar = substr($number, 0, 1);
    $result = ($result * 32) + $self->unhash32($firstchar);
    $number = substr($number, 1, $l-1);
  }
  return $result;
}



sub unhash32 ($) {
  my ($self, $number) = @_;
  if($number eq 'a')  {return 0;}
  if($number eq 'b')  {return 1;}
  if($number eq 'c')  {return 2;}
  if($number eq 'd')  {return 3;}
  if($number eq 'e')  {return 4;}
  if($number eq 'f')  {return 5;}
  if($number eq 'g')  {return 6;}
  if($number eq 'h')  {return 7;}
  if($number eq 'i')  {return 8;}
  if($number eq 'j')  {return 9;}
  if($number eq 'k') {return 10;}
  if($number eq 'm') {return 11;}
  if($number eq 'n') {return 12;}
  if($number eq 'p') {return 13;}
  if($number eq 'q') {return 14;}
  if($number eq 'r') {return 15;}
  if($number eq 's') {return 16;}
  if($number eq 't') {return 17;}
  if($number eq 'u') {return 18;}
  if($number eq 'v') {return 19;}
  if($number eq 'w') {return 20;}
  if($number eq 'x') {return 21;}
  if($number eq 'y') {return 22;}
  if($number eq 'z') {return 23;}
  if($number eq '2') {return 24;}
  if($number eq '3') {return 25;}
  if($number eq '4') {return 26;}
  if($number eq '5') {return 27;}
  if($number eq '6') {return 28;}
  if($number eq '7') {return 29;}
  if($number eq '8') {return 30;}
  if($number eq '9') {return 31;}
}

sub createFieldXML($$)
{
 	my($self, $tag, $value) = @_;
	my $nameattribute;
    if($tag =~ /^[1-9]\d*$/)
    	{
    	$nameattribute = "fid";
    	}
    else
    	{
    	$nameattribute = "name";
    	}
	if(ref($value) eq "ARRAY")
            {
            if($$value[0] =~ /^file/i)
                {
                #This is a file attachment!
                my $filename = "";
                my $buffer = "";	
                my $filecontents = "";
                if($$value[1] =~ /[\\\/]([^\/\\]+)$/)
                    {
                    $filename = $1;
                    }
                else
                    {
                    $filename = $$value[1];
                    }
                unless(open(FORUPLOADTOQUICKBASE, "<$$value[1]"))
                    {
                    $filecontents = encode_base64("Sorry QuickBase could not open the file '$$value[1]' for input, for upload to this field in this record.", "");
                    }									
                binmode FORUPLOADTOQUICKBASE;
                while (read(FORUPLOADTOQUICKBASE, $buffer, 60*57))
                    {
                    $filecontents .= encode_base64($buffer, "");
                    }
                close FORUPLOADTOQUICKBASE;
                return "<field $nameattribute='$tag' filename=\"".$self->xml_escape($filename)."\">".$filecontents."</field>";
                }
            }
	else
            {
            $value = $self->xml_escape($value);
            return "<field $nameattribute='$tag'>$value</field>";
            }
}


1;