use strict;
use warnings;

use 5.008003;
use ExtUtils::MakeMaker;

use Config;
use Env;

if ($Config{ivsize} < 8 || $Config{uvsize} < 8) {
    die "Lab::Zhinst needs a perl with 64-bit integer support.\n" .
        "Make sure that perl has use64bitint defined."
}

my $os = $Config{osname};
my $arch = $Config{ptrsize} >= 8 ? '64' : '32';

my $libs = '';
my $inc = '-I. ';

if ($os eq 'linux') {
    my @lib_dirs;
    my $library_path = $ENV{LIBRARY_PATH};
    if ($library_path) {
        @lib_dirs = (split ':', $library_path);
        @lib_dirs = map "-L$_", @lib_dirs;
        $libs  .= join ' ', @lib_dirs;
    }
    
    $libs .= " -lziAPI-linux${arch}";
}
elsif ($os eq 'MSWin32') {
    $libs = '"-lC:\\Program Files\\Zurich Instruments\\LabOne\\API\\C\\lib\\'
        . "ziAPI-win${arch}.lib" . '"';
    $inc .=
        '"-IC:\\Program Files\\Zurich Instruments\\LabOne\\API\\C\\include"';
}
else {
    die "Unknown os $os";
}

WriteMakefile(
    ABSTRACT_FROM => 'lib/Lab/Zhinst.pm',
    AUTHOR => "Simon Reinhardt <simon.reinhardt\@stud.uni-regensburg.de>",
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 0
    },
    DISTNAME => "Lab-Zhinst",
    LICENSE => "perl",
    MIN_PERL_VERSION => "5.008003",
    NAME => "Lab::Zhinst",
    PREREQ_PM => {
        "AutoLoader" => 0,
        "Carp" => 0,
        "Exporter" => 0,
        "XSLoader" => 0,
        "strict" => 0,
        "warnings" => 0
    },
    TEST_REQUIRES => {
        "Test::More" => 0
    },
    VERSION_FROM => 'lib/Lab/Zhinst.pm',
    LIBS => [$libs],
    INC => $inc,
    CCFLAGS => "$Config{ccflags} -Wall -Wno-deprecated-declarations",
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'http://www.labmeasurement.de',
            repository => {
                type => 'git',
                url => 'git://github.com/lab-measurement/Lab-Zhinst.git',
                web => 'https://github.com/lab-measurement/Lab-Zhinst',
            },
            x_MailingList => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-measurement-users',
            x_IRC => 'irc://chat.freenode.net/#labmeasurement',
        }
    }
    );

use ExtUtils::Constant;

