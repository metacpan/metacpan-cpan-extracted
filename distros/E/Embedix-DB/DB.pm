package Embedix::DB;

use strict;
use vars qw($VERSION $AUTOLOAD);

# this class is central all things configuration-related
use Embedix::ECD;

# database back ends
use Embedix::DB::Pg;
#se Embedix::DB::mysql;

$VERSION = 0.05;

# Embedix::DB->new (
#   backend => 'Pg' # only one implemented so far
#   source  => [ 'dbi:Pg:dbname=embedix', $user, $password, $opt ],
# );
#
# factory method for Embedix::DB::* objects
#_______________________________________
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    (@_ & 1) && die("Odd number of parameters.");
    my %opt   = @_;

    # FIXME : this needs to be much more robust

    my $edb_class = "Embedix::DB::" . $opt{backend};

    my $self = $edb_class->new(source => $opt{source});

    return $self;
}


1;

__END__

=head1 NAME

Embedix::DB - persistence for ECDs

=head1 SYNOPSIS

instantiation

    my $edb = Embedix::DB->new (
        backend => 'Pg',
        source  => [ 
            'dbi:Pg:dbname=embedix',
            'user', 'password',
            { AutoCommit => 0 },
        ],
    );

    # $edb should be an instance of Embedix::DB::Pg

adding a distro

    $edb->addDistro (
        name  => 'uCLinux 2.4',
        board => 'm68k',
    );

    $edb->addDistro (
        name  => 'Embedix 1.2',
        board => 'ppc',
    );

selecting a distro to work on

    $edb->workOnDistro(name => 'Embedix 1.2', board => 'ppc');

cloning a distro

    $edb->cloneDistro(board => 'mpc8260adsp');

updating a distro with new information

    my $apache_ecd = Embedix::ECD->newFromFile('apache.ecd');
    $edb->updateDistro(ecd => $apache_ecd);

deleting components from a distro

    $edb->deleteNode(name => 'busybox');

=head1 REQUIRES

=over 4

=item Embedix::ECD

This is needed to get data from ECD files into perl objects that can
then be inserted into a database.

=item DBD::Pg

The PostgreSQL backend uses this.

=item DBD::mysql

If anyone writes a MySQL backend, it'll surely use this.

=back

=head1 DESCRIPTION

The "DB" in Embedix::DB stands for database.  Although Embedix::DB was
inspired by the B<tigger> code that implements the original Embedix
Database, the implementation strategy is quite different.

First, Embedix::DB is a means to provide persistence for data found in
ECD files.  Tigger uses the filesystem for this purpose.  Embedix::DB
may have a filesystem-based backend in the future, but the current
implementation provides a PostgreSQL-based backend.  The goal here was
to minimize the amount of parsing necessary to start an Embedix
configuration program (like TargetWizard).  By doing the CPU-intensive
parsing stage only once for when an Embedix distribution is initially
defined, startup can be much faster.  TargetWizard currently parses a
large collection of ECDs every time it starts up.

Beyond that, it has the ability to take ECD data and organize it
at a higher level into distributions.  Currently, it is awkward to use
a single TargetWizard installation to provide the ability to configure
different distributions.  For example, you could not use TargetWizard to
configure both a uCLinux distribution and an Embedix distribution during
the same session.  In order to do this, one would currently have to exit
TargetWizard, install a new config that points to the appropriate
directories, and restart TargetWizard.  Although tigger is theoretically
capable of handling this more gracefully, the directory structure for
how ECDs are stored doesn't facilitate this.  In contrast, Embedix::DB
was designed from the beginning to be able to manipulate multiple
distributions simultaneously.

Another area where Embedix::DB deviates from tigger is in node names
for ECDs.  Tigger requires that all nodes must have B<unique> names
regardless of the node's nesting.  Embedix::DB does not have this
restriction.  Hopefully, this will allow node names to be less contrived
in the future.

One significant difference between Embedix::DB and tigger is that
Embedix::DB does not handle dependency and conflict resolution.  That
job is delegated to Embedix::Config which will use an instance of
Embedix::DB to get information from the database when necessary.  Also
note that Embedix::DB does not know how to parse or generate ECD files.
That job belongs to Embedix::ECD.  Tigger does many things, and its
parts are tightly coupled making it difficult to use any given part of
it in isolation from the rest of tigger.  The functionality provided by
tigger is roughly equivalent to the functionality provided by
Embedix::ECD, Embedix::DB, and Embedix::Config.  (I need to make this
paragraph flow better).

The overall theme of Embedix::DB is to try to improve upon the areas
where tigger is lacking.  It's a lot of work, and I'd like to emphasize
that I'm not doing this out of disrespect.  Surely, I would have made
many of the same mistakes (and some original ones of my own) if I were
implementing this without the benefit of hindsight.  I believe the
concept of TargetWizard is a good one, and that's why I'm doing this.

