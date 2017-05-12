package JSAN::Index;

=pod

=head1 NAME

JSAN::Index - JavaScript Archive Network (JSAN) SQLite/ORLite Index

=head1 DESCRIPTION

JSAN is the JavaScript Archive Network, a port of CPAN to JavaScript.

You can find the JSAN at L<http://openjsan.org>.

As well as a flat text file index like CPAN, the JSAN index is also
distributed as a L<DBD::SQLite> database.

C<JSAN::Index> is a L<ORLite> wrapper built around the JSAN
SQLite index.

It allow you to easily do all sorts of nifty things with the index in a
simple and straight forward way.

=head2 Using The JSAN Index / Terminology

Once loaded, most of the functionality of the index is accessed through
the classes that implement the various objects in the index.

These are:

=over 4

=item L<JSAN::Index::Author>

An author is a single human (or under certain very special circumstances
a company or mailing list) that creates distributions and uploads them
to the JSAN.

=item L<JSAN::Index::Distribution>

A distribution is a single software component that may go through a number
of releases

=item L<JSAN::Index::Release>

A release is a compressed archive file containing a single version of a
paricular distribution.

=item L<JSAN::Index::Library>

A library is a single class, or rather a "pseudo-namespace", that
defines an interface to provide some functionality. Distributions often
contain a number of libraries, making up a complete "API".

=back

=head1 METHODS

There are only a very limited number of utility methods available
directly from the C<JSAN::Index> class itself.

=cut

use 5.008005;
use strict;
use warnings;
use Params::Util   1.00 ();
use Carp                ();
use DBI                 ();


use JSAN::Transport;
use JSAN::Index::Author                 ();
use JSAN::Index::Library                ();
use JSAN::Index::Release                ();
use JSAN::Index::Release::Dependency    ();
use JSAN::Index::Release::Source        ();
use JSAN::Index::Distribution           ();

our $VERSION = '0.29';

my $SINGLETON = undef;

#####################################################################
# Constructor

=pod

=head2 init param => $value, ...

The C<init> method initializes the JSAN index adapter. It takes a set of
parameters and initializes the C<JSAN::Index> class. JSAN::Index is a 
singleton, so only it can initialized only once. Any further attempts 
to do so will result in an exception being thrown.
 
=cut


sub init {
    Carp::croak("JSAN::Index already initialized") if $SINGLETON;
    
    my $class  = shift;
    my $params = Params::Util::_HASH(shift) || {};
    
    my $transport = JSAN::Transport->new(
        mirror_remote => delete $params->{mirror_remote},
        mirror_local  => delete $params->{mirror_local},
        verbose       => $params->{verbose},
    );
    
    $SINGLETON = bless { 
        transport   => $transport,
        file        => $transport->index_file,
        verbose     => delete $params->{verbose}
    }, $class;
}




#####################################################################
# Top-level Methods

=pod

=head2 dependency param => $value

The C<dependency> method creates and returns an dependency resolution 
object that is used by L<JSAN::Client> to schedule which releases to
install.

If the optional parameter 'build' is true, creates a build-time
dependency resolve, which will additionally install releases only needed
for testing.

Returns an L<Algorithm::Dependency> object.

=cut

sub dependency {
    my $class  = shift;
    JSAN::Index::Release::Dependency->new( @_ );
}


=pod

=head2 transport

This accessor return an instance of JSAN::Transport, which can be used
for managing files of current mirror.

=cut

sub transport {
    Carp::croak("JSAN::Index is not initialized") unless $SINGLETON;
    $SINGLETON->{transport}
}


=pod

=head2 self

This accessor return a singleton instance of JSAN::Index, or undef is its
not initialized yet.

=cut

sub self {
    $SINGLETON
}

#####################################################################
# Database connectivity


sub sqlite {
    $SINGLETON || Carp::croak('JSAN::Index is not initialized yet');
    
    $SINGLETON->{file} 
}

sub dsn { 
    "dbi:SQLite:" . shift->sqlite 
}


sub dbh {
    $_[0]->connect;
}

sub connect {
    DBI->connect( $_[0]->dsn, undef, undef, {
        PrintError => 0,
        RaiseError => 1,
    } );
}

sub prepare {
    shift->dbh->prepare(@_);
}

sub do {
    shift->dbh->do(@_);
}

sub selectall_arrayref {
    shift->dbh->selectall_arrayref(@_);
}

sub selectall_hashref {
    shift->dbh->selectall_hashref(@_);
}

sub selectcol_arrayref {
    shift->dbh->selectcol_arrayref(@_);
}

sub selectrow_array {
    shift->dbh->selectrow_array(@_);
}

sub selectrow_arrayref {
    shift->dbh->selectrow_arrayref(@_);
}

sub selectrow_hashref {
    shift->dbh->selectrow_hashref(@_);
}

sub pragma {
    $_[0]->do("pragma $_[1] = $_[2]") if @_ > 2;
    $_[0]->selectrow_arrayref("pragma $_[1]")->[0];
}

sub iterate {
    my $class = shift;
    my $call  = pop;
    my $sth   = $class->prepare( shift );
    $sth->execute( @_ );
    while ( $_ = $sth->fetchrow_arrayref ) {
        $call->() or last;
    }
    $sth->finish;
}


1;

__END__

=pod

=head2 dsn

  my $string = JSAN::Index->dsn;

The C<dsn> accessor returns the L<DBI> connection string used to connect
to the SQLite database as a string.

=head2 dbh

  my $handle = JSAN::Index->dbh;

To reliably prevent potential L<SQLite> deadlocks resulting from multiple
connections in a single process, each ORLite package will only ever
maintain a single connection to the database.

During a transaction, this will be the same (cached) database handle.

Although in most situations you should not need a direct DBI connection
handle, the C<dbh> method provides a method for getting a direct
connection in a way that is compatible with connection management in
L<ORLite>.

Please note that these connections should be short-lived, you should
never hold onto a connection beyond your immediate scope.

The transaction system in ORLite is specifically designed so that code
using the database should never have to know whether or not it is in a
transation.

Because of this, you should B<never> call the -E<gt>disconnect method
on the database handles yourself, as the handle may be that of a
currently running transaction.

Further, you should do your own transaction management on a handle
provided by the <dbh> method.

In cases where there are extreme needs, and you B<absolutely> have to
violate these connection handling rules, you should create your own
completely manual DBI-E<gt>connect call to the database, using the connect
string provided by the C<dsn> method.

The C<dbh> method returns a L<DBI::db> object, or throws an exception on
error.

=head2 selectall_arrayref

The C<selectall_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_hashref

The C<selectall_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectcol_arrayref

The C<selectcol_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_array

The C<selectrow_array> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_arrayref

The C<selectrow_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_hashref

The C<selectrow_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 prepare

The C<prepare> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction

It takes the same parameters and has the same return values and error
behaviour.

In general though, you should try to avoid the use of your own prepared
statements if possible, although this is only a recommendation and by
no means prohibited.

=head2 pragma

  # Get the user_version for the schema
  my $version = JSAN::Index->pragma('user_version');

The C<pragma> method provides a convenient method for fetching a pragma
for a datase. See the SQLite documentation for more details.

=head1 SUPPORT

JSAN::Index is based on L<ORLite> 1.25.

Documentation created by L<ORLite::Pod> 0.07.

For general support please see the support section of the main
project documentation.

=head1 COPYRIGHT

Copyright 2009 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
