=head1 NAME

Devel::PerlySense::Class - A Perl Class

=head1 SYNOPSIS



=head1 DESCRIPTION

A Perl Class is a Perl Package with an OO interface.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Class;
$Devel::PerlySense::Class::VERSION = '0.0221';




use Spiffy -Base;
use Carp;
use Data::Dumper;
use File::Basename;
use Path::Class qw/dir file/;
use List::MoreUtils qw/ uniq /;

use Devel::PerlySense;
use Devel::PerlySense::Util;
use Devel::PerlySense::Util::Log;
use Devel::PerlySense::Document;
use Devel::PerlySense::Document::Api;
use Devel::PerlySense::Document::Meta;
use Devel::PerlySense::Document::Location;

use Devel::TimeThis;





=head1 PROPERTIES

=head2 oPerlySense

Devel::PerlySense object.

Default: set during new()

=cut
field "oPerlySense" => undef;





=head2 name

The Class name (i.e. the package name)

Default: ""

=cut
field "name" => "";





=head2 raDocument

Array ref with PerlySense::Document objects that define this class.

Default: []

=cut
field "raDocument" => [];





=head2 rhClassBase

Hash ref with (keys: base class names; values: base class
PerlySense::Class objects).

Default: {}

=cut
###TODO: Make this lazy, populate on first request, so we don't have
###to go all the way up all the time! There are enough objects in
###memory as it is (this makes all subclasses eagerly find all ther
###base classes...)
field "rhClassBase" => {};





=head1 API METHODS

=head2 new(oPerlySense, name, raDocument, rhClassSeen => {})

Create new PerlySense::Class object. Give it $name and associate it
with $oPerlySense.

$rhClassSeen is used to keep track of seen base classes in case we
encounter circular deps.

=cut
sub new {
    my ($oPerlySense, $name, $raDocument) = Devel::PerlySense::Util::aNamedArg(["oPerlySense", "name", "raDocument"], @_);
    my $rhClassSeen = {@_}->{rhClassSeen};

    $self = bless {}, $self;    #Create the object. It looks weird because of Spiffy
    $self->oPerlySense($oPerlySense);
    $self->name($name);
    $self->raDocument($raDocument);

    $rhClassSeen ||= { $name => $self };
    $self->findBaseClasses(rhClassSeen => $rhClassSeen);

    return($self);
}





=head2 newFromFileAt(oPerlySense => $oPerlySense, file => $file, row => $row, col => $col)

Create new PerlySense::Class object given the class found at $row,
$col in $file.

