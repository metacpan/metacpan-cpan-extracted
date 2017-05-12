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
    DBICTest::Schema::ArtistSubclass;

use base 'DBICTest::Schema::Artist';

__PACKAGE__->table(__PACKAGE__->table);

1;