package LibreCat::Auth::SSO::ResponseParser;

use Catmandu::Sane;
use Moo::Role;

our $VERSION = "0.01";

with "Catmandu::Logger";

requires "parse";

1;
