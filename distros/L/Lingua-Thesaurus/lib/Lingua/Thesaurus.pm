package Lingua::Thesaurus;
use 5.010;
use Moose;
use Module::Load ();
use Carp;
use namespace::clean -except => 'meta';

our $VERSION = '0.13';

has 'storage'          => (is => 'ro', does => 'Lingua::Thesaurus::Storage',
                           handles => [qw/search_terms fetch_term
                                          rel_types    fetch_rel_type/],
         documentation => "storage engine for the thesaurus");

sub BUILDARGS {
  my $class = shift;
  @_ > 1 or croak "not enough arguments";

  # load the storage subclass
  my $storage_class = $class->_load_component_class(Storage => shift);

  # instanciate storage, passing all our args, and get this as input for new()
  return {storage => $storage_class->new(@_)};
}

sub load {
  my $self     = shift;

  # load and instanciate the IO subclass
  my $io_class = $self->_load_component_class(IO => shift);
  my $io_obj   = $io_class->new(storage => $self->storage);

  # forward the call to the IO object
  $io_obj->load(@_);
}

sub _load_component_class {
  my ($class, $family, $subclass) = @_;

  # prefix $subclass by the family namespace, unless it starts with '+'
  s/^\+// or s/^/Lingua::Thesaurus::${family}::/ for $subclass;

  # load that class and return
  Module::Load::load($subclass);
  return $subclass;
}

1; # End of Lingua::Thesaurus


__END__

=encoding ISO8859-1

=head1 NAME

Lingua::Thesaurus - Thesaurus management

=head1 SYNOPSIS

=head2 Creating a thesaurus

  my $thesaurus = Lingua::Thesaurus->new(SQLite => $dbname);
  $thesaurus->load($io_class => @files);
  $thesaurus->load($io_class => {$origin1 => $file1, ...});
  $thesaurus->load($io_class => {files => \@files,
                                 params  => {termClass => ..,
                                             relTypeClass => ..}});

=head2 Using a thesaurus

  my $thesaurus = Lingua::Thesaurus->new(SQLite => $dbname);

  my @terms = $thesaurus->search_terms('*foo*');
  my $term  = $thesaurus->fetch_term('foobar');

  my $scope_note = $term->SN; # returns a string
  my @synonyms   = $term->UF; # returns a list of other terms

  foreach my $pair ($term->related(qw/NT RT/)) {
    my ($rel_type, $item) = @$pair;
    printf "  %s(%s) = %s\n", $rel_type->description, $rel_type->rel_id, $item;
  }

  # transitive search
  foreach my $quadruple ($term->transitively_related(qw/NT/)) {
    my ($rel_type, $related_term, $through_term, $level) = @$quadruple;
    printf "  %s($level): %s (through %s)\n", 
       $rel_type->rel_id,
       $level,
       $related_term->string,
       $through_term->string;
  }

=head1 DESCRIPTION

This distribution manages I<thesauri>. A thesaurus is a list of
terms, with some relations (like for example "broader term" /
"narrower term"). Relations are either "internal" (between two terms),
or "external" (between a term and some external data, like for example
a "Scope Note"). Relations may have a reciprocal;
see L<Lingua::Thesaurus::RelType>.

Thesauri are loaded from one or several I<IO formats>; usually this will be
the ISO 2788 format, or some derivative from it. See classes under the
L<Lingua::Thesaurus::IO> namespace for various implementations.

Once loaded, thesauri are stored via a I<storage class>; this is
meant to be an efficient internal structure for supporting searches.
Currently, only L<Lingua::Thesaurus::Storage::SQLite> is implemented;
but the architecture allows for other storage classes to be defined,
as long as they comply with the L<Lingua::Thesaurus::Storage> role.

Terms are retrieved through the L</"search_terms"> and L</"fetch_term">
methods. The results are instances of L<Lingua::Thesaurus::Term>;
these objects have navigation methods for retrieving related terms.

This distribution was originally targeted for dealing with the
Swiss thesaurus for justice "Jurivoc"
(see L<Lingua::Thesaurus::IO::Jurivoc>).
However, the framework should be easily extensible to other needs.
Other Perl modules for thesauri are briefly discussed below
in the L</"SEE ALSO"> section.

Side note: another motivation for writing this distribution was also
to experiment with L<Moose> meta-programming possibilities.
Subclasses of L<Lingua::Thesaurus::Term> are created dynamically
for implementing relation methods C<NT>, C<BT>, etc. ---
see L<Lingua::Thesaurus::Storage> source code.

B<Caveat>: at the moment, IO classes only implement loading and
searching; methods for editing and dumping a thesaurus will be added in a
future version.


=head1 METHODS

=head2 new

  my $thesaurus = Lingua::Thesaurus->new($storage_class => @storage_args);

Instanciates a thesaurus on a given storage.
The C<$storage_class> will be automatically prefixed by
C<Lingua::Thesaurus::Storage::>, unless the classname contains
an initial C<'+'>. The remaining arguments are transmitted to the
storage class. Since L<Lingua::Thesaurus::Storage::SQLite> is the default
storage class supplied with this distribution, thesauri are usually opened
as 

  my $dbname = '/path/to/some/file.sqlite';
  my $thesaurus = Lingua::Thesaurus->new(SQLite => $dbname);

=head2 load

  $thesaurus->load($io_class => @files);
  $thesaurus->load($io_class => {$origin1 => $file1, ...});
  $thesaurus->load($io_class => {files => \@files,
                                 params  => {termClass    => ..,
                                             relTypeClass => ..}});

