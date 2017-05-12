#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Data::Startup;

use strict;
use 5.001;
use warnings;
use warnings::register;
use attributes;

use vars qw( $VERSION $DATE $FILE);
$VERSION = '0.03';
$DATE = '2004/04/26';
$FILE = __FILE__;


#######
# Object used to set default, startup, options values.
#
sub new
{
     my $class = shift;
     $class = ref($class) ? ref($class) : $class;

     #########
     # Create a new hash in hopes of not to
     # mangle, which may be a reference outside,
     # inputs to this subroutine.
     #
     my %startup_options;
     my $ref = ref($_[0]);
     $ref = attributes::reftype($_[0]) if($ref);
     if($ref eq 'HASH') {
         %startup_options = %{$_[0]};
         shift;
     }
     elsif($ref eq 'ARRAY') {
         %startup_options = @{$_[0]};
         shift;
     }
     else {
         %startup_options = @_;
     }
  
     bless \%startup_options,$class;
}


# use SelfLoader;

# 1

# __DATA__


######
# Provide a way to module wide configure
#
sub config
{
     my $self = shift;
     my ($key, $new_value) = @_;
     unless($key) {
         my @return;
         foreach (sort keys %$self) {
             push @return, $_, $self->{$_};
         }
         return @return;    
     }
     my $old_value = $self->{$key};
     $self->{$key} = $new_value if $new_value;
     $old_value;
}




#######
# Override the options in a default object and create
# a new object with the override options, perserving
# the default object.
# 
sub override
{
     my $self = shift;
     return bless {},'Data::Startup' unless ref($self);

     #########
     # A using package, subroutine, module may pass overrides
     # in a hash where the overrides for a package are
     # the package name in the hash
     # 
     my %options = %$self;
     my %options_override;

     #######
     # Using separate arrays, trying to avoid managing the
     # input.
     #
     if(@_) {
         my $ref = ref($_[0]);
         $ref = attributes::reftype($_[0]) if($ref);
         if($ref) {
             if($ref eq 'HASH') {
                 %options_override = %{$_[0]};
             }
             elsif($ref eq 'ARRAY') {
                 %options_override = @{$_[0]};
             }
         }
         else {
             %options_override = @_;
         }
         foreach (keys %options_override) {
             $options{$_} = $options_override{$_};
         }
     }
     bless \%options,ref($self);
}


=head1 NAME

Data::Startup - startup options class

=head1 SYNOPSIS


=head1 DESCRIPTION



=head2 config

 $old_value = config( $option );
 $old_value = config( $option => $new_value);
 (@all_options) = config( );

When Perl loads 
the C<Data::SecsPack> program module,
Perl creates the C<Data::SecsPack>
subroutine C<Data::SecsPack> object
C<$Data::SecsPack::subroutine_secs>
using the C<new> method.
Using the C<config> subroutine writes and reads
the C<$Data::SecsPack::subroutine_secs> object.

Using the C<config> as a class method,

 Data::SecsPack->config( @_ )

also writes and reads the 
C<$Data::SecsPack::subroutine_secs> object.

Using the C<config> as an object method
writes and reads that object.

The C<Data:SecsPack> subroutines used as methods
for that object will
use the object underlying data for their
startup (default options) instead of the
C<$Data::SecsPack::subroutine_secs> object.
It goes without saying that that object
should have been created using one of
the following:

 $object = $class->Data::SecsPack::new(@_)
 $object = Data::SecsPack::new(@_)
 $object = new Data::SecsPack(@_)

The underlying object data for the C<Data::SecsPack>
class of objects is a hash. For object oriented
conservative purist, the C<config> subroutine is
the accessor function for the underlying object
hash.

Since the data are all options whose names and
usage is frozen as part of the C<Data::SecsPack>
interface, the more liberal minded, may avoid the
C<config> accessor function layer, and access the
object data directly.

The options are as follows:

 used by                                     values default  
 subroutine    option                        value 1st
 ----------------------------------------------------------
               big_float_version              \d+\.\d+
               big_int_version                \d+\.\d+
               version                        \d+\.\d+

               warnings                        0 1
               die                             0 1

 bytes2int 

 float2binary  decimal_integer_digits          20 \d+
               extra_decimal_fraction_digits    5 \d+
               decimal_fraction_digits       
               binary_fraction_bytes

 ifloat2binary decimal_fraction_digits         25 \d+
               binary_fraction_bytes           10 \d+

 int2bytes
   
 pack_float    decimal_integer_digits          
               extra_decimal_fraction_digits   
               decimal_fraction_digits       
               binary_fraction_bytes

 pack_int 

 pack_num      nomix                            0 1
               decimal_integer_digits          
               extra_decimal_fraction_digits   
               decimal_fraction_digits       
               binary_fraction_bytes

 str2float
 str2int 
 unpack_float
 unpack_int
 unpack_num

For options with a default value and subroutine, see the subroutine for
a description of the option.  Each subroutine that
uses an option or uses a subroutine that
uses an option has an option input.
The option input overrides the startup option from
the <Data::SecsPack> object.

The description of the options without a subroutine are as follows:

 option              description
 --------------------------------------------------------------
 big_float_version   Math::BigFloat version
 big_int_version     Math::BigInt version
 version             Data::SecsPack version

 warnings            issue a warning on subroutine events
 die                 die on subroutine events

They really versions should not be changed unless the intend is to provided
fraudulent versions.


=head1 REQUIREMENTS

Coming.

=head1 DEMONSTRATION


=head1 QUALITY ASSURANCE

Running the test script C<Starup.t> verifies
the requirements for this module.
 
The <tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Starup.t> test script, C<Starup.d> demo script,
and C<t::Data::Starup> STD program module POD,
from the C<t::Data::Starup> program module contents.
The  C<t::Data::Starup> program module
is in the distribution file
F<Data-Secs2-$VERSION.tar.gz>.

=head1 NOTES

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
government practices, 490A (L<STD490A/3.2.3.6>).
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

=head1 SEE ALSO

=over 4

=item L<Docs::Site_SVD::Data_Startup|Docs::Site_SVD::Data_Startup>

=item L<Test::STDmaker|Test::STDmaker> 

=back

=cut

### end of script  ######