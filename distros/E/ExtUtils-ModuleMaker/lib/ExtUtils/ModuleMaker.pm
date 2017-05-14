#!/usr/local/bin/perl

package ExtUtils::ModuleMaker;
use strict;
use ExtUtils::ModuleMaker::Licenses;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK);
	$VERSION = "0.204";
	@ISA		= qw (Exporter);
	@EXPORT		= qw (&Generate_Module_Files &Quick_Module);
	@EXPORT_OK	= qw ();
}

########################################### main pod documentation begin ##

=head1 NAME

ExtUtils::ModuleMaker - A simple replacement for h2xs -XA

=head1 SYNOPSIS

h2xs can be used for pure perl modules using the -XA flags.  But it has many annoying features.
ExtUtils::ModuleMaker is designed to bring module templates into the 21st Century.

In the simplest case it can be used from the command line as

	perl -MExtUtils::ModuleMaker -e "Quick_Module ('Sample::Module::Foo')"

=head1 DESCRIPTION

This module is a replacement for h2xs.  It can be used from the command line with just a module
name, similar to h2xs, or can be called from a Modulefile.PL similar to calling MakeMaker from
Makefile.PL.

=head1 USAGE

  use ExtUtils::ModuleMaker;

  Generate_Module_Files (
                         NAME     => 'Sample::Module::Foo',
                         ABSTRACT => 'a sample module',
                         AUTHOR   => {NAME    => 'A. U. Thor',
                                      EMAIL   => 'a.u.thor@a.galaxy.far.far.away',
                                      CPANID  => 'AUTHOR',
                                      WEBSITE => 'http://a.galaxy.far.far.away/modules',
                                     },
                         VERSION  => 0.01,
                         LICENSE  => 'perl',
                         EXTRA_MODULES=> [
                                          {
                                           NAME     => 'Sample::Module::Bar',
                                           ABSTRACT => 'a second module',
                                          },
                                          {
                                           NAME     => 'Sample::Baz',
                                           ABSTRACT => 'a third module',
                                          },
                                         ],
  );

=head1 BUGS

Still only supports the simple perl only modules, not things with XS components.

=head1 SUPPORT

Send email to modulemaker@PlatypiVentures.com.

=head1 AUTHOR

    R. Geoffrey Avery
    CPAN ID: RGEOFFREY
    modulemaker@PlatypiVentures.com
    http://www.PlatypiVentures.com/perl/modules/ModuleMaker.shtml

=head1 COPYRIGHT

Copyright (c) 2001-2002 R. Geoffrey Avery. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

h2xs, ExtUtils::MakeMaker

=head1 PUBLIC METHODS

Each public function/method is described here.
These are how you should interact with this module.

=cut

############################################# main pod documentation end ##

 
################################################ subroutine header begin ##

=head2 Quick_Module

 Usage     :
             perl -MExtUtils::ModuleMaker -e "Quick_Module ('Sample::Module')"
 or
             use ExtUtils::ModuleMaker;
             Quick_Module ('Sample::Module');

 Purpose   : Creates a Module.pm with supporing files
 Returns   : n/a
 Argument  : A name for the module, like 'Module' or 'Sample::Module'
 Throws    : 
 Comments  : More closely mimics h2xs behavior than Generate_Module_Files.
           : Included to allow simple creation from a command line.

See Also   : Generate_Module_Files

=cut

################################################## subroutine header end ##

sub Quick_Module
{
	&Generate_Module_Files (NAME => $_[0]);
}

################################################ subroutine header begin ##

=head2 Generate_Module_Files

 Usage     : How to use this function/method
 Purpose   : Creates one or more modules with supporing files
 Returns   : n/a
 Argument  : A hash with the information for the new module(s)
 Throws    : 
 Comments  : 

See Also   : Verify_Data, Create_Changes, Create_Makefile, Create_README,
           : Create_Module, Create_MANIFEST, Create_MANIFEST_SKIP,
           : Create_cvsignore

