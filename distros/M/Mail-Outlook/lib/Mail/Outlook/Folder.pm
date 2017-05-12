package Mail::Outlook::Folder;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.25';

#----------------------------------------------------------------------------

=head1 NAME

Mail::Outlook::Folder - extension to handle Microsoft (R) Outlook (R) mail folders.

=head1 SYNOPSIS

See Mail::Outlook, as this is not meant to be used as a standalone module.

=head1 DESCRIPTION

Handles the Folder interaction with the Outlook API.

=cut

#----------------------------------------------------------------------------

#############################################################################
#Library Modules                                                            #
#############################################################################

use Win32::OLE;
use Win32::OLE::Const 'Microsoft Outlook';

use Mail::Outlook::Message;

#############################################################################
#Variables
#############################################################################

my %foldernames = (
    'Inbox'         => olFolderInbox,
    'Outbox'        => olFolderOutbox,
    'Sent Items'    => olFolderSentMail,
    'Drafts'        => olFolderDrafts,
    'Deleted Items' => olFolderDeletedItems,
);

#----------------------------------------------------------------------------

#############################################################################
#Interface Functions                                                        #
#############################################################################

=head1 METHODS

=over 4

=item new()

Create a new Outlook mail object. Returns the object on success or undef on
failure. To see the last error use 'Win32::OLE->LastError();'.

=cut

sub new {
    my ($self, $outlook, $foldername) = @_;
    my ($mailbox,$folder,$path);

    # split mailbox and path
    ($foldername,$path) = ($foldername =~ m!(.*?)/(.*)!)
        if ($foldername =~ m!/!);

    # mailbox name
    if($foldernames{$foldername}) {
        eval { $mailbox = $outlook->{namespace}->GetDefaultFolder($foldernames{$foldername}) };
        return undef    if($@);

    # mailbox constant only
    } elsif($foldername =~ /^\d+$/) {
        eval { $mailbox = $outlook->{namespace}->GetDefaultFolder($foldername) };
        return undef    if($@);

    # well if you don't know, neither do i!!!
    } else {
        return undef;
    }

    if($path) {
        # This is a bit of a hack to stop the OLE complaining when the path
        # doesn't exist in the folder tree
        my $hash;
        eval { $hash = $mailbox->Folders(); };
        my %keys = map {$_ => 1} keys %$hash;
        return undef    if($@);

        $folder = $self->_folders($mailbox, $path) || return undef; 

    }

    # create an attributes hash
    my $atts = {
        'outlook'       => $outlook,
        'foldername'    => $foldername,
        'objfolder'     => $folder || $mailbox || undef,
        'items'         => undef,
    };

    # prime the mail items collection
    $atts->{items} = $atts->{objfolder}->Items()    or return undef;

    # create the object
    bless $atts, $self;
    return $atts;
}

# Split the path (eg A/B/C) into segments call call the Folder method for each. 
# Unix style separators (/).
sub _folders {
  my ($self,$mailbox, $path)=@_;
  my @segs = split('/', $path );
  my $f;
  foreach my $s ( @segs ) {
    eval { $f = $f ? $f->Folders($s) : $mailbox->Folders($s);1;}||return undef;
    return undef if($@); 
    return undef unless( defined($f) );    
  }
  return $f;
}

=item DESTROY

Empty sub

=cut

sub DESTROY {}

=item first()

Gets the first message object in the current folder. Returns undef if no messages.

=cut

sub first {
    my $self = shift;
    my $message = $self->{items}->GetFirst();
    return  unless($message);
    Mail::Outlook::Message->new($self->{outlook},$message);
}

=item last()

Gets the last message object in the current folder. Returns undef if no messages.

=cut

sub last {
    my $self = shift;
    my $message = $self->{items}->GetLast();
    return  unless($message);
    Mail::Outlook::Message->new($self->{outlook},$message);
}

=item next()

Gets the next message object in the current folder. Returns undef if no more
messages. Must be called after a first() or last() has been intiated.

=cut

sub next {
    my $self = shift;
    my $message = $self->{items}->GetNext();
    return  unless($message);
    Mail::Outlook::Message->new($self->{outlook},$message);
}

=item previous()

Gets the previous message object in the current folder. Returns undef if no
more messages. Must be called after a first() or last() has been intiated.

=cut

sub previous {
    my $self = shift;
    my $message = $self->{items}->GetPrevious();
    return  unless($message);
    Mail::Outlook::Message->new($self->{outlook},$message);
}

=item move($message)

Move a message into this folder.

=cut

sub move {
    my ($self,$message) = @_;

    $message->{message}->Move($self->{objfolder});
    return 1;
}

=item move_folder($folder)

Move a folder into this folder.

=cut

sub move_folder {
    my ($self,$folder) = @_;

    $folder->{objfolder}->Move($self->{objfolder});
}

=item delete_folder()

Remove this folder.

=cut

sub delete_folder {
    my $self = shift;

    $self->{objfolder}->Delete();
    $self = undef;
}

=item all_folders

List the names of all folders in this folder.

=cut

sub all_folders {
  my $self = shift;
  my $folders = $self->{objfolder}->Folders || [];
  my @folder_names = ();
  my $num_folders = $folders->{Count};
  for( my $i=1; $i <= $num_folders; $i++ ) {
    push( @folder_names, $folders->Item($i)->Name );
  }
  return @folder_names;
  1;
}

=item count_items

Return the number of items in the folder.

=cut

sub count_items {
  my $self = shift;
  my $count = $self->{objfolder}->Items->Count;
}

1;

__END__

#----------------------------------------------------------------------------

=back

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
