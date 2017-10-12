=head1 NAME

Lab::Zhinst - Perl bindings to the LabOne API of Zurich Instruments 

=head1 SYNOPSIS

 use Lab::Zhinst;
 
 ####################################################

 # LabOne's "Getting Started" example in Perl:

 # Create connection object
 my ($rv, $connection) = Lab::Zhinst->Init();
 if ($rv) {
     # handle error ...
 }
 # Connect to DataServer at localhost, port 8004.
 ($rv)  = $connection->Connect("localhost", 8004);

 # Set all demodulator rates of device dev1046 to 150 Hz.
 my ($rv) = $connection->SetValueD("/dev1046/demods/*/rate", 150);

 ####################################################

 # Read x and y value from the Lock-In demodulator:

 my $device = "/dev3281";
 my ($rv, $hash_ref) = $connection->GetDemodSample("$device/DEMODS/0/SAMPLE");
 printf("x = %g, y = %g\n", $hash_ref->{x}, $hash_ref->{y});

=head1 INSTALLATION

=head2 Linux

=over

=item *

Download the LabOne API for Linux from L<https://www.zhinst.com>.

=item *

After unpacking, copy the header F<API/C/include/ziAPI.h> and the library
F<API/C/lib/ziAPI-linux64.so> into directories searched by the compiler and
linker (e.g. /usr/local/include and /usr/local/lib).

=item *

Use your favourite cpan client to install Lab::Zhinst.

=back

=head3 Non-root installation in home directory

you will need something like e.g. L<local::lib>, 
L<plenv|https://github.com/tokuhirom/plenv> or
L<perlbrew|https://perlbrew.pl/>.

Add the directory which contains the shared library to the B<LIBRARY_PATH> and
B<LD_LIBRARY_PATH> environment variables and add the directory which contains
the header F<ziAPI.h> to the B<CPATH> environment variable.

You can then install Lab::Zhinst with your favourite cpan client.

See our L<Travis CI build
file|https://github.com/lab-measurement/Lab-Zhinst/blob/master/.travis.yml>
for the exact list of needed commands.

=head2 Windows

=over

=item *

