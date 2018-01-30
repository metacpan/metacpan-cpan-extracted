=head1 NAME

Devel::PerlySense::Document - A Perl file/document

=head1 SYNOPSIS




=head1 DESCRIPTION

The document contains a PPI parsed document, etc. along with a
metadata object.


=head2 Caching

Caching is done on a per file + mod timestamp basis. Things that are
cached are: PPI documents, Document::Api and Document::Meta objects.

Currently Cache::Cache is used. This isn't great (duh), since there is
no good way to expire obsolete files.


=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Document;
$Devel::PerlySense::Document::VERSION = '0.0219';




use Spiffy -Base;
use Carp;
use Data::Dumper;
use PPI 1.003;
use File::Basename;
use List::MoreUtils qw/ uniq /;

use Devel::PerlySense;
use Devel::PerlySense::Util;
use Devel::PerlySense::Util::Log;
use Devel::PerlySense::Document::Location;
use Devel::PerlySense::Document::Api;
use Devel::PerlySense::Document::Meta;

use Devel::TimeThis;





=head1 PROPERTIES

=head2 oPerlySense

Devel::PerlySense object.

Default: set during new()

=cut
field "oPerlySense" => undef;





=head2 file

The absolute file name of the parsed file, or "" if none was parsed.

Default: ""

=cut
field "file" => "";





=head2 oDocument

The PPI::Document object from the parse(), or undef if none was
parsed.

Default: undef

=cut
field "oDocument" => undef;
# sub oDocument {
#     @_ or (Carp::longmess =~ /Document::parse/s or cluck("\n\n\n\n\nODOCUMENT FOR (" . $self->file . ")\n"));
#     use Carp qw/cluck/;

#     @_ and $self->{odocument} = $_[0];

#     $self->{odocument};
# }





=head2 oMeta

The Devel::PerlySense::Document::Meta object from the parse(), or
undef if none was parsed.

Default: undef

=cut
field "oMeta" => undef;





=head2 rhPackageApiLikely

Hash ref with (keys: package names; Document::Api objects).

Default: {}

=cut
field "rhPackageApiLikely" => {};





=head1 API METHODS

=head2 new(oPerlySense => $oPerlySense)

Create new PearlySense::Document object. Associate it with $oPerlySense.

=cut
sub new {
    my ($oPerlySense) = Devel::PerlySense::Util::aNamedArg(["oPerlySense"], @_);

    $self = bless {}, $self;    #Create the object. It looks weird because of Spiffy
    $self->oPerlySense($oPerlySense);

    return($self);
}





=head2 fileFindModule(nameModule => $nameModule)

Find the file containing the $nameModule given the file property of
the document.

Return the absolute file name, or undef if none could be found. Die on
errors.

=cut
sub fileFindModule {
    my ($nameModule) = Devel::PerlySense::Util::aNamedArg(["nameModule"], @_);

    my $file = $self->file or return(undef);

    return(
        $self->oPerlySense->fileFindModule(
            nameModule => $nameModule,
            dirOrigin => dirname($self->file)
        )
    );
}





=head2 parse(file => $file)

Parse the $file and store the metadata.

Return 1 on success, else die.

Cached on the usual.

=cut
###TODO: Rearrange these so they are write cached here, but read
###cached on first access instead.
sub parse {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    my $keyCache = "document";
    if(my $oDocument = $self->cacheGet($keyCache, $file)) {
        $self->oDocument($oDocument);
    } else {
        $self->parse0(file => $file);
        $self->cacheSet($keyCache, $file, $self->oDocument);
    }

    $self->file($file);


    $keyCache = "document-meta";
    if(my $oMeta = $self->cacheGet($keyCache, $file)) {
        $self->oMeta($oMeta);
    } else {
        $oMeta = Devel::PerlySense::Document::Meta->new();

        $oMeta->parse($self);

        $self->oMeta($oMeta);
        $self->cacheSet($keyCache, $file, $self->oMeta);
    }

    return(1);
}





=head2 parse0(file => $file)

Parse the $file and store the metadata.

Return 1 on success, else die.

