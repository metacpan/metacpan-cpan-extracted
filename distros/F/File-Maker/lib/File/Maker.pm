#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  File::Maker;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.05';
$DATE = '2004/05/13';

use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(load_db);

use File::Package;
use Tie::Layers 0.02;
use Tie::Form;
use Data::Startup;

use Cwd;
use File::Spec;

#######
#
# Handle the options
#
sub new 
{
     return undef unless @_;
     my ($class, @options) = @_;
     $class = ref($class) if ref($class);
     my $self =  bless {}, $class;
     $self->{options} = Data::Startup->new(@options);
     $self;
}


######
#
# make_targets
#
sub make_targets
{
     my ($self, $targets_h, @targets) = @_;

     $self->{options} = pop @targets if ref($targets[-1]) eq 'HASH';

     my $formDB_pm = $self->{options}->{pm};

     ########
     # Determine the formDB program module to load
     #
     unless( $formDB_pm ) {
         warn "No formDB program module.\n";
         return undef;
     }

     if( $self->{options}->{verbose} ) {
         print "~~~~~\nGenerating $formDB_pm " . (join ' ',@targets)    . "\n";
     }

     unless($self->{FormDB_PM} && $self->{FormDB_PM} eq $formDB_pm) {

         $self = $self->File::Maker::load_db($formDB_pm);
         unless(ref($self)) {
             warn "Cannot load $formDB_pm\n\t$self";
             return undef;
         }
          
     }

     @targets = ('all') unless( @targets );
     my $restore_dir = cwd();
     my $success = 1;

     if( @targets ) {

         my ($macro, $value, $target);
         foreach $target (@targets) {
             if( $target =~ /=/ ) {
                 ($macro,$value) = split /=/, $target;
                 $self->{FormDB}->{$macro} = $value;
                 next;
             }

             $self->{target} = $target;
             chdir $restore_dir;

             my $expanded_target = $targets_h->{$target};

             unless( $expanded_target ) {
                 $expanded_target = $targets_h->{__no_target__};
                 unless( $expanded_target ) {
                     warn "No expanded_target.\n";
                     $success = undef;
                     last;
                 }
             }

             my (@args,$method,$result);
             foreach $target (@{$expanded_target}) {
                 
                 $method = $target;  
                 @args = ();  
                 if(ref($target) eq 'ARRAY') {
                     ($method, @args) = @$target;                
                 }
                 
                 $result = $self->$method( @args );
                 if(ref($result) ) {
                     $self = $result;
                 }
                 elsif ( !defined($result) ) {
                     $success = undef;
                     warn( "Target $method failed.\n" );
                     last;
                 }

             }

             last unless( $success);
         }
     }

     chdir $restore_dir;

     print "\nFinished processing.\n" if $self->{options}->{verbose};
 
     $success;

}


#####
# Use a Form type database file for Variables
#
sub load_db
{

     my $self = ref($_[0]) ? shift :  {};
     my ($formDB_pm) = @_;

     #######
     # Add any extra directories to the include path
     #
     my @restore_inc = @INC; 
     unshift @INC, @{$self->{Load_INC}} if( $self->{Load_INC} ); 

     #####
     # load the FormDB program module
     #
     # Always look in the current directory first
     #
     unshift @INC, File::Spec->curdir();
     my $error;
     $formDB_pm = ref($formDB_pm) if ref($formDB_pm);
     if($error = File::Package->load_package($formDB_pm)) {
         @INC = @restore_inc; 
         return $error ;
     }

     ####
     # 
     #
     no strict;
     my $data_handle = \*{"$formDB_pm" . '::DATA'};
     use strict;
 
     my  $position = tell($data_handle );
     my $fh = $data_handle;
     my @data = <$fh>;
     seek($data_handle ,$position,0);
     tie *FORM, 'Tie::Form';
     open FORM, '<', $data_handle ;
     my @fields = <FORM>;
     seek($data_handle ,$position,0);

     ######
     # Bring the FormDB into memory as @std_db
     #
     my ($formDB_file);
     no strict;
     $formDB_file = ${"${formDB_pm}::FILE"};
     use strict;
     $self->{FormDB_File} = File::Spec->rel2abs( $formDB_file );

     $self->{FormDB_PM} = $formDB_pm;
     my $data = join '',@data;  # smart NL to convert to site NL
     $data =~ s/\015\012|\012\015/\012/g;  # replace LFCR or CRLF with a LF
     $data =~ s/\012|\015/\n/g;   # replace CR or LF with logical \n 
     $self->{FormDB_Record} = "\n" . $data;
     $self->{FormDB} = $fields[0];
     @INC = @restore_inc; 
     $self
}

