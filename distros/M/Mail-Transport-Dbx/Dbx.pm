package Mail::Transport::Dbx;

use 5.00503;
use strict;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
@ISA = qw(Exporter
	DynaLoader);

%EXPORT_TAGS = ( 'all' => [ qw(
	DBX_BADFILE
	DBX_DATA_READ
	DBX_EMAIL_FLAG_ISSEEN
	DBX_FLAG_BODY
	DBX_INDEXCOUNT
	DBX_INDEX_OVERREAD
	DBX_INDEX_READ
	DBX_INDEX_UNDERREAD
	DBX_ITEMCOUNT
	DBX_NEWS_ITEM
	DBX_NOERROR
	DBX_TYPE_EMAIL
	DBX_TYPE_FOLDER
	DBX_TYPE_NEWS
	DBX_TYPE_VOID
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	DBX_BADFILE
	DBX_DATA_READ
	DBX_EMAIL_FLAG_ISSEEN
	DBX_FLAG_BODY
	DBX_INDEXCOUNT
	DBX_INDEX_OVERREAD
	DBX_INDEX_READ
	DBX_INDEX_UNDERREAD
	DBX_ITEMCOUNT
	DBX_NEWS_ITEM
	DBX_NOERROR
	DBX_TYPE_EMAIL
	DBX_TYPE_FOLDER
	DBX_TYPE_NEWS
	DBX_TYPE_VOID
);

$VERSION = '0.07';

my %FOLDERS;
sub Mail::Transport::Dbx::Folder::folder_path {
    my $self = shift;
    my $id = $self->id;
    my $dbx = $self->_dbx;
    
    my $folders = $FOLDERS{ $dbx };
    # get folders data (just first time this function is called)
    if (! $folders) {
	for my $sub ($dbx->subfolders) {
		my $i = $sub->id;
		$folders->{$i}{'name'}      = $sub->name;
		$folders->{$i}{'parent_id'} = $sub->parent_id;
	}
	$FOLDERS{ $dbx } = $folders;
    }
    # get path
    my @path;
    my $i = $id;
    unshift @path, $folders->{$id}{'name'};
    while ($i != $folders->{$i}{'parent_id'}) {
	    $i = $folders->{$i}{'parent_id'};
	    unshift @path, $folders->{$i}{'name'};
    }
    return @path;
}
   
sub Mail::Transport::Dbx::Folder::DESTROY {
    my $self = shift;
    my $dbx = $self->_dbx;
    delete $FOLDERS{ $dbx } if defined $dbx;
    $self->_DESTROY;
}

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Mail::Transport::Dbx::constant not defined" 
        if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

bootstrap Mail::Transport::Dbx $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Transport::Dbx - Parse Outlook Express mailboxes

=head1 SYNOPSIS

    use Mail::Transport::Dbx;

    my $dbx = eval { Mail::Transport::Dbx->new("box.mbx") };
    die $@ if $@;
    
    for my $i (0 .. $dbx->msgcount - 1) {
        my $msg = $dbx->get($i);
        print $msg->subject;
        ...
    }

    # more convenient
    for my $msg ($dbx->emails) {
        print $msg->subject;
        ...
    }

=head1 ABSTRACT

    Read dbx files (mailbox files of Outlook Express)

=head1 DESCRIPTION

Mail::Transport::Dbx gives you platform independent access to Outlook Express' dbx files.  Extract subfolders, messages etc. from those or use it to convert dbx archives into a more portable format (such as standard mbox format).

It relies on LibDBX to do its job. The bad news: LibDBX knows nothing about the endianness of your machine so it does not work on big-endian machines such as Macintoshs or SUNs. The good news: I made the appropriate patches so that it in fact does work even on machines with the 'wrong' byteorder (exception: machines with an even odder byteorder such as Crays are not suppored; exception from the exception: If you buy me a Cray I'll promise to fix it. :-).

You have to understand the structure of .dbx files to make proper use of this module. Outlook Express keeps a couple of those files on your harddisk. For instance:

    Folders.dbx
    folder1.dbx
    comp.lang.perl.misc.dbx

The nasty thing about that is that there are really two different kinds of such files: One that contains the actual messages and one that merely holds references to other .dbx files. F<Folders.dbx> could be considered the toplevel file since it lists all other available .dbx files. As for folder1.dbx and comp.lang.perl.misc.dbx you can't yet know whether they contain messages or subfolders (though comp.lang.perl.misc.dbx probably contains newsgroup messages that are treated as mere emails).

Fortunately this module gives you the information you need. A common approach would be the following:

    1) create a new Mail::Transport::Dbx object from "Folders.dbx"
    
    2) iterate over its items using the get() method
        2.1 if it returns a Mail::Transport::Dbx::Email  
            => a message
        2.2 if it returns a Mail::Transport::Dbx::Folder 
            => a folder
        
    3) if message
        3.1 call whatever method from Mail::Transport::Dbx::Email 
            you need
        
    4) if folder
        4.1 call whatever method from Mail::Transport::Dbx::Folder 
            you need
        OR
        4.2 call dbx() on it to create a new Mail::Transport::Dbx 
            object
            4.2.1 if dbx() returned something defined
                  => rollback to item 2)

