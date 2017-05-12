# Env::Sanctify::Auto
#  Automatically cleans up your environment to prevent security issues.
#
# $Id: Auto.pm 8622 2009-08-18 04:46:41Z FREQUENCY@cpan.org $

package Env::Sanctify::Auto;

use strict;
use warnings;
use Carp ();

use base 'Env::Sanctify';

=head1 NAME

Env::Sanctify::Auto - Perl module that cleans up %ENV

=head1 VERSION

Version 1.001 ($Id: Auto.pm 8622 2009-08-18 04:46:41Z FREQUENCY@cpan.org $)

=cut

our $VERSION = '1.001';
$VERSION = eval $VERSION;

=head1 DESCRIPTION

Environment variables such as B<PATH> (command search path) and B<IFS> (input
field separator) can have severe security ramifications. Luckily, enabling
Perl's taint mode will provide some extra checking whenever there can be
potentially unsafe calls to functions like B<system> or B<open>.

However, there has been no simple way to load a module which automatically
cleans up your environment. Various methods are used to temporarily clean up
the environment for you or forked children, such as:

  local $ENV{PATH} = '/usr/bin:/usr/local/bin';

While this works for most purposes, it has some potential issues such as what
to do when the paths are different under different architectures. Obviously
such a command is not portable to environments with different path conventions
so this would break your program's compatibility with Win32, among others.

This simple module subclasses B<Env::Sanctify> to take care of this for you.
Among other things, this means you get the nice bonus of lexically scoped
environments (see L<Env::Sanctify> for details).

=head1 SYNOPSIS

  my $env = Env::Sanctify::Auto->new();
  # do some stuff, fork some processes, etc.
  $env->restore; # everything is back to normal.

=head1 COMPATIBILITY

This module was tested under Perl 5.10.0, using Debian Linux. However, because
it's Pure Perl and doesn't do anything too obscure, it should be compatible
with any version of Perl that supports its prerequisite modules.

It is untested on Win32 and unlikely to work for the time being.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 ENVIRONMENT VARIABLES

This module knows about the following environment variables:

=head2 PATH

B<PATH> provides a list of paths to search for executables, which influences
which commands are invoked by unqualified calls to system() and others. This
variable is particularly dangerous because even if you use a fully qualified
call to the executable, like "/usr/bin/echo ..." -- there is still a security
hole, since B<echo> could be executing unqualified code itself.

The safest way to handle this, and the strategy used by this module, is to
remove everything except C</usr/bin> and C</usr/local/bin> (or equivalent,
depending on your operating system).

=head2 CDPATH

B<CDPATH> provides additional paths for B<cd> to search on the system when it
is called. This is dangerous because you could be attempting to change into
a known safe directory, but the CDPATH may divert you to another directory.
The variable is generally of limited usefulness, and so is removed completely
during C<%ENV> scrubbing.

=head2 IFS

B<IFS> is the Internal Field Separator, which tells the operating system
what characters should be considered whitespace separating command line
arguments. Combined with controlling B<PATH>, this exposes a very dangerous
vulnerability: if the IFS is set to '/', then C<system('/bin/more')> is
essentially the same as C<system('bin more')>. As a result, the 'bin' command
is executed instead of '/bin/more' as expected.

=head2 ENV and BASH_ENV

B<ENV> and B<BASH_ENV> list files that are executed whenever a new shell is
started, which includes whenever a shell script (.sh) is run.

=head1 METHODS

=head2 Env::Sanctify::Auto->new($opts)

=head2 Env::Sanctify::Auto->sanctify($opts)

Creates a new C<Env::Sanctify::Auto> object, scrubbing the environment to
remove or pacify potentially dangerous variables. Options may be passed as
a hash reference to the constructor.

Code example:

  my $env = Env::Sanctify::Auto->new;

By default, PATH will be set to a sane value, but you can override the
behaviour by passing the 'path' option:

  my $env = Env::Sanctify::Auto->new({
    path => '/usr/local/bin:/usr/bin'
  });

=cut

