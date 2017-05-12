package FreeBSD::Pkgs;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

FreeBSD::Pkgs - Reads the FreeBSD installed packaged DB.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';


=head1 SYNOPSIS

The following example prints out the package information.


    use FreeBSD::Pkgs;
    
    $pkgdb=FreeBSD::Pkgs->new;
    
    $pkgdb->parseInstalled;
    
    while(my ($name, $pkg) = each %{$pkgdb->{packages}}){
    	print $name."\nComment=".$pkg->{comment}."\n";
    
    	#prints the packages that require it
    	if (defined($pkg->{requiredby})){
    		my $requiredbyInt=0;
    		while (defined($pkg->{requiredby}[$requiredbyInt])){
    			print $name." required by ".$pkg->{requiredby}[$requiredbyInt]."\n";
    			$requiredbyInt++;
    		}
    	}
    
    	#if the extract-in-place option is set, print it
    	if (defined($pkg->{contents}{extract-in-place})){
    		print $name." is set to extract in place\n";
    	}
    
    	#if the extract-in-place option is set, print it
    	if (defined($pkg->{contents}{preserve})){
    		print $name." is set to preserve the old file\n";
    	}
    
    	#print the mtree
    	if (defined($pkg->{contents}{mtree})){
    		print $name." the mtree for this package is '".$pkg->{contents}{mtree}."'\n";
    	}
    
    	#print installed files and associated info
    	if (defined($pkg->{contents}{files})){
    		my @files=keys(%{$pkg->{contents}{files}});
    		my $filesInt=0;
    		while (defined($files[$filesInt])){
    			print $name." installs ".$files[$filesInt]." md5='".
    			$pkg->{contents}{files}{$files[$filesInt]}{MD5}."' ";
    			#prints the the group if there is a specific one for the file
    			if (defined($pkg->{contents}{files}{$files[$filesInt]}{group})) {
    				print " group='".$pkg->{contents}{files}{$files[$filesInt]}{group}."'";
    			}
    			#prints the the user if there is a specific one for the file
    			if (defined($pkg->{contents}{files}{$files[$filesInt]}{user})) {
    				print " user='".$pkg->{contents}{files}{$files[$filesInt]}{user}."'";
    			}
    			#prints the the mode if there is a specific one for the file
    			if (defined($pkg->{contents}{files}{$mfiles[$filesInt]}{mode})) {
    				print " mode='".$pkg->{contents}{files}{$files[$filesInt]}{mode}."'";
    			}
    			#prints the directory if it is not relative to the base
    			if (defined($pkg->{contents}{files}{$mfiles[$filesInt]}{cwd})) {
    				print " cwd='".$pkg->{contents}{files}{$files[$filesInt]}{cwd}."'";
    			}
    			#print if the file is set to be ignored
    			if (defined($pkg->{contents}{files}{$mfiles[$filesInt]}{ignore})) {
    				print " ignore='".$pkg->{contents}{files}{$files[$filesInt]}{ignore}."'";
    			}
    			#print if the file is set to be ignored
    			if (defined($pkg->{contents}{files}{$mfiles[$filesInt]}{ignore_inst})) {
    				print " ignore_inst='".$pkg->{contents}{files}{$files[$filesInt]}{ignore_inst}."'";
    			}
    			print "\n";
    			$filesInt++;
    		}
    	}
    
    	#prints the conflict information
    	my $conflictInt=0;
    	while (defined($pkg->{contents}{conflict}[$conflictInt])){
    		print $name." conflicts with ".$pkg->{contents}{conflict}[$conflictInt]."\n";
    		$conflictInt++;
    	}
    
    	#print dirrm stuff
    	my $dirrmInt=0;
    	while (defined($pkg->{contents}{dirrm}[$dirrmInt])){
    		print $name." conflicts with ".$pkg->{contents}{dirrm}[$dirrmInt]."\n";
    		$dirrmInt++;
    	}
    
    	print "\n";
    }

=head1 FUNCTIONS

=head2 new

    #creates a new object with the default settings
    my $pkgdb=FreeBSD::Pkgs->new;

    #creates a new package with the a specified pkgdb dir
    my $pkgdb=FreeBSD::Pkgs->new({pkgdb=>'/var/db/pkg'});

    #if this is true there is a error
    if($pkgdb->error){
        warn('Error:'.$pkgdb->error.': '.$pkgdb->errorString);
    }