The confusing thing is that .dbx files may contain references to other folders that don't really exist! If Outlook Express was used a newsclient this is a common scenario since Folders.dbx lists B<all> newsgroups as separate C<Mail::Transport::Dbx::Folder> objects no matter whether you are subscribed to any of those or not. So in essence calling C<dbx()> on a folder will only return a new object if the corresponding .dbx file exists. 

=head1 METHODS

The following are methods for B<Mail::Transport::Dbx> objects:

=over

=item B<new(filename)>

=item B<new(filehandle-ref)>

Passed either a string being the filename or an already opened and readable filehandle ref, C<new()> will construct a Mail::Transport::Dbx object from that.

This happens regardless of whether you open an ordinary dbx file or the special F<Folders.dbx> file that contains an overview over all available dbx subfolders.

If opening fails for some reason your program will instantly C<die()> so be sure to wrap the constructor into an C<eval()> and check for C<$@>:

    my $dbx = eval { Mail::Transport::Dbx->new( "file.dbx" ) };
    die $@ if $@;

Be careful with using a filehandle, though. On Windows, you might need to use C<binmode()> on your handle or otherwise the stream from your dbx file might get corrupted.

=item B<msgcount>

Returns the number of items stored in the dbx structure. If you previously opened Folders.dbx C<msgcount()> returns the number of subfolders in it. Otherwise it returns the number of messages. C<msgcount() - 1> is the index of the last item.

=item B<emails>

In list context this method returns all emails contained in the file. In boolean (that is, scalar) context it returns a true value if the file contains emails and false if it contains subfolders.

    if ($dbx->emails) {
        print "I contain emails";
    } else {
        print "I contain subfolders";
    }

This is useful for iterations:

    for my $msg ($dbx->emails) {
        ...
    }

=item B<subfolders>

In list context this method returns all subfolders of the current file as C<Mail::Transport::Dbx::Folder> objects. In boolean (scalar) context it returns true of the file contains subfolders and false if it contains emails.

Remember that you still have to call C<dbx()> on these subfolders if you want to do something useful with them:

    for my $sub ($dbx->subfolders) {
        if (my $d = $sub->dbx) {
            # $d now a proper Mail::Transport::Dbx object 
            # with content
        } else {
            print "Subfolder referenced but non-existent";
        }
    }

=item B<get(n)>

Get the item at the n-th position. First item is at position 0. C<get()> is actually a factory method so it either returns a C<Mail::Transport::Dbx::Email> or C<Mail::Transport::Dbx::Folder> object. This depends on the folder you call this method upon:

    my $dbx  = Mail::Transport::Dbx->new( "Folders.dbx" );
    my $item = $dbx->get(0);

C<$item> will now definitely be a C<Mail::Transport::Dbx::Folder> object since F<Folders.dbx> doesn't contain emails but references to subfolders.

You can use the C<is_email()> and C<is_folder()> method to check for its type:

    if ($item->is_email) {
        print $item->subject;
    } else {
        # it's a subfolder
        ...
    }

On an error, this method returns an undefined value. Check C<$dbx-E<gt>errstr> to find out what went wrong.

=item B<errstr>

Whenever an error occurs, C<errstr()> will contain a string giving you further help what went wrong. 

B<WARNING:> Internally it relies on a global variable so all objects will have the same error-string! That means it only makes sense to use it after an operation that potentially raises an error:

    # example 1
    my $dbx = Mail::Transport::Dbx->new("box.dbx")
        or die Mail::Transport::Dbx->errstr;

    # example 2
    my $msg = $dbx->get(5) or print $dbx->errstr;