=cut
sub parse0 {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);
#print "    Parsing: ((($file)))\n";
    my $oDocument = PPI::Document->new($file) or die("Could not parse file ($file): " . PPI::Document->errstr . "\n");
    $oDocument->index_locations();

    $self->oDocument($oDocument);

    return(1);
}





=head2 aNamePackage()

Return list of package names in this document.

=cut
sub aNamePackage {
    return( sort uniq map { $_->namespace } @{$self->oMeta->raPackage} );
}





=head2 aNameBase()

Return list of names of modules that are base classes, according to
either "use base" or an assignment to @ISA.

Dir on errors.

=cut
sub aNameBase {

    #TODO: Should be centralized in PerlySense and made configurable
    my %hStop = map { $_ => 1 } qw(Exporter DynaLoader);

    my @aBase = grep { (! $hStop{$_}) && $_ =~ /[A-Z]/ } @{$self->oMeta->raNameModuleBase};

    return(@aBase);
}





=head2 hasBaseClass($nameClass)

Return true if $nameClass is an immediate base class to this one, else
false.

=cut
sub hasBaseClass {
    my ($nameClass) = @_;

    return( (grep { $_ eq $nameClass  } @{$self->oMeta->raNameModuleBase}) > 0 );
}





=head2 aNameModuleUse()

Find modules that are used in this document.

Don't find pragmas. Don't find very common infrastructure
modules. Only report modules used in this actual document.

Return list of unique module names.

Dir on errors.

=cut
sub aNameModuleUse {

    my %hStop = map { $_ => 1 } qw(Exporter DynaLoader);    #TODO: Should be centralized in PerlySense and made configurable
    my @aModule = grep { (! $hStop{$_}) } @{$self->oMeta->raNameModuleUse};

    return(@aModule);
}





=head2 packageAt(row => $row)

Return the package name that is active on line $row (1..), or die on
errors.

=cut
sub packageAt {
    my ($row) = Devel::PerlySense::Util::aNamedArg(["row"], @_);
    $row > 0 or croak("Parameter row ($row) must be 1..");

    my @aPackage =
            grep { $_->namespace && $_->location->[0] <= $row }
            @{$self->oMeta->raPackage}
                    or return("main");

    my $oPackage = $aPackage[-1];
    return($oPackage->namespace);
}




=head2 isEmptyAt(row => $row, col => $col)

Determine whether the position at $row, $col is empty (ther is no known
content, no:

  modules
  methods
  variables?

).

Return 1 if empty, else 0.

Die on errors.

=cut
sub isEmptyAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);

    $self->oMeta->moduleAt(row => $row, col => $col) and return(0);
    $self->oMeta->rhMethodAt(row => $row, col => $col) and return(0);

    return(1);
}





=head2 moduleAt(row => $row, col => $col)

Find the module mentioned on line $row (1..) at $col (1..). Don't
recognize modules that isn't ucfirst(). There may be false positives,
if it looks like a module. (examples?)

Return string like "My::Module" or "Module", or undef if none was
found.

Die on errors.

=cut
sub moduleAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);
    return($self->oMeta->moduleAt(row => $row, col => $col));
}





=head2 methodCallAt(row => $row, col => $col)

Return the method call Perl code is on line $row (1..) at $col (1..),
or die on errors.

In scalar context, return string like "$self->fooBar". Don't include
the parameter list or parens, only the "$object->method".

In list context, return two item list with (object, method).

The object may be undef/"" if it's an expression rather than a simple
variable.

Return undef or () if none was found. Die on errors.

=cut
sub methodCallAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);

    my $rhMethod = $self->oMeta->rhMethodAt(row => $row, col => $col) or return;
    my ($oMethod, $oObject) = ($rhMethod->{oNode}, $rhMethod->{oNodeObject});

    wantarray and return($oObject, $oMethod);
    return((defined($oObject) ? $oObject : "") . "->$oMethod");
}





=head2 selfMethodCallAt(row => $row, row => $col)

Return the name of the $self->method at $row, $col in this document.

Also matches shift->method, if there is no $self in this sub at all.

If no method call is found, maybe warn and return undef.

Die on errors.

