#!perl
#
#

use strict;
use warnings;
use warnings::register;
use 5.001;

use Getopt::Long;
use ExtUtils::SVDmaker;
use Pod::Usage;

use vars qw($VERSION $DATE);
$VERSION = '1.04';
$DATE = '2004/05/11';

use vars qw($man $help);
$man = '0';
$help = '0';

my %options;
use vars qw($man $help);
unless ( GetOptions( 

            'help|?' => \$help,
            'man' => \$man,
            
            #######
            # SVDmaker options  
            #
            'verbose!' => \$options{verbose},
            'pm=s' => \$options{pm},

           ) ) {
   pod2usage(1);
}

#####
# Help section. Note the pod2usage(2) has big problems
# with the spaces in WIN32 file names. Thus, simply
# supply the perdoc system command directly that
# pod2usage supplies. Actually faster and cleaner.
#
pod2usage(1) if ( $help );
if($man) {
   system "perldoc \"$0\"";
   exit 1;
}

#####
# General release files and documents in accordance with the
# Software Version Description files.
#
my $svd = new ExtUtils::SVDmaker(\%options);
$svd->vmake(@ARGV);

__END__



=head1 NAME

vmake - Make a release for CPAN from a Software Version Description (SVD) program module

=head1 SYNOPSIS

vmake [-help] [-man] [-verbose] [pm=I<spec>] 
   target .. target

=head1 DESCRIPTION


The vmake script is a simple cover script for 
L<SVD::SVDmaker|SVD::SVDmaker> that in that
the command line inputs and executes the
below:

  use ExtUtils::SVDmaker;

  my $svd = new SVD::SVDmaker(\%options);
  $svd->vmake(@targets);

See L<SVD::SVDmaker|SVD::SVDmaker> man page
for further details.

=head1 OPTIONS

=over 4

=item -help  

This option tells C<sdbuild> to output this 
Plain Old Documentation (POD) SYNOPSIS and OPTIONS 
instead of its normal processing.

=item -man

This option tells C<sdbuild> to output all of this 
Plain Old Documentation (POD) 
instead of its normal processing.

=item -pm

A list of Software Version Description (SVD) program modules

See 
L<ExtUtils::SVDmaker|sExtUtils::SVDmaker> and
L<ExtUtils::SVDmaker Option|ExtUtils::SVDmaker/Options>

=item -verbose

Tells L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> to print
on STDOUT informative messages about what 
L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> is processing.

See 
L<ExtUtils::SVDmaker|sExtUtils::SVDmaker> and
L<ExtUtils::SVDmaker Option|ExtUtils::SVDmaker/Options>

=back

=head1 NOTES

=head2 Author

The author, holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

copyright © 2003 SoftwareDiamonds.com

=head2 License

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

=head1 SEE ALSO

L<Software Version Description (SVD) DID|US_DOD::SVD>
L<DOD 490A - Specification Practices|US_DOD::STD490A>
L<DOD 2167A - Software Development Standard|US_DOD::STD2167A>

=for html
<hr>
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
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

### end of file ###
