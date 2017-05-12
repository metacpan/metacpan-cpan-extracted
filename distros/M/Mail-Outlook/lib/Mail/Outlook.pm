package Mail::Outlook;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.25';

#----------------------------------------------------------------------------

=head1 NAME

Mail::Outlook - mail module to interface with Microsoft (R) Outlook (R).

=head1 SYNOPSIS

  # create the object
  use Mail::Outlook;
  my $outlook = new Mail::Outlook();

  # start with a folder
  my $outlook = new Mail::Outlook('Inbox');

  # use the Win32::OLE::Const definitions
  use Mail::Outlook;
  use Win32::OLE::Const 'Microsoft Outlook';
  my $outlook = new Mail::Outlook(olInbox);

  # get/set the current folder
  my $folder = $outlook->folder();
  my $folder = $outlook->folder('Inbox');

  # get the first/last/next/previous message
  my $message = $folder->first();
     $message = $folder->next();
     $message = $folder->last();
     $message = $folder->previous();

  # read the attributes of the current message
  my $text = $message->From();
     $text = $message->To();
     $text = $message->Cc();
     $text = $message->Bcc();
     $text = $message->Subject();
     $text = $message->Body();
  my @list = $message->Attach();

  # use Outlook to display the current message
  $message->display;

  # create a message for sending
  my $message = $outlook->create();
  $message->To('you@example.com');
  $message->Cc('Them <them@example.com>');
  $message->Bcc('Us <us@example.com>; anybody@example.com');
  $message->Subject('Blah Blah Blah');
  $message->Body('Yadda Yadda Yadda');
  $message->Attach(@lots_of_files);
  $message->Attach(@more_files);    # attachments are appended
  $message->Attach($one_file);      # so multiple calls are allowed
  $message->send;

  # Or use a hash
  my %hash = (
     To      => 'you@example.com',
     Cc      => 'Them <them@example.com>',
     Bcc     => 'Us <us@example.com>, anybody@example.com',
     Subject => 'Blah Blah Blah',
     Body    => 'Yadda Yadda Yadda',
  );

  my $message = $outlook->create(%hash);
  $message->display(%hash);
  $message->send(%hash);

=head1 DESCRIPTION

This module was written to overcome the problem of sending mail messages,
where Microsoft (R) Outlook (R) is the only mail application available.
However, since it's inception the module has expanded to handle a range of
Outlook mail functionality.

Note that when sending messages, the module uses the named owner of the
Outbox MAPI Folder in order to access the correct objects. Thus the From
field of a new message is predetermined, and therefore a read only property.

If using the 'Win32::OLE::Const' constants, only the following are supported:

  olFolderInbox
  olFolderOutbox
  olFolderSentMail
  olFolderDrafts
  olFolderDeletedItems

=head1 ABSTRACT

A mail module to interface with mail message accessible via
Microsoft (R) Outlook (R).

=cut

#----------------------------------------------------------------------------

#############################################################################
#Library Modules                                                            #
#############################################################################

use lib qw(./lib);

use Win32::OLE;
use Win32::OLE::Const 'Microsoft Outlook';

use Mail::Outlook::Folder;
use Mail::Outlook::Message;

#----------------------------------------------------------------------------

#############################################################################
#Interface Functions                                                        #
#############################################################################

=head1 METHODS

=head2 new()

Create a new Outlook mail object. Returns the object on success or undef on
failure. To see the last error use 'Win32::OLE->LastError();'.

=cut

sub new {
    my ($self, $foldername) = @_;

    #open the Outlook program and get a hook into it
    my $outlook;
    eval {
        $outlook = Win32::OLE->GetActiveObject('Outlook.Application')
    };
    if ($@ || !defined($outlook)) {
        $outlook = Win32::OLE->new('Outlook.Application', sub {$_[0]->Quit;})
            or return undef;
    }
    my $namespace = $outlook->GetNameSpace("MAPI")  or return undef;

    # create an attributes hash
    my $atts = {
        'outlook'   => $outlook,
        'namespace' => $namespace,
        'objfolder' => undef,
    };

    # create the object
    bless $atts, $self;

    # create a folder if required
    $atts->{objfolder} = $atts->folder($foldername) if($foldername);

    return $atts;
}

=head2 DESTROY

Free unused Win32::OLE libraries

=cut

sub DESTROY {
    Win32::OLE->FreeUnusedLibraries();
}

=head2 all_folders()

Get the list of all open mail folders in Outlook

=cut

sub all_folders {
    my ($self) = @_;
    my $folders = $self->{namespace}->Folders;
    my @folders;
    push @folders, $folders->Item($_)->Name
        for 1 .. $folders->Count;
    return @folders;
}

=head2 folder()

Gets or sets the current folder object.

=cut

sub folder {
    my ($self,$foldername) = @_;
    return $self->{objfolder}   unless($foldername);
    $self->{objfolder} = Mail::Outlook::Folder->new($self,$foldername);
}

=head2 all_accounts

Return a list of the available accounts. Each element is a hash ref with two
keys: address and account. "address" is the SMPT address, "account" is the Account
object.

=cut

sub all_accounts {
  my $self = shift;
  my $session = $self->{namespace}->Session || return;
  my $accounts = $session->Accounts || return;
  my @smtp_addresses = ();
  for ( my $i=1;$i<=$accounts->{Count};$i++ ) {
    my $item = $accounts->Item($i);
    push( @smtp_addresses, { address => $item->smtpAddress, account => $item } );  
  }
  return @smtp_addresses;  
}

=head2 create(%hash)

Creates a new message. Option hash table can be used. Returns the new message
object or undef on failure.

=cut

sub create {
    my ($self,%hash) = @_;

    my $msg = Mail::Outlook::Message->new($self->{outlook}) or return undef;
    $msg->create(%hash);
    return $msg;
}

1;

__END__

#----------------------------------------------------------------------------

#=head1 FURTHER READING

#If you intend to supply a patch for a bug or new feature, please visit the
#following URL (and associated pages) to ensure you are using the correct
#objects and methods.

#http://msdn.microsoft.com/library/default.asp?url=/library/en-us/off2000/html/olobjApplication.asp

#This article contains some interesting background into creating mail
#messages via Outlook, although it is VB-centric.

#http://www.exchangeadmin.com/Articles/Index.cfm?ArticleID=4657

#=head1 FUTURE ENHANCEMENTS

#A couple of items that I'd like to get working.

#* X-Header support
#* Send without the popups (Outlook Redemption looks possible)

=head1 NOTES

This module is intended to be used on Win32 platforms only, with Microsoft (R)
Outlook (R) installed.

  Microsoft and Outlook are registered trademarks and the copyright 1995-2003
  of Microsoft Corporation.

=head1 SEE ALSO

  Win32::OLE
  Win32::OLE::Const

=head1 BUGS, PATCHES & FIXES

There are some minor items under "Issues" , but there are no known serious bugs 
at the time of this release. 

However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: L<http://rt.cpan.org/Public/Dist/Display.html?Name=Mail-Outlook>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions, <http://www.missbarbell.co.uk>

=head1 COPYRIGHT AND LICENSE

  Copyright E<copy> 2003-2013 Barbie for Miss Barbell Productions.
  
  Copyright E<copy> 2014-2016 Duncan Garland.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