=cut
sub selfMethodCallAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);

    my ($object, $method) = $self->methodCallAt(row => $row, col => $col);
    $method or return(undef);
    $object or return(undef);
    $object eq '$self' and return($method);

    # If the object is "shift" and there is no mention of a $self in
    # the sub, assume it's $self being shifted off @_
    if($object eq "shift") {
        $self->isThereSelfInSubAt(row => $row, col => $col) and return undef;
        return($method);
    }

    return(undef);
}

=head2 isThereSelfInSubAt(row => $row, col => $col) : Bool

Whether there is a mention of $self in the sub surrounding $row, $col.

=cut
sub isThereSelfInSubAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);

    my $oLocationSubAt = $self->oLocationSubAt(row => $row, col => $col)
        or return(0);

    my $source = $oLocationSubAt->rhProperty->{source} or return(0);

    if ( $source =~ / \$self \b /smx ) {
        # There is a $self somewhere in this sub (could be false
        # positive in a comment or string), so shift isn't $self
        return(1);
    }

    return(0);
}

=head2 moduleMethodCallAt(row => $row, row => $col)

Find the My::Module->method call at $row, $col in this document.

In list context, return two item list with (module, method). In scalar
context, return "My::Module->method".

Return undef or () if none was found. Die on errors.

=cut
sub moduleMethodCallAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);

    my ($module, $method) = $self->methodCallAt(row => $row, col => $col);
    $module && $method or return(undef);
    $module =~ /[^\w:]/ and return(undef); #only allow bareword modules

    wantarray() and return($module, $method);
    return("$module->$method");
}





=head2 aObjectMethodCallAt(row => $row, row => $col)

Return three item array with (object name, method name, $oLocation of the
surrounding sub) of the $self->method at $row, $col in this
document. The object may be '$self'.

If no method call is found, maybe warn and return ().

Die on errors.

=cut
sub aObjectMethodCallAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);

    my ($oObject, $oMethod) = $self->methodCallAt(row => $row, col => $col);
    $oObject && $oMethod or return();
    $oObject =~ /^\$\w+$/ or return();

    my $oLocationSub = $self->oLocationEnclosingSub($oMethod) or return();

    return($oObject, $oMethod, $oLocationSub);
}





=head2 rhRegexExample(row => $row, col => $col)

Look in $file at location $row/$col and find the regex located there,
and possibly the example comment preceeding it.

Return hash ref with (keys: regex, example; values: source
string). The source string is an empty string if nothing found.

If there is an example string in a comment, return the example without
the comment #

Die if $file doesn't exist, or on other errors.

=cut
sub rhRegexExample {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);

    return { regex => "", example => "" };
}





=head2 oLocationSub(name => $name, [package => "main"])

Return a Devel::PerlySense::Document::Location object with the
location of the sub declaration called $name in $package, or undef if
it wasn't found.

Die on errors.

=cut
sub oLocationSub {
    my ($name) = Devel::PerlySense::Util::aNamedArg(["name"], @_);
	my (%p) = @_;
    my $package = $p{package} || "main";

    for my $oLocation (@{$self->oMeta->raLocationSub}) {
#        debug("JPL: " . $oLocation->rhProperty->{nameSub} . " eq $name && " . $oLocation->rhProperty->{namePackage} . " eq $package");
#        defined $oLocation->rhProperty->{nameSub} or debug("SANITY FAILED: " . Dumper($oLocation));
#        defined $oLocation->rhProperty->{namePackage} or debug("SANITY FAILED: " . Dumper($oLocation));
        if(        $oLocation->rhProperty->{nameSub}     eq $name
                && $oLocation->rhProperty->{namePackage} eq $package) {
            debug("Document->oLocation found ($name) in ($oLocation)");
            return($oLocation);
        }
    }

    return(undef);
}





=head2 oLocationSubAt(row => $row, col => $col)

Return a Devel::PerlySense::Document::Location object with the
location of the sub definition at $row/$col, or undef if it row/col
isn't inside a sub definition.

Note: Currently, col is ignored, and the sub is presumed to occupy the
entire row.

Die on errors.

=cut
sub oLocationSubAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);

    for my $oLocation (@{$self->oMeta->raLocationSub}) {
        if(           $row >= $oLocation->row
                   && $row <= $oLocation->rhProperty->{oLocationEnd}->row
               ) {
            debug("Sub " . $oLocation->rhProperty->{namePackage} . "->" . $oLocation->rhProperty->{nameSub} . " found at (" . $oLocation->file . ":$row)");
            return($oLocation->clone);
        }
    }

    return(undef);
}





