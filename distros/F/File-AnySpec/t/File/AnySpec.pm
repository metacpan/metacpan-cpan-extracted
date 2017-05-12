#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::File::AnySpec;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.02';
$DATE = '2004/04/09';
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

 Perl File::AnySpec Program Module

 Revision: -

 Version: 

 Date: 2004/04/09

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<File::AnySpec|File::AnySpec>

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
     use File::Spec;
     use File::Package;
     my $fp = 'File::Package';
     my $as = 'File::AnySpec';
     my $loaded = '';
     my @drivers;
     my @files;
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded($as)^
  E:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  R: L<DataPort::DataFile/general [1] - load>^
  S: $loaded^
  C: my $errors = $fp->load_package( $as)^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3

  N: fspec2fspec^
  A: $as->fspec2fspec( 'Unix', 'MSWin32', 'File/FileUtil.pm')^
  E: 'File\\FileUtil.pm'^
 ok: 3^

=head2 ok: 4

  N: fspec2os os2fspec 1^
  A: $as->os2fspec( 'Unix', ($as->fspec2os( 'Unix', 'File/FileUtil.pm')))^
  E: 'File/FileUtil.pm'^
 ok: 4^

=head2 ok: 5

  N: fspec2os os2fspec 2^
  A: $as->os2fspec( 'MSWin32', ($as->fspec2os( 'MSWin32', 'Test\\TestUtil.pm')))^
  E: 'Test\\TestUtil.pm'^
 ok: 5^

=head2 ok: 6

  N: fspec_glob Unix^
  C: @drivers = sort $as->fspec_glob('Unix','Drivers/G*.pm')^
  A: join (', ', @drivers)^
  E: File::Spec->catfile('Drivers', 'Generate.pm')^
 ok: 6^

=head2 ok: 7

  N: fspec2pm^
  A: $as->fspec2pm('Unix', 'File/AnySpec.pm')^
  E: "$as"^
 ok: 7^

=head2 ok: 8

 DO: ^
  N: pm2fspec^
  A: $as->pm2fspec( 'Unix', 'File::Basename')^
 VO: ^
  N: pm2fspec^
  C: @files = $as->pm2fspec( 'Unix', 'File::Basename')^
  A: $files[-1]^
  E: 'File/Basename.pm'^
 ok: 8^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<DataPort::DataFile/general [1] - load>                         L<t::File::AnySpec/ok: 2>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::File::AnySpec/ok: 2>                                        L<DataPort::DataFile/general [1] - load>


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

L<File::AnySpec>

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
UUT: File::AnySpec^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: AnySpec.d^
Verify: AnySpec.t^


 T: 8^


 C:
    use File::Spec;

    use File::Package;
    my $fp = 'File::Package';

    my $as = 'File::AnySpec';

    my $loaded = '';
    my @drivers;
    my @files;
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded($as)^
 E:  ''^
ok: 1^

 N: Load UUT^
 R: L<DataPort::DataFile/general [1] - load>^
 S: $loaded^
 C: my $errors = $fp->load_package( $as)^
 A: $errors^
SE: ''^
ok: 2^

 N: fspec2fspec^
 A: $as->fspec2fspec( 'Unix', 'MSWin32', 'File/FileUtil.pm')^
 E: 'File\\FileUtil.pm'^
ok: 3^

 N: fspec2os os2fspec 1^
 A: $as->os2fspec( 'Unix', ($as->fspec2os( 'Unix', 'File/FileUtil.pm')))^
 E: 'File/FileUtil.pm'^
ok: 4^

 N: fspec2os os2fspec 2^
 A: $as->os2fspec( 'MSWin32', ($as->fspec2os( 'MSWin32', 'Test\\TestUtil.pm')))^
 E: 'Test\\TestUtil.pm'^
ok: 5^

 N: fspec_glob Unix^
 C: @drivers = sort $as->fspec_glob('Unix','Drivers/G*.pm')^
 A: join (', ', @drivers)^
 E: File::Spec->catfile('Drivers', 'Generate.pm')^
ok: 6^

 N: fspec2pm^
 A: $as->fspec2pm('Unix', 'File/AnySpec.pm')^
 E: "$as"^
ok: 7^

DO: ^
 N: pm2fspec^
 A: $as->pm2fspec( 'Unix', 'File::Basename')^
VO: ^
 N: pm2fspec^
 C: @files = $as->pm2fspec( 'Unix', 'File::Basename')^
 A: $files[-1]^
 E: 'File/Basename.pm'^
ok: 8^


See_Also: L<File::AnySpec>^

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
