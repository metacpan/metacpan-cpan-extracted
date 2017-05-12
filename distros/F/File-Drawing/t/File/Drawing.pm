#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::File::Drawing;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2004/05/04';
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

 Perl File::Drawing Program Module

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
requirements of Perl Program Module (PM) L<File::Drawing|File::Drawing>

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

 T: 61^

=head2 ok: 1


  C:
     use File::Package;
     use File::SmartNL;
     use File::Path;
     use File::Copy;
     my $fp = 'File::Package';
     my $uut = 'File::Drawing';
     my $loaded;
     my $artists1;
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded($uut)^
  E:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  R: L<Data::Filer/general [1] - load>^
  S: $loaded^
  C: my $errors = $fp->load_package($uut)^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3

  N: pm2number^
  A: $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','_Drawings_::Repository0')^
  E: 'Artists_M::Madonna::Erotica'^
 ok: 3^

=head2 ok: 4

  N: pm2number, empty repository^
  A: $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','')^
  E: '_Drawings_::Repository0::Artists_M::Madonna::Erotica'^
 ok: 4^

=head2 ok: 5

  N: pm2number, no repository^
  A: $uut->pm2number('Etc::Artists_M::Madonna::Erotica')^
  E: 'Artists_M::Madonna::Erotica'^
 ok: 5^

=head2 ok: 6

  N: number2pm^
  A: $uut->number2pm('Artists_M::Madonna::Erotica','_Drawings_::Repository0')^
  E: '_Drawings_::Repository0::Artists_M::Madonna::Erotica'^
 ok: 6^

=head2 ok: 7

  N: number2pm, empty repository^
  A: $uut->number2pm('Artists_M::Madonna::Erotica','')^
  E: 'Artists_M::Madonna::Erotica'^
 ok: 7^

=head2 ok: 8

  N: number2pm, no repository^
  A: $uut->number2pm('Artists_M::Madonna::Erotica')^
  E: 'Etc::Artists_M::Madonna::Erotica'^
 ok: 8^

=head2 ok: 9

  N: dod_date^
  A: $uut->dod_date(25, 34, 36, 5, 1, 104)^
  E: '2004/02/05 36:34:25'^
 ok: 9^

=head2 ok: 10

  N: dod_drawing_number^
  A: length($uut->dod_drawing_number())^
  E: 11^
 ok: 10^

=head2 ok: 11

  N: Repository0 exists^

  C:
    ####
    # Drawing must find the below directory in the @INC paths
    # in order to perform this test.
    #
 ^
  A: -d (File::Spec->catfile( qw(_Drawings_ Repository0)))^
 SE: 1^
 ok: 11^

=head2 ok: 12

  N: Created Repository1^

  C:
    ####
    # Drawing must find the below directory in the @INC paths
    # in order to perform this test.
    #     
    rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));
    mkpath (File::Spec->catdir( qw(_Drawings_ Repository1) ));
 ^
  A: -d (File::Spec->catfile( qw(_Drawings_ Repository1)))^
 SE: 1^
 ok: 12^

=head2 ok: 13

  N: Retrieve erotica source control drawing^
  C: my $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository0')^
 DM: $erotica2^
  A: ref($erotica2)^
 SE: 'File::Drawing'^
 ok: 13^

=head2 ok: 14

  N: Release erotica to different repository^
  C:  my $error= $erotica2->release(revise_repository => '_Drawings_::Repository1::' )^
  A: $error^
 SE: ''^
 ok: 14^

=head2 ok: 15

  N: Retrieve erotica^
  C: my $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');^
 DM: $erotica1^
  A: ref($erotica1)^
 SE: 'File::Drawing'^
 ok: 15^

=head2 ok: 16

  N: Erotica contents unchanged^
  A:  $erotica1->[0]^
  E:  $erotica2->[0]^
 ok: 16^

=head2 ok: 17

 VO: ^
  N: Erotica rev - white tape date changed^

  C:
      $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
      $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
      $erotica2->[1]->{file} = $erotica1->[1]->{file};
 ^
  A:  $erotica1->[1]^
  E:  $erotica2->[1]^
 ok: 17^

=head2 ok: 18

 DO: ^
  A:  $erotica1->[1]^
 VO: ^
  N: Revise erotica unchanged^
  C:     $error= $erotica2->revise( );^
  A: $error^
 SE: ''^
 ok: 18^