=head2 oLocationSubDefinition(name => $name, [row => $row], [package => $package])

Return a Devel::PerlySense::Document::Location object with the
location of the sub "definition" for $name, or undef if it wasn't
found. The definition can be the sub declaration, or a POD entry.

If $row is passed, use it to determine which package is active at
$row. If $package is passed, use that instead. Default to package
"main" if neither is passed.

If no definition can be found in this document, and the module has one
or more base classes, look in the @ISA (depth-first, just like Perl
(see perldoc perltoot)).

Warn on some failures to find the location. Die on errors.

=cut
sub oLocationSubDefinition {
    my ($name) = Devel::PerlySense::Util::aNamedArg(["name"], @_);
    my %p = @_;  my ($row, $package) = ($p{row}, $p{package});

    if(! $package) {
        if($row) {
            $package = $self->packageAt(row => $row)
                    or warn("Could not find active package at row ($row)\n"), return(undef);
        } else {
            $package = "main";
        }
    }
    debug("Document->oLocationSubDefinition name($name) package($package)");

    #Look for the sub definition
    my $oLocation = $self->oLocationSub(name => $name, package => $package);
    $oLocation and return($oLocation);

    #Fail to POD in same file
    $oLocation = $self->oLocationPod(name => $name, lookFor => "method", ignoreBaseModules => 1);
    $oLocation and return($oLocation);

    #Fail to base classes
    for my $moduleBase ($self->aNameBase) {
        my $oDocumentBase = $self->oPerlySense->oDocumentFindModule(
            nameModule => $moduleBase,
            dirOrigin => dirname($self->file),
        ) or debug("Could not find module ($moduleBase)\n"), next;
        $oLocation = $oDocumentBase->oLocationSubDefinition(name => $name, package => $moduleBase);
        $oLocation and return($oLocation);
    }

    return(undef);
}





=head2 oLocationPod(name => $name, lookFor => $lookFor, [ignoreBaseModules => 0])

Return a Devel::PerlySense::Document::Location object with the "best"
location of the pod =head? or =item where $name is present, or undef
if it wasn't found.

$lookFor can be "method", i.e. what the search was looking for.

If $lookFor is "method" and the POD isn't found, try in the base
classes, unless $ignoreBaseModules is true.

If the method POD is found in a base class, make sure that notice is
in the rhProperty->{pod} (once).

Set the rhProperty keys of the Location:

  found - $lookFor
  docType - "hint"
  name - the $name
  pod - the POD describing $name (includes podSection)
  podSection - the POD section the name is located in

pod will be munged to include podSection, and if the original pod
consisted of an "=item", it will be surrounded by "=over" 4 and
"=back".

Die on errors.

=cut
sub oLocationPod {
    my ($name, $lookFor) = Devel::PerlySense::Util::aNamedArg(["name", "lookFor"], @_);
    my %p = @_;
    my $ignoreBaseModules = $p{ignoreBaseModules} || 0;
    $lookFor eq "method" or croak("Invalid value for lookFor ($lookFor). Valid values are: 'method'.");

    my $rexName = quotemeta($name);
    for my $oLocationCur (@{$self->oMeta->raLocationPod}) {

        ###TODO: ignore name if it has a sigil, i.e "$name"/"%name"/"@name"
        #First match, this may have to be refined (go for the earliest occurence on the line, or the shortest line)
        if($oLocationCur->rhProperty->{pod} =~ /^= \w+ \s+ [^\n]*? \b $rexName \b /x) {
            my $oLocation = $oLocationCur->clone;
            $oLocation->rhProperty->{found} = $lookFor;
            $oLocation->rhProperty->{docType} = "hint";
            $oLocation->rhProperty->{name} = "$name";

            my $pod = $oLocation->rhProperty->{pod};
            $pod =~ /^=item\s/ and $pod = "=over 4\n\n$pod\n\n=back\n";
            $oLocation->rhProperty->{pod} = $oLocation->rhProperty->{podSection} . $pod;

            return($oLocation);
        }
    }


    $ignoreBaseModules and return(undef);
    #Fail to base classes, maybe

    for my $moduleBase ($self->aNameBase) {
        my $oDocumentBase = $self->oPerlySense->oDocumentFindModule(
            nameModule => $moduleBase,
            dirOrigin => dirname($self->file),
        ) or warn("Could not find module ($moduleBase)\n"), next;
        if(my $oLocation = $oDocumentBase->oLocationPod(
            name => $name,
            lookFor => $lookFor,
        )) {

            if( $oLocation->rhProperty->{pod} !~ /\n=head1 From <[\w:]+>\n$/) {
                $oLocation->rhProperty->{pod} .= "\n=head1 From <$moduleBase>\n";
            }

            return($oLocation);
        }
    }

    return(undef);
}





