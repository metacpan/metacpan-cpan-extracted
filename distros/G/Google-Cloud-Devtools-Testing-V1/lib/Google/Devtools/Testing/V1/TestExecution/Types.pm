package Google::Devtools::Testing::V1::TestExecution::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OrchestratorOption',
    as (Int | Str);

declare 'RoboMode',
    as (Int | Str);

declare 'RoboActionType',
    as (Int | Str);

declare 'InvalidMatrixDetails',
    as (Int | Str);

declare 'TestState',
    as (Int | Str);

declare 'OutcomeSummary',
    as (Int | Str);

declare 'TestMatrix',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::TestMatrix'];

coerce 'TestMatrix',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::TestMatrix'->new($_) };

declare 'RepeatedTestMatrix',
    as ArrayRef[TestMatrix()];

coerce 'RepeatedTestMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::TestMatrix'->new($_) } @$_ ] };

declare 'MapStringTestMatrix',
    as HashRef[TestMatrix()];

declare 'MatrixErrorDetail',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::MatrixErrorDetail'];

coerce 'MatrixErrorDetail',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::MatrixErrorDetail'->new($_) };

declare 'RepeatedMatrixErrorDetail',
    as ArrayRef[MatrixErrorDetail()];

coerce 'RepeatedMatrixErrorDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::MatrixErrorDetail'->new($_) } @$_ ] };

declare 'MapStringMatrixErrorDetail',
    as HashRef[MatrixErrorDetail()];

declare 'TestExecution',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::TestExecution'];

coerce 'TestExecution',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::TestExecution'->new($_) };

declare 'RepeatedTestExecution',
    as ArrayRef[TestExecution()];

coerce 'RepeatedTestExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::TestExecution'->new($_) } @$_ ] };

declare 'MapStringTestExecution',
    as HashRef[TestExecution()];

declare 'TestSpecification',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::TestSpecification'];

coerce 'TestSpecification',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::TestSpecification'->new($_) };

declare 'RepeatedTestSpecification',
    as ArrayRef[TestSpecification()];

coerce 'RepeatedTestSpecification',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::TestSpecification'->new($_) } @$_ ] };

declare 'MapStringTestSpecification',
    as HashRef[TestSpecification()];

declare 'SystraceSetup',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::SystraceSetup'];

coerce 'SystraceSetup',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::SystraceSetup'->new($_) };

declare 'RepeatedSystraceSetup',
    as ArrayRef[SystraceSetup()];

coerce 'RepeatedSystraceSetup',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::SystraceSetup'->new($_) } @$_ ] };

declare 'MapStringSystraceSetup',
    as HashRef[SystraceSetup()];

declare 'TestSetup',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::TestSetup'];

coerce 'TestSetup',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::TestSetup'->new($_) };

declare 'RepeatedTestSetup',
    as ArrayRef[TestSetup()];

coerce 'RepeatedTestSetup',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::TestSetup'->new($_) } @$_ ] };

declare 'MapStringTestSetup',
    as HashRef[TestSetup()];

declare 'IosTestSetup',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::IosTestSetup'];

coerce 'IosTestSetup',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::IosTestSetup'->new($_) };

declare 'RepeatedIosTestSetup',
    as ArrayRef[IosTestSetup()];

coerce 'RepeatedIosTestSetup',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::IosTestSetup'->new($_) } @$_ ] };

declare 'MapStringIosTestSetup',
    as HashRef[IosTestSetup()];

declare 'EnvironmentVariable',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::EnvironmentVariable'];

coerce 'EnvironmentVariable',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::EnvironmentVariable'->new($_) };

declare 'RepeatedEnvironmentVariable',
    as ArrayRef[EnvironmentVariable()];

coerce 'RepeatedEnvironmentVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::EnvironmentVariable'->new($_) } @$_ ] };

declare 'MapStringEnvironmentVariable',
    as HashRef[EnvironmentVariable()];

declare 'Account',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::Account'];

coerce 'Account',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::Account'->new($_) };

declare 'RepeatedAccount',
    as ArrayRef[Account()];

coerce 'RepeatedAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::Account'->new($_) } @$_ ] };

declare 'MapStringAccount',
    as HashRef[Account()];

declare 'GoogleAuto',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::GoogleAuto'];

coerce 'GoogleAuto',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::GoogleAuto'->new($_) };

declare 'RepeatedGoogleAuto',
    as ArrayRef[GoogleAuto()];

coerce 'RepeatedGoogleAuto',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::GoogleAuto'->new($_) } @$_ ] };

declare 'MapStringGoogleAuto',
    as HashRef[GoogleAuto()];

