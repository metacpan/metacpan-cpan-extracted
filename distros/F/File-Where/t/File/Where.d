#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.04';   # automatically generated file
$DATE = '2004/05/04';


##### Demonstration Script ####
#
# Name: Where.d
#
# UUT: File::Where
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::File::Where 
#
# Don't edit this test script file, edit instead
#
# t::File::Where
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

demo( "\ \ \ \ use\ File\:\:Spec\;\
\ \ \ \ use\ File\:\:Copy\;\
\ \ \ \ use\ File\:\:Path\;\
\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\
\ \ \ \ my\ \$uut\ \=\ \'File\:\:Where\'\;\
\ \ \ \ my\ \$loaded\ \=\ \'\'\;\
\ \ \ \ \#\ Use\ the\ test\ file\ as\ an\ example\ since\ know\ its\ absolute\ path\
\ \ \ \ \#\
\ \ \ \ my\ \$test_script_dir\ \=\ cwd\(\)\;\
\ \ \ \ chdir\ File\:\:Spec\-\>updir\(\)\;\
\ \ \ \ chdir\ File\:\:Spec\-\>updir\(\)\;\
\ \ \ \ my\ \$include_dir\ \=\ cwd\(\)\;\
\ \ \ \ chdir\ \$test_script_dir\;\
\ \ \ \ my\ \$OS\ \=\ \$\^O\;\ \ \#\ need\ to\ escape\ \^\
\ \ \ \ unless\ \(\$OS\)\ \{\ \ \ \#\ on\ some\ perls\ \$\^O\ is\ not\ defined\
\ \ \ \ \ \ \ \ require\ Config\;\
\	\$OS\ \=\ \$Config\:\:Config\{\'osname\'\}\;\
\ \ \ \ \}\ \
\ \ \ \ \$include_dir\ \=\~\ s\=\/\=\\\\\=g\ if\(\ \$OS\ eq\ \'MSWin32\'\)\;\
\ \ \ \ \$test_script_dir\ \=\~\ s\=\/\=\\\\\=g\ if\(\ \$OS\ eq\ \'MSWin32\'\)\;\
\
\ \ \ \ \#\ Put\ base\ directory\ as\ the\ first\ in\ the\ \@INC\ path\
\ \ \ \ \#\
\ \ \ \ my\ \@restore_inc\ \=\ \@INC\;\
\
\ \ \ \ my\ \$relative_file\ \=\ File\:\:Spec\-\>catfile\(\'t\'\,\ \'File\'\,\ \'Where\.pm\'\)\;\ \
\ \ \ \ my\ \$relative_dir1\ \=\ File\:\:Spec\-\>catdir\(\'t\'\,\ \'File\'\)\;\
\ \ \ \ my\ \$relative_dir2\ \=\ File\:\:Spec\-\>catdir\(\'t\'\,\ \'Jolly_Green_Giant\'\)\;\
\
\ \ \ \ my\ \$absolute_file1\ \=\ File\:\:Spec\-\>catfile\(\$include_dir\,\ \'t\'\,\ \'File\'\,\ \'Where\.pm\'\)\;\
\ \ \ \ my\ \$absolute_dir1A\ \=\ File\:\:Spec\-\>catdir\(\$include_dir\,\ \'t\'\,\ \'File\'\)\;\
\ \ \ \ my\ \$absolute_dir1B\ \=\ File\:\:Spec\-\>catdir\(\$include_dir\,\ \'t\'\)\;\
\
\ \ \ \ mkpath\ \(File\:\:Spec\-\>catdir\(\$test_script_dir\,\ \'t\'\,\'File\'\)\)\;\
\ \ \ \ my\ \$absolute_file2\ \=\ File\:\:Spec\-\>catfile\(\$test_script_dir\,\ \'t\'\,\ \'File\'\,\ \'Where\.pm\'\)\;\
\ \ \ \ my\ \$absolute_dir2A\ \=\ File\:\:Spec\-\>catdir\(\$include_dir\,\ \'t\'\,\ \'File\'\,\ \'t\'\,\ \'File\'\)\;\
\ \ \ \ my\ \$absolute_dir2B\ \=\ File\:\:Spec\-\>catdir\(\$include_dir\,\ \'t\'\,\ \'File\'\,\ \'t\'\)\;\
\
\ \ \ \ \#\#\#\#\#\
\ \ \ \ \#\ If\ doing\ a\ target\ site\ install\,\ blib\ going\ to\ be\ up\ front\ in\ \@INC\
\ \ \ \ \#\ Locate\ the\ include\ directory\ with\ high\ probability\ of\ having\ the\
\ \ \ \ \#\ first\ File\:\:Where\ in\ the\ include\ path\.\
\ \ \ \ \#\
\ \ \ \ \#\ Really\ not\ important\ that\ that\ cheapen\ test\ somewhat\ by\ doing\ a\ quasi\
\ \ \ \ \#\ where\ search\ in\ that\ using\ this\ to\ test\ for\ a\ boundary\ condition\ where\
\ \ \ \ \#\ the\ class\,\ \'File\:\:Where\'\,\ is\ the\ same\ as\ the\ program\ module\ \'File\:\:Where\
\ \ \ \ \#\ that\ the\ \'where\'\ subroutine\/method\ is\ locating\.\
\ \ \ \ \#\
\ \ \ \ my\ \$absolute_dir_where\ \=\ File\:\:Spec\-\>catdir\(\$include_dir\,\ \'lib\'\)\;\
\ \ \ \ foreach\ \(\@INC\)\ \{\
\ \ \ \ \ \ \ \ if\ \(\$_\ \=\~\ \/blib\/\)\ \{\
\ \ \ \ \ \ \ \ \ \ \ \ \$absolute_dir_where\ \=\ \$_\ \;\
\ \ \ \ \ \ \ \ \ \ \ \ last\;\
\ \ \ \ \ \ \ \ \}\
\ \ \ \ \ \ \ \ elsif\ \(\$_\ \=\~\ \/lib\/\)\ \{\
\ \ \ \ \ \ \ \ \ \ \ \ \$absolute_dir_where\ \=\ \$_\ \;\
\ \ \ \ \ \ \ \ \ \ \ \ last\;\
\ \ \ \ \ \ \ \ \}\
\ \ \ \ \}\
\ \ \ \ my\ \$absolute_file_where\ \=\ File\:\:Spec\-\>catfile\(\$absolute_dir_where\,\ \'File\'\,\ \'Where\.pm\'\)\;\
\
\ \ \ \ my\ \@inc2\ \=\ \(\$test_script_dir\,\ \@INC\)\;\ \ \#\ another\ way\ to\ do\ unshift\
\ \ \ \ \
\ \ \ \ copy\ \$absolute_file1\,\$absolute_file2\;\
\ \ \ \ unshift\ \@INC\,\ \$include_dir\;\ \ \ \ \
\
\ \ \ \ my\ \(\@actual\,\$actual\)\;\ \#\ use\ for\ array\ and\ scalar\ context"); # typed in command           
          use File::Spec;
    use File::Copy;
    use File::Path;
    use File::Package;
    my $fp = 'File::Package';

    my $uut = 'File::Where';
    my $loaded = '';
    # Use the test file as an example since know its absolute path
    #
    my $test_script_dir = cwd();
    chdir File::Spec->updir();
    chdir File::Spec->updir();
    my $include_dir = cwd();
    chdir $test_script_dir;
    my $OS = $^O;  # need to escape ^
    unless ($OS) {   # on some perls $^O is not defined
        require Config;
	$OS = $Config::Config{'osname'};
    } 
    $include_dir =~ s=/=\\=g if( $OS eq 'MSWin32');
    $test_script_dir =~ s=/=\\=g if( $OS eq 'MSWin32');

    # Put base directory as the first in the @INC path
    #
    my @restore_inc = @INC;

    my $relative_file = File::Spec->catfile('t', 'File', 'Where.pm'); 
    my $relative_dir1 = File::Spec->catdir('t', 'File');
    my $relative_dir2 = File::Spec->catdir('t', 'Jolly_Green_Giant');

    my $absolute_file1 = File::Spec->catfile($include_dir, 't', 'File', 'Where.pm');
    my $absolute_dir1A = File::Spec->catdir($include_dir, 't', 'File');
    my $absolute_dir1B = File::Spec->catdir($include_dir, 't');

    mkpath (File::Spec->catdir($test_script_dir, 't','File'));
    my $absolute_file2 = File::Spec->catfile($test_script_dir, 't', 'File', 'Where.pm');
    my $absolute_dir2A = File::Spec->catdir($include_dir, 't', 'File', 't', 'File');
    my $absolute_dir2B = File::Spec->catdir($include_dir, 't', 'File', 't');

    #####
    # If doing a target site install, blib going to be up front in @INC
    # Locate the include directory with high probability of having the
    # first File::Where in the include path.
    #
    # Really not important that that cheapen test somewhat by doing a quasi
    # where search in that using this to test for a boundary condition where
    # the class, 'File::Where', is the same as the program module 'File::Where
    # that the 'where' subroutine/method is locating.
    #
    my $absolute_dir_where = File::Spec->catdir($include_dir, 'lib');
    foreach (@INC) {
        if ($_ =~ /blib/) {
            $absolute_dir_where = $_ ;
            last;
        }
        elsif ($_ =~ /lib/) {
            $absolute_dir_where = $_ ;
            last;
        }
    }
    my $absolute_file_where = File::Spec->catfile($absolute_dir_where, 'File', 'Where.pm');

    my @inc2 = ($test_script_dir, @INC);  # another way to do unshift
    
    copy $absolute_file1,$absolute_file2;
    unshift @INC, $include_dir;    

    my (@actual,$actual); # use for array and scalar context; # execution