=head2 aMethodCallOf(nameObject => $nameObject, oLocationWithin => $oLocationWithin)

Find all the method calls of $nameObject in the $oLocationWithin.

Shortcut: assume the $oLocationWithin is the entire interesting
scope. Ignore morons who re-define their vars in inner scopes with a
different type. If this turns out to be a problem, fix the problem
then. Or smack them over the head with a trout.

Return sorted array with the method names called.

Die on errors.

=cut
sub aMethodCallOf {
    my ($nameObject, $oLocationWithin) = Devel::PerlySense::Util::aNamedArg(["nameObject", "oLocationWithin"], @_);


    #Stop methods
    my %hMethodStop = (isa => 1, can => 1);   #TODO: Move to property and config


    my $rexObject = quotemeta($nameObject);
    my %hMethod =
            map { $_ => 1 }
            grep { ! exists $hMethodStop{$_} } (
            $oLocationWithin->rhProperty->{source} =~ /
                             $rexObject
                             \s* -> \s*
                             ( \w+ )
                             /gsx
                         );

    return(sort keys %hMethod);
}





=head2 determineLikelyApi(nameModule => $nameModule)

Look in the document for sub declarations, $self->method calls, and
$self->{hash_key} in order to determine what is the likely API of the
packages of this document. Focus on the $nameModule and its base
classes.

Set the rhPackageApiLikely property with new
Devel::PerlySense::Document::Api objects for each package.

Return 1 on success. Die on errors.

Cached on the usual + $nameModule.

=cut
sub determineLikelyApi {
    my ($nameModule) = Devel::PerlySense::Util::aNamedArg(["nameModule"], @_);

    my $keyCache = "likelyApi\t$nameModule";
    if(my $rhPackageApi = $self->cacheGet($keyCache, $self->file)) {
        $self->rhPackageApiLikely($rhPackageApi);
    } else {
        $self->determineLikelyApi0(nameModule => $nameModule);
        $self->cacheSet($keyCache, $self->file, $self->rhPackageApiLikely);
   }

    return(1);
}





=head2 determineLikelyApi0(nameModule => $nameModule)

Implementation for determineLikelyApi()

=cut
sub determineLikelyApi0 {
    my ($nameModule) = Devel::PerlySense::Util::aNamedArg(["nameModule"], @_);


    my $rhPackageApi = {};

    my $oApiCur = Devel::PerlySense::Document::Api->new();
    my $packageCur = "main";
    my $sourcePackage = "";
    my @aNodeSub = ();
    for my $oNode ($self->oDocument->elements) {
        if ($oNode->isa("PPI::Statement::Package")) {
            $oApiCur->parsePackageSetSub(oDocument => $self, raNodeSub => \@aNodeSub, source => $sourcePackage);
            (keys %{$oApiCur->rhSub}) and $rhPackageApi->{$packageCur} = $oApiCur;


            $oApiCur = Devel::PerlySense::Document::Api->new();
            $packageCur = $oNode->namespace;
            $sourcePackage = "";
            @aNodeSub = ();
        }

        ###TODO: push this down into the API class?
        if ($oNode->isa("PPI::Statement::Sub") && ! $oNode->forward) {
            push(@aNodeSub, $oNode);
            $sourcePackage .= $oNode;
        }
    }
    $oApiCur->parsePackageSetSub(oDocument => $self, raNodeSub => \@aNodeSub, source => $sourcePackage);
    (keys %{$oApiCur->rhSub}) and $rhPackageApi->{$packageCur} = $oApiCur;



    #Look in base classes
    for my $nameBase ($self->aNameBase) {
        my $oDocumentBase = $self->oPerlySense->oDocumentFindModule(
            nameModule => $nameBase,
            dirOrigin => dirname($self->file),
        ) or next;

        debug("($nameModule) looking in base class ($nameBase)");
        $nameModule eq $nameBase and next;
        ###TODO: look for longer recursive chains

        $oDocumentBase->determineLikelyApi(nameModule => $nameBase);

        $self->mergePackageApiWithBase(
            nameModule => $nameModule,
            rhPackageApi => $rhPackageApi,
            nameModuleBase => $nameBase,
            rhPackageApiBase => $oDocumentBase->rhPackageApiLikely,
        );

    }


    $self->rhPackageApiLikely($rhPackageApi);

    return(1);
}





