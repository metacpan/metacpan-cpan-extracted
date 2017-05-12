package Dist::Zilla::Plugin::RunByBranch;
BEGIN {
  $Dist::Zilla::Plugin::RunByBranch::AUTHORITY = 'cpan:FFFINKEL';
}
{
  $Dist::Zilla::Plugin::RunByBranch::VERSION = '0.214';
}

# ABSTRACT: Run external commands at specific phases of Dist::Zilla on regex'd Git branches

use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::RunByBranch - Run external commands at specific phases of Dist::Zilla on regex'd Git branches

=head1 VERSION

version 0.214

=head1 SYNOPSIS

  [RunByBranch::BeforeBuild]
  run = ^dev script/clean_artifacts.pl %s
  run = ^test script/prepare_tests.pl %n %v

  [RunByBranch::BeforeRelease]
  run = ^master$ script/myapp_deploy1.pl %s

  [RunByBranch::AfterBuild]
  run = ^dev script/myapp_after.pl %s %v
  run_no_trial ^dev script/no_trial.pl
  run = ^test(.*)/v1.[0-3]$ script/report_test_results.pl %s %v

  [RunByBranch::Test]
  run = ^feature/ script/report.pl

=head1 DESCRIPTION

This module aims to duplicate the interface of the fantasticly useful
L<Dist::Zilla::Plugin::Run> by allowing the user to specify a regex that
determines on which Git branch the command should be run.

=head1 NAME

Dist::Zilla::Plugin::RunByBranch - Run external commands at specific phases of Dist::Zilla on regex'd Git branches

I am a very terrible programmer and user of words.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Run>
L<Dist::Zilla::Plugin::Git>

=head1 AUTHOR

Matt Finkel <finkel.matt@gmail.com> L<http://mfinkel.net/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Matt Finkel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
