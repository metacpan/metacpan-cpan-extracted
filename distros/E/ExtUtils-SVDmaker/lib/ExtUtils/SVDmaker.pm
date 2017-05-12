#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  ExtUtils::SVDmaker;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.12';
$DATE = '2004/05/25';

######
# Distribution Program Modules
#
use Cwd;
use File::Path;
use Pod::Text;
use Pod::Html;
use File::Copy;
use Config;
use Test::Harness;

######
# Software Diamonds Modules
#
use Archive::TarGzip;
use File::AnySpec 1.13;
use File::Maker 0.03;
use File::Package 1.16;
use File::SmartNL 1.14;
use File::Where;
use Text::Column;
use Text::Replace;
use Text::Scrub 1.17;
use Tie::Form 0.01;
use Tie::Layers 0.04;

use vars qw(@ISA);
@ISA = qw(File::Maker);  # inherit File::Maker methods

######
# Hash of targets
#
my %expand_targets = (
        all => [ qw(clear_all check_svd_db restore_previous auto_revise write_svd_pm makemake test tar ppd) ],
        auto_revise => [ qw(clear_all check_svd_db restore_previous auto_revise) ],
        check_svd_db => [ qw(clear_all check_svd_db) ],
        clear => [ qw(clear) ],
        dist => [ qw(clear_all check_svd_db restore_previous auto_revise makemake tar_gzip ppd) ],
        tar_gzip => [ qw(clear_all check_svd_db restore_previous auto_revise write_svd_pm makemake tar) ],
        makemake => [ qw(clear_all check_svd_db restore_previous auto_revise makemake) ],
        ppd => [ qw(clear_all check_svd_db ppd) ],
        readme_html => [ qw(clear_all check_svd_db restore_previous auto_revise write_svd_pm readme_html)],
        restore_previous => [ qw(clear_all check_svd_db restore_previous) ],
        test => [ qw(clear_all check_svd_db restore_previous auto_revise test) ],
        write_svd_pm => [ qw(clear_all check_svd_db restore_previous auto_revise write_svd_pm) ],
        __no_target__ => [ qw(clear_all check_svd_db restore_previous auto_revise write_svd_pm makemake test tar readme_html) ],
);


######
#
#
sub auto_revise
{

    my ($self) = @_;
    return 1 if $self->{auto_revise};
    $self->{auto_revise} = 1;

    my $formDB = $self->{FormDB};
    my $fspec_in = $self->{options}->{fspec_in};
    chdir $formDB->{TOP_DIR};

    my @inventory = ();
    my @manifest=();
    my $date = $formDB->{DATE};

    ######
    # Add input and files generated after auto_revise
    #
    my $svd_file = File::AnySpec->os2fspec( $formDB->{SVD_FSPEC}, $formDB->{PM_File_Relative});
    my $comment =  $formDB->{PREVIOUS_RELEASE} ? "revised $formDB->{PREVIOUS_RELEASE}" : 'new';
    push @manifest,$svd_file;
    push @inventory, [$svd_file, $formDB->{VERSION}, $date, $comment];

    ######
    # List automatically generated files after auto revise files
    #
    $comment =  $formDB->{PREVIOUS_RELEASE} ? "generated, replaces $formDB->{PREVIOUS_RELEASE}" : 'generated new';
    foreach my $file ( 
          'MANIFEST', 
          'Makefile.PL',
          'README') {
        push @manifest, $file;
        push @inventory, [$file, $formDB->{VERSION}, $date, $comment];
    }
    $formDB->{MANIFEST} = \@manifest;    
    $formDB->{inventory} = \@inventory;

 
    my $release_dir = $formDB->{RELEASE_DIR};
    my ($file,$work_file,$release_file,$temp_file,$to_file);

    #####
    # auto revise each file
    #
    my @auto_revise = @{$formDB->{AUTO_REVISE_LIST}};
    foreach $file (@auto_revise) {
        ($work_file,$to_file) = @$file;
        unless( -f $work_file ) {
            next if -d $work_file;
            my $file = File::Spec->catfile( cwd(), $work_file);
            warn "The file $file does not exist\n";
            next;
        }
        $release_file = File::Spec->catfile($release_dir, $to_file);
        $self->auto_revise_file($work_file, $release_file, $to_file, 'auto_revise');
    }

    #####
    # replace file but do not revise
    #
    my @replace = @{$formDB->{REPLACE_LIST}};
    foreach $file (@replace) {
        ($work_file,$to_file) = @$file;
        unless( -f $work_file ) {
            next if -d $work_file;
            my $file = File::Spec->catfile( cwd(), $work_file);
            warn "The file $file does not exist\n";
            next;
        }
        $release_file = File::Spec->catfile($release_dir, $to_file);
        $self->auto_revise_file($work_file, $release_file, $to_file);
    }


    $formDB->{DIST_INVENTORY} =  Text::Column->format_array_table(
                 $formDB->{inventory}, [60,7,10,24], ['file','version','date','comment']);

    1
}





