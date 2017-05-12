#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::File::Maker;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.03';
$DATE = '2004/05/10';
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

 Perl File::Maker Program Module

 Revision: -

 Version: 

 Date: 2004/05/10

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<File::Maker|File::Maker>

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

 T: 12^

=head2 ok: 1


  C:
     use File::Package;
     my $fp = 'File::Package';
     my $loaded = '';
     use File::SmartNL;
     my $snl = 'File::SmartNL';
     use File::Spec;
     my @inc = @INC;
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded('_Maker_::MakerDB')^
  E:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  S: $loaded^
  C: my $errors = $fp->load_package( '_Maker_::MakerDB' )^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3

 DO: ^
  A: $snl->fin(File::Spec->catfile('_Maker_','MakerDB.pm'))^
  N: No target^
  C: my $maker = new _Maker_::MakerDB( pm => '_Maker_::MakerDB' )^
  A: $maker->make( )^
  E: ' target1  target2 '^
 ok: 3^

=head2 ok: 4

  N: FormDB_File^
  A: $maker->{FormDB_File}^
  E: File::Spec->rel2abs(File::Spec->catfile('_Maker_','MakerDB.pm'))^
 ok: 4^

=head2 ok: 5

  N: FormDB_PM^
  A: $maker->{FormDB_PM}^
  E: '_Maker_::MakerDB'^
 ok: 5^

=head2 ok: 6

  N: FormDB_Record^
  A: $maker->{FormDB_Record}^

  E:
 '
 Revision: -^^
 End_User: General Public^^
 Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^^
 Version: ^^
 Classification: None^^
 ~-~
 '
 ^
 ok: 6^

=head2 ok: 7

  N: FormDB^
  A: $maker->{FormDB}^

  E:
 [
   'Revision' => '-',
   'End_User' => 'General Public',
   'Author' => 'http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com',
   'Version' => '',
   'Classification' => 'None'
 ]
 ^
 ok: 7^

=head2 ok: 8

  N: Target all^
  A: $maker->make( 'all' )^
  E: ' target1  target2 '^
 ok: 8^

=head2 ok: 9

  N: Unsupport target^
  A: $maker->make( 'xyz' )^
  E: ' target3  target4  target5 '^
 ok: 9^

=head2 ok: 10

  N: target3^
  A: $maker->make( 'target3' )^
  E: ' target1  target3 '^
 ok: 10^

=head2 ok: 11

  N: target3 target4^
  A: $maker->make( qw(target3 target4) )^
  E: ' target1  target3  target1  target2  target4 '^
 ok: 11^

=head2 ok: 12

  N: Include stayed same^
  A: [@INC]^
  E: [@inc]^
 ok: 12^



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

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

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

L<File::Maker>

=back

=for html


=cut

__DATA__

File_Spec: Unix^
UUT: File::Maker^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: Maker.d^
Verify: Maker.t^


 T: 12^


 C:
    use File::Package;
    my $fp = 'File::Package';
    my $loaded = '';

    use File::SmartNL;
    my $snl = 'File::SmartNL';

    use File::Spec;

    my @inc = @INC;
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded('_Maker_::MakerDB')^
 E:  ''^
ok: 1^

 N: Load UUT^
 S: $loaded^
 C: my $errors = $fp->load_package( '_Maker_::MakerDB' )^
 A: $errors^
SE: ''^
ok: 2^

DO: ^
 A: $snl->fin(File::Spec->catfile('_Maker_','MakerDB.pm'))^
 N: No target^
 C: my $maker = new _Maker_::MakerDB( pm => '_Maker_::MakerDB' )^
 A: $maker->make( )^
 E: ' target1  target2 '^
ok: 3^

 N: FormDB_File^
 A: $maker->{FormDB_File}^
 E: File::Spec->rel2abs(File::Spec->catfile('_Maker_','MakerDB.pm'))^
ok: 4^

 N: FormDB_PM^
 A: $maker->{FormDB_PM}^
 E: '_Maker_::MakerDB'^
ok: 5^

 N: FormDB_Record^
 A: $maker->{FormDB_Record}^

 E:
'

Revision: -^^
End_User: General Public^^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^^
Version: ^^
Classification: None^^

~--~
'
^

ok: 6^

 N: FormDB^
 A: $maker->{FormDB}^

 E:
[
  'Revision' => '-',
  'End_User' => 'General Public',
  'Author' => 'http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com',
  'Version' => '',
  'Classification' => 'None'
]
^

ok: 7^

 N: Target all^
 A: $maker->make( 'all' )^
 E: ' target1  target2 '^
ok: 8^

 N: Unsupport target^
 A: $maker->make( 'xyz' )^
 E: ' target3  target4  target5 '^
ok: 9^

 N: target3^
 A: $maker->make( 'target3' )^
 E: ' target1  target3 '^
ok: 10^

 N: target3 target4^
 A: $maker->make( qw(target3 target4) )^
 E: ' target1  target3  target1  target2  target4 '^
ok: 11^

 N: Include stayed same^
 A: [@INC]^
 E: [@inc]^
ok: 12^


See_Also: L<File::Maker>^

Copyright:
copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

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

HTML: ^


~-~
