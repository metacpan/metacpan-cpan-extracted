#===============================================================================
#
# CryptFile/lib/Filter/Crypto/CryptFile.pm
#
# DESCRIPTION
#   Module providing the means to convert files to/from an encrypted state in
#   which they can be run via Filter::Crypto::Decrypt.
#
# COPYRIGHT
#   Copyright (C) 2004-2009, 2012-2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   This module is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

package Filter::Crypto::CryptFile;

use 5.008001;

use strict;
use warnings;

use Carp qw(carp croak);
use Exporter qw();
use Fcntl qw(:DEFAULT :flock);
use Scalar::Util qw(reftype);
use XSLoader qw();

## no critic (Subroutines::ProhibitSubroutinePrototypes)

sub crypt_file($;$$);
sub _isa_cryptmode($);
sub _isa_filehandle($);
sub _isa_filename($);

#===============================================================================
# MODULE INITIALIZATION
#===============================================================================

our(@ISA, @EXPORT, @EXPORT_OK, $VERSION);

BEGIN {
    @ISA = qw(Exporter);

    @EXPORT = qw(
        CRYPT_MODE_AUTO
        CRYPT_MODE_ENCRYPT
        CRYPT_MODE_DECRYPT
        CRYPT_MODE_ENCRYPTED
        CRYPT_MODE_DECRYPTED
        crypt_file
    );

    @EXPORT_OK = qw(
        $ErrStr
    );

    $VERSION = '2.09';

    XSLoader::load(__PACKAGE__, $VERSION);
}

# Last error message.
our $ErrStr = '';

#===============================================================================
# PUBLIC API
#===============================================================================

# Autoload the CRYPT_MODE_* flags from the constant() XS function.

sub AUTOLOAD {
    our $AUTOLOAD;

    # Get the name of the constant to generate a subroutine for.
    (my $constant = $AUTOLOAD) =~ s/^.*:://o;

    # Avoid deep recursion on AUTOLOAD() if constant() is not defined.
    croak('Unexpected error in AUTOLOAD(): constant() is not defined')
        if $constant eq 'constant';

    my($error, $value) = constant($constant);

    # Handle any error from looking up the constant.
    croak($error) if $error;

    # Generate an in-line subroutine returning the required value.
    {
    no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
    *$AUTOLOAD = sub { return $value };
    }

    # Switch to the subroutine that we have just generated.
    goto &$AUTOLOAD;
}

