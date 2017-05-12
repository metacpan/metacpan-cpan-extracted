#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.02';   # automatically generated file
$DATE = '2004/05/10';


##### Demonstration Script ####
#
# Name: Maker.d
#
# UUT: File::Maker
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::File::Maker 
#
# Don't edit this test script file, edit instead
#
# t::File::Maker
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
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\ \ \ \ my\ \$loaded\ \=\ \'\'\;\
\
\ \ \ \ use\ File\:\:SmartNL\;\
\ \ \ \ my\ \$snl\ \=\ \'File\:\:SmartNL\'\;\
\
\ \ \ \ use\ File\:\:Spec\;\
\
\ \ \ \ my\ \@inc\ \=\ \@INC\;"); # typed in command           
          use File::Package;
    my $fp = 'File::Package';
    my $loaded = '';

    use File::SmartNL;
    my $snl = 'File::SmartNL';

    use File::Spec;

    my @inc = @INC;; # execution

print << "EOF";

 ##################
 # Load UUT
 # 
 
EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\ \'_Maker_\:\:MakerDB\'\ \)"); # typed in command           
      my $errors = $fp->load_package( '_Maker_::MakerDB' ); # execution

demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

demo( "\$snl\-\>fin\(File\:\:Spec\-\>catfile\(\'_Maker_\'\,\'MakerDB\.pm\'\)\)", # typed in command           
      $snl->fin(File::Spec->catfile('_Maker_','MakerDB.pm'))); # execution


print << "EOF";

 ##################
 # No target
 # 
 
EOF

demo( "my\ \$maker\ \=\ new\ _Maker_\:\:MakerDB\(\ pm\ \=\>\ \'_Maker_\:\:MakerDB\'\ \)"); # typed in command           
      my $maker = new _Maker_::MakerDB( pm => '_Maker_::MakerDB' ); # execution

demo( "\$maker\-\>make\(\ \)", # typed in command           
      $maker->make( )); # execution


print << "EOF";

 ##################
 # FormDB_File
 # 
 
EOF

demo( "\$maker\-\>\{FormDB_File\}", # typed in command           
      $maker->{FormDB_File}); # execution


print << "EOF";

 ##################
 # FormDB_PM
 # 
 
EOF

demo( "\$maker\-\>\{FormDB_PM\}", # typed in command           
      $maker->{FormDB_PM}); # execution


print << "EOF";

 ##################
 # FormDB_Record
 # 
 
EOF

demo( "\$maker\-\>\{FormDB_Record\}", # typed in command           
      $maker->{FormDB_Record}); # execution


print << "EOF";

 ##################
 # FormDB
 # 
 
EOF

demo( "\$maker\-\>\{FormDB\}", # typed in command           
      $maker->{FormDB}); # execution


print << "EOF";

 ##################
 # Target all
 # 
 
EOF

demo( "\$maker\-\>make\(\ \'all\'\ \)", # typed in command           
      $maker->make( 'all' )); # execution


print << "EOF";

 ##################
 # Unsupport target
 # 
 
EOF

demo( "\$maker\-\>make\(\ \'xyz\'\ \)", # typed in command           
      $maker->make( 'xyz' )); # execution


print << "EOF";

 ##################
 # target3
 # 
 
EOF

demo( "\$maker\-\>make\(\ \'target3\'\ \)", # typed in command           
      $maker->make( 'target3' )); # execution


print << "EOF";

 ##################
 # target3 target4
 # 
 
EOF

demo( "\$maker\-\>make\(\ qw\(target3\ target4\)\ \)", # typed in command           
      $maker->make( qw(target3 target4) )); # execution


print << "EOF";

 ##################
 # Include stayed same
 # 
 
EOF

demo( "\[\@INC\]", # typed in command           
      [@INC]); # execution



=head1 NAME

Maker.d - demostration script for File::Maker

=head1 SYNOPSIS

 Maker.d

=head1 OPTIONS

None.

=head1 COPYRIGHT

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

## end of test script file ##

=cut