=over 4

=item NAME

The only required feature.  This is the name of the primary module (with '::' separators if needed).

=item ABSTRACT

A short description of the module, this will be passed on to MakeMaker through Makefile.PL.

=item VERSION

A real number to be the version number.  The default is 0.01.

=item LICENSE

Which license to include in the Copyright section.  You can choose one of the standard licenses by
including 'perl', 'gpl', 'artistic', and 18 others approved by opensource.org.
The default is to choose the 'perl' flavor which is to
share it "under the same terms as Perl itself".  Any other value is passed on directly so you
can have any license you want.

=over 4

=item LICENSE == 'custom'

When set to 'custom', you get the opportunity to specify exactly these fields...

=item COPYRIGHT 

Text to appear in the COPYRIGHT section of the pod

=item LICENSETEXT

The text for the LICENSE file

=back

=item AUTHOR

A hash contining information about the author to pass on to all the necessary places in the files.

=over 4

=item NAME

Name of the author.

=item EMAIL

Email address of the author.

=item CPANID

The CPANID of the author.  If this is omited, then the line will not be added to the documentation.

=item WEBSITE

The personal or organizational website of the author.

=back

=item EXTRA_MODULES

An array of hashes that each contain values for NAME and ABSTRACT.  Each extra module will be created in
the correct relative place in the B<lib> directory, but no extra supporting documents, like README or Changes.

This is one major improvement over the earlier B<h2xs> as you can now build multi module packages.

=item compact

For a module named "Foo::Bar::Baz" creates a base directory named "Foo-Bar-Baz"
instead of Foo/Bar/Baz.

=back

=cut

################################################## subroutine header end ##

sub Generate_Module_Files
{
	my (%module_data) = @_;

	&Verify_Data     (\%module_data);
	&Create_License  (\%module_data);

	&Check_Dir       ("$module_data{'Base_Dir'}/lib");
	&Check_Dir       ("$module_data{'Base_Dir'}/t");

	&Create_Changes  (\%module_data);
	&Create_Makefile (\%module_data);
	&Create_README   (\%module_data);

	&Create_MANIFEST_SKIP (\%module_data);
	&Create_cvsignore (\%module_data);

	&Create_Module   (\%module_data);
	foreach my $module (@{$module_data{'EXTRA_MODULES'}}) {
		$module_data{'NAME'}     = $module->{'NAME'};
		$module_data{'ABSTRACT'} = $module->{'ABSTRACT'};
		$module_data{'FILE'}     = join ('/', 'lib', split ('::', $module_data{'NAME'}));
		&Create_Module   (\%module_data);
	}

	&Create_MANIFEST (\%module_data);
}

########################################### main pod documentation begin ##

=head1 PRIVATE METHODS

Each private function/method is described here.
These methods and functions are considered private and are intended for
internal use by this module. They are B<not> considered part of the public
interface and are described here for documentation purposes only.

=cut

############################################# main pod documentation end ##

#Global Variables
use vars qw ($RAW_MODULE);
{
	local $/;
	$RAW_MODULE = <DATA>;
}

################################################ subroutine header begin ##

=head2 Verify_Data

 Usage     : 
 Purpose   : To fill in default values for unspecified features
 Returns   : n/a
 Argument  : pointer to hash of data for modules
 Throws    : 
 Comments  : 

See Also   : Create_Base_Directory

=cut

################################################## subroutine header end ##