sub new {
  my ($class, $opts) = @_;

  Carp::croak('You must call this as a class method') if ref($class);

  Carp::croak('Options must be given as a hash reference')
    if (defined $opts && ref($opts) ne 'HASH');

  my $path;
  if ($opts->{path}) {
    $path = $opts->{path};
  }
  else {
    $path = _secure_path();
  }

  # Construct the Env::Sanctify (superclass) base
  my $self = Env::Sanctify->sanctify(
    env => {
      PATH => $path,
    },
    sanctify => [
      'CDPATH', # cd search path
      'IFS', # Internal field separator
      'ENV',
      'BASH_ENV',
    ]
  );

  # Re-bless this into our package
  return bless($self, $class);
}
*sanctify = *new;

# Private utility functions
sub _secure_path {
  # Return a PATH specific to the platform we're running on
  if ($^O eq 'MSWin32') {
    return '%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem';
  }

  # Assume everything else is Unix-like
  return '/usr/bin:/usr/bin/local';
}

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 ACKNOWLEDGEMENTS

=over

=item * Thanks to Chris "BinGOs" Williams <chris@bingosnet.co.uk> for
making L<Env::Sanctify>, a pretty neat module that inspired this one.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Env::Sanctify::Auto

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Env-Sanctify-Auto>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Env-Sanctify-Auto>

=item * Search CPAN

L<http://search.cpan.org/dist/Env-Sanctify-Auto>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Env-Sanctify-Auto>

=item * CPAN Testing Service (Kwalitee Tests)

L<http://cpants.perl.org/dist/overview/Env-Sanctify-Auto>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<http://svn.ali.as/cpan/trunk/Env-Sanctify-Auto>

If you are a CPAN developer and would like to make modifications to the
code base, please contact Adam Kennedy E<lt>adamk@cpan.orgE<gt>, the
repository administrator. I only ask that you contact me first to discuss
the changes you wish to make to the distribution.

=head1 FEEDBACK

Please send relevant comments, rotten tomatoes and suggestions directly to
the maintainer noted above.

If you have a bug report or feature request, please file them on the CPAN
Request Tracker at L<http://rt.cpan.org>. If you are able to submit your
bug report in the form of failing unit tests, you are B<strongly> encouraged
to do so.

=head1 SEE ALSO

L<Env::Sanctify>, the module upon which this one is based.

L<http://www.perlmonks.org/?node_id=131746>, a Perl Monks thread discussing
why IFS, CDPATH, ENV and BASH_ENV are considered dangerous

L<perlsec>, a document explaining security considerations for Perl programs.

=head1 CAVEATS

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head2 LIMITATIONS

=over

=item *

There are lots of variables that can do dangerous things, particularly when
executing files via C<system()> or others. This module tries to fix the most
common ones, but is by no means a complete way to sanctify your namespace,
and is not a substitute for performing your own security audit.

=item *

I'm not a security expert, so more than likely I've missed something.
Please do file bug reports so that I can fix the module.

=item *

I don't have access to a VMS machine, nor do I know how they work, so there
is currently nothing here to deal with that. If you have a OpenVMS machine
or know how they work, feel free to send me an e-mail or patch.

=back

=head1 QUALITY ASSURANCE METRICS

=head2 TEST COVERAGE

  ------------------------- ------ ------ ------ ------ ------ ------
  File                      stmt   bran   cond    sub    pod   total
  ------------------------- ------ ------ ------ ------ ------ ------
  Env/Sanctify/Auto.pm      100.0  100.0  100.0  100.0  100.0  100.0

=head1 LICENSE

Copyright (C) 2009 by Jonathan Yu <frequency@cpan.org>

This package is distributed under the same terms as Perl itself. Please
see the LICENSE file included in this distribution for full details of
these terms.

=head1 DISCLAIMER OF WARRANTY

This software is provided by the copyright holders and contributors "AS IS"
and ANY EXPRESS OR IMPLIED WARRANTIES, including, but not limited to, the
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.

In no event shall the copyright owner or contributors be liable for any
direct, indirect, incidental, special, exemplary or consequential damages
(including, but not limited to, procurement of substitute goods or services;
loss of use, data or profits; or business interruption) however caused and
on any theory of liability, whether in contract, strict liability or tort
(including negligence or otherwise) arising in any way out of the use of
this software, even if advised of the possibility of such damage.

=cut

1;
