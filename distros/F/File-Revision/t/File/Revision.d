#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.03';   # automatically generated file
$DATE = '2004/05/03';


##### Demonstration Script ####
#
# Name: Revision.d
#
# UUT: File::Revision
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::File::Revision 
#
# Don't edit this test script file, edit instead
#
# t::File::Revision
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

demo( "\ \ \ \ use\ File\:\:AnySpec\;\
\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ use\ File\:\:Path\;\
\ \ \ \ use\ File\:\:Copy\;\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\ \ \ \ my\ \$uut\ \=\ \'File\:\:Revision\'\;\
\ \ \ \ my\ \(\$file_spec\,\ \$from_file\,\ \$to_file\)\;\
\ \ \ \ my\ \(\$backup_file\,\ \$rotate\)\ \=\ \(\'\'\,\'\'\)\;\
\ \ \ \ my\ \$loaded\ \=\ \'\'\;"); # typed in command           
          use File::AnySpec;
    use File::Package;
    use File::Path;
    use File::Copy;
    my $fp = 'File::Package';
    my $uut = 'File::Revision';
    my ($file_spec, $from_file, $to_file);
    my ($backup_file, $rotate) = ('','');
    my $loaded = '';; # execution

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
       ($revision_letter, $revision_number) = @$_;; # execution

print << "EOF";

 ##################
 # revision2num(\'$revision_letter\')
 # 
 
EOF

demo( "\$uut\-\>revision2num\(\$revision_letter\)", # typed in command           
      $uut->revision2num($revision_letter)); # execution


print << "EOF";

 ##################
 # num2revision(\'$revision_number\')
 # 
 
EOF

demo( "\$uut\-\>num2revision\(\$revision_number\)", # typed in command           
      $uut->num2revision($revision_number)); # execution


      };; # execution

print << "EOF";

 ##################
 # revision_file( 7, parse_options( 'myfile.myext', pre_revision => '', revision => 'AA') )
 # 
 
EOF

demo( "\ \ \ \ \ \$uut\-\>revision_file\(\ 7\,\ \$uut\-\>parse_options\(\ \'myfile\.myext\'\,\
\ \ \ \ \ pre_revision\ \=\>\ \'\'\,\ revision\ \=\>\ \'AA\'\)\)", # typed in command           
           $uut->revision_file( 7, $uut->parse_options( 'myfile.myext',
     pre_revision => '', revision => 'AA'))); # execution


print << "EOF";

 ##################
 # new_revision(ext => '.bak', revision => 1, places => 6, pre_revision => '')
 # 
 
EOF

demo( "\$file_spec\ \=\ File\:\:AnySpec\-\>fspec2os\(\'Unix\'\,\ \'_Drawings_\/Erotica\.pm\'\)"); # typed in command           
      $file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm'); # execution

demo( "\ \ \ \ \[\$uut\-\>new_revision\(\$file_spec\,\ ext\ \=\>\ \'\.bak\'\,\ revision\ \=\>\ 1\,\
\ \ \ \ places\ \=\>\ 6\,\ pre_revision\ \=\>\ \'\'\)\]", # typed in command           
          [$uut->new_revision($file_spec, ext => '.bak', revision => 1,
    places => 6, pre_revision => '')]); # execution


print << "EOF";

 ##################
 # new_revision(ext => '.htm' revision => 5, places => 6, pre_revision => '')
 # 
 
EOF

demo( "\[\$uut\-\>new_revision\(\$file_spec\,\ \ revision\ \=\>\ 1000\,\ places\ \=\>\ 3\,\ \)\]", # typed in command           
      [$uut->new_revision($file_spec,  revision => 1000, places => 3, )]); # execution


print << "EOF";

 ##################
 # new_revision(base => 'SoftwareDiamonds', ext => '.htm', places => 6, pre_revision => '')
 # 
 
EOF

