#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::File::SmartNL;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2004/05/03';
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

 Perl File::SmartNL Program Module

 Revision: -

 Version: 

 Date: 2004/05/03

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<File::SmartNL|File::SmartNL>

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

 T: 8^

=head2 ok: 1


  C:
     use File::Package;
     my $fp = 'File::Package';
     my $uut = 'File::SmartNL';
     my $loaded = '';
     my $expected = '';
     my $data = '';
 VO:
 ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded('File::Where')^
  E:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  S: $loaded^
  C: my $errors = $fp->load_package($uut, 'config')^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3


  C:
    unlink 'test.pm';
    $expected = "=head1 Title Page\n\nSoftware Version Description\n\nfor\n\n";
    $uut->fout( 'test.pm', $expected, {binary => 1} );
 ^
  N: fout Unix fin^
  A: $uut->fin( 'test.pm' )^
  E: $expected^
 ok: 3^

=head2 ok: 4


  C:
    unlink 'test.pm';
    $data = "=head1 Title Page\r\n\r\nSoftware Version Description\r\n\r\nfor\r\n\r\n";
    $uut->fout( 'test.pm', $data, {binary => 1} );
 ^
  N: fout Dos Fin^
  A: $uut->fin('test.pm')^
  E: $expected^
 ok: 4^

=head2 ok: 5


  C:
   unlink 'test.pm';
   $data =   "line1\015\012line2\012\015line3\012line4\015";
   $expected = "line1\nline2\nline3\nline4\n";
 ^
  N: smart_nl^
  A: $uut->smart_nl($data)^
  E: $expected^
 ok: 5^

=head2 ok: 6

  N: read configuration^
  A: [config('binary')]^
  E: ['binary',0]^
 ok: 6^

=head2 ok: 7

  N: write configuration^
  A: [config('binary',1)]^
  E: ['binary',0]^
 ok: 7^

=head2 ok: 8

  N: verify write configuration^
  A: [config('binary')]^
  E: ['binary',1]^
 ok: 8^



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

copyright © 2004 Software Diamonds.

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

L<File::SmartNL>

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
UUT: File::SmartNL^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: SmartNL.d^
Verify: SmartNL.t^


 T: 8^


 C:
    use File::Package;
    my $fp = 'File::Package';

    my $uut = 'File::SmartNL';
    my $loaded = '';
    my $expected = '';
    my $data = '';

VO:
^

 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded('File::Where')^
 E:  ''^
ok: 1^

 N: Load UUT^
 S: $loaded^
 C: my $errors = $fp->load_package($uut, 'config')^
 A: $errors^
SE: ''^
ok: 2^


 C:
   unlink 'test.pm';
   $expected = "=head1 Title Page\n\nSoftware Version Description\n\nfor\n\n";
   $uut->fout( 'test.pm', $expected, {binary => 1} );
^

 N: fout Unix fin^
 A: $uut->fin( 'test.pm' )^
 E: $expected^
ok: 3^


 C:
   unlink 'test.pm';
   $data = "=head1 Title Page\r\n\r\nSoftware Version Description\r\n\r\nfor\r\n\r\n";
   $uut->fout( 'test.pm', $data, {binary => 1} );
^

 N: fout Dos Fin^
 A: $uut->fin('test.pm')^
 E: $expected^
ok: 4^


 C:
  unlink 'test.pm';
  $data =   "line1\015\012line2\012\015line3\012line4\015";
  $expected = "line1\nline2\nline3\nline4\n";
^

 N: smart_nl^
 A: $uut->smart_nl($data)^
 E: $expected^
ok: 5^

 N: read configuration^
 A: [config('binary')]^
 E: ['binary',0]^
ok: 6^

 N: write configuration^
 A: [config('binary',1)]^
 E: ['binary',0]^
ok: 7^

 N: verify write configuration^
 A: [config('binary')]^
 E: ['binary',1]^
ok: 8^


See_Also: L<File::SmartNL>^

Copyright:
copyright © 2004 Software Diamonds.

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
