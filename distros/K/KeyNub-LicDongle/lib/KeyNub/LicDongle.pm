package KeyNub::LicDongle;

use strict;
use warnings;
use Carp qw(croak);
use FFI::Platypus 2.00;
use FFI::Platypus::Buffer qw(scalar_to_buffer);
use Exporter qw(import);

our $VERSION = '1.1.1';

=head1 NAME

KeyNub::LicDongle - Perl binding for the KeyNub USB-C license dongle

=head1 SYNOPSIS

    use KeyNub::LicDongle;

    my $dongle = KeyNub::LicDongle->open;      # first dongle, or ->open($serial)
    $dongle->verify_genuine;                   # dies unless genuine
    $dongle->session_open;
    my $data = $dongle->app_decrypt($blob);    # <- build the licence check on this
    $dongle->session_close;
    $dongle->close;

=head1 DESIGN

This binding calls the SDK's B<flat companion API> (C<keynub_licdongle_flat>)
rather than the core ABI, which is what COBOL and Fortran do and for the same
reason. The flat API has no structs, no library-allocated buffers and no
callbacks, so nothing here hand-writes a struct layout with computed padding —
the one class of mistake in an FFI binding that produces plausible wrong values
instead of a crash.

The cost is that there is no progress reporting: the flat API has no callbacks.
Records are read in one call.

Requires L<FFI::Platypus>, the one dependency. Set
C<KEYNUB_LICDONGLE_FLAT_LIBRARY> to point at a specific library.

=head1 SECURITY

Read F<docs/integration-security.md> before writing the check.
C<exit unless $dongle-E<gt>is_genuine> is one line to delete, and Perl ships as
source. What cannot be deleted is data the program needs and only the dongle can
decrypt — put it through C<app_encrypt>/C<app_decrypt>.

=cut

# --- status codes -----------------------------------------------------------

our %STATUS = (
    OK                    => 0,
    INVALID_ARGUMENT      => -1,
    NO_DEVICE             => -2,
    ACCESS_DENIED         => -3,
    IO                    => -4,
    TIMEOUT               => -5,
    PROTOCOL              => -6,
    NOT_GENUINE           => -7,
    CERTIFICATE_INVALID   => -8,
    SESSION_EXPIRED       => -9,
    TAG_MISMATCH          => -10,
    RANGE                 => -11,
    STORAGE_FULL          => -12,
    BUSY                  => -13,
    NOT_FOUND             => -14,
    AUTH_REQUIRED         => -15,
    FIRMWARE_INCOMPATIBLE => -16,
    SDK_TOO_OLD           => -17,
    CANCELLED             => -18,
    NOT_IMPLEMENTED       => -19,
    INTERNAL              => -20,
);

# Bits in the flags value from get_info.
our $FLAG_SE_READY     = 1;
our $FLAG_PROVISIONED     = 2;
our $FLAG_WATCHDOG_REBOOT = 4;
our $FLAG_ISOLATED        = 8;
# The write-auth key has been rotated away from the factory one, which is
# public: a dongle without this bit takes writes from anyone holding it.
our $FLAG_WRITEAUTH_ROTATED = 16;

# Who can decrypt data produced by app_encrypt.
our $SCOPE_DEVICE    = 0;    # only this one physical dongle
our $SCOPE_DEVELOPER = 1;    # any dongle issued by the same developer

our @EXPORT_OK = qw(
    %STATUS $FLAG_SE_READY $FLAG_PROVISIONED $FLAG_WATCHDOG_REBOOT
    $FLAG_ISOLATED $FLAG_WRITEAUTH_ROTATED
    $SCOPE_DEVICE $SCOPE_DEVELOPER
);

# --- library discovery ------------------------------------------------------

sub _default_library {
    return 'keynub_licdongle_flat.dll'    if $^O eq 'MSWin32';
    return 'libkeynub_licdongle_flat.dylib' if $^O eq 'darwin';
    return 'libkeynub_licdongle_flat.so';
}

