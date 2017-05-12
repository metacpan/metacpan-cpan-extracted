# -*- perl -*-
#


use strict;
require 5.005;

use File::Copy ();
use File::Basename ();
use Symbol ();
use Mail::IspMailGate::Filter ();
use File::Spec ();


package Mail::IspMailGate::Filter::VirScan;

@Mail::IspMailGate::Filter::VirScan::ISA = qw(Mail::IspMailGate::Filter);

sub getSign { "X-ispMailGate-VirScan" }

#####################################################################
#
#   Name:     mustFilter
#
#   Purpose:   determines wether this message must be filtered and
#             allowed to modify $self the message and so on
#
#   Inputs:   $self   - This class
#             $entity - the whole message
#
#
#   Returns:  1 if it must be, else 0
#
#####################################################################

sub mustFilter ($$) {
    # Always true (consider faked headers!)
    1;
}


#####################################################################
#
#   Name:     hookFilter
#
#   Purpose:  a function which is called after the filtering process
#
#   Inputs:   $self   - This class
#             $entity - the whole message
#
#
#   Returns:  errormessage if any
#
#####################################################################

sub hookFilter ($$) {
    my($self, $entity) = @_;
    my($head) = $entity->head;
    $head->set($self->getSign(), 'scanned');
    '';
}



#####################################################################
#
#   Name:     createDir
#
#   Purpse:   creates a new directory, under the given
#
#   Inputs:   $self   - This class
#             $attr   - Attributes
#
#   Returns:  the name of the new dir
#
#####################################################################

sub createDir ($$) {
    my ($self, $attr) = @_;

    my($baseDir) = $attr->{'parser'}->output_dir();
    my($i) = 0;
    my($dir);

    while (-e ($dir = "$baseDir/dir$i")) {
	++$i;
    }
    if (!mkdir $dir, 0700) {
	die "Cannot create directory $dir ($!)";
    }
    $dir;
}


#####################################################################
#
#   Name:     checkDirFiles
#
#   Purpse:   creates a list of files from a certain directory,
#             including subdirectories
#
#   Inputs:   $self   - This instance
#             $dir    - Directory name
#
#   Returns:  File list; dies in case of trouble
#
#####################################################################

sub checkDirFiles ($$) {
    my($self, $dir) = @_;
    my(@files);

    #
    # Recursively scan directory $dir for files
    #
    my($dirHandle) = Symbol::gensym();
    if (!opendir($dirHandle, $dir)) {
	die "Cannot read directory $dir ($!)";
    }
    my($file);
    while (defined($file = readdir($dirHandle))) {
	if ($file eq '.'  ||  $file eq '..') {
	    next;
	}
	$file = "$dir/$file";
	if (-d $file) {
	    push(@files, $self->checkDirFiles($file));
	} elsif (-f _) {
	    push(@files, $file);
	}
    }
    closedir($dirHandle);

    @files;
}


#####################################################################
#
#   Name:     checkArchive
#
#   Purpse:   creates a new temporary directory and extracts an
#             archive into it; returns a list of files that have
#             been created by calling checkDirFiles
#
#   Inputs:   $self     - This instance
#             $attr     - The $attr argument of filterList
#             $ipath    - The archive path
#             $deflater - An element from the deflater list that
#                         matches $ipath.
#
#   Returns:  File list; dies in case of trouble
#
#####################################################################

sub checkArchive ($$$$) {
    my($self, $attr, $ipath, $deflater) = @_;
    my $cfg = $Mail::IspMailGate::Config::config;

    # Create a new directory for extracting the files into it.
    my %patterns = ('ipath' => $ipath,
		    'idir'  => File::Basename::dirname($ipath),
		    'ifile' => File::Basename::basename($ipath),
		    'odir'  => $self->createDir($attr));
    $patterns{'ofile'} = $patterns{'ifile'};
    if ($deflater->{'extension'}) {
	$patterns{'ofile'} =~ s/$deflater->{'extension'}$//;
    }
    $patterns{'opath'} = File::Spec->catfile($patterns{'odir'},
					     $patterns{'ofile'});
    my $cmd = $deflater->{'cmd'};
    $cmd =~ s/\$(\w+)/exists($patterns{$1}) ? quotemeta($patterns{$1}) :
                      exists $cfg->{$1} ? $cfg->{$1} : ''/esg;
    $attr->{'main'}->Debug("Running command: $cmd");
    system $cmd;

    $self->checkDirFiles($patterns{'odir'});
}


############################################################################
#
#   Name:    HasVirus
#
#   Purpose: Takes the virus scanners output and parses it for virus
#	     warnings.
#
#            This version is well suited for the AntiVir virus scanner.
#            You typically need to override it for other programs.
#
#   Input:   $self - Instance
#            $output - Message emitted by the virus scanner
#
#   Returns: TRUE if $output indicates a virus, FALSE otherwise
#
############################################################################

