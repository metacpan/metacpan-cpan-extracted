package GSM::Gnokii;

require 5.008004;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( all => [ qw( ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{all} } );
our @EXPORT      = qw( );
our $VERSION     = "0.09";

bootstrap GSM::Gnokii $VERSION;

sub version
{
    return $VERSION;
    } # version

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto	or  return;
    @_ > 0 &&   ref $_[0] ne "HASH"	and return;
    my $attr  = shift || {};

    my $gsm = bless {
# TODO:
#	device			=> "00:11:22:33:44:55",
#	model			=> "3109",
#
#	connected		=> "bluetooth",
#	initlength		=> 0,
#	use_locking		=> "no",
#	serial_baudrate		=> 19200,
#	smsc_timeout		=> 10,
#	allow_breakage		=> 0,
#	bindir			=> "/usr/sbin/",
#	TELEPHONE		=> "0612345678",
#	debug			=> "off",
#	rlpdebug		=> "off",
#	xdebug			=> "off",
	gsm_gnokii_version	=> $VERSION,
	verbose			=> $attr->{verbose} || 0,
	}, $class;
    $gsm->_Initialize ();
    $gsm;
    } # new

sub connect
{
    my $self = shift;

    $self->{connected} = $self->_Connect ();
    $self->{verbose} and
	warn ("# GSM::Gnokii-$VERSION - libgnokii-$self->{libgnokii_version}\n");
    $self;
    } # connect

sub DESTROY
{
    my $self = shift;

    $self->disconnect ();
    } # DESTROY

1;
__END__

=head1 NAME

GSM::Gnokii - Perl extension libgnokii

=head1 SYNOPSIS

  use GSM::Gnokii;
  
  $gsm = GSM::Gnokii->new ();
  $gsm->connect ();

  my $date_time    = $gsm->GetDateTime ();
  my $memory_state = $gsm->GetMemoryStatus ();
  my $address_book = $gsm->GetPhoneBook ("ME", 1, 0);

=head1 DESCRIPTION

GSM::Gnokii is a driver module to interface Perl with libgnokii.

 At the moment there is no active development, as the author is not able
 to connect the old phone to the new laptop anymore. 
 This module has been requested to transfer maint to the libgnokii
 development team.

=head1 MEMORYTYPES

The supported memory types are the ones that gnokii supports on the
different phone models, notably:

  ME  Internal memory of the mobile equipment
  SM  SIM card memory
  FD  Fixed dial numbers
  ON  Own numbers
  EN  Emergency numbers
  DC  Dialed numbers
  RC  Received calls
  MC  Missed calls
  LD  Last dialed numbers

For SMS, these are likely to be valid:

  IN  SMS Inbox
  OU  SMS Outbox, sent items
  OUS SMS Outbox, items to be sent
  AR  SMS Archive
  DR  SMS Drafts
  TE  SMS Templates
  F1  SMS Folder 1 (..20)

=head1 PARAMETERS AND RETURN VALUES

Most data used in below examples is made up and does not necessarily
reflect existing values. Values like "..." are indicating "some sort
of data, as my phone did not (yet) yield anything sensible to show.

When ranges are requested, if C<end> is C<0> or beyond the maximum
allowed location index, it is set to the known maximum, like gnokii
accepts "end" as range end. If a requested range includes empty slots
(like selecting all speed dials where location 4 is not set), the
empty slot returns C<undef>.

For methods that return a status C<$err>, the return code in C<$err> is

=over 4

=item undef

When undefined, you passed conflicting or illegal options. I this case,
it is very likely that C<< $gsm->{ERROR} >> contains an explanation.

=item C<0>

All is well: operation completed successfully.

=item I<#>

Any other value is either the return code from the call was performed,
in which case the value of C<< $gsm->{ERROR} >> should have been set to tell
the cause of failure, or it is set to a sensible return code, like the
new location of the item that was added. In that case, C<< $gsm->{ERROR} >>
will contain something like C<"no error / no data">.

=back

=head1 METHODS