sub Verify_Data
{
	my ($p_module_data) = @_;

	die "Must give a 'NAME' for the module\n" unless ($p_module_data->{'NAME'});

	$p_module_data->{'FILE'}     = join ('/', 'lib', split ('::', $p_module_data->{'NAME'}));
	$p_module_data->{'Base_Dir'} = &Create_Base_Directory ($p_module_data->{'NAME'},
							       $p_module_data->{compact});
	$p_module_data->{'Next_Test_Number'} = 1;
	$p_module_data->{'VERSION'} ||= 0.01;
	$p_module_data->{'ABSTRACT'} = '' unless (exists ($p_module_data->{'ABSTRACT'}));

	$p_module_data->{'AUTHOR'} = {} unless (ref ($p_module_data->{'AUTHOR'}) eq 'HASH');
	unless (exists ($p_module_data->{'AUTHOR'}{'NAME'})) {
		$p_module_data->{'AUTHOR'}{'NAME'}    = 'A. U. Thor';
		print "Using default value for {'AUTHOR'}{'NAME'}:\t'$p_module_data->{'AUTHOR'}{'NAME'}'\n";
	}
	unless (exists ($p_module_data->{'AUTHOR'}{'EMAIL'})) {
		$p_module_data->{'AUTHOR'}{'EMAIL'}   = 'a.u.thor@a.galaxy.far.far.away';
		print "Using default value for {'AUTHOR'}{'EMAIL'}:\t'$p_module_data->{'AUTHOR'}{'EMAIL'}'\n";
	}
	unless (exists ($p_module_data->{'AUTHOR'}{'CPANID'})) {
		$p_module_data->{'AUTHOR'}{'CPANID'}  = '';
		print "Using default value for {'AUTHOR'}{'CPANID'}:\t'$p_module_data->{'AUTHOR'}{'CPANID'}'\n";
	}
	unless (exists ($p_module_data->{'AUTHOR'}{'WEBSITE'})) {
		$p_module_data->{'AUTHOR'}{'WEBSITE'} = 'http://a.galaxy.far.far.away/modules';
		print "Using default value for {'AUTHOR'}{'WEBSITE'}:\t'$p_module_data->{'AUTHOR'}{'WEBSITE'}'\n";
	}

	&Get_License ($p_module_data);
}

################################################ subroutine header begin ##

=head2 Create_Base_Directory

 Usage     : 
 Purpose   :
             Create the directory where all the files will be created.
 Returns   :
             $DIR = directory name where the files will live
 Argument  :
             $package_name = name of module separated by '::'
 Throws    : 
 Comments  : 

See Also   : Check_Dir

=cut

################################################## subroutine header end ##

sub Create_Base_Directory
{
	my ($package_name, $compact) = @_;
	my ($DIR, @package);

	if ($compact) {
	    ($DIR = $package_name) =~ s/(::|\')/-/g;
	    print STDERR "creating compact directory for '$DIR'\n";
	    &Check_Dir ($DIR);
	} else {
	    ($DIR, @package) = split ('::', $package_name);

	    print STDERR "creating directory for '$DIR'\n";
	    &Check_Dir ($DIR);
	
	    foreach (@package) {
		$DIR = join ('/', $DIR, $_);
		print STDERR "creating directory for '$DIR'\n"; # if $VERBOSE
		&Check_Dir ($DIR);
	    }
	}

	return ($DIR);
}

################################################ subroutine header begin ##

=head2 Check_Dir

 Usage     :
             Check_Dir ($dir, $MODE);
 Purpose   :
             Creates a directory with the correct mode if needed.
 Returns   : n/a
 Argument  :
             $dir = directory name
             $MODE = mode of directory (e.g. 0777, 0755)
 Throws    : 
 Comments  : 

See Also   : 

=cut

################################################## subroutine header end ##

sub Check_Dir
{
	my($dir, $MODE) = @_;

	$MODE = 0770 unless ($MODE);
#	$MODE = 0770 if ($MODE eq "");
	if( ! ( -d $dir) ){
		mkdir($dir, $MODE);
		if( ! -d $dir ){
			print STDERR "I cannot create the Directory $dir.";
			exit (0);
		}
	}
	chmod ($MODE, $dir);
} # Check_Dir

################################################ subroutine header begin ##

=head2 Create_Makefile

 Usage     : Create_Makefile ($p_module_data);
 Purpose   : Write the Makefile.PL file
 Returns   : n/a
 Argument  : $p_module_data = hash with all the data
 Throws    : 
 Comments  : 

See Also   : 

=cut

################################################## subroutine header end ##

sub Create_Makefile
{
	my ($p_module_data) = @_;

	push (@{$p_module_data->{'MANIFEST'}}, 'Makefile.PL');

	open (FILE, ">$p_module_data->{'Base_Dir'}/Makefile.PL") or die "Could not write Makefile.PL, $!";

print FILE <<EOFF;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => '$p_module_data->{'NAME'}',
    VERSION_FROM => '$p_module_data->{'FILE'}.pm', # finds \$VERSION
    AUTHOR       => '$p_module_data->{'AUTHOR'}{'NAME'} ($p_module_data->{'AUTHOR'}{'EMAIL'})',
    ABSTRACT     => '$p_module_data->{'ABSTRACT'}'
);
EOFF

	close FILE;
}