sub HasVirus {
    my $self = shift; my $str = shift;
    my $result = join('\n', grep { $_ =~ /\!Virus\!/ } split(/\n/, $str));
    $result ? "Alert: A Virus has been detected:\n\n$result\n" : '';
}


#####################################################################
#
#   Name:     checkFile
#
#   Purpse:   checks a file (recursively if archive) for virus
#
#   Inputs:   $self   - Instance
#             $attr   - Same as the $attr argument of filterFile
#             $ipath  - the file to check
#
#   Returns:  error message, if any
#
#####################################################################

sub checkFile ($$$) {
    my ($self, $attr, $ipath) = @_;
    my(@simpleFiles, @checkFiles);
    my($ret) = '';
    my $cfg = $Mail::IspMailGate::Config::config;

    @checkFiles = ($ipath);
    my($file);
    while (defined($file = shift @checkFiles)) {
	# Modify the name for use in a shell command
	if ($file =~ /[\000-\037]/) {
	    $ret .= "Suspect file names: $file";
	    next;
	}

	# Check whether file is an archive
	my($deflater);
	foreach $deflater (@{$cfg->{'virscan'}->{'deflater'}}) {
	    if ($file =~ /$deflater->{'pattern'}/) {
		push(@checkFiles,
		     $self->checkArchive($attr, $file, $deflater));
		undef $file;
		last;
	    }
	}

	# If it isn't, scan it
	if (defined($file)) {
	    push(@simpleFiles, $file);
	}
    }

    if (@simpleFiles) {
	my $cmd = $cfg->{'virscan'}->{'scanner'};
	$cmd =~ s/\$antivir_path/$cfg->{'antivir_path'}/g;
	my $output;
	if ($cmd =~ /\$ipaths/) {
	    # We may scan all files with a single command
	    my($ipaths) = '';
	    foreach $file (@simpleFiles) {
		$ipaths .= ' ' . quotemeta($file);
	    }
	    $cmd =~ s/\$ipaths/$ipaths/sg;
	    $cmd =~ s/\$(\w+)/exists $cfg->{$1} ? $cfg->{$1} : ''/seg;
	    $attr->{'main'}->Debug("Running command: $cmd");
	    $output = `$cmd`;
	    $ret .= $self->HasVirus($output);
        } else {
	    # We need to scan any file separately
	    foreach $file (@simpleFiles) {
		$ipath = quotemeta($file);
		$cmd =~ s/\$ipath/$ipath/sg;
		$cmd =~ s/\$(\w+)/exists $cfg->{$1} ? $cfg->{$1} : ''/seg;
		$attr->{'main'}->Debug("Running command: $cmd");
		$output = `$cmd`;
	        $ret .= $self->HasVirus($output);
	    }
        }
    }
    $ret;
}


#####################################################################
#
#   Name:     filterFile
#
#   Purpse:   do the filter process for one file
#
#   Inputs:   $self   - This class
#             $attr   - hash-ref to filter attribute
#                       1. 'body'
#                       2. 'parser'
#                       3. 'head'
#                       4. 'globHead'
#
#   Returns:  error message, if any
#
#####################################################################

sub filterFile ($$) {
    my ($self, $attr) = @_;
    my $cfg = $Mail::IspMailGate::Config::config;

    my ($body) = $attr->{'body'};
    my ($globHead) = $attr->{'globHead'};
    my ($ifile) = $body->path();
    $attr->{'main'}->Debug("Scanning file $ifile for viruses");
    my ($ret) = 0;
    if($ret = $self->SUPER::filterFile($attr)) {
	$attr->{'main'}->Debug("Returning immediately, result $ret");
	return $ret;
    }

    $ret = $self->checkFile($attr, $ifile);
    $attr->{'main'}->Debug("Returning, result $ret");
    $ret;
}


1;

__END__


=pod

=head1 NAME

Mail::IspMailGate::Filter::VirScan  - Scanning emails for Viruses


=head1 SYNOPSIS

 # Create a filter object
 my($scanner) = Mail::IspMailGate::Filter::VirScan->new({});

 # Call it for filtering the MIME entity $entity and pass it a
 # Mail::IspMailGate::Parser object $parser
 my($result) = $scanner->doFilter({
     'entity' => $entity,
     'parser' => $parser
     });
 if ($result) { die "Error: $result"; }


=head1 DESCRIPTION

This class implements a Virus scanning email filter. It is derived from
the abstract base class Mail::IspMailGate::Filter. For details of an
abstract filter see L<Mail::IspMailGate::Filter>.

