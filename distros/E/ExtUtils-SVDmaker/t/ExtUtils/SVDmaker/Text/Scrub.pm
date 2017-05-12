#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Text::Scrub;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.17';
$DATE = '2004/05/25';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(scrub_architect scrub_date scrub_date_ticket scrub_date_version 
                scrub_file_line scrub_probe scrub_test_file);

# use SelfLoader;
# 1
# __DATA__

#######
# Blank out the Verion, Date for comparision
#
#
sub scrub_architect
{

    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($text) = @_;

    return $text unless $text;

    ######
    # Blank out the architecutre name
    #
    $text =~ s/ARCHITECTURE NAME\s*=\s*['"].*?['"]/ARCHITECTURE NAME="Perl"/ig; 

    ######
    # Blank out the osname
    #
    $text =~ s/OS NAME\s*=\s*['"].*?['"]/OS NAME="Site OS"/ig; 

    $text

}


#####
# 
# Scrub date
#
#
sub scrub_date
{
    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($text) = (@_);
    $text =~ s|([ '"(]?)\d{2,4}/\d{1,2}/\d{1,2}([ '")\n]?)|${1}1969/02/06${2}|g;
    $text

}

#######
# Blank out the Verion, Date for comparision
#
#
sub scrub_date_version
{
    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($text) = @_;

    return $text unless $text;

    ######
    # Blank out version and date for comparasion
    #
    $text =~ s/\$VERSION\s*=\s*['"].*?['"]/\$VERSION = '0.00'/ig;      
    $text =~ s/\$DATE\s*=\s*['"].*?['"]/\$DATE = 'Feb 6, 1969'/ig;
    $text =~ s/DATE:\s+.*?\n/\$DATE: Feb 6, 1969\n/ig;
    $text

}



#####
# Date changes between runs so cannot have
# a static compare file unless you eliminate
# the date. Also the ticket is different
#
sub scrub_date_ticket
{
    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($email) = @_;

    $email =~ s/Date: .*?\n/Date: Feb 6 00 00 00 1969 +0000\n/ig;

    $email =~ s/Subject: .*?,(.*)\n/Subject: XXXXXXXXX-X, $1\n/ig;

    $email =~ s/X-SDticket:.*?\n/X-SDticket: XXXXXXXXX-X\n/ig;

    $email =~ s/\QFrom ???@???\E .*?\n/From ???@??? Feb 6 00 00 00 1969 +0000\n/ig;

    $email =~ s/X-eudora-date: .*?\n/X-eudora-date: Feb 6 00 00 00 1969 +0000\n/ig;

    $email =~ s/X-SDmailit: sent .*?\n/X-SDmailit: sent Sat Feb 6 00 00 00 1969 +0000\n/ig;

    $email =~ s/X-SDmailit: dead .*?\n/X-SDmailit: dead Sat Feb 6 00 00 00 1969 +0000\n/ig;

    $email =~ s/Sent email \S+ to (.*?)\n/Sent email XXXXXXXXX-X to $1\n/ig;

    open OUT, '> actual.txt';  # use to gen the expected
    print OUT $email;
    close OUT;;
    $email;
}


#######
# Blank out the Verion, Date for comparision
#
#
sub scrub_file_line
{
    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($text) = @_;

    return $text unless $text;

    ######
    # Blank out version and date for comparasion
    #
    $text =~ s/\(.*?at line \d+/(xxxx.t at line 000/ig;

    ######
    # Most Perls return single quotes around numbers; however,
    # darwin-thread-multi-2level 7.0, and probably others
    # return double quotes
    #
    $text =~ s/\"(\d+)\"/'$1'/g;

    $text

}

#####
#
#
sub scrub_probe
{
    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($text) = @_;
    $text =~ s/^(.*?\n)(.*?)\#\s+=cut\s*\n/$1/s;
    $text
}

#######
# Blank out the Verion, Date for comparision
#
#
sub scrub_test_file
{
    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($text) = @_;

    return $text unless $text;

    ######
    # Blank out version and date for comparasion
    #
    $text =~ s/Running Tests.*?1\.\./Running Tests xxx.t 1../sig;
    $text

}


1


__END__

=head1 NAME
  
Text::Scrub - used to wild card out text used for comparison

=head1 SYNOPSIS


  #########
  # Subroutine Interface
  #
  use Text::Scrub qw(scrub_date scrub_date_ticket scrub_date_version scrub_file_line 
                     scrub_probe scrub_test_file);

  $scrubbed_text = scrub_architect($script_text)
  $scrubbed_text = scrub_file_line($script_text)
  $scrubbed_text = scrub_date($script_text)
  $scrubbed_text = scrub_date_ticket($script_text)
  $scrubbed_text = scrub_date_version($script_text)
  $scrubbed_text = scrub_probe($script_text)
  $scrubbed_text = scrub_test_file($script_text)

  #########
  # Class Interface
  #
  use Text::Scrub

  $scrubbed_text = Text::Scrub->scrub_architect($script_text)
  $scrubbed_text = Text::Scrub->scrub_file_line($script_text)
  $scrubbed_text = Text::Scrub->scrub_date($script_text)
  $scrubbed_text = Text::Scrub->scrub_date_ticket($script_text)
  $scrubbed_text = Text::Scrub->scrub_date_version($script_text)
  $scrubbed_text = Text::Scrub->scrub_probe($script_text)
  $scrubbed_text = Text::Scrub->scrub_test_file($script_text)

=head1 DESCRIPTION

The methods in the C<Test::STD:Scrub> package are designed to support the
L<C<Test::STDmaker>|Test::STDmaker> and 
the L<C<ExtUtils::SVDmaker>|ExtUtils::SVDmaker> package.
This is the focus and no other focus.
Since C<Test::STD::Scrub> is a separate package, the methods
may be used elsewhere.
They are used to wild card out parts of two documents before
they are compared by making these snippets the same.
In all likehood, any revisions will maintain backwards compatibility
with previous revisions.
However, support and the performance of the 
L<C<Test::STDmaker>|Test::STDmaker> and 
L<C<ExtUtils::SVDmaker>|ExtUtils::SVDmaker> packages has
priority over backwards compatibility.

=head2 scrub_architect

 $scrubbed_text = Test::STD::Scrub->scrub_architect($script_text)

When comparing the contents of two Perl program modules, 
the architect should not be used 
in the comparision. 
The C<scrub_architect> method will replace
the architect with a generic value.
Applying the C<scrub_architect> to the contents
of both files before the comparision will 
eliminate the date and version as factors in
the comparision.

=head2 scrub_date_ticket

 $scrubbed_text = Test::STD::Scrub->scrub_date_ticket($script_text)

When comparing the contents of email messages, 
the date and email ticket should not be used 
in the comparision. 
The C<scrub_date_ticket> method will replace
the date and email ticket with a generic value.
Applying the C<scrub_date_ticket> to the contents
of both files before the comparision will 
eliminate the data and ticket as factors in
the comparision.

=head2 scrub_date_version

 $scrubbed_text = Test::STD::Scrub->scrub_date_version($script_text)

When comparing the contents of two Perl program modules, 
the date and version should not be used 
in the comparision. 
The I<scrub_date_versiont> method will replace
the date and version with a generic value.
Applying the C<scrub_date_version> to the contents
of both files before the comparision will 
eliminate the date and version as factors in
the comparision.

=head2 scrub_file_line

 $scrubbed_text = Test::STD::Scrub->scrub_file_line($script_text)

When comparing the ouput of I<Test> module
the file and line number should not be used 
in the comparision. 
The C<scrub_file_line> method will replace
the file and line with a generic value.
The subroutine changes any double quotes around
numbers to single quotes.
Applying the C<scrub_file_line> to the contents
of both files before the comparision will 
eliminate the file and line as factors in
the comparision.

=head2 scrub_test_file

 $scrubbed_text = Test::STD::Scrub->scrub_test_file($script_text)

When comparing the ouput of I<Test:Harness> module
the test file should not be used 
in the comparision. 
The C<scrub_test_file> method will replace
the test file with a generic value.
Applying the C<scrub_test_file> to the contents
of both files before the comparision will 
eliminate the test file as a factor in
the comparision.

=head1 REQUIREMENTS

Someday.

=head1 DEMONSTRATION

 #########
 # perl Scrub.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Spec;

     use File::Package;
     my $fp = 'File::Package';

     my $uut = 'Text::Scrub';

     my $loaded = '';
     my $template = '';
     my %variables = ();
     my $expected = '';

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut)
 $errors

 # ''
 #

 ##################
 #  scrub_file_line
 # 

 my $text = 'ok 2 # (E:/User/SoftwareDiamonds/installation/t/Test/STDmaker/tgA1.t at line 123 TODO?!)'
 $uut->scrub_file_line($text)

 # 'ok 2 # (xxxx.t at line 000 TODO?!)'
 #

 ##################
 #  scrub_test_file
 # 

 $text = 'Running Tests\n\nE:/User/SoftwareDiamonds/installation/t/Test/STDmaker/tgA1.1..16 todo 2 5;'
 $uut->scrub_test_file($text)

 # 'Running Tests xxx.t 1..16 todo 2 5;'
 #

 ##################
 #  scrub_date_version
 # 

 $text = '$VERSION = \'0.01\';\n$DATE = \'2003/06/07\';'
 $uut->scrub_date_version($text)

 # '$VERSION = '0.00';\n$DATE = 'Feb 6, 1969';'
 #

 ##################
 #  scrub_date_ticket
 # 

 $text = <<'EOF';
 Date: Apr 12 00 00 00 2003 +0000
 Subject: 20030506, This Week in Health'
 X-SDticket: 20030205
 X-eudora-date: Feb 6 2000 00 00 2003 +0000
 X-SDmailit: dead Feb 5 2000 00 00 2003
 Sent email 20030205-20030506 to support.softwarediamonds.com
 EOF

 my $expected_text = <<'EOF';
 Date: Feb 6 00 00 00 1969 +0000
 Subject: XXXXXXXXX-X,  This Week in Health'
 X-SDticket: XXXXXXXXX-X
 X-eudora-date: Feb 6 00 00 00 1969 +0000
 X-SDmailit: dead Sat Feb 6 00 00 00 1969 +0000
 Sent email XXXXXXXXX-X to support.softwarediamonds.com
 EOF

 # end of EOF
 $uut->scrub_date_ticket($text)

 # 'Date: Feb 6 00 00 00 1969 +0000
 #Subject: XXXXXXXXX-X,  This Week in Health'
 #X-SDticket: XXXXXXXXX-X
 #X-eudora-date: Feb 6 00 00 00 1969 +0000
 #X-SDmailit: dead Sat Feb 6 00 00 00 1969 +0000
 #Sent email XXXXXXXXX-X to support.softwarediamonds.com
 #'
 #

 ##################
 #  scrub_date
 # 

 $text = 'Going to happy valley 2003/06/07'
 $uut->scrub_date($text)

 # 'Going to happy valley 1969/02/06'
 #

 ##################
 #  scrub_probe
 # 

 $text = <<'EOF';
 1..8 todo 2 5;
 # OS            : MSWin32
 # Perl          : 5.6.1
 # Local Time    : Thu Jun 19 23:49:54 2003
 # GMT Time      : Fri Jun 20 03:49:54 2003 GMT
 # Number Storage: string
 # Test::Tech    : 1.06
 # Test          : 1.15
 # Data::Dumper  : 2.102
 # =cut 
 # Pass test
 ok 1
 EOF

 $expected_text = <<'EOF';
 1..8 todo 2 5;
 # Pass test
 ok 1
 EOF

 # end of EOF
 $uut->scrub_probe($text)

 # '1..8 todo 2 5;
 ## Pass test
 #ok 1
 #'
 #

 ##################
 #  scrub_architect
 # 

 $text = 'ARCHITECTURE NAME="MSWin32-x86-multi-thread-5.5"'
 $uut->scrub_architect($text)

 # 'ARCHITECTURE NAME="Perl"'
 #
 unlink 'actual.txt'

=head1 QUALITY ASSURANCE

Running the test script C<Scrub.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Scrub.t> test script, C<Scrub.d> demo script,
and C<t::Text::Scrub> program module POD,
from the C<t::Text::Scrub> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Scrub.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::Text::Scrub> program module
is in the distribution file
F<Text-Scrub-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements

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

=item L<Docs::Site_SVD::Text_Srube|Docs::Site_SVD::Text_Scrub>

=item L<Test::STDmaker|Test::STDmaker>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

=item L

=back

=cut

### end of file ###