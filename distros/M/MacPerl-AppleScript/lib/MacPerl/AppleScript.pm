# $Id: AppleScript.pm 51 2005-11-29 21:04:47Z wolfgang $
package MacPerl::AppleScript;

use 5.008006;
use strict;
use warnings;
use Carp;
use MacPerl;                # Mac Stuff DoAppleScript
use Encode;                 # Encode AppleScript Code to MacRoman
use Parse::RecDescent;      # Parsing of AppleScript Data -> Perl Structures
use Class::Std::Utils;

our $VERSION = '0.02';

{   # Inside-Out Class

    ############################################################ private Data Storage

    my %object_name_of;         # ident Object  => [part, part]
    my %parent_object_of;       # ident Object  => parent Object
    my %app_object_of;          # ident Object  => Applikation Object
    my %object_for;             # full Name     => Object
    my %prop_cache_for;         # ident Object  => { properties } -- short-term
    my %registration_for;       # "AppleScript class name" => "Perl Class"

    my $DEBUG = 0; require Data::Dumper if ($DEBUG);

    ############################################################ Data Parser
    #
    # Grammar and parser for applescript data
    #
    my $datatype_parser = Parse::RecDescent->new(<<'GRAMMAR');
datatype:
    boolean                         { $return = $item[1] }
    | number                        { $return = $item[1] }
    | string                        { $return = $item[1] }
    | objref                        { $return = MacPerl::AppleScript->new($item[1]) }
    | word(s)                       { $return = join(" ", @{$item[1]}) }
    | hash                          { $return = { map { $_->[0],$_->[1] } @{$item[1]} } }
    | array                         { $return = [ @{$item[1]} ] }

id:
    /\d+/                           { $return = $item[1] }

word:
    /[a-zA-Z][a-zA-Z0-9_]*/         { $return = $item[1] }

word_but_not_of:
    word <reject: $item[1] eq "of"> { $return = $item[1] }

boolean:
    /true|false/                    { $return = $item[1] }

number:
    /-?\d+(\.\d+)?/                 { $return = $item[1] }

string:
    '"' /(?:\\\"|[^\"])*/ '"'       { $return = $item[2] }

id_or_str:
    id                              { $return = $item[1] }
    | string                        { $return = qq{"$item[1]"} }

objref_comp:
    word_but_not_of(s) id_or_str(?) { $return = join(" ", @{$item[1]}, @{$item[2]}) }

objref_part2:
    'of' objref_comp                { $return = join(" ", $item[2]) }

objref:
    objref_comp objref_part2(s?)    { $return = join(" of ",$item[1], @{$item[2]}) }

objref_parts:
    objref_comp objref_part2(s?)    { $return = [$item[1], @{$item[2]}] }

array:
    '{' datatype(s? /,/) '}'        { $return = $item[2] }

identifier:
    word(s)                         { $return = join(" ", @{$item[1]}) }

hash_comp:
    identifier ':' datatype         { $return = [ $item[1], $item[3] ] }

hash:
    '{' hash_comp(s? /,/) '}'       { $return = [ @{$item[2]} ] }
GRAMMAR
    ;

    ############################################################ some useful overloads
    #
    # - convert Object to string to allow interpolation with Obj-name
    # - tie hash to allow properties to set/read
    #
    use overload (
                  q{""}  => sub { my $self = shift;
                                  return $self->name();
                              },
                  q{%{}} => sub { my $self = shift;
                                  my %h; tie %h, ref($self),$self;
                                  return \%h;
                              },
                  fallback => 1,
              );

    ############################################################ Tie-Hash stuff
    #
    # Hash-Tie - handle requests to "obj->{name}" as property set/get
    #
    sub TIEHASH {
        my $self = shift;
        my $class = shift;
        return bless $class,$self;
    }

    sub STORE {
        my $self = shift;
        my $key = shift;
        my $value = shift;

        access_property($self,"set",$key,$value);
    }

    sub FETCH {
        my $self = shift;
        my $key = shift;

        return eval { access_property($self,"get",$key) };
    }

    sub EXISTS {
        my $self = shift;
        my $key = shift;

        return defined( eval { access_property($self,"get",$key) } );
    }

    sub FIRSTKEY {
        my $self = shift;

        my @result;

        my $prop = $self->app()->execute("get properties of $self");
        $prop_cache_for{ident $self} = $prop;
        my $a = keys %{$prop}; # reset each() iterator

        if (!(@result = each %{$prop_cache_for{ident $self}})) {
            delete $prop_cache_for{ident $self};
        };

        return @result;
    }

    sub NEXTKEY {
        my $self = shift;

        my @result;

        if (!(@result = each %{$prop_cache_for{ident $self}})) {
            delete $prop_cache_for{ident $self};
        };

        return @result;
    }

    sub CLEAR {
        my $self = shift;

        my $class = ref($self);
        croak("cannot clear a tied hash of type '$class'");
    }

    sub DELETE {
        my $self = shift;
        my $key = shift;

        my $class = ref($self);
        croak("cannot delete a key from a tied hash of type '$class'");
    }

    ############################################################ AutoLoad
    sub AUTOLOAD {
        my $self = shift;

        use vars qw($AUTOLOAD);

        my $sub = $AUTOLOAD;
        $sub =~ s{\A .* ::}{}xms;

        my $script = join(" ",$sub,
                          map { ref($_) ? convert_to_ascript($_) : $_ }
                          (@_)
                         );
        return $self->execute($script);
    }

    ############################################################ Methods
    #
    # Constructor -- Create Application|Object class
    #   args: Name
    #
    sub new {
        my ($class,$name) = @_;

        croak("no name for object construction") if (!defined($name) || !$name);

        #
        # split name into parts divided by 'of'
        #
        my $name_parts = $datatype_parser->objref_parts($name) || [$name];

        #
        # resulting object - built stepwise bottom up
        #
        my $object = undef;

        #
        # full-path, relative path on object or simple app-name?
        #
        if ($name_parts->[-1] =~ m{\A application \s+ "([^\"]+)" \z}xms) {
            #
            # construct a brand-new Object with full path
            #
            $object = new_app($class,$1);
            pop @{$name_parts};
        } elsif (ref($class)) {
            #
            # construct an Object relative to another one
            #
            $object = $class;
        } else {
            #
            # assume simple application name
            #
            return new_app($class,$name);
        }

        #
        # create all (remaining) parts for this obj
        #
        foreach my $part (reverse @{$name_parts}) {
            $object = new_obj($object,$part);
        }

        return $object;
    }

    #
    # Destructor: clean up internal variables
    #
    sub DESTROY {
        my $self = shift;

        my $name = $self->name();
        delete $object_name_of   {ident $self};
        delete $app_object_of    {ident $self};
        delete $parent_object_of {ident $self};
        delete $object_for       {$name};
    }

    #
    # Helper: create App Object -- name is just app name
    #
    sub new_app {
        my ($class,$name) = @_;

        if (my $registered_class = $class->get_registered_class([$name])) {
            $class = $registered_class;
        } elsif (ref($class)) {
            $class = ref($class);
        }

        $name = qq{application "$name"};

        return $object_for{$name} if (exists($object_for{$name}));

        my $object = bless anon_scalar(), $class;
        $object_name_of{ident $object} = [$name];
        $app_object_of {ident $object} = $object;
        $object_for    {$name}         = $object;

        return $object;
    }

    #
    # Helper: create Object relative to parent -- name is last component only
    #
    sub new_obj {
        my ($class,$name) = @_;

        my $all_parts = [ $name,@{$object_name_of{ident $class}} ];
        my $full_name = join(" of ",@{$all_parts});

        my $obj_class = $class->get_registered_class($all_parts) || $class;

        return $object_for{$full_name} if (exists($object_for{$full_name}));

        my $object = bless anon_scalar(), ref($obj_class) || $obj_class;
        $object_name_of  {ident $object} = $all_parts;
        $parent_object_of{ident $object} = $class;
        $app_object_of   {ident $object} = $app_object_of{ident $class};
        $object_for      {$full_name}    = $object;

        return $object;
    }

    #
    # execute a script
    #   args: script | script as array | script as array-ref
    #   -OR- {
    #          script  => string or array-ref of strings
    #          object  => destination object (tell ...)
    #          timeout => with timeout of ... around whole script
    #        }
    #
    #
    sub execute {
        my $self = shift;

        #
        # construct script to get executed
        #
        my $script = "";
        if (ref($_[0]) eq "HASH") {
            #
            # complex form
            #
            my $object  = exists($_[0]->{object})  ? "$_[0]->{object}" : "$self";
            my $timeout = exists($_[0]->{timeout}) ? int($_[0]->{timeout}) : 0;
            my $commands= exists($_[0]->{script})  ? $_[0]->{script} : "";

            $script = ($timeout>0 ? "with timeout of $timeout seconds\n" : "") .
                      "tell $object\n" .
                      join("\n", ref($commands) eq "ARRAY" ? @{$commands} : $commands) . "\n" .
                      "end tell\n" .
                      ($timeout>0 ? "end timeout\n" : "");
        } else {
            #
            # simple form: script as an array or array-ref
            #
            $script = "tell $self\n" .
                      join("\n", ref($_[0]) eq "ARRAY" ? @{$_[0]} : @_) . "\n" .
                      "end tell\n";
        }

        my $result = execute_applescript($script);
        if (defined($result) && $result ne "") {
            $result = $datatype_parser->datatype($result);
            print STDERR Data::Dumper->Dump([$result],["result"]) if ($DEBUG);
        }

        return $result;
    }

    #
    # get object's name
    #
    sub name {
        my ($self) = @_;

        return join(" of ", @{$object_name_of{ident $self}});
    }

    #
    # get object's app object
    #
    sub app {
        my ($self) = @_;

        return $app_object_of{ident $self};
    }

    #
    # get object's parent
    #
    sub parent {
        my ($self) = @_;

        return $parent_object_of{ident $self};
    }

    #
    # register Mapping for AppleScript Class
    #   -- register_class('XyzApp','MacPerl::XyzApp');
    #   -- register_class('document of XyzApp','MacPerl::XyzApp::Doc');
    #   register_class(['document','XyzApp'], 'MacPerl::XyzApp');
    #   register_class(['document|page', 'XyzApp'], 'MacPerl::XyzApp');
    #
    sub register_class {
        my $self = shift;
        my $name_parts = shift;
        my $perl_class = shift;

        if (ref($name_parts) eq "ARRAY") {
            # do nothing -- already OK
        } elsif (!ref($name_parts)) {
            $name_parts = [ split(/\s+of\s+/, $name_parts) ];
        }
        $name_parts->[-1] = "application \"$name_parts->[-1]\""
            if ($name_parts->[-1] !~ m{\A application \s+}xms);

        my $base = \%registration_for;
        foreach my $part (reverse @{$name_parts}) {
            if (!exists($base->{$part})) {
                $base->{$part} = {};
            }
            $base = $base->{$part};
        }
        $base->{_class} = $perl_class;
    }

    #
    # get back a perl class for a list of object parts
    #
    sub get_registered_class {
        my $self = shift;
        my $name_parts = shift;

        my $base = \%registration_for;
        foreach my $test_name (reverse @{$name_parts}) {
            $test_name =~ s{\s+}{ }xmsg;
            my ($found_name) = grep { $test_name =~ m{\A$_(?:\b|\z)}ms }
                               (keys (%{$base}));
            return if (!$found_name);
            $base = $base->{$found_name};
        }

        return $base->{_class};
    }

    #
    # convert a path to ' [POSIX] file "/path/to/file"|"path:to:file" as ... '
    #
    sub convert_path {
        my $self = shift;
        my $filename = shift;
        my $destination = shift;

        croak("no filename given") if (!$filename);

        my $posix = ($filename =~ m{\A /}xms) ? "POSIX " : "";
        my $result = qq{${posix}file "$filename"};
        $result .= " as $destination" if ($destination);

        return $result;
    }

    ############################################################ Internals
    #
    # Execute Applescript - low level
    #
    sub execute_applescript {
        my $script = shift;

        #
        # need to encode because of special symbols like "<<" or ">>"...
        #
        $script = encode("MacRoman", $script, Encode::FB_QUIET);

        print STDERR "Executing script:\n$script\n\n" if ($DEBUG);
        my $result = MacPerl::DoAppleScript($script);
        croak($@) if ($@);

        print STDERR "\n\n\nscript result: ** $result **\n" if ($DEBUG);
        return $result;
    }

    #
    # internal: access (=set/get) a property
    #
    sub access_property {
        my $self = shift;
        my $method = shift; # "set" / "get"
        my $key = shift;
        my $value = shift;

        croak("unknown method $method") if ($method !~ m{\A [gs]et \z}xms);

        my $alt_key = $key;
        my $alt_value = convert_to_ascript($value);

        $alt_key =~ s/_/ /g;

        #
        # permutations of keys and value representations
        #
        my %tries = ();
        if ($method eq "set") {
            $tries{"$key$alt_value"} = "$method $key of $self to $alt_value\nreturn\n";
            if (!ref($value) && $value =~ m{\A [ -~]* \z}xms) {
                $tries{"$key$value"} = "$method $key of $self to $value\nreturn\n";
                $tries{"$key\"$value\""} = "$method $key of $self to \"$value\"\nreturn\n";
            }
            $tries{"$alt_key$alt_value"} = "$method $alt_key of $self to $alt_value\nreturn\n";
            if (!ref($value) && $value =~ m{\A [ -~]* \z}xms) {
                $tries{"$alt_key$value"} = "$method $alt_key of $self to $value\nreturn\n";
                $tries{"$alt_key\"$value\""} = "$method $alt_key of $self to \"$value\"\nreturn\n";
            }
        } else {
            $tries{"$key"} = "return $key of $self\n";
            $tries{"$alt_key"} = "return $alt_key of $self\n";
        }

        #
        # pack all permutations in "try" statements - let the first successful win
        #
        my $script = "try\n" .
                     join("on error\ntry\n",
                          values(%tries), "error \"cannot $method property\"\n") .
                     "end try\n" x (scalar(keys(%tries))+1);
        return eval { $self->app()->execute($script) };
    }

    #
    # convert perl structure to AppleScript
    #
    sub convert_to_ascript {
        my $data = shift;
        my $depth = shift || 0; # primitive recursion loop detection
        my $result = "";

        croak("recursion depth exceeded - probably cyclic structure") if ($depth > 10);

        my $ref = ref($data);
        if (!defined($data)) {
            #
            # convert undef to AppleScript null (Class w/o attributes)
            #
            $result = "null";
        } elsif ($ref eq "HASH") {
            #
            # convert Hash to AppleScript Record
            #
            $result = '{' .
                      join(",",
                           map { "$_:" . convert_to_ascript($data->{$_},$depth+1) }
                           keys(%{$data}) ) .
                      '}';
        } elsif ($ref eq "ARRAY") {
            #
            # convert Array to AppleScript List
            #
            $result = '{' .
                      join(",",
                           map { convert_to_ascript($_,$depth+1) }
                           @{$data} ) .
                      '}';
        } elsif ($ref) {
            #
            # other kind of reference (maybe some AppleScript Object)
            #   -> convert to string
            #
            $result = "$data";
        } else {
            #
            # guess: boolean / numeric / string
            #
            if ($data =~ m{\A (?:false|true) \z}xms) {
                #
                # boolean
                #
                $result = $data;
            } elsif ($data =~ m{\A -? \d+ (?:\.\d+)? \z}xms) {
                #
                # integer of float
                #
                $result = $data;
            } else {
                #
                # special handling for non-ascii characters required?
                #
                if ($data !~ m{\A [\x09\x0a\x0d\x20-\x7f]* \z}xms) {
                    #
                    # treat string as unicode
                    # create a <<data utxt....>> sequence
                    #
                    my $hex_text = join("",
                                        map { sprintf("%04x",ord($_)) }
                                        (split(//,$data))
                                       );

                    my $cont  = "\x{00ac}"; # macroman: 0xc2 - "-," not symbol
                    my $begin = "\x{00ab}"; # macroman: 0xc7 - "<<"
                    my $end   = "\x{00bb}"; # macroman: 0xc8 - ">>"

                    $result = "(" .
                              join(" & $cont\n",
                                   map { "${begin}data utxt$_$end as Unicode text" }
                                   ($hex_text =~ m/(.{4,40})/g) ) .
                              ")";
                } else {
                    #
                    # just-ascii string
                    # filter out anything inside whole-enclosing "" marks
                    # (use "123" inside a string to force applescript string type)
                    #
                    $data =~ s{\A \" (.*) \" \z}{$1}xms;

                    #
                    # convert "bad" characters
                    #
                    my %string_translation = (
                                              qq{"}  => q{\\"},
                                              qq{\n} => q{\\n},
                                              qq{\r} => q{\\r},
                                              qq{\t} => q{\\t},
                                              qq{\\} => q{\\\\},
                                          );
                    $data =~ s{([\"\n\r\t\\])}{$string_translation{$1}}xmsge;
                    $result = qq{"$data"};
                }
            }
        }

        return $result;
    }

} # End of Inside-Out Class


1;
__END__

=head1 NAME

MacPerl::AppleScript - Perl extension for easily accessing scriptable Apps

=head1 SYNOPSIS

  use MacPerl::AppleScript;

  #
  # create Application Object
  #
  my $app = MacPerl::AppleScript->new("Application Name");

  my $doc1 = $application->new("document 1");
  my $doc2 = $application->new("document 2 of $app");

  #
  # directly execute Script in Application
  # (auto-creates a tell "Application Name" block for you
  #
  $app->execute("some applescript command");
  $app->execute(["some applescript command", "..." ... ]);
  $app->execute("some applescript command", "..." ... );

  #
  # alternative way using a hashref
  #   script: script to get executed (string or array-ref)
  #   object: optional, object to be named in the "tell" block
  #   timeout: optional, timeout in seconds
  #
  $app->execute({
                  script => [...],
                  object => $doc1,
                  timeout => 10,
                });


  #
  # calling functions
  #
  $app->open('POSIX path "/path/to/file" as alias');
  $app->open($app->convert_path('/path/to/file','alias'));
  $doc->close();
  $app->close($doc1);

  #
  # string interpolation to Applescript Object Name
  # gets 'application "Application Name"' for $application
  # gets 'document 1 of application "Application Name"' for $doc1
  #
  my $ascript_appname = "$app";
  my $ascript_docname = "$doc1";

  $app->execute("close $doc1");  # cool :-)

  #
  # getting/setting properties
  #
  my $foo_property = $app->{foo};

  my $foo_bar_prop = $doc1->{'foo bar'};
  my $foo_bar_prop = $doc1->{foo_bar};

  $app->{bar} = "any value";

  $doc1->{'foo bar'} = [1,2,3,4];
  $doc1->{foo_bar} = {a=>1, b=>2};

  my %properties = %{$app};


=head1 DESCRIPTION

This module is not written for being efficient. In fact it is
really inefficient but hopefully easy to use :-)

As AppleScript (and its way of communicating to Applications) usually
has some kind of latency. The creation of readable code is the most
important goal when writing this Module.

Another reason for some kind of inefficiency results in the technical
problem that AppleScript is a strongly typed language. Converting
types back to Perl is easy. But the other direction is not always
clear, as converting a scalar from Perl to AppleScript needs some
guessing :-(

The parts of the code that deal with these problems do some tries with
different AppleScript commands wrapped in try-blocks. So usually one
of the expression works without errors. The same approach is made with
hash keys that can contain spaces or underscores inside the key name.

This module assumes that all strings are correctly encoded in perl
internal's coding sheme based on Unicode. During the conversion to
AppleScript all characters inside strings that are not ascii-clean are
converted to strange looking unicode-string constructing sequences. I
tested a lot of character schemes including west- and mid-european
languages as well as russian, greek and arabic with some applications
without getting problems.


=head2 USAGE

  use MacPerl::AppleScript;

there are no special options for the usage of this module.


=head2 APPLESCRIPT OBJECTS

Internally a MacPerl::AppleScript Object simply is something that
knows the name of itself, its parent and the application it belongs
to. There is some caching inside. Constructing two objects for the
same AppleScript-Object results in the same Perl Object if the names
are the same. If the names differ (eg. C<'foo id 13'> and C<'foo 1'>) but
refer to the same AppleScript Object, the MacPerl::AppleScript Objects
will be different, as this module only identifies things by their
name.

  my $app = MacPerl::AppleScript->new('application "MyApp"');
  my $app = MacPerl::AppleScript->new('MyApp');

  my $doc = MacPerl::AppleScript->new('document 1 of application "MyApp"');
  my $doc = MacPerl::AppleScript->new("document 1 of $app");
  my $doc = $app->new('document 1');

  my $par = MacPerl::AppleScript->new('paragraph 1 of document 1 of application "MyApp"');
  my $par = MacPerl::AppleScript->new("paragraph 1 of document 1 of $app");
  my $par = MacPerl::AppleScript->new("paragraph 1 of $doc");
  my $par = $app->new("paragraph 1 of $doc");
  my $par = $doc->new('paragraph 1');

All grouped forms above are equivalent and give exactly the same
result. Note that in a string-context an object interpolates to its
AppleScript Name known from the moment of its construction.


=head2 SIMPLE METHODS

  $obj->name()

delivers the name of an object in fully qualified form as used inside
AppleScript, e.g. C<'application "MyApp"'> or C<'document 1 of application
"MyApp"'>.

  $obj->app()

gives back the Object of the application this Object belongs to. An
application object returns itself.

  $obj->parent()

gives back the parent Object of this one. Application objects do not
have a parent object. In this case, C<undef> is returned. (We do not
reflect the real AppleScript hierarchy hiere where everything is a
descendant of C<'script "AppleScript"'> that magically encloses every
code you write.)


=head2 SCRIPT EXECUTION

  $obj->execute("one line script here");
  $obj->execute("first line","second line", ...);
  $obj->execute(["first line","second line",...]);

This simple execution format constructs an AppleScript "tell" Block
for the object on which the execute is called and puts the line(s)
inside the tell block. There is no guarantee that this execute ever
returns or that it will not die... Using the timeout feature (below)
will prevent the first, using an C<eval{}> around will prevent the
second.

If the AppleScript run returns something, it will be returned as a
Perl data structure reflecting the AppleScript data returned.

  $obj->execute({script => string or array_ref,
                 timeout => seconds,
                 object => some_object });

Here, a timeout in full seconds may be given, or the object to be
named in the "tell" Block can get specified. The script may be a
simple string or an array-ref of script-lines.

Another way of getting AppleScript code to execute is by calling the
method directly. Internally the functions are resolved by Perl's
AUTOLOAD feature. Calling an undefined function of this class triggers
the AUTOLOAD function, that converts its caller and the parameters to
an AppleScript code sequence.

  $obj->someFunction();

makes a "tell" block for $obj and "someFunction" as the AppleScript
function to get executed.

  $obj->someFunction("argument1", "argument2", ...);

appends the space-separated arguments to the function call. If any
argument is an object, a hash or an array, the correct form for
AppleScript is used. Scalars are insert as they are. If you need
args quoted, you will have to add them on your own.


=head2 PROPERTIES AND INTERPOLATION

All AppleScript Objects have some magic features built in.

  "$obj"

In String context, an object interpolates to its name inserting
exactly the same result as the C<$obj->name()> function call
returns. This allows you to use the object name inside an AppleScript
you like to constuct, giving you the meaning of this object in the
right context.

An Object may get accessed like a Hash reference.

  $obj->{'property name'}
  $obj->{property_name}
  %properties = %{$obj};

Access a property of the object by either using the AppleScript
commands "get ..." or "set ... to" to get the job done.

The key of the property may be written correct or in a simplified form
using underscores instead of spaces. Technically, both forms are tried
as AppleScript commands. The first successful set/get wins.

Retrieved values are converted to their Perl structures. Referred
Objects inside other objects are returned as MacPerl::AppleScript
Object (or subclasses hereof) references.

Setting values needs guessing of the right AppleScript datatype. 123
and '123' will both result in an Integer Object inside AppleScript. In
doubtful cases, put the entire contents in "" quotes '"123"' in this
case.


=head2 CLASS METHODS

Working with paths and filenames in AppleScript is a bit nasty as it
is not always clear how to use Mac and Unix paths.

  $self->convert_path('volume:folder:file')
    returns 'file "volume:folder:file"'

  $self->convert_path('volume:folder:file', 'string')
    returns 'file "volume:folder:file" as string'

  $self->convert_path('/path/to/file', 'alias')
    returns 'POSIX file "/path/to/file" as alias'


=head2 SUBCLASSING

When building new classes based on MacPerl::AppleScript, there is
one feature that might help.

Every result that comes back from AppleScript is parsed as a text and
then converted to some Perl data structure. During this step all
things that look like AppleScript Objects are converted using a call
like
  MacPerl::AppleScript->new('some name');

Usually all objects created like that are objects of the base
class. However, if you like to get all 'foo of application "xx"' to be
an Object of 'MacPerl::XX::Foo' then you could force that behaviour.

  $self->register_class('foo of application "xx"', 'MacPerl::XX::Foo');
    or
  $self->register_class('foo of xx', 'MacPerl::XX::Foo');
    or
  $self->register_class(['foo','application "xx"'], 'MacPerl::XX::Foo');
    or
  $self->register_class(['foo','xx'], 'MacPerl::XX::Foo');

as a step inside your class (maybe inside a BEGIN block) will do that
job. The left side is a collection of 'of' separated items or an array
reference that act as regular expressions to match the beginning of
object names.

If multiple registrations are made like this, they are evaluated in
unpredictable order of their definition stopping at the first
match. Doing a registration multiple times will not hurt, as
internally the registrations are stored in a HoH structure.

  $self->get_registered_class(['foo','application "xx"'])
    returns 'MacPerl::XX::Foo'

usually the latter function need never get called by a subclass, as
the magic of finding the class name occurs behind the scenes
automatically.


=head2 EXPORT

None by default.

All defined subroutines are accessed as object-methods or indirectly
by overloaded functionality.


=head1 SEE ALSO

  MacPerl
    this module uses the AppleScript sending routines of MacPerl.

  Mac::Glue
    this is an alternative to this module.

  Mac::AppleEvents
    for the brave people who want to compose AppleEvents on their own.

  Mac::AppleScript
    yet another alternative to executing AppleScript


=head1 BUGS

probably many :-(

Please do not shame me too much, as this is my first CPAN
module. There are a couple of things that can be improved. Marying two
completely different worlds is not an easy task. If you do have any
idea on how to improve things, please drop me a short mail.


=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Wolfgang Kinkeldei

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