=head2 ok: 19

 VO: ^
  N: Retrieve erotica unchanged^

  C:
      $erotica2 = $erotica1;
      $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
 ^
 VO: ^
 DM: $erotica1^
  A: ref($erotica1)^
 SE: 'File::Drawing'^
 ok: 19^

=head2 ok: 20

 VO: ^
  N: Erotica unchanged contents unchanged^
  A: $erotica1->[0]^
  E: $erotica2->[0]^
 ok: 20^

=head2 ok: 21

 VO: ^
  N: Erotica unchanged white tape unchanged^
  A: $erotica1->[1]^
  E: $erotica2->[1]^
 ok: 21^

=head2 ok: 22

 VO: ^
  N: Revise erotica contents^

  C:
     my $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
     $erotica2->[0]->{in_house}->{num_media} =  1;
     $error = $erotica2->revise();
 ^
  A: $error^
 SE: ''^
 ok: 22^

=head2 ok: 23

 DO: ^
  N: Revise erotica contents^

  C:
     $erotica2->[0]->{in_house}->{num_media} =  1;
     $error = $erotica2->revise();
 ^
  A: $error^
 SE: ''^
 VO: ^
  N: Obsolete erotica^
  A: File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica.pm)))^
  E: $file_contents2^
 ok: 23^

=head2 ok: 24

 DO: ^
  A: -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica.pm))^
  N: Retrieve erotica, revision 1^
  C: $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');^
 DM: $erotica1^
  A: ref($erotica1)^
 SE: 'File::Drawing'^
 ok: 24^

=head2 ok: 25

  N: Erotica Revision 1 contents revised^
  A: $erotica1->[0]^
  E: $erotica2->[0]^
 ok: 25^

=head2 ok: 26

 VO: ^
  N: Erotica Revision 1 white tape revised^

  C:
      $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
      $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
      $erotica2->[1]->{version} = '0.02';
      $erotica2->[1]->{revision} = '1';
 ^
  A:  $erotica1->[1]^
  E:  $erotica2->[1]^
 ok: 26^

=head2 ok: 27

 DO: ^
  A: $erotica1->[1]->{version}^
 DO: ^
  A: $erotica1->[1]->{revision}^
 DO: ^
  A: $erotica1->[1]->{date_gm}^
 DO: ^
  A: $erotica1->[1]->{date_loc}^
 VO: ^
  N: Revise erotica revision 1 white tape^

  C:
     $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
     $erotica2->[1]->{classification} = 'Top Secret';
     $error = $erotica2->revise();
 ^
  A: $error^
 SE: ''^
 ok: 27^

=head2 ok: 28

 DO: ^

  C:
     $erotica2->[1]->{classification} = 'Top Secret';
     $error = $erotica2->revise();
 ^
  A: $error^
 SE: ''^
 VO: ^
  N: Obsolete erotica revision 1^
  A: File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-1.pm)))^
  E: $file_contents2^
 ok: 28^

=head2 ok: 29

 DO: ^
  A: -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-01.pm))^
  N: Retrieve erotica revision 2^
  C: $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');^
 DM: $erotica1^
  A: ref($erotica1)^
 SE: 'File::Drawing'^
 ok: 29^

=head2 ok: 30

 VO: ^
  N: Erotica revision 2 contents unchanged^
  A: $erotica1->[0]^
  E: $erotica2->[0]^
 ok: 30^

=head2 ok: 31

 VO: ^
  N: Erotica revision 2 white tape revised^

  C:
      $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
      $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
      $erotica2->[1]->{version} = '0.03';
      $erotica2->[1]->{revision} = '2';
 ^
  A:  $erotica1->[1]^
  E:  $erotica2->[1]^
 ok: 31^

=head2 ok: 32

 DO: ^
  A:  $erotica1->[1]^
  E:  $erotica2->[1]^
  N: Retrieve _Drawings_::Erotica^
  C: $erotica2 = $uut->retrieve('_Drawings_::Erotica', repository => '');^
 DM: $erotica2^
  A: ref($erotica2)^
 SE: 'File::Drawing'^
 ok: 32^

=head2 ok: 33

 VO: ^
  N: Revise erotica revision 2^

  C:
     $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
     $error = $erotica2->revise(revise_drawing_number=>'Artists_M::Madonna::Erotica', revise_repository=>'_Drawings_::Repository1');
 ^
  A: $error^
 SE: ''^
 ok: 33^