my $FFI;

sub _ffi {
    return $FFI if $FFI;

    my $lib = $ENV{KEYNUB_LICDONGLE_FLAT_LIBRARY} || _default_library();
    my $ffi = eval { FFI::Platypus->new(api => 2, lib => $lib) }
        or croak "could not load the KeyNub flat library '$lib': $@";

    # int32 in by value, int32 out by reference, strings in as 'string', and every
    # caller-provided buffer as 'opaque' with a pointer taken from a Perl scalar.
    $ffi->attach(licdf_version   => ['sint32*','sint32*','sint32*'] => 'sint32');
    $ffi->attach(licdf_strerror  => ['sint32','opaque','sint32'] => 'sint32');

    $ffi->attach(licdf_device_count  => ['sint32*'] => 'sint32');
    $ffi->attach(licdf_device_serial => ['sint32','opaque','sint32'] => 'sint32');
    $ffi->attach(licdf_device_path   => ['sint32','opaque','sint32'] => 'sint32');

    $ffi->attach(licdf_open      => ['string'] => 'sint32');
    $ffi->attach(licdf_open_path => ['string'] => 'sint32');
    $ffi->attach(licdf_close     => ['sint32'] => 'sint32');
    $ffi->attach(licdf_set_trust_root => ['sint32','opaque','sint32'] => 'sint32');

    $ffi->attach(licdf_get_serial => ['sint32','opaque','sint32'] => 'sint32');
    $ffi->attach(licdf_get_info   => ['sint32', map { 'sint32*' } 1..8] => 'sint32');
    $ffi->attach(licdf_verify_genuine =>
        ['sint32','sint32*','opaque','sint32','opaque','sint32'] => 'sint32');

    $ffi->attach(licdf_session_open  => ['sint32'] => 'sint32');
    $ffi->attach(licdf_session_close => ['sint32'] => 'sint32');
    $ffi->attach(licdf_write_auth    => ['sint32','opaque','sint32'] => 'sint32');
    $ffi->attach(licdf_write_auth_rotate => ['sint32','opaque','sint32'] => 'sint32');

    $ffi->attach(licdf_record_count => ['sint32','sint32*'] => 'sint32');
    $ffi->attach(licdf_record_name  =>
        ['sint32','sint32','opaque','sint32','sint32*'] => 'sint32');
    $ffi->attach(licdf_record_size  => ['sint32','string','sint32*'] => 'sint32');
    $ffi->attach(licdf_record_read  =>
        ['sint32','string','opaque','sint32','sint32*'] => 'sint32');
    $ffi->attach(licdf_record_write =>
        ['sint32','string','opaque','sint32'] => 'sint32');
    $ffi->attach(licdf_record_erase     => ['sint32','string'] => 'sint32');
    $ffi->attach(licdf_record_erase_all => ['sint32'] => 'sint32');

    $ffi->attach(licdf_counter_read      => ['sint32','sint32','sint32*'] => 'sint32');
    $ffi->attach(licdf_counter_increment => ['sint32','sint32','sint32*'] => 'sint32');

    $ffi->attach(licdf_app_encrypt =>
        ['sint32','sint32','opaque','sint32','opaque','sint32','sint32*'] => 'sint32');
    $ffi->attach(licdf_app_decrypt =>
        ['sint32','opaque','sint32','opaque','sint32','sint32*'] => 'sint32');

    $ffi->attach(licdf_last_error => ['sint32','opaque','sint32'] => 'sint32');

    $FFI = $ffi;
    return $FFI;
}

# --- errors -----------------------------------------------------------------

=head2 Errors

Failures die with a L<KeyNub::LicDongle::Error> object, which stringifies for a
plain C<die> handler and carries C<status>, C<operation> and C<detail> for code
that wants to branch. Compare C<$err-E<gt>status> against C<$STATUS{NO_DEVICE}>
and friends.

