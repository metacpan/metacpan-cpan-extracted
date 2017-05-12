#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Data::Secs2;

use 5.001;
use strict;
use warnings;
use warnings::register;
use attributes;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.15';
$DATE = '2004/04/09';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(&stringify &listify &arrayify list2str);

#####
# If the variable is not a scalar,
# stringify it.
#
sub stringify
{
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     return $_[0] unless ref($_[0]) ||  1 < @_;
     list2str( listify(@_) );

}


sub list2str
{
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

     my @list = @{$_[0]};  # separate copy so do not clobber @_;
   
     my @level = ();
     my $spaces = '  ';
     my $indent = '';

     my ($format, $length, $element);

     my $string = '';

     while (@list) {

         my $length;
         my $format = shift @list;
         if(@level && $level[-1] <= 0) {
             while (@level && $level[-1] <= 0) {pop @level};
             $indent = $spaces x ((0 < @level) ? @level : 0);
         }

         if ($format eq 'L') {
             $length = shift @list;
             $string .= ${indent} . $format .'[' . $length . ']' . "\n";
             $level[-1] -= 1 if @level;
             push @level, $length;
             $indent = $spaces x ((0 < @level) ? @level : 0);
         }

         elsif ($format =~ /[IUF]\d+/) {
             $length = shift @list;
             $string .= ${indent} . $format .'[' . $length . ']';
             $string .= ' ' . (join ', ' , splice(@list,0,$length));
             $level[-1] -= 1 if @level;
         }

         elsif ($format =~ /[AJBT]/) {
             $element = splice(@list,0,1);
             $element = '' unless $element;
             $length = length($element);
             $string .= ${indent} . $format .'[' . $length . ']';
             $string .= ($element =~ /\n/) ? "\n" : ' ';
             $string .= $element;
             $level[-1] -= 1 if @level;
         }

         else {
            warn( "Unkown SECSII format $format\n");
            last;
         }

         $string .= "\n" if substr($string, -1, 1) ne "\n";

     };

     ########
     # Stingified SECSII message of a Perl Nested Data
     # 
     $string;

}



################
# This subroutine walks a nested data structure, and listify each level.
# The list is a perlified SECII message.
#
sub listify
{

     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);


     #########
     # Return an array, so going to walk the array, looking
     # for hash and array references to arrayify
     #
     # Use a stack for the walk instead of recusing. Easier
     # to maintain when the data is on a separate stack instead
     # of the call (return) stack and only the pertient data
     # is stored on the separate stack. The return stack does
     # not grow. Instead the separate recure stack grows.
     #
     my %dups = ();
     my @stack = ();
     my @index = ();

     my @list = ();  
     my $i = 0;
     my @var = @_; # do not clobber @_ so make a copy
     my $var = \@var;
     for(;;) {

        while($i < @$var) {

             my $ref_dup = (ref($var->[$i])) ? "$var->[$i]"  : '';
             $var->[$i] = arrayify( $var->[$i] );

             my ($class, $built_in_class, $scalar);
             my $ref = ref($var->[$i]);
             if( $dups{$ref_dup} ) {
                  my @dup_index = @{$dups{$ref_dup}};
                  push @list, ('L', '2', 'A', 'Index', 'U4', (scalar @dup_index), @dup_index);
             }

             ####
             # If a HASH or ARRAY reference was found,
             # it was arrayify. Save the place on the
             # current array, and look for HASH and
             # ARRAY references in the new array.
             #
             elsif ($ref) {
                 my @ref_index = (@index, $i);
                 $dups{$ref_dup} = \@ref_index;

                 ########
                 # Nest for 'ARRAY' references
                 #
                 if($ref eq 'ARRAY' ) {
                     push @stack, $var;
                     push @index, $i;
                     $var = $var->[$i];
                     $i = 0;
                     push @list, ('L', scalar @$var);
                     next;
                 }

                 ##########
                 # Reference to a list of 1
                 #
                 $built_in_class = attributes::reftype($var);
                 $class = (ref($var) ne $built_in_class) ? ref($var) : '';

                 push @list,('L', '3', 'A', $class, 'A',  $built_in_class);

                 if( attributes::reftype($var) eq 'SCALAR' ) {
                     push @list, 'A', ${$var->[$i]};
                 }

                 else {

                     ########
                     # Not data so stringify the reference and lose
                     # the ability to bring it back to Perl data.
                     #
                     # It is still good for making comparison for
                     # nested data from the same machine.
                     # 
                     push @list, 'A', "$var->[$i]";

                 }

             }

             else {

                 ########
                 # Pure simple scalar
                 # 
                 push @list, 'A', $var->[$i];

             }
             $i++;

         }

         #####
         # At the end of the current array, so go back
         # working on any array whose work was interupted
         # to work on the current array.
         #
         last unless @stack;   
         $i = pop @index;
         $i++;  
         $var = pop @stack;

    }

    ########
    # Listified unpacked SECSII message
    # 
    \@list;

}


