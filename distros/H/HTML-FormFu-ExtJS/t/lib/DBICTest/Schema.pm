#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package # hide from PAUSE
    DBICTest::Schema;

use base qw/DBIx::Class::Schema/;

no warnings qw/qw/;

__PACKAGE__->load_classes(qw/
  Artist
  SequenceTest
  Employee
  CD
  Link
  Bookmark
  #dummy
  Track
  Tag
  /,
  { 'DBICTest::Schema' => [qw/
    LinerNotes
    OneKey
    #dummy
    TwoKeys
    Serialized
  /]},
  (
    'FourKeys',
    'FourKeys_to_TwoKeys',
    '#dummy',
    'SelfRef',
    'ArtistUndirectedMap',
    'ArtistSourceName',
    'ArtistSubclass',
    'Producer',
    'CD_to_Producer',
  ),
  qw/SelfRefAlias TreeLike TwoKeyTreeLike Event NoPrimaryKey/,
  qw/Collection CollectionObject TypedObject Owners BooksInLibrary/,
  qw/ForceForeign/,
);

sub sqlt_deploy_hook {
  my ($self, $sqlt_schema) = @_;

  $sqlt_schema->drop_table('dummy');
}

1;