print << "EOF";

 ##################
 # Load UUT
 # 
 
EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\'File\:\:Where\'\,\ \'where_pm\'\)"); # typed in command           
      my $errors = $fp->load_package('File::Where', 'where_pm'); # execution

demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

print << "EOF";

 ##################
 # pm2require
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>pm2require\(\ \'File\:\:Where\'\)", # typed in command           
      $actual = $uut->pm2require( 'File::Where')); # execution


print << "EOF";

 ##################
 # program modules('_Drivers_')
 # 
 
EOF

demo( "\[my\ \@drivers\ \=\ sort\ \$uut\-\>program_modules\(\ \'_Drivers_\'\ \)\]", # typed in command           
      [my @drivers = sort $uut->program_modules( '_Drivers_' )]); # execution


print << "EOF";

 ##################
 # is_module('dri', @drivers)
 # 
 
EOF

demo( "\$uut\-\>is_module\(\'dri\'\,\ \@drivers\ \)", # typed in command           
      $uut->is_module('dri', @drivers )); # execution


print << "EOF";

 ##################
 # repository_pms('t::File::_Drivers_')
 # 
 
EOF

demo( "\[\@drivers\ \=\ sort\ \$uut\-\>repository_pms\(\ \'t\:\:File\:\:_Drivers_\'\ \)\]", # typed in command           
      [@drivers = sort $uut->repository_pms( 't::File::_Drivers_' )]); # execution


