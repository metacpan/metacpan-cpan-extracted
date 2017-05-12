#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  File::Where;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.15';
$DATE = '2004/04/29';
$FILE = __FILE__;

use File::Spec;

use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(pm2require where where_dir where_file where_pm where_repository);

use SelfLoader;

1

__DATA__

#####
#
#
sub pm2require
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     File::Spec->catfile( split /::/, $_[0] . '.pm');

}


####
# Find
#
sub where
{

     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($relative, $path, $no_file) = @_;
 
     ######
     # Validate inputs
     #
     return undef unless $relative;
     $path = \@INC unless( $path );

     ######
     # Split up the platform dependent file specification into
     # pathform independent perl arrays and strings
     #
     my (undef, $dirs, $file) = File::Spec->splitpath($relative, $no_file); 
     my (@dirs) = File::Spec->splitdir( $dirs );

     my ($abs_file,  $path_dir);
     while( @dirs ) {
         foreach $path_dir (@$path) {
             ######
             # Check for a file or directory
             #
             if( $no_file ) {
                 $abs_file = File::Spec->catdir( $path_dir, $relative);
                 $abs_file = undef unless -d $abs_file;
             }
             else {
                 $abs_file = File::Spec->catfile( $path_dir, @dirs, $file);
                 $abs_file = undef unless -f $abs_file;
             }

             ######
             # If found a file or directory return it.
             # 
             if($abs_file) {

                 my $OS = $^O; 
                 unless ($OS) {   # on some perls $^O is not defined
                    require Config;
	            $OS = $Config::Config{'osname'};
                 } 

                 #### 
                 # MicroSoft thing - cannot decide between Unix or DOS
                 #
                 return $abs_file unless wantarray;
                 $path_dir =~ s|/|\\|g if $OS eq 'MSWin32';
                 return ($abs_file, $path_dir, $relative) if(wantarray);
                 return $abs_file;
             }
         }
         last unless $no_file;
         pop @dirs;
         $relative = File::Spec->catdir(@dirs);
     }
     return (undef,undef,undef) if wantarray;
     return undef;
}


#####
#
#
sub where_dir
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $dir = shift;
     my $path = '';
     if($_[0]) {
         $path = (ref($_[0]) eq 'ARRAY') ? $_[0] : \@_;
     }
     where($dir, $path, 'no_file');
}


#####
#
#
sub where_file
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $file = shift;
     my $path = '';
     if($_[0]) {
         $path = (ref($_[0]) eq 'ARRAY') ? $_[0] : \@_;
     }
     where($file, $path);
}


######
#
#
sub where_pm
{
     #####
     # Simply drop the $self, have a boundary problem for case where
     # for File::Where->where_pm('File::Where');
     # 
     #
     my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
     if( @_ == 0 && $self eq 'File::Where' ) {
         return( where_file($self->pm2require('File::Where') ) );
     }
     where_file($self->pm2require(shift), @_);
}


#####
#
#
sub where_repository
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $repository = shift;
     my @repository_dir = split /::/,$repository;
     where_dir(File::Spec->catdir(@repository_dir), @_);
}

1

__END__

=head1 NAME

File::Where - find the absolute file for a program module; absolute dir for a repository

