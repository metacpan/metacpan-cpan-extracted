#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2004/05/04';


##### Demonstration Script ####
#
# Name: Drawing.d
#
# UUT: File::Drawing
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::File::Drawing 
#
# Don't edit this test script file, edit instead
#
# t::File::Drawing
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# The working directory is the directory of the generated file
#
use vars qw($__restore_dir__ @__restore_inc__ );

BEGIN {
    use Cwd;
    use File::Spec;
    use FindBin;
    use Test::Tech qw(demo is_skip plan skip_tests tech_config );

    ########
    # The working directory for this script file is the directory where
    # the test script resides. Thus, any relative files written or read
    # by this test script are located relative to this test script.
    #
    use vars qw( $__restore_dir__ );
    $__restore_dir__ = cwd();
    my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
    chdir $vol if $vol;
    chdir $dirs if $dirs;

    #######
    # Pick up any testing program modules off this test script.
    #
    # When testing on a target site before installation, place any test
    # program modules that should not be installed in the same directory
    # as this test script. Likewise, when testing on a host with a @INC
    # restricted to just raw Perl distribution, place any test program
    # modules in the same directory as this test script.
    #
    use lib $FindBin::Bin;

    unshift @INC, File::Spec->catdir( cwd(), 'lib' ); 

}

END {

    #########
    # Restore working directory and @INC back to when enter script
    #
    @INC = @lib::ORIG_INC;
    chdir $__restore_dir__;

}

print << 'MSG';

~~~~~~ Demonstration overview ~~~~~
 
The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

MSG

demo( "\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ use\ File\:\:SmartNL\;\
\ \ \ \ use\ File\:\:Path\;\
\ \ \ \ use\ File\:\:Copy\;\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\ \ \ \ my\ \$uut\ \=\ \'File\:\:Drawing\'\;\
\ \ \ \ my\ \$loaded\;\
\ \ \ \ my\ \$artists1\;"); # typed in command           
          use File::Package;
    use File::SmartNL;
    use File::Path;
    use File::Copy;
    my $fp = 'File::Package';
    my $uut = 'File::Drawing';
    my $loaded;
    my $artists1;; # execution

print << "EOF";

 ##################
 # Load UUT
 # 
 
EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\$uut\)"); # typed in command           
      my $errors = $fp->load_package($uut); # execution

demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

print << "EOF";

 ##################
 # pm2number
 # 
 
EOF