=item B<error>

Similar to C<errstr()>, only that it will return an error code. See "Exportable constants/Error-Codes" under L<"EXPORT"> for codes that can be returned.

=back

The following are the methods for B<Mail::Transport::Dbx::Email> objects:

=over 4

=item B<as_string>

Returns the whole message (header and body) as one large string.

Note that the string still contains the raw newlines as used by DOSish systems (\015\012). If you want newlines to be represented in the native format of your operating system, use the following:

    my $email = $msg->as_string;
    $email =~ s/\015\012/\n/g;

On Windows this is a no-op so you can ommit this step.

Especially for news-articles this method may return C<undef>. This always happens when the particular articles was only partially downloaded (that is, only header retrieved from the newsserver). There is no way to retrieve this header literally with C<header>. Methods like C<subject> etc. however do work.

=item B<header>

Returns the header-portion of the whole email.

With respect to newlines the same as described under C<as_string()> applies.

Returns C<undef> under the same circumstances as C<as_string>.

=item B<body>

Returns the body-portion of the whole email.

With respect to newlines the same as described under C<as_string()> applies.

Returns C<undef> under the same circumstances as C<as_string>.

=item B<subject>

Returns the subject of the email as a string.

=item B<psubject>

Returns the processed subject of the email as a string. 'Processed' means that additions such as "Re:" etc. are cut off.

=item B<msgid>

Returns the message-id of the message as a string.

=item B<parents_ids>

Returns the message-ids of the parent messages as a string.

=item B<sender_name>

Returns the name of the sender of this email as a string.

=item B<sender_address>

Returns the address of the sender of this email as a string.

=item B<recip_name>

Returns the name of the recipient of this email as a string. This might be your name. ;-)

=item B<recip_address>

Returns the address of the recipient of this email as a string.

=item B<oe_account_name>

Returns the Outlook Express account name this message was retrieved with as a string.

=item B<oe_account_num>

Outlook Express accounts also seem to have a numerical representation. This method will return this as a string (something like "0000001").

=item B<fetched_server>

Returns the name of the POP server that this message was retrieved from as a string.

=item B<rcvd_localtime>

This is the exact duplicate of Perl's builtin C<localtime()> applied to the date this message was received. It returns a string in scalar context and a list with nine elements in list context. See 'perldoc -f localtime' for details.

=item B<rcvd_gmtime>

Same as C<rcvd_localtime()> but returning a date conforming to GMT.

=item B<date_received( [format, [len, [gmtime]]] )>

This method returns the date this message was received by you as a string. The date returned is calculated according to C<localtime()>.

Without additional arguments, the string returned looks something like 

    Sun Apr 14 02:27:57 2002

The optional first argument is a string describing the format of the date line. It is passed unchanged to C<strftime(3)>. Please consult your system's documentation for C<strftime(3)> to see how such a string has to look like. The default string to render the date is "%a %b %e %H:%M:%S %Y".

The optional second argument is the max string length to be returned by C<date_received()>. This parameter is also passed unaltered to C<strftime()>. This method uses 25 as default

The third argument can be set to a true value if you rather want to get a date in GMT. So if you want to get the GMT of the date but want to use the default rendering settings, you will have to provide them yourself:

    print $msg->date_received("%a %b %e %H:%M:%S %Y", 25, 1);

=item B<is_seen>

Returns a true value if this message has already been seen. False otherwise.

=item B<is_email>

Always returns true for this kind of object.

=item B<is_folder>

Always returns false for this kind of object.

=back

The following methods exist for B<Mail::Transport::Dbx::Folder> objects:

=over 4

=item B<dbx>

This is a convenience method. It creates a C<Mail::Transport::Dbx> object from the folder object. If the folder is only mentioned but not physically existing on your hard-drive (either because you deleted the .dbx file or it was actually never there which especially happens for newsgroup files) C<dbx> returns an undefined value.

Please read L<"DESCRIPTION"> again to learn why C<dbx()> can return an undefined value.

=item B<num>

The index number of this folder. This is the number you passed to C<$dbx-E<gt>get()> to retrieve this folder.

=item B<type>