=cut

{
    package KeyNub::LicDongle::Error;
    use overload '""' => sub {
        my $self = shift;
        my $text = "$self->{operation}: $self->{message}";
        $text .= " ($self->{detail})" if length $self->{detail};
        return "$text\n";
    }, fallback => 1;

    sub new    { my ($c,%a) = @_; bless {%a}, $c }
    sub status    { $_[0]{status} }
    sub operation { $_[0]{operation} }
    sub detail    { $_[0]{detail} }
    sub message   { $_[0]{message} }
}

sub _status_text {
    my ($status) = @_;
    my $buffer = "\0" x 256;
    my ($ptr, $size) = scalar_to_buffer $buffer;
    return "status $status" if licdf_strerror($status, $ptr, $size) != 0;
    return unpack 'Z*', $buffer;
}

sub _throw {
    my ($status, $operation, $detail) = @_;
    die KeyNub::LicDongle::Error->new(
        status    => $status,
        operation => $operation,
        message   => _status_text($status),
        detail    => defined $detail ? $detail : '',
    );
}

sub _check {
    my ($self, $status, $operation) = @_;
    return if $status == 0;
    my $detail = '';
    if (ref $self && $self->{handle}) {
        my $buffer = "\0" x 256;
        my ($ptr, $size) = scalar_to_buffer $buffer;
        $detail = unpack 'Z*', $buffer
            if licdf_last_error($self->{handle}, $ptr, $size) == 0;
    }
    _throw($status, $operation, $detail);
}

# --- module-level -----------------------------------------------------------

=head2 library_version

    my ($major, $minor, $patch) = KeyNub::LicDongle::library_version();

=cut

sub library_version {
    _ffi();
    my ($major, $minor, $patch) = (0, 0, 0);
    licdf_version(\$major, \$minor, \$patch);
    return ($major, $minor, $patch);
}

=head2 device_count / device_serial

Enumerates without opening. C<device_count> takes the snapshot that
C<device_serial> indexes into, so call them back to back.

=cut

sub device_count {
    _ffi();
    my $count = 0;
    _check(undef, licdf_device_count(\$count), 'licdf_device_count');
    return $count;
}

sub device_serial {
    my ($index) = @_;
    _ffi();
    my $buffer = "\0" x 15;
    my ($ptr, $size) = scalar_to_buffer $buffer;
    _check(undef, licdf_device_serial($index, $ptr, $size), 'licdf_device_serial');
    return unpack 'Z*', $buffer;
}

# --- constructor ------------------------------------------------------------

=head2 open

    my $dongle = KeyNub::LicDongle->open;          # first dongle found
    my $dongle = KeyNub::LicDongle->open($serial);

Dies with C<$STATUS{NO_DEVICE}> when none is attached.

=cut

sub open {
    my ($class, $serial) = @_;
    _ffi();
    my $handle = licdf_open(defined $serial ? $serial : '');
    _throw($handle, 'licdf_open') if $handle <= 0;
    return bless { handle => $handle, session => 0 }, ref($class) || $class;
}

=head2 open_simulated

Opens a dongle backed by the in-process software simulator. Present only when the
loaded library was built with the simulator compiled in, which the shipping
library is not.

=cut

sub open_simulated {
    my ($class) = @_;
    my $ffi = _ffi();
    $ffi->attach(licdf_open_simulated => [] => 'sint32')
        unless defined &licdf_open_simulated;
    my $handle = licdf_open_simulated();
    _throw($handle, 'licdf_open_simulated') if $handle <= 0;
    return bless { handle => $handle, session => 0 }, ref($class) || $class;
}

sub _handle {
    my ($self) = @_;
    croak 'the dongle has been closed' unless $self->{handle};
    return $self->{handle};
}

=head2 close

Releases the dongle. Safe to call more than once, and called from C<DESTROY>.
The library holds 32 handles at a time, so a loop that forgets will notice.

