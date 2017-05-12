#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::File::PM2File;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.03';
$DATE = '2004/04/08';
$FILE = __FILE__;

########
# The Test::STDmaker module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmaker generates this file.
#
#


=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl File::PM2File Program Module

 Revision: -

 Version: 

 Date: 2004/04/08

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<File::PM2File|File::PM2File>

The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.
in accordance with 
L<Detail STD Format|Test::STDmaker/Detail STD Format>.

#######
#  
#  4. TEST DESCRIPTIONS
#
#  4.1 Test 001
#
#  ..
#
#  4.x Test x
#
#

=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD FormDB Test Description Fields|Test::STDmaker/STD FormDB Test Description Fields>.

=head2 Test Plan

 T: 5^

=head2 ok: 1


  C:
     use File::Spec;
     use File::Package;
     my $fp = 'File::Package';
     my $uut = 'File::PM2File';
     my $loaded = '';
     # Use the test file as an example since no its absolue path
     # Calculate the absolute file, relative file, and include directory
     my $relative_file = File::Spec->catfile('t', 'File', 'PM2File.pm'); 
     my $restore_dir = cwd();
     chdir File::Spec->updir();
     chdir File::Spec->updir();
     my $include_dir = cwd();
     chdir $restore_dir;
     my $OS = $^^O;  # need to escape ^^
     unless ($OS) {   # on some perls $^^O is not defined
         require Config;
         $OS = $Config::Config{'osname'};
     } 
     $include_dir =~ s=/=\\=g if( $^^O eq 'MSWin32');
     my $absolute_file = File::Spec->catfile($include_dir, 't', 'File', 'PM2File.pm');
     $absolute_file =~ s=.t$=.pm=;
     # Put base directory as the first in the @INC path
     my @restore_inc = @INC;
     unshift @INC, $include_dir;
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded('File::PM2File')^
  E:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  S: $loaded^
  A: my $errors = $fp->load_package( 'File::PM2File' )^
 SE: ''^
 ok: 2^

=head2 ok: 3

  N: pm2require^
  A: $uut->pm2require( "$uut")^
  E: File::Spec->catfile('File', 'PM2File' . '.pm')^
 ok: 3^

=head2 ok: 4

  N: find_in_include^
  A: [my @actual =  $uut->find_in_include( $relative_file )]^
  E: [$absolute_file, $include_dir]^
 ok: 4^

=head2 ok: 5

  N: pm2file^
  A: [@actual = $uut->pm2file( 't::File::PM2File' )]^
  E: [$absolute_file, $include_dir, $relative_file]^
 ok: 5^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------


=cut

#######
#  
#  6. NOTES
#
#

=head1 NOTES

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

/=over 4

/=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

/=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

/=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
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

#######
#
#  2. REFERENCED DOCUMENTS
#
#
#

=head1 SEE ALSO

L<File::PM2File>

=back

=for html
<hr>
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
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

__DATA__

File_Spec: Unix^
UUT: File::PM2File^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: PM2File.d^
Verify: PM2File.t^


 T: 5^


 C:
    use File::Spec;
    use File::Package;
    my $fp = 'File::Package';
    my $uut = 'File::PM2File';
    my $loaded = '';

    # Use the test file as an example since no its absolue path
    # Calculate the absolute file, relative file, and include directory
    my $relative_file = File::Spec->catfile('t', 'File', 'PM2File.pm'); 

    my $restore_dir = cwd();
    chdir File::Spec->updir();
    chdir File::Spec->updir();
    my $include_dir = cwd();
    chdir $restore_dir;
    my $OS = $^^O;  # need to escape ^^
    unless ($OS) {   # on some perls $^^O is not defined
        require Config;
        $OS = $Config::Config{'osname'};
    } 
    $include_dir =~ s=/=\\=g if( $^^O eq 'MSWin32');
    my $absolute_file = File::Spec->catfile($include_dir, 't', 'File', 'PM2File.pm');
    $absolute_file =~ s=.t$=.pm=;

    # Put base directory as the first in the @INC path
    my @restore_inc = @INC;
    unshift @INC, $include_dir;
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded('File::PM2File')^
 E:  ''^
ok: 1^

 N: Load UUT^
 S: $loaded^
 A: my $errors = $fp->load_package( 'File::PM2File' )^
SE: ''^
ok: 2^

 N: pm2require^
 A: $uut->pm2require( "$uut")^
 E: File::Spec->catfile('File', 'PM2File' . '.pm')^
ok: 3^

 N: find_in_include^
 A: [my @actual =  $uut->find_in_include( $relative_file )]^
 E: [$absolute_file, $include_dir]^
ok: 4^

 N: pm2file^
 A: [@actual = $uut->pm2file( 't::File::PM2File' )]^
 E: [$absolute_file, $include_dir, $relative_file]^
ok: 5^

 C: @INC = @restore_inc^

See_Also: L<File::PM2File>^

Copyright:
copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

/=over 4

/=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

/=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

/=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
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
^


HTML:
<hr>
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
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>
^



~-~
