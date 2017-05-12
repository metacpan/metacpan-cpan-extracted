# -*- perl -*-

use Test::More no_plan; #tests => 27;
use Test::Exception;

use MacPerl::AppleScript;

my $app_name ="TextEdit";

# make app object
my $app_object;
lives_ok { $app_object = MacPerl::AppleScript->new($app_name) } "App Object for $app_name";

# execution
lives_ok { $app_object->execute("activate") } "App '$app_name' can get activated";
lives_ok { $app_object->execute("get properties") } "App '$app_name' can deliver properties";
lives_ok { $app_object->execute(["close documents saving no",
                                 "make new document"]) } "script as array-ref";
lives_ok { $app_object->execute("close documents saving no",
                                "make new document") } "script as multiple strings";

# calling functions by AUTOLOAD
lives_ok { $app_object->close("document 1") } "autoload test 1";
lives_ok { $app_object->make("new document") } "autoload test 2";


# overload tests
is(ref($app_object->execute("get properties")), "HASH", "Properties delivered as Hash");
ok(exists($app_object->{class}), "access of property element as hash-element");
ok(!exists($app_object->{unknownpropertyname}), "access of unknown property element");

# simple tests on returned values
my $docs = $app_object->execute("get documents");
is(ref($docs), "ARRAY", "list of documents is array");
is(scalar(@{$docs}), 1, "one document is open");
is(ref($docs->[0]), "MacPerl::AppleScript", "Class of Object");
like($docs->[0]->name(), qr/^document .* of application "TextEdit"$/, "Document Name");
is($docs->[0]->app(), $app_object, "App Object of Document");
is($docs->[0]->parent(), $app_object->name(), "Document is child of App");

# using datatypes
lives_ok { $docs->[0]->{text}="Hello Mac" } "set string property";
lives_ok { $docs->[0]->{text}=123 } "set numeric property";
is($docs->[0]->{text}, "123", "retrieve string property");

my $par = MacPerl::AppleScript->new("paragraph 1 of $docs->[0]");
is(ref($par), "MacPerl::AppleScript", "paragraph object OK");
is("$par", "paragraph 1 of document 1 of application \"TextEdit\"", "paragraph object name");
is(ref($par->{color}), "ARRAY", "paragraph color is Array");
lives_ok { $par->{size}=48.0 } "set real value";
lives_ok { $par->{color}=[0,65535,0] } "set array value";
is_deeply($par->{color}, [0,65535,0], "get array value");

# Writing to / reading from document
lives_ok { $app_object->execute("set text of $docs->[0] to \"Hello World\"") } "set text";
is( $app_object->execute("get text of $docs->[0]"), "Hello World", "get text" );

# Unicode characters ("Latex" with strange accents, "Internet" in cyrillic, ":-)" as unicode char)
lives_ok { $docs->[0]->{text}="\x{0141}\x{03B1}\x{0163}\x{0117}\x{03C7} \x{21D2} \x{0406}\x{043D}\x{0442}\x{0438}\x{0440}\x{043D}\x{0438}\x{0442} \x{263A}" } "show unicode characters";