print << "EOF";

 ##################
 # dir_pms( '_Drivers_' )
 # 
 
EOF

demo( "\[\@drivers\ \=\ sort\ \$uut\-\>dir_pms\(\ \'_Drivers_\'\ \)\]", # typed in command           
      [@drivers = sort $uut->dir_pms( '_Drivers_' )]); # execution


print << "EOF";

 ##################
 # where finding a file, array context, path absent
 # 
 
EOF

demo( "\[\@actual\ \=\ \$uut\-\>where\(\$relative_file\)\]", # typed in command           
      [@actual = $uut->where($relative_file)]); # execution


print << "EOF";

 ##################
 # where finding a file, scalar context, path absent
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>where\(\$relative_file\)", # typed in command           
      $actual = $uut->where($relative_file)); # execution


print << "EOF";

 ##################
 # where finding a file, array context, array reference path
 # 
 
EOF

demo( "\[\@actual\ \=\ \$uut\-\>where\(\$relative_file\,\ \[\$test_script_dir\,\ \$include_dir\]\)\]", # typed in command           
      [@actual = $uut->where($relative_file, [$test_script_dir, $include_dir])]); # execution


print << "EOF";

 ##################
 # where finding a dir, array context, path absent
 # 
 
EOF

demo( "\[\@actual\ \=\ \$uut\-\>where\(\$relative_dir1\,\ \'\'\,\ \'nofile\'\)\]", # typed in command           
      [@actual = $uut->where($relative_dir1, '', 'nofile')]); # execution


print << "EOF";

 ##################
 # where finding a dir, scalar context, path absent
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>where\(\$relative_file\,\ \'\'\,\ \'nofile\'\)", # typed in command           
      $actual = $uut->where($relative_file, '', 'nofile')); # execution


print << "EOF";

 ##################
 # where finding a dir, array context, array reference path
 # 
 
EOF

demo( "\[\@actual\ \=\ \$uut\-\>where\(\$relative_dir2\,\ \\\@inc2\,\ \'nofile\'\)\]", # typed in command           
      [@actual = $uut->where($relative_dir2, \@inc2, 'nofile')]); # execution


