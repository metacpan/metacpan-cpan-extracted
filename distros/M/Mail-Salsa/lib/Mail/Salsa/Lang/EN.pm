#
# Mail/Salsa/Lang/EN.pm
# Last Modification: Thu Apr  7 10:15:46 WEST 2005
#
# Copyright (c) 2005 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Lang::EN;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(&insidefh);
our $VERSION = '0.02';

sub insidefh { return(\*DATA); }

1;

__DATA__
<template name="PERMISSION_DENY">
From: Mailing List Owner <$from>
To: $to
Subject: Permission deny

The email "$to" don't have permission to
post messages to "$list" list!
</template>

<template name="NO_ATTACHMENTS">
From: Mailing List Owner <$from>
To: $to
Subject: Not allowed to send attachment to list

The administrator of list "$list" does not allow to
send attachments of type "$mime_type" to the list.
</template>

<template name="MAX_MESSAGE_SIZE">
From: Mailing List Owner <$from>
To: $to
Subject: The maximum allowed size was exceeded

The last message that you have sent to the
"$list" list exceeds maximum allowed size!
The maximum allowed size is $size Kbytes.
</template>

<template name="DONT_BOUNCE">
From: Mailing List Owner <$from>
To: $to
Subject: Please don't bounce messages!

Please don't bounce messages to "$list" mailing list.

Thank You,

Mailing List Owner
</template>

<template name="MAILSTAMP">
From: Mailing List Owner <$from>
To: $to
Subject: MailingList Stamp

I'm sorry to have to inform you that the message
that you sent could not be delivered.

To post messages to "$list" list,
please use the following "stamp"

$stamp

in any part of the message.

Thank You,

Mailing List Owner
</template>

<template name="SUBSCRIBE">
From: Mailing List Owner <$from>
To: $to
Subject: [Salsa] To subscribe the "$list" list.

To subscribe the "$list" list
please send a email to "$from".
</template>

<template name="EMAIL_EXISTS">
From: Mailing List Owner <$from>
To: $to
Subject: [Salsa] The email already exists.

The following addresses already exists in "$list" list!

$emails
</template>

<template name="EMAIL_ADDED">
From: Mailing List Owner <$from>
To: $to
Subject: [Salsa] The email was added to list

The email "$to" was added to "$list" list!"
</template>

<template name="CONFIRM_SUB">
From: Mailing List Owner <$from>
To: $to
Subject: [Salsa] Confirm the subscription.

Request from: $origin

Please confirm the subscription of "$list".
Reply this mail to add your mail to the list.

$stamp
</template>

<template name="UNSUBSCRIBE">
From: Mailing List Owner <$from>
To: $to
Subject: [Salsa] To unsubscribe the "$list" list.

To usubscribe the "$list" list
please send a email to "$from".
</template>

<template name="EMAILNOTEXIST">
From: Mailing List Owner <$from>
To: $to
Subject: [Salsa] The email not exists.

The following addresses not exists in "$list" list!

$emails
</template>

<template name="EMAIL_REMOVED">
From: Mailing List Owner <$from>
To: $to
Subject: [Salsa] The email was removed from the list.

The email "$to" was removed from the $list list!
</template>

<template name="CONFIRM_UNSUB">
From: Mailing List Owner <$from>
To: $to
Subject: [Salsa] Confirm the unsubscription.

Request from: $origin

Please confirm the unsubscription of "$list" list.
Reply this mail to remove your mail from the list.

$stamp
</template>

<template name="ADMINTICKET">
From: Salsa Master <$from>
To: $to
Subject: [Salsa] Wrong Administrator Ticket File.

The file "ticket.txt" is not valid.
</template>

<template name="UPDATE_ERROR">
From: Salsa Master <$from>
To: $to
Subject: [Salsa] Content Error.

The file "$file" have the following errors:

$errors
</template>

<template name="UPDATED_FILES">
From: Salsa Master <$from>
To: $to
Subject: [Salsa] Files Update.

The following files has been updated:

$files

Thank You,

Salsa Master
</template>

<template name="ATTACH_FILES">
From: Salsa Master <$from>
To: Mailing List Owner <$to>
Subject: [Salsa] Mailing List Files.
MIME-Version: 1.0
Content-Type: MULTIPART/MIXED; BOUNDARY="$boundary"

  This message is in MIME format.  The first part should be readable text,
  while the remaining parts are likely unreadable without MIME-aware tools.
  Send mail to mime@docserver.cac.washington.edu for more info.

--$boundary
Content-Type: TEXT/PLAIN; charset=US-ASCII

Request from: $origin
Mailing List: $list

To manage the mailing list, please modify the file(s) attached
to this mail, attach the "ticket.txt" file and resend them to
this address: "$admin".

To subscribe many people to the lists save the addresses to a
file with "subscribe.txt" name and send them attached to address
"$admin" with the "ticket.txt".

To unsubscribe many people from the lists save the addresses to
a file with "unsubscribe.txt" name and send them attached to
address "$admin" with the "ticket.txt".

You can send both files ("subscribe.txt" and "unsubscribe.txt")
in one mail.

To add a header/footer to the message set the word "header/footer"
to "y" in "configuration.txt" file.

Thank You,

Salsa Master
</template>

<template name="HELP_MESSAGE">
From: Salsa Master <$from>
To: $to
Subject: [Salsa] Help.

To subscribe to the list, send a message to:
   <$name-subscribe@$domain>

To remove your address from the list, send a message to:
   <$name-unsubscribe@$domain>

You can start a subscription for one or more alternate addresses,
for example "salsero@host.domain", just add the addresses to Cc.

To: <$name-subscribe@$domain>
Cc: Salsero <salsero@host.domain>

and send...

To stop the subscription for this address, send a mail:

To: <$name-unsubscribe@$domain>
Cc: Salsero <salsero@host.domain>

In both cases, I'll send a confirmation message to that address. When
you receive it, simply reply to it to complete the subscription or
unsubscription.

Virtually Yours,

Salsa Master
</template>

<template name="LIST_NOT_ACTIVE">
From: Salsa Master <$master>
To: $to
Subject: Mailing list was not yet activated.

The "$list" mailing list was not yet activated.
Contact the list owner "$from" to configure the list.

Thank You,

Salsa Master
</template>

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Lang::EN - Custom messages templates for English language.

=head1 SYNOPSIS

  use Mail::Salsa::Lang::EN;

  my $templates = Mail::Salsa::Lang::EN::insidefh();

=head1 DESCRIPTION

Stub documentation for Mail::Salsa::Lang::EN, created by h2xs. It looks
like the author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Henrique M. Ribeiro Dias, E<lt>hdias@aesbuc.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