=head3 arguement keys

=over

=item pkgdb

If this key is defined, it uses this dir to use for the package db.

The same environmental variables as used by the package tools are respected.

=back

=cut

sub new{
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	#blesses it and inits the hash
	my $self={
		packages=>{}, 
		error=>undef,
		errorString=>'',
	};
	bless $self;

	#figures out what to use for pkgdb
	if (!defined($args{pkgdb})){
		if (!defined($ENV{PKG_DBDIR})) {
			$self->{pkgdb}='/var/db/pkg/';
		}else{
			$self->{pkgdb}=$ENV{PKG_DBDIR};
		}
	}else{
		$self->{pkgdb}=$args{pkgdb};
	}

#	#makes sure it exists
#	if (! -e $args{pkgdb}){
#		warn("FreeBSD-Pkgs:1: PKG_DBDIR, '".$args{pkgdb}."' does not exist");
#		$self->{error}='1';
#		return $self;
#	}

#	#reads the packages
#	if (opendir(PKGDBDIR, $args{pkgdb})){
#		warn("FreeBSD-Pkgs:2: Could not open PKG_DBDIR, '".$args{pkgdb}."',");
#		exit 2;
#	}
#	my @packages=readdir(PKGDBDIR);
#	closedir(PKGDBDIR);

#	#removes directories that start with '.'
#	@packages=grep(/^\./, @packages);

#	#processes them all
#	my @packagesInt=0;
#	while (defined($packages[$packagesInt])){
#		#only process it if it is a directory
#		if (-d $args{pkgdb}.'/'.$packages[$packagesInt]){
#			my %returned=$self->paseInstalledPkg($packages[$packagesInt]);
#			#only add it if it is not an error
#			if (!defined($self->{error})) {
#				$self->{packages}{$packages[$packagesInt]}=%returned;
#			}else{
#				warn('FreeBSD-Pkgs:3: Parsing "'.$packages[$packagesInt].'" as failed.');
#			}
#		}else{
#			#non-fatal
#			warn('FreeBSD-Pkgs:3: Skipping "'.$packages[$packagesInt].'" as it is not a directory');
#		}
#	}

	return $self;
}

=head2 parseContents

This parses the '+CONTENTS' file for a package. The only required is a
string containing the contents of the file to be parsed.

=head3 args hash

=head4 files

A boolean controlling if file information is parsed or not.

    my %contents=$pkgdb->parseContents($contentString, %args);
    if($pkgdb->error){
        warn('Error:'.$pkgdb->error.': '.$pkgdb->errorString);
    }

=cut

