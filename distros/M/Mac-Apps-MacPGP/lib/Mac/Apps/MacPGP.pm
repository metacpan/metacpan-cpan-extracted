#!perl -w
package Mac::Apps::MacPGP;
require 5.004;
use vars qw($VERSION $be @ISA @EXPORT);
use strict;
use Exporter;
use Carp;
use Mac::AppleEvents;
use Mac::Apps::Launch;
@ISA = qw(Exporter);
@EXPORT = ();
$VERSION = sprintf("%d.%02d", q$Revision: 1.20 $ =~ /(\d+)\.(\d+)/);
$be = '';
#=================================================================
# Stuff
#=================================================================
sub new {
	my $self = shift;
	&_MpgpLaunchApp;
	return bless{}, $self;
}
#-----------------------------------------------------------------
sub DESTROY {
	my $self = shift;
	&_MpgpFrontApp($self->{MpgpMainApp}) if ($self->{MpgpSwitchApps} && $self->{MpgpSwitchApps} == 1 && $self->{MpgpMainApp});
}
#-----------------------------------------------------------------
sub getresults {
	my($self,$res) = @_;
	$res = 'result' if (!$res);
	return $self->{results}->{$res};
}
#-----------------------------------------------------------------
sub getresultsall {
	my($self) = shift;
	my($results) = $self->{results};
	return %{$results};
}
#-----------------------------------------------------------------
sub switchapp {
	my($self,$do,$app) = @_;
	if (defined $do) {
		$self->{MpgpSwitchApps} = $do;
	}
	if ($app) {
		$self->{MpgpMainApp} = $app;
	}
	&_MpgpFrontApp('MPGP') if ($self->{MpgpSwitchApps} == 1);
	return 1;
}
#-----------------------------------------------------------------
sub quitpgp {
	my($be) = AEBuildAppleEvent('aevt','quit',typeApplSignature,'MPGP',0,0,'') || croak $^E;
	AESend($be, kAEWaitReply) || croak $^E;
	AEDisposeDesc $be;
	return 1;
}
#=================================================================
# Main subroutines
#=================================================================
sub encrypt {
	my(@p)	= @_;
	my($ev)	= &_checkType($p[1],'encr','ncrd','cncr');
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if (scalar(@{$p[2]})) 
						{&_dObjData($p[2],'a')	}
	elsif ($p[2])
						{&_dObjData($p[2],'t')	}
	else				{&_MpgpError('m','dObj') unless ($ev eq 'ncrd')}
	if ($ev ne 'cncr') {
		if (scalar(@{$p[3]})) 
						{&_recvData($p[3],'a')	}
		elsif ($p[3])
						{&_recvData($p[3],'t')	} else {&_MpgpError('m','recv')}}
	if ($p[3] && $ev eq 'cncr')
						{&_cpasData($p[3])		}
	if ($p[4])			{&_passData($p[4])		}
	if ($p[5])			{&_usidData($p[5])		}
	if ($p[6])			{&_signData($p[6],'e')	}
	if ($p[7])			{&_readData($p[7])		}
	if ($p[8])			{&_outpData($p[8])		} else {&_outpData('asci')}
	if (defined $p[9])	{&_latiData($p[9])		}
	if (defined $p[10])	{&_wrapData($p[10])		}
	if (defined $p[11])	{&_alnsData($p[11])		}
	if (defined $p[12] && (AEGetParamDesc($be,'wrap') !=0))
						{&_tabxData($p[12])		}
	if ($p[13])			{&_mdalData($p[13])		}
	if ($p[14] && $ev ne 'ncrd')
						{&_wsrcData($p[14])		}
	if ($p[15] && $ev eq 'cncr')
						{&_coptData($p[15])		}
	&_MpgpError('s','') 
		if ((AEGetParamDesc($be,'sign') eq 'incl') && 
			(AEGetParamDesc($be,'copt') =~ /sdf/));
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub decrypt {
	my(@p)	= @_;
	my($ev)	= &_checkType($p[1],'decr','dcrd');
	$be		= &_MpgpAeBuild($ev);
	if (scalar(@{$p[2]}))
						{&_dObjData($p[2],'a')	}
	elsif ($p[2])
						{&_dObjData($p[2],'t')	}
	else				{&_MpgpError('m','dObj') unless ($ev eq 'dcrd')}
	if ($p[3])			{&_passData($p[3])		}
	if (defined $p[4])	{&_screData($p[4])		}
	if (defined $p[5])	{&_nsigData($p[5])		}
	if ($p[6])			{&_apl2Data($p[6])		}
	if ($p[7] && $ev eq 'decr')
						{&_recvData($p[7],'t')	}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub sign {
	my(@p)	= @_;
	my($ev)	= &_checkType($p[1],'sign','sigd');
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if (scalar(@{$p[2]})) 
						{&_dObjData($p[2],'a')	}
	elsif ($p[2])
						{&_dObjData($p[2],'t')	}
	else				{&_MpgpError('m','dObj') unless ($ev eq 'sigd')}
	if ($p[3])			{&_passData($p[3])		}
	if ($p[4])			{&_usidData($p[4])		}
	if ($p[5])			{&_signData($p[5],'s')	}
	if ($p[6])			{&_readData($p[6])		}
	if ($p[7])			{&_outpData($p[7])		} else {&_outpData('asci')}
	if (defined $p[8])	{&_latiData($p[8])		}
	if (defined $p[9])	{&_wrapData($p[9])		}
	if (defined $p[10])	{&_alnsData($p[10])		}
	if (defined $p[11] && (AEGetParamDesc($be,'wrap') !=0))
						{&_tabxData($p[11],$ae)	}
	if ($p[12])			{&_mdalData($p[12])		}
	if ($p[13])			{&_stfxData($p[13])		}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub asciify {
	my(@p)	= @_;
	my($ev) = 'asci';
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if (scalar(@{$p[1]})) 
						{&_dObjData($p[1],'a')	}
	elsif ($p[1])
						{&_dObjData($p[1],'t')	} else {&_MpgpError('m','dObj')}
	if ($p[2])			{&_readData($p[2])		}
	if (defined $p[3])	{&_latiData($p[3])		}
	if (defined $p[4])	{&_wrapData($p[4])		}
	if (defined $p[5])	{&_alnsData($p[5])		}
	if (defined $p[6] && (AEGetParamDesc($be,'wrap') !=0))
						{&_tabxData($p[6],$ae)	}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub execute {
	my(@p)	= @_;
	my($ev) = 'exec';
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if ($p[1])			{&_dObjData($p[1],'t')	} else {&_MpgpError('m','dObj')}
	if ($p[2])			{&_passData($p[2])		}
	if (defined $p[3])	{&_latiData($p[3])		}
	if (defined $p[4])	{&_wrapData($p[4])		}
	if (defined $p[5])	{&_alnsData($p[5])		}
	if (defined $p[6] && (AEGetParamDesc($be,'wrap') !=0))
						{&_tabxData($p[6],$ae)	}
	if ($p[7])			{&_mdalData($p[7])		}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub keyring {
	my(@p)	= @_;
	my($ev)	= &_checkType($p[1],'selk','ckey','crfy','remv','addk','fing');
	$be		= &_MpgpAeBuild($ev);
	if ($p[2])			{&_dObjData($p[2],'t')	} else {&_MpgpError('m','dObj')}
	if ($p[3])			{&_keyrData($p[3])		}
	if ($p[4] && $ev eq 'crfy')
						{&_usidData($p[4])		}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub extract {
	my(@p)	= @_;
	my($ev) = 'extr';
	$be		= &_MpgpAeBuild($ev);
	if ($p[1])			{&_dObjData($p[1],'t')	} else {&_MpgpError('m','dObj')}
	if ($p[2])			{&_recvData($p[2],'t')	} else {&_MpgpError('m','recv')}
	if ($p[3])			{&_keyrData($p[3])		}
	if ($p[4])			{&_outpData($p[4])		} else {&_outpData('asci')}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub generate {
	my(@p)	= @_;
	my($ev) = 'gene';
	$be		= &_MpgpAeBuild($ev);
	if ($p[1])			{&_dObjData($p[1],'t')	} else {&_MpgpError('m','dObj')}
	if ($p[2])			{&_lengData($p[2])		}
	if ($p[3])			{&_ebitData($p[3])		}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub logfile {
	my(@p)	= @_;
	my($ev) = 'logf';
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if ($p[1])			{&_dObjData($p[1],'b')	} else {&_MpgpError('m','dObj')}
	if ($p[2])			{&_recvData($p[2],'t')	}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub window {
	my(@p)	= @_;
	my($ev) = 'wind';
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if ($p[1])			{&_windData($p[1])		} else {&_MpgpError('m','dObj')}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub create {
	my(@p)	= @_;
	my($ev) = 'crea';
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if ($p[1])			{&_dObjData($p[1],'t') } else {&_MpgpError('m','dObj')}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub clip2file {
	my(@p)	= @_;
	my($ev) = 'sc2f';
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if ($p[1])			{&_dObjData($p[1],'t') } else {&_MpgpError('m','dObj')}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub file2clip {
	my(@p)	= @_;
	my($ev) = 'f2sc';
	$be		= &_MpgpAeBuild($ev);
	my($ae);
	if ($p[1])			{&_dObjData($p[1],'t') } else {&_MpgpError('m','dObj')}
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub checksignresult {
	my(@p)	= @_;
	my($ev) = 'cksg';
	$be		= &_MpgpAeBuild($ev);
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub getlasterror {
	my(@p)	= @_;
	my($ev) = 'gler';
	$be		= &_MpgpAeBuild($ev);
	return &_MpgpAeProcess($p[0]);
}
#-----------------------------------------------------------------
sub getversion {
	my(@p)	= @_;
	my($ev) = 'gver';
	$be		= &_MpgpAeBuild($ev);
	return &_MpgpAeProcess($p[0]);
}
#=================================================================
# Check AE param ids
#=================================================================
sub _checkType {
	my($ev,@evs)  = @_;
	return $ev if (&_oneOf('evType',$ev,\@evs));
}
#=================================================================
# Process data into AE descriptors
#=================================================================
sub _dObjData {
	my($data,$type) = @_;
	if ($type eq 't') {
		&_MpgpBText($data,'----');
	} elsif ($type eq 'a') {
		&_MpgpBTextArray($data,'----');
	} elsif ($type eq 'b') {
		&_MpgpBBool($data,'----');
	}
}
#-----------------------------------------------------------------
sub _recvData {
	my($data,$type) = @_;
	if ($type eq 'a') {
		&_MpgpBTextArray($data,'recv');
	} elsif ($type eq 't') {
		&_MpgpBText($data,'recv');
	}
}
#-----------------------------------------------------------------
sub _passData {
	my($data) = @_;
	&_MpgpBText($data,'pass');
}
#-----------------------------------------------------------------
sub _cpasData {
	my($data) = @_;
	&_MpgpBText($data,'cpas');
}
#-----------------------------------------------------------------
sub _usidData {
	my($data) = @_;
	&_MpgpBText($data,'usid');
}
#-----------------------------------------------------------------
sub _apl2Data {
	my($data) = @_;
	&_MpgpBText($data,'apl2');
}
#-----------------------------------------------------------------
sub _keyrData {
	my($data) = @_;
	&_MpgpBText($data,'keyr');
}
#-----------------------------------------------------------------
sub _signData {
	my($data,$type) = @_;
	my(@datas);
	if ($type eq 'e') {
		@datas = qw(incl sepa omit);
	} elsif ($type eq 's') {
		@datas = qw(incl sepa clea);
	}
	&_MpgpBKeyw($data,'sign') if (&_oneOf('sign',$data,\@datas));
}
#-----------------------------------------------------------------
sub _readData {
	my($data) = @_;
	my(@datas) = qw(macb text norm);
	&_MpgpBKeyw($data,'read') if (&_oneOf('read',$data,\@datas));
}
#-----------------------------------------------------------------
sub _outpData {
	my($data) = @_;
	my(@datas) = qw(bina asci);
	&_MpgpBKeyw($data,'outp') if (&_oneOf('outp',$data,\@datas));
}
#-----------------------------------------------------------------
sub _windData {
	my($data) = @_;
	my(@datas) = qw(show hide);
	&_MpgpBKeyw($data,'----') if (&_oneOf('wind',$data,\@datas));
}
#-----------------------------------------------------------------
sub _coptData {
	my($data) = @_;
	my(@datas) = qw(sdf sdfb);
	&_MpgpBKeyw($data,'copt') if (&_oneOf('copt',$data,\@datas));
}
#-----------------------------------------------------------------
sub _mdalData {
	my($data) = @_;
	my(@datas) = qw(MD5 SHA1);
	&_MpgpBKeyw($data,'mdal') if (&_oneOf('mdal',$data,\@datas));
}
#-----------------------------------------------------------------
sub _wsrcData {
	my($data) = @_;
	&_MpgpBBool($data,'wsrc');
}
#-----------------------------------------------------------------
sub _latiData {
	my($data) = @_;
	&_MpgpBBool($data,'lati');
}
#-----------------------------------------------------------------
sub _screData {
	my($data) = @_;
	&_MpgpBBool($data,'scre');
}
#-----------------------------------------------------------------
sub _nsigData {
	my($data) = @_;
	&_MpgpBBool($data,'nsig');
}
#-----------------------------------------------------------------
sub _stfxData {
	my($data) = @_;
	&_MpgpBBool($data,'stfx');
}
#-----------------------------------------------------------------
sub _wrapData {
	my($data) = @_;
	my(@datas) = qw(30 100);
	&_MpgpBShort($data,'wrap') if (&_twixtOf('wrap',$data,\@datas));
}
#-----------------------------------------------------------------
sub _alnsData {
	my($data) = @_;
	my(@datas) = qw(0 1E+1000);
	&_MpgpBShort($data,'alns') if (&_twixtOf('alns',$data,\@datas));
}
#-----------------------------------------------------------------
sub _tabxData {
	my($data) = @_;
	my(@datas) = qw(0 9);
	&_MpgpBShort($data,'tabx') if (&_twixtOf('tabx',$data,\@datas));
}
#-----------------------------------------------------------------
sub _ebitData {
	my($data) = @_;
	my(@datas) = qw(0 1E+1000);
	&_MpgpBShort($data,'ebit') if (&_twixtOf('ebit',$data,\@datas));
}
#-----------------------------------------------------------------
sub _lengData {
	my($data) = @_;
	my(@datas);
	if ($data !~ /\D/) {
		@datas = qw(384 2048);
		&_MpgpBShort($data,'kbit') if (&_twixtOf('kbit',$data,\@datas));
	} else {
		@datas = qw(casu comm mili);
		&_MpgpBKeyw($data,'leng') if (&_oneOf('leng',$data,\@datas));
	}
}
#=================================================================
# Error checking of data
#=================================================================
sub _twixtOf {
	my($type,$one,$of) = @_;
	&_MpgpError('d',$type) unless 
		(($one !~ /\D/ && $one >= $$of[0] && $one <= $$of[1]) || ($one == 0));
	return 1;
}
#-----------------------------------------------------------------
sub _oneOf {
	my($type,$one,$of,$yes) = @_;
	foreach (@{$of}) {
		$yes = 1 if ($one eq $_);
	}
	if (!$yes) {
		&_MpgpError('t',$type);
	}
	return 1;
}
#=================================================================
# Add AE descriptor records to event
#=================================================================
sub _MpgpBKeyw {
	my($data,$type) = @_;
	AEPutParamDesc($be,$type,(AEBuild($data)));
}
#-----------------------------------------------------------------
sub _MpgpBShort {
	my($data,$type) = @_;
	AEPutParamDesc($be,$type,(AEBuild($data)));
}
#-----------------------------------------------------------------
sub _MpgpBBool {
	my($data,$type) = @_;
	if ($data eq '1') {
		$data = 'true';
	} elsif ($data eq '0') {
		$data = 'fals';
	} else {
		&_MpgpError('b',$type);
	}
	AEPutParamDesc($be,$type,(AEBuild($data)));
}
#-----------------------------------------------------------------
sub _MpgpBText {
	my($data,$type) = @_;
	AEPutParamDesc($be,$type,(AEBuild('TEXT(@)',$data)));
}
#-----------------------------------------------------------------
sub _MpgpBTextArray {
	my($data,$type) = @_;
	my($ta) = '[';
	foreach (@{$data}) {
		$ta .= 'TEXT(@),';
	}
	$ta =~ s/,$/]/;
	AEPutParamDesc($be,$type,(AEBuild($ta,@{$data})));
}
#=================================================================
# Main processing
#=================================================================
sub _MpgpLaunchApp {
	my($app) = shift || 'MPGP';
	LaunchApps([$app],0);
}
#-----------------------------------------------------------------
sub _MpgpFrontApp {
	my($app) = @_;
	LaunchApps([$app],1);
}
#-----------------------------------------------------------------
sub _MpgpError {
	my($type,$info) = @_;
	if ($type eq 'm') {
		croak "Missing required element of type: $info.\n";
	} elsif ($type eq 'd') {
		croak "Value of $info does not fall within acceptable bounds.\n";
	} elsif ($type eq 't') {
		croak "Value of $info does not match acceptable parameters.\n";
	} elsif ($type eq 'b') {
		croak "Value of $info must be either 1 or 0 (boolean).\n";
	} elsif ($type eq 's') {
		croak "Cannot include signature in self-decrypting files.\n";
	} else {
		croak "Unknown error ($type, $info).\n";
	}
}
#-----------------------------------------------------------------
sub _MpgpAeBuild {
	my($ev,$st) = @_;
	$st = 'MPGP' if (!$st);
	my($be) = AEBuildAppleEvent($st,$ev,typeApplSignature,'MPGP',0,0,'') || croak $^E;
	return $be;
}
#-----------------------------------------------------------------
sub _MpgpAePrint {
	my($self,$rp) = @_;
	my(@ar,%ar,$ar,$at);
	@ar = ('----','errn','errs','outp');
	foreach $ar(@ar) {
		if ($at = AEGetParamDesc($rp,$ar)) {
			$ar{$ar} = AEPrint($at);
		}
	}
	if (exists $ar{'----'}) {
		$ar{'----'} =~ s/^Ò(.*)Ó$/$1/s;
		$ar{'result'} = $ar{'----'};
	}
	if ($ar{'errn'}) {
		$ar{'errs'} =~ s/^Ò(.*)Ó$/$1/ if (exists $ar{'errs'});
		carp "MacPGP error $ar{'errn'}: $ar{'errs'}\n";
	}
	if (exists $ar{'outp'}) {
		$ar{'outp'} =~ s/^\[alis\(\Ç(.*?)\È\)\]/$1/;
#		$ar{'outp'} = (pack("H*",$ar{'outp'}));
	}
	$self->{results} = \%ar;
	AEDisposeDesc $rp;
	return $ar{result};
}
#-----------------------------------------------------------------
sub _MpgpAeProcess {
	my($self) = shift;
	my($rp) = AESend($be, kAEWaitReply) || croak $^E;
	AEDisposeDesc $be;
	return &_MpgpAePrint($self,$rp);
}
#-----------------------------------------------------------------#
1;
__END__

=head1 NAME

Mac::Apps::MacPGP - Interface to MacPGP 2.6.3

=head1 SYNOPSIS

	use Mac::Apps::MacPGP;
	$object = new Mac::Apps::MacPGP;
	#see description for the rest

=head1 DESCRIPTION

MacPerl interface to MacPGP 2.6.3.  Older versions WILL NOT WORK.  The MIT version, MacPGP 2.6.2, does not support nearly the number of AppleEvents as does 2.6.3.  For those outside the U.S., you will not be able to download the program; but there are International versions.  Perhaps in the future I will add support for those.  Many of the functions should work fine for those, actually, but I imagine some will not.

MacPerl 5.1.1 (released January 1997) or higher is also required because of bugs in the AppleEvents library in previous versions.

Also required is the Mac::Apps::Launch module, however, which requires MacPerl 5.1.4r4 or higher.  :)

For optional parameters, MacPGP will either use the default or prompt the user.  Parameters are required unless noted as optional.  Exception: For the C<$OUTP> parameter, the MacPGP default is binary but I set it to ASCII in the module, because I rarely use binary PGP files.

Boolean parameters take a value of 1 (true) or 0 (false).  Filenames should be given the full pathname.  To leave an optional parameter empty, give it a value of C<undef>.  Optional parameters will either be given the default by MacPGP or MacPGP will prompt the user for a value if necessary.  

For further explanation of methods and parameters, see your MacPGP 2.6.3 user guide.  

If something seems seems to not work properly, try doing it directly from MacPGP before assuming it is the fault of MacPGP.pm.  :-)

=head1 USAGE

=head2 encrypt

Encrypt.  Returns encrypted text for C<$TYPE="ncrd">.

$object->encrypt(TYPE, DOBJ, [RECV|CPAS], PASS, USID, SIGN, READ, OUTP, LATI, WRAP, ALNS, TABX, MDAL, WSRC, COPT);

=item TYPE

One of "encr" (encrypt files), "ncrd" (encrypt data), or "cncr" (conventional encryption).

=item DOBJ

For C<$TYPE="encr"> or C<"cncr">, C<$DOBJ> is either a filename or a reference to an array of filenames.  For C<$TYPE="ncrd">, C<$DOBJ> is the data to be encrypted.  If C<$DOBJ> is empty, MacPGP will attempt to encrypt the clipboard instead.

=item RECV

Either the name of a recipient or a reference to an array of recipients.  (encr and ncrd only)

=item CPAS

Password used for conventional encryption.  Optional.  (cncr only)

=item PASS

The password.  Optional.

=item USID

Name of secret key.  Optional.

=item SIGN

Sign?  One of "sepa" (signature in separate file), "incl", (signature included), "omit" (omitted, don't sign).  Optional.

=item READ

Input format.  One of "macb" (MacBinarize first), "text", (convert text to CRLF), "norm" (do nothing).  Optional.

=item OUTP

Output format.  One of "bina" (8-bit binary), "asci", (ASCII-armored).  Optional.

=item LATI

Convert text to ISO-Latin1?  Boolean.  Optional.

=item WRAP

Wrap text to this many lines, between 30 and 100.  0=no wrap.  Optional.

=item ALNS

For armored files, split output into files of this line length.  0=no split.  Optional.

=item TABX

For wrapped files, expand tabs to this many spaces, from 0 to 9.  Optional.

=item MDAL

Use "MD5 " or "SHA1" to compute message digest for file.  Optional.

=item WSRC

Wipe out source file?  Boolean.  Optional.  (encr and cncr only)

=item COPT

Self-decrypting?  One of "sdf" (self-decrypting) or "sdfb", (self-decrypting and binhexed).  Default is neither.  Optional. (cncr only)

=head2 decrypt

Decrypt.  Returns decrypted text for C<$TYPE="dcrd"> and C<$DOBJ ne undef>.  Returns signatures for C<$TYPE="decr">.

$object->decrypt(TYPE, DOBJ, PASS, SCRE, NSIG, APL2, RECV);

=item TYPE

One of "decr" (decrypt files), "dcrd" (decrypt data).

=item DOBJ

For C<$TYPE="decr">, C<$DOBJ> is either a filename or a reference to an array of filenames.  For C<$TYPE="dcrd">, C<$DOBJ> is the data to be decrypted.  If C<$DOBJ> is empty, MacPGP will attempt to decrypt the clipboard instead.  To get signatures from "dcrd" event, see L<"checksignresult">.

=item PASS

The password.  Optional.

=item SCRE

Decrypt to screen instead of file?  Boolean.  Optional.

=item NSIG

Do not put up bad signature alerts?  Boolean.  Optional.

=item APL2

If direct object is a separate sig file, the file the sig applies to.  Optional.

=item RECV

File to decrypt to.  Optional. (decr only)

=head2 sign

Sign.  Returns encrypted signed text for C<$TYPE="sigd">, returns signature results for C<$TYPE="sign">.

$object->sign(TYPE, DOBJ, PASS, USID, SIGN, READ, OUTP, LATI, WRAP, ALNS, TABX, MDAL, STFX);

=item TYPE

One of "sign" (sign files), "sigd" (sign data).

=item DOBJ

For C<$TYPE="sign">, C<$DOBJ> is either a filename or a reference to an array of filenames.  For C<$TYPE="sigd">, C<$DOBJ> is the data to be signed.  If C<$DOBJ> is empty, MacPGP will attempt to sign the clipboard instead.

=item PASS

The password.  Optional.

=item USID

Name of secret key.  Optional.

=item SIGN

Sign?  One of "sepa" (signature in separate file), "incl", (signature included), "omit" (omitted, don't sign).  Optional.

=item READ

See READ in L<"encrypt">.  Optional.

=item OUTP

See OUTP in L<"encrypt">.  Optional.

=item LATI

See LATI in L<"encrypt">.  Optional.

=item WRAP

See WRAP in L<"encrypt">.  Optional.

=item ALNS

See ALNS in L<"encrypt">.  Optional.

=item TABX

See TABX in L<"encrypt">.  Optional.

=item MDAL

See MDAL in L<"encrypt">.  Optional.

=item STFX

Set text flag? (Esoteric option for some PGP/MIME implementations.)  Boolean.  Optional.

=head2 asciify

Asciify a file.

$object->asciify(DOBJ, READ, LATI, WRAP, ALNS, TABX);

=item DOBJ

Filename or reference to an array of filenames to be asciified.

=item READ

See READ in L<"encrypt">.  Optional.

=item LATI

See LATI in L<"encrypt">.  Optional.

=item WRAP

See WRAP in L<"encrypt">.  Optional.

=item ALNS

See ALNS in L<"encrypt">.  Optional.

=item TABX

See TABX in L<"encrypt">.  Optional.

=head2 execute

Execute MacPGP command-line command.

$object->execute(DOBJ, PASS, LATI, WRAP, ALNS, TABX, MDAL);

=item DOBJ

Command to be executed (i.e., C<pgp -kv pudge>).

=item PASS

The password.  Optional.

=item LATI

See LATI in L<"encrypt">.  Optional.

=item WRAP

See WRAP in L<"encrypt">.  Optional.

=item ALNS

See ALNS in L<"encrypt">.  Optional.

=item TABX

See TABX in L<"encrypt">.  Optional.

=item MDAL

See MDAL in L<"encrypt">.  Optional.

=head2 generate

Generate new public/secret key pair.

$object->generate(DOBJ, LENG, EBIT);

=item DOBJ

User id of new key.

=item LENG

Bit length of key.  Higher is stronger and slower.  Lower is faster and less secure.  Can be either a number from 384 to 2048, or one of the following: "casu" (casual, 512), "comm" (commercial, 768), "mili" (military, 1024).  Default is casual.  Optional.

=item EBIT

Number of bits in encryption exponent.  Default is 17.  Optional.

=head2 extract

Extract (export) a key.

$object->extract(DOBJ, RECV, KEYR, OUTP);

=item DOBJ

Key id to extract.

=item RECV

File to extract key to.  File must already exist (for now).  See L<"create">.

=item KEYR

Filename of keyring to perform operation on.  Optional.

=item OUTP

Output format.  One of "bina" (8-bit binary), "asci", (ASCII-armored).  Optional.

=head2 keyring

Miscellaneous keyring functions.

$object->keyring(TYPE, DOBJ, KEYR, USID);

=item TYPE

=over 4

=item addk

Add key in file C<$DOBJ>.

=item ckey

Count keys matching C<$DOBJ>.

=item crfy

Certify key matching C<$DOBJ>.

=item fing

Return fingerprint of key matching C<$DOBJ>.

=item remv

Remove key matching C<$DOBJ>.

=item selk

Show dialog box, with text C<$DOBJ>, of keys available in keyring.  Returns user id of selected key.

=back

=item DOBJ

Varies; see above.

=item KEYR

Filename of keyring to perform operation on.  Optional.

=item USID

Name of secret key to certify with.  Optional. (crfy only)

=head2 create

Create temporary scratch file.  File with same name, if existing, is erased.

$object->create(DOBJ);

=item DOBJ

New filename.

=head2 clip2file

Copy Clipboard to file.

$object->clip2file(DOBJ);

=item DOBJ

Filename of destination file.

=head2 file2clip

Copy file to Clipboard.  NOTE:  This only works if MacPGP is the front application (see L<"switchapp">).

$object->file2clip(DOBJ);

=item DOBJ

Filename of source file.

=head2 checksignresult

Check signature result from previous decrypt data event.  See L<"decrypt">.

$object->checksignresult;

=head2 getlasterror

Returns error message from previous MacPGP Apple Event.

$object->getlasterror;

=head2 getversion

Returns MacPGP version.

$object->getversion;

=head2 window

Show/hide window.

$object->window(DOBJ);

=item DOBJ

Either "show" or "hide".

=head2 logfile

Echo PGP messages to a logfile.  If logging was active when true sent or no filename is given, returns error. If logging was active.  Returns full pathname if successful.

$object->logfile(DOBJ, RECV);

=item DOBJ

Logging?  Boolean.

=item RECV

Full pathname of logfile.  Existing file of same name erased.  Optional.

=head2 switchapp

Set up window handling.  Whenever another method is called, MacPGP.pm will use these two variables to determine what app should be in front.  Note:  when muliple methods are called, this doesn't seem to work great.  Oh well.  Maybe someone else will fix this for me or have some ideas.  Until then, I suggest that if you DO want MacPGP to come to the front and you have sveral methods being called one after the other, that you just set C<$object->switchapp(1)> and don't have it switch back.

$object->switchapp(SWITCH, APP);

=item SWITCH

Switch to MacPGP when method is called?  Boolean.

=item APP

Switch to C<$APP> after C<$object> is destroyed (i.e., when last reference to C<$object> is made).  If left blank and C<$SWITCH=1>, MacPGP will go to front and stay there.

=head2 getresults

Returns result of parameter C<$DOBJ> from last method call.

$object->getresults(DOBJ);

=item DOBJ

Name of parameter keyword, one of "----", "result" (synonym for "----", the direct object parameter), "errs" (error string), "errn" (error number), "outp".  Optional, defaults to "result".

=head2 getresultsall

Returns hash of all result parameters from last method call.

%results = $object->getresultsall;

=head2 quitpgp

Quit MacPGP app.

$object->quitpgp;

=head1 HISTORY

=item v.1.2, January 3, 1998

Basic cleanup.  Requires MacPerl 5.1.4r4 or better now.

=item v.1.1, October 13, 1997

Get app launching from Mac::Apps::Launch, fixed descriptor disposing.

=item v.1.0, February 9, 1997

First full release.

=over 4

=item *

Added a whole slew of scripts and extensions for BBEdit, YA-NewsWatcher, Clipboard, Drag-n-Drop.  See MacPGP-scripts.readme for details.

=item *

Changed the behavior of C<switchapp> method.  Switching to MacPGP only occurs when C<switchapp> method is invoked, and switching back only occurs when object is destroyed.  Previously, switching took place before and after each method call.

=item *

Fixed bug which required C<decrypt>, C<encrypt> and C<sign> to have a DOBJ value.  When one of those methods is performing a function on data (dcrd, ncrd, sigd), MacPGP will use Clipboard if no data is given.

=item *

Fixed bug in C<_MpgpBBool> routine which would not catch unacceptable input.

=back

=item v.1.0b3, January 15, 1997

Simply switching to .tar.gz for CPAN instead of .sit.hqx.

=item v.1.0b2 January 8, 1997

Fixes problems in earlier release, optimizes, module-izes.

=over 4

=item *

Change name from MacPGP to Mac::Apps::MacPGP.

=item *

Rewrote AppleEvent calls using individual C<AEPutParamDesc> and C<AEBuild> calls.  Should be more efficient.  Fixes other bugs (like problems with lists and certain characters in TEXT values).

=item *

Improved error handling and descriptions.  Uses C<carp> for MacPGP errors.

=item *

Made file and recipients variables capable of handling either a scalar or a reference to an array.

=item *

Added C<switchapp>, C<getresults>, C<getresultsall>, C<quitpgp> methods.  See docs above.

=back

=item v.1.0b1, January 3, 1997

First public beta.  Nearly fully-functional.

=head1 BUGS

=item app switching

I want to benchmark different ways to switch between applications and use the best one.  Stay tuned.  If you have ideas, let me know.

=item other versions

I am investigating the idea of making this useful with other versions of MacPGP (international versions, and limited capabilities of MacPGP 2.6.2) and the future version of PGP 5.0.

=item stealthify

I have one more method group to add, and that is for stealtifying/destealthifying files.  This will come along eventually, but it is not a high priority.  First I have to figure out how to use it and what it does ... :-)  If you have a need/want for it, let me know.

=head1 SEE ALSO

=item MacPGP 2.6.3 Home Page

http://www.math.ohio-state.edu/~fiedorow/PGP/

=item MacPGP 2.6.3 Documentation

Included with the above package, take special note of the PGP User's Guide, MacPGP263_Manual, and MacPGP263_AppleEvents.

=head1 AUTHOR

Chris Nandor F<E<lt>pudge@pobox.comE<gt>>
http://pudge.net/

Copyright (c) 1998 Chris Nandor.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.  Please see the Perl Artistic License.

=head1 VERSION

Version 1.20 (03 January 1998)

=cut
