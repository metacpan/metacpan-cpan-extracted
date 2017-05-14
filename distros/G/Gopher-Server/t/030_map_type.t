
use Test::More tests => 21;
use strict;
use warnings;

use Gopher::Server::TypeMapper;
use Cwd;

# Plaintext files
my $type = Gopher::Server::TypeMapper->get_type({
	filename => 'file.txt', 
});
ok( defined $type, "returns a defined value" );
ok( UNIVERSAL::isa( $type, 'Gopher::Server::TypeMapper' ), "isa correct" );
ok( $type->gopher_type eq '0', "Plaintext Gopher type" );
ok( $type->mime_type eq 'text/plain', "Plaintext MIME type" );

ok( "$type" eq '0', "Stringifies to Gopher type" );

$type = Gopher::Server::TypeMapper->get_type({
	extention => 'txt', 
});
ok( defined $type, "return a defined value" );
ok( UNIVERSAL::isa( $type, 'Gopher::Server::TypeMapper' ), "isa correct" );
ok( $type->gopher_type eq '0', "Plaintext Gopher type" );
ok( $type->mime_type eq 'text/plain', "Plaintext MIME type" );


# Directories
$type = Gopher::Server::TypeMapper->get_type({
	filename => getcwd(), 
});
ok( defined $type, "returns a defined value" );
ok( UNIVERSAL::isa( $type, 'Gopher::Server::TypeMapper' ), "isa correct" );
ok( $type->gopher_type eq '1', "Menu Entity Gopher type" );
ok( $type->mime_type eq '',    "No MIME equivilent to menu entities" );


# Anything else should be binary type, for now
$type = Gopher::Server::TypeMapper->get_type({
	filename => 'blah.foo', 
});
ok( defined $type, "return a defined value" );
ok( UNIVERSAL::isa( $type, 'Gopher::Server::TypeMapper' ), "isa correct" );
ok( $type->gopher_type eq '9', "Binary Gopher type" );
ok( $type->mime_type eq 'application/data', "Binary Gopher type" );

$type = Gopher::Server::TypeMapper->get_type({
	extention => 'bar', 
});
ok( defined $type, "return a defined value" );
ok( UNIVERSAL::isa( $type, 'Gopher::Server::TypeMapper' ), "isa correct" );
ok( $type->gopher_type eq '9', "Binary Gopher type" );
ok( $type->mime_type eq 'application/data', "Binary Gopher type" );