sub crypt_file($;$$) {
    $ErrStr = '';
    my $num_bytes = 0;

    if ( @_ == 1 or
        (@_ == 2 and (not defined $_[1] or $_[1] eq '' or
                      _isa_cryptmode($_[1])              )))
    {
        my($fh, $file, $opened, $flocked);
        if (_isa_filehandle($_[0])) {
            $fh = $_[0];
            $opened = 0;
        }
        elsif (_isa_filename($_[0])) {
            $file = $_[0];
            unless (sysopen $fh, $file, O_RDWR | O_BINARY) {
                $ErrStr = "Can't open file '$file' for updating: $!";
                return;
            }
            $opened = 1;
        }
        else {
            croak("'$_[0]' is not a filehandle or a file name");
        }

        if (-f $fh) {
            unless (flock $fh, LOCK_EX | LOCK_NB) {
                $ErrStr = "Can't acquire exclusive lock on update " .
                          "filehandle: $!";
                local($!, $^E);
                close $fh if $opened;
                return;
            }
            $flocked = 1;
        }

        my $crypt_mode = (@_ == 2 and defined $_[1] and $_[1] ne '')
                         ? $_[1] : CRYPT_MODE_AUTO();

        unless (_crypt_fh($fh, $crypt_mode, $num_bytes)) {
            local($!, $^E);
            $opened ? close $fh : $flocked ? flock $fh, LOCK_UN : 1;
            return;
        }

        if ($opened) {
            close $fh or
                carp("Can't close file '$file' after updating: $!");
        }
        elsif ($flocked) {
            flock $fh, LOCK_UN or
                carp("Can't release lock on filehandle after updating: $!");
        }
    }
    else {
        my($in_fh, $in_file, $in_opened, $in_flocked);
        if (_isa_filehandle($_[0])) {
            $in_fh = $_[0];
            $in_opened = 0;
        }
        elsif (_isa_filename($_[0])) {
            $in_file = $_[0];
            unless (sysopen $in_fh, $in_file, O_RDONLY | O_BINARY) {
                $ErrStr = "Can't open input file '$in_file' for reading: $!";
                return;
            }
            $in_opened = 1;
        }
        else {
            croak("'$_[0]' is not a filehandle or a file name");
        }

        if (-f $in_fh) {
            unless (flock $in_fh, LOCK_SH | LOCK_NB) {
                $ErrStr = "Can't acquire shared lock on input filehandle: $!";
                local($!, $^E);
                close $in_fh if $in_opened;
                return;
            }
            $in_flocked = 1;
        }

        my($out_fh, $out_file, $out_opened, $out_flocked);
        if (_isa_filehandle($_[1])) {
            $out_fh = $_[1];
            $out_opened = 0;
        }
        elsif (_isa_filename($_[1])) {
            $out_file = $_[1];
            unless (sysopen $out_fh, $out_file,
                    O_WRONLY | O_CREAT | O_TRUNC | O_BINARY)
            {
                $ErrStr = "Can't open output file '$out_file' for writing: $!";
                local($!, $^E);
                $in_opened ? close $in_fh
                           : $in_flocked ? flock $in_fh, LOCK_UN : 1;
                return;
            }
            $out_opened = 1;
        }
        else {
            local($!, $^E);
            $in_opened ? close $in_fh : $in_flocked ? flock $in_fh, LOCK_UN : 1;
            croak("'$_[1]' is not a valid crypt mode or a filehandle or a " .
                  "file name");
        }

        if (-f $out_fh) {
            unless (flock $out_fh, LOCK_EX | LOCK_NB) {
                $ErrStr = "Can't acquire exclusive lock on output " .
                          "filehandle: $!";
                local($!, $^E);
                $in_opened ? close $in_fh
                           : $in_flocked ? flock $in_fh, LOCK_UN : 1;
                close $out_fh if $out_opened;
                return;
            }
            $out_flocked = 1;
        }

        my $crypt_mode;
        if (@_ == 3 and defined $_[2] and $_[2] ne '') {
            if (_isa_cryptmode($_[2])) {
                $crypt_mode = $_[2];
            }
            else {
                local($!, $^E);
                $in_opened  ? close $in_fh
                            : $in_flocked  ? flock $in_fh,  LOCK_UN : 1;
                $out_opened ? close $out_fh
                            : $out_flocked ? flock $out_fh, LOCK_UN : 1;
                croak("'$_[2]' is not a valid crypt mode");
            }
        }
        else {
            $crypt_mode = CRYPT_MODE_AUTO();
        }

        unless (_crypt_fhs($in_fh, $out_fh, $crypt_mode, $num_bytes)) {
            local($!, $^E);
            $in_opened  ? close $in_fh
                        : $in_flocked  ? flock $in_fh,  LOCK_UN : 1;
            $out_opened ? close $out_fh
                        : $out_flocked ? flock $out_fh, LOCK_UN : 1;
            return;
        }

        if ($in_opened) {
            close $in_fh or
                carp("Can't close input file '$in_file' after reading: $!");
        }
        elsif ($in_flocked) {
            flock $in_fh, LOCK_UN or
                carp("Can't release lock on input filehandle after " .
                     "reading: $!");
        }

        if ($out_opened) {
            close $out_fh or
                carp("Can't close output file '$out_file' after writing: $!");
        }
        elsif ($out_flocked) {
            flock $out_fh, LOCK_UN or
                carp("Can't release lock on output filehandle after " .
                     "writing: $!");
        }
    }

    return $num_bytes ? $num_bytes : '0E0';
}

#===============================================================================
# PRIVATE API
#===============================================================================

sub _isa_cryptmode($) {
    my $mode = shift;

    return(($mode eq CRYPT_MODE_AUTO()      or
            $mode eq CRYPT_MODE_ENCRYPT()   or
            $mode eq CRYPT_MODE_DECRYPT()   or
            $mode eq CRYPT_MODE_ENCRYPTED() or
            $mode eq CRYPT_MODE_DECRYPTED()   ));
}