###########
# The keys for hashes are not sorted. In order to
# establish a canonical form for the  hash, sort
# the hash and convert it to an array with a two
# leading control elements in the array. 
#
# The elements determine if the data is an array
# or a hash and its reference.
#
sub arrayify
{

     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($var,$indent) = shift @_;

     $indent = 0 unless $indent;

     if( ref($var) ) {

         my @array = (); 
         my $class;
         if ( attributes::reftype($var) eq 'HASH') {
             $class = (ref($var) ne 'HASH') ? ref($var) : '';
             @array = ($class,'HASH');
             my $value;
             foreach my $key (sort keys %$var ) {
                 push @array, ($key, $var->{$key});
             }
             return  \@array;
         }

         elsif( attributes::reftype($var) eq 'ARRAY') {
             $class = (ref($var) ne 'ARRAY') ? ref($var) : '';
             @array = ($class,  'ARRAY', @$var);
             return \@array;
         }

         elsif(attributes::reftype($var) eq 'SCALAR') {
             $class = (ref($var) ne 'SCALAR') ? ref($var) : '';
             @array = ($class,  'SCALAR', $$var);
             return \@array;
         }

         elsif(attributes::reftype($var) eq 'REF') {
             $class = (ref($var) ne attributes::reftype($var)) ? ref($var) : '';
             @array = ($class,  attributes::reftype($var), $$var);
             return \@array;
         }

         elsif(attributes::reftype($var) eq 'GLOB') {
             $class = (ref($var) ne attributes::reftype($var)) ? ref($var) : '';
             @array = ($class,  attributes::reftype($var));
             push @array,(*$var{SCALAR},*$var{ARRAY},*$var{HASH},*$var{CODE},
                          *$var{IO},*$var{NAME},*$var{PACKAGE},"*$var"),
             return \@array;  
         }

     }

     $var;

}


1

__END__

=head1 NAME
  
Data::Secs2 - canoncial string for nested data

=head1 SYNOPSIS

 #####
 # Subroutine interface
 #  
 use Data::Secs2 qw(stringify arrayify_walk arrayify);

 $string = stringify( @arg );
 @array = arrayify( @arg );
 @array = arrayify_var( @arg );

 #####
 # Class interface
 #
 use Data::Secs2;

 $string = Data::Secs2->stringify( @arg );
 @array = Data::Secs2->listify( @arg );
 @array = Data::Secs2->arrayify( $var );
 
 ##### 
 # Inherit by another class
 #
 use Data::Secs2
 use vars qw(@ISA);
 @ISA = qw(Data::Secs2);

 $string = __PACKAGE__->stringify( @arg );
 @array = __PACKAGE__->listify( @arg );
 @array = __PACKAGE__->arrayify( $var );


=head1 DESCRIPTION

The 'Data::SECSII' module provides a canoncial string for data
no matter how many nests of arrays and hashes it contains.

=head2 arrayify subroutine

The purpose of the 'arrayify_var' subroutine/method is
to provide a canoncial representation of hashes with
the keys sorted. This is accomplished by converting
a hash to an array of key value pairs with the keys
sorted. The variable reference is added as the first
member of a arary or arrayified hash to distinguish
a hash from a array in the unlikely event there are 
two data structures, one an array and the other a hash
where the array has the same member as an arrayified
hash.

The 'arrayify' subroutine/method converts $var into
an array as follows:

=over

=item reference with underlying 'HASH' data type

Converts a reference whose underlying data type is a 'HASH'
to array whose first member is ref($var), 
and the rest of the members the hash key, value pairs, sorted
by key