demo( "\$uut\-\>pm2number\(\'_Drawings_\:\:Repository0\:\:Artists_M\:\:Madonna\:\:Erotica\'\,\'_Drawings_\:\:Repository0\'\)", # typed in command           
      $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','_Drawings_::Repository0')); # execution


print << "EOF";

 ##################
 # pm2number, empty repository
 # 
 
EOF

demo( "\$uut\-\>pm2number\(\'_Drawings_\:\:Repository0\:\:Artists_M\:\:Madonna\:\:Erotica\'\,\'\'\)", # typed in command           
      $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','')); # execution


print << "EOF";

 ##################
 # pm2number, no repository
 # 
 
EOF

demo( "\$uut\-\>pm2number\(\'Etc\:\:Artists_M\:\:Madonna\:\:Erotica\'\)", # typed in command           
      $uut->pm2number('Etc::Artists_M::Madonna::Erotica')); # execution


print << "EOF";

 ##################
 # number2pm
 # 
 
EOF

demo( "\$uut\-\>number2pm\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\'_Drawings_\:\:Repository0\'\)", # typed in command           
      $uut->number2pm('Artists_M::Madonna::Erotica','_Drawings_::Repository0')); # execution


print << "EOF";

 ##################
 # number2pm, empty repository
 # 
 
EOF

demo( "\$uut\-\>number2pm\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\'\'\)", # typed in command           
      $uut->number2pm('Artists_M::Madonna::Erotica','')); # execution


print << "EOF";

 ##################
 # number2pm, no repository
 # 
 
EOF

demo( "\$uut\-\>number2pm\(\'Artists_M\:\:Madonna\:\:Erotica\'\)", # typed in command           
      $uut->number2pm('Artists_M::Madonna::Erotica')); # execution


print << "EOF";

 ##################
 # dod_date
 # 
 
EOF

demo( "\$uut\-\>dod_date\(25\,\ 34\,\ 36\,\ 5\,\ 1\,\ 104\)", # typed in command           
      $uut->dod_date(25, 34, 36, 5, 1, 104)); # execution


print << "EOF";

 ##################
 # dod_drawing_number
 # 
 
EOF

demo( "length\(\$uut\-\>dod_drawing_number\(\)\)", # typed in command           
      length($uut->dod_drawing_number())); # execution


print << "EOF";

 ##################
 # Repository0 exists
 # 
 
EOF

demo( "\ \ \ \#\#\#\#\
\ \ \ \#\ Drawing\ must\ find\ the\ below\ directory\ in\ the\ \@INC\ paths\
\ \ \ \#\ in\ order\ to\ perform\ this\ test\.\
\ \ \ \#"); # typed in command           
         ####
   # Drawing must find the below directory in the @INC paths
   # in order to perform this test.
   #; # execution

demo( "\-d\ \(File\:\:Spec\-\>catfile\(\ qw\(_Drawings_\ Repository0\)\)\)", # typed in command           
      -d (File::Spec->catfile( qw(_Drawings_ Repository0)))); # execution


print << "EOF";

 ##################
 # Created Repository1
 # 
 
EOF

demo( "\ \ \ \#\#\#\#\
\ \ \ \#\ Drawing\ must\ find\ the\ below\ directory\ in\ the\ \@INC\ paths\
\ \ \ \#\ in\ order\ to\ perform\ this\ test\.\
\ \ \ \#\ \ \ \ \ \
\ \ \ rmtree\ \(File\:\:Spec\-\>catdir\(\ qw\(_Drawings_\ Repository1\)\ \)\)\;\
\ \ \ mkpath\ \(File\:\:Spec\-\>catdir\(\ qw\(_Drawings_\ Repository1\)\ \)\)\;"); # typed in command           
         ####
   # Drawing must find the below directory in the @INC paths
   # in order to perform this test.
   #     
   rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));
   mkpath (File::Spec->catdir( qw(_Drawings_ Repository1) ));; # execution

demo( "\-d\ \(File\:\:Spec\-\>catfile\(\ qw\(_Drawings_\ Repository1\)\)\)", # typed in command           
      -d (File::Spec->catfile( qw(_Drawings_ Repository1)))); # execution


print << "EOF";

 ##################
 # Retrieve erotica source control drawing
 # 
 
EOF

demo( "my\ \$erotica2\ \=\ \$uut\-\>retrieve\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\ repository\ \=\>\ \'_Drawings_\:\:Repository0\'\)"); # typed in command           
      my $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository0'); # execution

demo( "ref\(\$erotica2\)", # typed in command           
      ref($erotica2)); # execution


print << "EOF";

 ##################
 # Release erotica to different repository
 # 
 
EOF

demo( "\ my\ \$error\=\ \$erotica2\-\>release\(revise_repository\ \=\>\ \'_Drawings_\:\:Repository1\:\:\'\ \)"); # typed in command           
       my $error= $erotica2->release(revise_repository => '_Drawings_::Repository1::' ); # execution

demo( "\$error", # typed in command           
      $error); # execution


print << "EOF";

 ##################
 # Retrieve erotica
 # 
 
EOF

demo( "my\ \$erotica1\ \=\ \$uut\-\>retrieve\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\ repository\ \=\>\ \'_Drawings_\:\:Repository1\'\)\;"); # typed in command           
      my $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');; # execution

demo( "ref\(\$erotica1\)", # typed in command           
      ref($erotica1)); # execution


print << "EOF";

 ##################
 # Erotica contents unchanged
 # 
 
EOF

