#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.07';
$DATE = '2003/07/05';

use File::Spec;
use File::Path;
use Cwd;
use Test;
use Pod::Checker;

use vars qw(@uut);

BEGIN {

    ####
    # Units Under Test
    #
    @uut = qw( 
        CDRL
        COM
        CPM
        CRISD
        CSCI
        CSOM
        DBDD
        ECP
        FSM
        HWCI
        IDD
        IRS
        OCD
        SCN
        SDD
        SDP
        SDR
        SIOM
        SIP
        SPM
        SPS
        SRR
        SRS
        SSDD
        SSS
        STD
        STD2167A
        STD490A
        STP
        STR
        STrP
        SUM
        SVD
        VDD
    );

    plan(tests => (3 * @uut));
   
}


my $restore_dir = cwd( );
my ($vol, $dir, $file) = File::Spec->splitpath( $0 );

chdir $vol if $vol;
chdir $dir if $dir;

#######
# Add the library under test to @INC
#
my $work_dir = cwd();
for( my $i=0; $i<3; $i++) {
    chdir File::Spec->updir();
}
my $lib_dir = File::Spec->catdir( cwd(), 'lib' );
my @restore_inc = @INC;
unshift @INC, $lib_dir;
chdir $work_dir;


######
# Test the program modules
#
#
use File::Package;
my $fp = 'File::Package';

my ($loaded, $error, $uut);
my $log = 'STD2167A.log';
foreach $uut (@uut) {

    print "# $uut not loaded\n";
    ok ($loaded = $fp->is_package_loaded("Docs::US_DOD::$uut"), ''); 

    print "# load $uut\n";
    my $error = $fp->load_package( "Docs::US_DOD::$uut" );
    skip($loaded, $error, '');

    open( STDERR, "> $log" );

    ## Now create a pod checker
    print "# $uut pod check\n";
    my $checker = new Pod::Checker();
  
    $error = '';
    # Now check the pod document for errors
    $checker->parse_from_file(File::Spec->catfile( $lib_dir,'Docs','US_DOD',"$uut.pm"), \*STDERR);
    close STDERR;

    open LOG, "< $log";
    $error = join '',<LOG>;
    close LOG;
    unlink $log;
 
    ok( $checker->num_errors(), 0, $error );

}

@INC = @restore_inc;
chdir $restore_dir;
unlink ($log);

__END__

=head1 NAME

Test for US_DOD book drawing PODs.

=head1 NOTES

=head2 Copyright

This Perl Plain Old Documentation (POD) version is
copyright © 2001 2003 Software Diamonds.

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
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.=head2 Copyright Holder Contact

E<lt>support@SoftwareDiamonds.comE<gt>

=for html
<p><br>
<!-- BLK ID="PROJECT_MANAGEMENT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="HEALTH" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>


=cut

## end of file ##
