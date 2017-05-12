#!perl
#
# Documentation, copyright and license is at the end of this file.
#

package  File::AnySpec;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.13';
$DATE = '2004/04/09';

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(fspec2fspec pm2fspec os2fspec fspec2os fspec_glob fspec2pm);

use SelfLoader;
use File::Spec;


######
#
# Having trouble with requires in Self Loader
#
# This could be because the below use Self Loader and
# Self Loader does not like to be nested,
#
# Anyway, since they use Self Loader, there is very
# little advantage in placing a require in subroutines.
#
#####
use File::Where;
use File::Package;

######
# Many of the methods in this package are use the File::Spec
# module submodules. 
#
# The L<File::Spec||File::Spec> uses the current operating system,
# as specified by the $^O to determine the proper File::Spec submodule
# to use.
#
# Thus, when using File::Spec method, only the submodule for
# the current operating system is loaded and the File::Spec
# method directed to the corresponding method of the
# File::Spec submodule.
#
my %module = (
      MacOS   => 'Mac',
      MSWin32 => 'Win32',
      os2     => 'OS2',
      VMS     => 'VMS',
      epoc    => 'Epoc');

sub fspec2module
{
    ######
    # This subroutine uses no object data. Drop class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($fspec) = @_;
    $module{$fspec} || 'Unix';
}


#####
# Convert between file specifications for different operating systems.
#
sub fspec2fspec
{
    ######
    # This subroutine uses no object data. Drop class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($from_fspec, $to_fspec, $fspec_file, $nofile) = @_;
    return $fspec_file if $from_fspec eq $to_fspec;

    #######
    # Extract the raw @dirs, file
    #
    my $from_module = fspec2module( $from_fspec );
    my $from_package = "File::Spec::$from_module";
    my $error = File::Package->load_package($from_package);
    if( $error ) {
         warn $error;
         return undef;
    }
    my (undef, $fspec_dirs, $file) = $from_package->splitpath( $fspec_file, $nofile); 
    my @dirs = ($fspec_dirs) ? $from_package->splitdir( $fspec_dirs ) : ();

    return $file unless @dirs;  # no directories, file spec same for all os

    #######
    # Contruct the new file specification
    #
    my $to_module = fspec2module( $to_fspec );
    my $to_package = "File::Spec::$to_module";
    $error = File::Package->load_package( $to_package);
    if( $error ) {
         warn $error;
         return undef;
    }
    my @dirs_up;
    foreach my $dir (@dirs) {
       $dir = $to_package->updir() if $dir eq $to_package->updir();
       push @dirs_up, $dir;
    }
    return $to_package->catdir(@dirs_up) if $nofile;
    $to_package->catfile(@dirs_up, $file); # to native operating system file spec

}

1

__DATA__

######
#
#
sub pm2fspec
{
    ######
    # This subroutine uses no object data. When present, drop class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fspec, $pm) = @_;
    my ($file,$path, $require) = File::Where->where_pm($pm);
    $file = os2fspec( $fspec, $file);
    $require = os2fspec( $fspec, $require);
    $path = os2fspec( $fspec, $path, 'nofile');
    ($file, $path, $require)
}


#####
#
#
sub os2fspec
{
    ######
    # This subroutine uses no object data. When present, drop class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fspec, $os_file, $nofile) = @_;
    my $OS; 
    unless ($OS = $^O) {   # on some perls $^O is not defined
	require Config;
	$OS = $Config::Config{'osname'};
    }
    fspec2fspec($OS, $fspec, $os_file, $nofile);
}

#####
#
#
sub fspec2os
{
    ######
    # This subroutine uses no object data. When present, drop class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fspec, $fspec_file, $nofile) = @_;
    my $OS; 
    unless ($OS = $^O) {   # on some perls $^O is not defined
	require Config;
	$OS = $Config::Config{'osname'};
    }
    fspec2fspec($fspec, $OS, $fspec_file, $nofile);
}

#######
#
# Glob a file specification
#
sub fspec_glob
{
    ######
    # This subroutine uses no object data. When present, drop class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fspec, @files) = @_;

    use File::Glob ':glob';

    my @glob_files = ();
    foreach my $file (@files) {
        $file = fspec2os($fspec, $file);
        push @glob_files, bsd_glob( $file );
    }
    @glob_files;
}




