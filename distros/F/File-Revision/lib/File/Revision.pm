#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  File::Revision;

require 5.001;

use strict;
use warnings;
use warnings::register;
use File::Spec;
use Data::Startup;

use vars qw($VERSION $DATE);
$VERSION = '1.04';
$DATE = '2004/05/03';

use vars qw($revision_letters $revision_base);
$revision_letters = 'ABCDEFGHJKLMNPRTUVWY';
$revision_base = length($revision_letters);

use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(new_revision num2revision parse_options revision2num revision_file rotate);

use SelfLoader;

1;

__DATA__

########
# 
#
sub new_revision
{
     #######
     # Drop object or class $self
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $file = shift;
     return(undef,"No file supplies\n") unless($file);
     my $options = parse_options($file,@_);

     if($options->{revision_number} <= 0 && !-e $file) {
         return ($file, $options->{rev_letters} ? 'A' : '1');
     }


     #######
     # Search for a file that does not exist that has the next revision from
     # the highest revision.
     #
     my $revision_number = $options->{revision_number};
     do {

         if ($options->{top_revision_number} && $options->{top_revision_number} <= $revision_number) {
             return(undef, "Revision number $revision_number overflowed limit of $options->{top_revision_number}.\n");
         }
         $file = revision_file($revision_number++, $options);
 
     }  while (-e $file);

     ($file, $options->{rev_letters} ? num2revision($revision_number) : $revision_number);
}



####
# 
# 
sub num2revision
{
     my $self = __PACKAGE__;
     $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($num) = @_;
     return '-' unless $num;
     my $rev = '';
     use integer;
     while ($num) {
         $rev = substr($revision_letters,($num - 1) % $revision_base,1) . $rev;
         $num = ($num - 1) / $revision_base;
     }
     no integer;
     $rev;
}



