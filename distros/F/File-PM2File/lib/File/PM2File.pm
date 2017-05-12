#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  File::PM2File;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.13';
$DATE = '2004/04/08';
$FILE = __FILE__;

use File::Where;

use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter File::Where);
@EXPORT_OK = qw(find_in_include pm2file pm2require);

my $warn_obsolete = 0;

sub find_in_include
{
     warn( "# ** NOTICE ** File::PM2File::find_in_include() obsolete. Replace with File::Where::where()\n" )
        if($warn_obsolete);
     my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
     my ($abs_file, $path_dir) = $self->File::Where::where( @_);
     return ($abs_file, $path_dir) if wantarray;
     $abs_file;
}


sub pm2file
{
     warn( "# ** NOTICE ** File::PM2File::pm2file() obsolete. Replace with File::Where::where_pm()\n" )
        if($warn_obsolete);
     my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
     my $file = $self->File::Where::pm2require( @_);
     $self->File::Where::where_file( $file );
}


sub pm2require
{
     warn( "# ** NOTICE ** File::PM2File::pm2require() obsolete. Replace with File::Where::pm2require()\n" )
        if($warn_obsolete);
     my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
     $self->File::Where::pm2require( @_);
}

1

__END__

=head1 NAME

File::PM2File - obsolete. User File::Where

=head1 SYNOPSIS

 file_in_include()  # obsolete. Replace with File::Where::where()
 pm2file()          # obsolete. Replace with  File::Where::where_pm()
 pm2require()       # obsolete. Replace with  File::Where::pm2require()

 $File::PM2File::warn_obsolete = 1;  # turns on obsolete warning

=head1 REQUIREMENTS

The File::PM2File subrouitnes shall not used. 

The File::PM2File subroutines shall be replaced by the
appropriate File::Where subroutine whenever a 
File::PM2File subroutine needs revision as follows:

 File::PM2File::find_in_include()   File::Where::where()
 File::PM2File::pm2file             File::Where::where_pm()
 File::PM2File::pm2require          File::Where::pm2require

NOTE: The subroutine File::Where::where is almost a direct
drop in for File::PM2File::find_in_include(). The difference is in an
array context File::Where::where() returns a third item where
File::PM2File::find_in_include() only returns two. The first two
items, though, are the same.

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
 =>     my $uut = 'File::PM2File';
 =>     my $loaded = '';

 =>     # Use the test file as an example since no its absolue path
 =>     # Calculate the absolute file, relative file, and include directory
 =>     my $relative_file = File::Spec->catfile('t', 'File', 'PM2File.pm'); 

 =>     my $restore_dir = cwd();
 =>     chdir File::Spec->updir();
 =>     chdir File::Spec->updir();
 =>     my $include_dir = cwd();
 =>     chdir $restore_dir;
 =>     my $OS = $^O;  # need to escape ^
 =>     unless ($OS) {   # on some perls $^O is not defined
 =>         require Config;
 =>         $OS = $Config::Config{'osname'};
 =>     } 
 =>     $include_dir =~ s=/=\\=g if( $^O eq 'MSWin32');
 =>     my $absolute_file = File::Spec->catfile($include_dir, 't', 'File', 'PM2File.pm');
 =>     $absolute_file =~ s=.t$=.pm=;

 =>     # Put base directory as the first in the @INC path
 =>     my @restore_inc = @INC;
 =>     unshift @INC, $include_dir;
 => my $errors = $fp->load_package( 'File::PM2File' )
 ''

 => $uut->pm2require( "$uut")
 'File\PM2File.pm'

 => [my @actual =  $uut->find_in_include( $relative_file )]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\PM2File.pm',
           'E:\User\SoftwareDiamonds\installation'
         ]

 => [@actual = $uut->pm2file( 't::File::PM2File' )]
 [
           'E:\User\SoftwareDiamonds\installation\t\File\PM2File.pm',
           'E:\User\SoftwareDiamonds\installation',
           't\File\PM2File.pm'
         ]

 => @INC = @restore_inc

=head1 NOTES

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