=head2 new ({ attributes })

Returns a new instance of C<GSM::Gnokii>. The attributes are optional.
If attributes are passed, it should be in an anonymous hash. Unknown
attributes are silently ignored.

=over 4

=item verbose

  verbose          => 1,

Will show on STDERR the entry point of functions called

=back

=head2 connect

Connect to the phone.

=head2 disconnect

Disconnects the phone.

=head2 PrintError (err)

Prints the string representation of the C<err> value to the current
STDERR handle.

=head2 GetPhonebook (type, start, end)

Returns a reference to an array of PhoneBook entries. Each entry has
been filled with as much as data as available from the entry in the
phone.

The C<type> argument reflects the memory type. See L</MEMORYTYPES>.
The C<start> argument is the first entry to retrieve. Counting starts
at 1, not 0. The C<end> argument may be C<0>, meaning "to the end".

An addressbook entry looks somewhat like:

  memorytype       => "ME",
  location         => 38,
  number           => "+31612345678",
  name             => "John Doe",
  caller_group     => "Friends",
  person           => {
    formal_name      => "Sr. J. Doe",
    formal_suffix    => "Zzz",
    given_name       => "John",
    family_name      => "Doe",
    additional_names => "Aldrick",
    },
  address          => {
    postal           => "P.O. Box 123",
    extended_address => "Whereever",
    street           => "Memory Lane 123",
    city             => "Duckstad",
    state_province   => "N/A",
    zipcode          => "1234AA",
    country          => "Verwegistan",
    },
  birthday         => "1961-12-31",
  company          => "Hackers Inc.",
  date             => "1970-01-01",
  ext_group        => 21,
  e_mail           => 'john.doe@some.where.com',
  nickname         => "johnny boy",
  note             => "This entry reflects imaginary data",
  postal_address   => "Camper 23",
  tel_none         => "+31201230000",
  tel_common       => "+31201230001",
  tel_home         => "+31612340002",
  tel_cell         => "+31612340003",
  tel_fax          => "+31201230004",
  tel_work         => "+31201230006",
  tel_general      => "+31201230010",
  url              => "http://www.some.where.com",

=head2 WritePhonebookEntry ({ ... })

Write a phonebook entry. The structure of the hash is as described
above in C<GetPhonebook>.

The attributes C<memorytype> and C<number> are required, all other
fields are optional.

If no C<location> is given, the location used will be the first after
the last used location. If C<location> is C<0>, it will use the first
free location.

C<caller_group> is numeric and should be any of:
    0: Family
    1: VIPs
    2: Friends
    3: Work
    4: Others
    5: None

Some fields are either ignored by this module, because they cause the
write to fail (e.g. C<tel_common>, C<tel_general>, and C<tel_none>),
or because the gnokii library does not write them (mainly the C<address>
and C<person> data seems to get lost).

On success, C<WritePhonbookEntry> returns the location this entry was
written to. On failure it returns C<undef>.

=head2 GetSpeedDial (number)

Returns a reference to a hash with the information needed to get to
the number used:

  number           =>  2,
  location         => 23,
  memory           => "ME",

To get the address book entry to the speed dial, use

  my $ab = $gsm->GetPhonebook ("ME", 23, 23);

=head2 SetSpeedDial (self, memtype, location, number)

Set the speed dial specified by the arguments. C<memtype> should be
either C<ME> or C<SM>, C<number> is the key number, usually allowed
are keys C<2> through C<9>, C<location> is the location in the phonebook
of memory type C<memorytype>. See L<GetPhonebook>.

=head2 GetDateTime

Returns a reference to a hash with two elements, like:

  date             => "2011-01-23 17:22:37",
  timestamp        => 1295799757,

=head2 SetDateTime (timestamp)

Set date and time on device. The C<timestamp> is a unix timestamp as
returned by the C<time> function.

=head2 GetAlarm

Returns a reference to a hash with alarm info, like:

  alarm            => "07:25",
  state            => "off",

=head2 SetAlarm (hour, minute)