sub parseContents{
	my $self=$_[0];
	my $contents=$_[1];
	my %args;
	if (defined($_[2])) {
		%args=%{$_[2]};
	}

	if ( ! $self->errorblank ){
		return undef;
	}

	#process the file info unless told to do otherwise
	if (!defined($args{file})) {
		$args{file}=1;
	}

	#splits the contents at every new line
	my @contentsA=split(/\n/, $contents);

	my %hash;

	my $contentsAint=0;

	#holds the the last line matching /^\@pkgdep/
	my $pkgdep=undef;

	#holds the last file
	my $file=undef;
		
	#defined if a file has a specific mode
	my $mode=undef;

	#defined if a file has a specific group
	my $group=undef;

	#defined if a file has a specific user
	my $user=undef;

	#holds any second cwds that pop up
	my $cwd=undef;

	#if this is set to true, the ignore flag is set on a file
	my $ignore=undef;

	#if this is set to true, the ignore_inst flag is set on a file
	my $ignore_inst=undef;

	#process it
	while (defined($contentsA[$contentsAint])){
		my $line=$contentsA[$contentsAint];
		chomp($line);

		#set to true if matched... used for checking at the end of this loop
		my $matched=undef;

		#handles it if the PKG_FORMAT_REVISION
		if ($line =~ /^\@comment PKG_FORMAT_REVISION:/){
			$line =~ s/^\@comment PKG_FORMAT_REVISION://;
			$hash{PKG_FORMAT_REVISION}=$line;

			goto contentsParseLoopEnd;
		}

		#handles it if it is the name line
		if ($line =~ /^\@name / ){
			$line =~ s/^\@name //;
			$hash{name}=$line;

			goto contentsParseLoopEnd;
		}
		
		#handles ignore lines
		if ($args{file}) {
			if ($line =~ /^\@ignore/ ){
				$line =~ s/^\@ignore//;
				$ignore=1;
				
				goto contentsParseLoopEnd;
			}
		}else {
			goto contentsParseLoopEnd;
		}

		#handles ignore lines
		if ($line =~ /^\@srcdir / ){
			$line =~ s/^\@srcdir //;
			$hash{srcdir}=$line;

			goto contentsParseLoopEnd;
		}

		#handles ignore_inst lines
		if ($line =~ /^\@ignore_inst/ ){
			$line =~ s/^\@ignore_inst//;
			$ignore_inst=1;

			goto contentsParseLoopEnd;
		}

		#handles it if origin line
		if ($line =~ /^\@comment ORIGIN:/){
			$line =~ s/^\@comment ORIGIN://;
			$hash{origin}=$line;

			goto contentsParseLoopEnd;
		}

		#extract-in-place options
		if ($line =~ /^\@option extract-in-place/){
			$line =~ s/^\@option extract-in-place//;
			$hash{'extract-in-place'}=1;

			goto contentsParseLoopEnd;
		}

		#extract-in-place option
		if ($line =~ /^\@option preserve/){
			$line =~ s/^\@option preserve//;
			$hash{preserve}=1;

			goto contentsParseLoopEnd;
		}

		#handles it if base dir line
		if ($line =~ /^\@cwd /){
			$line =~ s/^\@cwd //;
			if (!defined($hash{cwd})){
				$hash{cwd}=$line;
			}else {
				if ($hash{cwd} eq $line){
					$cwd=undef;
				}else{
					$cwd=$line;
				}
			}

			goto contentsParseLoopEnd;
		}

		if ($args{file}){
			#handles it group lines
			if ($line =~ /^\@group/){
				$line =~ s/^\@group//;
				
				#remove any spaces at the beginning
				$line =~ s/^\ *//;
				
				if ($line eq "") {
					$group=undef;
				}else{
					$group=$line;
				}
				
				goto contentsParseLoopEnd;
			}

			#handles it mode lines
			if ($line =~ /^\@mode/){
				$line =~ s/^\@mode//;
				
				#remove any spaces at the beginning
				$line =~ s/^\ *//;
				
				if ($line eq "") {
					$mode=undef;
				}else{
					$mode=$line;
				}
				
				goto contentsParseLoopEnd;
			}
		}
		#handles it if metree line
		if ($line =~ /^\@mtree /){
			$line =~ s/^\@mtree //;
			#it should only be defined once
			if (!defined($hash{mtree})){
				$hash{mtree}=$line;
			}

			goto contentsParseLoopEnd;
		}

		#handles it if dependency line
		if ($line =~ /^\@pkgdep /){
			$line =~ s/^\@pkgdep //;

			$pkgdep=$line;

			#creates the dep hash if it already exists
			if (!defined($hash{deps})) {
				$hash{deps}={};
			}

			#sets up the depdency hash
			$hash{deps}{$line}={};

			goto contentsParseLoopEnd;
		}

		#handles it if line describing the origin of a dependency
		if ($line =~ /^\@comment DEPORIGIN:/){
			if (!defined($pkgdep)){
				if (defined($hash{name})){
					$self->warnString('A line matching /^\@comment DEPORIGIN:/'.
						 ' was found, but no previous package dependencies were found. Line="'.
						 $line.'" name="'.$hash{name}.'"');
				}else {
					$self->warnString('A line matching /^\@comment DEPORIGIN:/'.
						 ' was found, but no previous package dependencies were found. Line="'.
						 $line.'"');
				}
			}

			$line =~ s/^\@comment DEPORIGIN://;

			$hash{deps}{$pkgdep}{origin}=$line;

			goto contentsParseLoopEnd;
		}

		#handles it if it is a file
		if ($args{file}) {
			if ($line !~ /^\@/){
				if (!defined($hash{files})){
					$hash{files}={};
				}
				
				$file=$line;
				
				$hash{files}{$line}={};
				
				#if a specific group is set, set it for the group
				if (defined($group)){
					$hash{files}{$line}{group}=$group;
				}

				#if a specific user is set, set it for the group
				if (defined($user)){
					$hash{files}{$line}{user}=$user;
				}

				#if a specific mode is set, set it for the file
				if (defined($mode)){
					$hash{files}{$line}{mode}=$mode;
				}
				
				#sets the ignore flag on a file if it is defined
				if ($ignore){
					$hash{files}{$line}{ignore}=1;
					$ignore=undef;
				}

				#sets the ignore_inst flag on a file if it is defined
				if ($ignore){
					$hash{files}{$line}{ignore_inst}=1;
					$ignore_inst=undef;
				}

				#adds the directory for the file if it is not in the base
				if (defined($cwd)){
					$hash{files}{$line}{cwd}=$cwd;
				}
				
				goto contentsParseLoopEnd;
			}
		}else {
			goto contentsParseLoopEnd;
		}

		#handles a line if it is describing a MD5 of a file
		if ($args{file}) {
			if ($line =~ /^\@comment MD5:/){
				if (!defined($file)){
					if (defined($hash{name})){
						$self->warnString('A line matching /^\@comment MD5:/'.
							 ' was found, but no previous files were found. Line="'.
							 $line.'" name="'.$hash{name}.'"');
					}else {
						$self->warnString('A line matching /^\@comment MD5:/'.
							 ' was found, but no previous files were found. Line="'.$line.'"');
					}
				}

				$line =~ s/^\@comment DEPORIGIN://;
				
				$hash{files}{$file}{MD5}=$line;
				
				goto contentsParseLoopEnd;
			}
		}else {
			goto contentsParseLoopEnd;
		}

		#handles unexec lines
		if ($line =~ /^\@unexec /){
			$line =~ s/^\@unexec //;

			if (!defined($hash{unexec})) {
				$hash{unexec}=[];
			}
			
			push(@{$hash{unexec}}, $line);
			
			goto contentsParseLoopEnd;
		}

		#handles exec lines
		if ($line =~ /^\@exec /){
			$line =~ s/^\@exec //;

			if (!defined($hash{exec})) {
				$hash{exec}=[];
			}
			
			push(@{$hash{exexec}}, $line);
			
			goto contentsParseLoopEnd;
		}

		#handles unexec lines
		if ($line =~ /^\@dirrm /){
			$line =~ s/^\@dirrm //;

			if (!defined($hash{dirrm})) {
				$hash{dirrm}=[];
			}
			
			push(@{$hash{dirrm}}, $line);
			
			goto contentsParseLoopEnd;
		}

		#handles display lines
		if ($line =~ /^\@display /){
			$line =~ s/^\@display //;

			if (!defined($hash{display})) {
				$hash{display}=[];
			}
			
			push(@{$hash{display}}, $line);
			
			goto contentsParseLoopEnd;
		}

		#handles conflict lines
		if ($line =~ /^\@conflicts /){
			$line =~ s/^\@conflicts //;

			if (!defined($hash{conflict})) {
				$hash{conflict}=[];
			}
			
			push(@{$hash{conflict}}, $line);
			
			goto contentsParseLoopEnd;
		}

		#handles generic comments
		if ($line =~ /^\@comment /){
			$line =~ s/^\@comment //;

			if (!defined($hash{comment})) {
				$hash{comment}=[];
			}
			
			push(@{$hash{comment}}, $line);
			
			goto contentsParseLoopEnd;
		}

		#if we reach this it means the line was not matched
		if (defined($hash{name})){
			warn('FreeBSD-Pkgs parseContents:10: Unmatched line. line="'.$line.
				 '" name="'.$hash{name}.'"');
		}else{
			warn('FreeBSD-Pkgs parseContents:10: Unmatched line. line="'.$line.
				 '"');			
		}

		#where using a goto here to simplify checking and speed it up a bit
		contentsParseLoopEnd:

		$contentsAint++;
	}

	return %hash;
}