Make sure that you have a 32-bit version of StrawberryPerl 5.20 or 5.18.
It is currently not possible to use other versions (see L<https://rt.cpan.org/Public/Bug/Display.html?id=121219>).

=item *

Download and install the LabOne API for Windows (MSI installer).

=item *

Make sure that the library directory
F<C:\Program Files\Zurich Instruments\LabOne\API\C\lib> is included in the PATH
environment variable. Otherwise loading the dynamic library F<Zhinst.xs.dll>
will fail.

=item *

Use your favourite cpan client to install Lab::Zhinst.

=back

=head1 API CONSIDERATIONS

The API provided by this module is basically a one-one mapping of the LabOne
C API to Perl5.

For full semantics of the various library functions, we refer to the
L<LabOne manual|https://www.zhinst.com/manuals/programming>.

=head2 Object orientation

Most ziAPI functions receive a ZIConnection as their first argument. The C<Init>
method of this library will create a ZIConnection object and bless it into the
Lab::Zhinst class. Most library functions are then called on this Lab::Zhinst
object.

=head2 Return values and error handling

Most ziAPI functions return an error code. The Perl functions return lists,
where the first element is the error code:

 my ($error_code, $first_return_value, $second_return_value) = $connection->foobar(@arguments);

The return values are only valid if C<$error_code> is 0.

=head1 FUNCTIONS/METHODS

All non-methods are exported by default.

=head2 Connecting to Data Server

=head3 Init

 my ($rv, $connection) = Lab::Zhinst->Init();

Return Lab::Zhinst object. Automatically call C<ziAPIDestroy> on C<$connection>
when it goes out of scope.

=head3 Connect

 my ($rv) = $connection->Connect($hostname, $port);

=head3 Disconnect

 my ($rv) = $connection->Disconnect();

=head3 ziAPIListImplementations

 my ($rv, $implementations) = ziAPIListImplementations();

=head3 GetConnectionAPILevel

 my ($rv, $level) = $connection->GetConnectionAPILevel();

=head2 Tree

=head3 ListNodes

 my ($rv, $nodes) = $connection->ListNodes($path, $bufferSize, $flags);

C<$flags> has to be bitwise or of ZI_LIST_NODES_NONE, ZI_LIST_NODES_RECURSIVE,
ZI_LIST_NODES_ABSOLUTE, ZI_LIST_NODES_LEAFSONLY, ZI_LIST_NODES_SETTINGSONLY.

=head2 Set and Get Parameters

=head3 GetValueD

 my ($rv, $double) = $connection->GetValueD($path);

=head3 GetValueI

 my ($rv, $integer) = $connection->GetValueI($path);
 

=head3 GetDemodSample

 my ($rv, $hash_ref) = $connection->GetDemodSample($path);
 # keys: timeStamp, x, y, frequency, phase, dioBits, trigger, auxIn0, auxIn1

=head3 GetDIOSample

 my ($rv, $hash_ref) = $connection->GetDIOSample($path);
 # keys: timeStamp, bits, reserved

=head3 GetAuxInSample

 my ($rv, $hash_ref) = $connection->GetAuxInSample($path);
 # keys: timeStamp, ch0, ch1

=head3 GetValueB

 my ($rv, $byte_string) = $connection->GetValueB($path, $bufferSize);

=head3 SetValueD

 my ($rv) = $connection->SetValueD($path, $double);

=head3 SetValueI

 my ($rv) = $connection->SetValueI($path, $integer);

=head3 SetValueB

 my ($rv) = $connection->SetValueB($path, $byte_string);

=head3 SyncSetValueD

 my ($rv, $set_value) = $connection->SyncSetValueD($path, $double);

=head3 SyncSetValueI

 my ($rv, $set_value) = $connection->SyncSetValueI($path, $integer);

=head3 SyncSetValueB

 my ($rv, $set_value) = $connection->SyncSetValueB($path, $byte_array);

=head3 Sync

 my ($rv) = $connection->Sync();

=head3 EchoDevice

 my ($rv) = $connection->EchoDevice($device_serial);

=head2 Data Streaming

=head3 ziAPIAllocateEventEx

 my ($event) = ziAPIAllocateEventEx();

Return Lab::Zhinst::ZIEvent object or undef on error.

C<ziAPIDeallocateEventEx> will be called on C<$event> when it goes out of
scope.

=head3 Subscribe

 my ($rv) = $connection->Subscribe($path);

=head3 UnSubscribe

 my ($rv) = $connection->UnSubscribe($path);

=head3 PollDataEx

 my ($rv, $data) = $connection->PollDataEx($event, $timeout_milliseconds);

C<$data> holds a hashref representing a 'struct ZIEvent'. It has the following
structure:

 $data = {
     valueType => $valueType,
     count     => $count,
     path      => $path,
     values    => [@values],
 };

For scalar data like ZIDoubleData, the elements of C<@values> are scalars. For
Samples (Demod, AuxIn, DIO, Impedance, ...) the elements are hashrefs.

=head3 GetValueAsPollData

 my ($rv) = $connection->GetValueAsPollData($path);



=head2 Error Handling and Logging in the LabOne C API

=head3 ziAPIGetError

 my ($rv, $error_string) = ziAPIGetError($result);

=head3 GetLastError

 my ($rv, $error_string) = $connection->GetLastError($bufferSize);

=head3 ziAPISetDebugLevel

 ziAPISetDebugLevel($level);

=head3 ziAPIWriteDebugLog

 ziAPIWriteDebugLog($level, $message);

=head2 Device discovery

=head3 DiscoveryFind

 my ($rv, $device_id) = $connection->DiscoveryFind($device_address);

=head3 DiscoveryGet

 my ($rv, $json) = $connection->DiscoveryGet($device_id);

=head1 REPORTING BUGS

Please report bugs at L<https://github.com/lab-measurement/Lab-Zhinst/issues>.

=head1 CONTACT

Feel free to contact us at

=over

=item * The #labmeasurement channel on Freenode IRC.

=item * Our L<mailing list|https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-measurement-users>.

=back

=head1 SEE ALSO

=over

=item * L<Blog post on Lab::Zhinst|http://blogs.perl.org/users/simon_reinhardt/2017/04/test.html>

=item * L<Lab::Measurement>

=item * L<USB::TMC>

=item * L<Lab::VXI11>

=item * L<Lab::VISA>

=back

=head1 AUTHOR

Simon Reinhardt, E<lt>simon.reinhardt@stud.uni-regensburg.deE<gt>

=head1 COPYRIGHT AND LICENSE

The following license only covers the perl front end to LabOne. LabOne uses
different licensing terms, and needs to be installed separately by the user.

Copyright (C) 2017 by Simon Reinhardt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.

=cut


package Lab::Zhinst;

use strict;
use warnings;
use Carp;
require Exporter;
use AutoLoader;

our $VERSION = '1.02';
our @ISA = qw(Exporter);

our @EXPORT = qw(
    ziAPIListImplementations
    ziAPIAllocateEventEx
    ziAPIGetError
    ziAPISetDebugLevel
    ziAPIWriteDebugLog
    
    MAX_EVENT_SIZE
	MAX_NAME_LEN
	MAX_PATH_LEN
	TREE_ACTION_ADD
	TREE_ACTION_CHANGE
	ZI_API_VERSION_0
	ZI_API_VERSION_1
	ZI_API_VERSION_4
	ZI_API_VERSION_5
	ZI_COMMAND
	ZI_CONNECTION
	ZI_DATA_AUXINSAMPLE
	ZI_DATA_BYTEARRAY
	ZI_DATA_DEMODSAMPLE
	ZI_DATA_DIOSAMPLE
	ZI_DATA_DOUBLE
	ZI_DATA_INTEGER
	ZI_DATA_NONE
	ZI_DATA_SCOPEWAVE
	ZI_DATA_TREE_CHANGED
	ZI_DUPLICATE
	ZI_ERROR
	ZI_ERROR_BASE
	ZI_ERROR_COMMAND
	ZI_ERROR_CONNECTION
	ZI_ERROR_DEVICE_CONNECTION_TIMEOUT
	ZI_ERROR_DEVICE_DIFFERENT_INTERFACE
	ZI_ERROR_DEVICE_INTERFACE
	ZI_ERROR_DEVICE_IN_USE
	ZI_ERROR_DEVICE_NEEDS_FW_UPGRADE
	ZI_ERROR_DEVICE_NOT_FOUND
	ZI_ERROR_DEVICE_NOT_VISIBLE
	ZI_ERROR_DUPLICATE
	ZI_ERROR_FILE
	ZI_ERROR_GENERAL
	ZI_ERROR_HOSTNAME
	ZI_ERROR_LENGTH
	ZI_ERROR_MALLOC
	ZI_ERROR_MAX
	ZI_ERROR_MUTEX_DESTROY
	ZI_ERROR_MUTEX_INIT
	ZI_ERROR_MUTEX_LOCK
	ZI_ERROR_MUTEX_UNLOCK
	ZI_ERROR_NOT_SUPPORTED
	ZI_ERROR_READONLY
	ZI_ERROR_SERVER_INTERNAL
	ZI_ERROR_SOCKET_CONNECT
	ZI_ERROR_SOCKET_INIT
	ZI_ERROR_THREAD_JOIN
	ZI_ERROR_THREAD_START
	ZI_ERROR_TIMEOUT
	ZI_ERROR_TOO_MANY_CONNECTIONS
	ZI_ERROR_USB
	ZI_ERROR_ZIEVENT_DATATYPE_MISMATCH
	ZI_FILE
	ZI_GENERIC_HEADER_FLAG_DATA
	ZI_GENERIC_HEADER_FLAG_DATALOSS
	ZI_GENERIC_HEADER_FLAG_DISPLAY
	ZI_GENERIC_HEADER_FLAG_FINISHED
	ZI_GENERIC_HEADER_FLAG_ROLLMODE
	ZI_GENERIC_HEADER_FLAG_VALID
	ZI_HOSTNAME
	ZI_IMP_FLAGS_AUTORANGE_GATING
	ZI_IMP_FLAGS_BWC_BIT0
	ZI_IMP_FLAGS_BWC_BIT1
	ZI_IMP_FLAGS_BWC_BIT2
	ZI_IMP_FLAGS_BWC_BIT3
	ZI_IMP_FLAGS_BWC_MASK
	ZI_IMP_FLAGS_FREQLIMIT_RANGE_CURRENT
	ZI_IMP_FLAGS_FREQLIMIT_RANGE_VOLTAGE
	ZI_IMP_FLAGS_FREQ_EXACT
	ZI_IMP_FLAGS_FREQ_EXTRAPOLATION
	ZI_IMP_FLAGS_FREQ_INTERPOLATION
	ZI_IMP_FLAGS_NEGATIVE_QFACTOR
	ZI_IMP_FLAGS_NONE
	ZI_IMP_FLAGS_OPEN_DETECTION
	ZI_IMP_FLAGS_OVERFLOW_CURRENT
	ZI_IMP_FLAGS_OVERFLOW_VOLTAGE
	ZI_IMP_FLAGS_STRONGCOMPENSATION_PARAM0
	ZI_IMP_FLAGS_STRONGCOMPENSATION_PARAM1
	ZI_IMP_FLAGS_SUPPRESSION_PARAM0
	ZI_IMP_FLAGS_SUPPRESSION_PARAM1
	ZI_IMP_FLAGS_UNDERFLOW_CURRENT
	ZI_IMP_FLAGS_UNDERFLOW_VOLTAGE
	ZI_IMP_FLAGS_VALID_INTERNAL
	ZI_IMP_FLAGS_VALID_USER
	ZI_INFO_BASE
	ZI_INFO_MAX
	ZI_INFO_SUCCESS
	ZI_LENGTH
	ZI_LIST_ABSOLUTE
	ZI_LIST_LEAFSONLY
	ZI_LIST_NODES_ABSOLUTE
	ZI_LIST_NODES_LEAFSONLY
	ZI_LIST_NODES_NONE
	ZI_LIST_NODES_RECURSIVE
	ZI_LIST_NODES_SETTINGSONLY
	ZI_LIST_NONE
	ZI_LIST_RECURSIVE
	ZI_LIST_SETTINGSONLY
	ZI_MALLOC
	ZI_MAX_ERROR
	ZI_MAX_INFO
	ZI_MAX_WARNING
	ZI_MODULE_HEADER_TYPE_GENERIC
	ZI_MODULE_HEADER_TYPE_NONE
	ZI_MODULE_HEADER_TYPE_SWEEPER
	ZI_MODULE_HEADER_TYPE_SWTRIGGER
	ZI_MUTEX_DESTROY
	ZI_MUTEX_INIT
	ZI_MUTEX_LOCK
	ZI_MUTEX_UNLOCK
	ZI_NOTFOUND
	ZI_OVERFLOW
	ZI_READONLY
	ZI_SERVER_INTERNAL
	ZI_SOCKET_CONNECT
	ZI_SOCKET_INIT
	ZI_SUCCESS
	ZI_THREAD_JOIN
	ZI_THREAD_START
	ZI_TIMEOUT
	ZI_TREE_ACTION_ADD
	ZI_TREE_ACTION_CHANGE
	ZI_TREE_ACTION_REMOVE
	ZI_UNDERRUN
	ZI_USB
	ZI_VALUE_TYPE_ADVISOR_WAVE
	ZI_VALUE_TYPE_ASYNC_REPLY
	ZI_VALUE_TYPE_AUXIN_SAMPLE
	ZI_VALUE_TYPE_BYTE_ARRAY
	ZI_VALUE_TYPE_BYTE_ARRAY_TS
	ZI_VALUE_TYPE_CNT_SAMPLE
	ZI_VALUE_TYPE_DEMOD_SAMPLE
	ZI_VALUE_TYPE_DIO_SAMPLE
	ZI_VALUE_TYPE_DOUBLE_DATA
	ZI_VALUE_TYPE_DOUBLE_DATA_TS
	ZI_VALUE_TYPE_IMPEDANCE_SAMPLE
	ZI_VALUE_TYPE_INTEGER_DATA
	ZI_VALUE_TYPE_INTEGER_DATA_TS
	ZI_VALUE_TYPE_NONE
	ZI_VALUE_TYPE_PWA_WAVE
	ZI_VALUE_TYPE_SCOPE_WAVE
	ZI_VALUE_TYPE_SCOPE_WAVE_EX
	ZI_VALUE_TYPE_SCOPE_WAVE_OLD
	ZI_VALUE_TYPE_SPECTRUM_WAVE
	ZI_VALUE_TYPE_SWEEPER_WAVE
	ZI_VALUE_TYPE_TREE_CHANGE_DATA
	ZI_VALUE_TYPE_TREE_CHANGE_DATA_OLD
	ZI_VALUE_TYPE_VECTOR_DATA
	ZI_VECTOR_ELEMENT_TYPE_ASCIIZ
	ZI_VECTOR_ELEMENT_TYPE_DOUBLE
	ZI_VECTOR_ELEMENT_TYPE_FLOAT
	ZI_VECTOR_ELEMENT_TYPE_UINT16
	ZI_VECTOR_ELEMENT_TYPE_UINT32
	ZI_VECTOR_ELEMENT_TYPE_UINT64
	ZI_VECTOR_ELEMENT_TYPE_UINT8
	ZI_VECTOR_WRITE_STATUS_IDLE
	ZI_VECTOR_WRITE_STATUS_PENDING
	ZI_WARNING
	ZI_WARNING_BASE
	ZI_WARNING_GENERAL
	ZI_WARNING_MAX
	ZI_WARNING_NOTFOUND
	ZI_WARNING_NO_ASYNC
	ZI_WARNING_OVERFLOW
	ZI_WARNING_UNDERRUN
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Lab::Zhinst::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Lab::Zhinst', $Lab::Zhinst::VERSION);

1;
__END__
