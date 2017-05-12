package Mac::Spotlight::MDQuery;

use 5.008;
use strict;
use warnings;
use Mac::Spotlight::MDItem;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'constants' => [ qw(
			 kMDQueryScopeHome 
			 kMDQueryScopeComputer
			 kMDQueryScopeNetwork )
				      ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'constants'} } );
our @EXPORT = qw();

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Mac::Spotlight::MDQuery', $VERSION);


sub new {
    my ($class, $qString) = @_;
    my $self = {};
    bless $self, $class;

    $self->{_qObj} = _new($qString);
    return undef if (!defined $self->{_qObj});
    return $self;
}


sub scope {
    return @{$_[0]->{_scope}};
}


sub setScope {
    my ($self, @scopes) = @_;

    # FIXME: Do we want this to return something or not?
    _setSearchScope($self->{_qObj}, \@scopes);
    # There's no corresponding MDQueryGetSearchScope(), so we note it here
    $self->{_scope} = \@scopes;
    return 1;
}
    

# FIXME: This can be made a call straight into XS
sub execute {
    return _execute($_[0]->{_qObj});
}


sub stop {
    _stop($_[0]->{_qObj});
}


sub getResults {
    return _getResults($_[0]->{_qObj});
}

sub DESTROY {
    _destroy($_[0]->{_qObj}) if defined $_[0]->{_qObj};
    undef $_[0]->{_scope};
}


1;
__END__


=head1 NAME

Mac::Spotlight::MDQuery - Make a query into OS X Spotlight

=head1 SYNOPSIS

  use Mac::Spotlight::MDQuery ':constants';
  use Mac::Spotlight::MDItem ':constants';

  $mdq = new Mac::Spotlight::MDQuery('kMDItemTitle == "*Battlestar*"c');
  $mdq->setScope(kMDQueryScopeComputer);

  $mdq->execute();
  $mdq->stop();

  @results = $mdq->getResults();
  foreach $r (@results) {
    print $r->get(kMDItemTitle), "\n";
    print $r->get(kMDItemKind), "\n";

    $listref = $r->get(kMDItemAuthors);
    foreach $a (@$listref) {
      print "$a\n";
    }

    if ($r->get(kMDItemStreamable)) {
      print "Content is streamable\n";
    }
    print scalar localtime($r->get(kMDItemContentCreationDate)), "\n";
  }

=head1 DESCRIPTION

Mac::Spotlight is primarily accessed through two subpackages MDQuery
and MDItem. An MDQuery object is used to run a query and obtain the
results. The results are in a list containing zero or more MDItem
objects. This POD documents the methods of MDQuery. See the MDItem POD
for MDItem's methods and a complete list of all the available
Spotlight attributes.

=head1 METHODS

=over 4

=item C<new>

Create a new MDQuery that will run the given query string when it
executes. The query string must be supplied to the constructor and
cannot be changed once the object is created. For the full format of
query strings see the URL L<http://developer.apple.com/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html>. For the full list of
attributes that can be queried see the POD for MDItem. Do note that
unlike the B<mdfind> command, you must provide at least one attribute
to be queried. (If you don't provide one to B<mdfind> it picks a few for
you.)

new() will return undef if the query string is malformed or if the
underlying Core Foundation object cannot be allocated.

=item C<setScope>

setScope() takes a list of zero or more MDQuery constants which define
the scope of the query when it is executed. The constants are imported
into your current namespace when you use the ':constants'
tag. Currently there are three defined constants:

=over 4

=item kMDQueryScopeHome

Limit the query to the current user's home directory

=item kMDQueryScopeComputer

Limit the query to all locally mounted volumes

=item kMDQueryScopeNetwork

Try to include currently mounted remote volumes in the query

=back

You can do $mdq->setScope() which will effectively stop the query from
doing anything when it is executed.

=item C<scope>

Return the list of scopes set for this query.

=item C<execute>

Do it! This runs the query and holds the results until they are
retrieved with getResults(). If the query fails to start for any
reason execute() will return undef. All MDQuery queries are executed
I<synchronously> so execute() will not return until the Spotlight
query is complete. Once execute() is called on an MDQuery object you
cannot call execute() on that object again.

=item C<stop>

Even though execute() currently runs synchronously, that may not
always be the case in the future. Spotlight has the ability to return
an initial set of results and then continue to update those results in
the background as it finds more matches. Running execute()
synchronously tells Spotlight not to return anything until it finds
everything. It is still a good idea to call stop() before you call
getResults(). If you don't, then if something changes in
Mac::Spotlight in the future, you may find that Spotlight is trying to
update your search results at the same time as you are trying to
access them.

=item C<getResults>

Returns an array of zero or more MDItem objects. Each object
represents one filesystem object that matched your query. See the POD
for MDItem.

=head2 EXPORT

None by default.

=head2 Exportable values

If you use the ":constants" tag when you use Mac::Spotlight::MDQuery,
you will pull the kMDQuery* constants into your current namespace. If
you chose not to you can still access the constants via their fully
qualified namespace.

=head1 SEE ALSO

Mac::Spotlight::MDItem

=head1 AUTHOR

Adrian Hosey, E<lt>alh@warhound.orgE<gt>

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Adrian Hosey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
