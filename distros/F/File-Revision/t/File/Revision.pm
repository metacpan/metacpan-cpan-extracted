#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::File::Revision;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.02';
$DATE = '2004/04/29';
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

 Perl File::Revision Program Module

 Revision: -

 Version: 

 Date: 2004/04/29

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<File::Revision|File::Revision>

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

 T: 26^

=head2 ok: 1


  C:
     use File::AnySpec;
     use File::Package;
     use File::Path;
     use File::Copy;
     my $fp = 'File::Package';
     my $uut = 'File::Revision';
     my ($file_spec, $from_file, $to_file);
     my ($backup_file, $rotate) = ('','');
     my $loaded = '';
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded($uut)^
  E:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  S: $loaded^
  C: my $errors = $fp->load_package($uut)^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3,5,7,9,11,13


 QC:
     my @revisions = (
     #  letter    number
     # -----------------
        ['-'   ,     0],
        ['Y'   ,    20],
        ['AA'  ,    21],
        ['WY'  ,   400],
        ['YY'  ,   420],
        ['AAA' ,   421],
     );
     my ($revision_letter, $revision_number);
     foreach (@revisions) {
        ($revision_letter, $revision_number) = @$_;
 ^
  N: revision2num(\'$revision_letter\')^
  A: $uut->revision2num($revision_letter)^
  E: $revision_number^
 ok: 3,5,7,9,11,13^

=head2 ok: 4,6,8,10,12,14

  N: num2revision(\'$revision_number\')^
  A: $uut->num2revision($revision_number)^
  E: $revision_letter^
 ok: 4,6,8,10,12,14^

=head2 ok: 15

 QC: };^
 VO: ^
  N: parse_options( 'myfile.myext', revision => 'AA', places => 3)^
  A: $uut->parse_options( 'myfile.myext', revision => 'AA', places => 3)^

  E:
 bless( { 
    base => 'myfile',
    dir => '',
    ext => '.myext', 
    lead_places => '_',
    places => 3,
    pre_revision => '-',
    rev_letters => 1,
    revision => 'AA',
    revision_number => 21,
    top_revision_number => 8000,
    vol => '',
  }, 'Data::Startup')
 ^
 ok: 15^

=head2 ok: 16

 VO: ^
  N: parse_options( 'myfile.myext', revision => 'WW')^
  A: $uut->parse_options( 'myfile.myext', revision => 'WW')^

  E:
 bless( { 
    base => 'myfile',
    dir => '',
    ext => '.myext', 
    lead_places => '',
    places => '',
    pre_revision => '-',
    rev_letters => 1,
    revision => 'WW',
    revision_number => 399,
    top_revision_number => '',
    vol => '',
  }, 'Data::Startup')
 ^
 ok: 16^

=head2 ok: 17

 VO: ^
  N: parse_options( 'myfile.myext', revision => 10, places => 3)^
  A: $uut->parse_options( 'myfile.myext', revision => 10, places => 3)^

  E:
 bless( { 
    base => 'myfile',
    dir => '',
    ext => '.myext', 
    lead_places => '0',
    places => 3,
    pre_revision => '-',
    rev_letters => 0,
    revision => 10,
    revision_number => 10,
    top_revision_number => '1000',
    vol => '',
  }, 'Data::Startup')
 ^
 ok: 17^

=head2 ok: 18

  N: revision_file( 7, parse_options( 'myfile.myext', pre_revision => '', revision => 'AA') )^

  A:
      $uut->revision_file( 7, $uut->parse_options( 'myfile.myext',
      pre_revision => '', revision => 'AA'))
 ^
  E: 'myfileG.myext'^
 ok: 18^

=head2 ok: 19

  N: new_revision(ext => '.bak', revision => 1, places => 6, pre_revision => '')^
  C: $file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm')^

  A:
     [$uut->new_revision($file_spec, ext => '.bak', revision => 1,
     places => 6, pre_revision => '')]
 ^
  E: [File::AnySpec->fspec2os('Unix','_Drawings_/Erotica000001.bak'), '2']^
 ok: 19^

=head2 ok: 20

  N: new_revision(ext => '.htm' revision => 5, places => 6, pre_revision => '')^
  A: [$uut->new_revision($file_spec,  revision => 1000, places => 3, )]^
  E: [undef, "Revision number 1000 overflowed limit of 1000.\n"]^
 ok: 20^

=head2 ok: 21

  N: new_revision(base => 'SoftwareDiamonds', ext => '.htm', places => 6, pre_revision => '')^

  A:
      [$uut->new_revision($file_spec,  base => 'SoftwareDiamonds', 
      ext => '.htm', revision => 5, places => 6, pre_revision => '')]
 ^
  E: [File::AnySpec->fspec2os('Unix','_Drawings_/SoftwareDiamonds000005.htm'), '6']^
 ok: 21^

=head2 ok: 22

  C: $file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/original.htm')^
  N: new_revision($file_spec, revision => 0,  pre_revision => '')^
  A: [$uut->new_revision($file_spec, revision => 0,  pre_revision => '')]^
  E: [File::AnySpec->fspec2os('Unix','_Drawings_/original.htm'), '1']^
 ok: 22^

=head2 ok: 23


  C:
      rmtree( '_Revision_');
      mkpath( '_Revision_');
      $from_file = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm');
      $to_file = File::AnySpec->fspec2os('Unix', '_Revision_/Erotica.pm');
 ^
  N: $uut->rotate($to_file, rotate => 2) 1st time^
  A: [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]^
  E: [File::AnySpec->fspec2os('Unix','_Revision_/Erotica0.pm'),0]^
 ok: 23^

=head2 ok: 24

  C: copy($from_file,$backup_file)^
  N: $uut->rotate($to_file, rotate => 2) 2nd time^
  A: [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]^
  E: [File::AnySpec->fspec2os('Unix','_Revision_/Erotica1.pm',1),1]^
 ok: 24^

=head2 ok: 25

  C: copy($from_file,$backup_file)^
  N: $uut->rotate($to_file, rotate => 2) 3rd time^
  A: [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]^
  E: [File::AnySpec->fspec2os('Unix','_Revision_/Erotica2.pm'),2]^
 ok: 25^

=head2 ok: 26

  C: copy($from_file,$backup_file)^
  N: $uut->rotate($to_file, rotate => 2) 4th time^
  A: [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]^
  E: [File::AnySpec->fspec2os('Unix','_Revision_/Erotica2.pm'),2]^
 ok: 26^



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

L<File::Revision>

=back

=for html


=cut

__DATA__

File_Spec: Unix^
UUT: File::Revision^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: Revision.d^
Verify: Revision.t^


 T: 26^


 C:
    use File::AnySpec;
    use File::Package;
    use File::Path;
    use File::Copy;
    my $fp = 'File::Package';
    my $uut = 'File::Revision';
    my ($file_spec, $from_file, $to_file);
    my ($backup_file, $rotate) = ('','');
    my $loaded = '';
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded($uut)^
 E:  ''^
ok: 1^

 N: Load UUT^
 S: $loaded^
 C: my $errors = $fp->load_package($uut)^
 A: $errors^
SE: ''^
ok: 2^


QC:
    my @revisions = (

    #  letter    number
    # -----------------
       ['-'   ,     0],
       ['Y'   ,    20],
       ['AA'  ,    21],
       ['WY'  ,   400],
       ['YY'  ,   420],
       ['AAA' ,   421],
    );

    my ($revision_letter, $revision_number);
    foreach (@revisions) {
       ($revision_letter, $revision_number) = @$_;
^

 N: revision2num(\'$revision_letter\')^
 A: $uut->revision2num($revision_letter)^
 E: $revision_number^
ok: 3,5,7,9,11,13^

 N: num2revision(\'$revision_number\')^
 A: $uut->num2revision($revision_number)^
 E: $revision_letter^
ok: 4,6,8,10,12,14^

QC: };^
VO: ^
 N: parse_options( 'myfile.myext', revision => 'AA', places => 3)^
 A: $uut->parse_options( 'myfile.myext', revision => 'AA', places => 3)^

 E:
bless( { 
   base => 'myfile',
   dir => '',
   ext => '.myext', 
   lead_places => '_',
   places => 3,
   pre_revision => '-',
   rev_letters => 1,
   revision => 'AA',
   revision_number => 21,
   top_revision_number => 8000,
   vol => '',
 }, 'Data::Startup')
^

ok: 15^

VO: ^
 N: parse_options( 'myfile.myext', revision => 'WW')^
 A: $uut->parse_options( 'myfile.myext', revision => 'WW')^

 E:
bless( { 
   base => 'myfile',
   dir => '',
   ext => '.myext', 
   lead_places => '',
   places => '',
   pre_revision => '-',
   rev_letters => 1,
   revision => 'WW',
   revision_number => 399,
   top_revision_number => '',
   vol => '',
 }, 'Data::Startup')
^

ok: 16^

VO: ^
 N: parse_options( 'myfile.myext', revision => 10, places => 3)^
 A: $uut->parse_options( 'myfile.myext', revision => 10, places => 3)^

 E:
bless( { 
   base => 'myfile',
   dir => '',
   ext => '.myext', 
   lead_places => '0',
   places => 3,
   pre_revision => '-',
   rev_letters => 0,
   revision => 10,
   revision_number => 10,
   top_revision_number => '1000',
   vol => '',
 }, 'Data::Startup')
^

ok: 17^

 N: revision_file( 7, parse_options( 'myfile.myext', pre_revision => '', revision => 'AA') )^

 A:
     $uut->revision_file( 7, $uut->parse_options( 'myfile.myext',
     pre_revision => '', revision => 'AA'))
^

 E: 'myfileG.myext'^
ok: 18^

 N: new_revision(ext => '.bak', revision => 1, places => 6, pre_revision => '')^
 C: $file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm')^

 A:
    [$uut->new_revision($file_spec, ext => '.bak', revision => 1,
    places => 6, pre_revision => '')]
^

 E: [File::AnySpec->fspec2os('Unix','_Drawings_/Erotica000001.bak'), '2']^
ok: 19^

 N: new_revision(ext => '.htm' revision => 5, places => 6, pre_revision => '')^
 A: [$uut->new_revision($file_spec,  revision => 1000, places => 3, )]^
 E: [undef, "Revision number 1000 overflowed limit of 1000.\n"]^
ok: 20^

 N: new_revision(base => 'SoftwareDiamonds', ext => '.htm', places => 6, pre_revision => '')^

 A:
     [$uut->new_revision($file_spec,  base => 'SoftwareDiamonds', 
     ext => '.htm', revision => 5, places => 6, pre_revision => '')]
^

 E: [File::AnySpec->fspec2os('Unix','_Drawings_/SoftwareDiamonds000005.htm'), '6']^
ok: 21^

 C: $file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/original.htm')^
 N: new_revision($file_spec, revision => 0,  pre_revision => '')^
 A: [$uut->new_revision($file_spec, revision => 0,  pre_revision => '')]^
 E: [File::AnySpec->fspec2os('Unix','_Drawings_/original.htm'), '1']^
ok: 22^


 C:
     rmtree( '_Revision_');
     mkpath( '_Revision_');
     $from_file = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm');
     $to_file = File::AnySpec->fspec2os('Unix', '_Revision_/Erotica.pm');
^

 N: $uut->rotate($to_file, rotate => 2) 1st time^
 A: [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]^
 E: [File::AnySpec->fspec2os('Unix','_Revision_/Erotica0.pm'),0]^
ok: 23^

 C: copy($from_file,$backup_file)^
 N: $uut->rotate($to_file, rotate => 2) 2nd time^
 A: [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]^
 E: [File::AnySpec->fspec2os('Unix','_Revision_/Erotica1.pm',1),1]^
ok: 24^

 C: copy($from_file,$backup_file)^
 N: $uut->rotate($to_file, rotate => 2) 3rd time^
 A: [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]^
 E: [File::AnySpec->fspec2os('Unix','_Revision_/Erotica2.pm'),2]^
ok: 25^

 C: copy($from_file,$backup_file)^
 N: $uut->rotate($to_file, rotate => 2) 4th time^
 A: [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]^
 E: [File::AnySpec->fspec2os('Unix','_Revision_/Erotica2.pm'),2]^
ok: 26^

 C: rmtree( '_Revision_');^

See_Also: L<File::Revision>^

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

HTML: ^


~-~