=head2 ok: 34

 DO: ^
  N: Revise erotica revision 2^

  C:
 $error = $erotica2->revise(revise_drawing_number=>'Artists_M::Madonna::Erotica', revise_repository=>'_Drawings_::Repository1');
 ^
  A: $error^
 SE: ''^
 VO: ^
  N: Obsolete erotica revision 2^
  A: File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-2.pm)))^
  E: $file_contents2^
 ok: 34^

=head2 ok: 35

 DO: ^
  A: -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-2.pm))^
  N: Retrieve erotica revision 3^
  C: $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');^
 DM: $erotica1^
  A: ref($erotica1)^
 SE: 'File::Drawing'^
 ok: 35^

=head2 ok: 36

 VO: ^
  N: Erotica revision 3 contents unchanged^
  A: $erotica1->[0]^
  E: $erotica2->[0]^
 ok: 36^

=head2 ok: 37

 VO: ^
  N: Erotica revision 3 white tape revised^

  C:
      $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
      $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
      $erotica2->[1]->{version} = '0.04';
      $erotica2->[1]->{revision} = '3';
 ^
  A:  $erotica1->[1]^
  E:  $erotica2->[1]^
 ok: 37^

=head2 ok: 38

 DO: ^
  A: $erotica1->[1]->{version}^
 DO: ^
  A: $erotica1->[1]->{revision}^
 DO: ^
  A: $erotica1->[1]->{date_gm}^
 DO: ^
  A: $erotica1->[1]->{date_loc}^
  N: Erotica revision 3 file contents revised^
  A:  $erotica1->[3]^

  E:
 '#!/usr/bin/perl
 #
 #
 package _Drawings_::Repository1::Artists_M::Madonna::Erotica;
 use strict;
 use warnings;
 use warnings::register;
 #<-- BLK ID="DRAWING" -->
 #<-- /BLK -->
 #####
 # This section may be used for Perl subroutines and expressions.
 #
 print "Hello world from _Drawings_::Erotica\n";

 1
 '
 ^
 ok: 38^

=head2 ok: 39

  N: Retrieve Sandbox erotica^

  C:
    unshift @INC,'_Sandbox_';
    $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
 ^
 DM: $erotica2^
  A: ref($erotica2)^
 SE: 'File::Drawing'^
 ok: 39^

=head2 ok: 40

 VO: ^
  N: Revise erotica revision 3^

  C:
     $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
     shift @INC;
     $error = $erotica2->revise( );
 ^
  A: $error^
 SE: ''^
 ok: 40^

=head2 ok: 41

 DO: ^
  N: Revise erotica revision 3^

  C:
     shift @INC;
     $error = $erotica2->revise( );
 ^
  A: $error^
 VO: ^
  N: Obsolete erotica revision 3^
  A: File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-3.pm)))^
  E: $file_contents2^
 ok: 41^

=head2 ok: 42

 DO: ^
  A: -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-3.pm))^
  N: Retrieve erotica revision 4^
  C: $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1')^
 DM: $erotica1^
  A: ref($erotica1)^
 SE: 'File::Drawing'^
 ok: 42^

=head2 ok: 43

 VO: ^
  N: Erotica Revision 4 contents unchanged^
  A: $erotica1->[0]^
  E: $erotica2->[0]^
 ok: 43^

=head2 ok: 44

 VO: ^
  N: Erotica Revision 4 white tape revised^

  C:
      $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
      $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
      $erotica2->[1]->{version} = '0.05';
      $erotica2->[1]->{revision} = '4';
 ^
  A:  $erotica1->[1]^
  E:  $erotica2->[1]^
 ok: 44^

=head2 ok: 45

 DO: ^
  A: $erotica1->[1]->{version}^
 DO: ^
  A: $erotica1->[1]->{revision}^
 DO: ^
  A: $erotica1->[1]->{date_gm}^
 DO: ^
  A: $erotica1->[1]->{date_loc}^
  N: Erotica Revision 4 file contents revised^
  A:  $erotica1->[3]^

  E:
 '#!/usr/bin/perl
 #
 #
 package _Drawings_::Repository1::Artists_M::Madonna::Erotica;
 use strict;
 use warnings;
 use warnings::register;
 #<-- BLK ID="DRAWING" -->
 #<-- /BLK -->
 #####
 # This section may be used for Perl subroutines and expressions.
 #
 print "Hello world from Sandbox\n";

 1
 '
 ^
 ok: 45^