Set and enable alarm. Hour should be between 0 and 23, Minute between
0 and 59.

=head2 GetCalendarNotes (start, end)

Returns a reference to a list of calendar note hashes, like:

  location         => 1,
  date             => "2011-11-11 11:11:11",
  type             => "Meeting",
  text             => "Be there or be fired",
  mlocation        => "Board room",
  alarm            => "2010-10-10 10:10:10",
  recurrence       => "Weekly",
  number           => "+31612345678",

=head2 WriteCalendarNote ({ ... })

Set a calendar note,  attributes marked with a * are required

  date             => time + 86400,   # * Date and time of note
  text             => "Call John!",   # * Note text
  type             => "call",         #   Note type, defaults to MEMO
  number           => "+31612345678", #   Required for type CALL
  mlocation        => "Board room",   #   Adviced for type MEET
  alarm            => time + 86400,   #   Alarm time
  recurrence       => "Weekly",       #   Recurrence, defaults to NEVER

Valid note types are C<REMINDER>, C<CALL>, C<MEETING>, C<BIRTHDAY>,
and C<MEMO>. Type match is done case-ignorant and types may be
abbreviated to 4 characters.

Valid recurrence specifications are C<NEVER>, C<DAILY>, C<WEEKLY>,
C<2WEEKLY>, C<YEARLY>.  Type match is done case-ignorant and types
may be abbreviated to 4 characters.

=head2 GetTodo (start, end)

Returns a reference to a list of TODO note hashes, like:

  location         => 1,
  text             => "Finish GSM::Gnokii",
  priority         => "low",

=head2 WriteTodo ({ ... })

Write a TODO note. The contents of the hashref should match what GetTodo
returns for a fetched TODO entry.

=head2 DeleteAllTodos

Will delete B<all> TODO items.

=head2 GetDisplayStatus

Returns a reference to a hash with the display status, all boolean, like:

  call_in_progress => 0,
  unknown          => 0,
  unread_SMS       => 0,
  voice_call       => 0,
  fax_call_active  => 0,
  data_call_active => 0,
  keyboard_lock    => 0,
  sms_storage_full => 0,

=head2 Ping

Returns availability of the phone or undef if Ping is unimplemented in
libgnokii.

=head2 GetIMEI

Returns a reference to a hash with the IMEI data, like:

  model            => "RM-274",
  revision         => "V 07.21",
  imei             => "345634563456678",
  manufacturer     => "...",

=head2 GetPowerStatus

Returns a reference to a hash with power related information like:

  level            => "42.8571434020996094",
  source           => "battery",

=head2 GetMemoryStatus

Returns a reference to a list of memory status entries, like:

  dcfree           =>   236,	# Dialed numbers
  dcused           =>    20,
  enfree           => 12544,	# Emergency numbers
  enused           =>     0,
  fdfree           => 12544,	# Fied-dial numbers
  fdused           =>     0,
  mcfree           =>   493,	# Missed calls
  mcused           =>    19,
  onfree           =>    15,	# Own numbers
  onused           =>     0,
  phonefree        =>  1902,	# Internal phone memory
  phoneused        =>    98,
  rcfree           =>   748,	# Received calls
  rcused           =>    20,
  simfree          =>   250,	# SIM card
  simused          =>     0,

=head2 GetProfiles (start, end)

Returns a reference to a list of hashes with profile information, like:

  number           => 1,
  name             => "Tux",
  defaultname      => "Default",
  call_alert       => "Ringing",
  ringtonenumber   => 3,
  volume_level     => "Level 5",
  message_tone     => "Beep once",
  keypad_tone      => "Level 2",
  warning_tone     => "Off",
  vibration        => "On",
  caller_groups    => 2,
  automatic_answer => "Off",

Note that at some models, requesting profile information outside of the
known range might cause the phone to power off.

My own phone timed out on all C<GetProfile> requests.

=head2 GetSecurity

Returns a reference to a hash with the security information, like:

  status           => "Nothing to enter",
  security_code    => "...",