sub _isa_filehandle($) {
    my $fh = shift;

    return(((    ref $fh and reftype($fh)  eq 'GLOB') or
            (not ref $fh and reftype(\$fh) eq 'GLOB')   ) and
           defined fileno $fh);
}

sub _isa_filename($) {
    my $name = shift;

    return(not ref $name and reftype(\$name) eq 'SCALAR');
}

1;

__END__

#===============================================================================
# DOCUMENTATION
#===============================================================================

=head1 NAME

Filter::Crypto::CryptFile - Encrypt (and decrypt) Perl files

=head1 SYNOPSIS

    use Filter::Crypto::CryptFile qw(:DEFAULT $ErrStr);

    # Encrypt one filehandle (or file name) to another.
    crypt_file($in_fh,   $out_fh,   $crypt_mode) or
        die "crypt_file() failed: $ErrStr\n";
    crypt_file($in_file, $out_file, $crypt_mode) or
        die "crypt_file() failed: $ErrStr\n";

    # The crypt mode can be determined automatically.
    crypt_file($in_fh,   $out_fh)   or die "crypt_file() failed: $ErrStr\n";
    crypt_file($in_file, $out_file) or die "crypt_file() failed: $ErrStr\n";

    # Encrypt one filehandle (or file name) in-place (in memory).
    crypt_file($in_out_fh,   $crypt_mode) or
        die "crypt_file() failed: $ErrStr\n";
    crypt_file($in_out_file, $crypt_mode) or
        die "crypt_file() failed: $ErrStr\n";

    # The crypt mode can be determined automatically.
    crypt_file($in_out_fh)   or die "crypt_file() failed: $ErrStr\n";
    crypt_file($in_out_file) or die "crypt_file() failed: $ErrStr\n";

=head1 DESCRIPTION

This module provides a single function called C<crypt_file()> for converting
files to/from an encrypted state in which they can be run via
L<Filter::Crypto::Decrypt|Filter::Crypto::Decrypt>.

The function takes either a pair of open filehandles (one to read from and one
to write to) or else a single open filehandle (to process "in-place").  (File
names can also be specified instead of open filehandles.)  It reads data from
the input source, either encrypts it or decrypts it according to the "crypt
mode", and then writes the result to the output source.

In each case, the "crypt mode" may either be explicitly specified using the
C<CRYPT_MODE_*> flags, or else it can be omitted (or specified as C<undef> or
the null string) in order to be determined automatically by C<crypt_file()>.

=head2 Functions

=over 4

=item C<crypt_file($in_fh, $out_fh[, $crypt_mode])>

=item C<crypt_file($in_out_fh[, $crypt_mode])>

If two open filehandles, $in_fh and $out_fh, are supplied then input is read
from $in_fh, encrypted or decrypted, and the output is written to $out_fh.
Clearly $in_fh must have been opened for reading and $out_fh must have been
opened for writing.  Only a small amount of data is held in memory at any time,
so this method is safe to use for "large" files without using unduly large
amounts of memory.

If only one open filehandle, $in_out_fh, is supplied then input is read from it,
encrypted or decrypted, and the output is written back to it after truncating
the file to zero size.  In this case, $in_out_fh must have been opened for
"updating" (both reading and writing).  Using this method the whole file is read
into memory in one go, so it is not suitable for use on "large" files.  This is
unlikely to be a problem in practice, however, since Perl source code files are
rarely, if ever, sufficiently large to cause any trouble in this regard.

Note that the filehandle being written to when encrypting and the filehandle
being read from when decrypting I<must> be opened in "binary" mode on those
platforms where it makes a difference (notably Win32), otherwise the encrypted
"binary" data being written or read may become corrupted by CR-LF translations.
It will also be necessary to open the other filehandle (which the Perl source
code itself is being read from or written to) in "binary" mode too if the Perl
source code happens to contain any "binary" data, e.g. in a C<__DATA__> section.

File names may be supplied instead of open filehandles, in which case they will
be opened appropriately by C<crypt_file()> itself and closed again after use.
(C<crypt_file()> always opens the filehandles in "binary" mode so any "binary"
data in the Perl source code will be correctly handled.)

The optional L<$crypt_mode|"Crypt Mode Flags"> argument specifies whether to
perform encryption or decryption.  If it is omitted or specified as C<undef> or
the null string then the crypt mode will be determined automatically by reading
the beginning of the input data.  If the beginning is

    use Filter::Crypto::Decrypt;

then the data is presumed to be in an encrypted state already so the mode will
be set to C<CRYPT_MODE_DECRYPT>; otherwise the mode will be set to
C<CRYPT_MODE_ENCRYPT>.

On success, returns the number of bytes written (which could be zero if the
input was already in the requested state, in which case the special "zero but
true" value will be returned); on failure returns the undefined value (in scalar
context) or the empty list (in list context) and sets $ErrStr.

=back

=head2 Crypt Mode Flags

The $crypt_mode argument in C<crypt_file()> specifies whether to encrypt or
decrypt the input data, as follows:

=over 4

=item C<CRYPT_MODE_AUTO>

Have the crypt mode determined automatically by the same means as described
under C<crypt_file()> in the case where the $crypt_mode argument is omitted or
specified as C<undef> or the null string.

=item C<CRYPT_MODE_ENCRYPT>

Encrypt the input data and prepend the statement

    use Filter::Crypto::Decrypt;

to the output data so that it can be run via
L<Filter::Crypto::Decrypt|Filter::Crypto::Decrypt>.  Produces a warning if the
input data already has that statement at the beginning.

=item C<CRYPT_MODE_DECRYPT>

Decrypt the input data after first removing the statement

    use Filter::Crypto::Decrypt;

from the beginning.  Produces a warning if the input data does not have that
statement at the beginning.

=item C<CRYPT_MODE_ENCRYPTED>

The same as C<CRYPT_MODE_ENCRYPT> except that the encryption is not performed if
the input data already begins with the statement

    use Filter::Crypto::Decrypt;

Thus, unencrypted data will be encrypted, while encrypted data will not be
encrypted a second time.

=item C<CRYPT_MODE_DECRYPTED>

The same as C<CRYPT_MODE_DECRYPT> except that the decryption is not attempted if
the input data does not begin with the statement

    use Filter::Crypto::Decrypt;

Thus, encrypted data will be decrypted, while unencrypted data will not be
decrypted a second time.

=back

=head2 Variables

=over 4

=item $ErrStr

Last error message.

If the C<crypt_file()> function fails then a description of the last error will
be set in this variable for use in reporting the cause of the failure, much like
the use of the Perl Special Variables C<$!> and C<$^E> after failed system calls
and OS API calls.  See L<"Error Values"> for a listing of the possible values of
$ErrStr.

If the function succeeds then this variable will generally be set to the null
string.  The only exceptions to this are when the crypt mode was specified as
either C<CRYPT_MODE_ENCRYPTED> or C<CRYPT_MODE_DECRYPTED> and the input data was
found to be already encrypted or decrypted respectively so that no action was
required: in these cases a message to this effect will be set in $ErrStr.

=back

=head1 DIAGNOSTICS

=head2 Warnings and Error Messages

This module may produce the following diagnostic messages.  They are classified
as follows (a la L<perldiag>):

    (W) A warning (optional).
    (F) A fatal error (trappable).
    (I) An internal error that you should never see (trappable).

=over 4

=item Can't close file '%s' after updating: %s

(W) The specified file opened by C<crypt_file()> for reading data from and
writing data to when updating a file "in-place" could not be closed after use.
The system error message corresponding to the standard C library C<errno>
variable is also given.

=item Can't close input file '%s' after reading: %s

(W) The specified input file opened by C<crypt_file()> for reading data from
could not be closed after use.  The system error message corresponding to the
standard C library C<errno> variable is also given.

=item Can't close output file '%s' after writing: %s

(W) The specified output file opened by C<crypt_file()> for writing data to
could not be closed after use.  The system error message corresponding to the
standard C library C<errno> variable is also given.

=item Can't release lock on filehandle after updating: %s

(W) The exclusive lock acquired by C<crypt_file()> on the filehandle used for
reading data from and writing data to when updating a file "in-place" could not
be released after use.  The system error message corresponding to the standard 
library C<errno> variable is also given.

=item Can't release lock on input filehandle after reading: %s

(W) The shared lock acquired by C<crypt_file()> on the input filehandle used for
reading data from could not be released after use.  The system error message
corresponding to the standard C library C<errno> variable is also given.

=item Can't release lock on output filehandle after writing: %s

(W) The exclusive lock acquired by C<crypt_file()> on the output filehandle used
for writing data to could not be released after use.  The system error message
corresponding to the standard C library C<errno> variable is also given.

=item chsize/ftruncate not implemented

(F) The attempt by C<crypt_file()> to truncate the file to zero size before
writing the data to it when updating a file "in-place" failed because the
C<chsize()> and C<ftruncate()> functions are not implemented on this system.

=item Input data already contains decryption filter

(W) The crypt mode was specified as C<CRYPT_MODE_ENCRYPT> but data read from the
input filehandle already begins with the statement

    use Filter::Crypto::Decrypt;

Perhaps you are attempting to encrypt data when you meant to be decrypting it?

=item Input data does not contain decryption filter

(W) The crypt mode was specified as C<CRYPT_MODE_DECRYPT> but data read from the
input filehandle did not begin with the statement

    use Filter::Crypto::Decrypt;

Perhaps you are attempting to decrypt data when you meant to be encrypting it?

=item %s is not a filehandle or a file name

(F) The first parameter for C<crypt_file()> must be either a valid (open)
filehandle or a file name, but the argument passed was neither of these things.

=item %s is not a valid crypt mode

(F) The third parameter for C<crypt_file()> must be either C<undef> or the null
string (meaning determine the crypt mode automatically), or a valid crypt mode
(i.e. one of the C<CRYPT_MODE_*> flags), but the argument passed was neither of
these things.

=item %s is not a valid crypt mode or a filehandle or a file name

(F) The second parameter for C<crypt_file()> must be one of: C<undef> or the
null string (meaning determine the crypt mode automatically), a valid crypt mode
(i.e. one of the C<CRYPT_MODE_*> flags), or a valid (open) filehandle or a file
name, but the argument passed was none of these things.

=item %s is not a valid Filter::Crypto::CryptFile macro

(F) You attempted to lookup the value of the specified constant in the
Filter::Crypto::CryptFile module, but that constant is unknown to this module.

=item No such package '%s'

(F) This module's bootstrap function was called on the specified package, which
does not exist.

=item Random IV may not be cryptographically strong

(W) libcrypto's random number generator failed to generate cryptographically
strong pseudo-random bytes for use as the initialization vector (IV) in the
encryption.  A weaker sequence of pseudo-random bytes was used instead, which is
not necessarily unpredictable and may not be suitable for this purpose.

=item Random salt may not be cryptographically strong

(W) libcrypto's random number generator failed to generate cryptographically
strong pseudo-random bytes for use as the salt when performing the key
derivation before encryption.  A weaker sequence of pseudo-random bytes was used
instead, which is not necessarily unpredictable and may not be suitable for this
purpose.

=item Unexpected error in AUTOLOAD(): constant() is not defined

(I) There was an unexpected error looking up the value of a constant: the
constant-lookup function itself is apparently not defined.

=item Unexpected return type %d while processing Filter::Crypto::CryptFile macro
%s

(I) There was an unexpected error looking up the value of the specified
constant: the C component of the constant-lookup function returned an unknown
type.

=item Unknown crypt mode '%d'

(I) The XSUB called internally by C<crypt_file()> was passed a crypt mode that
it does not recognize or failed to derive correctly a crypt mode for setting in
the crypto context structure to be used when performing the encryption or
decryption.

=item Unknown crypto context mode '%d'

(I) The crypto context structure used internally when performing encryption or
decryption has been set-up with a crypt mode that it does not recognize.

=item Your vendor has not defined Filter::Crypto::CryptFile macro %s

(I) You attempted to lookup the value of the specified constant in the
Filter::Crypto::CryptFile module, but that constant is apparently not defined.

=back

=head2 Error Values

The C<crypt_file()> function sets $ErrStr to a value indicating the cause of the
error when it fails.  The possible values are as follows:

=over 4

=item Can't acquire exclusive lock on output filehandle: %s

The filehandle used by C<crypt_file()> for writing data to could not be locked
for exclusive use.  The system error message corresponding to the standard C
library C<errno> variable is also given.

=item Can't acquire exclusive lock on update filehandle: %s

The filehandle used by C<crypt_file()> for reading data from and writing data to
when updating a file "in-place" could not be locked for exclusive use.  The
system error message corresponding to the standard C library C<errno> variable
is also given.