The virus scanner class needs an external binary which has the ability
to detect viruses in given files, like VirusX from http://www.antivir.com.
What the module does is extracting files from the email and passing them
to the scanner. Extracting includes dearchiving .zip files, .tar.gz files
and other known archive types by using external dearchiving utilities like
I<unzip>, I<tar> and I<gzip>. Known extensions and dearchivers are
configurable, so you can customize them for your own needs.


=head1 CUSTOMIZATION

The virus scanner module depends on some items in the
Mail::IspMailGate::Config module:

=over 4

=item $cfg->{'antivir_path'}

Path of the AntiVir binary, for example

  $cfg->{'antivir_path'} = '/usr/bin/antivir';

=item $cfg->{virscan}->{scanner}

A template for calling the external virus scanner; example:

    $cfg->{'virscan'}->{'scanner'} =
	'$antivir_path -rs -nolnk -noboot $ipaths';

The template must include either of the variable names $ipath or $ipaths;
the former must be used, if the virus scanner cannot accept more than one
file name with one call. Note the use of single quotes which prevent
expanding the variable name!

Additionally the pattern $antivir_path may be used for the path to
the antivir binary.

=item $cfg->{virscan}->{deflater}

This is an array ref of known archive deflaters. Each element of the
array is a hash ref with the attributes C<cmd>, a template for calling the
dearchiver and C<pattern>, a Perl regular expression for detecting
file names which refer to archives that this program might extract.
An example which configures the use of C<unzip>, C<tar> and C<gzip>:

    $cfg->{'virscan'}->{'deflater'} =
        [ { pattern => '\\.(tgz|tar\\.gz|tar\\.[zZ])$',
            cmd => '$gzip_path -cd $ipath | /bin/tar -xf -C $odir'
          },
          { pattern => '\\.tar$',
            cmd => '$tar_path -xf -C $odir'
	  },
	  { pattern => '\\.(gz|[zZ])$',
            cmd => '$gzip_path -cd $ipath >$opath'
          },
          { pattern => '\\.zip$',
            cmd => '$unzip_path $ifile -d $odir'
          }
        ];

Again, note the use of single quotes to prevent variable expansion and
double backslashes for passing a single backslash in the Perl regular
expressions. See L<perlre> for details of regular expressions.

The command template can use the following variables:

=over 8

=item $ipath

Full filename of the archive being deflated

=item $idir

=item $ifile

Directory and file name portion of the archive

=item $odir

Directory where the archive must be extracted to; if your dearchiver
doesn't support an option --directory or something similar, you need
to create a subshell. For example the following might be used for
an LhA deflater:

    { 'pattern' => '\\.(lha|lzx)',
       'cmd' => '(cd $odir; lha x $ipath)'
    }

=item $ofile

=item $opath

Same as $ifile and $odir/$ofile; for example gzip needs this, when it
runs as a standalone deflater and not as a backend of tar.

=item $gzip_path

=item $tar_path

=item $unzip_path

=item $lha_path

=item $unarj_path

These are the paths of the corresponding binaries and read from
$cfg->{'gzip_path'}, $cfg->{'tar_path'} and so on.

=back

=back


=head1 PUBLIC INTERFACE

=over

=item I<checkFile $ATTR, $FILE>

This function is called for every part of a MIME-message from within
the I<filterFile> method. It receives the arguments $ATTR (same as the
$ATTR argument of filterFile) and $FILE, the filename where the MIME
part is stored. If it detects $FILE to be an archive, it calls
C<checkArchive> for deflating it and building a list of files contained
in the archive. If another archive is found, it calls C<checkArchive>
again.

Finally, after building a list of files, it calls the virus scanner.
If the scanner can handle multiple files, a single call occurs, otherwise
the scanner will be called for any file. See L<CONFIGURATION> above.

=item I<checkArchive $ATTR, $IPATH, $DEFLATER>

This function is called from within I<checkFile> to extract the archive
$IPATH by using the $DEFLATER->{'cmd'} ($DEFLATER is an element from
the deflater list). The $ATTR argument is the same as in I<checkFile>.

The function creates a new temporary directory and extracts the archive
contents into that directory. Finally it returns a list of files that
have been extracted.

=item I<HasVirus>

  $hasVirus = $self->HasVirus($OUTPUT)

(Instance method) This method takes the string $OUTPUT, which is a message
emitted by the virus scanner and parses it for possible virus warnings.
The method returns TRUE, if such warnings are detected or FALSE otherwise.

The default implementation knows about the output of the I<AntiVir> virus
scanner. To use the filter with other virus scanners, you typically
dervice a subclass from it which overrides this method.

=back


=head1 SEE ALSO

L<ispMailGate>, L<Mail::IspMailGate::Filter>

=cut