=cut

sub close {
    my ($self) = @_;
    if ($self->{handle}) {
        my $handle = $self->{handle};
        $self->{handle} = 0;
        licdf_close($handle);
    }
    return;
}

sub DESTROY {
    my ($self) = @_;
    local ($@, $!);
    eval { $self->close };    # a destructor must not die
    return;
}

=head2 last_error_detail

The SDK's diagnostic detail for the most recent failure. Log it; do not parse it.

=cut

sub last_error_detail {
    my ($self) = @_;
    my $buffer = "\0" x 256;
    my ($ptr, $size) = scalar_to_buffer $buffer;
    return '' unless licdf_last_error($self->_handle, $ptr, $size) == 0;
    return unpack 'Z*', $buffer;
}

=head2 set_trust_root

Overrides the CA root that C<verify_genuine> checks against. Applications do not
need this: a release build embeds the KeyNub production root. It exists for
dongles provisioned against a different CA, and for vendor tooling.

=cut

sub set_trust_root {
    my ($self, $der) = @_;
    my $copy = defined $der ? $der : '';
    my ($ptr, $size) = scalar_to_buffer $copy;
    $self->_check(licdf_set_trust_root($self->_handle, $size ? $ptr : undef, $size),
                  'licdf_set_trust_root');
    return;
}

# --- plaintext info ---------------------------------------------------------

=head2 serial

The dongle serial as hex.

=cut

sub serial {
    my ($self) = @_;
    my $buffer = "\0" x 15;
    my ($ptr, $size) = scalar_to_buffer $buffer;
    $self->_check(licdf_get_serial($self->_handle, $ptr, $size), 'licdf_get_serial');
    return unpack 'Z*', $buffer;
}

=head2 info

A hashref of the plaintext device info. C<watchdog_reboot> means the dongle's
I<previous> boot ended in a watchdog timeout: the firmware hung and reset itself.
It is the only trace a field hang leaves behind, and a power cycle clears it, so
log it.

=cut

sub info {
    my ($self) = @_;
    my @out = (0) x 8;
    $self->_check(
        licdf_get_info($self->_handle, map { \$out[$_] } 0 .. 7),
        'licdf_get_info'
    );
    my ($pmaj, $pmin, $fmaj, $fmin, $fpat, $flags, $capacity, $free) = @out;
    return {
        protocol_version => [ $pmaj, $pmin ],
        firmware_version => [ $fmaj, $fmin, $fpat ],
        se_ready      => ($flags & $FLAG_SE_READY)     ? 1 : 0,
        provisioned      => ($flags & $FLAG_PROVISIONED)     ? 1 : 0,
        watchdog_reboot  => ($flags & $FLAG_WATCHDOG_REBOOT) ? 1 : 0,
        isolated         => ($flags & $FLAG_ISOLATED)        ? 1 : 0,
        writeauth_rotated => ($flags & $FLAG_WRITEAUTH_ROTATED) ? 1 : 0,
        data_capacity    => $capacity,
        data_free        => $free,
    };
}

=head2 verify_genuine

Proves authenticity: the certificate chain to the trusted root plus a live ECDSA
challenge-response. Dies unless the dongle is genuine; returns a hashref with
C<genuine> and C<serial>.

=cut

sub verify_genuine {
    my ($self) = @_;
    my $genuine = 0;
    my $serial = "\0" x 15;
    my ($sptr, $ssize) = scalar_to_buffer $serial;
    my $date = "\0" x 11;
    my ($dptr, $dsize) = scalar_to_buffer $date;
    $self->_check(
        licdf_verify_genuine($self->_handle, \$genuine, $sptr, $ssize, $dptr, $dsize),
        'licdf_verify_genuine'
    );
    _throw($STATUS{NOT_GENUINE}, 'licdf_verify_genuine') unless $genuine;
    return {
        genuine          => 1,
        serial           => unpack('Z*', $serial),
        provisioned_date => unpack('Z*', $date),
    };
}

