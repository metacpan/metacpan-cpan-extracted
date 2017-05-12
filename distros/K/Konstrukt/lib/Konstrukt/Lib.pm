=head1 NAME

Konstrukt::Lib - Common function library

=head1 SYNOPSIS

	$Konstrukt::Lib->some_handy_method($param);
	#see documentation for each method
	
=head1 DESCRIPTION

This is a collection of commonly used methods. For more information take a look 
at the documentation for each method.

=head1 CONFIGURATION

You may do some configuration in your konstrukt.settings to let the mail
method know how it should work:
	
	#transport:
	#currently available: sendmail, smtp.
	#defaults to 'sendmail'.
	mail/transport      sendmail
	
	#the path of your mailer:
	#you may also specify some extra parameters.
	#defaults to 'sendmail'.
	mail/sendmail/path  /usr/sbin/sendmail -odb 
	
	#your smtp server:
	#defaults to 'localhost'.
	mail/smtp/server    some.smtp-server.com 
	
	#user and pass:
	#optional. when no user/pass is given, no auth will be tried.
	#defaults to 'undefined'
	mail/smtp/user      your username 
	mail/smtp/pass      your password
	
	#smtp authentication mechanism:
	#optional. may be: CRAM-MD5, NTLM, LOGIN, PLAIN.
	#when not specified every available method will be tried.
	mail/smtp/authtype  CRAM-MD5
	
	#defaults for the sender identification.
	#will be used when you don't specifiy it in your code.
	#defaults:
	mail/default_from   mail@localhost
	mail/default_name   Konstrukt Framework

=cut

package Konstrukt::Lib;

use strict;
use warnings;

use Konstrukt::Debug;

use URI::Escape;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless {}, $class;
}
#= /new

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default('mail/transport'     => 'sendmail');
	$Konstrukt::Settings->default('mail/sendmail/path' => 'sendmail');
	$Konstrukt::Settings->default('mail/smtp/server'   => 'localhost');
	$Konstrukt::Settings->default('mail/default_from'  => 'mail@localhost');
	$Konstrukt::Settings->default('mail/default_name'  => 'Konstrukt Framework');
	
	return 1;
}
#= /init

=head2 sh_escape

Escapes some critical sh characters

=over

=item * $string - Unescaped string

=back

=cut
sub sh_escape {
	my ($self, @strings) = @_;
	
	foreach my $string (@strings) {
		$string =~ s/[\001-\011\013-\014\016-\037\041-\052\057\074-\077\133-\136\140\173-\377]//go;
	}

	return wantarray ? @strings : $strings[0];
}
#= /sh_escape

=head2 html_paragraphify

Converts \n-separated texts into to <p></p>-separated text.

=over

=item * $string - Unescaped string

=back

=cut
sub html_paragraphify {
	my ($self, $text) = @_;
	
	return unless defined $text;
	
	my @lines = split /\r?\n|\r/, $text;
	return join '', map { ($_ ? "<p>$_</p>\n" : "") } @lines;
}
#= /html_paragraphify

=head2 html_escape

Escapes some critical HTML characters

=over

=item * $string - Unescaped string

=back