################################################ subroutine header begin ##

=head2 Create_Changes

 Usage     : Create_Changes ($p_module_data);
 Purpose   : 
 Returns   : n/a
 Argument  : $p_module_data = hash with all the data
 Throws    : 
 Comments  : 

See Also   : 

=cut

################################################## subroutine header end ##

sub Create_Changes
{
	my ($p_module_data) = @_;

	push (@{$p_module_data->{'MANIFEST'}}, 'Changes');

	my @thetime = localtime ();
	open (FILE, ">$p_module_data->{'Base_Dir'}/Changes") or die "Could not write Changes, $!";
	print FILE ("Revision history for Perl extension $p_module_data->{'NAME'}.\n\n$p_module_data->{'VERSION'}  ",
				sprintf ("%s %s %02d %02d:%02d:%02d %04d",
						 ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')[$thetime[6]],
						 ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
						  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')[$thetime[4]],
						 $thetime[3],
						 $thetime[2], $thetime[1], $thetime[0],
						 (1900 + $thetime[5])),
				"\n\t- original version; created by ExtUtils::ModuleMaker $VERSION\n\n");
	close FILE;
}

################################################ subroutine header begin ##

=head2 Create_License

 Usage     : Create_License ($p_module_data);
 Purpose   : 
 Returns   : n/a
 Argument  : $p_module_data = hash with all the data
 Throws    : 
 Comments  : 

See Also   : 

=cut

################################################## subroutine header end ##

sub Create_License
{
	my ($p_module_data) = @_;

	push (@{$p_module_data->{'MANIFEST'}}, 'LICENSE');

	open (FILE, ">$p_module_data->{'Base_Dir'}/LICENSE") or die "Could not write LICENSE, $!";
	print FILE ($p_module_data->{'LICENSETEXT'});
	close FILE;
}

################################################ subroutine header begin ##

=head2 Create_MANIFEST

 Usage     : Create_MANIFEST ($p_module_data);
 Purpose   : 
 Returns   : n/a
 Argument  : $p_module_data = hash with all the data
 Throws    : 
 Comments  : 

See Also   : 

=cut

################################################## subroutine header end ##

sub Create_MANIFEST
{
	my ($p_module_data) = @_;

	push (@{$p_module_data->{'MANIFEST'}}, 'MANIFEST');

	open (FILE, ">$p_module_data->{'Base_Dir'}/MANIFEST") or die "Could not write MANIFEST, $!";
	print FILE join ("\n", @{$p_module_data->{'MANIFEST'}});
	close FILE;
}

################################################ subroutine header begin ##

=head2 Create_README

 Usage     : Create_README ($p_module_data);
 Purpose   : 
 Returns   : n/a
 Argument  : $p_module_data = hash with all the data
 Throws    : 
 Comments  : 

See Also   : 

=cut

################################################## subroutine header end ##

sub Create_README
{
	my ($p_module_data) = @_;

	push (@{$p_module_data->{'MANIFEST'}}, 'README');

	open (FILE, ">$p_module_data->{'Base_Dir'}/README") or die "Could not write README, $!";
print FILE <<EOF;
pod2text $p_module_data->{'FILE'}.pm > README

If this is still here it means the programmer was too lazy to create the readme file.

You can create it now by using the command shown above from this directory.
EOF

	close FILE;
}

################################################ subroutine header begin ##

=head2 Create_MANIFEST_SKIP

 Usage     : Create_MANIFEST_SKIP ($p_module_data);
 Purpose   : Writes MANIFEST.SKIP which prevents the following tagets
             `make install` and `make dist` from using distribution files,
             editor backups, revision control (CVS & RCS) and dynamically-
             created MakeMaker files & directories.
 Returns   : n/a
 Argument  : $p_module_data = hash with all the data
 Throws    :
 Comments  :
 Author    : joshua@cpan.org

The regular expressions, explained:

=over 4

=item ^Makefile$ - created by `perl Makefile.PL`

=item ^blib/ - created by `make`

=item ^Makefile\.[a-z]+$ - ignores `Makefile.old`

=item ^pm_to_blib$ - created by `make`

=item CVS/.* - CVS stores working dir info in the CVS directory

=item ,v$ - RCS files

=item ^te?mp/ - Temporary directory

=item \.old$ - Makefile gets renamed to Makefile.old each time you `make`

=item \.bak$ - Backup files

=item ~$ - Editor-created file backup

=item ^# - Editor-created file backup

=item \.shar$ - `make shardist` distribution

=item \.tar$ - `make tardist` distribution

=item \.tgz$ - `make dist` distribution

=item \.tar\.gz$ - `make dist` distribution

=item \.zip$ - `make zipdist` distribution

=item _uu$ - `make uutardist` distribution

=back

=cut

################################################## subroutine header end ##

sub Create_MANIFEST_SKIP {
	my ($p_module_data) = @_;

	push (@{$p_module_data->{'MANIFEST'}}, 'MANIFEST.SKIP');

	open (FILE, "> $p_module_data->{'Base_Dir'}/MANIFEST.SKIP")
	    or die "Could not write MANIFEST.SKIP, $!";

print FILE <<'EOF';
^blib/
^Makefile$
^Makefile\.[a-z]+$
^pm_to_blib$
CVS/.*
,v$
^tmp/
\.old$
\.bak$
~$
^#
\.shar$
\.tar$
\.tgz$
\.tar\.gz$
\.zip$
_uu$
EOF
	close FILE;
}


################################################ subroutine header begin ##

=head2 Create_cvsignore

 Usage     : Create_cvsignore ($p_module_data);
 Purpose   : Writes .cvsignore. Prevents MakeMaker's dynamically-
             created files from getting checked into CVS (or listed
             during `cvs update`.
 Returns   : n/a
 Argument  : $p_module_data = hash with all the data
 Throws    :
 Comments  :
 Author    : joshua@cpan.org

See Also   :

=cut

################################################## subroutine header end ##

sub Create_cvsignore {
	my ($p_module_data) = @_;

	push (@{$p_module_data->{'MANIFEST'}}, '.cvsignore');

	open (FILE, "> $p_module_data->{'Base_Dir'}/.cvsignore")
	    or die "Could not write .cvsignore, $!";

print FILE <<EOF;
blib
Makefile
pm_to_blib
EOF

	close FILE;
}



################################################ subroutine header begin ##

=head2 Create_Module

 Usage     : 
 Purpose   : 
 Returns   : 
 Argument  : 
 Throws    : 
 Comments  : 

See Also   : 

=cut

################################################## subroutine header end ##

sub Create_Module
{
	my ($p_module_data) = @_;

	my $DIR = $p_module_data->{'Base_Dir'};
	my @package = split ('/', $p_module_data->{'FILE'});
	my $file = pop (@package);

	foreach (@package) {
		$DIR .= '/' . $_;
		print STDERR "creating directory for '$DIR'\n";
		&Check_Dir ($DIR);
	}

	my $string = $RAW_MODULE;

	$string =~ s/##-##PACKAGE_NAME##-##/$p_module_data->{'NAME'}/g;
	$string =~ s/##-##ABSTRACT##-##/$p_module_data->{'ABSTRACT'}/;
	$string =~ s/##-##VERSION##-##/$p_module_data->{'VERSION'}/;
	$string =~ s/##-##COPYRIGHT##-##/$p_module_data->{'COPYRIGHT'}/;
	$string =~ s/\n ====/\n=/g;

	my $author = join ("\n\t",
					   $p_module_data->{'AUTHOR'}{'NAME'},
					   ($p_module_data->{'AUTHOR'}{'CPANID'})
						   ? "CPAN ID: $p_module_data->{'AUTHOR'}{'CPANID'}" : (),
					   $p_module_data->{'AUTHOR'}{'EMAIL'},
					   $p_module_data->{'AUTHOR'}{'WEBSITE'},
					  );
	$string =~ s/##-##AUTHOR##-##/$author/;

	push (@{$p_module_data->{'MANIFEST'}}, "$p_module_data->{'FILE'}.pm");

	open (FILE, ">$p_module_data->{'Base_Dir'}/$p_module_data->{'FILE'}.pm") or
			die "Could not write $p_module_data->{'FILE'}.pm, $!";
	print FILE $string;
	close FILE;

	&Create_Test_Init ($p_module_data);
}

################################################ subroutine header begin ##

=head2 Create_Test_Init

 Usage     : 
 Purpose   : 
 Returns   : 
 Argument  : 
 Throws    : 
 Comments  : 

See Also   : 

=cut

################################################## subroutine header end ##

 sub Create_Test_Init
{
	my ($p_module_data) = @_;

	my $test_name = sprintf ("t/%02d_ini.t", $p_module_data->{'Next_Test_Number'}++);
	push (@{$p_module_data->{'MANIFEST'}}, $test_name);

	open (FILE, ">$p_module_data->{'Base_Dir'}/$test_name") or die "Could not write $test_name, $!";
print FILE <<EOF;
# $test_name; just to load $p_module_data->{'NAME'} by using it

\$|++; 
print "1..1\n";
my(\$test) = 1;

# 1 load
use $p_module_data->{'NAME'};
my(\$loaded) = 1;
\$loaded ? print "ok \$test\n" : print "not ok \$test\n";
\$test++;

# end of $test_name

EOF

	close FILE;
}

###########################################################################
###########################################################################

1;

__DATA__

package ##-##PACKAGE_NAME##-##;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = ##-##VERSION##-##;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!

 ====head1 NAME

##-##PACKAGE_NAME##-## - ##-##ABSTRACT##-##

 ====head1 SYNOPSIS

  use ##-##PACKAGE_NAME##-##;
  blah blah blah

 ====head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.

 ====head1 USAGE

 ====head1 BUGS

 ====head1 SUPPORT

 ====head1 AUTHOR

	##-##AUTHOR##-##

 ====head1 COPYRIGHT

##-##COPYRIGHT##-##
 ====head1 SEE ALSO

perl(1).

 ====head1 PUBLIC METHODS

Each public function/method is described here.
These are how you should interact with this module.

 ====cut

############################################# main pod documentation end ##


# Public methods and functions go here. 



########################################### main pod documentation begin ##

 ====head1 PRIVATE METHODS

Each private function/method is described here.
These methods and functions are considered private and are intended for
internal use by this module. They are B<not> considered part of the public
interface and are described here for documentation purposes only.

 ====cut

############################################# main pod documentation end ##


# Private methods and functions go here.





################################################ subroutine header begin ##

 ====head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comments  : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   : 

 ====cut

################################################## subroutine header end ##




1; #this line is important and will help the module return a true value
__END__