=head2 is_genuine

The non-dying form, for a licence gate. B<Fails closed>: a missing dongle, an I/O
error and an invalid certificate all return false.

=cut

sub is_genuine {
    my ($self) = @_;
    my $ok = eval { $self->verify_genuine; 1 };
    return $ok ? 1 : 0;
}

# --- session ----------------------------------------------------------------

=head2 session_open / session_close

Opens and ends the encrypted session (P-256 ECDH, HKDF-SHA256, AES-256-GCM).

=cut

sub session_open {
    my ($self) = @_;
    $self->_check(licdf_session_open($self->_handle), 'licdf_session_open');
    $self->{session} = 1;
    return;
}

sub session_close {
    my ($self) = @_;
    if ($self->{session} && $self->{handle}) {
        $self->{session} = 0;
        licdf_session_close($self->{handle});
    }
    return;
}

sub _in_session {
    my ($self) = @_;
    croak 'no session is open; call session_open first' unless $self->{session};
    return $self->_handle;
}

=head2 authorize_write

Elevates to the write role with the developer master key (a DER EC private key).
This belongs in your licence-issuing tooling; never ship that key
in the application your users run.

=cut

sub authorize_write {
    my ($self, $der) = @_;
    my $copy = $der;
    my ($ptr, $size) = scalar_to_buffer $copy;
    $self->_check(licdf_write_auth($self->_in_session, $ptr, $size), 'licdf_write_auth');
    return;
}

=head2 rotate_write_key($new_key_der)

Replaces the dongle's write-auth key with your own (a DER EC private key). Call
C<authorize_write> with the current key first. From the next session on, only the
new key elevates.

=cut

sub rotate_write_key {
    my ($self, $der) = @_;
    my $copy = $der;
    my ($ptr, $size) = scalar_to_buffer $copy;
    $self->_check(licdf_write_auth_rotate($self->_in_session, $ptr, $size),
                  'licdf_write_auth_rotate');
    return;
}

# --- records ----------------------------------------------------------------

=head2 records

An arrayref of C<{ name, size }> hashrefs.

=cut

sub records {
    my ($self) = @_;
    my $handle = $self->_in_session;
    my $count = 0;
    $self->_check(licdf_record_count($handle, \$count), 'licdf_record_count');
    my @out;
    for my $index (0 .. $count - 1) {
        my $buffer = "\0" x 64;
        my ($ptr, $size) = scalar_to_buffer $buffer;
        my $record_size = 0;
        $self->_check(licdf_record_name($handle, $index, $ptr, $size, \$record_size),
                      'licdf_record_name');
        push @out, { name => unpack('Z*', $buffer), size => $record_size };
    }
    return \@out;
}

=head2 read_record

    my $data = $dongle->read_record('license');

Two calls under the hood: the flat API answers a zero-capacity read with
C<RANGE> and the size needed, so nothing has to guess a buffer size.

=cut

sub read_record {
    my ($self, $name) = @_;
    croak 'the record name must not be empty' unless defined $name && length $name;
    my $handle = $self->_in_session;

    my $needed = 0;
    my $probe = "\0";
    my ($pptr) = scalar_to_buffer $probe;
    my $status = licdf_record_read($handle, $name, $pptr, 0, \$needed);
    $self->_check($status, 'licdf_record_read')
        if $status != 0 && $status != $STATUS{RANGE};
    return '' if $needed == 0;

    my $data = "\0" x $needed;
    my ($ptr, $size) = scalar_to_buffer $data;
    my $got = 0;
    $self->_check(licdf_record_read($handle, $name, $ptr, $size, \$got),
                  'licdf_record_read');
    return substr $data, 0, $got;
}

=head2 write_record

Atomically replaces a record. Requires the write role.

=cut