########
# 
#
sub parse_options
{
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $file = shift;
     return(undef,"No file supplies\n") unless($file);

     my $options = new Data::Startup(@_);

     #####
     # Parse the file into an path, base name and extension 
     #
     my ($vol,$dir,$base) = File::Spec->splitpath($file);
     my ($ext,$pat) = ('','\..*?');
     $pat = (File::Spec->case_tolerant() ? '(?i)' : '') . "($pat)\$";
     $ext = $1 . $ext if ($base =~ s/$pat//s);
     $options->{vol} = $vol;
     $options->{dir} = $dir;
     $options->{ext} = $ext unless $options->{ext};
     $options->{base} = $base unless $options->{base};


     ######
     # Process revision
     #
     $options->{revision} = $options->{rotate} if $options->{rotate};
     $options->{revision} = 0 unless $options->{revision};
     $options->{revision} = $options->{revision} =~ /\s*(\S+)/ ? $1 : '0';
     if ($options->{revision} =~ /^(\d+)/) {
         $options->{revision_number} = $1;
         $options->{revision_number} = $options->{revision};
         $options->{rev_letters} = 0;
     }
     elsif($options->{revision} =~ /^([$revision_letters]+)/) {
         $options->{revision_number} = $1;
         $options->{revision_number} = revision2num($options->{revision});
         $options->{rev_letters} = 1;
     }

     ######
     # If do not have a valid revision, consider it an original
     #
     $options->{revision_number} = 0 unless ($options->{revision_number});

     ######
     # Determine the top revision based upon the number of places
     #
     $options->{places} = '' unless defined $options->{places}; 
     if($options->{places}) {
         if($options->{rev_letters}) {
             $options->{top_revision_number} = $revision_base ** $options->{places}; 
             $options->{lead_places} = '_' unless $options->{lead_places};
         }
         else {
             $options->{top_revision_number} = 10 ** $options->{places};
             $options->{lead_places} = '0' unless $options->{lead_places};
         }
     }
     else {
         $options->{top_revision_number} = '';
         $options->{lead_places} = '' unless $options->{lead_places}; 
     }

     $options->{pre_revision} = '-' unless defined $options->{pre_revision};

     $options;
}



####
# 
# 
sub revision2num
{
     my $self = __PACKAGE__;
     $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($rev) = @_;
     return 0 if $rev eq '-';
     my $num = 0;
     use integer;
     while (length($rev)) {  
        $num = $revision_base * $num; 
        $num += 1 + index($revision_letters,substr($rev,0,1));    
        $rev = substr($rev,1);
     }
     no integer;
     $num;
}


######
#
#
sub revision_file
{
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($revision_number, $options) = @_;

     my $revision = $options->{rev_letters} ? num2revision($revision_number) : $revision_number;
     if($options->{places}) {
        $revision = ($options->{lead_places} x ($options->{places} - length($revision))) . $revision;
     }
     File::Spec->catpath($options->{vol},$options->{dir},
                    $options->{base} . $options->{pre_revision} . ${revision} . $options->{ext});
}


########
# 
#
sub rotate
{
     #######
     # Drop object or class $self
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $file = shift;
     return(undef,"No file supplies\n") unless($file);
     my $options = parse_options($file,@_);

     #####
     # Rotate files
     #
     my ($from_sequence,$to_sequence,$from_file,$to_file);
     my $sequence_number = $options->{revision_number};
     if ($options->{top_revison_number} && $options->{top_revison_number} <= $sequence_number) {
         return(undef, "Number of rotate files, $sequence_number, overflowed limit of $options->{top_revison_number}.\n");
     }
     $from_file = revision_file($sequence_number, $options);

     #####
     # If $from_file exists, rotate
     #  
     if(-e $from_file) {
         unlink revision_file(0, $options);
         $sequence_number = 0;
         do {
             $sequence_number++;
             $from_file = revision_file($sequence_number, $options);   
             $to_file = revision_file($sequence_number-1, $options);
             rename($from_file, revision_file($sequence_number-1, $options)); 
         } while($sequence_number < $options->{revision_number});
     }
 
     ######
     # Find the next revision
     # 
     else {
         $sequence_number = 0;
         for($sequence_number = 0; $sequence_number <= $options->{revision_number}; $sequence_number++) {
            $from_file = revision_file($sequence_number, $options);
            last unless -e $from_file;
         };
     }
     ($from_file, $sequence_number);
}



1;


__END__


#########
# Perl Plain Old Documentaion (POD) 
#
=head1 NAME
 
 File::Revision - return a name of non-existing backup file with a revision id

=head1 SYNOPSIS

 #######
 # Subroutine interface
 #
 use File::Revision qw(new_revision num2revision parse_options revision2num revision_file rotate);

 ($file_name, $next_revsion) = new_revision($file, @options);
 ($file_name, $next_revsion) = new_revision($file, \@options);
 ($file_name, $next_revsion) = new_revision($file, \%options);

 $revision_letter = num2revision($revision_number); 

 $options = parse_options($file, @options);
 $options = parse_options($file, \@options);
 $options = parse_options($file, \%options);

 $revision_number = revision2num($revision_letter; 

 $file_name = revision_file($revision_number, $options);

 $file_name = rotate($file, @options);
 $file_name = rotate($file, \@options);
 $file_name = rotate($file, \%options);

 #######
 # Object interface
 #  
 $self = 'File::Revision'; # or
 $self = new $class; # where $class::@ISA contains 'File::Revision'

 ($file_name, $next_revsion) = $self->new_revision($file, @options);
 ($file_name, $next_revsion) = $self->new_revision($file, \@options);
 ($file_name, $next_revsion) = $self->new_revision($file, \%options);

 $revision_letter = $self->num2revision($revision_number); 

 $options = $self->parse_options($file, @options);
 $options = $self->parse_options($file, \@options);
 $options = $self->parse_options($file, \%options);

 $revision_number = $self->revision2num($revision_letter; 

 $file_name = $self->revision_file($revision_number, $options);

 $file_name = $self->rotate($file, @options);
 $file_name = $self->rotate($file, \@options);
 $file_name = $self->rotate($file, \%options);

=head1 DESCRIPTIONS

The C<File::Revision> program modules provides the name of a non-existing file
with a revision identifier
based on the a file name $file.
This has many uses backup file uses. 
There are no restrictions on the number of backup files or the time to live
of the backup files.

A typical use would be to create a backup file for
If the revised file passes does not pass all validity
checks, use the backup file to replace or repair the revised file.
This minimizes loses import data when revising files. 

Better yet, create a temporary
file, using one of the temp file name program modules.
Revise the temp file. Once it passes all valitity checks,
rename the original file to the backup file and
rename the temp file to the original file.
This allows full use of the original file until a
validated revison is ready to replace it.

The C<File::Revision> program module also supports limiting
the backup files and delete the oldest once C<File::Revision>
reaches the rotation limit.


=head1 SUBROUTINES

=head2 new_revision

 ($file_name, $next_revsion) = new_revision($file, @options);

The C<new_revision> subroutine returns the name of a non-existing
file by appending revision letters to the base name of a supplied file.
The supplied file usually exists.

=head2 num2revsion

 $revision = num2revsion($number)

The C<num2revision> is the inverse of C<revision2num>
as described below.

=head2 parse_options

 $options = parse_options($file, @options);

The C<parse_options> subroutine pre-process the options and used internally
by the other routines. The only external ues is as an input to
the C<revision_file> subroutine.   

The C<rotate> and C<new_revision> subroutine embeds the
revision in the C<$file> input to produce the C<$file_name>
output as follows:

 "$vol$dir$base$pre_revision$lead_revision$revision$ext"

The C<$vol $dir $base $ext> are obtained from the
C<$file> input but may be overrided by the
options C<vol dir base ext>. The $pre_revision is
the C<pre_revision> option and has a default
of '-'. The C<$lead_revision> comes in play when
a the C<places> option has a number. It contains
just enough characters so that C<places> revision
is exactly

 length(($lead_revision$revision")

The C<lead_revision> default to a '_' for
drafing style letter revisions and '0' for
numeric revisions. 

 options       description
 ----------------------------------------------------------
 base          overide the $file_name base
 dir           overide the $file_name dir
 ext           overide the $file_name ext

 lead_places   fill for places

 places        the maximum places of the embedded revision

 revision      the lowest revision embedded in $file_name
               (new_revision subroutine only)

 rotate        the highest revision embeded in $file_name
               (rotate subroutine only)

 vol           overide the $file_name vol


=head2 revision2num

 $number = revision2num($revision)

The C<revision2num> subroutine converts
a drawing revision letter(s)
that complies to American industry, US DOD,
and International drawing
practices to a number, where 0 is the drawing
release, 1 the 1st revision, 2 the 2nd revision
and so forth.

The old DOD-STD-100C which itself cited a slew of
American National Standards,
may itself been superceded by an American National Standard.
Anyway drawing revisions are pretty the same across 
commerical, military and national boundaries.
The US Navy provides DOD-STD-100C free.
However, comericalized American Nation Standards are
not so generous. 
They do not have the American taxpayer to support
their generosity.

DOD-Std-100C 5003.2, Drawing Practices, states

'5003.2 Revision Letters. Upper-case letters shall be
used in alphabetical sequence. The letters "I", "O", "Q", "S',
"X" and "Z" shall be omitted. When  revisions are numberous enough to
exhaust the alphabet the revision following Y shall be "AA" and the
next "AB", the "AC", etc. Revision letters shall not exceed two
characters. The first revision to a drawing shall be assigned the
letter A. Release (initial issue) of a drawing does not constitute a need 
for a revision letter.'

The convention is to use rev - for the initial release. The requirement
that the revision does not exceed two letters, maximum of 400 revisions, is not 
realistic for automation of drawings. The revision for index drawings that
index large databases can easy exceed this very quickly.

During the development of software programs, there can easily be more
than 400 builds. When this happens, for strcit compliance,
the drawing had to be rolled over to a new
drawing and start out with rev -.
Isn't more sensible to allow more than two letters for revisions,
especially since it is easy to convert revision letters
into a number.

When using hard paper media, 400 revisions never exist. Management
lowers the hammer about revision MN. They fire the development team
and bring in a new one.

Once there was a software engineer (SE) working on a Laser Printer
and the lead mechanical engineer (ME)
came it and starting examining a part. The SE asked him why he was looking so
intensely at that part. The ME replied that they where going to revise it.
SE: "Whey are you revising it?" ME: "It is the only part that has not
been changed." That is funny unless you are the manager paying for it.

The standard drawing revision conventions is an interesting number system
with no symbol for zero  (absence of a revision is zero) and is base 20.
The Persians successfully argued that the lack of a zero makes the arith twisted
back in what is now Iran, Iraq around 600 A.D.
However, the drafing disciplines never
went along with this concept.
Maybe they feel a symbol for zero makes the arith twisted.
Anyway with non-zero digit arith there are additions and subtractions
of one to shift around numbers to line up with the computer arith which
uses arith with a zero symbol.

Actually this is being unkind. 
The reason drafting uses letters is because they are trying to make
it hard to confuse the drawing revision with the drawing number.
Then again, the American drafting standards and Internationl drafting
standards allow letters in the drawing number. 
In other words, do not tried to understand drafting standards or
make sense out of them.
Just live with them.

Take a look at a base 4 number system without zero.

    digits 1 2 3 4

    Weights  zero base ten
    16 4 1   number 
   --------------------------
                 0
         1       1   
         2       2
         3       3
         4       4
       1 1       5
       1 2       6
       1 3       7
       1 4       8
       2 1       9
       2 4      12 
       3 1      13
       3 4      16
       4 1      17
       4 4      20
     1 1 1      21

    base 10 non-zero digit 
    digits 1 2 3 4 5 6 7 8 9 A

    Weights     zero base ten
    100 10  1   number 
     9A  A  1
   --------------------------
                    0
            1       1   
            2       2
            3       3
            4       4
            A      10
         1  1      11
         9  A     100
         A  1     101
         A  A     110
      1  1  1     111 
      A  A  A    1110

   base 20 non-zero digit

             1111111112
   12345678901234567890
   ABCDEFGHJKLMNPRTUVWY   

                  non-zero digit 
   400   20   1   number 
              -       0
              A       1
              Y      20
          A   A      21
          A   Y      40
          W   Y     400
          Y   A     401
          Y   Y     420  
  

=head2 revision_file

  $file_name = revision_file($revision_number, parse_options($file, @options));

The C<revision_file> subroutine returns the backup file name for C<$file> with
the C<$revision_number> embedded. This subroutine does not check to see
if the C<$file_name> exists. The C<rotate> and C<new_revision> subroutines
use it extensively internally.

=head2 rotate

 $file_name = rotate($file, @options);

The C<rotate> subroutine returns is similar to the C<new_file> subroutine
except that it uses C<rotate> as the highest revision that will be
embedded in $file_name. When the subroutine finds that the highest revision
file exists, it unlinks the oldest revision and rotates the rest of the
files by renaming them to the next lowest revision.  The subroutine
returns the a C<$file_name> with the vacated C<rotate> revision embedded
in the name.

=head1 REQUIREMENTS

Someday.

=head1 DEMONSTRATION

 #########
 # perl Revision.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::AnySpec;
     use File::Package;
     use File::Path;
     use File::Copy;
     my $fp = 'File::Package';
     my $uut = 'File::Revision';
     my ($file_spec, $from_file, $to_file);
     my ($backup_file, $rotate) = ('','');
     my $loaded = '';

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut)

 # ''
 #

 ##################
 # revision2num('-')
 # 

 File::Revision->revision2num(-)

 # 0
 #

 ##################
 # num2revision('0')
 # 

 File::Revision->num2revision(0)

 # '-'
 #

 ##################
 # revision2num('Y')
 # 

 File::Revision->revision2num(Y)

 # 20
 #

 ##################
 # num2revision('20')
 # 

 File::Revision->num2revision(20)

 # 'Y'
 #

 ##################
 # revision2num('AA')
 # 

 File::Revision->revision2num(AA)

 # 21
 #

 ##################
 # num2revision('21')
 # 

 File::Revision->num2revision(21)

 # 'AA'
 #

 ##################
 # revision2num('WY')
 # 

 File::Revision->revision2num(WY)

 # 400
 #

 ##################
 # num2revision('400')
 # 

 File::Revision->num2revision(400)

 # 'WY'
 #

 ##################
 # revision2num('YY')
 # 

 File::Revision->revision2num(YY)

 # 420
 #

 ##################
 # num2revision('420')
 # 

 File::Revision->num2revision(420)

 # 'YY'
 #

 ##################
 # revision2num('AAA')
 # 

 File::Revision->revision2num(AAA)

 # 421
 #

 ##################
 # num2revision('421')
 # 

 File::Revision->num2revision(421)

 # 'AAA'
 #

 ##################
 # revision_file( 7, parse_options( 'myfile.myext', pre_revision => '', revision => 'AA') )
 # 

      File::Revision->revision_file( 7, File::Revision->parse_options( 'myfile.myext',
      pre_revision => '', revision => 'AA'))

 # 'myfileG.myext'
 #

 ##################
 # new_revision(ext => '.bak', revision => 1, places => 6, pre_revision => '')
 # 

 $file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm')
     [File::Revision->new_revision(_Drawings_\Erotica.pm, ext => '.bak', revision => 1,
     places => 6, pre_revision => '')]

 # [
 #          '_Drawings_\Erotica000001.bak',
 #          '2'
 #        ]
 #

 ##################
 # new_revision(ext => '.htm' revision => 5, places => 6, pre_revision => '')
 # 

 [File::Revision->new_revision(_Drawings_\Erotica.pm,  revision => 1000, places => 3, )]

 # [
 #          undef,
 #          'Revision number 1000 overflowed limit of 1000.
 #'
 #        ]
 #

 ##################
 # new_revision(base => 'SoftwareDiamonds', ext => '.htm', places => 6, pre_revision => '')
 # 

      [File::Revision->new_revision(_Drawings_\Erotica.pm,  base => 'SoftwareDiamonds', 
      ext => '.htm', revision => 5, places => 6, pre_revision => '')]

 # [
 #          '_Drawings_\SoftwareDiamonds000005.htm',
 #          '6'
 #        ]
 #
 $file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/original.htm')

 ##################
 # new_revision(_Drawings_\original.htm, revision => 0,  pre_revision => '')
 # 

 [File::Revision->new_revision(_Drawings_\original.htm, revision => 0,  pre_revision => '')]

 # [
 #          '_Drawings_\original.htm',
 #          '1'
 #        ]
 #
      rmtree( '_Revision_');
      mkpath( '_Revision_');
      $from_file = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm');
      $to_file = File::AnySpec->fspec2os('Unix', '_Revision_/Erotica.pm');

 ##################
 # File::Revision->rotate(_Revision_\Erotica.pm, rotate => 2) 1st time
 # 

 [(,) = File::Revision->rotate(_Revision_\Erotica.pm, rotate => 2, pre_revision => '')]

 # [
 #          '_Revision_\Erotica0.pm',
 #          0
 #        ]
 #
 copy($from_file,$backup_file)

 ##################
 # File::Revision->rotate(_Revision_\Erotica.pm, rotate => 2) 2nd time
 # 

 [(_Revision_\Erotica0.pm,0) = File::Revision->rotate(_Revision_\Erotica.pm, rotate => 2, pre_revision => '')]

 # [
 #          '_Revision_\Erotica1.pm',
 #          '1'
 #        ]
 #
 copy($from_file,$backup_file)

 ##################
 # File::Revision->rotate(_Revision_\Erotica.pm, rotate => 2) 3rd time
 # 

 [(_Revision_\Erotica1.pm,1) = File::Revision->rotate(_Revision_\Erotica.pm, rotate => 2, pre_revision => '')]

 # [
 #          '_Revision_\Erotica2.pm',
 #          '2'
 #        ]
 #
 copy($from_file,$backup_file)

 ##################
 # File::Revision->rotate(_Revision_\Erotica.pm, rotate => 2) 4th time
 # 

 [(_Revision_\Erotica2.pm,2) = File::Revision->rotate(_Revision_\Erotica.pm, rotate => 2, pre_revision => '')]

 # [
 #          '_Revision_\Erotica2.pm',
 #          '2'
 #        ]
 #
 rmtree( '_Revision_');

=head1 QUALITY ASSURANCE

Running the test script C<Revision.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Revision.t> test script, C<Revision.d> demo script,
and C<t::File::Revision> STD program module POD,
from the C<t::File::Revision> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Startup.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::File::Revision> program module
is in the distribution file
F<File-Revision-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright Notice

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements Notice

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
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

=head1 SEE ALSO

=over 4

=item L<Docs::Site_SVD::File_Revision|Docs::Site_SVD::File_Revision>

=item L<Test::STDmaker|Test::STDmaker>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

=back

=cut


### end of script  ######