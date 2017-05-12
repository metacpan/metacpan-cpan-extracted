#!/usr/bin/perl
#
# This file is not a real module,
# it just delivers 4 things required to make CPAN infrastructure happy:
#
#  - file name with .pm -- pass ticket to CPAN
#  - package name
#  - version of distribution
#  - README content in .pod format
#
package Funifs;

$VERSION = '1.3';

1;
__END__

=pod

=head1 NAME

Funifs - FUSE read-only Union Filesystem

=head1 OBJECTIVE

Funifs implements a limited set of unionfs filesystem features
(a read-only union of read-only branches)
sufficient for staging web site testing and development.

The primary motivation for funifs comes from the KISS principle:
make something easy, stable and extensionsable.

=head1 HOSTED ON

 https://funifs.googlecode.com/hg/
 http://search.cpan.org/~vova/Funifs/

=head1 INSTALLATION

After downloading and unpacking the tarball, run this in the directory with Build.PL:

./Build.PL ; ./Build ; ./Build test ; ./Build install

=head1 PACKAGE FILES

 funifs  - /usr/sbin/funifs - funifs userspace FUSE driver
 rcfunifs - /etc/init.d/funifs - service script to mount/unmount at system boot
 fstab (in /usr/share/doc/packages/funifs/) - examples of /etc/fstab lines.

=head1 DRY RUN

For those of you who are as paranoid as me,
before installing to your system directories, make sure:

./Build.PL --install_base=/var/tmp/Funifs ; ./Build ; ./Build test ; ./Build install

If running it as a regular user fails,
add "user_allow_other" to /etc/fuse.conf.
That should make the Build test happy.
Or, just run it as root.

=head1 USAGE CONCEPT

Let's say we have a production website configured like this:

  ServerName      www.site.com
  DocumentRoot    /srv/site.com/www/root

And a staging website configured like this:

  ServerName      w.u.site.com
  DocumentRoot    /srv/site.com/u/w/root

To mount the staging directory tree (w.u) on top
of the production directory tree (www),
configure /etc/fstab like this:

 /u/w /srv/site.com/u/w fuse.funifs dirs=/delta/site.com/u/w:/srv/site.com/www 0 0

Your staging website's DocumentRoot now consists of
the production tree overlain with any differences from the staging tree.
Delta branches sandwich can have multiple layers, not just one.

=head1 PREREQUISITES

Funifs relies on FUSE library, fuse.ko kernel module, and perl modules:

 * Fuse
 * Filesys::Statvfs
 * Unix::Syslog
 * Module::Build

Perl module Fuse.pm works flawless starting version Fuse-0.08.
Multi-threaded use has buggy history on RHEL/Centos 5.

=head1 AVOID INDEXING

It's recommended to disable filesystem crawling for "fuse" type filesystems.
You may want to update system configuration files, such as
  /etc/sysconfig/locate
  /etc/cron.daily/slocate.cron
  /etc/updatedb.conf
  /usr/share/msec/security.sh

=head1 KNOWN ISSUES

Funifs is not a comprehensive driver, it has limited features
due to specific demands and stacking nature. The most visible are:

=head2 Lack of whiteouts support

"Whiteout" is the way to "remove" file from the union, when it
physically exists in one of branches. That is, if program code relies on
a file presence test

-f $path ...

and file exists in bottom branch of union, funifs has no way to emulate
removal by manipulating the delta branches content.

Application code should not rely on a file presence.
For a templates (where empty file equivalent to missing file)
the lack of whiteout-s is not an issue: zero-size file in top layer
has the same effect as the whiteout.

=head2 Lack of persistent i-nodes support

Unionfs semantics by it's nature is inaccurate about files i-nodes,
thus any attempt to compare two files i-nodes most likely will return false,
even for identical files on underlying filesystem branches.
Application code should not rely on i-node values.

=head2 Copy file to "itself" bug

Attempt to copy file to delta branch from another branch using the union
as the source tends to produce empty file of non-zero length.
Fix for this issue is not known: funifs driver is unable to control this.
Application code should refer to bottom branch content explicitly,
rather then use result of union-ing.

=head1 LICENSE AND COPYRIGHT

Copyright (C) Vladimir V. Kolpakov [aka double-you] 2006-2011

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 THANKS

To Stephane Saux and Ben Schein at SFGate for inspiration and insistency,
to Mark Glines and Dobrica Pavlinusic for the bridge FUSE--Perl,
to Denis Cirulis at opensource for the bugs hunting.

=head1 FEEDBACKS

I would really appreciate it if you could publish your ideas,
bug reports, or feature request on
http://groups.google.com/group/funifs/topics
or even submit fixes on funifs.googlecode.com.

Releasing new version on googlecode,
don't forget also upload tarball to CPAN, that is result of the

./Build dist

=head1 SEE ALSO

Funion - somewhat similar to funifs, but seems unfinished
http://code.google.com/p/funion/

Unionfs-fuse - read/write FUSE union
http://podgorny.cz/moin/UnionFsFuse

Perl wrapper for FUSE
http://search.cpan.org/~dpavlin/Fuse/

=cut