=head2 ok: 46

 VO: ^
  N: Retrieve index drawing artists^
  C: my $artists2 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository0')^
 DM: $artists2^
  A: ref($artists2)^
 SE: 'File::Drawing'^
 ok: 46^

=head2 ok: 47

 VO: ^
  N: Release artists to different repository^
  C: $error= $artists2->release(revise_repository =>  '_Drawings_::Repository1::')^
  A: $error^
 SE: ''^
 ok: 47^

=head2 ok: 48

 VO: ^
  N: Retrieve artists^
  C: $artists2 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository1');^
 DM: $artists2^
  A: ref($artists2)^
 SE: 'File::Drawing'^
 ok: 48^

=head2 ok: 49

 VO: ^
  N: Revise artists^

  C:
     $artists2->[0]->{browse} = ['Artists_M::Index'];
     $error = $artists2->revise();
 ^
  A: $error^
 SE: ''^
 ok: 49^

=head2 ok: 50

 VO: ^
  N: Obsolete artists^
  A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index.pm))^
  E: 1^
 ok: 50^

=head2 ok: 51

 VO: ^
  N: Revise artists revision 1^

  C:
     $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index'];
     $error = $artists2->revise();
 ^
 VO: ^
  A: $error^
 SE: ''^
 ok: 51^

=head2 ok: 52

 VO: ^
  N: Obsolete artists revision 1^
  A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-1.pm))^
  E: 1^
 ok: 52^

=head2 ok: 53

 VO: ^
  N: Revise artists revision 2^

  C:
     $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index','Artists_E::Index'];
     $error = $artists2->revise();
 ^
  A: $error^
 SE: ''^
 ok: 53^

=head2 ok: 54

 VO: ^
  N: Obsolete artists revision 2^
  A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-2.pm))^
  E: 1^
 ok: 54^

=head2 ok: 55

 VO: ^
  N: Destory artists^
  A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index.pm))^
  E: undef^
 ok: 55^

=head2 ok: 56

 VO: ^
  N: Revise artists revision 3^

  C:
     $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index','Artists_E::Index','Artists_F::Index'];
     $error = $artists2->revise();
 ^
  A: $error^
 SE: ''^
 ok: 56^

=head2 ok: 57

 VO: ^
  N: Obsolete artists revision 3^
  A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-3.pm))^
  E: 1^
 ok: 57^

=head2 ok: 58

 VO: ^
  N: Destory artists Revision 1^
  A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists IndexA.pm))^
  E: undef^
 ok: 58^

=head2 ok: 59

 VO: ^
  N: Retrieve broken artists revision 4^

  C:
     copy ( File::Spec->catfile(qw(_Drawings_ Repository0 Artists IndexBad.pm)),
            File::Spec->catfile(qw(_Drawings_ Repository1 Artists Index.pm)));
     $artists1 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository1');
 ^
 DM: $artists1^
  A: ref($artists1)^
 SE: ''^
 ok: 59^

=head2 ok: 60

 VO: ^
  N: Artists Revision 4 removed^
  A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Artists Index.pm))^
  E: undef^
 ok: 60^

=head2 ok: 61

 VO: ^
  N: Artists Revision 4 sequestered^
  A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Broken Artists Index.pm))^
  E: 1^
 ok: 61^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<Data::Filer/general [1] - load>                                L<t::File::Drawing/ok: 2>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::File::Drawing/ok: 2>                                        L<Data::Filer/general [1] - load>


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

=over 4

=item 1

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
UUT: File::Drawing^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: Drawing.d^
Verify: Drawing.t^


 T: 61^


 C:
    use File::Package;
    use File::SmartNL;
    use File::Path;
    use File::Copy;
    my $fp = 'File::Package';
    my $uut = 'File::Drawing';
    my $loaded;
    my $artists1;
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded($uut)^
 E:  ''^
ok: 1^

 N: Load UUT^
 R: L<Data::Filer/general [1] - load>^
 S: $loaded^
 C: my $errors = $fp->load_package($uut)^
 A: $errors^
SE: ''^
ok: 2^

 N: pm2number^
 A: $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','_Drawings_::Repository0')^
 E: 'Artists_M::Madonna::Erotica'^
ok: 3^

 N: pm2number, empty repository^
 A: $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','')^
 E: '_Drawings_::Repository0::Artists_M::Madonna::Erotica'^