=head2 GetLogo ({ options })

Return a reference to a hash with Logo information, like:

  text             => "Foo",
  type             => "text",
  bitmap           => "...",
  size             => 64,
  height           => 8,
  width            => 8,

Supported options:

  type             => "...",  # text/dealer/op/startup/caller/
                              #  picture/emspicture/emsanimation
  callerindex      => 0,      # required for type => "caller". NYI

=head2 GetRingtoneList

Returns a reference to a hash with ringtone list information, like:

  count            =>   1,
  userdef_count    =>  10,
  userdef_location => 231,

=head2 GetRingtone (location)

Returns a reference to a hash with ringtone information, like:

  location         => 1,
  length           => 15,
  name             => 'Tones',
  ringtone         => "\002J:UQ\275\271\225\314\004",

=head2 GetDirTree (memorytype, depth)

Return a reference to a (recursive) list of folders and files in the
phone. The C<memorytype> should be either C<"ME"> for phone memory,
which will descend into C<A:\*>, or C<"SM">, which will descend into
the SIM card C<B:\*>. Descending is limited to C<depth> levels, where
passing C<0> for C<depth> means unlimited. It will return a hash
reference like:

  dir_size         => 128,
  file_count       => 18,
  memorytype       => "ME",
  path             => "A:\\*",
  tree             => [ ... ]

The C<tree> entry in the hash is a list of entries in the folder, of
which each is a reference to a hash with entry information like:

  date             => "2006-01-01 00:00:00",
  file             => undef,
  folder_id        => 0,
  name             => "FIM_punique_id",
  size             => 66,
  type             => "None",

If the entry has a size greater than 0, there might be added a file_id:

  date             => "2005-01-01 12:00:00",
  file             => undef,
  folder_id        => 0,
  id               => "00.00.10.00.01.8e",
  name             => "Flower2.jpg",
  size             => 10203,
  type             => "None",

If the entry is a folder itself, it will be extended with tree info
like in the top node:

  date             => "2006-01-01 00:00:00",
  dir_size         => 128,
  file             => undef,
  file_count       => 13,
  folder_id        => 0,
  name             => "predefgallery",
  path             => "A:\\predefgallery\\*",
  size             => 0,
  tree             => [ ... ]

Note that these calls might take a long time with big trees.

=head2 GetDir (memorytype, path, depth)

Like C<GetDirTree>, but with a default depth of C<1>, and a starting point.

=head2 GetFile (path)

Fetches a file from the phone. The C<path> should be in phone format, e.g.

  my $h = $gsm->GetFile ("A:\\FIM_fixed_id");

On success, a hashref is returned with two entries

  size             => 8,
  file             => "\1\0\0\0\0\0\3\0",

=head2 GetSMSCenter (start, end)

Returns a reference to a list of SMS Center information hashes like:

  id               => 1,
  name             => "KPN",
  defaultname      => -1,
  format           => "Text",
  validity         => "72 hours"
  type             => 145,
  smscnumber       => "+31612345678",
  recipienttype    => 0,
  recipientnumber  => "",

The valid range for start is 1..5.

=head2 GetSMSFolderList

Returns a reference to a list of hashes containing SMS Folder info, like:

  location         => 1,
  memorytype       => "IN",
  name             => "SMS Inbox",
  count            => 42,

=head2 CreateSMSFolder (name)

Creates an SMS folder.

=head2 DeleteSMSFolder (name)

Deletes an SMS folder.

=head2 GetSMSStatus

Returns a reference to the SMS status info, like:

  read             => 73,
  unread           =>  0,

=head2 GetSMS (memorytype, location)

Returns a reference to a hash with the SMS data, like:

  memorytype       => "IN",
  location         => 3,
  date             => "0000-00-00 00:00:00",
  sender           => "+31612345678",
  smsc             => "",
  smscdate         => "2010-07-12 20:10:35",
  status           => "read",
  text             => "This is fake data, enjoy!",
  timestamp        => -1,

=head2 DeleteSMS (memorytype, location)

Deletes the SMS as specified by the arguments.

=head2 $err = SendSMS ({ options })

Sends an SMS, attributes marked with a * are required

  destination      => "+31612345678", # * Recipient phone number
  message          => "Hello there",  # * Message text (max 160 characters)
  smscindex        => 1,              #   Index  of the SMS Center to use or
  smscnumber       => "+31612345678", #   Number of the SMS Center to use
  report           => 1,              #   Delivery report (default off )
  eightbit         => 1,              #   Use 8bit data   (default 7bit)
  validity         => 4320,           #   SMS validity in minutes
  animation        => ".....",        #   Animation ...              (NYI)
  ringtone         => ".....",        #   Filename with ringtone ... (NYI)

All other attribute are silently ignored.

=head2 GetRF

Returns a reference to a hash with the RF data, like:

  level            => 100,
  unit             =>   5,

=head2 GetNetworkInfo

Returns a reference to a hash with the network information, like:

  name             => "KPN",
  countryname      => "Netherlands",
  networkcode      => "204 08",
  cellid           => "b56f",
  lac              => 1127,

=head2 GetWapSettings (location)

Returns a reference to a hash with the WAP settings for given
location, like:

  location         => 1,
  name             => "Default",
  home             => "http://p3rl.org",
  session          => "Temporary",
  security         => "yes",
  bearer           => "GPRS",
  gsm_data_auth    => "Secure",
  call_type        => "Analog",
  call_speed       => "Automatic",
  number           => 1,
  gsm_data_login   => "Automatic",
  gsm_data_ip      => "10.11.12.13",
  gsm_data_user    => "johndoe",
  gsm_data_pass    => "Secret",
  gprs_connection  => "Always",
  gprs_auth        => "Secure",
  gprs_login       => "Automatic",
  access_point     => "w3_foo",
  gprs_ip          => "14.15.16.17",
  gprs_user        => "johndoe",
  gprs_pass        => "fidelity",
  sms_servicenr    => "+31612345678",
  sms_servernr     => 456,

=head2 WriteWapSetting ({ ... })

Write a WAP setting. Content of the hashref is like what
L<GetWapSetting> returns.

=head2 ActivateWapSetting (location)

Active WAP setting at location C<location>.

=head2 GetWapBookmark (location)

Returns a reference to a hash with WAP bookmark information, like:

  location         => 1,
  name             => "perl",
  url              => "http://p3rl.org",

=head2 WriteWapBookmark ({ ... })

Write a WAP bookmark. Content of the hashref should match what
L<GetWapBookmark> returns.

=head2 DeleteWapBookmark (location)

Delete WAP bookmark at C<location>.

=head2 GetFileList

NYI.

=head2 GetFiles

NYI.

=head2 GetMMS

NYI.

=head2 version

Returns the version of the module.

=head1 OTHER RESOURCES

  Gnokii home:       http://www.gnokii.org

  To get the most recent development branch:

    $ git clone git://git.savannah.nongnu.org/gnokii.git gnokii-git

  To view the most recent changes:

    http://git.savannah.gnu.org/gitweb/?p=gnokii.git;a=summary

  All gnokii projects:

    http://git.savannah.gnu.org/gitweb/?s=gnokii

  GSMI/GSMD::Gnokii: http://www.agouros.de/gnokii/

=head1 WARNINGS AND WARRANTY

This module just aims to be a perl API to libgnokii. All operations
are done without warranty. Just at own risk. Bugs could exist in this
code, as well as in libgnokii code or in the phone software itself.

Some functionality has not been tested as the phones available for
testing did not support the methods. Not all phones allow all actions,
even basic ones like C<GetProfile> might not be supported on your
mobile device.

=head1 AUTHOR

H.Merijn Brand 

Author of GSMD::Gnokii is Konstantin Agouros. gnokii@agouros.de
His code served as a huge inspiration to create this module.

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011-2013 H.Merijn Brand. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

gnokii(1), GSMI, GSMD::Gnokii

=cut