# If you edit these definitions to change the constants used by this module,
# you will need to use the generated const-c.inc and const-xs.inc
# files to replace their "fallback" counterparts before distributing your
# changes.
my @names = (qw(MAX_EVENT_SIZE MAX_NAME_LEN MAX_PATH_LEN),
             {name=>"TREE_ACTION_ADD", macro=>"1"},
             {name=>"TREE_ACTION_CHANGE", macro=>"1"},
             {name=>"ZI_API_VERSION_0", macro=>"1"},
             {name=>"ZI_API_VERSION_1", macro=>"1"},
             {name=>"ZI_API_VERSION_4", macro=>"1"},
             {name=>"ZI_API_VERSION_5", macro=>"1"},
             {name=>"ZI_COMMAND", macro=>"1"},
             {name=>"ZI_CONNECTION", macro=>"1"},
             {name=>"ZI_DATA_AUXINSAMPLE", macro=>"1"},
             {name=>"ZI_DATA_BYTEARRAY", macro=>"1"},
             {name=>"ZI_DATA_DEMODSAMPLE", macro=>"1"},
             {name=>"ZI_DATA_DIOSAMPLE", macro=>"1"},
             {name=>"ZI_DATA_DOUBLE", macro=>"1"},
             {name=>"ZI_DATA_INTEGER", macro=>"1"},
             {name=>"ZI_DATA_NONE", macro=>"1"},
             {name=>"ZI_DATA_SCOPEWAVE", macro=>"1"},
             {name=>"ZI_DATA_TREE_CHANGED", macro=>"1"},
             {name=>"ZI_DUPLICATE", macro=>"1"},
             {name=>"ZI_ERROR", macro=>"1"},
             {name=>"ZI_ERROR_BASE", macro=>"1"},
             {name=>"ZI_ERROR_COMMAND", macro=>"1"},
             {name=>"ZI_ERROR_CONNECTION", macro=>"1"},
             {name=>"ZI_ERROR_DEVICE_CONNECTION_TIMEOUT", macro=>"1"},
             {name=>"ZI_ERROR_DEVICE_DIFFERENT_INTERFACE", macro=>"1"},
             {name=>"ZI_ERROR_DEVICE_INTERFACE", macro=>"1"},
             {name=>"ZI_ERROR_DEVICE_IN_USE", macro=>"1"},
             {name=>"ZI_ERROR_DEVICE_NEEDS_FW_UPGRADE", macro=>"1"},
             {name=>"ZI_ERROR_DEVICE_NOT_FOUND", macro=>"1"},
             {name=>"ZI_ERROR_DEVICE_NOT_VISIBLE", macro=>"1"},
             {name=>"ZI_ERROR_DUPLICATE", macro=>"1"},
             {name=>"ZI_ERROR_FILE", macro=>"1"},
             {name=>"ZI_ERROR_GENERAL", macro=>"1"},
             {name=>"ZI_ERROR_HOSTNAME", macro=>"1"},
             {name=>"ZI_ERROR_LENGTH", macro=>"1"},
             {name=>"ZI_ERROR_MALLOC", macro=>"1"},
             {name=>"ZI_ERROR_MAX", macro=>"1"},
             {name=>"ZI_ERROR_MUTEX_DESTROY", macro=>"1"},
             {name=>"ZI_ERROR_MUTEX_INIT", macro=>"1"},
             {name=>"ZI_ERROR_MUTEX_LOCK", macro=>"1"},
             {name=>"ZI_ERROR_MUTEX_UNLOCK", macro=>"1"},
             {name=>"ZI_ERROR_NOT_SUPPORTED", macro=>"1"},
             {name=>"ZI_ERROR_READONLY", macro=>"1"},
             {name=>"ZI_ERROR_SERVER_INTERNAL", macro=>"1"},
             {name=>"ZI_ERROR_SOCKET_CONNECT", macro=>"1"},
             {name=>"ZI_ERROR_SOCKET_INIT", macro=>"1"},
             {name=>"ZI_ERROR_THREAD_JOIN", macro=>"1"},
             {name=>"ZI_ERROR_THREAD_START", macro=>"1"},
             {name=>"ZI_ERROR_TIMEOUT", macro=>"1"},
             {name=>"ZI_ERROR_TOO_MANY_CONNECTIONS", macro=>"1"},
             {name=>"ZI_ERROR_USB", macro=>"1"},
             {name=>"ZI_ERROR_ZIEVENT_DATATYPE_MISMATCH", macro=>"1"},
             {name=>"ZI_FILE", macro=>"1"},
             {name=>"ZI_HOSTNAME", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_AUTORANGE_GATING", macro=>"1"},
             # {name=>"ZI_IMP_FLAGS_BWC_BIT0", macro=>"1"}, removed in LabOne 20.07 ...
             {name=>"ZI_IMP_FLAGS_BWC_BIT1", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_BWC_BIT2", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_BWC_BIT3", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_BWC_MASK", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_FREQLIMIT_RANGE_CURRENT", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_FREQLIMIT_RANGE_VOLTAGE", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_FREQ_EXACT", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_FREQ_EXTRAPOLATION", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_FREQ_INTERPOLATION", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_NEGATIVE_QFACTOR", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_NONE", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_OPEN_DETECTION", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_OVERFLOW_CURRENT", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_OVERFLOW_VOLTAGE", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_STRONGCOMPENSATION_PARAM0", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_STRONGCOMPENSATION_PARAM1", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_SUPPRESSION_PARAM0", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_SUPPRESSION_PARAM1", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_UNDERFLOW_CURRENT", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_UNDERFLOW_VOLTAGE", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_VALID_INTERNAL", macro=>"1"},
             {name=>"ZI_IMP_FLAGS_VALID_USER", macro=>"1"},
             {name=>"ZI_INFO_BASE", macro=>"1"},
             {name=>"ZI_INFO_MAX", macro=>"1"},
             {name=>"ZI_INFO_SUCCESS", macro=>"1"},
             {name=>"ZI_LENGTH", macro=>"1"},
             {name=>"ZI_LIST_ABSOLUTE", macro=>"1"},
             {name=>"ZI_LIST_LEAFSONLY", macro=>"1"},
             {name=>"ZI_LIST_NODES_ABSOLUTE", macro=>"1"},
             {name=>"ZI_LIST_NODES_LEAFSONLY", macro=>"1"},
             {name=>"ZI_LIST_NODES_NONE", macro=>"1"},
             {name=>"ZI_LIST_NODES_RECURSIVE", macro=>"1"},
             {name=>"ZI_LIST_NODES_SETTINGSONLY", macro=>"1"},
             {name=>"ZI_LIST_NONE", macro=>"1"},
             {name=>"ZI_LIST_RECURSIVE", macro=>"1"},
             {name=>"ZI_LIST_SETTINGSONLY", macro=>"1"},
             {name=>"ZI_MALLOC", macro=>"1"},
             {name=>"ZI_MAX_ERROR", macro=>"1"},
             {name=>"ZI_MAX_INFO", macro=>"1"},
             {name=>"ZI_MAX_WARNING", macro=>"1"},
             {name=>"ZI_MUTEX_DESTROY", macro=>"1"},
             {name=>"ZI_MUTEX_INIT", macro=>"1"},
             {name=>"ZI_MUTEX_LOCK", macro=>"1"},
             {name=>"ZI_MUTEX_UNLOCK", macro=>"1"},
             {name=>"ZI_NOTFOUND", macro=>"1"},
             {name=>"ZI_OVERFLOW", macro=>"1"},
             {name=>"ZI_READONLY", macro=>"1"},
             {name=>"ZI_SERVER_INTERNAL", macro=>"1"},
             {name=>"ZI_SOCKET_CONNECT", macro=>"1"},
             {name=>"ZI_SOCKET_INIT", macro=>"1"},
             {name=>"ZI_SUCCESS", macro=>"1"},
             {name=>"ZI_THREAD_JOIN", macro=>"1"},
             {name=>"ZI_THREAD_START", macro=>"1"},
             {name=>"ZI_TIMEOUT", macro=>"1"},
             {name=>"ZI_TREE_ACTION_ADD", macro=>"1"},
             {name=>"ZI_TREE_ACTION_CHANGE", macro=>"1"},
             {name=>"ZI_TREE_ACTION_REMOVE", macro=>"1"},
             {name=>"ZI_UNDERRUN", macro=>"1"},
             {name=>"ZI_USB", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_ADVISOR_WAVE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_ASYNC_REPLY", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_AUXIN_SAMPLE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_BYTE_ARRAY", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_BYTE_ARRAY_TS", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_CNT_SAMPLE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_DEMOD_SAMPLE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_DIO_SAMPLE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_DOUBLE_DATA", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_DOUBLE_DATA_TS", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_IMPEDANCE_SAMPLE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_INTEGER_DATA", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_INTEGER_DATA_TS", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_NONE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_PWA_WAVE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_SCOPE_WAVE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_SCOPE_WAVE_EX", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_SCOPE_WAVE_OLD", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_SPECTRUM_WAVE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_SWEEPER_WAVE", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_TREE_CHANGE_DATA", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_TREE_CHANGE_DATA_OLD", macro=>"1"},
             {name=>"ZI_VALUE_TYPE_VECTOR_DATA", macro=>"1"},
             {name=>"ZI_VECTOR_ELEMENT_TYPE_ASCIIZ", macro=>"1"},
             {name=>"ZI_VECTOR_ELEMENT_TYPE_DOUBLE", macro=>"1"},
             {name=>"ZI_VECTOR_ELEMENT_TYPE_FLOAT", macro=>"1"},
             {name=>"ZI_VECTOR_ELEMENT_TYPE_UINT16", macro=>"1"},
             {name=>"ZI_VECTOR_ELEMENT_TYPE_UINT32", macro=>"1"},
             {name=>"ZI_VECTOR_ELEMENT_TYPE_UINT64", macro=>"1"},
             {name=>"ZI_VECTOR_ELEMENT_TYPE_UINT8", macro=>"1"},
           # removed in 19.05
           # {name=>"ZI_VECTOR_WRITE_STATUS_IDLE", macro=>"1"},
           # {name=>"ZI_VECTOR_WRITE_STATUS_PENDING", macro=>"1"},
             {name=>"ZI_WARNING", macro=>"1"},
             {name=>"ZI_WARNING_BASE", macro=>"1"},
             {name=>"ZI_WARNING_GENERAL", macro=>"1"},
             {name=>"ZI_WARNING_MAX", macro=>"1"},
             {name=>"ZI_WARNING_NOTFOUND", macro=>"1"},
             {name=>"ZI_WARNING_NO_ASYNC", macro=>"1"},
             {name=>"ZI_WARNING_OVERFLOW", macro=>"1"},
             {name=>"ZI_WARNING_UNDERRUN", macro=>"1"},
    );

ExtUtils::Constant::WriteConstants(
    NAME         => 'Lab::Zhinst',
    NAMES        => \@names,
    DEFAULT_TYPE => 'IV',
    C_FILE       => 'const-c.inc',
    XS_FILE      => 'const-xs.inc',
    );
