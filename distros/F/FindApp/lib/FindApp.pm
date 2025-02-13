package FindApp;

use v5.10;
use strict;
use warnings;
use mro "c3";

our $VERSION = "v0.0.7";

use FindApp::Vars       qw(:all);
use FindApp::Utils      qw(:package);
use namespace::clean;
use FindApp::Utils      <tracing debugging>;
use parent subpackage   Object => with "Exporter";

# Don't do this here!!!
#__PACKAGE__->renew();

1;

=encoding utf8

=head1 NAME

FindApp - find your application home and config your process for it

=head1 SYNOPSIS

 use FindApp;           # defaults to "lib" argument
 use FindApp "lib";     # explicit

That guarantees that this will always src, presuming there is
a "lib" above you that has the "MyCorp::CorpApp" module under it:

 use FindApp "MyCorp::CorpApp";
 use MyCorp::CorpApp;

Or load-and-go:

 use FindApp -root => "lib/", -use "MyCorp::CorpApp";

AKA:

 use applib "MyCorp::CorpApp";

=head1 DESCRIPTION

When you have a application directory with its own installation
instructure, setting up its @INC path for its scripts to use
can be troublesome.   You can't just say:

    use lib "lib";

or

    use lib "../lib";

because that requires that the program be run from a particular
directory.  The normal approach is something like this:

    use FindBin;
    use lib "$FindBin::Bin/../lib";

Even when possible in a few cases, it doesn't src for scripts that
you want to move around your application tree, such as test files,
support tools that may be in a prod-vs-nonprod directory, cron scripts,
and all the rest.

When you say C<use FindApp>, the first enclosing directory that matches
the selection criteria is used.  The default selection criterion is that
the root application directory contain a directory called "lib", which
will be added to your @INC.  You can also look at the current selection
criteria this way:

    bash$ perl -MFindApp -le 'print FindApp->constraint_text'
    lib/ in root

What it actually does is something like this:

    bash$ perl -MFindApp -e 'print FindApp->shell_settings'
    export APP_ROOT="/home/tchrist/src/corp-app";
    export PERL5LIB="/home/tchrist/src/corp-app/lib:$PERL5LIB";
    export PATH-"/home/tchrist/src/corp-app/bin:$PATH";

Except that it only does a C<use lib> on the library directory it found; it doesn't
actually muck with your PERL5LIB variable.

That's something you could eval directly from your shell.  This even
srcs for I<csh> and I<tcsh> users, because they see something different:

    tcsh% perl -MFindApp -e 'print FindApp->shell_settings'
    setenv APP_ROOT "/home/tchrist/src/corp-app";
    setenv PERL5LIB "/home/tchrist/src/corp-app/lib:$PERL5LIB";
    setenv PATH "/home/tchrist/src/corp-app/bin:$PATH";

You can add constraints to the root directory itself or the bin set, the lib set,
or the man set.  For example,

     use FindApp -LIB "t/lib",          # add new lib possibility
                 -BIN "bin/utils",      # add new bin possibility
                 -bin "app.fcgi",       # add new bin requirement
                 qw(MyCorp::CorpApp MyCorp::CorpApp::Test);  # add two lib requirements

The constraint text after that would be:

    lib/ in root, app.fcgi in bin or bin/utils, and MyCorp::CorpApp and MyCorp::CorpApp::Test in lib or t/lib

=head2 Public Methods

=over

=back

=head2 Exports

=over

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
