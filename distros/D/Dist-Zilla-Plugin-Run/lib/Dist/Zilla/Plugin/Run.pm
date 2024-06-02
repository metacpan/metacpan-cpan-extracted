use strict;
use warnings;

package Dist::Zilla::Plugin::Run; # git description: 0.049-2-g1f18022
# ABSTRACT: Run external commands and code at specific phases of Dist::Zilla
# KEYWORDS: plugin tool distribution build release run command shell execute

our $VERSION = '0.050';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Run - Run external commands and code at specific phases of Dist::Zilla

=head1 VERSION

version 0.050

=head1 SYNOPSIS

  [Run::AfterBuild]
  run = script/do_this.pl --dir %d --version %v
  run = script/do_that.pl
  eval = unlink scratch.dat

  [Run::BeforeBuild]
  fatal_errors = 0
  run = script/do_this.pl --version %v
  run = script/do_that_crashy_thing.pl
  eval = if ($ENV{SOMETHING}) {
  eval =   $_[0]->log('some message')
  eval = }

  [Run::BeforeArchive]
  run = script/myapp_before1.pl %d %v
  run = script/myapp_before2.pl %n %v
  run_no_trial = script/no_execution_on_trial.pl %n %v

  [Run::BeforeRelease]
  run = script/myapp_before1.pl %a
  run = script/myapp_before2.pl %n %v
  run_no_trial = script/no_execution_on_trial.pl %n %v

  [Run::Release]
  run = script/myapp_deploy1.pl %a
  run = deployer.pl --dir %d --tgz %a --name %n --version %v
  run_no_trial = script/no_execution_on_trial.pl --dir %d --tgz %a --name %n --version %v

  [Run::AfterRelease]
  run = script/myapp_after.pl --archive %a --dir %d --version %v
  ; %p can be used as the path separator if you have contributors on a different OS
  run = script%pmyapp_after.pl --archive %a --dir %d --version %v

  [Run::AfterRelease / MyAppAfter]
  run = script/myapp_after.pl --archive %a --dir %d --version %v

  [Run::Test]
  run = script/tester.pl --name %n --version %v some_file.ext
  run_if_release = ./Build install
  run_if_release = make install

  [Run::AfterMint]
  run = some command %d
  eval = unlink scratch.dat
  eval = print "I just minted %n for you. Have a nice day!\n";

=head1 DESCRIPTION

Run arbitrary commands and code at various L<Dist::Zilla> phases.

=head1 PARAMETERS

=head2 run

Run the specific command at the specific L<Dist::Zilla> phase given by the
plugin. For example, C<[Run::Release]> runs during the release phase.

=head2 run_if_trial

Only run the given command if this is a I<trial> build or release.

=head2 run_no_trial

Only run the given command if this isn't a I<trial> build or release.

=head2 run_if_release

Only run the given command if this is a release.

=head2 run_no_release

Only run a given command if this isn't a release.

=head2 eval

Treats the input as a list of lines of Perl code; the code is evaluated at the
specific L<Dist::Zilla> phase given by the plugin. The code is executed in its
own C<eval> scope, within a subroutine body; C<@_> contains the instance of the
plugin executing the code. (Remember that C<shift> in an C<eval> actually
operates on C<@ARGV>, not C<@_>, so to access the plugin instance, use
C<$_[0]>.)

=head2 censor_commands

Normally, C<run*> commands are included in distribution metadata when used
with the L<[MetaConfig]|Dist::Zilla::Plugin::MetaConfig> plugin. To bypass
this, set C<censor_commands = 1>.  Additionally, this command is set to true
automatically when a URL with embedded password is present.

Defaults to false.

=head2 fatal_errors

When true, if the C<run> command returns a non-zero exit status or the C<eval>
command dies, the build will fail. Defaults to true.

=head2 quiet

When true, diagnostic messages are not printed (except in C<--verbose> mode).

Defaults to false.

=head1 EXECUTION ORDER

All commands for a given option name are executed together, in the order in
which they are documented above.  Within commands of the same option name,
order is preserved (from the order provided in F<dist.ini>).

=head1 ENVIRONMENT

=for stopwords subshell

For executed commands, L<IPC::Open3/open3> is used -- there is no subshell.
Consequently environment variables may or may not be available depending on
the individual architecture used.  For Perl strings that are evaluated, they
are done in the dzil process, so all current global variables and other state
is available for use.

The current working directory is undefined, and may vary depending on the
version of Dist::Zilla being used. If the state of the filesystem is
important, explicitly change directories first, or base your relative paths
off of the build root (available as C<%d>, see below).

=head1 CONVERSIONS

The following conversions/format specifiers are defined
for passing as arguments to the specified commands and eval strings
(though not all values are available at all phases).

=over 4

=item *

C<%a> the archive of the release (only available to all C<*Release> phases), as documented to be passed to BeforeRelease, Release, AfterRelease plugins

=item *

C<%o> the directory in which the distribution source originated

=item *

C<%d> the directory in which the distribution was built (or minted) (not available in C<BeforeBuild>)

=item *

C<%n> the distribution name

=item *

C<%p> path separator ('/' on Unix, '\\' on Win32... useful for cross-platform F<dist.ini> files)

=item *

C<%v> the distribution version, if available (depending on the phase, the C<VersionProvider> plugin may not be able to return a version)

=item *

C<%t> C<-TRIAL> if the release is a trial release, otherwise the empty string

=item *

C<%x> full path to the current perl interpreter (like C<$^X> but from L<Config>)

=back

Additionally C<%s> is retained for backward compatibility (for those plugins that existed
when it was documented).  Each occurrence is replaced by a different value
(like the regular C<sprintf> function).
Individual plugins define their own values for the positional replacement of C<%s>.

B<NOTE>: when using filenames (e.g. C<%d>, C<%n> and C<%x>), be mindful that
these paths could contain special characters or whitespace, so if they are to
be used in a shell command, take care to use quotes or escapes!

=head1 DANGER! SECURITY RISK!

The very nature of these plugins is to execute code. Be mindful that your code
may run on someone else's machine and don't be a jerk!

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Run>
(or L<bug-Dist-Zilla-Plugin-Run@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Run@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Randy Stauner Nickolay Platonov Olivier Mengué Al Newkirk David Golden Graham Ollis Tatsuhiko Miyagawa Thomas Sibley

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Nickolay Platonov <nplatonov@cpan.org>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Al Newkirk <github@alnewkirk.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Graham Ollis <plicease@cpan.org>

=item *

Tatsuhiko Miyagawa <miyagawa@cpan.org>

=item *

Thomas Sibley <tsibley@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by L<Raudssus Social Software|https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
