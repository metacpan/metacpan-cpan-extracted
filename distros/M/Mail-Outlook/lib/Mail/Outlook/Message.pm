package Mail::Outlook::Message;

use warnings;
use strict;

use vars qw($VERSION $AUTOLOAD);
$VERSION = '0.25';

#----------------------------------------------------------------------------

=head1 NAME

Mail::Outlook::Message - extension to handle Microsoft (R) Outlook (R) mail messages.

=head1 SYNOPSIS

See Mail::Outlook, as this is not meant to be used as a standalone module.

=head1 DESCRIPTION

Handles the Message interaction with the Outlook API.

=cut

#----------------------------------------------------------------------------

#############################################################################
#Library Modules                                                            #
#############################################################################

use File::Basename;
use Win32::OLE;
use Win32::OLE::Const 'Microsoft Outlook';

#############################################################################
#Variables
#############################################################################

my @autosubs = qw(To Cc Bcc Subject Body SenderName);
my %autosubs = map {$_ => 1} @autosubs;

#----------------------------------------------------------------------------

#############################################################################
#Interface Functions                                                        #
#############################################################################

=head1 METHODS

=over 4

=item new()

Create a new Outlook mail object. Returns the object on success or undef on
failure. To see the last error use 'Win32::OLE->LastError();'.

Note that when displaying or sending a message, you MUST have completed the
following fields:

  To
  Subject
  Body

While the RFCs may let you send blank messages, it seems a rather pointless
idea to me, and probably not what you intended. If you want to ignore this
restriction, feel free to edit your copy of the source code and comment out
or edit the appropriate line in _make_message().

=cut

sub new {
    my ($self, $outlook, $message) = @_;

    # create an attributes hash
    my $atts = {
        'outlook'   => $outlook,
        'message'   => $message || undef,
        'readonly'  => 1,
    };

    # create the object
    bless $atts, $self;
    return $atts;
}

=item DESTROY

Empty sub

=cut

sub DESTROY {}

=item create(%hash)

Creates a new message. Option hash table can be used.

=cut

sub create {
    my ($self,%hash) = @_;

    # Create a new message object
    $self->{message} = $self->{outlook}->CreateItem(olMailItem)
        or return undef;
    $self->{readonly} = 0;

    # pre-populate the fields
    foreach my $field (@autosubs) { $self->{$field} = $hash{$field} || ''; }

    return $self->{message};
}

=item display()

Creates a pre-populated New Message via Outlook. Returns 1 on success, 0 on failure.

=cut

sub display {
    my $self = shift;

    return 0    unless($self->_make_message(@_));

    # Display the email
    $self->{message}->Display();

    return 1;
}

=item send()

Sends the message. Returns 1 on success, 0 on failure.

=cut

sub send {
    my $self = shift;

    return 0    unless($self->_make_message(@_));
    
    eval {
    
        $self->{message}->{SendUsingAccount} = $self->{use_account} if $self->{use_account};
        
        # Send the email
        $self->{message}->Send();
    };

    # check whether user cancelled send or it failed
    return 2    if($@ =~ /Operation aborted/);
    return 0    if($@);

    return 1;
}

=item save()

Excerpt from the MSDN:

"Saves the Outlook  to the current folder or, if this is a new item, to the
Outlook default folder for the item type."

In other words, if the message is a new one, it will be saved to the default
folder (B<Drafts>) in Outlook.

Returns 1 on success, 0 on failure.

=cut

sub save {
    my $self = shift;

    return 0 unless ( $self->_make_message(@_) );

    eval {
        $self->{message}->Save();
    };

    my $err = Win32::OLE::LastError();

    if($@ or $err) {
        warn "error $@\n" if ( defined($@) );
        warn Win32::OLE::LastError() . "\n" if ($err);
        return 0;
    }

    return 1;
}

=item delete_message()

Remove this message.

=cut

sub delete_message {
    my $self = shift;

    $self->{message}->Delete();
    $self = undef;
}

=item use_account

This can be used to specify the account from which this email
will be sent.

$m->use_account( $account_object );

where $account_object has be retrieved using the all_accounts method of the Outlook 
object.

=cut

sub use_account {
  my ( $self, $account_obj ) = @_;
  $self->{use_account} = $account_obj;
  return 1;
}

# -------------------------------------
# The Get & Set Methods Interface Subs

=back

=head2 Accessor Methods

=over 4

=item Basic Accessor Methods

The following basic accessor methods are available:

  SenderName
  To
  Cc
  Bcc
  Subject
  Body

All functions can be called to return the current value of the associated
object variable, or be called with a parameter to set a new value for the
object variable if you are creating a message.

=cut

sub AUTOLOAD {
    no strict;
    my $name = $AUTOLOAD;
    $name =~ s/^.*:://;
    die "Unknown sub $AUTOLOAD\n"   unless($autosubs{$name});

    *$name = sub {
        my ($self,$value) = @_;

        if($self->{readonly}) {     # existing message
            local $^W = 0;
            return $self->{message}->$name();
        }

        @_==2 ? $self->{$name} = $value : $self->{$name};
    };
    goto &$name;
}

=item From()

Returns the current settings for the read only From field. Note that this is
not an email address when used in connection with a new message. Returns a
list containing the Name and Address of the user.

=cut