If there was no package started yet at $row, $col, but there is one
later in the file, use the first one instead (this is when you're at
the top of the file and the package statement didn't happen yet).

Return new object, or undef if no class was found, or die if the file
doesn't exist.

=cut
sub newFromFileAt {
    my ($oPerlySense, $file, $row, $col) = Devel::PerlySense::Util::aNamedArg(["oPerlySense", "file", "row", "col"], @_);

    my $oDocument = $oPerlySense->oDocumentParseFile($file);
    my $package = $oDocument->packageAt(row => $row);

    if($package eq "main") {
        $package = ($oDocument->aNamePackage)[0] or return undef;
    }

    my $class = Devel::PerlySense::Class->new(
        oPerlySense => $oPerlySense,
        name => $package,
        raDocument => [ $oDocument ],
    );

    return($class);
}





=head2 newFromName(oPerlySense, name, dirOrigin, rhClassSeen)

Create new PerlySense::Class object given the class $name.

Look for the module file starting at $dirOrigin.

Return new object, or undef if no class was found with that $name.

=cut
sub newFromName {
    my ($oPerlySense, $name, $dirOrigin, $rhClassSeen) = Devel::PerlySense::Util::aNamedArg(["oPerlySense", "name", "dirOrigin", "rhClassSeen"], @_);

    my $oDocument = $oPerlySense->oDocumentFindModule(
        nameModule => $name,
        dirOrigin => $dirOrigin,
    ) or return undef;

    my $class = Devel::PerlySense::Class->new(
        rhClassSeen => $rhClassSeen,
        oPerlySense => $oPerlySense,
        name => $name,
        raDocument => [ $oDocument ],
    );

    return($class);
}





=head2 findBaseClasses(rhClassSeen)

Find the base classes of this class and set (replace) rBaseClass with
newly created Class objects.

Reuse any class names and objects in $rhClassSeen (keys: class names;
values: Class objects), i.e. don't follow them upwards, they have
already been taken care of.

=cut
sub findBaseClasses {
    my ($rhClassSeen) = Devel::PerlySense::Util::aNamedArg(["rhClassSeen"], @_);

    my $rhClassBase = {};

    debug("Checking class (" . $self->name . ") for inheritance\n");

    ###TODO: protect against infinite inheritance loops
    for my $oDocument (@{$self->raDocument}) {
        for my $classNameBase ($oDocument->aNameBase) {
            debug("  Base for (" . $self->name . ") is ($classNameBase)\n");
            my $classBase =
                    $rhClassSeen->{$classNameBase} ||
                    ref($self)->newFromName(
                        oPerlySense => $self->oPerlySense,
                        rhClassSeen => $rhClassSeen,
                        name => $classNameBase,
                        dirOrigin => dirname($oDocument->file),
                    ) or debug("WARN: Could not find parent ($classNameBase)\n"), next;  #Don't stop if we can't find the base class. Maybe warn?

            $rhClassSeen->{$classNameBase} = $classBase;

            $rhClassBase->{$classNameBase} = $classBase;
        }
    }

    $self->rhClassBase($rhClassBase);

    return 1;
}





=head2 rhClassSub()

Find the sub classes of this class and return a hash ref with (keys:
Class names; values: Class objects).

Look for subclasses in the directory of this Class, and below.

(In the future, look in all of the current project.)

(this is a horribly inefficient way of finding subclasses. When there
is Project with metadata, use that instead of looking everywhere).

=cut
sub rhClassSub {

    my $oDocument = $self->raDocument->[0] or return {};
    my $fileClass = $oDocument->file;
    my $dirClass = dir( dirname($fileClass) )->absolute;

    my $nameClass = $self->name;
    my @aDocumentCandidate =
            $self->oPerlySense->aDocumentGrepInDir(
                dir => $dirClass,
                rsGrepFile => sub { shift ne $fileClass },
                rsGrepDocument => sub { shift->hasBaseClass($nameClass) },
            ) or return {};

    ###TODO: can any of this be pushed down into the document/meta
    ###class?
    my $rhPackageDocument = {};
    for my $oDocumentCandidate (@aDocumentCandidate) {
        for my $package ($oDocumentCandidate->aNamePackage) {
            $rhPackageDocument->{$package} ||= [];
            push(@{$rhPackageDocument->{$package}}, $oDocumentCandidate);
        }
    }

    my $rhClassSub = {
        map {
            my $namePackage = $_;

            $_ => ref($self)->new(
                oPerlySense => $self->oPerlySense,
                name => $namePackage,
                raDocument => $rhPackageDocument->{$namePackage},
            );
        }
        keys %$rhPackageDocument
    };

    return $rhClassSub;
}





=head2 rhDirNameClassInNeighbourhood()

Find the classes in the neighbourhood of this class and return a hash
ref with (keys: up, current, down; values: array refs with (Package names).

=cut
sub raClassInDirs {
    my ($raDir) = @_;

    my @aNameClass;
    for my $dir (@$raDir) {
        push(@aNameClass, $self->aNameClassInDir(dir => $dir));
    }

    return [ sort( uniq(@aNameClass) ) ];
}
sub rhDirNameClassInNeighbourhood {

    my $dir = dir(dirname( $self->raDocument->[0]->file ));
    my $raDir = [ $dir ];
    my $raDirUp = [ $dir->parent ];

    my $nameClassLast = (split(/::/, $self->name))[-1];
    my $raDirDown = [ dir($dir, $nameClassLast) ];

    return({
        up      => $self->raClassInDirs($raDirUp),
        current => $self->raClassInDirs($raDir),
        down    => $self->raClassInDirs($raDirDown),
    });
}





=head2 aNameClassInDir(dir => $dir)

Find the classes names in the .pm files in $dir and return a list of
Class names.

=cut
sub aNameClassInDir {
    my ($dir) = Devel::PerlySense::Util::aNamedArg(["dir"], @_);

    my @aNameClass =
            map {
                my $oDocument = Devel::PerlySense::Document->new(
                    oPerlySense => $self->oPerlySense,
                );
                $oDocument->parse(file => $_) ? $oDocument->aNamePackage : ();
            }
            glob("$dir/*.pm");

    return sort( uniq( @aNameClass ) );
}





=head2 aNameModuleUse()

Return array with the names of the "use MODULE" modules in the Class.

=cut
sub aNameModuleUse {
    return sort( uniq( map { $_->aNameModuleUse } @{$self->raDocument} ) );
}





=head2 aBookmarkMatchResult()

Return array of Bookmark::MatchResult objects that matches the current
source.

=cut
sub aBookmarkMatchResult {
    my $file = $self->raDocument->[0]->file;
    return $self->oPerlySense->oBookmarkConfig->aMatchResult(file => $file);
}





=head2 dirModule()

Return the base dir for this class, i.e. the dir in which the main .pm
file is in.

=cut
sub dirModule {
    my $file = $self->raDocument->[0]->file;
    return file($file)->absolute->dir . "";
}





=head2 oLocationMethodDoc(method => $method)

Find the docs for the $method name and return a Location object
similar to PerlySense->oLocationMethodDocFromDocument, or undef if no
doc could be found.

Die on errors.

=cut
sub oLocationMethodDoc {
    my ($method) = Devel::PerlySense::Util::aNamedArg(["method"], @_);
    my $oDocument = $self->raDocument->[0] or return undef;
    return $self->oPerlySense->oLocationMethodDocFromDocument($oDocument, $method);
}





=head2 oLocationMethodGoTo(method => $method)

Find the declaration for the $method name and return a Location object
similar to PerlySense->oLocationSubDefinitionFromDocument, or undef if no
declaration could be found.

Die on errors.

=cut
sub oLocationMethodGoTo {
    my ($method) = Devel::PerlySense::Util::aNamedArg(["method"], @_);
    my $oDocument = $self->raDocument->[0] or return undef;
    return $self->oPerlySense->oLocationMethodDefinitionFromDocument(
        nameClass => $self->name,
        nameMethod => $method,
        oDocument => $oDocument,
    );
}





=head2 oLocationSubAt(row => $row, col => $col)

Return a Devel::PerlySense::Document::Location object with the
location of the sub definition at $row/$col, or undef if it row/col
isn't inside a sub definition.

Die on errors.

=cut
sub oLocationSubAt {
    my ($row, $col) = Devel::PerlySense::Util::aNamedArg(["row", "col"], @_);
    my $oDocument = $self->raDocument->[0] or return undef;
    return $oDocument->oLocationSubAt(row => $row, col => $col);
}





=head2 oLocationSub(name => $name)

Return a Devel::PerlySense::Document::Location object with the
location of the sub declaration called $name, or undef if it wasn't
found.

Die on errors.

=cut
sub oLocationSub {
    my ($name) = Devel::PerlySense::Util::aNamedArg(["name"], @_);
    my $oDocument = $self->raDocument->[0] or return undef;
    return $oDocument->oLocationSub(name => $name, package => $self->name);
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