Populates a thesaurus database with data from thesauri dumpfiles.  The
job of parsing these files is delegated to some C<IO> subclass, given
as first argument. The C<$io_class> will be automatically prefixed by
C<Lingua::Thesaurus::IO::>, unless the classname contains an initial
C<'+'>. The remaining arguments are transmitted to the IO class; the
simplest form is just a list of dumpfiles, or a hashref of pairs C<<
{$origin1 => $dumpfile1, ...} >>. Each C<$origin> is a string for
tagging terms coming from that dumpfile; while interrogating the
thesaurus, origins can be retrieved from C<< $term->origin >>.  See IO
subclasses in the L<Lingua::Thesaurus::IO> namespace for more details.

=head3 search_terms

  my @terms = $thesaurus->search_terms($pattern, $origin);

Searches the term database according to C<$pattern>, where
the pattern may contain C<'*'> to mean word completion.

The interpretation of patterns depends on the storage
engine; by default, this is implemented using SQLite's
"LIKE" function (see L<http://www.sqlite.org/lang_expr.html#like>).
Characters C<'*'> in the pattern are translated into
C<'%'> for the LIKE function to work as expected.

It is also possible to configure the storage to use fulltext
searches, so that a pattern such as C<'sci*'> would also match
C<'computer science'>; see
L<Lingua::Thesaurus::Storage::SQLite/use_fulltext>.

If C<$pattern> is empty, the method returns the list
of all terms in the thesaurus.

The second argument C<$origin> is optional; it may be used
to restrict the search on terms loaded from one specific origin.

Results are instances of L<Lingua::Thesaurus::Term>.

=head3 fetch_term

  my $term = $thesaurus->fetch_term($term_string, $origin);

Retrieves a specific term and
returns an instance of L<Lingua::Thesaurus::Term>
(or C<undef> if the term is unknown). The second argument C<$origin>
is optional.


=head3 rel_types

Returns the list of ids of relation types stored in this thesaurus
(i.e. 'NT', 'RT', etc.).

=head3 fetch_rel_type

  my $rel_type = $thesaurus->fetch_rel_type($rel_type_id);

Returns the L<Lingua::Thesaurus::RelType> object
corresponding to C<$rel_type_id>.


=head3 storage

Returns the internal object playing role L<Lingua::Thesaurus::Storage>.

=head1 FURTHER DOCUMENTATION

More details can be found in the various implementation classes :

=over

=item *

L<Lingua::Thesaurus::IO> : Role for input/output operations on a thesaurus

=item *

L<Lingua::Thesaurus::IO::ISO2788> :
IO class for ISO thesauri (not implemented yet)

=item *

L<Lingua::Thesaurus::IO::Jurivoc> :
IO class for "Jurivoc", the Swiss thesaurus for justice


=item *

L<Lingua::Thesaurus::IO::LivelinkCollectionServer> : 
IO class for Livelink Collection Server thesaurus files

=item *

L<Lingua::Thesaurus::RelType> :
Relation type in a thesaurus

=item *

L<Lingua::Thesaurus::Storage>:
Role for thesaurus storage

=item *

L<Lingua::Thesaurus::Storage::SQLite>:
Thesaurus storage in an SQLite database

=item *

L<Lingua::Thesaurus::Term>:
parent class for thesaurus terms; in particular, this class
implements methods for navigating through relations.

=back


=head1 SEE ALSO

Here is a brief review of some other thesaurus modules on CPAN :

=over

=item *

L<Thesaurus> has several backend implementations
(CSV, BerkeleyDB, DBI), but it just handles synonyms (a single relation
between terms).

=item *

L<Text::Thesaurus::ISO> is quite old (1998), uses obsolete technology
(C<dbmopen>), and has a fixed number of relations, some of which are 
apparently targeted to the specific needs of UK electronic libraries.

=item *

L<Biblio::Thesaurus> has a rich set of features, not only for
reading and searching, but also for editing and exporting a thesaurus.
Storage is directly in hashes in memory; those can be saved into
files in L<Storable> format. The set of relations is flexible; it
is read from the ISO dumpfiles. If it fits directly your needs, it's
probably a good choice; but if you need to adapt/extend it, it's not
totally obvious because all features are mingled into one monolithic
module.

=item *

L<Biblio::Thesaurus::SQLite> has an unclear status : it sits in the
same namespace as L<Biblio::Thesaurus>, and actually calls it in the
source code, but doesn't inherit or call it.
A separate API is provided for storing some thesaurus data into
an SQLite database; but the full features of L<Biblio::Thesaurus> are absent.

=back


=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-thesaurus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Thesaurus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Thesaurus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Thesaurus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-Thesaurus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-Thesaurus>

=item * Search MetaCPAN

L<https://metacpan.org/module/Lingua::Thesaurus>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

The test suite contains a short excerpt from the Swiss Jurivoc thesaurus,
copyright 1999-2012 Tribunal fédéral Suisse
(see L<http://www.bger.ch/fr/index/juridiction/jurisdiction-inherit-template/jurisdiction-jurivoc-home.htm>).


=head1 TODO

=head2 Thesaurus

  - support for multiple thesauri files (a term belongs to one-to-many
    thesaurus files; a relation belongs to exactly one thesaurus file)

=head2 SQLite

    - use_unaccent without fulltext ==> use collation sequence or redefine LIKE
    - store thesaurus name for each term
       => adapt search_terms($pattern, $thes_name);




=cut


