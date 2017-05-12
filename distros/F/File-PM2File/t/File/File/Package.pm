#!perl
#
# Documentation, copyright and license is at the end of this file.
#

package  File::Package;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.13';
$DATE = '2004/04/08';
$FILE = __FILE__;

use File::Spec;
# use SelfLoader;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(load_package is_package_loaded eval_str);
use vars qw(@import);

# 1;

# __DATA__


######
#
#
sub load_package
{

     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     local @import;

     (my $package, @import) = @_;

     unless ($package) { # have problem if there is no package
         return  "# The package name is empty. There is no package to load.\n";
     }

     if( $package =~ /\-/ ) {
         return  "# The - in $package causes problems. Perl thinks - is subtraction when it evals it.\n";
     }

     my $error = '';
     unless (File::Package->is_package_loaded( $package )) {

         #####
         # Load the module
         #
         # On error when evaluating "require $package" only the last
         # line of STDERR, at least on one Perl, is return in $@.
         # Save the entire STDERR to a memory variable
         #
         $error = eval_str ("require $package;");
         return "Cannot load $package\n\t" . $error if $error;

         #####
         # Verify the package vocabulary is present
         #
         unless (File::Package->is_package_loaded( $package )) {
             return "# $package loaded but package vocabulary absent.\n";
         }
     }

     ####
     # Import flagged symbols from load package into current package vocabulary.
     #
     if( @import ) {
         ####
         # Poor man's eval so that we can maintain caller stack for
         # proper use by import.
         #
         my $restore_level = $Exporter::ExportLevel;
         $Exporter::ExportLevel = 1;
         my $restore_warn = $SIG{__WARN__};
         my $restore_die = $SIG{__DIE__};
         $SIG{__WARN__} = sub { $error .= join '', @_; };
         $SIG{__DIE__} = sub { $error .= join '', @_; };
         $package->import( @import );
         $SIG{__WARN__} = ref( $restore_warn ) ? $restore_warn : '';
         $SIG{__DIE__} = ref( $restore_die ) ? $restore_die : '';
         $Exporter::ExportLevel = $restore_level;  
     }

     return $error;

}



#####
# Many times, all the warnings do not get into the $@ string
#
sub eval_str
{
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($str) = @_;

     my $restore_warn = $SIG{__WARN__};
     my $error_msg = '';
     $SIG{__WARN__} = sub { $error_msg .= join '', @_; };
     eval $str;
     $SIG{__WARN__} = ref( $restore_warn ) ? $restore_warn : '';

     $error_msg = $@ . $error_msg if $@;
     $error_msg =~ s/\n/\n\t/g if $error_msg;
     $error_msg;
}


######
#
#
sub is_package_loaded
{
     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

     my ($package) = @_;
   
     $package .= "::";
     my $vocabulary = defined %$package;
     my $require = File::Spec->catfile( split /::/, $_[0] . '.pm');
     my $inc = $INC{$require};

     ####
     # Microsoft cannot make up its mind to use
     # Microsoft \ or Unix / for path separator.
     # 
     # Just in case, running Microsoft, delete
     # Unix mirror name for the file
     #
     $require =~ s|\\|/|g; 
     $inc = $inc || $INC{$require};
     ($vocabulary && $inc) ? 1 : '';
}

1

__END__


=head1 NAME

File::Package - test load a program module with a package of the same name

=head1 SYNOPSIS

 ##########
 # Subroutine interface
 #
 use File::Package qw( is_package_loaded load_package);

 $package = is_package_loaded($package);
 $error   = load_package($package);
 $error   = load_package($package, @import);

 ##########
 # Class Interface
 # 
 use File::Package;

 $package = File::Package->is_package_loaded($package);
 $error   = File::Package->load_package($package);
 $error   = File::Package->load_package($package, @import);

 ###### 
 # Class Interface - Add File::Package to another class
 #
 use File::Package;
 use vars qw(@ISA);
 @ISA = qw(File::Package);

 $self = __PACKAGE__;
 $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

 $package = $self->is_package_loaded($package);
 $error   = $self->load_package($package);
 $error   = $self->load_package($package, @import);