######
#
#
sub auto_revise_file
{
    my($self, $work_file, $release_file, $to_file, $auto_revise ) = @_;

    my $formDB = $self->{FormDB};

    unless($work_file) {
        warn( "No work file\n");
        return undef;
    }

    unless($release_file) {
        warn( "No work file\n");
        return undef;
    }

    if( $formDB->{CHANGE2PREVIOUS} ) {
         eval '$release_file  =~ ' . $formDB->{CHANGE2PREVIOUS};
         if($@) {
            warn "Cannot change work file, $release_file, to previous name\n";
         }
    }

    unless( -e $work_file ) {
        unlink( $release_file );

        return 1;
    }


    ################
    # Read the work (current, previous version) file contents.
    #
    return undef unless open( WORK, "< $work_file" );
    binmode WORK;
    my $work_contents = join ( '', <WORK> );
    close WORK;

    ######
    # Try to find the Version and date from the work (current, previous version) file contents.
    # 
    my ($work_version, $work_date);
    if( $auto_revise ) {

        ($work_version) = $work_contents =~ /\$VERSION\s*=\s*['"]?\s*(\d+\.\d+)\s*['"]?/;
        $work_version = '' unless $work_version;

        ($work_date) = $work_contents =~ /\$DATE\s*=\s*['"]?(.*?)['"]?/;
        $work_date = '' unless $work_date;

    }
 
    ########
    # If there is no work_version try to pick one up from
    # the previous inventory
    #
    my ($inventory_version, $inventory_date, $work_previous);
    my $work_file_fspecin = File::AnySpec->os2fspec($formDB->{SVD_FSPEC}, $work_file );
    my $release_file_fspecin = File::AnySpec->os2fspec($formDB->{SVD_FSPEC}, $to_file );
    unless( $work_version ) {
        $work_previous = $formDB->{PREVIOUS_INVENTORY}->{$work_file_fspecin};
        $inventory_version = ($work_previous && @$work_previous[0]) ? @$work_previous[0] : $formDB->{VERSION};
    }
    unless( $work_date ) {
        $work_previous = $formDB->{PREVIOUS_INVENTORY}->{$work_file_fspecin};
        $inventory_date = ($work_previous && @$work_previous[1]) ? @$work_previous[1] : $formDB->{DATE};
    }

    my $inventory_p = $formDB->{inventory};
    my $manifest_p = $formDB->{MANIFEST};
    my $release_date = $formDB->{DATE};
    unlink $release_file unless $formDB->{PREVIOUS_RELEASE};
    my $changed = 0;
    if ( -f $release_file ) {

        return undef unless open( RELEASE, "< $release_file" );
        binmode RELEASE;
        my $release_contents = join ( '', <RELEASE> );
        close RELEASE;
        
        ######
        # Make sure have an inventory version.
        #
        my ($release_version) = $release_contents =~ /\$VERSION\s*=\s*['"]*\s*(\d+\.\d+)\s*['"]*/;
        $inventory_version = $release_version unless $inventory_version;
        $inventory_version = '0.01' unless $inventory_version;
       
        ######
        # Blank out version and date for comparasion
        #
        my $release_contents_scrub = Text::Scrub->scrub_date_version( $release_contents);
        my $work_contents_scrub = Text::Scrub->scrub_date_version( $work_contents);
        
        #####
        # If the files are the same return
        #
        $work_version = ($work_version) ? $work_version : $inventory_version;
        $work_date = ($work_date) ? $work_date : $inventory_date;
        if( $release_contents_scrub eq $work_contents_scrub) {
             push @$inventory_p, [$release_file_fspecin, $work_version, $work_date, 'unchanged'];
             push @$manifest_p, $release_file_fspecin;
             return 1;
        }

        #######
        # The file has changed since the last release.
        #
        $release_version = ($inventory_version < $work_version) ? $work_version : $inventory_version + 0.01;
        push @$inventory_p,[$release_file_fspecin, $release_version, $release_date, "revised $inventory_version"];
        print "Changed: $work_file,    $release_version $release_date\n" if $self->{options}->{verbose};
        $self->{file_changed} = 1;

        #######
        # Update the $VERSION and $DATE variables.
        #
        if($auto_revise) {
            $work_contents =~ s/\$VERSION\s*=\s*['"]*\d+\.\d+\s*['"]*/\$VERSION = '$release_version'/;
            $work_contents =~ s/VERSION\s*:\s*(.*)\s*\^/VERSION\:$release_version^ /;
            $work_contents =~ s/\$DATE\s*=\s*['"].*?['"]/\$DATE = '$release_date'/;
            $work_contents =~ s/DATE\s*:\s*(.*)\s*\^/DATE\:$release_date^ /;
            $changed = 1;
        }
    }
    else {
 
        ########
        # Have a new file
        # 
        $work_version = $inventory_version unless $work_version;
        $work_contents =~ s/\$DATE\s*=\s*['"].*?['"]/\$DATE = '$release_date'/;
        push @$inventory_p, [$release_file_fspecin, $work_version,  $release_date, 'new'];
        print "New    : $work_file,    $work_version $release_date\n" if $self->{options}->{verbose};

    }
    push @$manifest_p, $release_file_fspecin;

    ######
    # Make sure the path exists for the release file
    #
    my ($vol, $dir, undef) = File::Spec->splitpath( $release_file );
    $dir = File::Spec->catdir( $vol, $dir ) if( $vol && $dir );
    mkpath( $dir ) if $dir;

    #######
    # Copy the work file to the release file
    #
    return undef unless open( RELEASE, "> $release_file" );
    binmode RELEASE;
    print RELEASE $work_contents;
    close RELEASE;

    #######
    # If freezing the release, update the work file with any new date and version
    #
    my $freeze = $formDB->{FREEZE};
    $freeze = 0 unless $freeze;
    if( $freeze eq 'YES' || $freeze eq 'yes' || $freeze eq '1') {

        ######
        # Pick up the new version and date in the work copy
        #
        return undef unless open( WORK, "> $work_file" );
        binmode WORK;
        print WORK $work_contents;
        close WORK;
    }

    return 1;
}





#####
#
#
sub clear
{
   my ($self) = @_;
   $self->{clear} = 0;

   1
}





####
# Clear all target flags
#
sub clear_all
{
    my ($self ) = (@_);
    if( ref($self->{FormDB}) eq 'ARRAY') {

        ###### 
        # Unescape any POD directives
        #
        for( my $i=1; $i < @{$self->{FormDB}}; $i += 2) {
            ${$self->{FormDB}}[$i] =~ s/\n\\=/\n=/g;   
        }

        my %form_db = @{$self->{FormDB}};
        $self->{FormDB} = \%form_db;
        $self->{FormDB}->{FormDB_File} = $self->{FormDB_File};
        $self->{FormDB}->{FormDB_PM} = $self->{FormDB_PM};

    } 
    return 1 if $self->{clear};
    $self->{clear} = 1;
    $self->{check_svd_db} = 0;
    $self->{restore_previous} = 0;
    $self->{auto_revise} = 0;
    $self->{write_svd_pm} = 0;
    $self->{readme_html} = 0;
    $self->{makemake} = 0;
    $self->{test} = 0;

    1
}


######
#
#
sub check_svd_db
{
    my ($self) = @_;
    return 1 if $self->{check_svd_db};
    $self->{check_svd_db} = 1;
 
    my $passed_check = 1;

    my $formDB = $self->{FormDB};

    ######
    # Alias PREVIOUS_RELEASE and PREVIOUS_VERSION
    #
    $formDB->{PREVIOUS_RELEASE} = $formDB->{PREVIOUS_VERSION} if $formDB->{PREVIOUS_VERSION};

    my @required = qw(
       DISTNAME VERSION REVISION AUTHOR
       ABSTRACT TITLE END_USER REPOSITORY
       DOCUMENT_OVERVIEW CAPABILITIES AUTO_REVISE
       INSTALLATION SUPPORT
    );

    foreach my $required (@required) {
         unless ($formDB->{$required}) {
              warn "Required SVD DB field, $required, missing.\n";
              $passed_check = undef;
         }
    }

    my @default = (
        CHANGE2CURRENT => '',
        CLASSIFICATION => 'None',
        COPYRIGHT => 'Public Domain',
        COMPRESS => 'gzip',
        COMPRESS_SUFFIX => 'gz',        
        CSS => 'help.css',
        END_USER => 'General Public',
        EXE_FILES => '',
        FREEZE => 0,
        HTML => '', 
        LICENSE => 'These files are public domain.',
        NOTES => 'None.',
        PREREQ_PM => '',
        PROBLEMS => 'There are no known open issues.',
        REPLACE => '',
        REPOSITORY_DIR => 'packages',
        RESTRUCTURE => '',
        SEE_ALSO => '',
        SVD_FSPEC => 'Unix',
        TEMPLATE => '',
    );
    my %default = @default;
   
    foreach my $key (keys %default) {
         $formDB->{$key} = $default{$key} unless $formDB->{$key};
    }


    #########
    # Rule: previous version must be less than the current version
    #
    unless( $formDB->{PREVIOUS_DISTNAME} ) {
        if( $formDB->{PREVIOUS_RELEASE} && !$formDB->{PREVIOUS_DISTNAME} ) {
            unless($formDB->{PREVIOUS_RELEASE} < $formDB->{VERSION}) {
                warn " Previous version, $formDB->{PREVIOUS_RELEASE}, must be less than current version, $formDB->{VERSION}\n"; 
                $passed_check = undef;
            }
        }

        #######
        # There is no previous version so make a best guess
        #
        else {

            if( $formDB->{VERSION} eq '0.01' ) {
                $formDB->{PREVIOUS_RELEASE} = '';
            }
            else {
                $formDB->{PREVIOUS_RELEASE} = $formDB->{VERSION} - 0.01;
                warn( "Guessing previous release is $formDB->{PREVIOUS_RELEASE}\n" );
            } 
        }
    }

    #########
    # Clean-up data fields
    #
    foreach my $field qw(PREVIOUS_RELEASE) {

        if($formDB->{$field} ) {

            #####
            # Drop leading and trailing white space
            #
            ($formDB->{$field}) = $formDB->{$field} =~ /^\s*(.*?)\s*$/s;
        }
        else {
            $formDB->{$field} = ''; 
        }
    }

    ##############
    # Create derived fields
    #
    $formDB->{DATE} = get_date();

    $formDB->{NAME} = $formDB->{DISTNAME};
    $formDB->{NAME} =~ s/\-/::/;

    $formDB->{SVD_FSPEC} = 'Unix' unless $formDB->{SVD_FSPEC};


    #########
    # Change to the directory containing the svd_file, 
    # remembering the current working directory in order
    # to restore it after processing
    #
    my $svd_file = $self->{FormDB_File};
    my ($svd_vol, $svd_dir) = File::Spec->splitpath( $svd_file );
    chdir $svd_vol if $svd_vol;
    chdir $svd_dir if $svd_dir;
    $formDB->{SVD_DIR} = cwd();

    ########
    # Determine the top directory.
    #
    my @top_dir = File::Spec->splitdir( $svd_dir );
    while( @top_dir && $top_dir[-1] !~ /lib/) { 
        pop @top_dir;
        chdir File::Spec->updir(); 
    };
    pop @top_dir;
    $formDB->{TOP_DIR} = cwd();

    ######
    # BSD glob the AUTO_REVISE list
    #
    my @auto_revise =  File::AnySpec->fspec_glob($formDB->{SVD_FSPEC}, split "\n", $formDB ->{AUTO_REVISE} );
    my %auto_revise;
    my $from_file;
    foreach my $file (@auto_revise) {
        if( $file =~ /(.*?)\s*=>\s*(.*)/ ) {
            ($from_file,$file) = ($1,$2);
        }
        else {
            $from_file = $file; 
        }
        $auto_revise{$file} = $from_file;   
        $file = [$from_file,$file];
    }
    $formDB->{AUTO_REVISE_LIST} = \@auto_revise;
    $formDB->{AUTO_REVISE_HASH} = \%auto_revise;

    ######
    # BSD glob the REPLACE list
    #
    my @replace =  File::AnySpec->fspec_glob($formDB->{SVD_FSPEC}, split "\n", $formDB ->{REPLACE} );
    my %replace;
    foreach my $file (@replace) {
        if( $file =~ /(.*?)\s*=>\s*(.*)/ ) {
            ($from_file,$file) = ($1,$2);
        }
        else {
            $from_file = $file; 
        }
        $replace{$file} = $from_file;   
        $file = [$from_file,$file];
    }
    $formDB->{REPLACE_LIST} = \@replace;
    $formDB->{REPLACE_HASH} = \%replace;

    #######
    # BSD Glob test files
    #
    my @tests;
    if($formDB->{TESTS}) {
        @tests = File::AnySpec->fspec_glob($formDB->{SVD_FSPEC}, split "\n", $formDB->{TESTS} );
    }
    else {
        @tests = File::AnySpec->fspec_glob('Unix', ('t/*.t') );
    }

    #######
    # Rule: test script must be included in auto revise
    #
    foreach my $test (@tests) {
        unless( $auto_revise{$test} ) {
            warn( "Test, $test, not included in the distribution\n");
            $passed_check = undef;
        }
    }

    ######
    # Change the test file spec to that of the SVD
    #
    foreach my $test (@tests) {
        $test = File::AnySpec->os2fspec( $formDB->{SVD_FSPEC}, $test );
    }
    $formDB->{TEST_INVENTORY} = ' ' . join "\n ", @tests;
    $formDB->{TEST_LIST} = \@tests;

    #######
    # BSD Glob exe files
    #
    my @exe;
    if($formDB->{EXE_FILES}) {
        @exe = File::AnySpec->fspec_glob($formDB->{SVD_FSPEC}, split "\n", $formDB->{EXE_FILES} );
    }
    else {
        @exe = ();
    }
    foreach my $exe (@exe) {
        $exe = File::AnySpec->os2fspec( $formDB->{SVD_FSPEC}, $exe );
    }
    $formDB->{EXE_LIST} = \@exe;


    ######
    # Determine the SVD file relative to the top directory
    #
    $svd_dir = File::Spec->abs2rel($formDB->{SVD_DIR}, $formDB->{TOP_DIR});
    (undef,$svd_dir) = File::Spec->splitpath($svd_dir,'nofile');
    (undef,undef,$svd_file) = File::Spec->splitpath( $svd_file);
    $formDB->{PM_File_Relative} = File::Spec->catfile($svd_dir, $svd_file); # relative to TOP_DIR

    ###########
    # Determine repository directory which is relative to the top dir
    #
    my $repository_dir = File::AnySpec->fspec2os($formDB->{SVD_FSPEC}, $formDB->{REPOSITORY_DIR}, 'nofile');
    mkpath( $repository_dir);
    chdir $repository_dir;
    $formDB->{REPOSITORY_DIR} = cwd();

    $passed_check

}


######
# 
# Default SVD template
#
sub default_template
{
    << 'EOF';

\=head1 NAME

${TITLE}

\=head1 Title Page

 Software Version Description

 for

 ${TITLE}

 Revision: ${REVISION}

 Version: ${VERSION}

 Date: ${DATE}

 Prepared for: ${END_USER} 

 Prepared by:  ${AUTHOR}

 Copyright: ${COPYRIGHT}

 Classification: ${CLASSIFICATION}

\=head1 1.0 SCOPE

This paragraph identifies and provides an overview
of the released files.

\=head2 1.1 Identification

This release,
identified in L<3.2|/3.2 Inventory of software contents>,
is a collection of Perl modules that
extend the capabilities of the Perl language.

\=head2 1.2 System overview

${CAPABILITIES}

\=head2 1.3 Document overview.

${DOCUMENT_OVERVIEW}

\=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the ${SVD_FSPEC} operating
system file specification.

\=head2 3.1 Inventory of materials released.

This document releases the file 

 ${DIST_FILE}

found at the following repository(s):

${REPOSITORY}

Restrictions regarding duplication and license provisions
are as follows:

\=over 4

\=item Copyright.

${COPYRIGHT}

\=item Copyright holder contact.

 ${SUPPORT}

\=item License.

${LICENSE}

\=back

\=head2 3.2 Inventory of software contents

The content of the released, compressed, archieve file,
consists of the following files:

${DIST_INVENTORY}

\=head2 3.3 Changes

${RESTRUCTURE_CHANGES}${CHANGES}

\=head2 3.4 Adaptation data.

This installation requires that the installation site
has the Perl programming language installed.
There are no other additional requirements or tailoring needed of 
configurations files, adaptation data or other software needed for this
installation particular to any installation site.

\=head2 3.5 Related documents.

There are no related documents needed for the installation and
test of this release.

\=head2 3.6 Installation instructions.

Instructions for installation, installation tests
and installation support are as follows:

\=over 4

\=item Installation Instructions.

${INSTALLATION}

\=item Prerequistes.

${PREREQ_PM_TEXT}

\=item Security, privacy, or safety precautions.

None.

\=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

${TEST_INVENTORY}

\=item Installation support.

If there are installation problems or questions with the installation
contact

 ${SUPPORT}

\=back

\=head2 3.7 Possible problems and known errors

${PROBLEMS}

\=head1 4.0 NOTES

${NOTES}

\=head1 2.0 SEE ALSO

${SEE_ALSO}

\=for html
${HTML}

\=cut

EOF

}


######
# Date with year first
#
sub get_date
{
   my @d = localtime();
   @d = @d[5,4,3];
   $d[0] += 1900;
   $d[1] += 1;
   sprintf( "%04d/%02d/%02d", @d[0,1,2]);

}


######
#
#
sub makemake
{
    my($self, $svd_file) = @_;
    return 1 if $self->{makemake};
    $self->{makemake} = 1;

    my $formDB = $self->{FormDB};

    my $cwd = cwd();
    my $release_dir = $formDB->{RELEASE_DIR};
    chdir $release_dir;
    if ($self->{options}->{verbose}) {
        print "~~~~\nGenerating makemake files:\n";
        print "Current directory: $cwd\n";
        print "Release directory: $release_dir\n";
    }

    ########
    # Generate the manifest file
    #
    ########
    my $manifest_file = File::Spec->catfile($release_dir, 'MANIFEST');
    my $manifest_h;
    print  "Generating $manifest_file\n" if $self->{options}->{verbose};
    unless (open( $manifest_h, "> $manifest_file" )) {
        warn "Cannot open $manifest_file";
        return undef;
    }
    print $manifest_h join "\n", @{$formDB->{MANIFEST}};
    close $manifest_h;
    undef $manifest_h;  # problems with ActivePerl redirecting outputs

    #######
    # Generate README
    #
    ######
    print "Generating README\n" if $self->{options}->{verbose};
    my $pod2text = new Pod::Text;
    my ($in_fh,  $out_fh);
    my $readme_file = File::Spec->catfile($release_dir, 'README');
    unless( open($out_fh, "> $readme_file") ) {
        warn "Cannot open $readme_file\n\t$!";
        return undef;
    }
    if($formDB->{README_PODS}) {
        my @readme_pods = split /[\n ,]/, $formDB->{README_PODS};
        foreach (@readme_pods) {
            unless( open($in_fh, "< $_" ) ) {
                warn "Cannot open $_\n\t$!";
                return undef;
            }
            $pod2text->parse_from_filehandle($in_fh, $out_fh);
            close $in_fh;
        }
    }
    unless( open($in_fh, "< $formDB->{PM_File_Relative}" ) ) {
        warn "Cannot open $formDB->{PM_File_Relative}\n\t$!";
        return undef;
    }
    $pod2text->parse_from_filehandle($in_fh, $out_fh);
    close $in_fh;
    close $out_fh;
   
    ######
    # Create the Makefile.PL file
    #
    my $makemaker_file = File::Spec->catfile($release_dir, 'Makefile.PL');
    print "Generating $makemaker_file\n" if $self->{options}->{verbose};
    my $makefile_h;
    unless (open( $makefile_h, "> $makemaker_file" )) {
        warn "Cannot open $makemaker_file";
        return undef;
    }


    my $tests = '\'' . join ('\',\'', @{$formDB->{TEST_LIST}}) . '\'';
 
    my $exe_text = '';
    my $exe_com_text = '';
    if( @{$formDB->{EXE_LIST}} ) {
        my $exe = '\'' . join ('\',\'', @{$formDB->{EXE_LIST}}) . '\'';
        $exe_text = "my \@exe = unix2os($exe);";
        $exe_com_text = 'EXE_FILES => \@exe,'
    }
    
    my $prereq_pm = '';
    if($formDB->{PREREQ_PM}) {
        $prereq_pm = $formDB->{PREREQ_PM};
        while( chomp $prereq_pm ) {};
        $prereq_pm =~ s/\n/\n                  /g;
        $prereq_pm = "PREREQ_PM => {$prereq_pm},";
    }

    print $makefile_h <<"EOF";

####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# $formDB->{FormDB_PM} 
#
# Don't edit this file, edit instead
#
# $formDB->{FormDB_PM}
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my \$tests = join ' ',unix2os($tests);
$exe_text

WriteMakefile(
    NAME => '$formDB->{NAME}',
    DISTNAME => '$formDB->{DISTNAME}',
    VERSION  => '$formDB->{VERSION}',
    dist     => {COMPRESS => '$formDB->{COMPRESS}',
                '$formDB->{COMPRESS_SUFFIX}' => 'gz'},
    test     => {TESTS => \$tests},
    $prereq_pm
    $exe_com_text

    (\$] >= 5.005 ?     
        (AUTHOR    => '$formDB->{AUTHOR}',
        ABSTRACT  => '$formDB->{ABSTRACT}', ) : ()),
);


EOF


     my $subs = <<'EOF';

use File::Spec;
use File::Spec::Unix;
sub unix2os
{
   my @file = ();
   foreach my $file (@_) {
       my (undef, $dir, $file_unix) = File::Spec::Unix->splitpath( $file );
       my @dir = File::Spec::Unix->splitdir( $dir );
       push @file, File::Spec->catfile( @dir, $file_unix);
   }
   @file;
}

EOF

     $subs =~ s/Unix/$formDB->{SVD_FSPEC}/g;
     print $makefile_h $subs;

     close $makefile_h;
     undef $makefile_h;  # problems with ActivePerl redirecting outputs


     1

}




######
# Create the ppd file
#
sub ppd_version
{
     my(undef, $version) = @_;
     my @version = split /\./, $version; 
     while( @version < 4 ) {
        push @version, 0;
     }
     $version = join ',', @version;
     $version
}


sub ppd_html
{
     my(undef, $text) = @_;
     $text =~ s/>/&gt;/g;
     $text =~ s/</&lt;/g;
     $text
}


sub ppd
{
     my ($self) = @_;

     my $formDB = $self->{FormDB};
     chdir $formDB->{REPOSITORY_DIR};

     my $data = $formDB->{DISTNAME} . '.ppd';
     unless( open(PPD, "> $data") ) {
         warn "Cannot open $data\n";
        return undef;
     }

     $data = $self->ppd_version( $formDB->{VERSION} );
     print PPD qq{<SOFTPKG NAME=\"$formDB->{DISTNAME}\" VERSION=\"$data\">\n};
     print PPD qq{\t<TITLE>$formDB->{DISTNAME}</TITLE>\n};

     $data = $self->ppd_html($formDB->{ABSTRACT});
     print PPD qq{\t<ABSTRACT>$data</ABSTRACT>\n};
 
     $data = $self->ppd_html($formDB->{AUTHOR});
     print PPD qq{\t<AUTHOR>$data</AUTHOR>\n};

     print PPD qq{\t<IMPLEMENTATION>\n};

     my @prereq_pm = split /\n/, $formDB->{PREREQ_PM};
     my ($module, $version);
     foreach my $prereq_pm (@prereq_pm) {
         if( $prereq_pm =~ /\s*['"]*(.*?)['"]*\s*=>\s*['"]*(\d+\.*\d*)/ ) {
             ($module,$version) = ($1,$2);
             $version = $self->ppd_version($version);
         }
         else {
             $module = $prereq_pm;
             $version = '0,0,0,0';
         }
         print PPD qq{\t\t<DEPENDENCY NAME=\"$module\" VERSION=\"$version\" />\n};
     }
 
     print PPD qq{\t\t<OS NAME=\"$Config{osname}\" />\n};
     print PPD qq{\t\t<ARCHITECTURE NAME=\"$Config{archname}-$Config{PERL_API_REVISION}.$Config{PERL_API_VERSION}\" />\n};

     $data = "$formDB->{DISTNAME}-$formDB->{VERSION}";
     $data .=  ".tar.$formDB->{COMPRESS_SUFFIX}";
     print PPD qq{\t\t<CODEBASE HREF=\"$data\" />\n};

     print PPD qq{\t</IMPLEMENTATION>\n};
     print PPD qq{</SOFTPKG>\n};

     close PPD;

     1
}




######
#
#
sub readme_html
{
    my ($self) = (@_);
    return 1 if $self->{readme_html};
    $self->{readme_html} = 1;
    my $formDB = $self->{FormDB};

    #######
    # Generate HTML in the repository directory
    #
    #######
    my $html_file .= $formDB->{DISTNAME} . '-' . $formDB->{VERSION} . '.html';
    $html_file = File::Spec->catfile( $formDB->{REPOSITORY_DIR}, $html_file);
    my $css = File::AnySpec->fspec2fspec($formDB->{SVD_FSPEC}, 'Unix', $formDB->{CSS});
    $css = 'help.css' unless $css;
    my $podpath = join ';',@INC;
    print "Generating $html_file\n" if $self->{options}->{verbose};
    pod2html($self->{FormDB_File},
            "--podpath=$podpath",
            "--podroot=$formDB->{TOP_DIR}",
            "--backlink='Back to Top'",
            "--htmlroot=.",
            "--header",
            "--css=$css",
            "--recurse",
            "--title=Software Version Description for $formDB->{TITLE}",
            "--outfile=$html_file");
    unlink "pod2htmd.x~~";
    unlink "pod2htmi.x~~";

}





######
#
#
sub restore_previous
{
    my ($self) = @_;
    return 1 if $self->{restore_previous};
    $self->{restore_previous} = 1;

    my $formDB = $self->{FormDB};

    ###### 
    # Auto revise the files
    #
    my $previous_release = $formDB->{PREVIOUS_RELEASE};
    my $release_dir;
    chdir $formDB->{REPOSITORY_DIR};
    if( $previous_release ) {

        $formDB->{PREVIOUS_DISTNAME} = $formDB->{DISTNAME}  unless $formDB->{PREVIOUS_DISTNAME}; 
        my $previous_release_dir = "$formDB->{PREVIOUS_DISTNAME}-$previous_release";
        rmtree $previous_release_dir;

        ######
        # Extract files from tape archive
        #
        return undef unless Archive::TarGzip->untar( {dest_dir => $formDB->{REPOSITORY_DIR},
              tar_file => "$formDB->{PREVIOUS_DISTNAME}-$formDB->{PREVIOUS_RELEASE}.tar.$formDB->{COMPRESS_SUFFIX}",
              compress => 1} );

        #######
        # Get a list of the previsous release inventory
        # In order to load it in memory, it must be under one of the library
        # directories in @INC
        #
        my $svd_base_file = $formDB->{PREVIOUS_DISTNAME};
        $svd_base_file =~ s/-/_/g;
        my $svd_file = File::Spec->catfile($previous_release_dir, 'lib', 'Docs', 'Site_SVD', $svd_base_file . '.pm' );

        #######
        # Look at older pass location
        #
        unless( -e $svd_file) {
            $svd_file = File::Spec->catfile($previous_release_dir, 'lib', 'SVD', 'Site', $svd_base_file . '.pm' );
        }
        unless( -e $svd_file) {
            $svd_file = File::Spec->catfile($previous_release_dir, 'lib', 'SVD', $svd_base_file . '.pm' );
        }
        unless( -e $svd_file) {
            $svd_file = File::Spec->catfile($previous_release_dir, 'lib', $svd_base_file . '.pm' );
        }

        unless (open FH, "< $svd_file") {
             warn "Cannot open $svd_file\n";
             return undef;
        }

        my $contents = join '', <FH>;
        close FH;
        my ($inventory) = $contents =~ /%INVENTORY\s*=\s*\((.*?)\);/s;
        my %inventory = ();
        eval "%inventory = ($inventory)" if $inventory;
        $formDB->{PREVIOUS_INVENTORY} = (keys %inventory) ? \%inventory : {};

        #########
        # If there is a name change, move the previous to the new
        #
        if( $formDB->{DISTNAME} ne  $formDB->{PREVIOUS_DISTNAME} ) {
            my $from_dir = File::Spec->catdir(cwd(),$previous_release_dir);
            chdir $formDB->{REPOSITORY_DIR};
            $release_dir = "$formDB->{DISTNAME}-$formDB->{VERSION}";
            rmtree $release_dir;
            mkpath $release_dir;
            chdir $release_dir;
            my ($previous_file, $file);
            my %inventory = ();
            my %previous_inventory = %{$formDB->{PREVIOUS_INVENTORY}};
            foreach $previous_file (keys %previous_inventory ) {

                ########
                # Change previous file name to current file name
                # 
                $file = $previous_file;
                if( $formDB->{CHANGE2CURRENT} ) {
                    eval $formDB->{CHANGE2CURRENT};
                    if($@) {
                         warn "Cannot change work file, $file, to current name\n\t$@\n";
                    }
                }

                #######
                # Copy previous inventory info to new inventory
                #
                $inventory{$file} = $previous_inventory{$previous_file};

                ######
                # Copy file from old distribution to new distribution
                #
                $previous_file = File::AnySpec->fspec2os( $formDB->{SVD_FSPEC}, $previous_file );
                $previous_file = File::Spec->catfile( $from_dir, $previous_file );
                $file = File::AnySpec->fspec2os( $formDB->{SVD_FSPEC}, $file );
                (undef,my $dir,undef) = File::Spec->splitpath($file);
                mkpath $dir if $dir;
                copy $previous_file, $file;
        
            }
            $formDB->{PREVIOUS_INVENTORY} =\%inventory;

        }

        chdir $previous_release_dir;
        return undef unless $self->restructure( );

    }  

    else {
        $release_dir = "$formDB->{DISTNAME}-$formDB->{VERSION}";
        rmtree( $release_dir );
        my $dirs = mkpath( $release_dir );
        unless( 0 < $dirs ) {
            warn "Cannot mkpath $release_dir\n";
            return undef;
        }
        chdir $release_dir;
        $formDB->{PREVIOUS_INVENTORY} = {};
    }

    ######
    # Record the release directory.
    #
    $formDB->{RELEASE_DIR} = cwd();

    if($self->{options}->{verbose}) {
        print "~~~~\nDirectories after restore previous:\n";
        print "Top directory: $formDB->{TOP_DIR}\n";
        print "Repository release : $formDB->{REPOSITORY_DIR}\n"; 
        print "Release directory: $formDB->{RELEASE_DIR}\n";
    }

    1
}




######
# 
#  
sub restructure
{
    my ($self ) = (@_);

    #######
    # Evaluate the pre build program
    #
    my $restructure = $self->{FormDB}->{RESTRUCTURE};
    if( $restructure ) {
        print"~~~\nRestructing release:\n$restructure\n" if( $self->{options}->{verbose} ); 
        eval $restructure;
        if ($@) {
            warn "Restructure failed.\n\t$@";
            return undef;
        }
    }

    1
}




#######
# File Archive
#
sub tar
{
     my ($self) = @_;
     my $formDB = $self->{FormDB};

     my @files = @{$formDB->{MANIFEST}};
     foreach my $file (@files) {
         $file = File::AnySpec->fspec2os( 'Unix', $file );
     }

     my $dest_dir = "$formDB->{DISTNAME}-$formDB->{VERSION}";
     my $tar_file = File::Spec->catfile( $formDB->{REPOSITORY_DIR}, $dest_dir . '.tar' );
     my $dest_file = "$formDB->{DISTNAME}-$formDB->{VERSION}";
     Archive::TarGzip->tar( @files,
          {tar_file => $tar_file, 
           dest_dir => $dest_dir,
           src_dir => $formDB->{RELEASE_DIR},
           compress => 1},
           );

}




########
#
#
sub test
{
     my ($self) = @_;
     return 1 if $self->{test};
     $self->{test} = 1;

     my $formDB = $self->{FormDB};
     chdir $formDB->{RELEASE_DIR};
     my @tests = @{$formDB->{TEST_LIST}};
     $Test::Harness::verbose = 1;

     #####
     # Copy prequest modules to the require directory
     #
     my $require_dir = File::Spec->catdir($formDB->{RELEASE_DIR},'require');
     if($formDB->{PREREQ_PM}) {
         my %prereq_pm = eval $formDB->{PREREQ_PM};
         unless($@) {
             my ($prereq_file, $from_file, $to_file, $to_dirs);
             foreach (keys %prereq_pm) {
                 $prereq_file = File::Where->pm2require($_);
                 $from_file = File::Where->where_file($prereq_file);
                 $to_file = File::Spec->catfile('require',$prereq_file);
                 (undef,$to_dirs) = File::Spec->splitpath( $prereq_file );
                 mkpath(File::Spec->catdir('require', $to_dirs));
                 if($from_file && $to_file) {
                     copy($from_file, $to_file);
                 }
             }
         }
     }

     ##########
     # Drop all but the Perl core libs
     #
     my @inc = @INC;
     while( @INC && $INC[0] !~ 'Perl') { 
         shift @INC;
     };
     @INC = @inc unless @INC; 

     #####
     # Add prequet to program module search path
     #
     unshift @INC,$require_dir;
     unshift @INC,File::Spec->catdir($formDB->{RELEASE_DIR},'lib');;

     ########
     # Run under eval because runtests is loaded with dies
     # But the eval does not help since the @INC is messed up
     #
     my $success =  eval( 'runtests(\''. (join '\',\'',@tests) . '\')' );
     unless( $success && !$@) {
        warn( "Tests failed.\n\t$@" );
        return undef;
     }

     #####
     # Restore include
     #
     @INC = @inc;
     rmtree $require_dir;
     $success;

}



######
# Write out files
#
sub vmake
{
     my ($self, @targets) = @_;

     ########
     # Default FormDB program module is "SVD"
     #
     $self->{options}->{pm} = 'SVD' unless $self->{options}->{pm};

     $self->make_targets( \%expand_targets, @targets);
 
}




######
#
#
sub write_svd_pm
{

    my ($self) = (@_);
    return 1 if $self->{write_svd_pm};
    $self->{write_svd_pm} = 1;
    my $formDB = $self->{FormDB};

    ######
    # Generate the svd program module
    #
    my $svd_file = $self->{FormDB_File};
    unless( $svd_file ) {
        warn "No SVD pm file specified\n";
        return undef;
    }


    chdir $formDB->{TOP_DIR};

    if( $self->{options}->{verbose} ) {
        print "~~~\nGenerating Software Version Description POD\n"; 
        print "Current directory: $formDB->{TOP_DIR}\n";
    }


    ##########
    # Generate some template variables
    #
    my $restructure = $formDB->{RESTRUCTURE};
    my $restructure_formatted;
    if($restructure) {
       $restructure_formatted = << "EOF";
The file structure from release \${PREVIOUS_RELEASE} was restructured as follows:

EOF
        chomp $restructure;
        $restructure =~ s/\n/\n /;
        $restructure_formatted .= ' ' . $restructure . "\n\n";

    }
    else {
       $restructure_formatted = ''
    }
    $formDB->{RESTRUCTURE_CHANGES} = $restructure_formatted;


    ##########
    # Generate add the file name changes
    #
    $restructure = $formDB->{CHANGE2CURRENT};
    if($restructure) {
       $restructure_formatted = << "EOF";
The file names from \${PREVIOUS_RELEASE} were changed as follows:

EOF
        chomp $restructure;
        $restructure =~ s/\n/\n /;
        $restructure_formatted .= ' ' . $restructure . "\n\n";

    }
    else {
       $restructure_formatted = ''
    }
    $formDB->{RESTRUCTURE_CHANGES} .= $restructure_formatted;

    #####
    # Generate the inventory hash
    #
    my $inventory = $formDB->{inventory};
    shift @$inventory;
    shift @$inventory;
    my $inventory_hash=''; 
    my ($file, @file);
    foreach $file (@$inventory) {
       @file = @$file;
       $inventory_hash .= "    '$file[0]' => [qw($file[1] $file[2]), '$file[3]'],\n" 
    }
    $formDB->{INVENTORY_HASH} = $inventory_hash;

    $formDB->{BASE_DIST_FILE} = "$formDB->{DISTNAME}-$formDB->{VERSION}";
    $formDB->{BASE_DIST_FILE} =~ s/\n//g;
    $formDB->{DIST_FILE} = "$formDB->{BASE_DIST_FILE}.tar.$formDB->{COMPRESS_SUFFIX}"; 

    #######
    # Determine the PM_NAME
    # 
    $formDB->{PM_NAME} = $formDB->{DISTNAME};
    $formDB->{PM_NAME} =~ s/\-/_/;

    #########
    # Make a table out of this
    #
    my @prereq_pm;
    my $prereq_pm = ($formDB->{PREREQ_PM}) ? $formDB->{PREREQ_PM} : 'None.';
    if( $prereq_pm ) {
        eval( "@prereq_pm = $prereq_pm" );
        chomp $prereq_pm;
        $prereq_pm =~ s/\n/\n /g;
        $prereq_pm = ' ' . $prereq_pm . "\n";
    }
    else {
        $prereq_pm = '';
    }
    $formDB->{PREREQ_PM_TEXT} = $prereq_pm;

    #######
    # Drop leading and trailing white space
    #
    foreach my $field qw(SEE_ALSO) {
        $formDB->{$field} =~ s/^\s*(.*)\s*$/$1/;
    }

    #########
    # Get the SVD template, the template is data of __DATA__ in a program module
    #
    my $template = '';
    if($formDB->{TEMPLATE}) {
        my $error = File::Package->load_package( $formDB->{TEMPLATE} );
        no strict;
        my $data_handle = \*{"$formDB->{TEMPLATE}" . '::DATA'};
        use strict;
        my $position = tell($data_handle);
        $template = join '',<$data_handle>;
        seek($data_handle,0,0);
    }

    ######
    # 
    # Get the default template
    # 
    $template = default_template() unless $template;

    #######
    # Generate the file header
    #
    my $header = << 'EOF';
#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  ${FormDB_PM};

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '${VERSION}';
$DATE = '${DATE}';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
${INVENTORY_HASH}
);

########
# The ExtUtils::SVDmaker module uses the data after the __DATA__ 
# token to automatically generate this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time ExtUtils::SVDmaker generates this file.
#
#


EOF

    ########
    # Replace template macros variables
    # 
    $template = $header . $template;
    Text::Replace->replace_variables(\$template, $formDB);
    $template =~ s/\n\\=/\n=/g; # unescape POD directives
    $template .= "1;\n\n__DATA__$self->{FormDB_Record}\n\n";

    ########
    # Print out the SVD file
    #
    my (undef, $svd_file_dirs, undef) = File::Spec->splitpath( $svd_file);
    mkpath( $svd_file_dirs) if $svd_file_dirs;
    unless ( open( SVD, "> $svd_file") ) {
        warn "Cannot open $svd_file\n";
        return undef;      
    }
    print SVD $template;
    close SVD;

    ##########
    # Copy the newly revised PM file to the distribution
    #
    my $svd_file_relative = $formDB->{PM_File_Relative};
    my $release_file = File::Spec->catfile( $formDB->{RELEASE_DIR}, $svd_file_relative);

    ######
    # Make sure the path exists for the release file
    #
    my ($vol, $dir, undef) = File::Spec->splitpath( $release_file );
    $dir = File::Spec->catdir( $vol, $dir ) if( $vol && $dir );
    mkpath( $dir ) if $dir;
    copy $svd_file, $release_file;

    1

}



1

__END__


=head1 NAME

ExtUtils::SVDmaker - Create CPAN distributions

=head1 SYNOPSIS

 use ExtUtils::SVDmaker;

 $svd = new ExtUtils::SVDmaker( @options );
 $svd = new ExtUtils::SVDmaker( \%options );

 $svd->vmake( @targets, \%options ); 
 $svd->vmake( @targets ); 
 $svd->vmake( \%options  ); 

=head1 DESCRIPTION

The "ExtUtils::SVDmaker" 
program module extends the Perl language (Perl is the system).

The input to "ExtUtils::SVDmaker" is the __DATA__
section of Software Version Description (SVD)
program module.
The __DATA__ section must contain SVD
forms text database in the
L<DataPort::FileType::DataDB|DataPort::FileType::DataDB> format.

Use the "vmake.pl" (SVD make) cover script for 
L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> to process a SVD database
module as follows:

  vmake -pm=Docs::Site_SVD::MySVDmodule

The preferred location for SVD program modules is

 Docs::Site_SVD::

The "ExtUtils::SVDmaker" module extends
the automation of releasing a Perl distribution file as
follows:

=over

=item *

The input data for the "ExtUtils::SVDmaker" module
is a form database as the __DATA__ section of a SVD program module.
The database is in the format of 
L<DataPort::FileType::FormDB|DataPort::FileType::FormDB>.
This is an efficient text database that is very close in
format to hard copy forms and may be edited by text editors

=item *

The "ExtUtils::SVDmaker" module compares the contents of the current release with the previous
release and automatically updates the version and date for files that
have changed

=item *

"ExtUtils::SVDmaker" module generates a SVD program module POD from the form database data contained
in the __DATA__ section of the SVD program module.

=item *

"ExtUtils::SVDmaker" modulegenerates MANIFEST, README and Makefile.PL distribution
files from the form database data

=item *

"ExtUtils::SVDmaker" module builds the distribution *.tar.gz file using
Perl code instead of starting tar and gzip process via a makefile build
by MakeFile.PL. This greatly increases portability and performance.

=item *

Runs the installation tests on the distribution files using the
"Test::Harness" module directly. It does not build any makefile 
using the MakeFile.PL and starting a Test::Harness process via
the makefile. This greatly increases portability and performance.

=back

The C<ExtUtils::SVDmaker> module is one of the
end user, functional interface modules for the US DOD STD2167A bundle.

The top level modules that establish the functional interface of
interest to the end user are the "Test::STDmaker" and "ExtUtils::SVDmaker"
modules.
The rest of the modules are design
modules for the US DOD STD2167A bundle. 
They are broken out as separate modules because they may
have uses outside of the US DOD STD2167A bundle.

The L<Test::STDmaker|Test::STDmaker> module has a number of design modules not
shown in the above dependency tree. 
See L<Test::STDmaker|Test::STDmaker> for more detail.

=head2 SVD Program Module Format

The input(s) for the C<fgenerate> method
are Softare Version Description (SVD) Program Modules (PM).

A SVD PM consists of three sections as follows:

=over 4

=item Perl Code Section

The code section contains the following
Perl scalars: $VERSION, $DATE, and $FILE.
The "ExtUtils::STDmaker" automatically generates this section.

=item SVD POD Section (DOD Tailoring)

The Software Version Description (SVD)
Plain Old Documentation (POD) section is in a slightly tailored 
United States (US) Department of Defense (DOD)
L<SVD Data Item Description (DID)|Docs::US_DOD::SVD> format.

The tailoring is that
paragraph 2 of the SVD DID is renamed from "REFERENCE DOCUMENTS" to 
"SEE ALSO" and moved to the end.
The content of paragraph, 1.2 System Overview, is changed
to include a brief statement of the software features and
capabilities.
The system is always the same, the Perl language. 
This makes better use of this space.

The "ExtUtils::SVDmaker" module
automatically generates this section.

=item SVD Form Database Section

This section contains a SVD Form Database that
the "ExtUtils::SVDmaker" module uses to generate the
Perl code section and the SVD POD section.

=back

=head2 Assumed Directory Structure

The directory structure assumed by the "ExtUtils::SVDmaker" 
module is as follows:

 $TOP_DIR -+- lib -- * -- $svd.pm
           |
           +- bin
           |
           +- $REPOSITORY_DIR -+- $DISTNAME-$PREVIOUS_VERSION -+- lib
                               |                               +- bin
                               |                               +- Makefile.PL
                               |                               +- README
                               |                               +- MANIFEST
                               |
                               +- $DISTNAME-$VERSION.tar.gz
                                  $DISTNAME-$VERSION.ppd
                                  $DISTNAME-$VERSION.html

 $RELEASE_DIR = File::Spec-catdir($TOPDIR, $REPOSITORY_DIR, $DISTNAME-$PREVIOUS_VERSION)

When the $PREVIOUS_DISTNAME is different than the $DISTNAME, the
directory structure is as follows:

 $TOP_DIR -+- lib -- * -- $svd.pm
           |
           +- bin
           |
           +- $REPOSITORY_DIR -+- $PREVIOUS_DISTNAME-$PREVIOUS_VERSION -+- lib
                               |                                        +- bin
                               |                                        +- Makefile.PL
                               |                                        +- README
                               |                                        +- MANIFEST
                               |
                               +- $DISTNAME-$VERSION -+- lib
                               |                      +- bin
                               |                      +- Makefile.PL
                               |                      +- README
                               |                      +- MANIFEST
                               |
                               +- $DISTNAME-$VERSION.tar.gz
                                  $DISTNAME-$VERSION.ppd
                                  $DISTNAME-$VERSION.html

 $RELEASE_DIR = File::Spec->catdir($TOPDIR, $REPOSITORY_DIR, $DISTNAME-$VERSION)


=head2 SVD Form Database Fields

The "ExtUtils::SVDmaker" module uses the
L<DataPort::FileType::FormDB|DataPort::FileType::FormDB>
lenient format to access the data.

This is a very compact database form. 
The fields are a merge of the data required by
the United States (US) Department of Defense (DOD)
L<SVD Data Item Description (DID)|DOCS::US_DOD::SVD>
and the L<ExtUtils::MakeMaker|ExtUtils::MakeMaker> module.

The following are the database file fields:

=over 4

=item ABSTRACT field

This field should be a one line description of the module. 
It Will be included in PPD file.

=item AUTHOR field

This field should contain 
the name (and email address) of package author(s). 
It is used in PPD (Perl Package Description) files for PPM (Perl Package Manager)
and as the "prepared by" entry in the title page of the generated SVD module POD
section.

=item AUTO_REVISE field

This is the list of files
(excluding the generated files 
MANIFEST, Makefile.pl, README and the $SVD.pm)
($SVD is the program module name supplied with the -pm option
which is usually Docs::Site_SVD::$DISTNAME_$VERSION,
L<DISTNAME field|/DISTNAME field> L<VERSION field|/DISTNAME field>), 
that the ExtUtils::SVDmaker module will copy from
the $TOP_DIR to the $RELEASE_DIR
(See L<Assumed Directory Structure|/Assumed Directory Structure>)
and automatically update the $VERSION and $DATE variables in
the $RELEASE_DIR file.

The file specification may contain BSD globbing
metacharaters such as the '*'.

An example of a AUTO_REVISE field is

 lib/Test/STD/STDgen.pm
 t/Test/STDmaker/*
 lib/Test/Tech.pm => tlib/Test/Tech.pm

The ExtUtils::SVDmaker assumes the files in the AUTO_REVISE field are
be relative to the $TOP_DIR.

Another features of the AUTO_REVISE field is that 
the files in the $RELEASE_DIR can be rename with
a line such as the following:
  
  top_dir_relative_file  => release_dir_relative_file

This is useful in arranging the test software in libraries
in the distribution.
The best place for a test library is the under the
test script itself.

=item CAPABILITIES field

This field shall briefly state
the purpose the software, its features and
capabilities.

=item CHANGE2CURRENT field

This field is normally left blank. 
This field only comes into play when the previous and current
distribution names are different.
In this case the "ExtUtils::SVDmaker" module,
after it has restored the previous release directory,
will copy each file from the previous release directory 
to the current release directory.

Before the copy,
the "ExtUtils::SVDmaker" module evals for each restored file, 
the "CHANGE2CURRENT" field.
The file name for the current release is contained in the variable $file.
Thus, the Perl statements in the 
"CHANGE2CURRENT" field should be use to change the names of files from a previous
release with different files names for the current release.

For example, to moved the top level from "lib/SVD" to
"lib/ExtUtils", use the following:

  return if $file =~ s=lib/SVD/SVDmaker.pm=lib/ExtUtils/SVDmaker.pm=;^

=item CHANGES field

This field should contain a list
of all changes incorporated into the software version since the
previous version.
It may include a brief history of changes to other versions.

This field should identify, as applicable, 
the problem reports, change proposals, and change
notices associated with each change and the effects, if any, of
each change on system operation and on interfaces with other hardware
and software.

=item CLASSIFICATION field

This field should include security other restrictions 
on the handling of the software.

=item COMPRESS field

This field is the program for compression. Normally this will be "gzip".

=item COMPRESS_SUFFIX field

This field is the default suffix for compressed files.
Normally this is '.gz'.

=item CSS field

The Casscading Style Sheet (css) file for the readme html. 
Normally this is "help.css".

=item DISTNAME field

This is the name for distributing the package (by tar file).
For library modules, this should be the package name
with the '::' characters replaced with the '-' character.

=item DOCUMENT_OVERVIEW field

This field should summarize the
purpose and contents of this document and shall describe any security
or privacy considerations associated with its use.

=item END_USER field

This field is the "prepare for" entry in the title page of 
the generated SVD module POD section.

=item FREEZE field

Normally this field will be set to 0 in order
to make dry-runs of the distribution.
When set to 0, the version of the master library
will not be changed.
Set this field to 1 for the finalized distribution.
The version number for any master library module
that changed since the last distribution will
be updated.

=item HTML field

This field is for HTML code at the end of
the SVD POD section.
For example,

 <hr>
 <p><br>
 <!-- BLK ID="NOTICE" -->
 <!-- /BLK -->
 <p><br>
 <!-- BLK ID="OPT-IN" -->
 <!-- /BLK -->
 <p><br>
 <!-- BLK ID="LOG_CGI" -->
 <!-- /BLK -->

=item INSTALLATION field

This field should include the following information:

=over 4

=item *

Instructions for installing the software version.

=item *

Identification of other changes that have
to be installed for this version to be used, including site-unique
adaptation data not included in the software version

=item *

Security, privacy, or safety precautions relevant
to the installation

=back

=item LICENSE field

This field should contain any
restrictions regarding duplication and license provisions.
Any copyright notice should also be included in this
field.

=item NOTES field

This field should contain any general
information that aids in understanding this document (e.g., background
information, glossary, rationale). This field shall include
an alphabetical listing of all acronyms, abbreviations, and their
meanings as used in this document and a list of any terms and
definitions needed to understand this document. 

=item PREREQ_PM field

This field contains the names of modules that need to be available 
to run this extension (e.g. Fcntl for SDBM_File) followed by
the desired version is the value. 
This field should use Perl array notation.
For examples:

 'Fcntl' => '0',
 'Test::Tech' => '1.09',

If the required version number is 0, 
any installed version is acceptable.

=item PREVIOUS_DISTNAME field

This field is normally left blank.
Supply this field when the 
previous distribution name is different.

=item PREVIOUS_RELEASE field

This field is the version of the previous release.

=item PROBLEMS field

This field should identify any
possible problems or known errors with the software version at
the time of release, any steps being taken to resolve the problems
or errors, and instructions (either directly or by reference)
for recognizing, avoiding, correcting, or otherwise handling each
one. The information presented shall be appropriate to the intended
recipient of the SVD (for example, a user agency may need advice
on avoiding errors, a support agency on correcting them).

=item REPLACE field

This is the list of files
that the ExtUtils::SVDmaker module will copy from
the $TOP_DIR to the $RELEASE_DIR entact without
revising the $VERSION and $DATE variables.
This is useful for say files used as expected files
in a test where the $VERSION and $DATE variables
should not be changed.

The file specification may contain BSD globbing
metacharaters such as the '*'.

An example of a REPLACE field is

 t/ExtUtils/SVDmaker/expected/*

The ExtUtils::SVDmaker assumes the files in the REPLACE field are
be relative to the $TOP_DIR.

Another features of the REPLACE field is that 
the files in the $RELEASE_DIR can be rename with
a line such as the following:
  
  top_dir_relative_file  => release_dir_relative_file

=item REPOSITORY field

This field is the repositories that the current distribution will 
be released.

For example,

 http://www.softwarediamonds/packages/
 http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=item REPOSITORY_DIR field

The value for the REPOSITORY_DIR is normally "packages".
This is the directory where all release files are found.
The "ExtUtils::SVDmaker" module uses the REPOSITORY_DIR
as follows:

=over 4

=item *

First it locates the $TOP_DIR of the package specified
by the -pm option. 

=item *

It locates the repository directory by using REPOSITORY_DIR field
as a sub directory of the $TOP_DIR.

=back

See L<Assumed Directory Structure|/Assumed Directory Structure>

=item RESTRUCTURE field

This field is Perl statements that the
"ExtUtils::SVDmaker" uses to rearrange
the directory tree of the release directory.

For example, to eliminate the "lib\SVD"
subtree, enter the following:

 use File::Path;
 rmtree 'lib\SVD';

The evaluation takes place after all "CHANGE2CURRENT" field
processing and with the cwd the current release directory,
not the previous release directory if they are different.

See also L<CHANGE2CURRENT field|/CHANGE2CURRENT field>;

=item REVISION field

Enter the revision for the STD POD.
The revision field, in accordance
with standard engineering drawing
practices are letters A .. B AA .. ZZ
except for the orginal revision which
is -.

=item SEE_ALSO field

This field shall list the number,
title, revision, and date of all referenced and related documents.  
This field shall also identify the source for all
documents.
A simple POD link, when applicable, will satisfy these
requirements.

=item SUPPORT field

Point of contact to be consulted if there
are problems or questions with the installation

=item TITLE field

This field is the "title" entry in the title page of the generated SVD module POD
section.

=item TEMPLATE field

This is the template that the
C<$svd->gen> method uses to generate
the SVD POD file.

=item TESTS field

List of tests for determining whether the version
has been installed properly and
meets its requirements.

=item VERSION field

This field is the version of the release. 
The version should be a decimal number of the
format "\d\.\d\d" starting with "0.01".

=back

=head2 targets

For this discussion of the targets, the
directory structure shown in the
L<REPOSITORY_DIR field|/REPOSITORY_DIR field>
item applies.

=over 4

=item all target

The all target executes the following target sequence: 

 check_svd_db
 restore_previous
 auto_revise
 write_svd_pm
 makemake
 test
 tar
 gzip
 ppd

=item auto_revise target

This target uses the relative files specified in the 
L<AUTO_REVISE field|/AUTO_REVISE field>.
FOr each of the these files, $file, it will
compare ($TOP_DIR $file) with ($RELEASE_DIR $file),
scrubing any date and version so they are not compared.

If the contents of ($TOP_DIR $file) is different
than the ($RELEASE_DIR $file), this target will
update the ($RELEASE_DIR $file) to the ($TOP_DIR $file)
and appropriately change the version and date.

The $TOP_DIR and $RELEASE_DIR used in this description is
as established by L<REPOSITORY_DIR field|/REPOSITORY_DIR field>
item.

Before performing the above sequence,
this target will ensure that the following
sequence of targets have been executed once

 check_svd_db
 restore_previous

=item check_svd_db target

This target checks the integrity of the 
SVD database and creates derived fields
such as "TOP_DIR" helpful in processing
other targets.

=item clear target

The following targets are executed only once no matter
how many times they are specified. 
The target "clear" will clear the block and allow them
to be executed again.

 check_svd_db
 restore_previous
 auto_revise
 write_svd_pm
 readme_html
 makemake

=item dist target

The dist target executes the following target sequence:

 check_svd_db
 restore_previous
 auto_revise
 write_svd_pm
 makemake
 tar
 gzip
 ppd

=item gzip target

The gzip target will compress 
the file

 $DISTNAME-$VERSION.tar

(L<DISTNAME field|/DISTNAME field> L<VERSION field|/DISTNAME field>), 
in the directory

 $REPOSITORY_DIR

After creating the compressed file

 $DISTNAME-$VERSION.tar.gz

in the directory

 $REPOSITORY_DIR

the gzip target will delete the
C<$DISTNAME-$VERSION.tar.gz> file.

Before generating the C<$DISTNAME-$VERSION.tar.gz>
compress file,
the gzip target will ensure that the following
sequence targets have been executed once

 check_svd_db
 restore_previous
 auto_revise
 write_svd_pm
 makemake
 tar

=item makemake target

This target generates the following 
files:

 README
 MANIFEST
 Makefile.PL

Before generating the above files,
the makemake target will ensure that the following
sequence targets have been executed once

 check_svd_db
 restore_previous
 auto_revise

=item ppd target

The ppd target will create the ppd file

 $DISTNAME-$VERSION.ppd
 
that describes the distribution using XML
in the directory

 $REPOSITORY_DIR

Before generating the ppd file,
the ppd target will ensure that the following
sequence targets have been executed once

 check_svd_db
 restore_previous
 auto_revise

=item readme_html target

This target generates the file

 $DISTNAME-$VERSION.html

in the directory

 $REPOSITORY_DIR

The $REPOSITORY_DIR scalar used in this description is
as established by L<REPOSITORY_DIR field|/REPOSITORY_DIR field>
item.

Before generating the $DISTNAME-$VERSION.html files,
the readme_html target will ensure that the following
sequence targets have been executed once

 check_svd_db
 restore_previous
 auto_revise
 write_svd_pm

=item restore_previous target

Before generating the above files,
this target will ensure that the following
sequence targets have been executed once

 check_svd_db

=item tar target

The tar target will archive the files
specified in the MANIFEST file into
the file

 $DISTNAME-$VERSION.tar

in the directory

 $REPOSITORY_DIR

Before generating the $DISTNAME-$VERSION.tar
archive file 
(L<DISTNAME field|/DISTNAME field> L<VERSION field|/DISTNAME field>), 
the tar target will ensure that the following
sequence targets have been executed once

 check_svd_db
 restore_previous
 auto_revise
 write_svd_pm
 makemake

=item test target

The test target will run the tests specified in
the L<TESTS field|/TESTS field> using the
L<Test::Harness|Test::Harness>

Before generating the above files,
this target will ensure that the following
sequence targets have been executed once

 check_svd_db
 restore_previous
 auto_revise

=item write_svd_pm target

This target generates the Perl and POD section
of the SVD program module from the __DATA__ section.
It updates both the copy in the $TOP_DIR subtree and the
$RELEASE_DIR subtree.

The $TOP_DIR and $RELEASE_DIR used in this description is
as established by L<REPOSITORY_DIR field|/REPOSITORY_DIR field>
item.

Before generating the above files,
this target will ensure that the following
sequence targets have been executed once

 check_svd_db
 restore_previous
 auto_revise

=item # no target

A lack of a target is the same as 

 "all readme_html"

=back

=head1 REQUIREMENTS

Requirements are coming soon.

=head1 DEMONSTRATION

 #########
 # perl Original.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use vars qw($loaded);
     use File::Glob ':glob';
     use File::Copy;
     use File::Path;
     use File::Spec;

     use File::Package;
     use File::SmartNL;
     use Text::Scrub;

     my $loaded = 0;
     my $snl = 'File::SmartNL';
     my $fp = 'File::Package';
     my $s = 'Text::Scrub';
     my $w = 'File::Where';
     my $fs = 'File::Spec';

 ##################
 # UUT not loaded
 # 

 $fp->is_package_loaded('ExtUtils::SVDmaker')

 # ''
 #

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package( 'ExtUtils::SVDmaker' )
 $errors

 # ''
 #
     ######
     # Add the SVDmaker test lib and test t directories onto @INC
     #
     unshift @INC, File::Spec->catdir( cwd(), 't');
     unshift @INC, File::Spec->catdir( cwd(), 'lib');
     rmtree( 't' );
     rmtree( 'lib' );
     mkpath( 't' );
     mkpath( 'lib' );
     mkpath( $fs->catfile( 't', 'Test' ));
     mkpath( $fs->catfile( 't', 'Data' ));
     mkpath( $fs->catfile( 't', 'File' ));

     copy ($fs->catfile('expected','SVDtest0A.pm'),$fs->catfile('lib','SVDtest1.pm'));
     copy ($fs->catfile('expected','module0A.pm'),$fs->catfile('lib','module1.pm'));
     copy ($fs->catfile('expected','SVDtest0A.t'),$fs->catfile('t','SVDtest1.t'));
     copy ($fs->catfile('expected','Test','Tech.pm'),$fs->catfile('t','Test','Tech.pm'));
     copy ($fs->catfile('expected','Data','Startup.pm'),$fs->catfile('t','Data','Startup.pm'));
     copy ($fs->catfile('expected','Data','Secs2.pm'),$fs->catfile('t','Data','Secs2.pm'));
     copy ($fs->catfile('expected','Data','SecsPack.pm'),$fs->catfile('t','Data','SecsPack.pm'));
     copy ($fs->catfile('expected','File','Package.pm'),$fs->catfile('t','File','Package.pm'));

     rmtree 'packages';
 $snl->fin( File::Spec->catfile('lib', 'module1.pm'))

 # '#!perl
 ##
 ## Documentation, copyright and license is at the end of this file.
 ##
 #package  module1;

 #use 5.001;
 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE);
 #$VERSION = '0.01';
 #$DATE = '2003/08/04';
 #$FILE = __FILE__;

 #####
 ## Using an object to pass localized object data
 ## between functions. Makes the functions reentrant
 ## where out right globals can be clobbered when
 ## used with different threads (processes??)
 ##
 #sub new
 #{
 #    my ($class, $test_log) = @_;
 #    $class = ref($class) if ref($class);
 #    bless {}, $class;

 #}

 ######
 ## Test method
 ##
 #sub hello 
 #{
 #   "hello world"
 #   
 #}

 #1

 #__END__

 #=head1 NAME

 #module1 - SVDmaker test module

 #=cut

 #### end of file ###'
 #
 $snl->fin( File::Spec->catfile('lib', 'SVDtest1.pm'))

 # '#!perl
 ##
 ## The copyright notice and plain old documentation (POD)
 ## are at the end of this file.
 ##
 #package SVDtest1;

 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE );
 #$VERSION = '0.01';
 #$DATE = '2003/08/04';
 #$FILE = __FILE__;

 #1

 #__DATA__

 #DISTNAME: SVDtest1^
 #VERSION:1.12^   
 #REPOSITORY_DIR: packages^
 #FREEZE: 0^

 #PREVIOUS_DISTNAME:  ^
 #PREVIOUS_RELEASE: ^
 #REVISION: -^
 #AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^

 #ABSTRACT: 
 #Objectify the Test module,
 #adds the skip_test method to the Test module, and 
 #adds the ability to compare complex data structures to the Test module.
 #^

 #TITLE   : ExtUtils::SVDmaker::SVDtest - Test SVDmaker^
 #END_USER: General Public^
 #COPYRIGHT: copyright © 2003 Software Diamonds^
 #CLASSIFICATION: NONE^
 #TEMPLATE:  ^
 #CSS: help.css^
 #SVD_FSPEC: Unix^

 #REPOSITORY: 
 #  http://www.softwarediamonds/packages/
 #  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/
 #^

 #COMPRESS: gzip^
 #COMPRESS_SUFFIX: gz^

 #CHANGE2CURRENT:  ^

 #RESTRUCTURE:  ^

 #AUTO_REVISE: 
 #lib/SVDtest1.pm
 #lib/module1.pm
 #t/SVDtest1.t
 #t/Test/Tech.pm
 #t/Data/Startup.pm
 #t/Data/Secs2.pm
 #t/Data/SecsPack.pm
 #t/File/Package.pm
 #^

 #PREREQ_PM: 'File::Basename' => 0^

 #TESTS: t/SVDtest1.t^
 #EXE_FILES:  ^

 #CHANGES: 
 #This is the original release. There are no preivious releases to change.
 #^

 #CAPABILITIES: The ExtUtils::SVDmaker::SVDtest module is a SVDmaker test module. ^

 #PROBLEMS: There are no open issues.^

 #DOCUMENT_OVERVIEW:
 #This document releases ${NAME} version ${VERSION}
 #providing description of the inventory, installation
 #instructions and other information necessary to
 #utilize and track this release.
 #^

 #LICENSE:
 #Software Diamonds permits the redistribution
 #and use in source and binary forms, with or
 #without modification, provided that the 
 #following conditions are met: 

 #\=over 4

 #\=item 1

 #Redistributions of source code, modified or unmodified
 #must retain the above copyright notice, this list of
 #conditions and the following disclaimer. 

 #\=item 2

 #Redistributions in binary form must 
 #reproduce the above copyright notice,
 #this list of conditions and the following 
 #disclaimer in the documentation and/or
 #other materials provided with the
 #distribution.

 #\=back

 #SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
 #PROVIDES THIS SOFTWARE 
 #'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 #INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 #WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 #A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 #SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
 #INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
 #CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 #TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 #LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
 #INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 #OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 #OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
 #ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
 #ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.
 #^

 #INSTALLATION:
 #To installed the release file, use the CPAN module in the Perl release
 #or the INSTALL.PL script at the following web site:

 # http://packages.SoftwareDiamonds.com

 #Follow the instructions for the the chosen installation software.

 #The distribution file is at the following respositories:

 #${REPOSITORY}
 #^

 #SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>^

 #NOTES:
 #The following are useful acronyms:

 #\=over 4

 #\=item .d

 #extension for a Perl demo script file

 #\=item .pm

 #extension for a Perl Library Module

 #\=item .t

 #extension for a Perl test script file

 #\=item DID

 #Data Item Description

 #\=item POD

 #Plain Old Documentation

 #\=item STD

 #Software Test Description

 #\=item SVD

 #Software Version Description

 #\=back
 #^

 #SEE_ALSO:

 #\=over 4

 #\=item L<ExtUtils::SVDmake|ExtUtils::SVDmaker>

 #\=back

 #^

 #HTML:
 #<hr>
 #<p><br>
 #<!-- BLK ID="PROJECT_MANAGEMENT" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="NOTICE" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="OPT-IN" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="LOG_CGI" -->
 #<!-- /BLK -->
 #<p><br>
 #^
 #~-~

 #'
 #
 $snl->fin( File::Spec->catfile('t', 'SVDtest1.t'))

 # '#!perl
 ##
 ##
 #use 5.001;
 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE);
 #$VERSION = '0.01';
 #$DATE = '2003/08/04';

 #######
 ##
 ## T:
 ##
 ## use a BEGIN block so we print our plan before Module Under Test is loaded
 ##
 #BEGIN { 
 #   use FindBin;
 #   use File::Spec;
 #   use Cwd;

 #   ########
 #   # The working directory for this script file is the directory where
 #   # the test script resides. Thus, any relative files written or read
 #   # by this test script are located relative to this test script.
 #   #
 #   use vars qw( $__restore_dir__ );
 #   $__restore_dir__ = cwd();
 #   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
 #   chdir $vol if $vol;
 #   chdir $dirs if $dirs;

 #   #######
 #   # Pick up any testing program modules off this test script.
 #   #
 #   # When testing on a target site before installation, place any test
 #   # program modules that should not be installed in the same directory
 #   # as this test script. Likewise, when testing on a host with a @INC
 #   # restricted to just raw Perl distribution, place any test program
 #   # modules in the same directory as this test script.
 #   #
 #   use lib $FindBin::Bin;

 #   ########
 #   # Using Test::Tech, a very light layer over the module "Test" to
 #   # conduct the tests.  The big feature of the "Test::Tech: module
 #   # is that it takes expected and actual references and stringify
 #   # them by using "Data::Secs2" before passing them to the "&Test::ok"
 #   # Thus, almost any time of Perl data structures may be
 #   # compared by passing a reference to them to Test::Tech::ok
 #   #
 #   # Create the test plan by supplying the number of tests
 #   # and the todo tests
 #   #
 #   require Test::Tech;
 #   Test::Tech->import( qw(finish is_skip ok plan skip skip_tests tech_config) );

 #   plan(tests => 3);

 #}

 #END {

 #   #########
 #   # Restore working directory and @INC back to when enter script
 #   #
 #   @INC = @lib::ORIG_INC;
 #   chdir $__restore_dir__;

 #}

 ########
 ##
 ## ok: 1 
 ##
 #use File::Package;
 #my $fp = 'File::Package';
 #my $loaded;
 #print "# UUT not loaded\n";
 #ok( [$loaded = $fp->is_package_loaded('module1')], 
 #    ['']); #expected results

 ########
 ## 
 ## ok:  2
 ## 
 #print "# Load UUT\n";
 #my $errors = $fp->load_package( 'module1' );
 #skip_tests(1) unless skip(
 #    $loaded, # condition to skip test   
 #    [$errors], # actual results
 #    ['']);  # expected results

 #my $m = new module1;
 #print "# test hello world\n";
 #ok($m->hello, 'hello world', 'hello world');

 #__END__

 #=head1 NAME

 #SVDmaker.t - test script for Test::tech

 #=head1 SYNOPSIS

 # SVDmaker.t 

 #=head1 NOTES

 #=head2 Copyright

 #copyright © 2003 Software Diamonds.

 #head2 License

 #Software Diamonds permits the redistribution
 #and use in source and binary forms, with or
 #without modification, provided that the 
 #following conditions are met: 

 #=over 4

 #=item 1

 #Redistributions of source code, modified or unmodified
 #must retain the above copyright notice, this list of
 #conditions and the following disclaimer. 

 #=item 2

 #Redistributions in binary form must 
 #reproduce the above copyright notice,
 #this list of conditions and the following 
 #disclaimer in the documentation and/or
 #other materials provided with the
 #distribution.

 #=back

 #SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
 #PROVIDES THIS SOFTWARE 
 #'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 #INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 #WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 #A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 #SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
 #INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
 #CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 #TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 #LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
 #INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 #OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 #OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
 #ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
 #ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

 #=cut

 ### end of test script file ##

 #'
 #
     unlink 'SVDtest1.log';
     no warnings;
     open SAVE_OUT, ">&STDOUT";
     open SAVE_ERR, ">&STDERR";
     use warnings;
     open STDOUT,'> SVDtest1.log';
     open STDERR, ">&STDOUT";
     my $svd = new ExtUtils::SVDmaker( );
     my  $success = $svd->vmake( {pm => 'SVDtest1'} );
     close STDOUT;
     close STDERR;
     open STDOUT, ">&SAVE_OUT";
     open STDERR, ">&SAVE_ERR";
     my $output = $snl->fin( 'SVDtest1.log' );
 $output

 # 't/SVDtest1....1..3
 ## Running under perl version 5.006001 for MSWin32
 ## Win32::BuildNumber 635
 ## Current time local: Tue May 25 09:23:19 2004
 ## Current time GMT:   Tue May 25 13:23:19 2004
 ## Using Test.pm version 1.25
 ## Test::Tech    : 1.24
 ## Data::Secs2   : 1.22
 ## Data::SecsPack: 0.07
 ## Data::Startup : 0.06
 ## =cut 
 ## UUT not loaded
 #ok 1
 ## Load UUT
 #ok 2
 ## test hello world
 #ok 3
 #ok
 #All tests successful.
 #Files=1, Tests=3,  0 wallclock secs ( 0.00 cusr +  0.00 csys =  0.00 CPU)
 #'
 #

 ##################
 # All tests successful
 # 

 $output =~ /All tests successful/

 # '1'
 #
 $s->scrub_date( $snl->fin( File::Spec->catfile( 'lib', 'SVDtest1.pm' ) ) )

 # '#!perl
 ##
 ## The copyright notice and plain old documentation (POD)
 ## are at the end of this file.
 ##
 #package  SVDtest1;

 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE );
 #$VERSION = '0.01';
 #$DATE = '1969/02/06';
 #$FILE = __FILE__;

 #use vars qw(%INVENTORY);
 #%INVENTORY = (
 #    'lib/SVDtest1.pm' => [qw(0.01 1969/02/06), 'new'],
 #    'MANIFEST' => [qw(0.01 1969/02/06), 'generated new'],
 #    'Makefile.PL' => [qw(0.01 1969/02/06), 'generated new'],
 #    'README' => [qw(0.01 1969/02/06), 'generated new'],
 #    'lib/SVDtest1.pm' => [qw(0.01 1969/02/06), 'new'],
 #    'lib/module1.pm' => [qw(0.01 1969/02/06), 'new'],
 #    't/SVDtest1.t' => [qw(0.01 1969/02/06), 'new'],
 #    't/Test/Tech.pm' => [qw(1.24 1969/02/06), 'new'],
 #    't/Data/Startup.pm' => [qw(0.06 1969/02/06), 'new'],
 #    't/Data/Secs2.pm' => [qw(1.22 1969/02/06), 'new'],
 #    't/Data/SecsPack.pm' => [qw(0.07 1969/02/06), 'new'],
 #    't/File/Package.pm' => [qw(1.17 1969/02/06), 'new'],

 #);

 #########
 ## The ExtUtils::SVDmaker module uses the data after the __DATA__ 
 ## token to automatically generate this file.
 ##
 ## Don't edit anything before __DATA_. Edit instead
 ## the data after the __DATA__ token.
 ##
 ## ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
 ##
 ## the next time ExtUtils::SVDmaker generates this file.
 ##
 ##

 #=head1 NAME

 #ExtUtils::SVDmaker::SVDtest - Test SVDmaker

 #=head1 Title Page

 # Software Version Description

 # for

 # ExtUtils::SVDmaker::SVDtest - Test SVDmaker

 # Revision: -

 # Version: 0.01

 # Date: 1969/02/06

 # Prepared for: General Public 

 # Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 # Copyright: copyright © 2003 Software Diamonds

 # Classification: NONE

 #=head1 1.0 SCOPE

 #This paragraph identifies and provides an overview
 #of the released files.

 #=head2 1.1 Identification

 #This release,
 #identified in L<3.2|/3.2 Inventory of software contents>,
 #is a collection of Perl modules that
 #extend the capabilities of the Perl language.

 #=head2 1.2 System overview

 #The ExtUtils::SVDmaker::SVDtest module is a SVDmaker test module.

 #=head2 1.3 Document overview.

 #This document releases SVDtest1 version 0.01
 #providing description of the inventory, installation
 #instructions and other information necessary to
 #utilize and track this release.

 #=head1 3.0 VERSION DESCRIPTION

 #All file specifications in this SVD
 #use the Unix operating
 #system file specification.

 #=head2 3.1 Inventory of materials released.

 #This document releases the file 

 # SVDtest1-0.01.tar.gz

 #found at the following repository(s):

 #  http://www.softwarediamonds/packages/
 #  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

 #Restrictions regarding duplication and license provisions
 #are as follows:

 #=over 4

 #=item Copyright.

 #copyright © 2003 Software Diamonds

 #=item Copyright holder contact.

 # 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

 #=item License.

 #Software Diamonds permits the redistribution
 #and use in source and binary forms, with or
 #without modification, provided that the 
 #following conditions are met: 

 #=over 4

 #=item 1

 #Redistributions of source code, modified or unmodified
 #must retain the above copyright notice, this list of
 #conditions and the following disclaimer. 

 #=item 2

 #Redistributions in binary form must 
 #reproduce the above copyright notice,
 #this list of conditions and the following 
 #disclaimer in the documentation and/or
 #other materials provided with the
 #distribution.

 #=back

 #SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
 #PROVIDES THIS SOFTWARE 
 #'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 #INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 #WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 #A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 #SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
 #INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
 #CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 #TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 #LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
 #INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 #OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 #OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
 #ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
 #ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

 #=back

 #=head2 3.2 Inventory of software contents

 #The content of the released, compressed, archieve file,
 #consists of the following files:

 # file                                                         version date       comment
 # ------------------------------------------------------------ ------- ---------- ------------------------
 # lib/SVDtest1.pm                                              0.01    1969/02/06 new
 # MANIFEST                                                     0.01    1969/02/06 generated new
 # Makefile.PL                                                  0.01    1969/02/06 generated new
 # README                                                       0.01    1969/02/06 generated new
 # lib/SVDtest1.pm                                              0.01    1969/02/06 new
 # lib/module1.pm                                               0.01    1969/02/06 new
 # t/SVDtest1.t                                                 0.01    1969/02/06 new
 # t/Test/Tech.pm                                               1.24    1969/02/06 new
 # t/Data/Startup.pm                                            0.06    1969/02/06 new
 # t/Data/Secs2.pm                                              1.22    1969/02/06 new
 # t/Data/SecsPack.pm                                           0.07    1969/02/06 new
 # t/File/Package.pm                                            1.17    1969/02/06 new

 #=head2 3.3 Changes

 #This is the original release. There are no preivious releases to change.

 #=head2 3.4 Adaptation data.

 #This installation requires that the installation site
 #has the Perl programming language installed.
 #There are no other additional requirements or tailoring needed of 
 #configurations files, adaptation data or other software needed for this
 #installation particular to any installation site.

 #=head2 3.5 Related documents.

 #There are no related documents needed for the installation and
 #test of this release.

 #=head2 3.6 Installation instructions.

 #Instructions for installation, installation tests
 #and installation support are as follows:

 #=over 4

 #=item Installation Instructions.

 #To installed the release file, use the CPAN module in the Perl release
 #or the INSTALL.PL script at the following web site:

 # http://packages.SoftwareDiamonds.com

 #Follow the instructions for the the chosen installation software.

 #The distribution file is at the following respositories:

 #  http://www.softwarediamonds/packages/
 #  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

 #=item Prerequistes.

 # 'File::Basename' => 0

 #=item Security, privacy, or safety precautions.

 #None.

 #=item Installation Tests.

 #Most Perl installation software will run the following test script(s)
 #as part of the installation:

 # t/SVDtest1.t

 #=item Installation support.

 #If there are installation problems or questions with the installation
 #contact

 # 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

 #=back

 #=head2 3.7 Possible problems and known errors

 #There are no open issues.

 #=head1 4.0 NOTES

 #The following are useful acronyms:

 #=over 4

 #=item .d

 #extension for a Perl demo script file

 #=item .pm

 #extension for a Perl Library Module

 #=item .t

 #extension for a Perl test script file

 #=item DID

 #Data Item Description

 #=item POD

 #Plain Old Documentation

 #=item STD

 #Software Test Description

 #=item SVD

 #Software Version Description

 #=back

 #=head1 2.0 SEE ALSO

 #=over 4

 #=item L<ExtUtils::SVDmake|ExtUtils::SVDmaker>

 #=back

 #=for html
 #<hr>
 #<p><br>
 #<!-- BLK ID="PROJECT_MANAGEMENT" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="NOTICE" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="OPT-IN" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="LOG_CGI" -->
 #<!-- /BLK -->
 #<p><br>

 #=cut

 #1;

 #__DATA__

 #DISTNAME: SVDtest1^
 #VERSION: 0.01^ 
 #REPOSITORY_DIR: packages^
 #FREEZE: 0^

 #PREVIOUS_DISTNAME:  ^
 #PREVIOUS_RELEASE: ^
 #REVISION: -^
 #AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^

 #ABSTRACT: 
 #Objectify the Test module,
 #adds the skip_test method to the Test module, and 
 #adds the ability to compare complex data structures to the Test module.
 #^

 #TITLE   : ExtUtils::SVDmaker::SVDtest - Test SVDmaker^
 #END_USER: General Public^
 #COPYRIGHT: copyright © 2003 Software Diamonds^
 #CLASSIFICATION: NONE^
 #TEMPLATE:  ^
 #CSS: help.css^
 #SVD_FSPEC: Unix^

 #REPOSITORY: 
 #  http://www.softwarediamonds/packages/
 #  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/
 #^

 #COMPRESS: gzip^
 #COMPRESS_SUFFIX: gz^

 #CHANGE2CURRENT:  ^

 #RESTRUCTURE:  ^

 #AUTO_REVISE: 
 #lib/SVDtest1.pm
 #lib/module1.pm
 #t/SVDtest1.t
 #t/Test/Tech.pm
 #t/Data/Startup.pm
 #t/Data/Secs2.pm
 #t/Data/SecsPack.pm
 #t/File/Package.pm
 #^

 #PREREQ_PM: 'File::Basename' => 0^

 #TESTS: t/SVDtest1.t^
 #EXE_FILES:  ^

 #CHANGES: 
 #This is the original release. There are no preivious releases to change.
 #^

 #CAPABILITIES: The ExtUtils::SVDmaker::SVDtest module is a SVDmaker test module. ^

 #PROBLEMS: There are no open issues.^

 #DOCUMENT_OVERVIEW:
 #This document releases ${NAME} version ${VERSION}
 #providing description of the inventory, installation
 #instructions and other information necessary to
 #utilize and track this release.
 #^

 #LICENSE:
 #Software Diamonds permits the redistribution
 #and use in source and binary forms, with or
 #without modification, provided that the 
 #following conditions are met: 

 #\=over 4

 #\=item 1

 #Redistributions of source code, modified or unmodified
 #must retain the above copyright notice, this list of
 #conditions and the following disclaimer. 

 #\=item 2

 #Redistributions in binary form must 
 #reproduce the above copyright notice,
 #this list of conditions and the following 
 #disclaimer in the documentation and/or
 #other materials provided with the
 #distribution.

 #\=back

 #SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
 #PROVIDES THIS SOFTWARE 
 #'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 #INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 #WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 #A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 #SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
 #INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
 #CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 #TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 #LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
 #INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 #OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 #OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
 #ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
 #ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.
 #^

 #INSTALLATION:
 #To installed the release file, use the CPAN module in the Perl release
 #or the INSTALL.PL script at the following web site:

 # http://packages.SoftwareDiamonds.com

 #Follow the instructions for the the chosen installation software.

 #The distribution file is at the following respositories:

 #${REPOSITORY}
 #^

 #SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>^

 #NOTES:
 #The following are useful acronyms:

 #\=over 4

 #\=item .d

 #extension for a Perl demo script file

 #\=item .pm

 #extension for a Perl Library Module

 #\=item .t

 #extension for a Perl test script file

 #\=item DID

 #Data Item Description

 #\=item POD

 #Plain Old Documentation

 #\=item STD

 #Software Test Description

 #\=item SVD

 #Software Version Description

 #\=back
 #^

 #SEE_ALSO:

 #\=over 4

 #\=item L<ExtUtils::SVDmake|ExtUtils::SVDmaker>

 #\=back

 #^

 #HTML:
 #<hr>
 #<p><br>
 #<!-- BLK ID="PROJECT_MANAGEMENT" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="NOTICE" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="OPT-IN" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="LOG_CGI" -->
 #<!-- /BLK -->
 #<p><br>
 #^
 #~-~

 #'
 #

 ##################
 # generated SVD POD
 # 

 $s->scrub_date( $snl->fin( File::Spec->catfile( 'packages', 'SVDtest1-0.01', 'lib', 'SVDtest1.pm' ) ) )

 # '#!perl
 ##
 ## The copyright notice and plain old documentation (POD)
 ## are at the end of this file.
 ##
 #package  SVDtest1;

 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE );
 #$VERSION = '0.01';
 #$DATE = '1969/02/06';
 #$FILE = __FILE__;

 #use vars qw(%INVENTORY);
 #%INVENTORY = (
 #    'lib/SVDtest1.pm' => [qw(0.01 1969/02/06), 'new'],
 #    'MANIFEST' => [qw(0.01 1969/02/06), 'generated new'],
 #    'Makefile.PL' => [qw(0.01 1969/02/06), 'generated new'],
 #    'README' => [qw(0.01 1969/02/06), 'generated new'],
 #    'lib/SVDtest1.pm' => [qw(0.01 1969/02/06), 'new'],
 #    'lib/module1.pm' => [qw(0.01 1969/02/06), 'new'],
 #    't/SVDtest1.t' => [qw(0.01 1969/02/06), 'new'],
 #    't/Test/Tech.pm' => [qw(1.24 1969/02/06), 'new'],
 #    't/Data/Startup.pm' => [qw(0.06 1969/02/06), 'new'],
 #    't/Data/Secs2.pm' => [qw(1.22 1969/02/06), 'new'],
 #    't/Data/SecsPack.pm' => [qw(0.07 1969/02/06), 'new'],
 #    't/File/Package.pm' => [qw(1.17 1969/02/06), 'new'],

 #);

 #########
 ## The ExtUtils::SVDmaker module uses the data after the __DATA__ 
 ## token to automatically generate this file.
 ##
 ## Don't edit anything before __DATA_. Edit instead
 ## the data after the __DATA__ token.
 ##
 ## ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
 ##
 ## the next time ExtUtils::SVDmaker generates this file.
 ##
 ##

 #=head1 NAME

 #ExtUtils::SVDmaker::SVDtest - Test SVDmaker

 #=head1 Title Page

 # Software Version Description

 # for

 # ExtUtils::SVDmaker::SVDtest - Test SVDmaker

 # Revision: -

 # Version: 0.01

 # Date: 1969/02/06

 # Prepared for: General Public 

 # Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 # Copyright: copyright © 2003 Software Diamonds

 # Classification: NONE

 #=head1 1.0 SCOPE

 #This paragraph identifies and provides an overview
 #of the released files.

 #=head2 1.1 Identification

 #This release,
 #identified in L<3.2|/3.2 Inventory of software contents>,
 #is a collection of Perl modules that
 #extend the capabilities of the Perl language.

 #=head2 1.2 System overview

 #The ExtUtils::SVDmaker::SVDtest module is a SVDmaker test module.

 #=head2 1.3 Document overview.

 #This document releases SVDtest1 version 0.01
 #providing description of the inventory, installation
 #instructions and other information necessary to
 #utilize and track this release.

 #=head1 3.0 VERSION DESCRIPTION

 #All file specifications in this SVD
 #use the Unix operating
 #system file specification.

 #=head2 3.1 Inventory of materials released.

 #This document releases the file 

 # SVDtest1-0.01.tar.gz

 #found at the following repository(s):

 #  http://www.softwarediamonds/packages/
 #  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

 #Restrictions regarding duplication and license provisions
 #are as follows:

 #=over 4

 #=item Copyright.

 #copyright © 2003 Software Diamonds

 #=item Copyright holder contact.

 # 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

 #=item License.

 #Software Diamonds permits the redistribution
 #and use in source and binary forms, with or
 #without modification, provided that the 
 #following conditions are met: 

 #=over 4

 #=item 1

 #Redistributions of source code, modified or unmodified
 #must retain the above copyright notice, this list of
 #conditions and the following disclaimer. 

 #=item 2

 #Redistributions in binary form must 
 #reproduce the above copyright notice,
 #this list of conditions and the following 
 #disclaimer in the documentation and/or
 #other materials provided with the
 #distribution.

 #=back

 #SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
 #PROVIDES THIS SOFTWARE 
 #'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 #INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 #WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 #A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 #SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
 #INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
 #CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 #TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 #LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
 #INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 #OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 #OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
 #ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
 #ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

 #=back

 #=head2 3.2 Inventory of software contents

 #The content of the released, compressed, archieve file,
 #consists of the following files:

 # file                                                         version date       comment
 # ------------------------------------------------------------ ------- ---------- ------------------------
 # lib/SVDtest1.pm                                              0.01    1969/02/06 new
 # MANIFEST                                                     0.01    1969/02/06 generated new
 # Makefile.PL                                                  0.01    1969/02/06 generated new
 # README                                                       0.01    1969/02/06 generated new
 # lib/SVDtest1.pm                                              0.01    1969/02/06 new
 # lib/module1.pm                                               0.01    1969/02/06 new
 # t/SVDtest1.t                                                 0.01    1969/02/06 new
 # t/Test/Tech.pm                                               1.24    1969/02/06 new
 # t/Data/Startup.pm                                            0.06    1969/02/06 new
 # t/Data/Secs2.pm                                              1.22    1969/02/06 new
 # t/Data/SecsPack.pm                                           0.07    1969/02/06 new
 # t/File/Package.pm                                            1.17    1969/02/06 new

 #=head2 3.3 Changes

 #This is the original release. There are no preivious releases to change.

 #=head2 3.4 Adaptation data.

 #This installation requires that the installation site
 #has the Perl programming language installed.
 #There are no other additional requirements or tailoring needed of 
 #configurations files, adaptation data or other software needed for this
 #installation particular to any installation site.

 #=head2 3.5 Related documents.

 #There are no related documents needed for the installation and
 #test of this release.

 #=head2 3.6 Installation instructions.

 #Instructions for installation, installation tests
 #and installation support are as follows:

 #=over 4

 #=item Installation Instructions.

 #To installed the release file, use the CPAN module in the Perl release
 #or the INSTALL.PL script at the following web site:

 # http://packages.SoftwareDiamonds.com

 #Follow the instructions for the the chosen installation software.

 #The distribution file is at the following respositories:

 #  http://www.softwarediamonds/packages/
 #  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

 #=item Prerequistes.

 # 'File::Basename' => 0

 #=item Security, privacy, or safety precautions.

 #None.

 #=item Installation Tests.

 #Most Perl installation software will run the following test script(s)
 #as part of the installation:

 # t/SVDtest1.t

 #=item Installation support.

 #If there are installation problems or questions with the installation
 #contact

 # 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

 #=back

 #=head2 3.7 Possible problems and known errors

 #There are no open issues.

 #=head1 4.0 NOTES

 #The following are useful acronyms:

 #=over 4

 #=item .d

 #extension for a Perl demo script file

 #=item .pm

 #extension for a Perl Library Module

 #=item .t

 #extension for a Perl test script file

 #=item DID

 #Data Item Description

 #=item POD

 #Plain Old Documentation

 #=item STD

 #Software Test Description

 #=item SVD

 #Software Version Description

 #=back

 #=head1 2.0 SEE ALSO

 #=over 4

 #=item L<ExtUtils::SVDmake|ExtUtils::SVDmaker>

 #=back

 #=for html
 #<hr>
 #<p><br>
 #<!-- BLK ID="PROJECT_MANAGEMENT" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="NOTICE" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="OPT-IN" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="LOG_CGI" -->
 #<!-- /BLK -->
 #<p><br>

 #=cut

 #1;

 #__DATA__

 #DISTNAME: SVDtest1^
 #VERSION: 0.01^ 
 #REPOSITORY_DIR: packages^
 #FREEZE: 0^

 #PREVIOUS_DISTNAME:  ^
 #PREVIOUS_RELEASE: ^
 #REVISION: -^
 #AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^

 #ABSTRACT: 
 #Objectify the Test module,
 #adds the skip_test method to the Test module, and 
 #adds the ability to compare complex data structures to the Test module.
 #^

 #TITLE   : ExtUtils::SVDmaker::SVDtest - Test SVDmaker^
 #END_USER: General Public^
 #COPYRIGHT: copyright © 2003 Software Diamonds^
 #CLASSIFICATION: NONE^
 #TEMPLATE:  ^
 #CSS: help.css^
 #SVD_FSPEC: Unix^

 #REPOSITORY: 
 #  http://www.softwarediamonds/packages/
 #  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/
 #^

 #COMPRESS: gzip^
 #COMPRESS_SUFFIX: gz^

 #CHANGE2CURRENT:  ^

 #RESTRUCTURE:  ^

 #AUTO_REVISE: 
 #lib/SVDtest1.pm
 #lib/module1.pm
 #t/SVDtest1.t
 #t/Test/Tech.pm
 #t/Data/Startup.pm
 #t/Data/Secs2.pm
 #t/Data/SecsPack.pm
 #t/File/Package.pm
 #^

 #PREREQ_PM: 'File::Basename' => 0^

 #TESTS: t/SVDtest1.t^
 #EXE_FILES:  ^

 #CHANGES: 
 #This is the original release. There are no preivious releases to change.
 #^

 #CAPABILITIES: The ExtUtils::SVDmaker::SVDtest module is a SVDmaker test module. ^

 #PROBLEMS: There are no open issues.^

 #DOCUMENT_OVERVIEW:
 #This document releases ${NAME} version ${VERSION}
 #providing description of the inventory, installation
 #instructions and other information necessary to
 #utilize and track this release.
 #^

 #LICENSE:
 #Software Diamonds permits the redistribution
 #and use in source and binary forms, with or
 #without modification, provided that the 
 #following conditions are met: 

 #\=over 4

 #\=item 1

 #Redistributions of source code, modified or unmodified
 #must retain the above copyright notice, this list of
 #conditions and the following disclaimer. 

 #\=item 2

 #Redistributions in binary form must 
 #reproduce the above copyright notice,
 #this list of conditions and the following 
 #disclaimer in the documentation and/or
 #other materials provided with the
 #distribution.

 #\=back

 #SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
 #PROVIDES THIS SOFTWARE 
 #'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 #INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 #WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 #A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 #SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
 #INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
 #CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 #TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 #LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
 #INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 #OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 #OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
 #ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
 #ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.
 #^

 #INSTALLATION:
 #To installed the release file, use the CPAN module in the Perl release
 #or the INSTALL.PL script at the following web site:

 # http://packages.SoftwareDiamonds.com

 #Follow the instructions for the the chosen installation software.

 #The distribution file is at the following respositories:

 #${REPOSITORY}
 #^

 #SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>^

 #NOTES:
 #The following are useful acronyms:

 #\=over 4

 #\=item .d

 #extension for a Perl demo script file

 #\=item .pm

 #extension for a Perl Library Module

 #\=item .t

 #extension for a Perl test script file

 #\=item DID

 #Data Item Description

 #\=item POD

 #Plain Old Documentation

 #\=item STD

 #Software Test Description

 #\=item SVD

 #Software Version Description

 #\=back
 #^

 #SEE_ALSO:

 #\=over 4

 #\=item L<ExtUtils::SVDmake|ExtUtils::SVDmaker>

 #\=back

 #^

 #HTML:
 #<hr>
 #<p><br>
 #<!-- BLK ID="PROJECT_MANAGEMENT" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="NOTICE" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="OPT-IN" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="LOG_CGI" -->
 #<!-- /BLK -->
 #<p><br>
 #^
 #~-~

 #'
 #

 ##################
 # generated packages SVD POD
 # 

 $snl->fin( File::Spec->catfile( 'packages', 'SVDtest1-0.01', 'MANIFEST' ) )

 # 'lib/SVDtest1.pm
 #MANIFEST
 #Makefile.PL
 #README
 #lib/SVDtest1.pm
 #lib/module1.pm
 #t/SVDtest1.t
 #t/Test/Tech.pm
 #t/Data/Startup.pm
 #t/Data/Secs2.pm
 #t/Data/SecsPack.pm
 #t/File/Package.pm'
 #

 ##################
 # generated MANIFEST
 # 

 $snl->fin( File::Spec->catfile( 'packages', 'SVDtest1-0.01', 'Makefile.PL' ) )

 # '
 #####
 ## 
 ## The module ExtUtils::STDmaker generated this file from the contents of
 ##
 ## SVDtest1 
 ##
 ## Don't edit this file, edit instead
 ##
 ## SVDtest1
 ##
 ##	ANY CHANGES MADE HERE WILL BE LOST
 ##
 ##       the next time ExtUtils::STDmaker generates it.
 ##
 ##

 #use ExtUtils::MakeMaker;

 #my $tests = join ' ',unix2os('t/SVDtest1.t');

 #WriteMakefile(
 #    NAME => 'SVDtest1',
 #    DISTNAME => 'SVDtest1',
 #    VERSION  => '0.01',
 #    dist     => {COMPRESS => 'gzip',
 #                'gz' => 'gz'},
 #    test     => {TESTS => $tests},
 #    PREREQ_PM => {'File::Basename' => 0},
 #    

 #    ($] >= 5.005 ?     
 #        (AUTHOR    => 'SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>',
 #        ABSTRACT  => 'Objectify the Test module,
 #adds the skip_test method to the Test module, and 
 #adds the ability to compare complex data structures to the Test module.', ) : ()),
 #);

 #use File::Spec;
 #use File::Spec::Unix;
 #sub unix2os
 #{
 #   my @file = ();
 #   foreach my $file (@_) {
 #       my (undef, $dir, $file_unix) = File::Spec::Unix->splitpath( $file );
 #       my @dir = File::Spec::Unix->splitdir( $dir );
 #       push @file, File::Spec->catfile( @dir, $file_unix);
 #   }
 #   @file;
 #}

 #'
 #

 ##################
 # generated Makefile.PL
 # 

 $s->scrub_date($snl->fin( File::Spec->catfile( 'packages', 'SVDtest1-0.01', 'README' ) ))

 # 'NAME
 #    ExtUtils::SVDmaker::SVDtest - Test SVDmaker

 #Title Page
 #     Software Version Description

 #     for

 #     ExtUtils::SVDmaker::SVDtest - Test SVDmaker

 #     Revision: -

 #     Version: 0.01

 #     Date: 1969/02/06

 #     Prepared for: General Public 

 #     Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 #     Copyright: copyright © 2003 Software Diamonds

 #     Classification: NONE

 #1.0 SCOPE
 #    This paragraph identifies and provides an overview of the released
 #    files.

 #  1.1 Identification

 #    This release, identified in 3.2, is a collection of Perl modules that
 #    extend the capabilities of the Perl language.

 #  1.2 System overview

 #    The ExtUtils::SVDmaker::SVDtest module is a SVDmaker test module.

 #  1.3 Document overview.

 #    This document releases SVDtest1 version 0.01 providing description of
 #    the inventory, installation instructions and other information necessary
 #    to utilize and track this release.

 #3.0 VERSION DESCRIPTION
 #    All file specifications in this SVD use the Unix operating system file
 #    specification.

 #  3.1 Inventory of materials released.

 #    This document releases the file

 #     SVDtest1-0.01.tar.gz

 #    found at the following repository(s):

 #      http://www.softwarediamonds/packages/
 #      http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

 #    Restrictions regarding duplication and license provisions are as
 #    follows:

 #    Copyright.
 #        copyright © 2003 Software Diamonds

 #    Copyright holder contact.
 #         603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

 #    License.
 #        Software Diamonds permits the redistribution and use in source and
 #        binary forms, with or without modification, provided that the
 #        following conditions are met:

 #        1   Redistributions of source code, modified or unmodified must
 #            retain the above copyright notice, this list of conditions and
 #            the following disclaimer.

 #        2   Redistributions in binary form must reproduce the above
 #            copyright notice, this list of conditions and the following
 #            disclaimer in the documentation and/or other materials provided
 #            with the distribution.

 #        SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com, PROVIDES THIS
 #        SOFTWARE 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 #        BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 #        FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 #        SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 #        SPECIAL,EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 #        LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 #        USE,DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 #        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 #        OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 #        NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE POSSIBILITY
 #        OF SUCH DAMAGE.

 #  3.2 Inventory of software contents

 #    The content of the released, compressed, archieve file, consists of the
 #    following files:

 #     file                                                         version date       comment
 #     ------------------------------------------------------------ ------- ---------- ------------------------
 #     lib/SVDtest1.pm                                              0.01    1969/02/06 new
 #     MANIFEST                                                     0.01    1969/02/06 generated new
 #     Makefile.PL                                                  0.01    1969/02/06 generated new
 #     README                                                       0.01    1969/02/06 generated new
 #     lib/SVDtest1.pm                                              0.01    1969/02/06 new
 #     lib/module1.pm                                               0.01    1969/02/06 new
 #     t/SVDtest1.t                                                 0.01    1969/02/06 new
 #     t/Test/Tech.pm                                               1.24    1969/02/06 new
 #     t/Data/Startup.pm                                            0.06    1969/02/06 new
 #     t/Data/Secs2.pm                                              1.22    1969/02/06 new
 #     t/Data/SecsPack.pm                                           0.07    1969/02/06 new
 #     t/File/Package.pm                                            1.17    1969/02/06 new

 #  3.3 Changes

 #    This is the original release. There are no preivious releases to change.

 #  3.4 Adaptation data.

 #    This installation requires that the installation site has the Perl
 #    programming language installed. There are no other additional
 #    requirements or tailoring needed of configurations files, adaptation
 #    data or other software needed for this installation particular to any
 #    installation site.

 #  3.5 Related documents.

 #    There are no related documents needed for the installation and test of
 #    this release.

 #  3.6 Installation instructions.

 #    Instructions for installation, installation tests and installation
 #    support are as follows:

 #    Installation Instructions.
 #        To installed the release file, use the CPAN module in the Perl
 #        release or the INSTALL.PL script at the following web site:

 #         http://packages.SoftwareDiamonds.com

 #        Follow the instructions for the the chosen installation software.

 #        The distribution file is at the following respositories:

 #          http://www.softwarediamonds/packages/
 #          http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

 #    Prerequistes.
 #         'File::Basename' => 0

 #    Security, privacy, or safety precautions.
 #        None.

 #    Installation Tests.
 #        Most Perl installation software will run the following test
 #        script(s) as part of the installation:

 #         t/SVDtest1.t

 #    Installation support.
 #        If there are installation problems or questions with the
 #        installation contact

 #         603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

 #  3.7 Possible problems and known errors

 #    There are no open issues.

 #4.0 NOTES
 #    The following are useful acronyms:

 #    .d  extension for a Perl demo script file

 #    .pm extension for a Perl Library Module

 #    .t  extension for a Perl test script file

 #    DID Data Item Description

 #    POD Plain Old Documentation

 #    STD Software Test Description

 #    SVD Software Version Description

 #2.0 SEE ALSO
 #    ExtUtils::SVDmake
 #'
 #

 ##################
 # generated README
 # 

 $s->scrub_architect($s->scrub_date($snl->fin( File::Spec->catfile( 'packages', 'SVDtest1.ppd' ) )))

 # '<SOFTPKG NAME="SVDtest1" VERSION="0,01,0,0">
 #	<TITLE>SVDtest1</TITLE>
 #	<ABSTRACT>Objectify the Test module,
 #adds the skip_test method to the Test module, and 
 #adds the ability to compare complex data structures to the Test module.</ABSTRACT>
 #	<AUTHOR>SoftwareDiamonds.com E&lt;lt&gt;support@SoftwareDiamonds.comE&lt;gt&gt;</AUTHOR>
 #	<IMPLEMENTATION>
 #		<DEPENDENCY NAME="File::Basename" VERSION="0,0,0,0" />
 #		<OS NAME="MSWin32" />
 #		<ARCHITECTURE NAME="Perl" />
 #		<CODEBASE HREF="SVDtest1-0.01.tar.gz" />
 #	</IMPLEMENTATION>
 #</SOFTPKG>
 #'
 #

 ##################
 # generated ppd
 # 

 -e File::Spec->catfile( 'packages', 'SVDtest1-0.01.tar.gz' )

 # '1'
 #

 ##################
 # generated distribution
 # 

     #####
     # Clean up
     #
     unlink 'SVDtest1.log';
     unlink File::Spec->catfile('lib','SVDtest1.pm'),File::Spec->catfile('lib', 'module1.pm');
     rmtree 'packages';
     rmtree 't';

=head1 QUALITY ASSURANCE

The modules C<t::ExtUtils::SVDmaker::Original> and
C<t::ExtUtils::SVDmaker::Revise>
are the Software
Test Description(STD) programs modules for the "ExtUtils::SVDmaker".
program module and package found in the distribution file
for C<ExtUtils::SVDmaker>. 

To generate all the test output files, 
run the generated test script, and
run the demonstration script,
execute the following in any directory in any order:

 tmake.pl -verbose -demo -run -pm=t::ExtUtils::SVDmaker::Original
 tmake.pl -verbose -run -pm=t::ExtUtils::SVDmaker::Revise

Note that F<tmake.pl> must be in the execution path C<$ENV{PATH}>,
the "t" directory on the same level as the "lib" that
contains the C<ExtUtils::SVDmaker> module, and
the C<Test::STDmaker> package must be present.
The C<tmake.pl> script is in the distribution file
for L<Test::STDmaker||Test::STDmaker>.

The C<tmake.pl> script will create the C<Original.t> and C<Revise.t> test
scripts and the C<Original.d> and C<Revise.d> demo scripts in
the same directory as the program modules which may
be individually ran by the C<Perl> command.

The Perl standard installation of the C<ExtUtils::SVDmaker> will
automatically run the test scripts C<Original.t> and C<Revise.t>
generated by F<tmake.pl> for the distribution file.

=head1 NOTES

=head2 COPYRIGHT HOLDER

The holder of the copyright and maintainer is

 E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

copyright © 2003 Software Diamonds.

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

=back

SOFTWARE DIAMONDS PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head1 SEE ALSO

=over 4 

=item L<Test::STDmaker|Test::STDmaker>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>

=item L<Tie::Form|Tie::Form>

=item L<Tie::Layers|Tie::Layers>

=item L<Test::Tech|Test::Tech> 

=item L<File::FileUtil|File::FileUtil>

=item L<Test::STD::TestUtil|Test::STD::TestUtil>

=item L<US DOD Software Development Standard|Docs::US_DOD::STD2167A>

=item L<US DOD Specification Practices|Docs::US_DOD::STD490A>

=item L<Software Version Description (SVD) DID|Docs::US_DOD::SVD>

=item L<Version Description Document (VDD) DID|Docs::US_DOD::VDD>

=back

=cut


#######
## E N D   O F   F I L E
#######