=head2 parseInstalled

This reads all installed packages. The returned value is a boolean.

=head3 args hash

=head4 files

A boolean controlling if file information is parsed or not.

This will be passed to parseInstalledPkg and then parseContents.

    $pkgdb->parseInstalled(%args);
    #checks to see if it completed successfully
    if($pkgdb->{error}){
        print 'Error: '.$pkgdb->{error}."\n";
    }

    #checks to make sure it completed successfully using a if statement
    if($pkgdb->parseInstalled(%args)){
        print 'Error: '.$pkgdb->{error}."\n";
    }

=cut

sub parseInstalled{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	if ( ! $self->errorblank ){
		return undef;
	}

	#makes sure it exists
	if (! -e $self->{pkgdb}){
		$self->{errorString}="PKG_DBDIR, '".$self->{pkgdb}."' does not exist";
		$self->{error}='1';
		$self->warn;
		return undef;
	}

	#reads the packages
	if (!opendir(PKGDBDIR, $self->{pkgdb})){
		$self->{errorString}="Could not open PKG_DBDIR, '".$self->{pkgdb}."',";
		$self->{error}=2;
		$self->warn;
		return undef;
	}
	my @packages=readdir(PKGDBDIR);
	closedir(PKGDBDIR);

	#removes directories that start with '.'
	@packages=grep(!/^\./, @packages);

	#processes them all
	my $packagesInt=0;
	while (defined($packages[$packagesInt])){
		#only process it if it is a directory
		if (-d $self->{pkgdb}.'/'.$packages[$packagesInt]){
			my %returned=$self->parseInstalledPkg($packages[$packagesInt], \%args);
			#only add it if it is not an error
			if (!defined($self->{error})) {
				$self->{packages}{$packages[$packagesInt]}={%returned};

			}else{
				$self->warnString('Parsing "'.$packages[$packagesInt].'" as failed.');
			}
		}else{
			#non-fatal
			#exception for the portupgrade DB file
			if ($packages[$packagesInt] ne 'pkgdb.db') {
				$self->warnString('Skipping "'.$packages[$packagesInt].'" as it is not a directory');
			}
		}

		$packagesInt++;
	}

	return 1;
}