sub fspec2pm
{
    ######
    # This subroutine uses no object data. When present, drop class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fspec, $fspec_file) = @_;

    ##########
    # Must be a pm to convert to :: specification
    #
    return $fspec_file unless ($fspec_file =~ /\.pm$/);

    my $module = fspec2module( $fspec );
    my $fspec_package = "File::Spec::$module";
    File::Package->load_package( $fspec_package);
    
    #####
    # extract the raw @dirs and file from the file spec
    # 
    my (undef, $fspec_dirs, $file) = $fspec_package->splitpath( $fspec_file ); 
    my @dirs = $fspec_package->splitdir( $fspec_dirs );
    pop @dirs unless $dirs[-1]; # sometimes get empty for last directory

    #####
    # Contruct the pm specification
    #
    $file =~ s/\..*?$//g; # drop extension
    $file = join '::', (@dirs,$file);    
    $file
}

1

__END__

=head1 NAME

File::AnySpec - perform operations on foreign (remote) file names

=head1 SYNOPSIS

 ###### 
 # Subroutine Interface
 #
 use File::AnySpec qw(fspec2fspec pm2fspec os2fspec fspec2os fspec_glob fspec2pm);

 $file                                 = fspec2fspec($from_fspec, $to_fspec $fspec_file, [$nofile])
 $os_file                              = fspec2os($fspec, $file, [$no_file])
 $fspec_file                           = os2fspec($fspec, $file, [$no_file])

 $pm                                   = fspec2pm($fspec, $require_file)
 ($abs_file, $inc_path, $require_file) = pm2fspec($fspec, $pm)

 @globed_files                         = fspec_glob($fspec, @files)

 ###### 
 # Class Interface
 #
 use File::AnySpec
 use vars qw(@ISA)
 @ISA = qw(File::AnySpec)

 $file                                 = __PACKAGE__->fspec2fspec($from_fspec, $to_fspec $fspec_file, [$nofile])
 $os_file                              = __PACKAGE__->fspec2os($fspec, $file, [$no_file])
 $fspec_file                           = __PACKAGE__->os2fspec($fspec, $file, [$no_file])

 $pm                                   = __PACKAGE__->fspec2pm($fspec, $require_file)
 ($abs_file, $inc_path, $require_file) = __PACKAGE__->pm2fspec($fspec, $pm)

 @globed_files                         = __PACKAGE__->fspec_glob($fspec, @files)


=head1 DESCRIPTION

Methods in this package, perform operations on file specifications for 
operating systems other then the current site operating system.
The input variable I<$fspec> tells the methods in this package
the file specification for file names used as input to the methods.
Thus, when using methods in this package, the method may 
load up to two L<File::Spec||File::Spec> submodules methods and
neither of them is a submodule for the current site operating
system.

Supported operating system file specifications are as follows:

 MacOS
 MSWin32
 os2
 VMS
 epoc

Of course since, the variable I<$^O> contains the file specification
for the current site operating system, it may be used for the
I<$fspec> variable.

=head2 fspec_glob method

  @globed_files = File::AnySpec->fspec_glob($fspec, @files)

The I<fspec_glob> method BSD globs each of the files in I<@files>
where the file specification for each of the files is I<$fspec>.

=head2 fspec2fspec method

 $to_file = File::AnySpec->fspec2fspec($from_fspec, $to_fspec $from_file, $nofile)

THe I<fspec2fspec> method translate the file specification for I<$from_file> from
the I<$from_fspec> to the I<$to_fpsce>. Supplying anything for I<$nofile>, tells
the I<fspec2fspec> method that I<$from_file> is a directory tree; otherwise, it
is a file.

=head2 fspec2os method

  $os_file = File::AnySpec->fspec2os($fspec, $file, $no_file)

The I<fspec2os> method translates a file specification, I<$file>, from the
current operating system file specification to the I<$fspec> file specification.
Supplying anything for I<$nofile>, tells
the I<fspec2fspec> method that I<$from_file> is a directory tree; otherwise, it
is a file.

=head2 fspec2pm method

 $pm_file = File::AnySpec->fspec2pm( $fspec, $relative_file )

The I<fspec2pm> method translates a filespecification I<$file>
in the I<$fspce> format to the Perl module formate.

=head2 os2fspec method

 $file = File::AnySpec->os2fspec($fspec, $os_file, $no_file)

The I<fspec2os> method translates a file specification, I<$file>, from the
current operating system file specification to the I<$fspec> file specification.
Supplying anything for I<$nofile>, tells
the I<fspec2fspec> method that I<$from_file> is a directory tree; otherwise, it
is a file.


