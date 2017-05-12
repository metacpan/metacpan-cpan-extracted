package Kwiki::Kwiki;
use strict;
use warnings;
use 5.008004;

our $VERSION = '0.10';

use Kwiki::Kwiki::Command;
use Kwiki::Kwiki::Command::Lib;
use Kwiki::Kwiki::Command::Distfile;
use Kwiki::Kwiki::Command::Init;
use Kwiki::Kwiki::Command::Source;

sub make_init {
    Kwiki::Kwiki::Command::Init->new->process;
}

sub make_src {
    Kwiki::Kwiki::Command::Source->new->process;
}

sub make_lib {
    Kwiki::Kwiki::Command::Lib->new->process;
}

sub make_cpan_lib {
    Kwiki::Kwiki::Command::Lib->new->process_cpan;
}

sub make_dist {
    Kwiki::Kwiki::Command::Distfile->new->process;
}


__END__

=head1 NAME

Kwiki-Kwiki - Kwiki Kwiki is a Wiki

=head1 SYNOPSIS

Typical Usage of Kwiki::Kwiki

    > mkdir site
    > cd site
    > kwiki -new
    > kk -init
    # Edit source code list
    > vim kwiki/sources/list
    # Download all the source code
    > kk -src
    # Make lib directory
    > kk -lib
    # Make distribution tarball
    > kk -dist
    # Run built-in Server
    > bin/server

=head1 DESCRIPTION

KwikiKwiki is a Wiki distribution toolkit, or framework. It's the best way to
spread your own copy of wiki to friends.

Most folks think that Kwiki is wiki software, and in a sense it is. But the
main purpose of Kwiki is to be a framework for creating wiki software. In
other words, it's a Perl hacker's playground. Most of the energy was put into
figuring out how plugins from various folks could play well together, and less
thought was put into how to simply run a wiki with the features you'd expect.

This is where KwikiKwiki comes in.

KwikiKwiki ships a "server" script under "bin/" directory. It is a pure-perl
http server just for serving this Kwiki directory. Therefore it is suggest
to leave the default source list intact, and add more your own.

KwikiKwiki installs a C<kk> script to your system. It's the front-end for
build KwikiKwiki distributions. There are four phrases to build a
distribution: 1. Create a new Kwiki directory 2. Get the source code,
3. Install to lib dir 3. Create a distribution tarball. C<kk> script works
with the C<kwiki> script, you should make sure that current Kwiki directory is
runnable and has plugins of your own choice before using C<kk> to create
distribution.

There are four arguments to C<kk> : <-init> initialize a C<kwiki/> directory
under current working directory, and you should edit C<kwiki/source/list> for
your own need. Plugins are auto-bundled, so you don't have to add them to the
list.

The source list file contains information where to find perl modules, lines
begin with C<===> are source types, lines begin with C<---> are sources.
There are four possible source types: svn, local, inc, cpan. For svn sources,
please give the repository url to the module directory (which should contain a
sub-directory 'lib'). For example, L<http://svn.kwiki.org/ingy/Kwiki>. For
local sources, please give the path to your module directories. For example,
C</home/gugod/src/Kwiki-NewStuff/>. For inc sources, please give the path of
module file names relative to @INC. For example, C<File/Temp.pm>. For cpan
sources, just give the full name of that module. For example,
C<Kwiki::Comments>. All fetched source are stored under C<kwiki/> directory,
and are excluded in the creation of distribution tarball.

Invoking <-src> argumenets will download all sources, and <-lib> just build a
C<lib> directory for all sources. After calling C<kk -lib>, pre-requesties
should all be installed to C<lib>.

Calling C<kk -dist> will create a tarball with the same name of current
working directory. You should be able to give away this tarball, and people
who extract it should be able to run

  bin/server

And have a Kwiki server running on localhost, port 8080.

That's pretty much about the current feature of KwikiKwiki.

=head1 SYSTEM REQUIREMENTS
 
=over

=item Perl 5.8.4 or higher

Kwiki uses unicode, and unicode didn't really stabilize until Perl
5.8.4. If you try to run Kwiki on older perls, you will likely run into
problems. So Kwiki-Kwiki requires 5.8.4 or higher.

=item Subversion 1.0 or higher

Depending on how you configure Kwiki-Kwiki, you may need subversion. You
really want subversion. It makes life so much simpler. If you really
can't get it on your machine, that's ok.

=item A working CPAN configuration.

Kwiki-Kwiki may uses your exist CPAN configuration to install CPAN modules
locally under "lib" directory, please make sure your CPAN installation is
configured well.

=back

=head1 Methods

=over 4

=item make_src

Download module source code from remote and extract it locally.

=item make_lib

Install all .pm files locally under kwiki/lib/

=item make_cpan_lib

Install all CPAN modules locally under lib/

=item make_dist

Create a distfile named based on current directory name.

=back

=head1 AUTHORS

Ingy döt Net <ingy@cpan.org>

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net, Kang-min Liu. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
