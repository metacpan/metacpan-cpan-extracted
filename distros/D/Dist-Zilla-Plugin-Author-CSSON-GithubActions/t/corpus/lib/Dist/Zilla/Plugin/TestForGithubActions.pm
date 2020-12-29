use 5.14.0;
use strict;
use warnings;

package Dist::Zilla::Plugin::TestForGithubActions;

use Moose;
extends 'Dist::Zilla::Plugin::Author::CSSON::GithubActions::Workflow::TestWithMakefile';

sub workflow_filename { 'share/test-workflow.yml' }

sub distribution_name { 'Dist-Zilla-Plugin-TestForGithubActions' }

1;
