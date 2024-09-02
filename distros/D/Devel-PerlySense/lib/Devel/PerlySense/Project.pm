=head1 NAME

Devel::PerlySense::Project - A Project root

=head1 SYNOPSIS




=head1 DESCRIPTION

A Project describes the root directory of a source tree.

A Project has configuration settings.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Project;
$Devel::PerlySense::Project::VERSION = '0.0223';


use Spiffy -Base;
use Carp;
use Data::Dumper;
use File::Basename;
use Path::Class;
use File::Slurp;
use File::chdir;
use File::Find::Rule;
use Perl::Critic 1.105;
use List::MoreUtils qw/ uniq /;

use Devel::PerlySense;
use Devel::PerlySense::Util;
use Devel::PerlySense::Util::Log;
use Devel::PerlySense::Config::Project::Default;





=head1 PROPERTIES

=head2 dirProject

The effective project root dir.

Readonly.

=cut
sub dirProject {
    return
            $self->dirProjectExplicitDir ||
            $self->dirProjectImplicitUse ||
            $self->dirProjectImplicitDir;
}





=head2 dirProjectExplicitDir

If known, the root dir made explicit by the existence of a project
directory and config, else ""

Default: ""

=cut
field "dirProjectExplicitDir" => "";





=head2 dirProjectImplicitUse

If known, the root dir indicated by a found used module, else "".

Default: ""

=cut
field "dirProjectImplicitUse" => "";





=head2 dirProjectImplicitDir

If known, the root dir indicated by the presence of "lib" or "t", else "".

Default: ""

=cut
field "dirProjectImplicitDir" => "";





=head2 oConfig

A Config::Project object with the current Project Config. This gets
loaded if there is a config file available when the Project is
identified.

Default: An Config::Project::Default object

=cut
field "oConfig" => Devel::PerlySense::Config::Project::Default->new();





=head2 rhConfig

The actual hashref with config values.

Readonly (that includes the entire data structure).

=cut
sub rhConfig {
    return $self->oConfig->rhConfig;
}





=head2 oPerlySense

Devel::PerlySense object.

=cut
field "oPerlySense" => undef;





=head2 nameVcs

The name of the Version Control system for the project.

Readonly. Currently supported:

  git
  svn
  none

In that order, so that if there's a Git repo on top of a SVN repo, git
is found.

=cut
sub nameVcs {

    #Git
    $self->oPerlySense->dirFindLookingAround(
        ".git",
        $self->dirProject,
        ["."],
    ) and return("git");

    #Subversion
    -d dir($self->dirProject, ".svn") and return("svn");

    return("none");
}





=head1 CLASS METHODS

=head2 newFromLocation(file => $file, dir => $dir, oPerlySense => $oPs)

Create new Project given either $file, or $dir.

First, search for an explicit project root directory, then try to find
any modules used in $file (if passed), then try to find any "lib" or
"t" directory upwards of $file or $dir.

$file takes precedence over $dir if both are specified.

If none if this works out, no Project can be created and undef is
returned.

Return the new object, or undef if no project could be found.

=cut
sub newFromLocation(@) {
    my $pkg = shift;
    my ($oPerlySense) = Devel::PerlySense::Util::aNamedArg(["oPerlySense"], @_);
    my %p = @_;
    my $file = $p{file};
    my $dir = $p{dir};
    $file and $dir = dirname($file);
    $dir and $dir = dir($dir)->absolute;

    my $oProject;

    $dir and $oProject = $pkg->newFindExplicit(
        dir => $dir,
        oPerlySense => $oPerlySense,
    ) and return $oProject;


    #If file, look for the dir from where any package in the file can
    #be used
    if($file and my $oDocument = $oPerlySense->oDocumentParseFile($file)) {
        for my $package ($oDocument->aNamePackage) {
            my $filePackage = $oPerlySense->fileFromModule($package);
            my $dirFound = $oPerlySense->dirFindLookingAround($filePackage, $dir);

            if($dirFound) {
                my $dirProject = dir($dirFound)->parent . ""; ###TODO: if lib or bin
                return $pkg->new(
                    oPerlySense => $oPerlySense,
                    dirProjectImplicitUse => $dirProject,
                );
            }
        }
    }

    #If dir, look for dirs
    if($dir) {
        my $dirFound =
                   $oPerlySense->fileFindLookingAround("lib", $dir) ||
                   $oPerlySense->fileFindLookingAround("t", $dir);

        if($dirFound) {
            my $dirProject = dir($dirFound)->parent . ""; ###TODO: if lib or bin

            #Special case the Unix style root dir. It's never a
            #Project dir, but if often contains a lib dir and so will
            #get identified as a Project.
            #
            #If it _is_ a root dir, this can be overriden with an
            #explicit .PerlySenseProject dir.
            #
            #On Windows, the root looks like X:\, and it's not
            #entirely unlikely that a secondary drive or a SUBST drive
            #letter contains the project root.
            $dirProject eq "/" and return undef;

            return $pkg->new(
                oPerlySense => $oPerlySense,
                dirProjectImplicitDir => $dirProject,
            );
        }
    }

    return(undef);
}