=item Can't acquire shared lock on input filehandle: %s

The filehandle used by C<crypt_file()> for reading data from could not be locked
for shared use.  The system error message corresponding to the standard C
library C<errno> variable is also given.

=item Can't cleanup cipher context: %s

The cipher context structure used to perform the encryption or decryption could
not be cleaned up after use.  The last error message from libcrypto is also
given.

=item Can't decode odd-numbered (%d-byte) length hexadecimal text

The hexadecimal encoding of the encrypted source code, consisting of a pair of
hexadecimal digits for each byte of data, could not be decoded because an odd
number of hexadecimal digits were found.

=item Can't decode non-hexadecimal digit (byte %02x at position %d) in
      hexadecimal text

The hexadecimal encoding of the encrypted source code, consisting of a pair of
hexadecimal digits for each byte of data, could not be decoded because a byte
other than a hexadecimal digit was found.

=item Can't derive %d-byte key: %s

libcrypto's PKCS#5 v2.0 compatible key derivation algorithm failed to derive a
key of the specified length from the supplied password for use in the encryption
or decryption.  The last error message from libcrypto is also given.

=item Can't finalize cipher context: %s

The cipher context structure used to perform the encryption or decryption could
not be finalized.  The last error message from libcrypto is also given.

=item Can't generate %d-byte random salt: %s

libcrypto's random number generator failed to generate the specified number of
pseudo-random bytes for use as the salt when performing the key derivation prior
to encryption.  The last error message from libcrypto is also given.

=item Can't generate %d-byte random IV: %s

libcrypto's random number generator failed to generate the specified number of
pseudo-random bytes for use as the initialization vector (IV) in the encryption.
The last error message from libcrypto is also given.

=item Can't initialize cipher context in crypt mode '%d': %s

The cipher context structure used to perform the encryption or decryption could
not be initialized in the specified crypt mode.  This is the first stage of the
cipher context structure initialization, performed before setting the key length
and modifying other cipher parameters.  The last error message from libcrypto is
also given.

=item Can't initialize cipher context in crypt mode '%d' using %d-byte key: %s

The cipher context structure used to perform the encryption or decryption could
not be initialized in the specified crypt mode with the specified key length.
This is the final stage of the cipher context structure initialization,
performed after setting the key length and modifying other cipher parameters.
The last error message from libcrypto is also given.

=item Can't initialize PRNG

libcrypto's random number generator could not be seeded with enough entropy.

=item Can't open file '%s' for updating: %s

The specified file could not be opened by C<crypt_file()> for reading data from
and writing data to when updating a file "in-place".  The system error message
corresponding to the standard C library C<errno> variable is also given.

=item Can't open input file '%s' for reading: %s

The specified file from which to read data could not be opened for reading by
C<crypt_file()>.  The system error message corresponding to the standard C
library C<errno> variable is also given.

=item Can't open output file '%s' for writing: %s

The specified file could not be opened by C<crypt_file()> for writing data to.
The system error message corresponding to the standard C library C<errno>
variable is also given.

=item Can't read from input filehandle: %s

There was an error reading data from the input filehandle.  The system error
message corresponding to the standard C library C<errno> variable is also given.

=item Can't set key length to %d: %s

The specified key length could not be set for the cipher context structure used
to perform the encryption or decryption.  The last error message from libcrypto
is also given.

=item Can't set RC2 effective key bits to %d: %s

The specified effective key bits could not be set for the cipher context
structure used to perform the encryption or decryption when using the RC2
cipher.  The last error message from libcrypto is also given.

=item Can't set RC5 number of rounds to %d: %s

The specified number of rounds could not be set for the cipher context structure
used to perform the encryption or decryption when using the RC5 cipher.  The
last error message from libcrypto is also given.

=item Can't truncate filehandle: %s

The filehandle used by C<crypt_file()> for reading data from and writing data to
when updating a file "in-place" could not be truncated to zero size before
writing data to it.  The system error message corresponding to the standard C
library C<errno> variable is also given.

=item Can't update cipher context with %d bytes of in-text: %s

The cipher context structure used to perform the encryption or decryption could
not be updated with the specified number of bytes of input data.  The last error
message from libcrypto is also given.