demo( "\ \ \ \ \ \[\$uut\-\>new_revision\(\$file_spec\,\ \ base\ \=\>\ \'SoftwareDiamonds\'\,\ \
\ \ \ \ \ ext\ \=\>\ \'\.htm\'\,\ revision\ \=\>\ 5\,\ places\ \=\>\ 6\,\ pre_revision\ \=\>\ \'\'\)\]", # typed in command           
           [$uut->new_revision($file_spec,  base => 'SoftwareDiamonds', 
     ext => '.htm', revision => 5, places => 6, pre_revision => '')]); # execution


demo( "\$file_spec\ \=\ File\:\:AnySpec\-\>fspec2os\(\'Unix\'\,\ \'_Drawings_\/original\.htm\'\)"); # typed in command           
      $file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/original.htm'); # execution

print << "EOF";

 ##################
 # new_revision($file_spec, revision => 0,  pre_revision => '')
 # 
 
EOF

demo( "\[\$uut\-\>new_revision\(\$file_spec\,\ revision\ \=\>\ 0\,\ \ pre_revision\ \=\>\ \'\'\)\]", # typed in command           
      [$uut->new_revision($file_spec, revision => 0,  pre_revision => '')]); # execution


demo( "\ \ \ \ \ rmtree\(\ \'_Revision_\'\)\;\
\ \ \ \ \ mkpath\(\ \'_Revision_\'\)\;\
\ \ \ \ \ \$from_file\ \=\ File\:\:AnySpec\-\>fspec2os\(\'Unix\'\,\ \'_Drawings_\/Erotica\.pm\'\)\;\
\ \ \ \ \ \$to_file\ \=\ File\:\:AnySpec\-\>fspec2os\(\'Unix\'\,\ \'_Revision_\/Erotica\.pm\'\)\;"); # typed in command           
           rmtree( '_Revision_');
     mkpath( '_Revision_');
     $from_file = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm');
     $to_file = File::AnySpec->fspec2os('Unix', '_Revision_/Erotica.pm');; # execution

print << "EOF";

 ##################
 # $uut->rotate($to_file, rotate => 2) 1st time
 # 
 
EOF

demo( "\[\(\$backup_file\,\$rotate\)\ \=\ \$uut\-\>rotate\(\$to_file\,\ rotate\ \=\>\ 2\,\ pre_revision\ \=\>\ \'\'\)\]", # typed in command           
      [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]); # execution


demo( "copy\(\$from_file\,\$backup_file\)"); # typed in command           
      copy($from_file,$backup_file); # execution

print << "EOF";

 ##################
 # $uut->rotate($to_file, rotate => 2) 2nd time
 # 
 
EOF

demo( "\[\(\$backup_file\,\$rotate\)\ \=\ \$uut\-\>rotate\(\$to_file\,\ rotate\ \=\>\ 2\,\ pre_revision\ \=\>\ \'\'\)\]", # typed in command           
      [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]); # execution


demo( "copy\(\$from_file\,\$backup_file\)"); # typed in command           
      copy($from_file,$backup_file); # execution

print << "EOF";

 ##################
 # $uut->rotate($to_file, rotate => 2) 3rd time
 # 
 
EOF

demo( "\[\(\$backup_file\,\$rotate\)\ \=\ \$uut\-\>rotate\(\$to_file\,\ rotate\ \=\>\ 2\,\ pre_revision\ \=\>\ \'\'\)\]", # typed in command           
      [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]); # execution


demo( "copy\(\$from_file\,\$backup_file\)"); # typed in command           
      copy($from_file,$backup_file); # execution

print << "EOF";

 ##################
 # $uut->rotate($to_file, rotate => 2) 4th time
 # 
 
EOF

demo( "\[\(\$backup_file\,\$rotate\)\ \=\ \$uut\-\>rotate\(\$to_file\,\ rotate\ \=\>\ 2\,\ pre_revision\ \=\>\ \'\'\)\]", # typed in command           
      [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')]); # execution


demo( "rmtree\(\ \'_Revision_\'\)\;"); # typed in command           
      rmtree( '_Revision_');; # execution


=head1 NAME

Revision.d - demostration script for File::Revision

=head1 SYNOPSIS

 Revision.d

=head1 OPTIONS

None.

=head1 COPYRIGHT

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

## end of test script file ##

=cut