declare 'Apk',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::Apk'];

coerce 'Apk',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::Apk'->new($_) };

declare 'RepeatedApk',
    as ArrayRef[Apk()];

coerce 'RepeatedApk',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::Apk'->new($_) } @$_ ] };

declare 'MapStringApk',
    as HashRef[Apk()];

declare 'AppBundle',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::AppBundle'];

coerce 'AppBundle',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::AppBundle'->new($_) };

declare 'RepeatedAppBundle',
    as ArrayRef[AppBundle()];

coerce 'RepeatedAppBundle',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::AppBundle'->new($_) } @$_ ] };

declare 'MapStringAppBundle',
    as HashRef[AppBundle()];

declare 'DeviceFile',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::DeviceFile'];

coerce 'DeviceFile',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::DeviceFile'->new($_) };

declare 'RepeatedDeviceFile',
    as ArrayRef[DeviceFile()];

coerce 'RepeatedDeviceFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::DeviceFile'->new($_) } @$_ ] };

declare 'MapStringDeviceFile',
    as HashRef[DeviceFile()];

declare 'ObbFile',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ObbFile'];

coerce 'ObbFile',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ObbFile'->new($_) };

declare 'RepeatedObbFile',
    as ArrayRef[ObbFile()];

coerce 'RepeatedObbFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ObbFile'->new($_) } @$_ ] };

declare 'MapStringObbFile',
    as HashRef[ObbFile()];

declare 'RegularFile',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::RegularFile'];

coerce 'RegularFile',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::RegularFile'->new($_) };

declare 'RepeatedRegularFile',
    as ArrayRef[RegularFile()];

coerce 'RepeatedRegularFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::RegularFile'->new($_) } @$_ ] };

declare 'MapStringRegularFile',
    as HashRef[RegularFile()];

declare 'IosDeviceFile',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::IosDeviceFile'];

coerce 'IosDeviceFile',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::IosDeviceFile'->new($_) };

declare 'RepeatedIosDeviceFile',
    as ArrayRef[IosDeviceFile()];

coerce 'RepeatedIosDeviceFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::IosDeviceFile'->new($_) } @$_ ] };

declare 'MapStringIosDeviceFile',
    as HashRef[IosDeviceFile()];

declare 'AndroidTestLoop',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::AndroidTestLoop'];

coerce 'AndroidTestLoop',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::AndroidTestLoop'->new($_) };

declare 'RepeatedAndroidTestLoop',
    as ArrayRef[AndroidTestLoop()];

coerce 'RepeatedAndroidTestLoop',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::AndroidTestLoop'->new($_) } @$_ ] };

declare 'MapStringAndroidTestLoop',
    as HashRef[AndroidTestLoop()];

declare 'IosXcTest',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::IosXcTest'];

coerce 'IosXcTest',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::IosXcTest'->new($_) };

declare 'RepeatedIosXcTest',
    as ArrayRef[IosXcTest()];

coerce 'RepeatedIosXcTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::IosXcTest'->new($_) } @$_ ] };

declare 'MapStringIosXcTest',
    as HashRef[IosXcTest()];

declare 'IosTestLoop',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::IosTestLoop'];

coerce 'IosTestLoop',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::IosTestLoop'->new($_) };

declare 'RepeatedIosTestLoop',
    as ArrayRef[IosTestLoop()];

coerce 'RepeatedIosTestLoop',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::IosTestLoop'->new($_) } @$_ ] };

declare 'MapStringIosTestLoop',
    as HashRef[IosTestLoop()];

declare 'IosRoboTest',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::IosRoboTest'];

coerce 'IosRoboTest',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::IosRoboTest'->new($_) };

declare 'RepeatedIosRoboTest',
    as ArrayRef[IosRoboTest()];

coerce 'RepeatedIosRoboTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::IosRoboTest'->new($_) } @$_ ] };

declare 'MapStringIosRoboTest',
    as HashRef[IosRoboTest()];

declare 'AndroidInstrumentationTest',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::AndroidInstrumentationTest'];

coerce 'AndroidInstrumentationTest',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::AndroidInstrumentationTest'->new($_) };

declare 'RepeatedAndroidInstrumentationTest',
    as ArrayRef[AndroidInstrumentationTest()];

coerce 'RepeatedAndroidInstrumentationTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::AndroidInstrumentationTest'->new($_) } @$_ ] };

declare 'MapStringAndroidInstrumentationTest',
    as HashRef[AndroidInstrumentationTest()];

declare 'AndroidRoboTest',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::AndroidRoboTest'];