=head1 SYNOPSIS

 #######
 # Subroutine interface
 #  
 use File::Where qw(pm2require where where_dir where_file where_pm where_repository);

 $file                            = pm2require($pm);

 $abs_file                        = where($relative_file);
 ($abs_file, $inc_path, $rel_fle) = where($relative_file)
 $abs_file                        = where($relative_file, \@path);
 ($abs_file, $inc_path, $rel_fle) = where($relative_file, \@path)
 $abs_dir                         = where($relative_dir, '', 'nofile'); 
 ($abs_dir, $inc_path, $rel_dir)  = where($relative_dir, '', 'nofile');
 $abs_dir                         = where($relative_dir, \@path, 'nofile'); 
 ($abs_dir, $inc_path, $rel_dir)  = where($relative_dir, \@path, 'nofile');

 $abs_dir                         = where_dir($relative_dir); 
 ($abs_dir, $inc_path, $rel_dir)  = where_dir($relative_dir);
 $abs_dir                         = where_dir($relative_dir, \@path; 
 ($abs_dir, $inc_path, $rel_dir)  = where_dir($relative_dir, \@path);
 $abs_dir                         = where_dir($relative_dir, @path; 
 ($abs_dir, $inc_path, $rel_dir)  = where_dir($relative_dir, @path);

 $abs_file                        = where_file($relative_file);
 ($abs_file, $inc_path, $rel_fle) = where_file($relative_file)
 $abs_file                        = where_file($relative_file, \@path);
 ($abs_file, $inc_path, $rel_fle) = where_file($relative_file, \@path)
 $abs_file                        = where_file($relative_file, @path);
 ($abs_file, $inc_path, $rel_fle) = where_file($relative_file, @path)

 $abs_file                        = where_pm($pm); 
 ($abs_file, $inc_path, $require) = where_pm($pm);
 $abs_file                        = where_pm($pm, \@path);
 ($abs_file, $inc_path, $require) = where_pm($pm, \@path);
 $abs_file                        = where_pm($pm, @path);
 ($abs_file, $inc_path, $require) = where_pm($pm, @path);

 $abs_dir                         = where_repository($repository);
 ($abs_dir,  $inc_path, $rel_dir) = where_repository($repository);
 $abs_dir                         = where_repository($repository, \@path);
 ($abs_dir,  $inc_path, $rel_dir) = where_repository($repository, \@path);
 $abs_dir                         = where_repository($repository, @path);
 ($abs_dir,  $inc_path, $rel_dir) = where_repository($repository, @path);

 #######
 # Class interface
 #
 $file                            = File::Where->pm2require($pm);

 $abs_file                        = File::Where->where($relative_file);
 ($abs_file, $inc_path, $require) = File::Where->where($relative_file)
 $abs_file                        = File::Where->where($relative_file, \@path);
 ($abs_file, $inc_path, $require) = File::Where->where($relative_file, \@path)
 $abs_dir                         = File::Where->where($relative_dir, '', 'nofile'); 
 ($abs_dir, $inc_path, $rel_dir)  = File::Where->where($relative_dir, '', 'nofile');
 $abs_dir                         = File::Where->where($relative_dir, \@path, 'nofile'); 
 ($abs_dir, $inc_path, $rel_dir)  = File::Where->where($relative_dir, \@path, 'nofile');

 $abs_dir                         = File::Where->where_dir($relative_dir); 
 ($abs_dir, $inc_path, $rel_dir)  = File::Where->where_dir($relative_dir);
 $abs_dir                         = File::Where->where_dir($relative_dir, \@path; 
 ($abs_dir, $inc_path, $rel_dir)  = File::Where->where_dir($relative_dir, \@path);
 $abs_dir                         = File::Where->where_dir($relative_dir, @path; 
 ($abs_dir, $inc_path, $rel_dir)  = File::Where->where_dir($relative_dir, @path);

 $abs_file                        = File::Where->where_file($relative_file);
 ($abs_file, $inc_path, $require) = File::Where->where_file($relative_file)
 $abs_file                        = File::Where->where_file($relative_file, \@path);
 ($abs_file, $inc_path, $require) = File::Where->where_file($relative_file, \@path)
 $abs_file                        = File::Where->where_file($relative_file, @path);
 ($abs_file, $inc_path, $require) = File::Where->where_file($relative_file, @path)

 $abs_file                        = File::Where->where_pm($pm); 
 ($abs_file, $inc_path, $require) = File::Where->where_pm($pm);
 $abs_file                        = File::Where->where_pm($pm, \@path);
 ($abs_file, $inc_path, $require) = File::Where->where_pm($pm, \@path);
 $abs_file                        = File::Where->where_pm($pm, @path);
 ($abs_file, $inc_path, $require) = File::Where->where_pm($pm, @path);

 $abs_dir                         = File::Where->where_repository($repository);
 ($abs_dir,  $inc_path, $rel_dir) = File::Where->where_repository($repository);
 $abs_dir                         = File::Where->where_repository($repository, \@path);
 ($abs_dir,  $inc_path, $rel_dir) = File::Where->where_repository($repository, \@path);
 $abs_dir                         = File::Where->where_repository($repository, @path);
 ($abs_dir,  $inc_path, $rel_dir) = File::Where->where_repository($repository, @path);

=head1 DESCRIPTION

From time to time, an program needs to know the abolute file for a program
module that has not been loaded. The File::Where module provides methods
to find this information. For loaded files, using the hash %INC may
perform better than using the methods in this module.

=head1 METHODS/SUBROUTINES

=head2 pm2require subroutine

 $file = pm2require($pm_file)

The I<pm2require> method/subroutine returns the file suitable
for use in a Perl C<require> for the C<$pm> program module.

=head2 where subroutine

The where subroutine is the core subroutine call by where_file, where_dir, 
where_pm and where_repository.

When $no_file is absent, 0 or '', the where subroutine performs as established
for the C<where_file> subroutine; otherwise the where subroutine performs as
established for the C<where_dir> subroutine.

The differences is that the C<where> syntax only accepts a reference to an array path
while the C<where_dir> and C<where_file> accept both a reference to an array path
and an array path.

=head2 where_dir subroutine

When $nofile exists and is non-zero,
the C<find_in_include> method/subroutine looks for the C<$relative_dir> under one of the directories in
the C<@path> (C<@INC> path if C<@path> is '' or 0) in the order listed in C<@path> or C<@INC>.
When I<find_in_include> finds the directory, it returns the absolute file C<$absolute_dir> and
the directory C<$path> where it found C<$relative_dir> when the usage calls for an array return;
otherwise, the absolute directory C<$absolute_dir>.

When the C<@path> list of directores exists and is not '' or 0, 
the C<where_dir> subroutine/method
searches the C<@path> list of directories instead of the C<@INC> list of directories.

=head2 where_file subroutine

When $nofile is '', 0 or absent,
the C<find_in_include> method/subroutine looks for the C<$relative_file> in one of the directories in
the C<@path> (C<@INC> path if C<@path> is absent, '' or 0) in the order listed in C<@path> or C<@INC>.
When I<find_in_include> finds the file, it returns the absolute file C<$file_absolute> and
the directory C<$path> where it found C<$file_relative> when the usage calls for an array return;
otherwise, the absolute file C<$file_absolute>.

When the C<@path> list of directores exists and is not '' or 0, 
the C<where_file> subroutine/method
searches the C<@path> list of directories instead of the C<@INC> list of directories.

=head2 where_pm subroutine

In an array context,
the I<where_pm> subroutine/method returns the C<$absolute_file>, 
the directory C<$inc_path> in C<@INC>, and the relative C<$require_file>
for the first directory in C<@INC> list of directories where it found
the program module C<$pm>; otherwise, it returns just the C<$absolute_file>.

When the C<@path> list of directores exists and is not '' or 0, 
the C<where_pm> subroutine/method
searches the C<@path> list of directories instead of the C<@INC> list of directories.

=head2 where_repository subroutine

An repository specifies the location of a number of program modules. For example,
the repository for this program module, C<File::Where>, is C<File::>.

In an array context,
the I<where_repository> subroutine/method returns the C<$absolute_directory>,
the directory C<$inc_path> in C<@INC> for the first directory in C<@INC> list of directories,
and the relative directory of the repository
where it found the C<$repository>; otherwise, it returns just the C<$absolute_file>.\
When I<where_repository> cannot find a directory containing the C<$repository> relative
directory, I<where_repository> pops the last directory off the C<$repository> relative
directory and trys again. If I<where_repository> finds that C<$repository> is empty,
it returns emptys. 

for the C<$repository>; otherwise, it returns just the C<$absolute_directory>.

When the C<@path> list of directores exists and is not '' or 0, 
the C<where_repository> subroutine/method
searches the C<@path> list of directories instead of the C<@INC> list of directories.

=head1 REQUIREMENTS


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
 =>     use File::Copy;
 =>     use File::Path;
 =>     use File::Package;
 =>     my $fp = 'File::Package';

 =>     my $uut = 'File::Where';
 =>     my $loaded = '';
 =>     # Use the test file as an example since know its absolute path
 =>     #
 =>     my $test_script_dir = cwd();
 =>     chdir File::Spec->updir();
 =>     chdir File::Spec->updir();
 =>     my $include_dir = cwd();
 =>     chdir $test_script_dir;
 =>     my $OS = $^O;  # need to escape ^
 =>     unless ($OS) {   # on some perls $^O is not defined
 =>         require Config;
 => 	$OS = $Config::Config{'osname'};
 =>     } 
 =>     $include_dir =~ s=/=\\=g if( $OS eq 'MSWin32');
 =>     $test_script_dir =~ s=/=\\=g if( $OS eq 'MSWin32');

 =>     # Put base directory as the first in the @INC path
 =>     #
 =>     my @restore_inc = @INC;

 =>     my $relative_file = File::Spec->catfile('t', 'File', 'Where.pm'); 
 =>     my $relative_dir1 = File::Spec->catdir('t', 'File');
 =>     my $relative_dir2 = File::Spec->catdir('t', 'Jolly_Green_Giant');

 =>     my $absolute_file1 = File::Spec->catfile($include_dir, 't', 'File', 'Where.pm');
 =>     my $absolute_dir1A = File::Spec->catdir($include_dir, 't', 'File');
 =>     my $absolute_dir1B = File::Spec->catdir($include_dir, 't');

 =>     mkpath (File::Spec->catdir($test_script_dir, 't','File'));
 =>     my $absolute_file2 = File::Spec->catfile($test_script_dir, 't', 'File', 'Where.pm');
 =>     my $absolute_dir2A = File::Spec->catdir($include_dir, 't', 'File', 't', 'File');
 =>     my $absolute_dir2B = File::Spec->catdir($include_dir, 't', 'File', 't');

 =>     #####
 =>     # If doing a target site install, blib going to be up front in @INC
 =>     # Locate the include directory with high probability of having the
 =>     # first File::Where in the include path.
 =>     #
 =>     # Really not important that that cheapen test somewhat by doing a quasi
 =>     # where search in that using this to test for a boundary condition where
 =>     # the class, 'File::Where', is the same as the program module 'File::Where
 =>     # that the 'where' subroutine/method is locating.
 =>     #
 =>     my $absolute_dir_where = File::Spec->catdir($include_dir, 'lib');
 =>     foreach (@INC) {
 =>         if ($_ =~ /blib/) {
 =>             $absolute_dir_where = $_ ;
 =>             last;
 =>         }
 =>         elsif ($_ =~ /lib/) {
 =>             $absolute_dir_where = $_ ;
 =>             last;
 =>         }
 =>     }
 =>     my $absolute_file_where = File::Spec->catfile($absolute_dir_where, 'File', 'Where.pm');

 =>     my @inc2 = ($test_script_dir, @INC);  # another way to do unshift
 =>     
 =>     copy $absolute_file1,$absolute_file2;
 =>     unshift @INC, $include_dir;    

 =>     my (@actual,$actual); # use for array and scalar context
 => my $errors = $fp->load_package('File::Where', 'where_pm')
 => $errors
 ''

 => $actual = $uut->pm2require( "$uut")
 'File\Where.pm'

 => [@actual = $uut->where($relative_file)]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\Where.pm',
           'E:\User\SoftwareDiamonds\installation',
           't\File\Where.pm'
         ]

 => $actual = $uut->where($relative_file)
 'E:\User\SoftwareDiamonds\installation\t\File\Where.pm'

 => [@actual = $uut->where($relative_file, [$test_script_dir, $include_dir])]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\t\File\Where.pm',
           'E:\User\SoftwareDiamonds\installation\t\File',
           't\File\Where.pm'
         ]

 => [@actual = $uut->where($relative_dir1, '', 'nofile')]
 [
           'E:\User\SoftwareDiamonds\installation\t\File',
           'E:\User\SoftwareDiamonds\installation',
           't\File'
         ]

 => $actual = $uut->where($relative_file, '', 'nofile')
 'E:\User\SoftwareDiamonds\installation\t\File'

 => [@actual = $uut->where($relative_dir2, \@inc2, 'nofile')]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\t',
           'E:\User\SoftwareDiamonds\installation\t\File',
           't'
         ]

 => $actual = $uut->where('t', [$test_script_dir,@INC], 'nofile')
 'E:\User\SoftwareDiamonds\installation\t\File\t'

 => [@actual = $uut->where_file($relative_file)]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\Where.pm',
           'E:\User\SoftwareDiamonds\installation',
           't\File\Where.pm'
         ]

 => $actual = $uut->where_file($relative_file, $test_script_dir, $include_dir)
 'E:\User\SoftwareDiamonds\installation\t\File\t\File\Where.pm'

 => [@actual = $uut->where_dir($relative_dir1, \@inc2)]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\t\File',
           'E:\User\SoftwareDiamonds\installation\t\File',
           't\File'
         ]

 => [@actual = $uut->where_dir($relative_dir2, $test_script_dir)]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\t',
           'E:\User\SoftwareDiamonds\installation\t\File',
           't'
         ]

 => $actual = $uut->where_dir($relative_file)
 'E:\User\SoftwareDiamonds\installation\t\File'

 => [@actual= $uut->where_pm( 't::File::Where' )]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\Where.pm',
           'E:\User\SoftwareDiamonds\installation',
           't\File\Where.pm'
         ]

 => $actual = $uut->where_pm( 't::File::Where', @inc2)
 'E:\User\SoftwareDiamonds\installation\t\File\t\File\Where.pm'

 => $actual = $uut->where_pm( 'File::Where')
 'E:\User\SoftwareDiamonds\installation\lib\File\Where.pm'

 => [@actual= $uut->where_pm( 't::File::Where', [$test_script_dir])]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\t\File\Where.pm',
           'E:\User\SoftwareDiamonds\installation\t\File',
           't\File\Where.pm'
         ]

 => [@actual= $uut->where_repository( 't::File' )]
 [
           'E:\User\SoftwareDiamonds\installation\t\File',
           'E:\User\SoftwareDiamonds\installation',
           't\File'
         ]

 => $actual = $uut->where_repository( 't::File', @inc2)
 'E:\User\SoftwareDiamonds\installation\t\File\t\File'

 => [@actual= $uut->where_repository( 't::Jolly_Green_Giant', [$test_script_dir])]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\t',
           'E:\User\SoftwareDiamonds\installation\t\File',
           't'
         ]

 =>    @INC = @restore_inc; #restore @INC;
 =>    rmtree 't';

=head1 QUALITY ASSURANCE

Running the test script C<Where.t> verifies
the requirements for this module.

The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Where.t> test script, C<Where.d> demo script,
and C<t::Data::Where> program module POD,
from the C<t::Data::Where> program module contents.
The C<t::Data::Where> program module
is in the distribution file
F<Data-Where-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright Notice

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements Notice

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 License

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

=head1 SEE ALSO

=over 4

=item L<Docs::Site_SVD::Data_Where|Docs::Site_SVD::Data_Where>

=item L<Test::STDmaker|Test::STDmaker> 

=back

=cut

### end of file ###