ok: 4^

 N: pm2number, no repository^
 A: $uut->pm2number('Etc::Artists_M::Madonna::Erotica')^
 E: 'Artists_M::Madonna::Erotica'^
ok: 5^

 N: number2pm^
 A: $uut->number2pm('Artists_M::Madonna::Erotica','_Drawings_::Repository0')^
 E: '_Drawings_::Repository0::Artists_M::Madonna::Erotica'^
ok: 6^

 N: number2pm, empty repository^
 A: $uut->number2pm('Artists_M::Madonna::Erotica','')^
 E: 'Artists_M::Madonna::Erotica'^
ok: 7^

 N: number2pm, no repository^
 A: $uut->number2pm('Artists_M::Madonna::Erotica')^
 E: 'Etc::Artists_M::Madonna::Erotica'^
ok: 8^

 N: dod_date^
 A: $uut->dod_date(25, 34, 36, 5, 1, 104)^
 E: '2004/02/05 36:34:25'^
ok: 9^

 N: dod_drawing_number^
 A: length($uut->dod_drawing_number())^
 E: 11^
ok: 10^

 N: Repository0 exists^

 C:
   ####
   # Drawing must find the below directory in the @INC paths
   # in order to perform this test.
   #
^

 A: -d (File::Spec->catfile( qw(_Drawings_ Repository0)))^
SE: 1^
ok: 11^

 N: Created Repository1^

 C:
   ####
   # Drawing must find the below directory in the @INC paths
   # in order to perform this test.
   #     
   rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));
   mkpath (File::Spec->catdir( qw(_Drawings_ Repository1) ));
^

 A: -d (File::Spec->catfile( qw(_Drawings_ Repository1)))^
SE: 1^
ok: 12^

 N: Retrieve erotica source control drawing^
 C: my $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository0')^
DM: $erotica2^
 A: ref($erotica2)^
SE: 'File::Drawing'^
ok: 13^

 N: Release erotica to different repository^
 C:  my $error= $erotica2->release(revise_repository => '_Drawings_::Repository1::' )^
 A: $error^
SE: ''^
ok: 14^

 N: Retrieve erotica^
 C: my $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');^
DM: $erotica1^
 A: ref($erotica1)^
SE: 'File::Drawing'^
ok: 15^

 N: Erotica contents unchanged^
 A:  $erotica1->[0]^
 E:  $erotica2->[0]^
ok: 16^

VO: ^
 N: Erotica rev - white tape date changed^

 C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{file} = $erotica1->[1]->{file};
^

 A:  $erotica1->[1]^
 E:  $erotica2->[1]^
ok: 17^

DO: ^
 A:  $erotica1->[1]^
VO: ^
 N: Revise erotica unchanged^
 C:     $error= $erotica2->revise( );^
 A: $error^
SE: ''^
ok: 18^

VO: ^
 N: Retrieve erotica unchanged^

 C:
     $erotica2 = $erotica1;
     $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
^

VO: ^
DM: $erotica1^
 A: ref($erotica1)^
SE: 'File::Drawing'^
ok: 19^

VO: ^
 N: Erotica unchanged contents unchanged^
 A: $erotica1->[0]^
 E: $erotica2->[0]^
ok: 20^

VO: ^
 N: Erotica unchanged white tape unchanged^
 A: $erotica1->[1]^
 E: $erotica2->[1]^
ok: 21^

VO: ^
 N: Revise erotica contents^

 C:
    my $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
    $erotica2->[0]->{in_house}->{num_media} =  1;
    $error = $erotica2->revise();
^

 A: $error^
SE: ''^
ok: 22^

DO: ^
 N: Revise erotica contents^

 C:
    $erotica2->[0]->{in_house}->{num_media} =  1;
    $error = $erotica2->revise();
^

 A: $error^
SE: ''^
VO: ^
 N: Obsolete erotica^
 A: File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica.pm)))^
 E: $file_contents2^
ok: 23^

DO: ^
 A: -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica.pm))^
 N: Retrieve erotica, revision 1^
 C: $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');^
DM: $erotica1^
 A: ref($erotica1)^
SE: 'File::Drawing'^
ok: 24^

 N: Erotica Revision 1 contents revised^
 A: $erotica1->[0]^
 E: $erotica2->[0]^
ok: 25^

VO: ^
 N: Erotica Revision 1 white tape revised^

 C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{version} = '0.02';
     $erotica2->[1]->{revision} = '1';
^

 A:  $erotica1->[1]^
 E:  $erotica2->[1]^