=head2 newFindExplicit(dir => $dir, oPerlySense => $oPs)

Create new Project if there is an explicit .PerlySenseProject
directory in the path above $dir.

Return the new object, or undef if no project could be found.

=cut
sub newFindExplicit(@) {
    my $pkg = shift;
    my ($oPerlySense, $dir) = Devel::PerlySense::Util::aNamedArg(["oPerlySense", "dir"], @_);

    if(my $dirProject = $oPerlySense->dirFindLookingAround(
        ".PerlySenseProject",
        $dir,
        ["."],
    )) {
        return $pkg->new(
            oPerlySense => $oPerlySense,
            dirProjectExplicitDir => $dirProject,
            oConfig => Devel::PerlySense::Config::Project->new(dirRoot => $dirProject),
        );
    }

    return undef;
}





=head1 MEHTODS

=head2 rhRunFile(file => $fileSource, [rhConfigType = DEDUCED_FROM_FILE], [ keyConfigCommand = "command" ])

Like rhRunFile0, but with what => "run".

=cut
sub rhRunFile {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);
    my %p = @_;
    return( $self->rhRunFile0(%p, what => "run") );
}





=head2 rhDebugFile(file => $fileSource, [rhConfigType = DEDUCED_FROM_FILE], [ keyConfigCommand = "command" ])

Like rhRunFile0, but with what => "debug".

=cut
### XXX refactor, DRY with rhRunFile
sub rhDebugFile {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);
    my %p = @_;
    return( $self->rhRunFile0(%p, what => "debug") );
}





=head2 rhRunFile0(file => $fileSource, what => "run" | "debug", [rhConfigType = DEDUCED_FROM_FILE], [ keyConfigCommand = "command" ])

Figure out what type of source file $fileSource is, and how it should
be run/debugged.

The settings in the global config->{$what_file} is used to determine
the details.

The command to use is taken from
config->{$what_file}->{$keyConfigCommand}, if that is specified,
otherwise for "command".

Return hash ref with (keys: "dir_$what_from", "command_$what",
"type_source_file"), or die on errors (like if no Project could be
found).

dir_$what_from is an absolute directory name which should be the cwd
when command_$what is executed.

type_source_file is something like "Test", "Module".

=cut
sub rhRunFile0 {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);
    my %p = @_;
    my $rhConfigType = $p{rhConfigType};
    my $what = $p{what};
    my $keyConfigCommand = $p{keyConfigCommand} || "command";

    $file = file($file)->absolute;
    $rhConfigType ||= $self->rhConfigTypeForFile(
        file      => $file,
        keyConfig => "${what}_file",
    );

    my $dirProject = dir($self->dirProject)->absolute;
    my %hTypeDirRunFrom = (
        source_root_directory => sub { $dirProject },
        file_directory        => sub { $file->dir },
    );
    my $typeRunFrom = $rhConfigType->{"${what}_from"};
    my $rsDirRunFrom = $hTypeDirRunFrom{$typeRunFrom} or die("Invalid ${what}_from value ($typeRunFrom)\n" . Dumper($rhConfigType) . "Allowed values: (" . join(", ", (sort keys %hTypeDirRunFrom)) . ")\n");
    my $dirRunFrom = $rsDirRunFrom->();

    my @aDirIncProject = $self->aDirIncProject(dirRelativeTo => $dirRunFrom);
    my $optionInc = join(" ", map { qq|"-I$_"| } @aDirIncProject);

    my $fileSource = $file->relative($dirRunFrom);
    my $command
        =  $rhConfigType->{ $keyConfigCommand }
        || $rhConfigType->{command}
        or die("Could not find a config value for which 'command' to run\n");
    my $commandRun = textRenderTemplate(
        $command,
        {
            INC         => $optionInc,
            SOURCE_FILE => $fileSource . "",
        },
    );

    my $rhConfigRun = {
        "dir_${what}_from" => $dirRunFrom . "",
        "command_${what}"  => $commandRun,
        type_source_file   => $rhConfigType->{moniker},
    };
    return($rhConfigRun);
}





=head2 rhConfigTypeForFile(file => $fileSource, keyConfig => CONFIG_KEY)

Return the config type hash ref (keys: command, moniker) from the ones
available in the config. Match the $fileSource name against each rex
in the config.

Die if no configType could be identified.