=head2 parseInstalledPkg

This parses the specified installed package.

=head3 args hash

=head4 files

A boolean controlling if file information is parsed or not.

This will be passed to parseContents.

    my %pkg=$pkgdb->parseInstalledPkg($pkgname, %args);
    if($error){
        print "Error!\n";
    }

=cut

sub parseInstalledPkg{
	my $self=$_[0];
	my $pkg=$_[1];
	my %args;
	if (defined($_[2])) {
		%args=%{$_[2]};
	}

	if (! $self->errorblank ){
		return undef;
	}

	#this is the directory that holds the package information
	my $pkgdir=$self->{pkgdb}."/".$pkg;

	my %hash;

	#the require by file
	my $requiredby=$pkgdir.'/+REQUIRED_BY';

	#if the required by file exists, process it
	if (-f $requiredby){
		#adds the required by array to the hash
		$hash{requiredby}=[];

		
		if (!open(REQUIREDBY, $requiredby)){
			$self->{error}='4';
			$self->{errorString}='Could not open the required by file, "'.$requiredby.'",';
			$self->warn;
			return undef;
		}
		my @reqs=<REQUIREDBY>;
		close(REQUIREDBY);

		#processes the required by entries
		my $reqsInt=0;
		while (defined($reqs[$reqsInt])){
			chomp($reqs[$reqsInt]);
			push(@{$hash{requiredby}}, $reqs[$reqsInt]);
			$reqsInt++;
		}
	}

	#reads the comment
	my $comment=$pkgdir.'/+COMMENT';

	#opens the comment
	if (!open(COMMENT, $comment)) {
		warn('FreeBSD-Pkgs:5: Could not open the comment file, "'.$comment.'"');
		$self->{error}=5;
		return undef;
	}
	#reads the comment
	read(COMMENT, $hash{comment}, 32768);
	close(COMMENT);
	chomp($hash{comment});

	#reads the comment
	my $desc=$pkgdir.'/+DESC';

	#opens the description
	if (!open(DESCRIPTION, $comment)) {
		warn('FreeBSD-Pkgs:6: Could not open the description file, "'.$desc.'"');
		$self->{error}=6;
		return undef;
	}
	#reads the comment
	read(DESCRIPTION, $hash{desc}, 32768);
	close(DESCRIPTION);


	#reads the comment
	my $contents=$pkgdir.'/+CONTENTS';

	#opens the description
	if (!open(CONTENTS, $contents)) {
		warn('FreeBSD-Pkgs:7: Could not open the comment file, "'.$desc.'"');
		$self->{error}=6;
		return undef;
	}
	#reads the comment
	my $contentsString;
	read(CONTENTS, $contentsString, 30000000);
	close(CONTENTS);

	#we don't do any error checking here as if there is a error, it will
	#already by defined
	$hash{contents}={$self->parseContents($contentsString,\%args)};

	return %hash;
}