=item reference with underlying 'ARRAY' data type

Converts a reference whose underlying data type is a 'ARRAY'
to array whose first member is ref($var), 
and the rest of the members the members of the array

=item otherwise

Leaves $var as is.

=back

=head2 secsify subroutine

The 'secsify' subroutine/method walks a data structure and
converts all underlying array and hash references to arrays
by applying the 'arrayify' subroutine/method.

The secsification of the nested data is in accordance with 
L<SEMI|http://www.semi.org> E5-94,
Semiconductor Equipment Communications Standard 2 (SECS-II),
pronounced 'sex two' with gussto and a perverted smile. 
The SEMI E4 SECS-I standard addresses transmitting SECSII messages from one machine to
another machine (all most always host to equipment) serially via RS-232. And, there is
another SECS standard for TCP/IP, the SEMI E37 standard,
High-Speed SECS Message Services (HSMS) Generic Services.

In order not to plagarize college students,
credit must be given where credit is due.
Tony Blair, when he was a college intern at Intel Fab 4, in London
invented the SEMI SECS standards.
When the Intel Fab 4 management discovered Tony's secsification of
their host and equipment, 
they elected to have security to escort Tony out the door.
This was Mr. Blair's introduction to elections which he
leverage into being elected prime minister. 
In this new position he used the skills he learned
at the Intel fab to secsify intelligence reports on Iraq's
weopons of mass distruction.
 
The SEMI E5 SECS-II standard is a method of forming listified packed
messages from nested data. 
It consists of elements where each element is a format code, 
number of elements followed by the elements. 

 unpacked   binary  octal    description
 ----------------------------------------
 L          000000   00      List (length in elements)
 B          001000   10      Binary
 T          001001   11      Boolean
 A          010000   20      ASCII
 J          010001   21      JIS-8
 I8         011000   30      8-byte integer
 I1         011001   31      1-byte integer
 I2         011010   32      2-byte integer
 I4         011100   34      4-byte floating
 F4         100000   40      8-byte floating
 F8         100400   48      8-byte integer (unsigned)
 U8         101000   50      8-byte integer (unsigned)
 U1         101001   51      1-byte integer (unsigned)
 U2         101010   52      2-byte integer (unsigned)
 U4         101100   54      4-byte integer (unsigned)

Notes:

=over 4

=item 1
 
ASCII  format - Non-printing characters are equipment specific

=item 2 

Integer formats - most significant byte sent first

=item 3

floating formats - IEEE 753 with the byte containing the sign sent first.

=back

In this module, there are only three Perlified SECSII elements that 
will be listified into SECSII message as follows:

 OBJECT, INDEX OBJECT, and SCALAR

 OBJECT => 'L', $number-of-elements, 
           'A', $class,
           'A', $built-in-class,
           @elements

 @elements may contain a Perlified OBJECT, REFERENCE or SCALAR)

 INDEX OBJECT => 'L' '2', 'A' 'Index', 'U4', $number-of-indices, @indices 
 
 (reference is index into the nested list of lists)

 SCALAR = 'A', $scalar  (Perl built-in class)
                
=head2 stringify subroutine

The 'stringify' subroutine/method stringifies a data structure
by applying '&Dump::Dumper' to a data structure arrayified by
the 'arrayify' subroutine/method

=head2 new method

The new method establishes an object to configure the variables
in the 'Data::Dumper' module used by 'Data::Secs2'.

=head1 REQUIREMENTS

