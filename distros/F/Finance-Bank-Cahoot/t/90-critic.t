#! /usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Test::More;

if (not defined $ENV{AUTHOR_MODE}) {
  my $msg = 'Skipping Test::Perl::Critic - author mode only';
  plan(skip_all => $msg);
}

eval { require Test::Perl::Critic; };

if ($@) {
  my $msg = 'Test::Perl::Critic required to criticise code';
  plan(skip_all => $msg);
}

Test::Perl::Critic->import(-severity => 'brutal',
			   -exclude => [qw (RequireRcsKeywords RequireTidyCode RequirePodSections
					    ProhibitPostfixControls ExtendedFormatting 
					    LineBoundaryMatching ProhibitCaptureWithoutTest)]);

all_critic_ok();