=cut
sub rhConfigTypeForFile {
    my ($file, $keyConfig) = Devel::PerlySense::Util::aNamedArg(["file", "keyConfig"], @_);

    my $rhConfig = $self->oPerlySense->rhConfig;
    for my $rhConfigType (@{ $rhConfig->{ $keyConfig } }) {
        my $rex = $rhConfigType->{rex}
                or die("Missing rex key in config chunk: " . Dumper($rhConfigType));

        eval { $file =~ /$rex/ } and return $rhConfigType;
        $@ and die("Invalid rex value in config chunk.\nError: $@\n" . Dumper($rhConfigType));
    }

    die("No run_perl rex matched the file ($file). Please check your config\n");
}





=head2 aDirIncProject(dirRelativeTo => $dirRelativeTo)

Return array with dir objects which are the inc_dir directories in the
config, plus the usual inc directories. They are all relative to
$dirRelativeTo.

=cut
sub aDirIncProject {
    my ($dirRelativeTo) = Devel::PerlySense::Util::aNamedArg(["dirRelativeTo"], @_);

    my $dirProject = dir($self->dirProject)->absolute;
    my $dirProjectRelativeTo = $dirProject->relative( $dirRelativeTo );

    ###TODO: extract method for the inc_dir config entry aIncDirConfig
    my @aDirIncProject = @{ $self->oPerlySense->rhConfig->{project}->{inc_dir} || [] };
    my @aDirInc = (@aDirIncProject, ".", "lib");

    my @aDirIncRelative =
            map { dir($dirProjectRelativeTo, $_) . "" }
            @aDirInc;

    return @aDirIncRelative;
}





=head2 aDirIncAbsolute()

Return array with absolute dir objects which are the inc_dir
directories in the config, plus the usual inc directories.

=cut
sub aDirIncAbsolute {
    my $dirProject = dir($self->dirProject)->absolute;

    ###TODO: extract method for the inc_dir config entry aIncDirConfig
    my @aDirIncProject = @{
        $self->oPerlySense->rhConfig->{project}->{inc_dir} || []
    };
    my @aDirInc = (@aDirIncProject, ".", "lib");

    my @aDirIncAbsolute =
        map { dir($dirProject, $_)->absolute . "" }
            @aDirInc;
    return @aDirIncAbsolute;
}





=head2 isFileInProject(file => $file)

Return true if $file is within the project root, or in any of the INC
directories, else false. Die on errors.

Test logically/structurally, not whether the file actually exists.

=cut
sub isFileInProject {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    my @aDirInc =
            map { dir($self->dirProject, $_) }
            @{ $self->oPerlySense->rhConfig->{project}->{inc_dir} || [] };
    my @aDirSourceAbsolute =
            map { dir($_)->absolute }
            ($self->dirProject, @aDirInc);

    ###TODO: Comment out  debug statements when that failing test in t/PerlySense-Project-file-in-project.t is fixed
    debug("\nTESTING WHETHER FILE\n($file) IS IN PROJECT\n(" . $self->dirProject . "),\ni.e.\n(" . join(")\n(", @aDirSourceAbsolute) . ")\n");
    my @aDirProjectRegex = map { qr/^ \Q$_\E /x } @aDirSourceAbsolute;

    my $dirFileAbsolute = dir( filePathNormalize( file($file)->absolute->dir ) );
    debug("DIR ABSOLUTE ($dirFileAbsolute)\n");

    for my $dirProject (map { dir(filePathNormalize($_)) } @aDirSourceAbsolute) {
        debug("Checking whether\n($dirFileAbsolute) is within\n($dirProject)\n");
        $dirProject->subsumes($dirFileAbsolute) and debug("Found it"), return 1;
    }

    debug("FILE ($file) is NOT in the Project (" . $self->dirProject . ")\n");
    return 0;
}





=head2 flymakeFile(file => $fileSource)

Do a flymake run with $fileSource according to the flymake config and
output the result to STDOUT and STDERR.

Return 1 or die on errors (but that will look like the result of a
failed flymake run).

=cut

sub flymakeFile {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    if($self->oPerlySense->rhConfig->{external}{editor}{emacs}{flymake}{syntax}) {
        my $rhConfigRun = $self->rhRunFile(
            file => $file,
            rhConfigType =>  {
                command => q{perl -c ${INC} "${SOURCE_FILE}" 2>&1 | perl -ne " /Subroutine [\\w:]+ redefined at/ or print"},
                moniker => "Flymake",
                rex => "",
                run_from => "file_directory",
            },
        );

        local $CWD = $rhConfigRun->{dir_run_from};
        system( $rhConfigRun->{command_run} );
    }

    if($self->oPerlySense->rhConfig->{external}{editor}{emacs}{flymake}{critic}) {
        ###TODO: don't run if syntax errors found

        my $fileConfigCritic = file(
            dir($self->dirProject)->absolute, ".PerlySenseProject", ".perlcritic",
        );

        my @aOption = (-profile => $fileConfigCritic . "");
        -e $fileConfigCritic or @aOption = ();

        my $oCritic = Perl::Critic->new(@aOption);

        my @aViolation = $oCritic->critique($file);

        Perl::Critic::Violation::set_format( "%m near '%r' (%e, %p) at %f line %l.\n" );
        for my $violation (@aViolation) {
            print STDERR "Warning: $violation";
        }
    }

    return 1;
}