=head2 mergePackageApiWithBase(nameModule => $nameModule, rhPackageApi => $rhPackageApi, nameModuleBase => $nameModuleBase, rhPackageApiBase => $rhPackageApiBase)

Merge the $rhPackageApiBase of the base class with the existing
$rhPackageApi. Modify $rhPackageApi.

Only merge the API of the $nameModule.

Document::Api objects are cloned, not reused, but individual
Document::Location objects may be shared between documents and apis.

Return 1 on success, or 0 if the package wasn't found. Die on errors.

=cut
sub mergePackageApiWithBase {
    my ($nameModule, $rhPackageApi, $nameModuleBase, $rhPackageApiBase) = Devel::PerlySense::Util::aNamedArg(["nameModule", "rhPackageApi", "nameModuleBase", "rhPackageApiBase"], @_);

    my $oApiBase = $rhPackageApiBase->{$nameModuleBase} or return(0);

    my $oApi = $rhPackageApi->{$nameModule};
    $oApi or $oApi = $rhPackageApi->{$nameModule} = Devel::PerlySense::Document::Api->new();

    $oApi->mergeWithBase($oApiBase);

    return(1);
}





=head2 scoreInterfaceMatch(nameModule => $nameModule, raMethodRequired => $raMethodRequired, raMethodNice => $raMethodNice)

Rate the interface match between the document and the wanted interface
of the method names in $raMethodRequired + $raMethodNice.

If not all method names in $raMethodRequired are supported, the score
is 0, and this document should not be considered to support the
requirements.

The score is calculated like this:

 % of ($raMethod*) that is supported, except
 all required must be there.

 +

 % of the api that consists of $raMethod*. This will favour smaller
 interfaces in base classes.

Return score on success. Die on errors.

=cut
sub scoreInterfaceMatch {
    my ($nameModule, $raMethodRequired, $raMethodNice) = Devel::PerlySense::Util::aNamedArg(["nameModule", "raMethodRequired", "raMethodNice"], @_);

    my $oApi = $self->rhPackageApiLikely->{$nameModule} or return(0);

    for my $method (@$raMethodRequired) {
        $oApi->isSubSupported($method) or return(0);
    }

    my %hSeen;
    my @aMethod = grep { ! $hSeen{$_}++ } (@$raMethodRequired, @$raMethodNice);

    my $supportedMultiplier = 5;    #TODO: move to config
    my $score = ($oApi->percentSupportedOf(\@aMethod) * $supportedMultiplier) +
            $oApi->percentConsistsOf(\@aMethod);

    my $percentScore = sprintf("%.02f", ($score / ($supportedMultiplier + 1))) + 0;

    return($percentScore);
}





=head2 stringSignatureSurveyFromFile()

Calculate a Signature Survey string for the source in the document.

Return the string. Die on errors.

=cut
sub stringSignatureSurveyFromFile {
    return $self->stringSignatureSurveyFromSource( slurp($self->file) );
}





=head2 stringSignatureSurveyFromSource($stringSource)

Calculate a Signature Survey string for the $stringSource, based on
the idea in http://c2.com/doc/SignatureSurvey/ .

The idea is not to get an exact representation of the source but a
good feel for what it contains.

Return the survey string. Die on errors.