=head1 DESCRIPTION

=head2 load_package method

The I<load_package> method attempts to capture any load problems by
loading the package with a "require " under an eval and capturing
all the "warn" and $@ messages. 
The I<@import> is optional and causes the load package messages
to import the symbols named by I<@import>.

One very useful application is in test scripts. 
If a package does load, it is very helpful that the program does
not die and reports the reason the package did not load. 
This information is readily available when loaded at a local site.
However, it the load occurs at a remote site and the load crashes
Perl, the remote tester usually will not have this information
readily available. 

If using it in a test script with the
'Test' module, be sure to use two arguments 
(2nd argument must be defined, not 0, not '')
for &Test::ok; 
otherwise the &Test::ok will not output the
the actual and expected in the failure error report.
For example,

 use Test;
 use File::Package qw(load_package);
 my $load_error = load_package($package_name);
 ok(!$load_error, 1);

 # skip rests of the tests unless $load_error eq ''

Other applications include using backup alternative software
if a package does not load. For example if the package
'Compress::Zlib' did not load, an attempt may be made
to use the gzip system command. 

=head2 is_package_loaded method

 $package = File::Package->is_package_loaded($package)

The I<is_package_loaded> method determines if a package
vocabulary is present.

=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Spec;

 =>     use File::Package;
 =>     my $uut = 'File::Package';
 =>     use File::Package;
 => my $errors = $uut->load_package( 'File::Basename' )
 ''

 => '' ne ($errors = $uut->load_package( 't::File::BadLoad' ) )
 '1'

 => '' ne ($errors = $uut->load_package( 't::File::BadVocab' ) )
 '1'

 => !defined($main::{'find'})
 '1'

 => $errors = $uut->load_package( 'File::Find', 'find' )
 ''

 => defined($main::{'find'})
 '1'

 => !defined($main::{'finddepth'})
 '1'

 => $errors = $uut->load_package( 'File::Find', '')
 ''

 => !defined($main::{'finddepth'})
 '1'

 => $errors = $uut->load_package( 'File::Find')
 ''

 => defined($main::{'finddepth'})
 '1'


=head1 QUALITY ASSURANCE

Running the test script 'Package.t' found in
the "File-Package-$VERSION.tar.gz" distribution file verifies
the requirements for this module.

All testing software and documentation
stems from the 
Software Test Description (L<STD|Docs::US_DOD::STD>)
program module 't::File::Package',
found in the distribution file 
"File-Package-$VERSION.tar.gz". 

The 't::File::Package' L<STD|Docs::US_DOD::STD> POD contains
a tracebility matix between the
requirements established above for this module, and
the test steps identified by a
'ok' number from running the 'Package.t'
test script.

The t::File::Package' L<STD|Docs::US_DOD::STD>
program module '__DATA__' section contains the data 
to perform the following:

=over 4

=item *

to generate the test script 'Package.t'

=item *

generate the tailored 
L<STD|Docs::US_DOD::STD> POD in
the 't::File::Package' module, 

=item *

generate the 'Package.d' demo script, 

=item *

replace the POD demonstration section
herein with the demo script
'Package.d' output, and

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

place the 't::File::Package' at the same
level in the directory struture as the
directory holding the 'File::Package'
module

=item *

execute the following in any directory:

 tmake -test_verbose -replace -run -pm=t::File::Package

=back

=head1 NOTES

=head2 FILES

The installation of the
"File-Package-$VERSION.tar.gz" distribution file
installs the 'Docs::Site_SVD::File_Package'
L<SVD|Docs::US_DOD::SVD> program module.

The __DATA__ data section of the 
'Docs::Site_SVD::File_Package' contains all
the necessary data to generate the POD
section of 'Docs::Site_SVD::File_Package' and
the "File-Package-$VERSION.tar.gz" distribution file.

To make use of the 
'Docs::Site_SVD::File_Package'
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
__DATA__ section of the 'Docs::Site_SVD::File_Package'
module.
For example, any changes to
'File::Package' will impact the
at least 'Changes' field.

=item *

Execute the following:

 vmake readme_html all -pm=Docs::Site_SVD::File_Package

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

=back
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