Embedix::DB is an exploratory work where I am trying to put certain
ideas about how tigger could be improved into practice.

=head1 CONCEPTS

=over 8

=item distro

Short for "distribution".  Examples:  'Embedix 1.2', 'uCLinux 2.4'.
Distros are collections of ECDs.

=item board

A board is a name for a piece of hardware that a distro has been
ported to.  Examples:  'i386', 'm68k', 'ppc', 'alpha'.

=item node

From ECDs, the data enclosed within a <GROUP>, <COMPONENT>, <OPTION>,
<AUTOVAR>, or <ACTION> tag is the data of a node.  Nodes may be nested.

=item database

This is where it's all stored.  The underlying implementation may be
something other than a 'real' database.  For example, the filesystem
with a specific directory structure may be providing persistence.  We
still call that a database -- just play along.

=item cloning

When creating a derivative of a distro, it is convenient (and space
efficient) to use the cloneDistro() method to create a clone to work
on.  Think of it as a form of inheritance.

=back

=head1 METHODS

The Embedix::DB API provides methods for performing abstract operations
on the database.  Whether the backend is based on a filesystem or a
relational database, the same API should be applicable.

=head2 Initialization

First, one must connect to a database.

=over 4

=item new(backend => $str, source => $source_ref)

This instantiates an Embedix::DB with the appropriate backend.

    my $edb = Embedix::DB->new(
        backend => 'Pg',
        source  => [
            'dbi:Pg:dbname=embedix', $user, $pass,
            { AutoCommit => 0},
        ],
    );

C<$edb> will be an instance of Embedix::DB::Pg in this example.

=item workOnDistro(distro => $str, board => $str)

This method is used to set the current working distribution.  This
method is usually called immediately after the new(), because almost
all other methods require that a current working distribution has been
set.  (The only exception is addDistro()).

    $edb->workOnDistro(distro => 'Embedix 1.2', board => 'i386');

=back

=head2 Methods for defining distributions

Now that a connection to the database has been made, the database
may be populated.

=over 4

=item addDistro

This adds a new distribution to the database.

=item updateDistro

This takes data from an ECD and populates the current working database
with it.

=item cloneDistro

This takes the current working distribution and makes an exact clone
of it.  This method exists to make it easy to create variations on a
distribution using a sort of inheritance.  For example, the 
"Embedix 1.2" distro may have the following variations.

    generic
    |-- i386
    |-- mips
    |-- ppc
    |   `-- mpc8260adsp
    `-- sh
        |-- sh3
        `-- sh4

C<generic> would be a distro containing data from only architecturally
neutral ECDs.  The C<i386>, C<mips>, C<ppc>, and C<sh> versions of
"Embedix 1.2" would be derived from generic by using cloneDistro().
They would then be populated with additional data from
architecturally-specific ECDs.  ECD nodes may be removed as well as with
the case for the C<mpc8260adsp>.  Since it doesn't have a graphics
controller, it doesn't make sense to provide the X11 packages, so the
C<mpc8260adsp> would be a cloned C<ppc> distribution w/ the X11 packages
removed.

=item unrelateNode

This is used to dissociate a node from a distro.

=item relateNode

This is used to associate a node with a distro.

=item deleteNode

This totally deletes a node.  If a node has been cloned many times,
all the clones go away.  This is more serious than unrelateNode().

=back

=head2 Methods for querying the database

This is an area that still needs to be fleshed out.  As Embedix::Config
matures, this API will mature as well to.

=over 4

=item getComponentList

This returns an arrayref of the form:

    [
        [ '/category0' [ $node0, $node1, ... ] ],
        [ '/category1' [ $node0, $node1, ... ] ],
        ...
    ];

The list of categories as well as the list of nodes within each category
come sorted in ASCII order.

=item getDistroList

This returns an arrayref of the form:

    [
        [ 'distro0' [ $board0, $board1, ... ] ],
        [ 'distro1' [ $board0, $board1, ... ] ],
        ...
    ];

This is a list of distributions where each distribution has a list of
which boards it supports.  The board lists are sorted in ASCII order.

=back

=head1 DIAGNOSTICS

error messages

=head1 COPYRIGHT

Copyright (c) 2000,2001 John BEPPU.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 AUTHOR

John BEPPU <beppu@lineo.com>

=head1 SEE ALSO

=over 4

=item related perl modules

Embedix::ECD(3pm), Embedix::Config(3pm)

=back

=cut

# vim:ts=8 tw=72
# $Id: DB.pm,v 1.5 2001/03/09 13:53:51 beppu Exp $