ok: 26^

DO: ^
 A: $erotica1->[1]->{version}^
DO: ^
 A: $erotica1->[1]->{revision}^
DO: ^
 A: $erotica1->[1]->{date_gm}^
DO: ^
 A: $erotica1->[1]->{date_loc}^
VO: ^
 N: Revise erotica revision 1 white tape^

 C:
    $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
    $erotica2->[1]->{classification} = 'Top Secret';
    $error = $erotica2->revise();
^

 A: $error^
SE: ''^
ok: 27^

DO: ^

 C:
    $erotica2->[1]->{classification} = 'Top Secret';
    $error = $erotica2->revise();
^

 A: $error^
SE: ''^
VO: ^
 N: Obsolete erotica revision 1^
 A: File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-1.pm)))^
 E: $file_contents2^
ok: 28^

DO: ^
 A: -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-01.pm))^
 N: Retrieve erotica revision 2^
 C: $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');^
DM: $erotica1^
 A: ref($erotica1)^
SE: 'File::Drawing'^
ok: 29^

VO: ^
 N: Erotica revision 2 contents unchanged^
 A: $erotica1->[0]^
 E: $erotica2->[0]^
ok: 30^

VO: ^
 N: Erotica revision 2 white tape revised^

 C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{version} = '0.03';
     $erotica2->[1]->{revision} = '2';
^

 A:  $erotica1->[1]^
 E:  $erotica2->[1]^
ok: 31^

DO: ^
 A:  $erotica1->[1]^
 E:  $erotica2->[1]^
 N: Retrieve _Drawings_::Erotica^
 C: $erotica2 = $uut->retrieve('_Drawings_::Erotica', repository => '');^
DM: $erotica2^
 A: ref($erotica2)^
SE: 'File::Drawing'^
ok: 32^

VO: ^
 N: Revise erotica revision 2^

 C:
    $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
    $error = $erotica2->revise(revise_drawing_number=>'Artists_M::Madonna::Erotica', revise_repository=>'_Drawings_::Repository1');
^

 A: $error^
SE: ''^
ok: 33^

DO: ^
 N: Revise erotica revision 2^

 C:
$error = $erotica2->revise(revise_drawing_number=>'Artists_M::Madonna::Erotica', revise_repository=>'_Drawings_::Repository1');
^

 A: $error^
SE: ''^
VO: ^
 N: Obsolete erotica revision 2^
 A: File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-2.pm)))^
 E: $file_contents2^
ok: 34^

DO: ^
 A: -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-2.pm))^
 N: Retrieve erotica revision 3^
 C: $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');^
DM: $erotica1^
 A: ref($erotica1)^
SE: 'File::Drawing'^
ok: 35^

VO: ^
 N: Erotica revision 3 contents unchanged^
 A: $erotica1->[0]^
 E: $erotica2->[0]^
ok: 36^

VO: ^
 N: Erotica revision 3 white tape revised^

 C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{version} = '0.04';
     $erotica2->[1]->{revision} = '3';
^

 A:  $erotica1->[1]^
 E:  $erotica2->[1]^
ok: 37^

DO: ^
 A: $erotica1->[1]->{version}^
DO: ^
 A: $erotica1->[1]->{revision}^
DO: ^
 A: $erotica1->[1]->{date_gm}^
DO: ^
 A: $erotica1->[1]->{date_loc}^
 N: Erotica revision 3 file contents revised^
 A:  $erotica1->[3]^

 E:
'#!/usr/bin/perl
#
#
package _Drawings_::Repository1::Artists_M::Madonna::Erotica;

use strict;
use warnings;
use warnings::register;

#<-- BLK ID="DRAWING" -->
#<-- /BLK -->

#####
# This section may be used for Perl subroutines and expressions.
#
print "Hello world from _Drawings_::Erotica\n";


1
'
^

ok: 38^

 N: Retrieve Sandbox erotica^

 C:
   unshift @INC,'_Sandbox_';
   $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
^

DM: $erotica2^
 A: ref($erotica2)^
SE: 'File::Drawing'^
ok: 39^

VO: ^
 N: Revise erotica revision 3^

 C:
    $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
    shift @INC;
    $error = $erotica2->revise( );
^

 A: $error^
SE: ''^
ok: 40^

DO: ^
 N: Revise erotica revision 3^

 C:
    shift @INC;
    $error = $erotica2->revise( );
