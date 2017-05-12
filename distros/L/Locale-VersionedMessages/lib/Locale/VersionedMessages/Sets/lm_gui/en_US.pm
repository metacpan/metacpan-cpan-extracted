package #
Locale::VersionedMessages::Sets::lm_gui::en_US;
####################################################
#        *** WARNING WARNING WARNING ***
#
# This file was generated, and is intended to be
# maintained automatically using the Locale::VersionedMessages
# tools.
#
# Any changes to this file may be lost the next
# time these commands are run.
####################################################
# Copyright 2014-2014

use strict;
use warnings;

our $CopyrightBeg = 2014;
our $CopyrightEnd = 2014;

our(%Messages);

%Messages = (
   'button: add locale' => {
      'vers'  => 1,
      'text'  => 'Add New Locale',
   },
   'button: add message' => {
      'vers'  => 1,
      'text'  => 'Add Message',
   },
   'button: browse' => {
      'vers'  => 1,
      'text'  => 'Browse',
   },
   'button: cancel' => {
      'vers'  => 1,
      'text'  => 'Cancel',
   },
   'button: exit' => {
      'vers'  => 1,
      'text'  => 'Exit',
   },
   'button: sel locale' => {
      'vers'  => 1,
      'text'  => 'Display Locale',
   },
   'button: submit' => {
      'vers'  => 1,
      'text'  => 'Submit',
   },
   'create_set: instructions' => {
      'vers'  => 1,
      'text'  => 'To create a message set, we have to specify the default locale.
The locale is of the form LC_CC or simply LC where LC is a 2-character language
code (lowercase) and CC is a 2-character language codes (uppercase).  So, the
following are valid: <b>en</b>, <b>en_US</b>.',
   },
   'create_set: loc err' => {
      'vers'  => 1,
      'text'  => 'A valid locale must be of the form LC_CC or LC.',
   },
   'create_set: locale' => {
      'vers'  => 1,
      'text'  => 'Default Locale',
   },
   'create_set: window title' => {
      'vers'  => 1,
      'text'  => '[COM] :: Create a Locale::VersionedMessages message set',
   },
   'error' => {
      'vers'  => 1,
      'text'  => 'ERROR',
   },
   'manage_set: curr' => {
      'vers'  => 1,
      'text'  => 'Message in Current Locale',
   },
   'manage_set: def' => {
      'vers'  => 1,
      'text'  => 'Message in Default Locale',
   },
   'manage_set: def mess instructions' => {
      'vers'  => 1,
      'text'  => 'The following message is defined in the default locale.

You can edit the text of the message in the default locale, or modify the
description or substitution values.

By default, any modification to the message will result in increasing the
version number of the message in the default locale.  This will have the affect
of making the message out-of-date in all other locales.

If you click on the <B>Leave Version Unmodified</B>, the version will be
left alone EXCEPT if the substitution values is modified.  In this case,
the version will be increased regardless as all messages will need to be
updated.',
   },
   'manage_set: desc' => {
      'vers'  => 1,
      'text'  => 'Message Description',
   },
   'manage_set: dupl loc err' => {
      'vers'  => 1,
      'text'  => 'The specified locale already exists and may not be recreated.',
   },
   'manage_set: edit mess instructions' => {
      'vers'  => 1,
      'text'  => 'The following message is defined in the current locale.

You can edit the text of the message to match the text in the default locale.

By default, whenever you modify the text, the version of the message in the
current locale will be set to the same as the default locale.  If your modification
is not sufficient to make it up-to-date, and further modification will be
necessary, click on the <B>Out-Of-Date</B> box and the message will be marked
as out-of-date.

Messages highlighted in red are currently missing in the current locale.  Those
highlighted in yellow are present, but out-of-date with respect to the default locale.',
   },
   'manage_set: leave version unmodified' => {
      'vers'  => 1,
      'text'  => 'Leave Version Unmodified',
   },
   'manage_set: mark ood' => {
      'vers'  => 1,
      'text'  => 'Mark out-of-date',
   },
   'manage_set: msgid' => {
      'vers'  => 1,
      'text'  => 'Message ID',
   },
   'manage_set: msgid list' => {
      'vers'  => 1,
      'text'  => 'Message set: [SET]',
   },
   'manage_set: new mess def err' => {
      'vers'  => 1,
      'text'  => 'When creating a new message, the message in the default
locale is required.',
   },
   'manage_set: new mess instructions' => {
      'vers'  => 1,
      'text'  => 'To create a new message, you have to enter the following:

1) A unique message ID (different from any message ID in the list to the left).

2) A simple 1-line description of the message.  This can be left blank, but
may be of use to translators in understanding the context of the message.

3) If there are any value substitutions in the message, they can be entered
as a space separated list of value names.  If there are none, leave this blank.

4) The text of the message in the default locale is required.  It can be
multiline.  Leave a blank line between paragraphs.',
   },
   'manage_set: new mess msgid err' => {
      'vers'  => 1,
      'text'  => 'When creating a new message, the message ID must not be
previously used.',
   },
   'manage_set: subst' => {
      'vers'  => 1,
      'text'  => 'Substitution Values',
   },
   'manage_set: window title' => {
      'vers'  => 1,
      'text'  => '[COM] :: Manage a Locale::VersionedMessages message set',
   },
   'select_operation: desc err' => {
      'vers'  => 1,
      'text'  => 'A valid set description file must be a perl module with a path of:
DIR/Locale/Messages/Sets/SET.pm.',
   },
   'select_operation: description' => {
      'vers'  => 1,
      'text'  => 'Message Set Description',
   },
   'select_operation: directory' => {
      'vers'  => 1,
      'text'  => 'Select Directory',
   },
   'select_operation: err' => {
      'vers'  => 1,
      'text'  => 'When specifying the message set, you may specify either the directory
and set name (both required) OR the message set description file, but not both.',
   },
   'select_operation: instructions_1' => {
      'vers'  => 1,
      'text'  => 'A message set named SET lives in a directory (DIR) which contains
a Locale::Message message set hierarchy of module.  The description of a message set
will be in the file:  DIR/Locale/Messages/Sets/SET.pm .  Lexicons will live in
DIR/Locale/Messages/Sets/SET/LOCALE.pm .

To create a new message set, it is necessary to select the directory where
the message set hierarchy will live (the directory must exist, but the hierarchy
underneath it will be created as necessary) and specify the name of the
message set.

You can also select an existing message set to maintain by selecting the
directory and specifying the message set (though in the case of an existing
message set, it may be easier to select it directly using the
<B>Message Set Description</B> box below).

To do this, enter the directory in the <b>Select Directory</b> box and enter
the name of the message set in the <b>Message Set:</b> box.',
   },
   'select_operation: instructions_2' => {
      'vers'  => 1,
      'text'  => 'To select an existing message set to manage, you can select
the message set description file directly in the
<b>Message Set Description:</b> box.',
   },
   'select_operation: set' => {
      'vers'  => 1,
      'text'  => 'Message Set',
   },
   'select_operation: set err' => {
      'vers'  => 1,
      'text'  => 'A valid set name must consist of alphanumeric and underscore
characters only.',
   },
   'select_operation: window title' => {
      'vers'  => 1,
      'text'  => '[COM] :: Locale::VersionedMessages message set tool',
   },
);

1;
