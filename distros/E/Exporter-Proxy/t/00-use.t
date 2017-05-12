
use v5.20;
use strict;

use Test::More;

plan tests => 2;


require_ok 'Exporter::Proxy';

ok Exporter::Proxy->can( 'import' ), "Exporter::Proxy can 'import'";

__END__