coerce 'AndroidRoboTest',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::AndroidRoboTest'->new($_) };

declare 'RepeatedAndroidRoboTest',
    as ArrayRef[AndroidRoboTest()];

coerce 'RepeatedAndroidRoboTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::AndroidRoboTest'->new($_) } @$_ ] };

declare 'MapStringAndroidRoboTest',
    as HashRef[AndroidRoboTest()];

declare 'RoboDirective',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::RoboDirective'];

coerce 'RoboDirective',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::RoboDirective'->new($_) };

declare 'RepeatedRoboDirective',
    as ArrayRef[RoboDirective()];

coerce 'RepeatedRoboDirective',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::RoboDirective'->new($_) } @$_ ] };

declare 'MapStringRoboDirective',
    as HashRef[RoboDirective()];

declare 'RoboStartingIntent',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::RoboStartingIntent'];

coerce 'RoboStartingIntent',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::RoboStartingIntent'->new($_) };

declare 'RepeatedRoboStartingIntent',
    as ArrayRef[RoboStartingIntent()];

coerce 'RepeatedRoboStartingIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::RoboStartingIntent'->new($_) } @$_ ] };

declare 'MapStringRoboStartingIntent',
    as HashRef[RoboStartingIntent()];

declare 'LauncherActivityIntent',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::LauncherActivityIntent'];

coerce 'LauncherActivityIntent',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::LauncherActivityIntent'->new($_) };

declare 'RepeatedLauncherActivityIntent',
    as ArrayRef[LauncherActivityIntent()];

coerce 'RepeatedLauncherActivityIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::LauncherActivityIntent'->new($_) } @$_ ] };

declare 'MapStringLauncherActivityIntent',
    as HashRef[LauncherActivityIntent()];

declare 'StartActivityIntent',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::StartActivityIntent'];

coerce 'StartActivityIntent',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::StartActivityIntent'->new($_) };

declare 'RepeatedStartActivityIntent',
    as ArrayRef[StartActivityIntent()];

coerce 'RepeatedStartActivityIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::StartActivityIntent'->new($_) } @$_ ] };

declare 'MapStringStartActivityIntent',
    as HashRef[StartActivityIntent()];

declare 'NoActivityIntent',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::NoActivityIntent'];

coerce 'NoActivityIntent',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::NoActivityIntent'->new($_) };

declare 'RepeatedNoActivityIntent',
    as ArrayRef[NoActivityIntent()];

coerce 'RepeatedNoActivityIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::NoActivityIntent'->new($_) } @$_ ] };

declare 'MapStringNoActivityIntent',
    as HashRef[NoActivityIntent()];

declare 'EnvironmentMatrix',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::EnvironmentMatrix'];

coerce 'EnvironmentMatrix',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::EnvironmentMatrix'->new($_) };

declare 'RepeatedEnvironmentMatrix',
    as ArrayRef[EnvironmentMatrix()];

coerce 'RepeatedEnvironmentMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::EnvironmentMatrix'->new($_) } @$_ ] };

declare 'MapStringEnvironmentMatrix',
    as HashRef[EnvironmentMatrix()];

declare 'AndroidDeviceList',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::AndroidDeviceList'];

coerce 'AndroidDeviceList',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::AndroidDeviceList'->new($_) };

declare 'RepeatedAndroidDeviceList',
    as ArrayRef[AndroidDeviceList()];

coerce 'RepeatedAndroidDeviceList',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::AndroidDeviceList'->new($_) } @$_ ] };

declare 'MapStringAndroidDeviceList',
    as HashRef[AndroidDeviceList()];

declare 'IosDeviceList',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::IosDeviceList'];

coerce 'IosDeviceList',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::IosDeviceList'->new($_) };

declare 'RepeatedIosDeviceList',
    as ArrayRef[IosDeviceList()];

coerce 'RepeatedIosDeviceList',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::IosDeviceList'->new($_) } @$_ ] };

declare 'MapStringIosDeviceList',
    as HashRef[IosDeviceList()];

declare 'AndroidMatrix',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::AndroidMatrix'];

coerce 'AndroidMatrix',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::AndroidMatrix'->new($_) };

declare 'RepeatedAndroidMatrix',
    as ArrayRef[AndroidMatrix()];

coerce 'RepeatedAndroidMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::AndroidMatrix'->new($_) } @$_ ] };

declare 'MapStringAndroidMatrix',
    as HashRef[AndroidMatrix()];

declare 'ClientInfo',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ClientInfo'];

coerce 'ClientInfo',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ClientInfo'->new($_) };

declare 'RepeatedClientInfo',
    as ArrayRef[ClientInfo()];