^

 A: $error^
VO: ^
 N: Obsolete erotica revision 3^
 A: File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-3.pm)))^
 E: $file_contents2^
ok: 41^

DO: ^
 A: -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-3.pm))^
 N: Retrieve erotica revision 4^
 C: $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1')^
DM: $erotica1^
 A: ref($erotica1)^
SE: 'File::Drawing'^
ok: 42^

VO: ^
 N: Erotica Revision 4 contents unchanged^
 A: $erotica1->[0]^
 E: $erotica2->[0]^
ok: 43^

VO: ^
 N: Erotica Revision 4 white tape revised^

 C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{version} = '0.05';
     $erotica2->[1]->{revision} = '4';
^

 A:  $erotica1->[1]^
 E:  $erotica2->[1]^
ok: 44^

DO: ^
 A: $erotica1->[1]->{version}^
DO: ^
 A: $erotica1->[1]->{revision}^
DO: ^
 A: $erotica1->[1]->{date_gm}^
DO: ^
 A: $erotica1->[1]->{date_loc}^
 N: Erotica Revision 4 file contents revised^
 A:  $erotica1->[3]^

 E:
'#!/usr/bin/perl
#
#
package _Drawings_::Repository1::Artists_M::Madonna::Erotica;

use strict;
use warnings;
use warnings::register;

#<-- BLK ID="DRAWING" -->
#<-- /BLK -->

#####
# This section may be used for Perl subroutines and expressions.
#
print "Hello world from Sandbox\n";


1
'
^

ok: 45^

VO: ^
 N: Retrieve index drawing artists^
 C: my $artists2 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository0')^
DM: $artists2^
 A: ref($artists2)^
SE: 'File::Drawing'^
ok: 46^

VO: ^
 N: Release artists to different repository^
 C: $error= $artists2->release(revise_repository =>  '_Drawings_::Repository1::')^
 A: $error^
SE: ''^
ok: 47^

VO: ^
 N: Retrieve artists^
 C: $artists2 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository1');^
DM: $artists2^
 A: ref($artists2)^
SE: 'File::Drawing'^
ok: 48^

VO: ^
 N: Revise artists^

 C:
    $artists2->[0]->{browse} = ['Artists_M::Index'];
    $error = $artists2->revise();
^

 A: $error^
SE: ''^
ok: 49^

VO: ^
 N: Obsolete artists^
 A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index.pm))^
 E: 1^
ok: 50^

VO: ^
 N: Revise artists revision 1^

 C:
    $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index'];
    $error = $artists2->revise();
^

VO: ^
 A: $error^
SE: ''^
ok: 51^

VO: ^
 N: Obsolete artists revision 1^
 A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-1.pm))^
 E: 1^
ok: 52^

VO: ^
 N: Revise artists revision 2^

 C:
    $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index','Artists_E::Index'];
    $error = $artists2->revise();
^

 A: $error^
SE: ''^
ok: 53^

VO: ^
 N: Obsolete artists revision 2^
 A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-2.pm))^
 E: 1^
ok: 54^

VO: ^
 N: Destory artists^
 A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index.pm))^
 E: undef^
ok: 55^

VO: ^
 N: Revise artists revision 3^

 C:
    $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index','Artists_E::Index','Artists_F::Index'];
    $error = $artists2->revise();
^

 A: $error^
SE: ''^
ok: 56^

VO: ^
 N: Obsolete artists revision 3^
 A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-3.pm))^
 E: 1^
ok: 57^

VO: ^
 N: Destory artists Revision 1^
 A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists IndexA.pm))^
 E: undef^
ok: 58^

VO: ^
 N: Retrieve broken artists revision 4^

 C:
    copy ( File::Spec->catfile(qw(_Drawings_ Repository0 Artists IndexBad.pm)),
           File::Spec->catfile(qw(_Drawings_ Repository1 Artists Index.pm)));
    $artists1 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository1');
^

DM: $artists1^
 A: ref($artists1)^
SE: ''^
ok: 59^

VO: ^
 N: Artists Revision 4 removed^
 A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Artists Index.pm))^
 E: undef^
ok: 60^

VO: ^
 N: Artists Revision 4 sequestered^
 A: -e  File::Spec->catfile(qw(_Drawings_ Repository1 Broken Artists Index.pm))^
 E: 1^
ok: 61^

 C: rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));^

See_Also: ^

Copyright:
copyright © 2004 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=back

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