=head1 Package Hash

This hash is contained in $pkgdb->{packages} or returned by $pkgdb-parseInstalledPkg.
Each of it's key is name of a installed package and a hash. See the information
below for key values of that hash.

=over

=item comment

This holds the package comment.

=item contents

This contains a hash that contains the parsed contents of the '+CONTENTS' file.
For additional information on this hash see the section '+CONTENTS Hash'.

=item desc

This holds the description of the package.

=item requiredby

This contains a array holding the a list of packages that require this package.

=back

=head1 +CONTENTS Hash

This has is either contained in $pkgdb->{packages}{<packagename>}{contents} or returned
by $pkgdb->parseContents.

=over

=item cwd

This is a string that contains the prefix for the package.

=item mtree

This is a string that contains the mtree file to use for the package.

=item requiredby

This is a array that contains a list of packages that requires this package.

=item srcdir

See pkg_create(1) for @srcdir, as I can't think of a decent description.

=item unexec

This is a array that contains the unexec lines.

=item exec

This is a array that contains the exec lines.

=item dirrm

This is a array of directories to remove.

=item conflicts

This is a array that holds a list of conflicting packages.

=item deps

This contains another hash. See the section 'deps Hash' for more information.

=item comment

This is a array that contains comments that this module was not sure what to do with.

=item files

This is a hash that contains information on the installed files. See the section 'files
Hash' for more information.

=back

=head1 deps Hash

This is a hash contained in $pkgdb->{<package>}{contents}{deps}{<pkgdep>}.

=over

=item origin

This is the ports origin location, if one is given.

=back

=head1 files Hash

This is a hash that contains information on the installed files. See the section
'files Hash' for more information. This is a hash contained in
$pkgdb->{<package>}{contents}{files}{<file>}. The keys of the hash are the name
of the files.

=over

=item MD5

This is the MD5 sum of the file.

=item cwd

This is the cwd for the file if it is not set to the base one.

=item ignore_inst

This is defined if the ignore_inst flag is set to.

=item ignore

This is defined if the ignore flag is set to.

=item mode

This is defined if a specific mode is set for a file.

=item group

This is defined if a specific group is set for a file.

=item owner

This is defined if a specific owner is set for a file.

=back

=head1 NOTES

=over

=item @noinst

These lines in the '+CONTENTS' file are not currently handled.

=item @exec

The handling of these lines are going to be changed in the near future.

=item @unexec

The handling of these lines are going to be changed in the near future.

=item @display

Currently not handled in this version of.

=item memory

It is generally uses atleast twice the amount of ram as the size of the pkgdb.

=back

=head1 ERROR CODES/HANDLING

Error handling is provided by L<Error::Helper>.

=head2 1

PKG_DBDIR does not exist.

=head2 2

Could not open PKG_DBDIR.

=head2 3

The named dir entry in PKG_DBDIR is not a directory.

=head2 4

Could not open the specified required by file.

=head2 5

Could not open the specified comment file.

=head2 6

Could not open the specified description file.

=head2 7

Could not open the specified contents file.

=head2 8

A line matching /^\@comment DEPORIGIN:/ was found, no previous depedencies have
been found.

=head2 9

A line matching /^\@comment MD5:/ was found, no previous files have
been found.

=head2 10

Unable to make sense of the specified '+CONTENTS' line.

=head2 11

/^\@cwd/ matched twice in a '+CONTENTS' file.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freebsd-pkgs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FreeBSD-Pkgs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FreeBSD::Pkgs


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FreeBSD-Pkgs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FreeBSD-Pkgs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FreeBSD-Pkgs>

=item * Search CPAN

L<http://search.cpan.org/dist/FreeBSD-Pkgs>

=back


=head1 ACKNOWLEDGEMENTS

Peter V. Vereshagin, #69658, notified me about a pointless warning for the portupgrade DB file

=head1 COPYRIGHT & LICENSE

Copyright 2012 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FreeBSD::Pkgs
