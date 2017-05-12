# $Id: GroupAdmin.pm,v 1.2 2003/01/16 19:41:31 lstein Exp $

package HTTPD::GroupAdmin;
use HTTPD::AdminBase ();
use strict;
use vars qw($VERSION @ISA $DLM);
@ISA = qw(HTTPD::AdminBase);
$DLM = " ";

$VERSION = 1.50;


sub delete {
    my($self,$username,$group) = @_;
    $group = $self->{NAME} unless defined $group;
    return unless $self->{'_HASH'}->{$group};
    $self->{'_HASH'}->{$group} =~ s/(^|$DLM)$username($DLM|$)/$1$2/;
}

sub list {
    my($self, $group) = @_;
    return keys %{$self->{'_HASH'}} unless $group;
    return unless $self->{'_HASH'}{$group};
    split /\s+/, $self->{'_HASH'}{$group};
}

sub create {
    my($self,$group) = @_;
    return unless $group;
    return (0, "group '$group' exists") if $self->exists($group);
    $self->{'_HASH'}{$group} = "";
    1;
}

sub exists {
    my($self, $name, $user) = @_;
    return 0 unless defined $self->{'_HASH'}{$name};
    return $self->{'_HASH'}{$name} unless $user;
    return grep { $_ eq $user } $self->list($name);
}

sub db {
    my($self, $file) = @_;
    my $old = $self->{'DB'};
    return $old unless $file;
    if($self->{'_HASH'}) {
	$self->DESTROY;
    }

    $self->{'DB'} = $file;

    #return unless $self->{NAME};	
    $self->lock || Carp::croak();
    $self->_tie('_HASH', $self->{DB});
    $old;
}

sub user {
    my($self) = shift;
    $self->load('HTTPD::UserAdmin');
    my %attr = %{$self};
    delete $attr{DB}; #just incase, everything else should be OK
    return new HTTPD::UserAdmin (%attr, @_);
}

sub name { shift->_elem('NAME', @_) }

#These should work fine with the _generic classes
my %Support = (apache =>   [qw(Text SQL)],
	       ncsa   =>   [qw(DBM Text)],
	       netscape => [qw(DBM)]
	       );

HTTPD::GroupAdmin->support(%Support);

1;

__END__

=head1 NAME 

HTTPD::GroupAdmin - Management of HTTP server group databases

=head1 SYNOPSIS

    use HTTPD::GroupAdmin ();

=head1 DESCRIPTION

This software is meant to provide a generic interface that
hides the inconsistencies across HTTP server implementations 
of user and group databases.

=head1 METHODS

=over 4

=item new ()

Here's where we find out what's different about your server.

Some examples:


    @DBM = (DBType => 'DBM',
	    DB     => '.htgroup',
	    Server => 'apache');

    $group = new HTTPD::GroupAdmin @DBM;


This creates an object whose database is a DBM file named '.htgroup',
in a format that the Apache server understands.


    @Text = (DBType => 'Text',
	     DB     => '.htgroup',
	     Server => 'ncsa');

    $group = new HTTPD::GroupAdmin @Text;


This creates an object whose database is a plain text file named
'.htgroup', in a format that the NCSA server understands.

Full list of constructor attributes:

Note: Attribute names are case-insensitive

B<Name>    - Group name

B<DBType>  - The type of database, one of 'DBM', 'Text', or 'SQL' (Default is 'DBM')

B<DB>      - The database name (Default is '.htpasswd' for DBM & Text databases)

B<Server>  - HTTP server name (Default is the generic class, that works with NCSA, Apache and possibly others)

Note: run 'perl t/support.t matrix' to see what support is currently availible

B<Path>    - Relative DB files are resolved to this value  (Default is '.')

B<Locking> - Boolean, Lock Text and DBM files (Default is true)

B<Debug>   - Boolean, Turn on debug mode

Specific to DBM files:

B<DBMF>    - The DBM file implementation to use (Default is 'NDBM')

B<Flags>   - The read, write and create flags.  
There are four modes:
B<rwc> - the default, open for reading, writing and creating.
B<rw> - open for reading and writing.
B<r> - open for reading only.
B<w> - open for writing only.

B<Mode>    - The file creation mode, defaults to '0644'

Specific to DBI:
We talk to an SQL server via Tim Bunce's DBI interface. For more info see:
http://www.hermetica.com/technologia/DBI/

B<Host>      - Server hostname

B<Port>      - Server port

B<User>      - Database login name	    

B<Auth>      - Database login password

B<Driver>    - Driver for DBI  (Default is 'mSQL')            

B<GroupTable> - Table with field names below

B<NameField> - Field for the name  (Default is 'user')

B<GroupField> - Field for the group  (Default is 'group')

From here on out, things should look the same for everyone.


=item add($username[,$groupname])

Add user $username to group $groupname, or whatever the 'Name' attribute is set to.

Fails if $username exists in the database

    if($group->add('dougm', 'www-group')) {
	print "Welcome!\n";
    }

=item delete($username[,$groupname])

Delete user $username from group $groupname, or whatever the 'Name' attribute is set to.

    if($group->delete('dougm')) {
	print "He's gone from the group\n";
    }

=item exists($groupname, [$username])

True if $groupname is found in the database

    if($group->exists('web-heads')) {
	die "oh no!";
    }
    if($group->exists($groupname, $username) {
	#$username is a member of $groupname
    }

=item list([$groupname])

Returns a list of group names, or users in a group if '$name' is present.

@groups = $group->list;

@users = $group->list('web-heads');

=item user()

Short cut for creating an HTTPD::UserAdmin object.
All applicable attributes are inherited, but can be 
overridden.

    $user = $group->user();

(See HTTPD::UserAdmin)

=item convert(@Attributes)

Convert a database. 

    #not yet

=item remove($groupname)

Remove group $groupname from the database

=item name($groupname)

Change the value of 'Name' attribute.

    $group->name('bew-ediw-dlrow');

=item debug($boolean)

Turn debugging on or off

=item lock([$timeout])
=item unlock()

These methods give you control of the locking mechanism.

    $group = new HTTPD::GroupAdmin (Locking => 0); #turn off auto-locking
    $group->lock; #lock the object's database
    $group->add($username,$passwd); #write while database is locked
    $group->unlock; release the lock

=item db($dbname);

Select a different database.

    $olddb = $group->db($newdb);
    print "Now we're reading and writing '$newdb', done with '$olddb'n\";

=item flags([$flags])

Get or set read, write, create flags.

=item commit

Commit changes to disk (for Text files).

=back

=head1 SEE ALSO

HTTPD::UserAdmin(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

Copyright (c) 1996, 1997 Doug MacEachern 

This library is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