=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Spec;

 =>     use File::Package;
 =>     my $fp = 'File::Package';

 =>     my $as = 'File::AnySpec';

 =>     my $loaded = '';
 =>     my @drivers;
 =>     my @files;
 => my $errors = $fp->load_package( $as)
 => $errors
 ''

 => $as->fspec2fspec( 'Unix', 'MSWin32', 'File/FileUtil.pm')
 'File\FileUtil.pm'

 => $as->os2fspec( 'Unix', ($as->fspec2os( 'Unix', 'File/FileUtil.pm')))
 'File/FileUtil.pm'

 => $as->os2fspec( 'MSWin32', ($as->fspec2os( 'MSWin32', 'Test\\TestUtil.pm')))
 'Test\TestUtil.pm'

 => @drivers = sort $as->fspec_glob('Unix','Drivers/G*.pm')
 => join (', ', @drivers)
 'Drivers\Generate.pm'

 => $as->fspec2pm('Unix', 'File/AnySpec.pm')
 'File::AnySpec'

 => $as->pm2fspec( 'Unix', 'File::Basename')
 '/Perl/lib/File/Basename.pm'
 '/Perl/lib'
 'File/Basename.pm'


=head1 QUALITY ASSURANCE

Running the test script 'AnySpec.t' found in
the "File-AnySpec-$VERSION.tar.gz" distribution file verifies
the requirements for this module.

All testing software and documentation
stems from the 
Software Test Description (L<STD|Docs::US_DOD::STD>)
program module 't::File::AnySpec',
found in the distribution file 
"File-AnySpec-$VERSION.tar.gz". 

The 't::File::AnySpec' L<STD|Docs::US_DOD::STD> POD contains
a tracebility matix between the
requirements established above for this module, and
the test steps identified by a
'ok' number from running the 'AnySpec.t'
test script.

The t::File::AnySpec' L<STD|Docs::US_DOD::STD>
program module '__DATA__' section contains the data 
to perform the following:

=over 4

=item *

to generate the test script 'AnySpec.t'

=item *

generate the tailored 
L<STD|Docs::US_DOD::STD> POD in
the 't::File::AnySpec' module, 

=item *

generate the 'AnySpec.d' demo script, 

=item *

replace the POD demonstration section
herein with the demo script
'AnySpec.d' output, and

=item *

run the test script using Test::Harness
with or without the verbose option,

=back

To perform all the above, prepare
and run the automation software as 
follows:

=over 4

=item *

Install "Test_STDmaker-$VERSION.tar.gz"
from one of the respositories only
if it has not been installed:

=over 4

=item *

http://www.softwarediamonds/packages/

=item *

http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=back
  
=item *

manually place the script tmake.pl
in "Test_STDmaker-$VERSION.tar.gz' in
the site operating system executable 
path only if it is not in the 
executable path

=item *

place the 't::File::AnySpec' at the same
level in the directory struture as the
directory holding the 'File::AnySpec'
module

=item *

execute the following in any directory:

 tmake -test_verbose -replace -run -pm=t::File::AnySpec

=back

=head1 NOTES

=head2 FILES

The installation of the
"File-AnySpec-$VERSION.tar.gz" distribution file
installs the 'Docs::Site_SVD::File_AnySpec'
L<SVD|Docs::US_DOD::SVD> program module.

The __DATA__ data section of the 
'Docs::Site_SVD::File_AnySpec' contains all
the necessary data to generate the POD
section of 'Docs::Site_SVD::File_AnySpec' and
the "File-AnySpec-$VERSION.tar.gz" distribution file.

To make use of the 
'Docs::Site_SVD::File_AnySpec'
L<SVD|Docs::US_DOD::SVD> program module,
perform the following:

=over 4

=item *

install "ExtUtils-SVDmaker-$VERSION.tar.gz"
from one of the respositories only
if it has not been installed:

=over 4

=item *

http://www.softwarediamonds/packages/

=item *

http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=back

=item *

manually place the script vmake.pl
in "ExtUtils-SVDmaker-$VERSION.tar.gz' in
the site operating system executable 
path only if it is not in the 
executable path

=item *

Make any appropriate changes to the
__DATA__ section of the 'Docs::Site_SVD::File_AnySpec'
module.
For example, any changes to
'File::AnySpec' will impact the
at least 'Changes' field.

=item *

Execute the following:

 vmake readme_html all -pm=Docs::Site_SVD::File_AnySpec

=back

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, 490A (L<STD490A/3.2.3.6>).
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

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
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

=head2 SEE_ALSO:

=over 4

=item L<File::Spec|File::Spec>

=item L<File::AnySpec|File::AnySpec>

=back

=for html
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

### end of file ###