1

__END__


=head1 NAME

File::Maker - mimics a make by loading a database and calling targets methods 

=head1 SYNOPSIS

 #####
 # Subroutine interface
 #
 use File::Maker qw(load_db);

 \%data = load_db($pm);

 ######
 # Object interface
 #
 require File::Maker;

 $maker = $maker->load_db($pm);

 $maker->make_targets(\%targets, @targets, \%options ); 
 $maker->make_targets(\%targets, \%options  ); 

 $maker = new File::Maker(@options);

Generally, if a subroutine will process a list of options, C<@options>,
that subroutine will also process an array reference, C<\@options>, C<[@options]>,
or hash reference, C<\%options>, C<{@options}>.
If a subroutine will process an array reference, C<\@options>, C<[@options]>,
that subroutine will also process a hash reference, C<\%options>, C<{@options}>.
See the description for a subroutine for details and exceptions.

=head1 DESCRIPTION

When porting low level C code from one architecture to another,
makefiles do provide some level of automation and save some
time.
However, once Perl or another high-level language is up and
running, the high-level language usually allows much more
efficient use of programmers time; otherwise, whats point
of the high-level language.
Thus, makes great economically sense to switch from makefiles
to high-level language.

The C<File::Maker> program module provides a "make" style interface
as shown in the herein above.
The C<@targets> contains a list of targets  that mimics the targets
of a C<makefile>. The targets are subroutines written in Perl
in a separate program module from the C<File::Maker>. 
The separate target program module inherits the methods in
the C<File::Maker> program module as follows:

 use File::Maker;
 use vars qw( @ISA );
 @ISA = qw(File::Maker);

The C<File::Maker> methods will then find the target subroutines in
the separate target program module.

The C<File::Maker> provides for the loading of a hash from a program
module to provide for the capabilities of C<defines> in a C<makefile>.
The option C<pm => $file> tells C<File::Maker> to load
a database from the __DATA__ section of a program module that is in the
L<Tie::Form|Tie::Form> format.
The C<Tie::Form> format is a very flexible lenient format that is
about as close to a natural language form and still have the
precision of being machine readable.
This provides a more flexible alternative to the defines
in a C<makefile>. 
The define hash is in a separate, very flexible form program module.
This arrangement allows one target program module that inherits
the C<File::Maker> program module to produce as many different
outputs as there are L<Tie::Form|Tie::Form> program modules.

=head1 METHODS

=head2 load_db

 \%data = load_db($pm);
 $maker = $maker->load_db($pm);

The C<load_db> subroutine loads the C<__DATA__> of C<$pm> using
L<C<Tie::Form>|Tie::Form> progrma module. The results are return
as a hash. If called as a object, the objec C<$maker> have hash
data. The return keys are as follows:

 key              description
 -------------------------------------------------------------- 
 FormDB_File      the absoute file of $pm
 FormDB_PM        $pm
 FormDB_Record    __DATA__ section of $pm
 FormDB           ordered name,value pairs of __DATA__ section

=head2 make_targets

 $maker->make_targets(\%targets, @targets); 
 $maker->make_targets(\%targets, @targets, \%options); 

 $maker->make_targets(\%targets); 
 $maker->make_targets(\%targets, \%options);

The C<make_targets> subroutine executes the C<@targets>
in order after substituing an expanded list C<$target[$targets[$i]}>
list if it exists, as follows:

 $result = $self->$target[$i]( @args )  

The C<@args> do not exists unless the C<$taget[$i]> is itself an
array reference in which case the C<make_targets> subroutine
assumes the array referenced is

 [$target, @args]

The return C<$result> may be a reference to an object, usually the
same class as the original $result, or a C<$success> flag of 1 or
undef. If C<$result> is a reference, the C<make_targets> subroutine
will set <$self> to the new object C<$result>.
Thus, by returning an reference, a target may pass data to the
next targe or even change the class of C<$self>.

=head2 new

 $maker = new File::Maker(@options);
 $maker = new File::Maker(\@options);
 $maker = new File::Maker(\%options);

The C<new> subroutine returns an object whose object data is
a hash reference of C<@options>.

=head1 REQUIREMENTS

Some day.