The requirements are coming.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Package;
 =>     my $fp = 'File::Package';

 =>     use Data::Secs2 qw(list2str);

 =>     my $uut = 'Data::Secs2';
 =>     my $loaded;
 => $uut->import( 'stringify' )
 => stringify( 'string' )
 'string'

 => stringify( 2 )
 2

 => stringify( '2', 'hello', 4 )
 'A[1] 2
 A[5] hello
 A[1] 4
 '

 => stringify( ['2', 'hello', 4] )
 'L[5]
   A[0] 
   A[5] ARRAY
   A[1] 2
   A[5] hello
   A[1] 4
 '

 => stringify( {header => 'To: world', body => 'hello'})
 'L[6]
   A[0] 
   A[4] HASH
   A[4] body
   A[5] hello
   A[6] header
   A[9] To: world
 '

 => stringify( '2', ['hello', 'world'], 4 )
 'A[1] 2
 L[4]
   A[0] 
   A[5] ARRAY
   A[5] hello
   A[5] world
 A[1] 4
 '

 => my $obj = bless { To => 'nobody', From => 'nobody'}, 'Class::None'
 => stringify( '2', { msg => ['hello', 'world'] , header => $obj } )
 'A[1] 2
 L[6]
   A[0] 
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0] 
     A[5] ARRAY
     A[5] hello
     A[5] world
 '

 => stringify( { msg => ['hello', 'world'] , header => $obj }, 
 =>                {msg => [ 'body' ], header => $obj} )
 'L[6]
   A[0] 
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0] 
     A[5] ARRAY
     A[5] hello
     A[5] world
 L[6]
   A[0] 
   A[4] HASH
   A[6] header
   L[2]
     A[5] Index
     U4[2] 0, 3
   A[3] msg
   L[3]
     A[0] 
     A[5] ARRAY
     A[4] body
 '


=head1 QUALITY ASSURANCE

Running the test script 'Secs2.t' found in
the "Data-Secs2-$VERSION.tar.gz" distribution file verifies
the requirements for this module.

All testing software and documentation
stems from the 
Software Test Description (L<STD|Docs::US_DOD::STD>)
program module 't::Data::Secs2',
found in the distribution file 
"Data-Secs2-$VERSION.tar.gz". 

The 't::Data::Secs2' L<STD|Docs::US_DOD::STD> POD contains
a tracebility matix between the
requirements established above for this module, and
the test steps identified by a
'ok' number from running the 'Secs2.t'
test script.

The t::Data::Secs2' L<STD|Docs::US_DOD::STD>
program module '__DATA__' section contains the data 
to perform the following:

=over 4

=item *

to generate the test script 'Secs2.t'

=item *

generate the tailored 
L<STD|Docs::US_DOD::STD> POD in
the 't::Data::Secs2' module, 

=item *

generate the 'Secs2.d' demo script, 

=item *

replace the POD demonstration section
herein with the demo script
'Secs2.d' output, and

=item *

run the test script using Test::Harness
with or without the verbose option,

=back

To perform all the above, prepare
and run the automation software as 
follows:

=over 4

=item *

Install "Test_STDmaker-$VERSION.tar.gz"
from one of the respositories only
if it has not been installed:

=over 4

=item *

http://www.softwarediamonds/packages/

=item *

http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=back
  
=item *

manually place the script tmake.pl
in "Test_STDmaker-$VERSION.tar.gz' in
the site operating system executable 
path only if it is not in the 
executable path

=item *

place the 't::Data::Secs2' at the same
level in the directory struture as the
directory holding the 'Data::Secs2'
module

=item *

execute the following in any directory:

 tmake -test_verbose -replace -run -pm=t::Data::Secs2

=back

=head1 NOTES

=head2 FILES

The installation of the
"Data-Secs2-$VERSION.tar.gz" distribution file
installs the 'Docs::Site_SVD::Data_Secs2'
L<SVD|Docs::US_DOD::SVD> program module.

The __DATA__ data section of the 
'Docs::Site_SVD::Data_Secs2' contains all
the necessary data to generate the POD
section of 'Docs::Site_SVD::Data_Secs2' and
the "Data-Secs2-$VERSION.tar.gz" distribution file.

To make use of the 
'Docs::Site_SVD::Data_Secs2'
L<SVD|Docs::US_DOD::SVD> program module,
perform the following:

=over 4

=item *

install "ExtUtils-SVDmaker-$VERSION.tar.gz"
from one of the respositories only
if it has not been installed:

=over 4

=item *

http://www.softwarediamonds/packages/

=item *

http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=back

=item *

manually place the script vmake.pl
in "ExtUtils-SVDmaker-$VERSION.tar.gz' in
the site operating system executable 
path only if it is not in the 
executable path

=item *

Make any appropriate changes to the
__DATA__ section of the 'Docs::Site_SVD::Data_Secs2'
module.
For example, any changes to
'Data::Secs2' will impact the
at least 'Changes' field.

=item *

Execute the following:

 vmake readme_html all -pm=Docs::Site_SVD::Data_Secs2

=back

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<US DOD 490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

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

=for html
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
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

### end of file ###