=head2 rhSubCovered(file => $fileSource)

Do a "covered subs" call with $fileSource.

Die if Devel::CoverX::Covered isn't installed.

Return hash ref with (keys: sub name; values: quality)), or an empty
hash ref if no coverage info was found for $fileSource.

Any subs with the same name will have their qualities combined.

=cut
sub rhSubCovered {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    local $CWD = $self->dirProject;

    eval {
        require Devel::CoverX::Covered;
        require Devel::CoverX::Covered::Db;
    };
    $@ and die("Devel::CoverX::Covered isn't installed\n");

    ###TODO: use dir specified in config and/or on command line
    local $CWD = $self->dirProject . "";

    ###TODO: Change Devel::CoverX::Covered to expose this dir properly
    ###and get it from there.
    my $dirDb = "covered";
    -d $dirDb or return( {} );

    my $db = Devel::CoverX::Covered::Db->new();
    my $fileRelative = file($file)->relative( $self->dirProject );
    my %hSubQuality;
    for my $raSubQuality ( $db->covered_subs($fileRelative) ) {
        my ($sub, $quality) = @$raSubQuality;
        $hSubQuality{$sub} += $quality;
    }

    return(\%hSubQuality);
}





=head2 raFileTestOther(file => $fileSource, [sub => $sub])

Return array ref with file names of files related to $file and
possibly $sub, i.e. the "other" files related $file.

If $file is a source file, return test files, and vice verca.

$sub is only ever active when $fileSource is a source file.

Die if Devel::CoverX::Covered isn't installed.

=cut
sub raFileTestOther {
    my ($file, $sub) = Devel::PerlySense::Util::aNamedArg(["file", "sub"], @_);

    eval {
        require Devel::CoverX::Covered;
        require Devel::CoverX::Covered::Db;
    };
    $@ and die("Devel::CoverX::Covered isn't installed\n");

    ###TODO: verify there is a cover_db database present

    local $CWD = $self->dirProject . "";

    my $db = Devel::CoverX::Covered::Db->new();

    my $method = "source_files_covered_by";                    # Default to test file
    $file =~ m|\.pm$| and $method = "test_files_covering";     # If a module, it's source
    $file =~ m|/t/|   and $method = "source_files_covered_by"; # If it's in /t/, it's a test
    $file =~ m|\.t$|  and $method = "source_files_covered_by"; # If it's a .t file, it's a test
    ### TODO: config with list of lib dirs and list of test dirs
    debug("raFileTestOther with method ($method)");

    my $fileRelative = file($file)->relative( $self->dirProject );
    my $raFileTestOther = [ $db->$method($fileRelative, $sub) ];

    return($raFileTestOther);
}





=head2 raFileProjectOther(file => $fileSource, [sub => $sub])

Return array ref with file names of files corresponding to $file.

Die if there is no config file.

=cut
sub raFileProjectOther {
    my ($file, $sub) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    eval {
        require File::Corresponding;
        require File::Corresponding::Config::Find;
    };
    $@ and die("File::Corresponding isn't installed\n");


    # Work from the project dir, so the rest of the paths will just work out
    local $CWD = $self->dirProject . "";

    my $fileConfig = File::Corresponding::Config::Find->new(
        preferred_dirs => [ dir(".PerlySenseProject"), dir(".") ],
    )->user_config(".corresponding_file")
            or die("Could not find a '.corresponding_file' config file in either 1) the .PerlySenseProject;  b) the current directory;  c) your home directory. See perldoc File::Corresponding for information on how to create one.\n");

    my $corresponding = File::Corresponding->new();
    eval { $corresponding->load_config_file($fileConfig) }
            or die("Could not read config file ($fileConfig): $@\n");

    my $fileRelative = file($file)->relative( $self->dirProject );
    my @aFileProjectOther = uniq(
        map { $_->file }
        @{$corresponding->corresponding( $fileRelative )}
    );

    return(\@aFileProjectOther);
}





=head2 aFileSourceCode()

Return array with file names with perl source code in the project.

# TODO: also look inside files without extension and check for perlyness

=cut
sub aFileSourceCode {
    return File::Find::Rule
        ->name("*.pm", "*.pl")
        ->in( $self->aDirIncAbsolute );
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
