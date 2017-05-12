use Config;
use Cwd;
use ExtUtils::MakeMaker;
use File::Basename;
use File::Spec::Functions qw(:DEFAULT splitdir);
use Pod::Select;
require '../fixargs.pl' if -e '../fixargs.pl';

use strict;
use vars qw($BASEDIR $MOD $XS $PM $POD $NAME $C %ARGS);

sub domakefile {
	# extra cleanup stuff
	if ($^O eq 'MacOS' && $] < 5.8) {  # old makemaker syntax?
		$ARGS{'TYPEMAPS'}	= join ' ', @{$ARGS{'TYPEMAPS'}};
	}
	WriteMakefile(%ARGS);

	undef $C;
	undef $MOD;
	undef $XS;
	undef $PM;
	undef $POD;
	undef $NAME;
	undef %ARGS;
}

$BASEDIR ||= updir();

$MOD  ||= (splitdir(cwd()))[-1];
$XS   ||= "$MOD.xs";
($C ||= $XS) =~ s/\.xs$/.c/;
$PM   ||= "$MOD.pm";
$POD  ||= "$MOD.pod";
$NAME ||= "Mac::$MOD";

%ARGS = (
	'NAME'                  => $NAME,
	'VERSION_FROM'          => $PM,
	'LINKTYPE'              => 'static dynamic',
	'XSPROTOARG'            => '-noprototypes',      # XXX remove later?
	'NO_META'               => 1,
);

if ($^O eq 'darwin') {
	$ARGS{'INC'}            = '-I/Developer/Headers/FlatCarbon/';
	$ARGS{'depend'}{$C}     = catfile($BASEDIR, 'Carbon.h');

	$ARGS{'LDFLAGS'}        = $Config{ldflags};
	$ARGS{'CCFLAGS'}        = $Config{ccflags} . ' -fpascal-strings';
#	$ARGS{'LDDLFLAGS'}      = '-dynamiclib -prebind -flat_namespace -undefined suppress -framework Carbon';
#	$ARGS{'DLEXT'}          = 'dylib';

	$ARGS{'LDDLFLAGS'}      = $Config{lddlflags};
	$ARGS{'LDDLFLAGS'}      =~ s/-undefined\s+\w+//;
	$ARGS{'LDDLFLAGS'}      =~ s/-bundle\b//;
	$ARGS{'LDDLFLAGS'}      .= ' -bundle -flat_namespace -undefined suppress -framework Carbon';

	fixargs(\%ARGS);
}

# let's make a new .pod with the right POD from .pm and .xs
if ($^O ne 'MacOS' && -e $XS) {
	podselect({-output => $POD}, $XS);
	my $xs = do { local $/; open my $fh, $POD or die $!; <$fh> };
	if ($xs) {
		podselect({-output => $POD}, $PM);
		my $pm = do { local $/; open my $fh, $POD or die $!; <$fh> };
		$pm =~ s/=include $XS/$xs/;
		open my $fh, "> $POD" or die $!;
		print $fh $pm;
		$ARGS{'MAN3PODS'} = { $POD =>
			File::Spec->catfile("\$(INST_MAN3DIR)", "$NAME.\$(MAN3EXT)")
		};
		$ARGS{'clean'} = { FILES => $POD };
	} else {
		unlink $POD;
	}
}

if ($^O ne 'MacOS') {
	package MY;

	# don't execute tests from the sub-dirs themselves
	sub test { "test ::\n\t\@\$(NOOP)" };

	# use the right xsubpp for this perl
	sub tool_xsubpp {
		my($self) = shift;
		my $return = $self->SUPER::tool_xsubpp;

		my $xsdir  = File::Spec->catdir($::BASEDIR, 'xsubpps');
		my $xsubpp = $] >= 5.008 ? 'xsubpp-5.8.0' : 'xsubpp-5.6.1';

		$return =~ s/^(XSUBPPDIR\s*=\s*).+$/$1$xsdir/m;
		# $return =~ s/^(XSUBPP\s*=\s*).+$/$1\$(XSUBPPDIR)\$(DFSEP)$xsubpp/m;
		# DFSEP not defined in older MakeMakers, and we know this is right anyway
		$return =~ s/^(XSUBPP\s*=\s*).+$/$1\$(XSUBPPDIR)\/$xsubpp/m;

		# just in case, for some older ExtUtils::MakeMakers ...
		my(@tmdeps) = File::Spec->catdir(
			$self->{PERL_LIB}, 'ExtUtils', 'typemap'
		);
		$return =~ s|\$\(XSUBPPDIR\)/typemap|@tmdeps|g;

		return $return;
	};
}