print << "EOF";

 ##################
 # where finding a dir, scalar context, array reference path
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>where\(\'t\'\,\ \[\$test_script_dir\,\@INC\]\,\ \'nofile\'\)", # typed in command           
      $actual = $uut->where('t', [$test_script_dir,@INC], 'nofile')); # execution


print << "EOF";

 ##################
 # where_file, array context, path absent
 # 
 
EOF

demo( "\[\@actual\ \=\ \$uut\-\>where_file\(\$relative_file\)\]", # typed in command           
      [@actual = $uut->where_file($relative_file)]); # execution


print << "EOF";

 ##################
 # where_file, scalar context, array path
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>where_file\(\$relative_file\,\ \$test_script_dir\,\ \$include_dir\)", # typed in command           
      $actual = $uut->where_file($relative_file, $test_script_dir, $include_dir)); # execution


print << "EOF";

 ##################
 # where_dir, array context, array reference
 # 
 
EOF

demo( "\[\@actual\ \=\ \$uut\-\>where_dir\(\$relative_dir1\,\ \\\@inc2\)\]", # typed in command           
      [@actual = $uut->where_dir($relative_dir1, \@inc2)]); # execution


print << "EOF";

 ##################
 # where_dir, array context, array reference
 # 
 
EOF

demo( "\[\@actual\ \=\ \$uut\-\>where_dir\(\$relative_dir2\,\ \$test_script_dir\)\]", # typed in command           
      [@actual = $uut->where_dir($relative_dir2, $test_script_dir)]); # execution


print << "EOF";

 ##################
 # where_dir, scalar context, path absent
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>where_dir\(\$relative_file\)", # typed in command           
      $actual = $uut->where_dir($relative_file)); # execution


print << "EOF";

 ##################
 # where_pm, array context, path absent
 # 
 
EOF

demo( "\[\@actual\=\ \$uut\-\>where_pm\(\ \'t\:\:File\:\:Where\'\ \)\]", # typed in command           
      [@actual= $uut->where_pm( 't::File::Where' )]); # execution


print << "EOF";

 ##################
 # where_pm, scalar context, array path
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>where_pm\(\ \'t\:\:File\:\:Where\'\,\ \@inc2\)", # typed in command           
      $actual = $uut->where_pm( 't::File::Where', @inc2)); # execution


print << "EOF";

 ##################
 # where_pm, File::Where boundary case
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>where_pm\(\ \'File\:\:Where\'\)", # typed in command           
      $actual = $uut->where_pm( 'File::Where')); # execution


print << "EOF";

 ##################
 # where_pm subroutine, array context, array reference path
 # 
 
EOF

demo( "\[\@actual\=\ \$uut\-\>where_pm\(\ \'t\:\:File\:\:Where\'\,\ \[\$test_script_dir\]\)\]", # typed in command           
      [@actual= $uut->where_pm( 't::File::Where', [$test_script_dir])]); # execution


print << "EOF";

 ##################
 # where_repository, array context, path absent
 # 
 
EOF

demo( "\[\@actual\=\ \$uut\-\>where_repository\(\ \'t\:\:File\'\ \)\]", # typed in command           
      [@actual= $uut->where_repository( 't::File' )]); # execution


print << "EOF";

 ##################
 # where_repository, scalar context, array path
 # 
 
EOF

demo( "\$actual\ \=\ \$uut\-\>where_repository\(\ \'t\:\:File\'\,\ \@inc2\)", # typed in command           
      $actual = $uut->where_repository( 't::File', @inc2)); # execution


print << "EOF";

 ##################
 # where_repository, array context, array reference path
 # 
 
EOF

demo( "\[\@actual\=\ \$uut\-\>where_repository\(\ \'t\:\:Jolly_Green_Giant\'\,\ \[\$test_script_dir\]\)\]", # typed in command           
      [@actual= $uut->where_repository( 't::Jolly_Green_Giant', [$test_script_dir])]); # execution


demo( "\ \ \ \@INC\ \=\ \@restore_inc\;\ \#restore\ \@INC\;\
\ \ \ rmtree\ \'t\'\;"); # typed in command           
         @INC = @restore_inc; #restore @INC;
   rmtree 't';; # execution


=head1 NAME

Where.d - demostration script for File::Where

=head1 SYNOPSIS

 Where.d

=head1 OPTIONS

None.

=head1 COPYRIGHT

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

## end of test script file ##

=cut