=cut
sub html_escape {
	my ($self, $text) = @_;
	
	return unless defined $text;
	
	my $replace = {
		'<' => '&lt;',
		'>' => '&gt;',
		'"' => '&quot;',
		"'" => '&apos;',
	};
	
	#replace ampersands separately
	$text =~ s/&/&amp;/go;
	#replace brackets and quotes
	$text =~ s/([<>'"])/$replace->{$1}/go;
	
	return $text;
}
#= /html_escape

=head2 html_unescape

Unescapes some critical HTML characters

=over

=item * $string - Escaped string

=back

=cut
sub html_unescape {
	my ($self, $text) = @_;
	
	return unless defined $text;
	
	my $replace = {
		'&lt;' => '<',
		'&gt;' => '>',
		'&amp;' => '&',
		'&quot;' => '"',
		'&apos;' => "'"		
	};
	
	$text =~ s/(&(?:lt|gt|amp|quot|apos);)/$replace->{$1}/go;

	return $text;
}
#= /html_unescape


=head2 uri_encode

Encode a string into a sequence of hex-values as done in HTTP URIs.

Encodes every character but [0-9A-Za-z-_.!~*'()]. If the $enc_all parameter
is true, B<all> characters will be encoded.

=over

=item * $string - String to encode

=item * $enc_all - Encode all characters

=back

=cut
sub uri_encode {
	my ($self, $string, $enc_all) = @_;
	
	return unless defined $string;
	return uri_escape($string, $enc_all ? "\x00-\xff" : undef);
}
# /uri_encode


=head2 xml_escape

Escapes some critical XML characters

=over

=item * $text - Unescaped string

=item * $esc_all - Boolean. Shall all chars besides letters and numbers be escaped?

=back

=cut
sub xml_escape {
	my ($self, $text, $enc_all) = @_;
	
	return unless defined $text;
	
	if ($enc_all) {
		for (my $pos = 0; $pos < length($text); $pos++) {
			my $char = substr($text, $pos, 1);
			if ($char !~ /[a-zA-Z0-9]/) {
				$char = sprintf "&#%03i;", ord(substr($text, $pos, 1));
				substr($text, $pos, 1) = $char;
				$pos += length($char) - 1;
			}
		}
	} else {
		#do the same as for html
		$text = $self->html_escape($text);
	}
	
	return $text;
}
#= /xml_escape

=head2 crlf2br

Converts \r?\n to <br />\n

=over

=item * $text - Unescaped string

=back

=cut
sub crlf2br {
	my ($self, $text) = @_;

	return unless defined $text;
	
	$text =~ s/(\r?\n|\r)/\<br \/\>\n/go;

	return $text;
}
#= /crlf2br

=head2 mail

Send out an email using the "sendmail" app on your system or directly via SMTP.
You may specify some settings in your konstrukt.settings. See L<above|/CONFIGURATION>.

Uses L<Mail::Sender> for SMTP, which in turn uses L<Digest::HMAC_MD5> for auth
type C<CRAM-MD5> and L<Authen::NTLM> for auth type NTLM.
So you might want to install those modules, if you use these auth types.

=over

=item * $subject - The mail's subject

=item * $text    - The body

=item * $to      - The recipient

=item * ($cc)    - Optional: Carbon copy

=item * ($bcc)   - Optional: Blind carbon copy

=item * ($from)  - The senders email address (e.g. john@doe.com).
If not specified the defaults from your settings will be used.

=item * ($FROM)  - The sender full name (e.g. "John Doe")
If not specified the defaults from your settings will be used.

=back

=cut
sub mail {
	my ($self, $subject, $text, $to, $cc, $bcc, $from, $FROM) = @_;
	
	#check obligatory parameters
	unless (defined $subject) {
		$Konstrukt::Debug->error_message("No subject defined!") if Konstrukt::Debug::ERROR;
		return;
	}
	unless (defined $text) {
		$Konstrukt::Debug->error_message("No text defined!") if Konstrukt::Debug::ERROR;
		return;
	}
	unless (defined $to) {
		$Konstrukt::Debug->error_message("No recipient defined!") if Konstrukt::Debug::ERROR;
		return;
	}
	
	$from ||= $Konstrukt::Settings->get('mail/default_from');
	$FROM ||= $Konstrukt::Settings->get('mail/default_name');
	
	#send mail
	if (lc $Konstrukt::Settings->get('mail/transport') eq 'smtp') {
		$self->mail_smtp($subject, $text, $to, $cc, $bcc, $from, $FROM);
	} else {
		$self->mail_sendmail($subject, $text, $to, $cc, $bcc, $from, $FROM);
	}
}
#= /mail

=head2 mail_sendmail

Send out an email using the "sendmail" app on your system.
Generally only used internally. You probably want to use L</mail>.

=cut
sub mail_sendmail {
	my ($self, $subject, $text, $to, $cc, $bcc, $from, $FROM) = @_;

	my $sendmail = $Konstrukt::Settings->get('mail/sendmail/path');
	
	if (open  MAIL, "| $sendmail -t -oi -f \"$from\" -F \"$FROM\"") {
		print MAIL  "To: $to\n";
		print MAIL  "CC: $cc\n" if defined $cc;
		print MAIL  "BCC: $bcc\n" if defined $bcc;
		print MAIL  "Reply-To: $from\n";
		print MAIL  "Subject: $subject\n\n";
		print MAIL  "$text";
		if (close MAIL) {
			return 1;
		} else {
			$Konstrukt::Debug->error_message("Couldn't close sendmail!") if Konstrukt::Debug::ERROR;
			return undef;
		}
	} else {
		 $Konstrukt::Debug->error_message("Couldn't open sendmail!") if Konstrukt::Debug::ERROR;
		 
		 return undef;
	}
}
#= /mail_sendmail

=head2 mail_smtp

Send out an email using an SMTP server.
Generally only used internally. You probably want to use L</mail>.

=cut
sub mail_smtp {
	my ($self, $subject, $text, $to, $cc, $bcc, $from, $FROM) = @_;
	
	eval { require Mail::Sender };
	if ($@) {
		$Konstrukt::Debug->error_message("Couldn't load module Mail::Sender! It is probably not installed. $@") if Konstrukt::Debug::ERROR;
		return;
	}
	
	my ($server, $auth, $user, $pass);

	#default settings
	$server   = $Konstrukt::Settings->get('mail/smtp/server');
	$auth     = $Konstrukt::Settings->get('mail/smtp/authtype');
	$user     = $Konstrukt::Settings->get('mail/smtp/user');
	$pass     = $Konstrukt::Settings->get('mail/smtp/pass');
	
	#build from-header
	$from = "\"$FROM\" <$from>" if defined $FROM;
	
	#create sender object
	my $sender = Mail::Sender->new({
		from    => $from,
#		replyto => $from,
		to      => $to,
		cc      => $cc,
		bcc     => $bcc,
		subject => $subject,

		smtp    => $server,
		authid  => $user,
		authpwd => $pass
	});
	
	#get supported auth protocols
	my %supported_auth_types = map { $_ => 1 } $sender->QueryAuthProtocols();
	#add UNDEF (= no auth) to the server supported auth methods
	$supported_auth_types{UNDEF} = 1;
	#connection error?
	if (defined $sender->{'error'}) {
		$Konstrukt::Debug->error_message("Couldn't get supported authentication methods/connect to SMTP server '$server'! " . $sender->{'error_msg'}) if Konstrukt::Debug::ERROR;
		return;
	}
	
	#determine auth types to try
	undef $auth if not $auth or not length $auth;
	my @auth_types;
	if (defined $user and defined $pass) {
		#auth required
		if (defined $auth) {
			#predefined auth
			@auth_types = (uc $auth);
		} else {
			#try all auth types
			@auth_types = qw/CRAM-MD5 NTLM LOGIN PLAIN UNDEF/;
		}
		
		#create intersection of server supported auth types and client
		my @intersection;
		foreach my $type (@auth_types) {
			push @intersection, $type if ($supported_auth_types{$type});
		}
		@auth_types = @intersection;
	} else {
		#no auth!
		@auth_types = ('UNDEF');
	}
	
	#put error message when there are no matching auth types
	unless (@auth_types) {
		$Konstrukt::Debug->error_message("No available authentication methods (matching your settings)! Cannot send.") if Konstrukt::Debug::ERROR;
		return;
	}
	
	#try all supported auth types
	my $sent = 0;
	foreach my $type (@auth_types) {
		eval {
			delete $sender->{auth};
			$sender->{auth} = $type unless $type eq 'UNDEF';
			#send mail
			my $rv = $sender->MailMsg({ msg => $text });
			#check return value
			if (ref $rv) {
				#success
				$sent = 1;
			} else {
				#error
				$Konstrukt::Debug->error_message("Error (auth method $type): $sender->{error_msg} (code $sender->{error})") if Konstrukt::Debug::ERROR;
			}
		};
		#errors in eval
		if ($@) {
			chomp $@;
			$Konstrukt::Debug->error_message("Error: $@") if Konstrukt::Debug::ERROR;
		}
		#exit the loop, if successfully sent
		last if $sent;
	}
	
	#put error message it no method succeeded:
	$Konstrukt::Debug->error_message("Could not send your email! No authentication method succeeded.") if not $sent and Konstrukt::Debug::ERROR;
	
	return $sent;
}
#= /mail_smtp

=head2 random_password

Generates a random password consisting of characters and digits of a given length.

=over

=item * $length - The passwords length

=item * $lowercase - Optional: Only use lowercase letters. Defaults to 0.

=back

=cut
sub random_password {
	my ($self, $length, $lowercase) = @_;
	
	my $pass = '';
	#0-9: 48-57
	#A-Z: 65-90
	#a-z: 97-122
	for (my $i = 1; $i <= $length; $i++) {
		my $num .= int(rand(36 + ($lowercase ? 0 : 26)));
		#warn $num;
		if ($num < 10) {
			#digits
			$pass .= chr($num + 48);
		} elsif ($num < 36) {
			#lower case letters
			$pass .= chr($num + 87);
		} else {
			#upper case letters
			$pass .= chr($num + 29);
		}
	}
	
	return $pass;
}
#= /random_password

=head2 date_w3c

Returns the specified local time in the w3c date/time format. Actually, it's ISO 8601.
Returns the diffence in the format as specified in http://www.w3.org/TR/NOTE-datetime
YYYY-MM-DDThh:mm:ssTZD

=over

=item * $year - Either the years since 1900 (e.g. 1996 = 96, 2004 = 104) or the absolute year (e.g. 1996)

=item * $month - Jan = 1, Feb = 2, ...

=item * $mday - 1,2,3,...

=item * $hour

=item * $minute

=item * $second

=back

=cut
sub date_w3c {
	my ($self, $year, $mon, $mday, $hour, $min, $sec) = @_;
	
	if (!$year or !$mon or !$mday) {
		$Konstrukt::Debug->error_message("Supplied date incomplete! " . sprintf('%04d-%02d-%02d', $year, $mon, $mday)) if Konstrukt::Debug::ERROR;
		return undef;
	}
	
	#adjust date to fit into timelocal/localtime
	$year  -= ($year > 1900 ? 1900 : 0);
	$mon   -= 1;
	$hour ||= 0;
	$min  ||= 0;
	$sec  ||= 0;
	
	use Time::Local;
	my $time = timelocal($sec, $min, $hour, $mday, $mon, $year);
	use Time::Zone;
	my $diff = tz_local_offset($time) / 3600;
	#my $diff = ((localtime($time))[2] - (gmtime($time))[2]);
	
	#readjust date to get it human readable
	$year += 1900;
	$mon  += 1;
	
	#format date
	$time = sprintf("%04d-%02d-%02dT%02d:%02d:%02d%+03d:00", $year, $mon, $mday, $hour, $min, $sec, $diff);
	
	return $time;
}
#= /date_w3c


=head2 date_rfc822

Returns the specified local time in the date/time format specified in RFC 822:
Day, DD Mon YYYY hh:mm:ss TZD

=over

=item * $year - Either the years since 1900 (e.g. 1996 = 96, 2004 = 104) or the absolute year (e.g. 1996)

=item * $month - Jan = 1, Feb = 2, ...

=item * $mday - 1,2,3,...

=item * $hour

=item * $minute

=item * $second

=back

=cut
sub date_rfc822 {
	my ($self, $year, $mon, $mday, $hour, $min, $sec) = @_;
	
	if (!$year or !$mon or !$mday) {
		$Konstrukt::Debug->error_message("Supplied date incomplete! " . sprintf('%04d-%02d-%02d', $year, $mon, $mday)) if Konstrukt::Debug::ERROR;
		return undef;
	}
	
	#adjust date to fit into timelocal/localtime
	$year  -= ($year > 1900 ? 1900 : 0);
	$mon   -= 1;
	$hour ||= 0;
	$min  ||= 0;
	$sec  ||= 0;
	
	#calculate timezone difference
   use Time::Local;
	my $time = timelocal($sec, $min, $hour, $mday, $mon, $year);
	use Time::Zone;
	my $diff = tz_local_offset($time) / 3600;
	
	#readjust date to get it human readable
	$year += 1900;
	$mon  += 1;
	
	use DateTime;
	use DateTime::Format::Mail;
	my $dt = DateTime->new(
		year => $year, month => $mon, day => $mday,
		hour => $hour, minute => $min, second => $sec,
		time_zone => sprintf("%+03d:00", $diff)
	);
	# "Mon, 16 Jul 1979 16:45:20 +1000"
	return DateTime::Format::Mail->format_datetime($dt);
}
#= /date_rfc822


=head2 plugin_dbi_install_helper

May be used to do the installation work of a DBI backend of some plugins.

The backend modules themselves pass a string containing SQL-statements
(among others) to create the needed tables.

The section for the creation is named C<dbi: create>. The section must be
declared using the scheme described in L</extract_data_sections>.

The statements in each block are separated through semicolons.

Example:

	-- 8< -- dbi: create -- >8 --
	
	CREATE TABLE IF NOT EXISTS foo ( <definition> );
	CREATE TABLE IF NOT EXISTS bar ( <definition> );

The backend plugin stores these SQL-statements in it's C<__DATA__>-section
at the end of the file.

The C<install> method of the backend module then can get as simple as:

	sub install {
		my ($self) = @_;
		return $Konstrukt::Lib->plugin_dbi_install_helper($self->{db_settings});
	}

This method returns true on success.

B<Parameters:>

=over

=item * $db - Either an array reference containing the DBI source, user and
password of the database your backend uses or a database handle to this db.

=back

=cut
sub plugin_dbi_install_helper {
	my ($self, $db) = @_;
	
	#determine calling package
	my $package = caller;
	
	#use supplied dbh or create one from the supplied db connection settings
	my $dbh;
	if ((ref $db) =~ /^(Apache::)?DBI::db$/) {
		$dbh = $db;
	} elsif (ref $db eq 'ARRAY') {
		$dbh = $Konstrukt::DBI->get_connection(@{$db})
	} else {
		$Konstrukt::Debug->error_message("Cannot install DBI backend for plugin $package: Parameter \$db is neither a database handle nor an arrayref containing database connection settings.") if Konstrukt::Debug::ERROR;
		return;
	}
	
	$Konstrukt::Debug->debug_message("Installing DBI backend for plugin $package") if Konstrukt::Debug::INFO;
	
	#extract relevant sections
	my $sections = $self->extract_data_sections($package);
	
	#only take the relevant sections and split multiple queries into single queries
	my @queries = split /;/, ($sections->{'dbi: create'} || '');
	
	#create tables
	foreach my $query (@queries) {
		next if $query =~ /^\s*$/; #skip "empty" queries
		$dbh->do($query) or return;
	}
	
	return 1;
}
# /plugin_dbi_install_helper

=head2 plugin_file_install_helper

May be used to do the installation work of the necessary files (like templates
or images) of some plugins.

The section for the each text file (e.g. a template) is named
C<textfile: subfolder/name.extension>.
The section must be declared using the scheme described in L</extract_data_sections>.
The section for a binary file must be named C<binaryfile: subfolder/name.extension>.
The content of the binary file must be base64 encoded and put into the section.
(You can use the supplied script C<base64enc.pl> which reads from STDIN and
writes the encoded data to STDOUT.)

The path/filename of template files should follow this scheme:

	<template type>/<name of the template>.template

C<template type> should be used to group different types of templates.
This may be:

=over

=item * layout: Templates to display the data

=item * messages: Templates to display messages like errors (e.g. "permission
denied") and confirmations (e.g. "entry successfully created") 

=back

Of course you can use other "directory names".

If the filename starts with a slash (C</>), the path will not be prepended by the
basepath. It will be put into the document root.

Example:

	-- 8< -- textfile: layout/display.template -- >8 --
	
	This is the data:
	<+$ data $+>(no data specified)<+$ / $+>

	-- 8< -- textfile: layout/display_something_else.template -- >8 --
	
	-- 8< -- binaryfile: /gfx/some_icon.gif -- >8 --
	
	R0lGODlhEAAQAKIAAEuVzf+MO////v96G/fMrdDj8v/izf+1fyH5BAAAAAAALAAAAAAQABAAAANE
	KLrcziQMOZ8gI2sCOliYNhmC9wmHWCkmqh6MGWpw7M0D4cgi2fCi2qKVCto6iqIm4GspcCNBYVpg
	GFQ5i8AgoQy0jwQAOw==
	
	...
	
The plugin stores these files in it's C<__DATA__>-section
at the end of the file.

The C<install> method of the plugin then can get as simple as:

	sub install {
		my ($self) = @_;
		return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
	}

This method returns true on success.

B<Parameters:>

=over

=item * $basepath - The base path for all the files of your plugin.

=back

=cut
sub plugin_file_install_helper {
	my ($self, $basepath) = @_;
	
	#determine calling package
	my $package = caller;
	
	$Konstrukt::Debug->debug_message("Installing templates for plugin $package") if Konstrukt::Debug::INFO;
	
	#extract relevant sections
	my $sections = $self->extract_data_sections($package);
	
	foreach my $section (sort keys %{$sections}) {
		if (defined $section and $section =~ /^(textfile|binaryfile):\s+(.*?)$/) {
			my ($type, $filename) = ($1, $2);
			$filename = "$basepath$filename" if $filename !~ /^\//;
			my $abs_filename = $Konstrukt::File->absolute_path($filename);
			unless (-f $abs_filename) {
				#file doesn't exist (yet). create it.
				my $content = $sections->{$section};
				if ($type eq 'binaryfile') {
					require MIME::Base64;
					$content = MIME::Base64::decode_base64($content);
				}
				$Konstrukt::Debug->debug_message("Installing file '$filename' for plugin $package") if Konstrukt::Debug::INFO;
				#ensure that the required directory exists
				$Konstrukt::File->create_dirs($Konstrukt::File->extract_path($abs_filename));
				$Konstrukt::File->raw_write($abs_filename, $content)
					or return;
			}
		}
	}
	
	return 1;
}
# /plugin_file_install_helper

=head2 extract_data_sections

Some plugins store some additional data at the end (after __DATA__) of the
module file.

This method takes all this data and returns multiple sections of this data
(which might represent some files or SQL statements and the like) as an hash:

	{
		name_of_section1 => 'content1',
		name_of_section2 => 'content2',
		...
	}

Where the text after __DATA__ is organized like that:

	-- 8< -- name_of_section1 -- >8 --
	
	content1
	
	-- 8< -- name_of_section2 -- >8 --
	
	content2

The sections have to be separated by "-- 8< --" followed by the identifier of
the section followed by "-- >8 --" all on one line.
	
B<Parameters:>

=over

=item * $package - The name of the package whose __DATA__ section should be read and parsed

=back

=cut
sub extract_data_sections {
	my ($self, $package) = @_;
	
	#create references to the DATA handle of the package and a variable to store its start position
	no strict 'refs';
	my $data_handle = *{$package . '::DATA'}{IO};
	my $data_pos = *{$package . '::DATA_POS'}{SCALAR};
	use strict 'refs';
	
	#save the starting position of the DATA handle of this package if not already saved
	$$data_pos = tell $data_handle unless defined $$data_pos;
	#reset the cursor of the DATA handle
	seek $data_handle, $$data_pos, 0;
	
	#read the data
	local $/ = undef;
	my $data = <$data_handle>;
	
	return unless defined $data;
	
	#split into sections
	my $identifier = '';
	my $sections;
	for (split /^(-- 8< --\s+.*?\s+-- >8 --)$/m, $data) {
		if (/^-- 8< --\s+(.*?)\s+-- >8 --$/) {
			$identifier = $1;
		} else {
			s/^\s*//; s/\s*$//; #trim leading/trailing whitespaces
			$sections->{$identifier} = $_;
		}
	}
	
	return $sections;
}
# /extract_data_sections 

=head2 xor_encrypt

Encrypt/Decrypt a string with a defined key using XOR encryption.

=over

=item * $text - String to en-/decrypt

=item * $key - The key to use for en-/decryption

=back

=cut
sub xor_encrypt {
	my ($self, $text, $key) = @_;
	
	return unless defined $text;
	
	my $result = '';
	for (my $i = 0; $i < length($text); $i++) {
		$result .= (substr($text, $i, 1) ^ substr($key, $i % length($key), 1));
	}
	return $result;
}
# /xor_encrypt 


=head2 quoted_string_to_word

Splits a given string into word. Multiple words which are surrounded by
doublequotes will be parsed into one word.

Returns an array of words/word sequences.

=over

=item * $string - String to parse

=back

=cut
sub quoted_string_to_word {
	my ($self, $string) = @_;
	
	return unless defined $string;
	
	#parse string
	my @tokens = split /(\s+|")/, $string;
	my @strings;
	my $quotes_opened;
	foreach my $token (@tokens) {
		next if not length($token) or $token =~ /^\s+$/;
		if ($token eq '"') {
			$quotes_opened = not $quotes_opened;
			push @strings, '' if $quotes_opened;
		} else {
			#text
			if ($quotes_opened) {
				#append text
				$strings[-1] .= length($strings[-1]) ? " $token" : $token;
			} else {
				#add text
				push @strings, $token;
			}
		}
	}
	
	return @strings;
}
# /quoted_string_to_word


#create global object
sub BEGIN { $Konstrukt::Lib = __PACKAGE__->new() unless defined $Konstrukt::Lib; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut
