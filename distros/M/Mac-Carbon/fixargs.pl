use Config;
use vars qw($bits_are_64 $usrlocal $defarch $noarch);

$bits_are_64 = unpack("L!", pack("LL", 0x12345678, 0x9ABCDEF)) >= 2**32;
$usrlocal = scalar(grep m|^/\w+/local/|, @INC);
$defarch = $Config{byteorder} eq 4321
	? 'ppc'
	: $Config{byteorder} eq 12345678
		? 'x86_64'
		: $Config{byteorder} eq 1234
			? 'i386'
			: 'ppc';  # what else can we do?
$noarch  = $Config{ccflags} !~ /\barch\b/;

sub fixargs {
	my $ARGS = shift;
	for (qw(LDDLFLAGS LDFLAGS CCFLAGS)) {
		$ARGS->{$_} =~ s/\s?-arch x86_64\s?/ /g;
#		$ARGS->{$_} =~ s/\s?-arch ppc(?:\d+)?\s?/ /g;
		$ARGS->{$_} =~ s|-[LI]/\w+/local/\S+| |g unless $usrlocal > 1;
		if ($noarch) {
			$ARGS->{$_} .= " -arch $defarch";
		}
	}
}

1;
