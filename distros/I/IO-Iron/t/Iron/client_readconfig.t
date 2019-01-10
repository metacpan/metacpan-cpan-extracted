#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
require JSON::MaybeXS;
use File::HomeDir;
use File::Remove 'remove';
use File::Copy 'move';
use Carp;

plan tests => 7;

require IO::Iron::IronWorker::Client;


diag('Testing IO::Iron::IronWorker::Client '
   . ($IO::Iron::IronWorker::Client::VERSION ? "($IO::Iron::IronWorker::Client::VERSION)" : '(no version)')
   . ", Perl $], $^X");

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
my $json = JSON::MaybeXS->new(utf8 => 1, pretty => 1);

diag('test ReadIronMQConfig');

# File in homedir
# (Can't be tested; we don't write to user's home dir!)
#my $iron_global_file_hash = {
#       'project_id' => 'Global_file_project_id', 'token' => 'Global_file_token',
#       'host' => 'Global_file_host', 'protocol' => 'Global_file_protocol',
#       'port' => '10001', 'api_version' => '1',
#       };
#my $homedir_filename = File::Spec->catfile(File::HomeDir->my_home, '.iron.json');
#open OPENDIR_HANDLE, '>', $homedir_filename;
#print OPENDIR_HANDLE encode_json($iron_global_file_hash);
#close OPENDIR_HANDLE;

# Global envs
$ENV{'IRON_PROJECT_ID'}       = 'Global_file_project_id'; # For convience

$ENV{'IRON_TOKEN'}       = 'Global_env_token';
$ENV{'IRON_HOST'}        = 'Global_env_host';
$ENV{'IRON_PROTOCOL'}    = 'Global_env_protocol';
$ENV{'IRON_PORT'}        = '10002';
$ENV{'IRON_API_VERSION'} = '2';

# Product specific envs
# (not tested)

# File in current dir. Yes, we write to the dir where the script is being run.
my $iron_local_file_hash = {
        'host' => 'Local_file_host', 'protocol' => 'Local_file_protocol',
        'port' => '10003', 'api_version' => '3',
        'timeout' => '23',
        };
my $currentdir_filename = File::Spec->catfile(File::Spec->curdir(), 'iron.json');
diag("Current dir config filename: $currentdir_filename");
my $currentdir_conf_file_already_here = 0; # If the file exists, we don't want to overwrite it!
if(-e $currentdir_filename) {
    $currentdir_conf_file_already_here = 1;
    move $currentdir_filename, $currentdir_filename . '.tmp';
}
open CURRENTDIR_HANDLE, '>', $currentdir_filename;
print CURRENTDIR_HANDLE $json->encode($iron_local_file_hash);
close CURRENTDIR_HANDLE;

# File with a different (any) name and location.
my $iron_extra_file_hash = {
        'protocol' => 'Extra_file_protocol',
        'port' => '10004', 'api_version' => '4',
        };
#'t/IronMQTestConfig.json'
my $iron_extra_file_name = File::Spec->catfile(File::Spec->curdir(), 't', '.IronMQTestConfig.json');
diag("Extra config filename: $iron_extra_file_name");
open DIFFDIR_HANDLE, '>', $iron_extra_file_name;
print DIFFDIR_HANDLE $json->encode($iron_extra_file_hash);
close DIFFDIR_HANDLE;

my $ironworker = IO::Iron::IronWorker::Client->new(
        'config' => $iron_extra_file_name,
        'port' => '10005', 'api_version' => '5'
        );

is($ironworker->{'connection'}->{'api_version'}, 5, 'Config is OK. (api_version)');
is($ironworker->{'connection'}->{'port'}, 10_005, 'Config is OK. (port)');
is($ironworker->{'connection'}->{'protocol'}, 'Extra_file_protocol', 'Config is OK. (protocol)');
is($ironworker->{'connection'}->{'host'}, 'Local_file_host', 'Config is OK. (host)');
is($ironworker->{'connection'}->{'token'}, 'Global_env_token', 'Config is OK (token).');
is($ironworker->{'connection'}->{'project_id'}, 'Global_file_project_id', 'Config is OK. (project_id)');
is($ironworker->{'connection'}->{'timeout'}, 23, 'Config is OK. (timeout)');


# Clean up after us, delete the extra files.
remove($iron_extra_file_name);
remove($currentdir_filename);
if($currentdir_conf_file_already_here) { # Return the original file.
    move $currentdir_filename . '.tmp', $currentdir_filename;
}

