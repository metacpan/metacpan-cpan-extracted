use strict;
use warnings;

use lib 'lib';

package File::Util::Exception::Diagnostic;
$File::Util::Exception::Diagnostic::VERSION = '4.161950';
# ABSTRACT: Diagnostic (verbose) error messages

use File::Util::Definitions qw( :all );
use File::Util::Exception qw( :all );

use vars qw(
   @ISA    $AUTHORITY
   @EXPORT_OK  %EXPORT_TAGS
);

use Exporter;

$AUTHORITY   = 'cpan:TOMMY';
@ISA         = qw( Exporter File::Util::Exception );
@EXPORT_OK   = ( '_errors', @File::Util::Exception::EXPORT_OK );
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );


#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
# DIAGNOSTIC (VERBOSE) ERROR MESSAGES
#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
sub _errors {
   my ( $class, $error_thrown ) = @_;

   $error_thrown ||= $class;

   # begin long table of helpful diag error messages
   my %error_msg_table = (
# NO UNICODE SUPPORT
'no unicode' => <<'__no_unicode__',
$opts->{_pak} can't read/write with (binmode => 'utf8') because your version of
Perl is not new enough to support unicode:
   Your currently running Perl is $EBL$^V$EBR

Origin:     This is a human error.
Solution:   Upgrade to Perl version 5.008001 (5.8) or newer for unicode support
            or do not use binmode => 'utf8' in your programs.
__no_unicode__

# NO SUCH FILE
'no such file' => <<'__bad_open__',
$opts->{_pak} can't open
   $EBL$opts->{filename}$EBR
because it is inaccessible or does not exist.

Origin:     This is *most likely* due to human error.
Solution:   Cannot diagnose.  A human must investigate the problem.
__bad_open__


# BAD FLOCK RULE POLICY
'bad flock rules' => <<'__bad_lockrules__',
Invalid file locking policy can not be implemented.  $opts->{_pak}::flock_rules
does not accept one or more of the policy keywords passed to this method.

   Invalid Policy specified: $EBL@{[
   join ' ', map { '[undef]' unless defined $_ } @{ $opts->{all} } ]}$EBR

   flock_rules policy in effect before invalid policy failed:
      $EBL@ONLOCKFAIL$EBR

   Proper flock_rules policy includes one or more of the following recognized
   keywords specified in order of precedence:
      BLOCK         waits to try getting an exclusive lock
      FAIL          dies with stack trace
      WARN          warn()s about the error with a stack trace
      IGNORE        ignores the failure to get an exclusive lock
      UNDEF         returns undef
      ZERO          returns 0

Origin:     This is a human error.
Solution:   A human must fix the programming flaw.
__bad_lockrules__


# CAN'T READ FILE - PERMISSIONS
'cant fread' => <<'__cant_read__',
Permissions conflict.  $opts->{_pak} can't read the contents of this file:
   $EBL$opts->{filename}$EBR

Due to insufficient permissions, the system has denied Perl the right to
view the contents of this file.  It has a bitmask of: (octal number)
   $EBL@{[ sprintf('%04o',(stat($opts->{filename}))[2] & 0777) ]}$EBR

   The directory housing it has a bitmask of: (octal number)
      $EBL@{[ sprintf('%04o',(stat($opts->{dirname}))[2] & 0777) ]}$EBR

   Current flock_rules policy:
      $EBL@ONLOCKFAIL$EBR

Origin:     This is *most likely* due to human error.  External system errors
            can occur however, but this doesn't have to do with $opts->{_pak}.
Solution:   A human must fix the conflict by adjusting the file permissions
            of directories where a program asks $opts->{_pak} to perform I/O.
            Try using Perl's chmod command, or the native system chmod()
            command from a shell.
__cant_read__


# CAN'T READ FILE - NOT EXISTENT
'cant fread not found' => <<'__cant_read__',
File not found.  $opts->{_pak} can't read the contents of this file:
   $EBL$opts->{filename}$EBR

The file specified does not exist.  It can not be opened or read from.

Origin:     This is *most likely* due to human error.  External system errors
            can occur however, but this doesn't have to do with $opts->{_pak}.
Solution:   A human must investigate why the application tried to open a
            non-existent file, and/or why the file is expected to exist and
            is not found.
__cant_read__


# CAN'T CREATE FILE - PERMISSIONS
'cant fcreate' => <<'__cant_write__',
Permissions conflict.  $opts->{_pak} can't create this file:
   $EBL$opts->{filename}$EBR

$opts->{_pak} can't create this file because the system has denied Perl
the right to create files in the parent directory.

   The -e test returns $EBL@{[-e $opts->{dirname} ]}$EBR for the directory.
   The -r test returns $EBL@{[-r $opts->{dirname} ]}$EBR for the directory.
   The -R test returns $EBL@{[-R $opts->{dirname} ]}$EBR for the directory.
   The -w test returns $EBL@{[-w $opts->{dirname} ]}$EBR for the directory
   The -W test returns $EBL@{[-w $opts->{dirname} ]}$EBR for the directory

   Parent directory: (path may be relative and/or redundant)
      $EBL$opts->{dirname}$EBR

   Parent directory has a bitmask of: (octal number)
      $EBL@{[ sprintf('%04o',(stat($opts->{dirname}))[2] & 0777) ]}$EBR

   Current flock_rules policy:
      $EBL@ONLOCKFAIL$EBR

Origin:     This is *most likely* due to human error.  External system errors
            can occur however, but this doesn't have to do with $opts->{_pak}.
Solution:   A human must fix the conflict by adjusting the file permissions
            of directories where a program asks $opts->{_pak} to perform I/O.
            Try using Perl's chmod command, or the native system chmod()
            command from a shell.
__cant_write__


# CAN'T WRITE TO FILE - EXISTS AS DIRECTORY
'cant write_file on a dir' => <<'__bad_writefile__',
$opts->{_pak} can't write to the specified file because it already exists
as a directory.
   $EBL$opts->{filename}$EBR

Origin:     This is a human error.
Solution:   Resolve naming issue between the existent directory and the file
            you wish to create/write/append.
__bad_writefile__


# CAN'T TOUCH A FILE - EXISTS AS DIRECTORY
'cant touch on a dir' => <<'__bad_touchfile__',
$opts->{_pak} can't touch the specified file because it already exists
as a directory.
   $EBL$opts->{filename}$EBR

Origin:     This is a human error.
Solution:   Resolve naming issue between the existent directory and the file
            you wish to touch.
__bad_touchfile__


# CAN'T WRITE TO FILE
'cant fwrite' => <<'__cant_write__',
Permissions conflict.  $opts->{_pak} can't write to this file:
   $EBL$opts->{filename}$EBR

Due to insufficient permissions, the system has denied Perl the right
to modify the contents of this file.  It has a bitmask of: (octal number)
   $EBL@{[ sprintf('%04o',(stat($opts->{filename}))[2] & 0777) ]}$EBR

   Parent directory has a bitmask of: (octal number)
      $EBL@{[ sprintf('%04o',(stat($opts->{dirname}))[2] & 0777) ]}$EBR

   Current flock_rules policy:
      $EBL@ONLOCKFAIL$EBR

Origin:     This is *most likely* due to human error.  External system errors
            can occur however, but this doesn't have to do with $opts->{_pak}.
Solution:   A human must fix the conflict by adjusting the file permissions
            of directories where a program asks $opts->{_pak} to perform I/O.
            Try using Perl's chmod command, or the native system chmod()
            command from a shell.
__cant_write__


# BAD OPEN MODE - PERL
'bad openmode popen' => <<'__bad_openmode__',
Illegal mode specified for file open.  $opts->{_pak} can't open this file:
   $EBL$opts->{filename}$EBR

When calling $opts->{_pak}::$opts->{meth}() you specified that the file
opened in this I/O operation should be opened in $EBL$opts->{badmode}$EBR
but that is not a recognized open mode.

Supported open modes for $opts->{_pak}::write_file() are:
   write       - open the file in write mode, creating it if necessary, and
                 overwriting any existing contents of the file.
   append      - open the file in append mode

Supported open modes for $opts->{_pak}::open_handle() are the same as above, but
also include the following:
   read        - open the file in read-only mode

   (and if the "use_sysopen => 1" flag is used):
   rwcreate    - open the file for update (read+write), creating it if necessary
   rwupdate    - open the file for update (read+write). Causes fatal error if
                 the file doesn't yet exist
   rwappend    - open the file for update in append mode
   rwclobber   - open the file for update, erasing all contents (truncating,
                 i.e- "clobbering" the file first)

Origin:     This is a human error.
Solution:   A human must fix the programming flaw by specifying the desired
            open mode from the list above.
__bad_openmode__


# BAD OPEN MODE - SYSOPEN
'bad openmode sysopen' => <<'__bad_openmode__',
Illegal mode specified for file sysopen.  $opts->{_pak} can't sysopen this file:
   $EBL$opts->{filename}$EBR

When calling $opts->{_pak}::$opts->{meth}() you specified that the file
opened in this I/O operation should be sysopen()'d in $EBL$opts->{badmode}$EBR
but that is not a recognized open mode.

Supported open modes for $opts->{_pak}::write_file() are:
   write       - open the file in write mode, creating it if necessary, and
                 overwriting any existing contents of the file.
   append      - open the file in append mode

Supported open modes for $opts->{_pak}::open_handle() are the same as above, but
also include the following:
   read        - open the file in read-only mode

   (and if the "use_sysopen => 1" flag is used, as the application JUST did):
   rwcreate    - open the file for update (read+write), creating it if necessary
   rwupdate    - open the file for update (read+write). Causes fatal error if
                 the file doesn't yet exist
   rwappend    - open the file for update in append mode
   rwclobber   - open the file for update, erasing all contents (truncating,
                 i.e- "clobbering" the file first)

Origin:     This is a human error.
Solution:   A human must fix the programming flaw by specifying the desired
            sysopen mode from the list above.
__bad_openmode__


# CAN'T LIST DIRECTORY
'cant dread' => <<'__cant_read__',
Permissions conflict.  $opts->{_pak} can't list the contents of this directory:
   $EBL$opts->{dirname}$EBR

Due to insufficient permissions, the system has denied Perl the right to
view the contents of this directory.  It has a bitmask of: (octal number)
   $EBL@{[ sprintf('%04o',(stat($opts->{dirname}))[2] & 0777) ]}$EBR

Origin:     This is *most likely* due to human error.  External system errors
            can occur however, but this doesn't have to do with $opts->{_pak}.
Solution:   A human must fix the conflict by adjusting the file permissions
            of directories where a program asks $opts->{_pak} to perform I/O.
            Try using Perl's chmod command, or the native system chmod()
            command from a shell.
__cant_read__


# CAN'T CREATE DIRECTORY - PERMISSIONS
'cant dcreate' => <<'__cant_dcreate__',
Permissions conflict.  $opts->{_pak} can't create:
   $EBL$opts->{dirname}$EBR

   $opts->{_pak} can't create this directory because the system has denied
   Perl the right to create files in the parent directory.

   Parent directory: (path may be relative and/or redundant)
      $EBL$opts->{parentd}$EBR

   Parent directory has a bitmask of: (octal number)
      $EBL@{[ sprintf('%04o',(stat($opts->{parentd}))[2] & 0777) ]}$EBR

Origin:     This is *most likely* due to human error.  External system errors
            can occur however, but this doesn't have to do with $opts->{_pak}.
Solution:   A human must fix the conflict by adjusting the file permissions
            of directories where a program asks $opts->{_pak} to perform I/O.
            Try using Perl's chmod command, or the native system chmod()
            command from a shell.
__cant_dcreate__


# CAN'T CREATE DIRECTORY - TARGET EXISTS
'make_dir target exists' => <<'__cant_dcreate__',
make_dir target already exists.
   $EBL$opts->{dirname}$EBR

$opts->{_pak} can't create the directory you specified because that
directory already exists, with filetype attributes of
@{[join(', ', @{ $opts->{filetype} })]} and permissions
set to $EBL@{[ sprintf('%04o',(stat($opts->{dirname}))[2] & 0777) ]}$EBR

Origin:     This is *most likely* due to human error.  The program has tried
            to make a directory where a directory already exists.
Solution:   Weaken the requirement somewhat by using the "if_not_exists => 1"
            flag when calling the make_dir object method.  This option
            will cause $opts->{_pak} to ignore attempts to create directories
            that already exist, while still creating the ones that don't.
__cant_dcreate__


# CAN'T OPEN
'bad open' => <<'__bad_open__',
$opts->{_pak} can't open this file for $EBL$opts->{mode}$EBR:
   $EBL$opts->{filename}$EBR

   The system returned this error:
      $EBL$opts->{exception}$EBR

   $opts->{_pak} used this directive in its attempt to open the file
      $EBL$opts->{cmd}$EBR

   Current flock_rules policy:
      $EBL@ONLOCKFAIL$EBR

Origin:     This is *most likely* due to human error.
Solution:   Cannot diagnose.  A Human must investigate the problem.
__bad_open__


# BAD CLOSE
'bad close' => <<'__bad_close__',
$opts->{_pak} couldn't close this file after $EBL$opts->{mode}$EBR
   $EBL$opts->{filename}$EBR

   The system returned this error:
      $EBL$opts->{exception}$EBR

   Current flock_rules policy:
      $EBL@ONLOCKFAIL$EBR

Origin:     Could be either human _or_ system error.
Solution:   Cannot diagnose.  A Human must investigate the problem.
__bad_close__


# CAN'T TRUNCATE
'bad systrunc' => <<'__bad_systrunc__',
$opts->{_pak} couldn't truncate() on $EBL$opts->{filename}$EBR after having
successfully opened the file in write mode.

The system returned this error:
   $EBL$opts->{exception}$EBR

Current flock_rules policy:
   $EBL@ONLOCKFAIL$EBR

This is most likely _not_ a human error, but has to do with your system's
support for the C truncate() function.
__bad_systrunc__


# CAN'T GET FLOCK AFTER BLOCKING
'bad flock' => <<'__bad_lock__',
$opts->{_pak} can't get a lock on the file
   $EBL$opts->{filename}$EBR

The system returned this error:
   $EBL$opts->{exception}$EBR

Current flock_rules policy:
   $EBL@ONLOCKFAIL$EBR

Origin:     Could be either human _or_ system error.
Solution:   Investigate the reason why you can't get a lock on the file,
            it is usually because of improper programming which causes
            race conditions on one or more files.
__bad_lock__


# CAN'T OPEN ON A DIRECTORY
'called open on a dir' => <<'__bad_open__',
$opts->{_pak} can't call open() on this file because it is a directory
   $EBL$opts->{filename}$EBR

Origin:     This is a human error.
Solution:   Use $opts->{_pak}::load_file() to load the contents of a file
            Use $opts->{_pak}::list_dir() to list the contents of a directory
__bad_open__


# CAN'T OPENDIR ON A FILE
'called opendir on a file' => <<'__bad_open__',
$opts->{_pak} can't opendir() on this file because it is not a directory.
   $EBL$opts->{filename}$EBR

Use $opts->{_pak}::load_file() to load the contents of a file
Use $opts->{_pak}::list_dir() to list the contents of a directory

Origin:     This is a human error.
Solution:   Use $opts->{_pak}::load_file() to load the contents of a file
            Use $opts->{_pak}::list_dir() to list the contents of a directory
__bad_open__


# CAN'T MKDIR ON A FILE
'called mkdir on a file' => <<'__bad_open__',
$opts->{_pak} can't auto-create a directory for this path name because it
already exists as a file.
   $EBL$opts->{filename}$EBR

Origin:     This is a human error.
Solution:   Resolve naming issue between the existent file and the directory
            you wish to create.
__bad_open__


# BAD CALL TO File::Util::read_limit
'bad read_limit' => <<'__read_limit__',
Bad call to $opts->{_pak}::read_limit().  This method can only be called with
a numeric value (bytes).  Non-integer numbers will be converted to integer
format if specified (numbers like 5.2), but don't do that, it's inefficient.

This operation aborted.

Origin:     This is a human error.
Solution:   A human must fix the programming flaw.
__read_limit__


# EXCEEDED READ_LIMIT
'read_limit exceeded' => <<'__read_limit__',
$opts->{_pak} can't load file: $EBL$opts->{filename}$EBR
into memory because its size exceeds the maximum file size allowed
for a read.

The size of this file is $EBL$opts->{size}$EBR bytes.

Currently the read limit is set at $EBL$opts->{read_limit}$EBR bytes.

Origin:     This is a human error.
Solution:   Consider setting the limit to a higher number of bytes.
__read_limit__


# BAD CALL TO File::Util::abort_depth
'bad abort_depth' => <<'__abort_depth__',
Bad call to $opts->{_pak}::abort_depth().  This method can only be called with
a numeric value (bytes).  Non-integer numbers will be converted to integer
format if specified (numbers like 5.2), but don't do that, it's inefficient.

This operation aborted.

Origin:     This is a human error.
Solution:   A human must fix the programming flaw.
__abort_depth__


# EXCEEDED ABORT_DEPTH
'abort_depth exceeded' => <<'__abort_depth__',
Recursion limit reached at $EBL${\ scalar(
   (exists $opts->{abort_depth} && defined $opts->{abort_depth}) ?
   $opts->{abort_depth} : $ABORT_DEPTH)
}$EBR dives.  The maximum level of subdirectory depth is set to the value
returned by $opts->{_pak}::abort_depth().  Try manually setting the value to a
higher number by calling list_dir() with the "abort_depth => N" option where N
is a positive integer value.  To set the default abort_depth for all recursive
list_dir() calls, invoke $opts->{_pak}::abort_depth() with the numeric argument
corresponding to the maximum number of subdirectory dives you want to allow.

This operation aborted.

Origin:     This is a human error.
Solution:   Consider setting the limit to a higher number.
__abort_depth__


# BAD OPENDIR
'bad opendir' => <<'__bad_opendir__',
$opts->{_pak} can't opendir on directory:
   $EBL$opts->{dirname}$EBR

The system returned this error:
   $EBL$opts->{exception}$EBR

Origin:     Could be either human _or_ system error.
Solution:   Cannot diagnose.  A Human must investigate the problem.
__bad_opendir__


# BAD MAKEDIR
'bad make_dir' => <<'__bad_make_dir__',
$opts->{_pak} had a problem with the system while attempting to create the
directory you specified with a bitmask of $EBL$opts->{bitmask}$EBR

directory: $EBL$opts->{dirname}$EBR

The system returned this error:
   $EBL$opts->{exception}$EBR

Origin:     Could be either human _or_ system error.
Solution:   Cannot diagnose.  A Human must investigate the problem.
__bad_make_dir__


# BAD CHARS
'bad chars' => <<'__bad_chars__',
$opts->{_pak} can't use this string for $EBL$opts->{purpose}$EBR.
   $EBL$opts->{string}$EBR
It contains illegal characters.

Illegal characters are:
   \\   (backslash)
   /   (forward slash)
   :   (colon)
   |   (pipe)
   *   (asterisk)
   ?   (question mark)
   "   (double quote)
   <   (less than)
   >   (greater than)
   \\t  (tab)
   \\ck (vertical tabulator)
   \\r  (newline CR)
   \\n  (newline LF)

Origin:     This is a human error.
Solution:   A human must remove the illegal characters from this string.
__bad_chars__


# CAN'T USE UTF8 WITH SYSOPEN
'bad binmode' => <<'__bad_binmode__',
IO discipline conflict.  $opts->{_pak} can't properly perform IO to this file
while using the options you specified:
   $EBL$opts->{filename}$EBR

The use of system IO (sysread/syswrite/etc) on utf8 file handles is deprecated,
and causes portability/reliability problems.  To learn more, you can read the
notes regarding binmode in `perldoc perlport`.

In short, please don't use these conflicting options together:
   use_sysopen => 1
   binmode     => 'utf8'

Origin:     This is a human error.
Solution:   A human must make a change to the code which calls
            $opts->{_pak}::$opts->{meth}(), so that it does not contain
            conflicting options.  Either use binmode => 'utf8' without the
            use_sysopen option, or don't direct $opts->{_pak}::$opts->{meth}()
            to 'use_sysopen'.
__bad_binmode__


# NOT A VALID FILEHANDLE
'not a filehandle' => <<'__bad_handle__',
$opts->{_pak} can't unlock file with an invalid file handle reference:
   $EBL$opts->{argtype}$EBR is not a valid filehandle

Origin:     This is most likely a human error, although it is remotely possible
            that this message is the result of an internal error in the
            $opts->{_pak} module, but this is not likely if you called
            $opts->{_pak}'s internal ::_release() method directly on your own.
Solution:   A human must fix the programming flaw.  Alternatively, in the second
            listed scenario the package maintainer must investigate the problem.
            Please submit a bug report with this error message in its entirety
            at https://rt.cpan.org/Dist/Display.html?Name=File%3A%3AUtil
__bad_handle__


# BAD CALL TO METHOD FOO
'no input' => <<'__no_input__',
$opts->{_pak} can't honor your call to $EBL$opts->{_pak}::$opts->{meth}()$EBR
because you didn't provide $EBL@{[$opts->{missing}||'the required input']}$EBR

Origin:     This is a human error.
Solution:   A human must fix the programming flaw.
__no_input__


# PLAIN ERROR TYPE
'plain error' => <<'__plain_error__',
$opts->{_pak} failed with the following message:
${\ scalar ($_[0] || ((exists $opts->{error} && defined $opts->{error}) ?
   $opts->{error} : '[error unspecified]')) }
__plain_error__


# INVALID ERROR TYPE
'unknown error message' => <<'__foobar_input__',
$opts->{_pak} failed with an invalid error-type designation.

Origin:     This is a bug!  Please file a bug report at
            https://rt.cpan.org/Dist/Display.html?Name=File%3A%3AUtil
Solution:   A human must fix the programming flaw.
__foobar_input__


# EMPTY ERROR TYPE
'empty error' => <<'__no_input__',
$opts->{_pak} failed with an empty error-type designation.

Origin:     This is a human error.
Solution:   A human must fix the programming flaw.
__no_input__

   ); # end of error message table

   exists $error_msg_table{ $error_thrown }
   ? $error_msg_table{ $error_thrown }
   : $error_msg_table{'unknown error message'}
}


# --------------------------------------------------------
# File::Util::Exception::Diagnostic::DESTROY()
# --------------------------------------------------------
sub DESTROY { }


1;


__END__

=pod

=head1 NAME

File::Util::Exception::Diagnostic - Diagnostic (verbose) error messages

=head1 VERSION

version 4.161950

=head1 DESCRIPTION

Provides those super-helpful wordy error messages with built-in diagnostics
to help users solve problems when things go wrong.

Users, don't use this module by itself.  It is for internal use only.

=cut