sub From {
    my $self = shift;

    if($self->{readonly}) { # existing message
        my $name;
        eval {$name = $self->{message}->SenderName()};
        return $name;   # note this will be undef if we have been declined access

    } else {                # new message
        my $user = $self->{message}->UserProperties;
        return  $user->{'Session'}->{'CurrentUser'}->{'Name'},
                $user->{'Session'}->{'CurrentUser'}->{'Address'};
    }
}

=item Sent()

Returns the date/time the current message was sent. Note that this will
return undef if the message has not been sent!

=cut

sub Sent {
    my $self = shift;

    return  unless($self->{readonly});  # existing messages only!

    my $dt;
    eval {$dt = $self->{message}->SentOn()->Date() . ' ' . $self->{message}->SentOn()->Time()};
    return $dt;   # note this will be undef if we have been declined access
}

=item Received()

Returns the date/time the current message was received. Note that this will
return undef if the message has not been sent!

=cut

sub Received {
    my $self = shift;

    return  unless($self->{readonly});  # existing messages only!

    my $dt;
    eval {$dt = $self->{message}->ReceivedTime()->Date() . ' ' . $self->{message}->ReceivedTime()->Time()};
    return $dt;   # note this will be undef if we have been declined access
}

=item XHeader($xheader,$value)

Adds a header in the style of 'X-Header' to the headers of the message.
Returns undef if header cannot be added.

NOTE: Currently unimplemented, due to unreliable treatment by Exchange server.

=cut

sub XHeader {
    return undef;

#   my ($self,$xheader,$value) = @_;
#   return undef    unless($xheader =~ /^X-(.*)/);

#   my $header = $1;

    # "That GUID (funky number between the curly braces) is the correct one
    # for generating X-Headers." - Thomas J. Zamberlan on a Yahoo tech group

#   my $user = $self->{msg}->UserProperties;
#   my $intXHeader = $self->{outlook}->GetIDsFromNames(
#           $self->{namespace},
#           "{00020386-0000-0000-C000-000000000046}",
#           $xheader, 1);

#   $self->{outlook}->HrSetOneProp(
#           $self->{namespace},
#           $intXHeader,
#           $value,
#           1);
#   $self->{XHeaders}->{$xheader} = $value;
}

=item Attach(@attachments)

Add attachments when creating a message. Returns the attachments of the message
if no arguments are passed to the method.

=cut

sub Attach {
    my $self = shift;

    if($self->{readonly}) {     # existing message
        local $^W = 0;
        if($self->_ole_exists('Attachments')) {
            $self->{attachment} = $self->{message}->Attachments;
            return $self->{attachment};
        }
        return undef;
    }

    if(@_) {
        push @{$self->{Attach}}, {file => $_, name => basename($_), attached => 0}  for(@_);
    }


    return map {$_->{file}} @{$self->{Attach}};
}

# -------------------------------------
# Internal Subs

sub _ole_exists {
    my ($self,$name) = @_;
    local $^W = 0;
    my $stat = eval { my $value = $self->{message}->{$name} };
    ($stat || $@) ? 0 : 1;
}

sub _make_message {
    my ($self,%hash) = @_;

    # pre-populate the fields, if hash
    foreach my $field (@autosubs) {
        $self->{$field} = $hash{$field} if($hash{$field});
    }

    # we need the basic message fields
    return 0    unless($self->{To} && $self->{Subject} && $self->{Body});

    # Build the message
    $self->{message}->{To}      = $self->{To};
    $self->{message}->{Cc}      = $self->{Cc}   if($self->{Cc});
    $self->{message}->{Bcc}     = $self->{Bcc}  if($self->{Bcc});
    $self->{message}->{Subject} = $self->{Subject};
    $self->{message}->{Body}    = $self->{Body};

    if ($self->{Attach}) {
        $self->{attachment} = $self->{message}->Attachments;
        for my $attach (@{$self->{Attach}}) {
            next    if($attach->{attached});
            $self->{attachment}->Add($attach->{file},olByValue,10000,$attach->{name});
            $attach->{attached} = 1;
        }
    }

    return 1;
}

1;

__END__

#----------------------------------------------------------------------------

=back

=head1 CAVEATS

Due to some recent security patches within Outlook, Microsoft have disabled
the automatic access to the Outlook OLE. As some spam and trojan scripts, as
well as the usual executables, have been using the application for malicious
uses, Microsoft have stepped in an attempt to block this. If these security
patches have been applied, when the module accesses Outlook via the OLE, you
will probably see one of the following messages, or something like them.

=over 4

=item Security Message 1

When the module attempts to retrieve the From address, a warning message box
may appear. The text will be along the lines of:


  A program is trying to access e-mail addresses you have
  stored in Outlook. Do you want to allow this?

  If this is unexpected, it may be a virus and you should
  choose "No".

  [ ] Allow access for [ --------- V]

  [Yes]  [No]  [Help]


The message informs you that an unknown application is accessing Outlook and
asks whether you wish to allow this. Click 'Yes' to allow the script to access
the Outlook Address Book. Or you can set a time period, during which the script
can access the Outlook OLE.

=item Security Message 2

On sending the message, you may also activate another warning message box.
The text will be along the lines of:


  A program is trying to automatically send e-mail on
  your behalf.
  Do you want to allow this?

  If this is unexpected, it may be a virus and you should
  choose "No".

  [Yes]  [No]  [Help]


Click 'Yes' to allow the script to automatically send the message via Outlook.

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

  Copyright 2003-2013 E<copy> Barbie for Miss Barbell Productions.

  Copyright E<copy> 2014-2016 Duncan Garland.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