=item Can't write header line to output filehandle: %s

There was an error writing the statement

    use Filter::Crypto::Decrypt;

to the output filehandle.  The system error message corresponding to the
standard C library C<errno> variable is also given.

=item Can't write to filehandle: %s

There was an error writing data to the filehandle when updating a file
"in-place".  The system error message corresponding to the standard C library
C<errno> variable is also given.

=item Can't write to output filehandle: %s

There was an error writing data to the output filehandle.  The system error
message corresponding to the standard C library C<errno> variable is also given.

=item Derived key length is wrong (%d, expected %d)

libcrypto's PKCS#5 v1.5 compatible key derivation algorithm failed to derive a
key of the requested length from the supplied password for use in the encryption
or decryption.

=item Input data was already decrypted

The crypt mode was specified as C<CRYPT_MODE_DECRYPTED> and data read from the
input filehandle does not begin with the statement

    use Filter::Crypto::Decrypt;

indicating that the data is probably already decrypted.  No action was taken,
and C<crypt_file()> returned success.  Use the crypt mode C<CRYPT_MODE_DECRYPT>
if you really want to force decryption in this case.

=item Input data was already encrypted

The crypt mode was specified as C<CRYPT_MODE_ENCRYPTED> and data read from the
input filehandle already begins with the statement

    use Filter::Crypto::Decrypt;

indicating that the data is probably already encrypted.  No action was taken,
and C<crypt_file()> returned success.  Use the crypt mode C<CRYPT_MODE_ENCRYPT>
if you really want to force encryption in this case.

=back

=head1 EXAMPLES

See the B<crypt_file> script for examples of the use of the C<crypt_file()>
function.

=head1 EXPORTS

The following symbols are, or can be, exported by this module:

=over 4

=item Default Exports

C<crypt_file>;

C<CRYPT_MODE_AUTO>,
C<CRYPT_MODE_ENCRYPT>,
C<CRYPT_MODE_DECRYPT>,
C<CRYPT_MODE_ENCRYPTED>,
C<CRYPT_MODE_DECRYPTED>.

=item Optional Exports

C<$ErrStr>.

=item Export Tags

I<None>.

=back

=head1 KNOWN BUGS

I<None>.

=head1 CAVEATS

=over 4

=item *

Note that specifying the "crypt_mode" as C<CRYPT_MODE_AUTO>, C<undef> or the
null string can be used to resolve any ambiguity in the case where
C<crypt_file()> is called with two arguments, namely, did the caller intend
C<crypt_file($in_file, $out_file)> or C<crypt_file($in_out_file, $crypt_mode)>?

In such cases, C<crypt_file()> checks if the second argument is a valid "crypt
mode" before considering if it is a file name, so it normally Does The Right
Thing.  However, if you wanted to write the output to a file called F<1> (which
happens to be the value of the C<CRYPT_MODE_ENCRYPT> flag) then calling

    crypt_file($in_file, '1');

will not do what you want.  In this case, you can call

    crypt_file($in_file, '1', CRYPT_MODE_AUTO);

instead to get the desired behaviour (without having to explicitly specify the
crypt mode).

=back

=head1 SEE ALSO

L<Filter::Crypto>.

=head1 ACKNOWLEDGEMENTS

The C<FilterCrypto_PRNGInit()> and C<FilterCrypto_GetRandNum()> functions used
by the XS code are based on code taken from the C<ssl_rand_seed()> and
C<ssl_rand_choosenum()> functions in Apache httpd (version 2.4.9).

Thanks to Steve Henson for help with performing PBE and PKCS#5 v2.0 key
derivation with arbitrary ciphers and non-default key lengths using the OpenSSL
libcrypto library.

=head1 AUTHOR

Steve Hay E<lt>L<shay@cpan.org|mailto:shay@cpan.org>E<gt>.

=head1 COPYRIGHT

Copyright (C) 2004-2009, 2012-2014 Steve Hay.  All rights reserved.

=head1 LICENCE

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself, i.e. under the terms of either the GNU General Public
License or the Artistic License, as specified in the F<LICENCE> file.

=head1 VERSION

Version 2.09

=head1 DATE

08 Dec 2020

=head1 HISTORY

See the F<Changes> file.

=cut

#===============================================================================