demo( "\ \$erotica1\-\>\[0\]", # typed in command           
       $erotica1->[0]); # execution


demo( "\ \$erotica1\-\>\[1\]", # typed in command           
       $erotica1->[1]); # execution


print << "EOF";

 ##################
 # Revise erotica contents
 # 
 
EOF

demo( "\ \ \ \ \$erotica2\-\>\[0\]\-\>\{in_house\}\-\>\{num_media\}\ \=\ \ 1\;\
\ \ \ \ \$error\ \=\ \$erotica2\-\>revise\(\)\;"); # typed in command           
          $erotica2->[0]->{in_house}->{num_media} =  1;
    $error = $erotica2->revise();; # execution

demo( "\$error", # typed in command           
      $error); # execution


demo( "\-e\ File\:\:Spec\-\>catfile\(qw\(_Drawings_\ Repository1\ Obsolete\ Artists_M\ Madonna\ Erotica\.pm\)\)", # typed in command           
      -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica.pm))); # execution


print << "EOF";

 ##################
 # Retrieve erotica, revision 1
 # 
 
EOF

demo( "\$erotica1\ \=\ \$uut\-\>retrieve\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\ repository\ \=\>\ \'_Drawings_\:\:Repository1\'\)\;"); # typed in command           
      $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');; # execution

demo( "ref\(\$erotica1\)", # typed in command           
      ref($erotica1)); # execution


print << "EOF";

 ##################
 # Erotica Revision 1 contents revised
 # 
 
EOF

demo( "\$erotica1\-\>\[0\]", # typed in command           
      $erotica1->[0]); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{version\}", # typed in command           
      $erotica1->[1]->{version}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{revision\}", # typed in command           
      $erotica1->[1]->{revision}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{date_gm\}", # typed in command           
      $erotica1->[1]->{date_gm}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{date_loc\}", # typed in command           
      $erotica1->[1]->{date_loc}); # execution


demo( "\ \ \ \ \$erotica2\-\>\[1\]\-\>\{classification\}\ \=\ \'Top\ Secret\'\;\
\ \ \ \ \$error\ \=\ \$erotica2\-\>revise\(\)\;"); # typed in command           
          $erotica2->[1]->{classification} = 'Top Secret';
    $error = $erotica2->revise();; # execution

demo( "\$error", # typed in command           
      $error); # execution


demo( "\-e\ File\:\:Spec\-\>catfile\(qw\(_Drawings_\ Repository1\ Obsolete\ Artists_M\ Madonna\ Erotica\-01\.pm\)\)", # typed in command           
      -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-01.pm))); # execution


print << "EOF";

 ##################
 # Retrieve erotica revision 2
 # 
 
EOF

demo( "\$erotica1\ \=\ \$uut\-\>retrieve\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\ repository\ \=\>\ \'_Drawings_\:\:Repository1\'\)\;"); # typed in command           
      $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');; # execution

demo( "ref\(\$erotica1\)", # typed in command           
      ref($erotica1)); # execution


demo( "\ \$erotica1\-\>\[1\]", # typed in command           
       $erotica1->[1]); # execution


print << "EOF";

 ##################
 # Retrieve _Drawings_::Erotica
 # 
 
EOF

demo( "\$erotica2\ \=\ \$uut\-\>retrieve\(\'_Drawings_\:\:Erotica\'\,\ repository\ \=\>\ \'\'\)\;"); # typed in command           
      $erotica2 = $uut->retrieve('_Drawings_::Erotica', repository => '');; # execution

demo( "ref\(\$erotica2\)", # typed in command           
      ref($erotica2)); # execution


print << "EOF";

 ##################
 # Revise erotica revision 2
 # 
 
EOF

demo( "\$error\ \=\ \$erotica2\-\>revise\(revise_drawing_number\=\>\'Artists_M\:\:Madonna\:\:Erotica\'\,\ revise_repository\=\>\'_Drawings_\:\:Repository1\'\)\;"); # typed in command           
      $error = $erotica2->revise(revise_drawing_number=>'Artists_M::Madonna::Erotica', revise_repository=>'_Drawings_::Repository1');; # execution

