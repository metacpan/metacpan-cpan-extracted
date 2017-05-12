# $Id: Build.PL 526 2017-04-15 01:52:05Z sync $

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.11 );

use Module::Build 0.28;

=head1 FAREWELL NOTE

I believe that after epic BSD-battle I leave B<F::AF> in good shape.
What you see on cpan-testers (well, before this release) is manifestation of
APT-methods changing underground.
At the time I believed that I absolutely must know what's happening on other
end of the pipe (and I still hold to this belief).
So the test-suite is doing all terrible things I can implement
(admitedly, it's C<copy> and C<file> only, everything else is networking).
Then APT-methods have changed.

Updating the test-suite (that's what's de-synchronized) is easy,
I just have to upgrade to something more current.
And here comes the problem.
I have no resources to build RedHat for third time (I did it twice already).
And I have to move on.
And I won't see Debian for any foreseeable future.
Here we are.

=cut

=head1 OVERVIEW

B<File::AptFetch> provides API for APT (Advanced Package Tool, that's the
Debian package management system) methods.
APT methods aren't libraries, they are executables
(placed, by default, in
F</var/lib/apt/methods>).
So it's not XS (and can't be), B<F::AF> forks.
However one doesn't need fork for each file or session.
The IPC is B<pipe>
(and can't be anything else).
As you can see there's a limit of number of methods available simultaneously
posed by the maximum number of open filehandles
(APT methods aren't that numerous anyway).

The module is named B<File::AptFetch> because it always fetches.
I think that's possible to develop a method that would bring away files, but,
at present, there's none.
And I doubt there would be any.

Further reading:

=over

=item B<File::AptFetch>

POD of the module.
Covers API and provides examples of intended usage.
It's development is kind of dead 
(unless APT methods API would change dramatically) --
any additions are in support for B<File::AptFetch::Simple>.

=item B<File::AptFetch::Cookbook>

Provides some useful, I believe, findings on each method behaviour
and an overview, of my understanding, how that stuff works.
Look, APT methods API documentation is quite outdated.
Each method is undocumented completely.
B<(bug)> My knowledge of APT methods is very irregular, so is B<F::AF::C>.

=item B<File::AptFetch::Simple>

That's what you should look into for doing all kinds of stuff.
B<(bug)> It still lacks some functionality.

=back

=cut

=head1 RUN-TIME REQUIREMENTS

=over

=item B<Perl>

I<v5.8.0> or later.
Look, I<v5.6.2> is C<woody>, 20031114.
You must be kidding.

=item B<base>

=item B<Carp>

=item B<Cwd>

Any version.
Distributed with Perl itself.

=item B<IO::Pipe>

Any version.
It's distributed with Perl itself too.
In core since I<v5.3.7>, predates debian, BTW.

=item B<List::Util>

Required by B<File::AptFetch::Simple> for doing some gibberish.
I<v1.03> shall be enough.
Distributed with Perl itself.

=item B<String::Truncate>

Required by B<File::AptFetch::Simple>.
I<v0.5> looks OK.

=item B<version>

I<v0.77>.
CPAN doesn't remember when I<v0.50> has been released.
Required version has been upgraded in fruitles attempt to fix some FTBFSes.
Introduced more breakage.
Stayed.

=back

=cut

=head1 BUILD-TIME REQUIREMENTS

=over

=item B<File::Temp>

=item B<POSIX>

=item B<Test::More>

Any version.
Should be distributed with Perl itself.

=back

=cut

my $builder = Module::Build->new(
  module_name          =>                       q|File::AptFetch|,
  dist_author          =>                              q|ADOPTME|,
  dist_version_from    =>                      q|lib/AptFetch.pm|,
  sign                 =>                                       1,
# TODO:201402091303:whynot: B<Software::License> support has been added to B<M::B> I<v0.36_14>, so 20100822, so B<perl> I<v5.12.2>, so B<version> I<v0.83>
# FIXME:201403172218:whynot: Nothing to do with B<CPAN::Meta>.  B<Module::Build> insists on backward compatibility.  Thus C<LGPL_3_0> becomes C<lgpl>, what in turn becomes C<LGPL_2_0>.  Unconditionally.
  license              =>                          q|open_source|,
  meta_merge           => { resources =>
  { license =>     q|http://www.gnu.org/licenses/lgpl-3.0.txt| }},
  requires             =>
# XXX:201405170202:whynot: Is there something not *that* long standing left?
# http://www.cpantesters.org/cpan/report/98753292-dd38-11e3-9f96-e4d5e82f99b1
  { perl                => qv( v5.8.0 ),
# FIXME:201404020142:whynot: How?
# http://www.cpantesters.org/cpan/report/4343e344-af71-11e3-b3f2-e50c8806f0e4
    version             =>  qv( v0.77 ),
# FIXME:201404020128:whynot: Go B<parent> as soon as B<perl> >= I<v5.10.1>
    base                =>           '',
    Carp                =>           '',
    Cwd                 =>           '',
    q|IO::Pipe|         =>           '',
    q|String::Truncate| =>           '',
    q|List::Util|       =>           ''                         },
  build_requires       =>
  { q|Test::More| => '',    q|File::Temp| => '',    POSIX => '' },
  recursive_test_files =>                                       1,
  pm_files =>
  { q|lib/AptFetch.pm|  =>        q|lib/File/AptFetch.pm|,
    q|lib/Simple.pm|    => q|lib/File/AptFetch/Simple.pm|       },
  pod_files            =>
  { q|lib/Cookbook.pod| =>    q|lib/File/AptFetch/Cookbook.pod| },
  add_to_cleanup       => [qw|              *.tmp *.bak skip_* |] );

=head1 BUILD-TIME CONFIGURATION

=over

=cut

=item I<lib_method>

That sets location of APT methods.
It's unrequired,
it will be set any time APT configuration is sourced.
L<File::AptFetch/_cache_configuration()> and
L<File::AptFetch/_uncache_configuration()> have more.

=cut

#$builder->config_data(lib_method    => q|/usr/lib/apt/methods|);

=item I<config_source>

Required.
C<ARRAY> ref that will be B<exec>ed.
L<File::AptFetch/_cache_configuration()> has more.

=cut

$builder->config_data( config_source => [qw| /usr/bin/apt-config dump |]);

=item I<signal>

Required.
Names a signal that will be sent to method.
L<File::AptFetch/DESTROY> has more.

=cut

$builder->config_data( signal => q|TERM| );

=item I<timeout>

=item I<tick>

I<(v0.0.8)>
Required.
I've believed, that could stay hardcoded.
I was wrong.
L<File::AptFetch/_read()> has more.

I<(v0.1.6)>
These are closely related.
From now on,
I<timeout> keeps the same semantics as before
(it's time to cut-off)
but is handled differently.
B<F::AF> object B<sleep>ed (literally) for time set.
Now it B<select>s (with magic) in I<tick>s.
(It's introduced for sake of B<F::AF::S>.)

Also.
Both must be naturals;
They're in seconds;
I<tick> is supposed to be couple of seconds (default: 5sec);
While I<timeout> is supposed to be large enough (default: 2min) in respect to
network introduced delays.

=cut

$builder->config_data( timeout => 120 );
$builder->config_data( tick    =>   5 );

=item I<beat>

=item I<wink>

I<(v0.1.9)> I<(B<F::AF::S> -- v0.1.4)>
Those two are for L<B<File::AptFetch::Simple>> (what has more) --
control progress indication.

=cut

$builder->config_data( beat => !0 );
$builder->config_data( wink => !0 );

=back

=cut

$builder->create_build_script( );

=head1 TEST-SUITE

Two things should be tested in regard with B<F::AF>:

=over

=item methods and structures

I wouldn't say I'm happy with this part (F<t/void/*.t>).
It's mostly a crash-type testing.
And a problem here is that I'm not completely sure what an input (from methods
side) here could be.

=item APT methods itself

Only local methods are tested.
And I<cdrom> method, among them, is no way touched.
Remote methods are missing from the test-suite.
This problem is easily fixable -- some kind Perlist could upload on CPAN some
modules, in B<Test> namespace, what would provide fake servers of
http://, ftp://, rsh:// etc protocols.
Anyone?

=back

And one note.
B<F::AF> is absolutely useles outside APT based world
(I'm not about F<*.deb>, I'm about APT).
Then F<t/file/*.t> and F<t/copy/*.t> skip completely.
Meanwhile F<t/void/*.t> enables some cute workaround, that would provide
all needed C<apt-config(1)> functionality without that executable itself.
(Just in case on that platform there will be Debian some day.)
But we still stay within POSIX world -- no future outside.

=cut

=head1 AVAILABILITY

=over

=item pure distribution

<http://search.cpan.org/dist/File-AptFetch/>

=item and debianization stuff too

# TODO

=item subversion (root)

# TODO

=back

=head1 BUGS

=over

=item please report here

<http://rt.cpan.org/Public/Dist/Display.html?Name=File-AptFetch/>

=item please don't report there

# TODO

=back

=head1 COPYRIGHT AND LICENSING

=over

=item *

Copyright 2009, 2010, 2014 by Eric Pozharski <whynot@cpan.org>

=item *

AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

=item *

GNU Lesser General Public License v3
<http://www.gnu.org/licenses/lgpl.txt>

=back