=cut
my $matchReplace = {
    q/{/ => q/{/,
    q/}/ => q/}/,
    q/"/ => q/"/,
    q/'/ => q/'/,
    q/;/ => q/;/,
    q/sub\s+\w+\s*{/ => q/SPECIAL/,
    q/sub\s+\w+\s*:\s*\w+[^{]+{/ => q/SPECIAL/,
    q/^=(?:head|item|for|pod)/ => q/SPECIAL/,
};
my $rexMatch = join("|", keys %$matchReplace );
sub _stringReplace {
    my ($match) = @_;

    if(index($match, "sub") > -1) {
        index($match, ":") > -1 and return "SA{";
        return "S{";
    }
    index($match, "=") > -1 and return "=";

    return $matchReplace->{$match};
}
sub stringSignatureSurveyFromSource {
    my ($source) = @_;

    my @aToken = $source =~ /($rexMatch)/gm;
#    print Dumper(\@aToken);
    my $signature = join(
        "",
        map { $self->_stringReplace($_) } @aToken,
    );

    #Remove closing " and ', they just clutter things up
    $signature =~ s/(["'])\1/$1/gsm;

    #Remove empty {}, they most often indicate hash accesses or derefs
    $signature =~ s/{}//gsm;

    #Remove =['"]+ that's a sign of quotes inside POD text
    $signature =~ s/=['"]+/=/gsm;

    return($signature);
}





=head1 IMPLEMENTATION METHODS


=head2 oLocationOfNode($oNode, [$extraRow = 0, $extraCol = 0])

Return Devel::PerlySense::Document::Location object for $oNode.

If $extraRow or $extraCol are passed, add that to the location.

=cut
sub oLocationOfNode {
	my ($oNode, $extraRow, $extraCol) = @_;
    $extraRow ||= 0;
    $extraCol ||= 0;

    return(
        Devel::PerlySense::Document::Location->new(
            file => $self->file,
            row => $oNode->location->[0] + $extraRow,
            col => $oNode->location->[1] + $extraCol,
        )
    );
}





=head2 aDocumentFind($what)

Convenience wrapper around $self->$oDocument->find($what) to account
for the unusable api.

Return list of matching nodes, or an empty list if none was found.

=cut
sub aDocumentFind {
	my ($what) = @_;
    return($self->aNodeFind($self->oDocument, $what));
}





=head2 aNodeFind($oNode, $what)

Convenience wrapper around $oNode->find($what) to account
for the unusable api.

Return list of matching nodes, or an empty list if none was found.

=cut
sub aNodeFind {
	my ($oNode, $what) = @_;
    my $raList = $oNode->find($what) or return();
    return(@$raList);
}





=head2 oLocationEnclosingSub($oNode)

Return a Document::Location object that is the enclosing sub of
$oNode, i.e. $oNode is located within the sub block. The Location
object has the following rhProperty keys:

  nameSub
  source
  oLocationEnd with: row and col

Return Location object with the sub, or undef if none was found. Die on
errors.

=cut
sub oLocationEnclosingSub {
	my ($oNode) = @_;

    #Simplification: assume there is only one sub on each row

    my ($row, $col) = @{$oNode->location};
    for my $oLocation (@{$self->oMeta->raLocationSub}) {
        if($row >= $oLocation->row && $row <= $oLocation->rhProperty->{oLocationEnd}->row) {
            return($oLocation);
        }
    }


    return(undef);
}





=head1 CACHE METHODS


=head2 cacheSet($key, $file, $rValue)

If a cache is active, store the $value in the cache under the total
key of ($file, $file's timestamp, $key).

$value should be a scalar or reference which can be freezed.

$file must be an existing file.

Return 1 if the $value was stored, else 0. Die on errors.

=cut
sub cacheSet {
	my ($key, $file, $rValue) = @_;
    return( $self->oPerlySense->cacheSet(file => $file, key => $key, value => $rValue) );
}





=head2 cacheGet($key, $file)

If a cache is active, get the value in the cache under the total key
of ($file, $file's timestamp, $key).

$file must be an existing file.

Return the value, or undef if the value could not be fetched. Die on
errors.

=cut
sub cacheGet {
	my ($key, $file) = @_;
    my $rValue = $self->oPerlySense->cacheGet(file => $file, key => $key);
    return($rValue);
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
