#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::File::Package;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.02';
$DATE = '2004/04/10';
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

 Perl File::Package Program Module

 Revision: -

 Version: 

 Date: 2004/04/10

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<File::Package|File::Package>

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

 T: 14^

=head2 ok: 1


  C:
     use File::Package;
     my $uut = 'File::Package';
 ^
 VO: ^
  N: UUT loaded^
  A: my $loaded = $uut->is_package_loaded('File::Package')^
  E:  '1'^
 ok: 1^

=head2 ok: 2

  N: Good Load^
  A: my $error = $uut->load_package( 'File::Basename' )^
  E: ''^
 ok: 2^

=head2 ok: 3

 DO: ^
  A: $error = $uut->load_package( '_File_::BadLoad' )^
 VO: ^
  N: Bad Load^
  C: $error = $uut->load_package( '_File_::BadLoad' )^
 DM: $error^
  A: $error =~ /^^Cannot load _File_::BadLoad/ ? 1 : 0^
  E: 1^
 ok: 3^

=head2 ok: 4

 DO: ^
  A: $uut->load_package( '_File_::BadPackage' )^
 VO: ^
  N: File Loads, Package absent^
  C: $error = $uut->load_package( '_File_::BadPackage' )^
 DM: $error^
  A: $error =~ /_File_::BadPackage absent./ ? 1 : 0^
  E: 1^
 ok: 4^

=head2 ok: 5

 DO: ^
  A: $uut->load_package( '_File_::Multi' )^
 VO: ^
  N: Multiple Package Load^

  A:
 $error = $uut->load_package( '_File_::Multi', 
         [qw(File::Package1  File::Package2 File::Package3)] )
 ^
  E: ''^
 ok: 5^

=head2 ok: 6

 DO: ^
  A: $error = $uut->load_package( '_File_::Hyphen-Test' )^
 VO: ^
  N: File::Hyphen-Test Load^
  C: $error = $uut->load_package( '_File_::Hyphen-Test' )^
 DM: $error^
  A: $error ? 1 : 0^
  E: 1^
 ok: 6^

=head2 ok: 7

  N: No &File::Find::find import baseline^
  A: !defined($main::{'find'})^
  E: 1^
 ok: 7^

=head2 ok: 8

  N: Load File::Find, Import &File::Find::find^
  A: $error = $uut->load_package( 'File::Find', 'find', ['File::Find'] )^
  E: ''^
 ok: 8^

=head2 ok: 9

  N: &File::Find::find imported^
  A: defined($main::{'find'})^
  E: '1'^
 ok: 9^

=head2 ok: 10

  N: &File::Find::finddepth not imported^
  A: !defined($main::{'finddepth'})^
  E: 1^
 ok: 10^

=head2 ok: 11

 DO: ^
  N: Import error^
  A: $uut->load_package( 'File::Find', 'Jolly_Green_Giant')^
 VO: ^
  N: Import error^
  A: $error = 0 < length($uut->load_package( 'File::Find', 'Jolly_Green_Giant'))^
  E: '1'^
 ok: 11^

=head2 ok: 12

  N: &File::Find::finddepth still no imported^
  A: !defined($main::{'finddepth'})^
  E: 1^
 ok: 12^

=head2 ok: 13

  N: Import all File::Find functions^
  A: $error = $uut->load_package( 'File::Find', '')^
  E: ''^
 ok: 13^

=head2 ok: 14

  N: &File::Find::finddepth imported^
  A: defined($main::{'finddepth'})^
  E: '1'^
 ok: 14^



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

L<File::Package>

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
UUT: File::Package^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: Package.d^
Verify: Package.t^


 T: 14^


 C:
    use File::Package;
    my $uut = 'File::Package';
^

VO: ^
 N: UUT loaded^
 A: my $loaded = $uut->is_package_loaded('File::Package')^
 E:  '1'^
ok: 1^

 N: Good Load^
 A: my $error = $uut->load_package( 'File::Basename' )^
 E: ''^
ok: 2^

DO: ^
 A: $error = $uut->load_package( '_File_::BadLoad' )^
VO: ^
 N: Bad Load^
 C: $error = $uut->load_package( '_File_::BadLoad' )^
DM: $error^
 A: $error =~ /^^Cannot load _File_::BadLoad/ ? 1 : 0^
 E: 1^
ok: 3^

DO: ^
 A: $uut->load_package( '_File_::BadPackage' )^
VO: ^
 N: File Loads, Package absent^
 C: $error = $uut->load_package( '_File_::BadPackage' )^
DM: $error^
 A: $error =~ /_File_::BadPackage absent./ ? 1 : 0^
 E: 1^
ok: 4^

DO: ^
 A: $uut->load_package( '_File_::Multi' )^
VO: ^
 N: Multiple Package Load^

 A:
$error = $uut->load_package( '_File_::Multi', 
        [qw(File::Package1  File::Package2 File::Package3)] )
^

 E: ''^
ok: 5^

DO: ^
 A: $error = $uut->load_package( '_File_::Hyphen-Test' )^
VO: ^
 N: File::Hyphen-Test Load^
 C: $error = $uut->load_package( '_File_::Hyphen-Test' )^
DM: $error^
 A: $error ? 1 : 0^
 E: 1^
ok: 6^

 N: No &File::Find::find import baseline^
 A: !defined($main::{'find'})^
 E: 1^
ok: 7^

 N: Load File::Find, Import &File::Find::find^
 A: $error = $uut->load_package( 'File::Find', 'find', ['File::Find'] )^
 E: ''^
ok: 8^

 N: &File::Find::find imported^
 A: defined($main::{'find'})^
 E: '1'^
ok: 9^

 N: &File::Find::finddepth not imported^
 A: !defined($main::{'finddepth'})^
 E: 1^
ok: 10^

DO: ^
 N: Import error^
 A: $uut->load_package( 'File::Find', 'Jolly_Green_Giant')^
VO: ^
 N: Import error^
 A: $error = 0 < length($uut->load_package( 'File::Find', 'Jolly_Green_Giant'))^
 E: '1'^
ok: 11^

 N: &File::Find::finddepth still no imported^
 A: !defined($main::{'finddepth'})^
 E: 1^
ok: 12^

 N: Import all File::Find functions^
 A: $error = $uut->load_package( 'File::Find', '')^
 E: ''^
ok: 13^

 N: &File::Find::finddepth imported^
 A: defined($main::{'finddepth'})^
 E: '1'^
ok: 14^


See_Also: L<File::Package>^

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
