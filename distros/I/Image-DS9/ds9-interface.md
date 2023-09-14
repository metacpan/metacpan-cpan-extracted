Language agnostic encoding of the DS9 client API
================================================

RPC Transport protocols
-----------------------

DS9 supports two RPC transport protocols: XPA and SAMP.  XPA is
supported via a C library or via executable programs.


Command Syntax
--------------

The native ds9 API resembles most a free-formatted string based
command line interface.  The syntax takes the following form

>     command [<subcommand>] [<arguments>]

A subcommand may consist of multiple tokens, e.g.the `regions` command
has a `load all` subcommand.

Arguments are typically positional, but some commands may use named arguments.
Positional arguments may be variable or constants, e.g. in the `regions` command

>    regions template foo.tpl at 13:29:55.92 +47:12:48.02 fk5

The token `at` is a constant string, while `foo.tpl`, `13:29:55.92`,
`+47:12:48.02`, and `fk5` are variable.

Named arguments consist of _name - value_ pairs with no required order
between the arguments.  For example,

>     regions -format ds9 -system wcs -sky fk5 -skyformat sexagesimal -prop edit 1 -group foo

In some cases, the named arguments are embedded in a single token,
e.g. for the `array` command,

>     array foo.arr[dim=512,bitpix=-32,endian=little]

Some named arguments exclude others and require others. For example,
the `array` command's `xdim` and `ydim` arguments must appear together, but must not appear with `dims`.

Data Serialization
------------------
Most data sent to and received from DS9 is encoded as free-form ASCII
text. When communicating with DS9 via XPA, certain commands accept or
send binary encoded data through a separate channel.

In most cases, outgoing and incoming data for a command share the same
format.

Client Interface
----------------

Client support for the DS9 API should include data validation,
serialization and unserialization of data and error reporting

Mapping the components onto a native language binding should not
necessarily follow the native DS9 syntax, as that may be an unnatural
fit for the language.  For example, client code may prefer to use
different combinations of positional and named parameters.  For
example, the above `array` command might be coded in Perl as:

>     $ds9->array( file => $file, dim => 512, bitpix => -32, endian => 'little' );

Additionally, some languages provide type conversions which would allow, for instance,
conversion between real numbers and sexagesimal coordinate notation.

Building interfaces for multiple languages, requires a machine
readable, language agnostic API specification. DS9 itself uses
generated lexer and parser Tcl code to interpret commands sent to it.
The parser and lexer specifications are in a proprietary DSL and
include Tcl code specific to DS9's internals, so are not easily
converted into a more generic grammar specification.

Of late encoding of HTTP REST API's has become commonplace via the
OpenAPI Specification (OAS) and RAML initiatives. These encode API
endpoints (*paths*), parameters and results as `YAML` or `JSON` data
structures (`RAML` only uses `YAML`).  Parameters and results may have
complex structures with types specified by`JSON` schema. 
As most languages in current use have some form of `JSON
Schema` validation, this provides a simple path to client-side parameter validation.
Tools exist to validate an API description, and to create test servers
and clients to evaluate it.

There are a few disadvantages of these specifications.

1. Code generators for client support assume HTTP transport.  DS9 has three methods for transport.
2. The specifications are designed for the HTTP protocol and explicitly follow its structure, e.g., responses categories are identified by HTTP error codes.
3. There is no supported means of specifying alternate data serialization and deserialization formats.