coerce 'RepeatedClientInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ClientInfo'->new($_) } @$_ ] };

declare 'MapStringClientInfo',
    as HashRef[ClientInfo()];

declare 'ClientInfoDetail',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ClientInfoDetail'];

coerce 'ClientInfoDetail',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ClientInfoDetail'->new($_) };

declare 'RepeatedClientInfoDetail',
    as ArrayRef[ClientInfoDetail()];

coerce 'RepeatedClientInfoDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ClientInfoDetail'->new($_) } @$_ ] };

declare 'MapStringClientInfoDetail',
    as HashRef[ClientInfoDetail()];

declare 'ResultStorage',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ResultStorage'];

coerce 'ResultStorage',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ResultStorage'->new($_) };

declare 'RepeatedResultStorage',
    as ArrayRef[ResultStorage()];

coerce 'RepeatedResultStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ResultStorage'->new($_) } @$_ ] };

declare 'MapStringResultStorage',
    as HashRef[ResultStorage()];

declare 'ToolResultsHistory',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ToolResultsHistory'];

coerce 'ToolResultsHistory',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ToolResultsHistory'->new($_) };

declare 'RepeatedToolResultsHistory',
    as ArrayRef[ToolResultsHistory()];

coerce 'RepeatedToolResultsHistory',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ToolResultsHistory'->new($_) } @$_ ] };

declare 'MapStringToolResultsHistory',
    as HashRef[ToolResultsHistory()];

declare 'ToolResultsExecution',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ToolResultsExecution'];

coerce 'ToolResultsExecution',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ToolResultsExecution'->new($_) };

declare 'RepeatedToolResultsExecution',
    as ArrayRef[ToolResultsExecution()];

coerce 'RepeatedToolResultsExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ToolResultsExecution'->new($_) } @$_ ] };

declare 'MapStringToolResultsExecution',
    as HashRef[ToolResultsExecution()];

declare 'ToolResultsStep',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ToolResultsStep'];

coerce 'ToolResultsStep',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ToolResultsStep'->new($_) };

declare 'RepeatedToolResultsStep',
    as ArrayRef[ToolResultsStep()];

coerce 'RepeatedToolResultsStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ToolResultsStep'->new($_) } @$_ ] };

declare 'MapStringToolResultsStep',
    as HashRef[ToolResultsStep()];

declare 'GoogleCloudStorage',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::GoogleCloudStorage'];

coerce 'GoogleCloudStorage',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::GoogleCloudStorage'->new($_) };

declare 'RepeatedGoogleCloudStorage',
    as ArrayRef[GoogleCloudStorage()];

coerce 'RepeatedGoogleCloudStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::GoogleCloudStorage'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudStorage',
    as HashRef[GoogleCloudStorage()];

declare 'FileReference',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::FileReference'];

coerce 'FileReference',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::FileReference'->new($_) };

declare 'RepeatedFileReference',
    as ArrayRef[FileReference()];

coerce 'RepeatedFileReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::FileReference'->new($_) } @$_ ] };

declare 'MapStringFileReference',
    as HashRef[FileReference()];

declare 'Environment',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'AndroidDevice',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::AndroidDevice'];

coerce 'AndroidDevice',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::AndroidDevice'->new($_) };

declare 'RepeatedAndroidDevice',
    as ArrayRef[AndroidDevice()];

coerce 'RepeatedAndroidDevice',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::AndroidDevice'->new($_) } @$_ ] };

declare 'MapStringAndroidDevice',
    as HashRef[AndroidDevice()];

declare 'IosDevice',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::IosDevice'];

coerce 'IosDevice',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::IosDevice'->new($_) };

declare 'RepeatedIosDevice',
    as ArrayRef[IosDevice()];

coerce 'RepeatedIosDevice',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::IosDevice'->new($_) } @$_ ] };

declare 'MapStringIosDevice',
    as HashRef[IosDevice()];

declare 'TestDetails',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::TestDetails'];

coerce 'TestDetails',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::TestDetails'->new($_) };

declare 'RepeatedTestDetails',
    as ArrayRef[TestDetails()];

coerce 'RepeatedTestDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::TestDetails'->new($_) } @$_ ] };

declare 'MapStringTestDetails',
    as HashRef[TestDetails()];

declare 'InvalidRequestDetail',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::InvalidRequestDetail'];

coerce 'InvalidRequestDetail',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::InvalidRequestDetail'->new($_) };

declare 'RepeatedInvalidRequestDetail',
    as ArrayRef[InvalidRequestDetail()];

coerce 'RepeatedInvalidRequestDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::InvalidRequestDetail'->new($_) } @$_ ] };

declare 'MapStringInvalidRequestDetail',
    as HashRef[InvalidRequestDetail()];

declare 'Reason',
    as (Int | Str);

declare 'ShardingOption',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ShardingOption'];

coerce 'ShardingOption',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ShardingOption'->new($_) };

declare 'RepeatedShardingOption',
    as ArrayRef[ShardingOption()];

coerce 'RepeatedShardingOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ShardingOption'->new($_) } @$_ ] };

declare 'MapStringShardingOption',
    as HashRef[ShardingOption()];

declare 'UniformSharding',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::UniformSharding'];

coerce 'UniformSharding',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::UniformSharding'->new($_) };

declare 'RepeatedUniformSharding',
    as ArrayRef[UniformSharding()];

coerce 'RepeatedUniformSharding',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::UniformSharding'->new($_) } @$_ ] };

declare 'MapStringUniformSharding',
    as HashRef[UniformSharding()];

declare 'ManualSharding',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::ManualSharding'];

coerce 'ManualSharding',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::ManualSharding'->new($_) };

declare 'RepeatedManualSharding',
    as ArrayRef[ManualSharding()];

coerce 'RepeatedManualSharding',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::ManualSharding'->new($_) } @$_ ] };

declare 'MapStringManualSharding',
    as HashRef[ManualSharding()];

declare 'TestTargetsForShard',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::TestTargetsForShard'];

coerce 'TestTargetsForShard',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::TestTargetsForShard'->new($_) };

declare 'RepeatedTestTargetsForShard',
    as ArrayRef[TestTargetsForShard()];

coerce 'RepeatedTestTargetsForShard',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::TestTargetsForShard'->new($_) } @$_ ] };

declare 'MapStringTestTargetsForShard',
    as HashRef[TestTargetsForShard()];

declare 'SmartSharding',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::SmartSharding'];

coerce 'SmartSharding',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::SmartSharding'->new($_) };

declare 'RepeatedSmartSharding',
    as ArrayRef[SmartSharding()];

coerce 'RepeatedSmartSharding',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::SmartSharding'->new($_) } @$_ ] };

declare 'MapStringSmartSharding',
    as HashRef[SmartSharding()];

declare 'Shard',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::Shard'];

coerce 'Shard',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::Shard'->new($_) };

declare 'RepeatedShard',
    as ArrayRef[Shard()];

coerce 'RepeatedShard',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::Shard'->new($_) } @$_ ] };

declare 'MapStringShard',
    as HashRef[Shard()];

declare 'CreateTestMatrixRequest',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::CreateTestMatrixRequest'];

coerce 'CreateTestMatrixRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::CreateTestMatrixRequest'->new($_) };

declare 'RepeatedCreateTestMatrixRequest',
    as ArrayRef[CreateTestMatrixRequest()];

coerce 'RepeatedCreateTestMatrixRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::CreateTestMatrixRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTestMatrixRequest',
    as HashRef[CreateTestMatrixRequest()];

declare 'GetTestMatrixRequest',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::GetTestMatrixRequest'];

coerce 'GetTestMatrixRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::GetTestMatrixRequest'->new($_) };

declare 'RepeatedGetTestMatrixRequest',
    as ArrayRef[GetTestMatrixRequest()];

coerce 'RepeatedGetTestMatrixRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::GetTestMatrixRequest'->new($_) } @$_ ] };

declare 'MapStringGetTestMatrixRequest',
    as HashRef[GetTestMatrixRequest()];

declare 'CancelTestMatrixRequest',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixRequest'];

coerce 'CancelTestMatrixRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixRequest'->new($_) };

declare 'RepeatedCancelTestMatrixRequest',
    as ArrayRef[CancelTestMatrixRequest()];

coerce 'RepeatedCancelTestMatrixRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixRequest'->new($_) } @$_ ] };

declare 'MapStringCancelTestMatrixRequest',
    as HashRef[CancelTestMatrixRequest()];

declare 'CancelTestMatrixResponse',
    as InstanceOf['Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixResponse'];

coerce 'CancelTestMatrixResponse',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixResponse'->new($_) };

declare 'RepeatedCancelTestMatrixResponse',
    as ArrayRef[CancelTestMatrixResponse()];

coerce 'RepeatedCancelTestMatrixResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixResponse'->new($_) } @$_ ] };

declare 'MapStringCancelTestMatrixResponse',
    as HashRef[CancelTestMatrixResponse()];

1;

__END__

=head1 NAME

Google::Devtools::Testing::V1::TestExecution::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