demo( "\$error", # typed in command           
      $error); # execution


demo( "\-e\ File\:\:Spec\-\>catfile\(qw\(_Drawings_\ Repository1\ Obsolete\ Artists_M\ Madonna\ Erotica\-2\.pm\)\)", # typed in command           
      -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-2.pm))); # execution


print << "EOF";

 ##################
 # Retrieve erotica revision 3
 # 
 
EOF

demo( "\$erotica1\ \=\ \$uut\-\>retrieve\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\ repository\ \=\>\ \'_Drawings_\:\:Repository1\'\)\;"); # typed in command           
      $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');; # execution

demo( "ref\(\$erotica1\)", # typed in command           
      ref($erotica1)); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{version\}", # typed in command           
      $erotica1->[1]->{version}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{revision\}", # typed in command           
      $erotica1->[1]->{revision}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{date_gm\}", # typed in command           
      $erotica1->[1]->{date_gm}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{date_loc\}", # typed in command           
      $erotica1->[1]->{date_loc}); # execution


print << "EOF";

 ##################
 # Erotica revision 3 file contents revised
 # 
 
EOF

demo( "\ \$erotica1\-\>\[3\]", # typed in command           
       $erotica1->[3]); # execution


print << "EOF";

 ##################
 # Retrieve Sandbox erotica
 # 
 
EOF

demo( "\ \ \ unshift\ \@INC\,\'_Sandbox_\'\;\
\ \ \ \$erotica2\ \=\ \$uut\-\>retrieve\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\ repository\ \=\>\ \'_Drawings_\:\:Repository1\'\)\;"); # typed in command           
         unshift @INC,'_Sandbox_';
   $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');; # execution

demo( "ref\(\$erotica2\)", # typed in command           
      ref($erotica2)); # execution


print << "EOF";

 ##################
 # Revise erotica revision 3
 # 
 
EOF

demo( "\ \ \ \ shift\ \@INC\;\
\ \ \ \ \$error\ \=\ \$erotica2\-\>revise\(\ \)\;"); # typed in command           
          shift @INC;
    $error = $erotica2->revise( );; # execution

demo( "\$error", # typed in command           
      $error); # execution


demo( "\-e\ File\:\:Spec\-\>catfile\(qw\(_Drawings_\ Repository1\ Obsolete\ Artists_M\ Madonna\ Erotica\-3\.pm\)\)", # typed in command           
      -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-3.pm))); # execution


print << "EOF";

 ##################
 # Retrieve erotica revision 4
 # 
 
EOF

demo( "\$erotica1\ \=\ \$uut\-\>retrieve\(\'Artists_M\:\:Madonna\:\:Erotica\'\,\ repository\ \=\>\ \'_Drawings_\:\:Repository1\'\)"); # typed in command           
      $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1'); # execution

demo( "ref\(\$erotica1\)", # typed in command           
      ref($erotica1)); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{version\}", # typed in command           
      $erotica1->[1]->{version}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{revision\}", # typed in command           
      $erotica1->[1]->{revision}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{date_gm\}", # typed in command           
      $erotica1->[1]->{date_gm}); # execution


demo( "\$erotica1\-\>\[1\]\-\>\{date_loc\}", # typed in command           
      $erotica1->[1]->{date_loc}); # execution


print << "EOF";

 ##################
 # Erotica Revision 4 file contents revised
 # 
 
EOF

demo( "\ \$erotica1\-\>\[3\]", # typed in command           
       $erotica1->[3]); # execution


demo( "rmtree\ \(File\:\:Spec\-\>catdir\(\ qw\(_Drawings_\ Repository1\)\ \)\)\;"); # typed in command           
      rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));; # execution


=head1 NAME

Drawing.d - demostration script for File::Drawing

=head1 SYNOPSIS

 Drawing.d

=head1 OPTIONS

None.

=head1 COPYRIGHT

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

## end of test script file ##

=cut