sub write_record {
    my ($self, $name, $data) = @_;
    croak 'the record name must not be empty' unless defined $name && length $name;
    my $copy = defined $data ? $data : '';
    my ($ptr, $size) = scalar_to_buffer $copy;
    $self->_check(licdf_record_write($self->_in_session, $name, $size ? $ptr : undef, $size),
                  'licdf_record_write');
    return;
}

=head2 erase_record / erase_all_records

Erasing everything is a separate method on purpose: in the C API a null name means
"erase every record", and an accidentally empty Perl variable must not do that.

=cut

sub erase_record {
    my ($self, $name) = @_;
    croak 'the record name must not be empty; use erase_all_records'
        unless defined $name && length $name;
    $self->_check(licdf_record_erase($self->_in_session, $name), 'licdf_record_erase');
    return;
}

sub erase_all_records {
    my ($self) = @_;
    $self->_check(licdf_record_erase_all($self->_in_session), 'licdf_record_erase_all');
    return;
}

# --- counters ---------------------------------------------------------------

=head2 read_counter / increment_counter

Hardware monotonic counters. Incrementing is irreversible and needs the write role.

=cut

sub read_counter {
    my ($self, $id) = @_;
    my $value = 0;
    $self->_check(licdf_counter_read($self->_in_session, $id, \$value), 'licdf_counter_read');
    return $value;
}

sub increment_counter {
    my ($self, $id) = @_;
    my $value = 0;
    $self->_check(licdf_counter_increment($self->_in_session, $id, \$value),
                  'licdf_counter_increment');
    return $value;
}

# --- app-data envelope encryption -------------------------------------------

=head2 app_encrypt / app_decrypt

    my $blob = $dongle->app_encrypt($SCOPE_DEVELOPER, $plaintext);
    my $data = $dongle->app_decrypt($blob);

The pair to build a licence check on: put something the program genuinely needs
through it, so removing the check removes the data. C<$SCOPE_DEVELOPER> lets any
dongle you have issued decrypt, so one blob ships to every customer;
C<$SCOPE_DEVICE> locks it to one dongle.

=cut

sub _two_call {
    my ($self, $operation, $call) = @_;
    my $needed = 0;
    my $probe = "\0";
    my ($pptr) = scalar_to_buffer $probe;
    my $status = $call->($pptr, 0, \$needed);
    $self->_check($status, $operation) if $status != 0 && $status != $STATUS{RANGE};
    return '' if $needed == 0;

    my $out = "\0" x $needed;
    my ($ptr, $size) = scalar_to_buffer $out;
    my $got = 0;
    $self->_check($call->($ptr, $size, \$got), $operation);
    return substr $out, 0, $got;
}

sub app_encrypt {
    my ($self, $scope, $plaintext) = @_;
    croak 'scope must be 0 (device) or 1 (developer)'
        unless defined $scope && ($scope == $SCOPE_DEVICE || $scope == $SCOPE_DEVELOPER);
    my $handle = $self->_in_session;
    my $copy = defined $plaintext ? $plaintext : '';
    my ($inPtr, $inSize) = scalar_to_buffer $copy;
    return $self->_two_call('licdf_app_encrypt', sub {
        my ($ptr, $size, $lenRef) = @_;
        licdf_app_encrypt($handle, $scope, $inSize ? $inPtr : undef, $inSize,
                          $ptr, $size, $lenRef);
    });
}

sub app_decrypt {
    my ($self, $packed) = @_;
    my $handle = $self->_in_session;
    my $copy = defined $packed ? $packed : '';
    my ($inPtr, $inSize) = scalar_to_buffer $copy;
    return $self->_two_call('licdf_app_decrypt', sub {
        my ($ptr, $size, $lenRef) = @_;
        licdf_app_decrypt($handle, $inSize ? $inPtr : undef, $inSize,
                          $ptr, $size, $lenRef);
    });
}

1;

__END__

=head1 LICENSE

Apache-2.0, like the rest of the SDK.

=cut