=head1 DEMONSTRATION

 #########
 # perl Maker.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     my $fp = 'File::Package';
     my $loaded = '';

     use File::SmartNL;
     my $snl = 'File::SmartNL';

     use File::Spec;

     my @inc = @INC;

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package( '_Maker_::MakerDB' )
 $errors

 # ''
 #
 $snl->fin(File::Spec->catfile('_Maker_','MakerDB.pm'))

 # '#!perl

 # package  _Maker_::MakerDB;

 # use strict;
 # use warnings;
 # use warnings::register;

 # use vars qw($VERSION $DATE $FILE );
 # $VERSION = '0.01';
 # $DATE = '2004/05/10';
 # $FILE = __FILE__;

 # use File::Maker;
 # use vars qw( @ISA );
 # @ISA = qw(File::Maker);

 # ######
 # # Hash of targets
 # #
 # my %targets = (
 #    all => [ qw(target1 target2) ],
 #    target3 => [ qw(target1 target3) ],
 #    target4 => [ qw(target1 target2 target4) ],
 #    __no_target__ => [ qw(target3 target4 target5) ],
 # );

 # my $data = '';

 # sub make
 # {
 #    my $self = shift @_;
 #    $self->make_targets( \%targets, @_ );
 #    my $result = $data;
 #    $data = '';
 #    $result
 # }

 # sub target1
 # {
 #   $data .= ' target1 ';
 #   1
 # }

 # sub target2
 # {
 #   $data .= ' target2 ';
 #   1
 # }

 # sub target3
 # {
 #   $data .= ' target3 ';
 #   1
 # }

 # sub target4
 # {
 #   $data .= ' target4 ';
 #   1
 # }

 # sub target5
 # {
 #   $data .= ' target5 ';
 #   1
 # }

 # 1

 #__DATA__

 #Revision: -^
 #End_User: General Public^
 #Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 #Version: ^
 #Classification: None^

 #~-~
 #'
 #

 ##################
 # No target
 # 

 my $maker = new _Maker_::MakerDB( pm => '_Maker_::MakerDB' )
 $maker->make( )

 # ' target1  target2 '
 #

 ##################
 # FormDB_File
 # 

 $maker->{FormDB_File}

 # 'E:\User\SoftwareDiamonds\installation\t\File\_Maker_\MakerDB.pm'
 #

 ##################
 # FormDB_PM
 # 

 $maker->{FormDB_PM}

 # '_Maker_::MakerDB'
 #

 ##################
 # FormDB_Record
 # 

 $maker->{FormDB_Record}

 # '

 #Revision: -^
 #End_User: General Public^
 #Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 #Version: ^
 #Classification: None^

 #~-~
 #'
 #

 ##################
 # FormDB
 # 

 $maker->{FormDB}

 # [
 #          'Revision',
 #          '-',
 #          'End_User',
 #          'General Public',
 #          'Author',
 #          'http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com',
 #          'Version',
 #          '',
 #          'Classification',
 #          'None'
 #        ]
 #

 ##################
 # Target all
 # 

 $maker->make( 'all' )

 # ' target1  target2 '
 #

 ##################
 # Unsupport target
 # 

 $maker->make( 'xyz' )

 # ' target3  target4  target5 '
 #

 ##################
 # target3
 # 

 $maker->make( 'target3' )

 # ' target1  target3 '
 #

 ##################
 # target3 target4
 # 

 $maker->make( qw(target3 target4) )

 # ' target1  target3  target1  target2  target4 '
 #

 ##################
 # Include stayed same
 # 

 [@INC]

 # [
 #          'E:\User\SoftwareDiamonds\installation\t\File\lib',
 #          'E:/User/SoftwareDiamonds/installation/t/File',
 #          'E:\User\SoftwareDiamonds\installation\lib',
 #          'D:/Perl/lib',
 #          'D:/Perl/site/lib',
 #          '.'
 #        ]
 #

=head1 QUALITY ASSURANCE

Running the test script C<Maker.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Maker.t> test script, C<Maker.d> demo script,
and C<t::File::Maker> STD program module POD,
from the C<t::File::Maker> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Maker.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::File::Maker> program module
is in the distribution file
F<File-Maker-$VERSION.tar.gz>.

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

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

=back

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
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

=item L<Tie::Form|Tie::Form>

=item L<Docs::Site_SVD::File_Maker|Docs::Site_SVD::File_Maker>

=item L<Test::STDmaker|Test::STDmaker>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

=back

=cut


### end of file  ######