According to F<libdbx.h> this returns one of C<DBX_TYPE_FOLDER> or C<DBX_TYPE_EMAIL>. Use it to check whether the folder contains emails or other folders.

=item B<name>

The name of the folder.

=item B<file>

The filename of the folder. Use this, to create a new C<Mail::Transport::Dbx> object:

    # $folder is a Mail::Transport::Dbx::Folder object
    my $new_dbx = Mail::Transport::Dbx->new( $folder->file );

Consider using the C<dbx()> method instead.

This method returns an undefined value if there is no .dbx file belonging to this folder.

=item B<id>

Numerical id of the folder. Not sure what this is useful for.

=item B<parent_id>

Numerical id of the parent's folder.

=item B<folder_path>

Returns the full folder name of this folder as a list of path elements. It's then in your responsibility to join them together by using a delimiter that doesn't show up in any of the elements. ;-)

    print join("/", $_->folder_path), "\n" for $dbx->subfolders;

    # could for instance produce a long list, such as:
    Outlook Express/news.rwth-aachen.de/de.comp.software.announce
    Outlook Express/news.rwth-aachen.de/de.comp.software.misc
    ...
    Outlook Express/Lokale Ordner/test/test1
    Outlook Express/Lokale Ordner/test
    Outlook Express/Lokale Ordner/Entwürfe
    Outlook Express/Lokale Ordner/Gelöschte Objekte
    Outlook Express/Lokale Ordner/Gesendete Objekte
    Outlook Express/Lokale Ordner/Postausgang
    Outlook Express/Lokale Ordner/Posteingang
    Outlook Express/Lokale Ordner
    Outlook Express/Outlook Express

Note that a slash (as any other character) might not be a safe choice as it could show up in a folder name.

=back

=head1 EXPORT

None by default.

=head2 Exportable constants

If you intend to use any of the following constants, you have to import them when C<use()>ing the module. You can import them all in one go thusly:

    use Mail::Transport::Dbx qw(:all);

Or you import only those you need:

    use Mail::Transport::Dbx qw(DBX_TYPE_EMAIL DBX_TYPE_FOLDER);

=over 4 

=item B<Error-Codes>

=over 8

=item * DBX_NOERROR

No error occured.

=item * DBX_BADFILE

Dbx file operation failed (open or close)

=item * DBX_DATA_READ

Reading of data from dbx file failed

=item * DBX_INDEXCOUNT

Index out of range

=item * DBX_INDEX_OVERREAD

Request was made for index reference greater than exists

=item * DBX_INDEX_UNDERREAD

Number of indexes read from dbx file is less than expected

=item * DBX_INDEX_READ

Reading of Index Pointer from dbx file failed

=item * DBX_ITEMCOUNT

Reading of Item Count from dbx file failed

=item * DBX_NEWS_ITEM

Item is a news item not an email

=back

=back

=over 4

=item B<Dbx types>

One of these is returned by C<$folder-E<gt>type> so you can check whether the folder contains emails or subfolders. B<Note that only DBX_TYPE_EMAIL and DBX_TYPE_FOLDER are ever returned so even newsgroup postings are of the type DBX_TYPE_EMAIL>.

=over 8

=item * DBX_TYPE_EMAIL

=item * DBX_TYPE_FOLDER

=item * DBX_TYPE_NEWS

Don't use this one!

=item * DBX_TYPE_VOID

I have no idea what this is for.

=back

=back

=over 4

=item B<Miscellaneous constants>

=over 8

=item * DBX_EMAIL_FLAG_ISSEEN

=item * DBX_FLAG_BODY

=back

=back

=head1 CAVEATS

You can't retrieve the internal state of the objects using C<Data::Dumper> or so since C<Mail::Transport::Dbx> uses a blessed scalar to hold a reference to the respective C structures. That means you have to use the provided methods for each object. Call that strong encapsultion if you need an euphemism for that.

There are currently no plans to implement write access to .dbx files. I leave that up to the authors of libdbx.

=head1 KNOWN BUGS

Other than that I don't know yet of any. This, of course, has never actually been a strong indication for the absence of bugs.

=head1 SEE ALSO

http://sourceforge.net/projects/ol2mbox hosts the libdbx package. It contains the library backing this module along with a description of the file format for .dbx files.

=head1 AUTHOR

Tassilo von Parseval, E<lt>tassilo.von.parseval@rwth-aachen.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by Tassilo von Parseval

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
