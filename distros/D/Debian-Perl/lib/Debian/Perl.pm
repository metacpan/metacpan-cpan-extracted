##
# name:      Debian::Perl
# abstract:  Package Perl Modules for Debian. Painlessly!
# author:    Ingy döt Net
# license:   perl
# copyright: 2011
# see:
# - DhMakePerl
# - Module::Install::Debian::Perl

package Debian::Perl;
use 5.008003;
our $VERSION = '0.01';
use Mouse;

sub build {
    print "\nBuilding your Debian Package...\n";
    sleep 1;
    print "\n...just kidding. coming soon though!\n\n";
}

sub release {
    print "\nReleasing your Debian Package...\n";
    sleep 1;
    print "\n...just kidding. coming soon though!\n\n";
}

sub make_debian {
    Debian::Perl->new->build;
}

sub make_release {
    Debian::Perl->new->release;
}

#-----------------------------------------------------------------------------
# App::Cmd support for the `debian-perl` command.
#-----------------------------------------------------------------------------
sub make_debian {
    Debian::Perl->new->build;
}

sub make_release {
    Debian::Perl->new->release;
}

package Debian::Perl::Cmd;
use Mouse;
extends 'MouseX::App::Cmd';

package Debian::Perl::Cmd::Command;
use Mouse;
extends 'MouseX::App::Cmd::Command';

use constant abstract => '';

package Debian::Perl::Cmd::Command::build;
use Mouse;
extends 'Debian::Perl::Cmd::Command';

sub execute {
    Debian::Perl->new->build;
}

package Debian::Perl::Cmd::Command::release;
use Mouse;
extends 'Debian::Perl::Cmd::Command';

sub execute {
    Debian::Perl->new->release;
}

1;

=head1 SYNOPSIS

From the command line:

    > debian-perl build
    > debian-perl release

From a Perl module directory:

    > Perl Makefile.PL
    > make debian
    > make release

=head1 DESCRIPTION

If you are a Perl module author, you probably know quite a bit about Perl,
modules and CPAN. You probably know about Debian Linux. There's even a decent
chance you've used it. However, there's only a very slim chance that you
maintain Debian packages for your modules.

Let's assume that this at least vaguely describes you. If someone told you
that you could flip a switch, and then every time you released a module to
CPAN, it went to Debian (perfectly packaged to their standards), you'd
probably flip that switch.

This module aspires to be that switch. It wants you to be a Debian Maintainer
for free. You may end up becoming a full fledged Debian guru one day, but for
now you just want to see your code available to a whole new world, without
having to know the details. As long as this switch doesn't tell you
otherwise, you know that you did the all right things.

This module is just a helping hand that automates all the standard best
practices for you. It bends over backwards to help you get that module to
Debian without having to know any more than is expected of a busy Perl module
author, like you.

Specifically it uses things like C<dh-make-perl>, C<debuild>, C<pbuilder> and
C<lintian>. If you've never heard of these things, that's ok. Until this week,
neither did I. They all do a lot of work, and they aren't that hard to use,
but the learning curve is quite high. As soon as Debian::Perl is stable and
shipping all my CPAN modules to Debian, I plan to forget about them as quickly
as possible. :)

=head1 USAGE

There are two ways to use this module. There is a command called
C<debian-perl> that you can use to prepare, build, test and release Debian
packages from your Perl module. There is also a Module::Install plugin that
allows you to simply do:

    > make debian

See L<Module::Install::Debian::Perl>

=head1 MORE DOCUMENTATION

Coming soon...

=head1 STATUS

This module is brand new and in heavy development. Nothing to see here. Move
along.

=head1 KUDOS

Many thanks to the great folks at Strategic Data for supporting the creation
of this module.

Extra special thanks to Andrew Pam, the resident Debian guru at Strategic
Data, for providing all the right pointers.

Also a nod to Jeremiah Foster whose article in The Perl Review from the Spring
2009 issue, not only pointed me in the right directions, but also convinced me
that the process was still not quite consumable by the masses. I look forward
to working with you and the debian-perl team.
