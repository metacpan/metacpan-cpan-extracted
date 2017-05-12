package Log::Fu::Chomp;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT = qw(fu_chomp);

use Log::Fu::Common qw(%Config);

my $HKEY_MORE_CHAR 	= 'StripMoreIndicator';
my $HKEY_STRIP		= 'Strip';
my $HKEY_MAX_COMPONENTS = 'StripMaxComponents';
my $HKEY_STRIP_WIDTH = 'StripCallerWidth';
my $HKEY_STRIP_KEEP = 'StripKeepChars';
my $HKEY_STRIP_TLNS = 'StripTopLevelNamespace';
my $HKEY_STRIP_SUB	= 'StripSubBasename';


#Filler 'more' char
$Config{$HKEY_MORE_CHAR}    = '~';

#Boolean, whether to strip
$Config{$HKEY_STRIP}        = 0;

#How many intermediate components to keep (max)
$Config{$HKEY_MAX_COMPONENTS} = 2;

#How small can caller info be to ignore stripping
$Config{$HKEY_STRIP_WIDTH}  = 10;

#How many characters to keep for each shortened component
$Config{$HKEY_STRIP_KEEP}   = 2;

#Whether to strip the top-level namespace
$Config{$HKEY_STRIP_TLNS}   = 0;

#Maximum length for function basname
$Config{$HKEY_STRIP_SUB}    = 8;

my %Handlers = ();
my %HandlerCache = ();

sub AddHandler {
	my ($match,$code) = @_;
	$Handlers{$match} = $code;
	%HandlerCache = ();
}

sub DelHandler {
	my ($match) = @_;
	if(delete $Handlers{$match}) {
		%HandlerCache = ();
	}
}

sub fu_chomp {
	my $sub = $_[0];
	
	GT_FETCH_CACHE:
	if(%Handlers) {
		my $code = $HandlerCache{$sub};
		if(defined $code && ref $code ne 'CODE') {
			goto GT_WE_PROCESS;
		} elsif (defined $code) {
			goto &$code;
		} else {
			my $module = $sub;
			$module =~ s/::[^:]+$//g;
			foreach my $key (reverse sort { length($a) <=> length($b) }
							  keys %Handlers) {
				if(index($module, $key) >= 0) {
					$HandlerCache{$sub} = $Handlers{$key};
					goto GT_FETCH_CACHE;
				}
			}
			$HandlerCache{$sub} = 0;
		}
	}
	
	GT_WE_PROCESS:
	return $sub unless $Config{$HKEY_STRIP};
	return $sub if $Log::Fu::NO_STRIP;
	
	my $maxwidth;
	
	if( ($maxwidth = $Config{$HKEY_STRIP_WIDTH}) ){
		return $sub if length($sub) < $maxwidth;
	}
	
	my @orig_components = split(/::/, $sub);
	my @components;
	my $sub_basename = pop @orig_components;
	
	my $tlns = shift @orig_components;
	$tlns .= "::" if $tlns;
	
	#Strip top-level component
	my $tlns_len = $Config{$HKEY_STRIP_TLNS} + length($Config{$HKEY_MORE_CHAR});
	if($Config{$HKEY_STRIP_TLNS} &&
	   $tlns_len-1 && length($tlns) > $tlns_len) {
		$tlns = substr($tlns, 0, $Config{$HKEY_STRIP_TLNS});
		$tlns .= $Config{$HKEY_MORE_CHAR};
	}
	push @components, $tlns;
	
	if($Config{$HKEY_MAX_COMPONENTS}) {
		while(scalar @orig_components > $Config{$HKEY_MAX_COMPONENTS}) {
			shift @orig_components;
		}
	}
	
	#Strip intermediary components
	my $new_len_min = $Config{$HKEY_STRIP_KEEP} + length($Config{$HKEY_MORE_CHAR});
	while ( (my $comp = shift @orig_components) ) {
		if(length($comp) <= $new_len_min) {
		} else {
			$comp = substr($comp, 0, $Config{$HKEY_STRIP_KEEP});
			$comp .= $Config{$HKEY_MORE_CHAR};
		}
		push @components, $comp;
	}
	
	#Strip the basename of the sub
	my $sub_len_min = $Config{$HKEY_STRIP_SUB} + length($Config{$HKEY_MORE_CHAR});
	if($Config{$HKEY_STRIP_SUB} && length($sub_basename) > $sub_len_min) {
		my $offset = length($sub_basename) - $Config{$HKEY_STRIP_SUB};
		$sub_basename = $Config{$HKEY_MORE_CHAR} . substr($sub_basename, $offset);
		#Make sure we have an offset. We wi
	}
	
	push @components, $sub_basename;
	return join("", @components);
}


1;
