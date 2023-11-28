#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::Kramerius;

my $obj = MARC::Convert::Wikidata::Object::Kramerius->new(
        'kramerius_id' => 'mzk',
        'object_id' => '814e66a0-b6df-11e6-88f6-005056827e52',
        'url' => 'https://www.digitalniknihovna.cz/mzk/view/uuid:814e66a0-b6df-11e6-88f6-005056827e52',
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::Kramerius  {
#     parents: Mo::Object
#     public methods (0)
#     private methods (0)
#     internals: {
#         kramerius_id   "mzk",
#         object_id      "814e66a0-b6df-11e6-88f6-005056827e52" (dualvar: 8.14e+68),
#         url            "https://www.digitalniknihovna.cz/mzk/view/uuid:814e66a0-b6df-11e6-88f6-005056827e52"
#     }
# }