package KiokuDB::Backend::CouchDB::Exceptions;

use strict;
use warnings;

use Exception::Class (
    'KiokuDB::Backend::CouchDB::Exception',
    'KiokuDB::Backend::CouchDB::Exception::Conflicts' => {
        fields => ['conflicts']
    }
);

1;
