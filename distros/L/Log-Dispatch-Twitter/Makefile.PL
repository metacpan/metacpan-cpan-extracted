# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
use Module::Install::GithubMeta;

# Define metadata
name     'Log-Dispatch-Twitter';
all_from 'lib/Log/Dispatch/Twitter.pm';
githubmeta;

requires 'Log::Dispatch' => 2.22;
requires 'Net::Twitter'  => 1.17;

WriteAll;

