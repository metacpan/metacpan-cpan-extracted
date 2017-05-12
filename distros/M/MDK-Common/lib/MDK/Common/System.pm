package MDK::Common::System;

=head1 NAME

MDK::Common::System - system-related useful functions

=head1 SYNOPSIS

    use MDK::Common::System qw(:all);

=head1 EXPORTS

=over

=item %compat_arch

architecture compatibility mapping (eg: k6 => i586, k7 => k6 ...)

=item %printable_chars

7 bit ascii characters

=item $sizeof_int

sizeof(int)

=item $bitof_int

$sizeof_int * 8

=item arch()

return the architecture (eg: i686, ppc, ia64, k7...)

=item typeFromMagic(FILENAME, LIST)

find the first corresponding magic in FILENAME. eg of LIST:

    [ 'empty', 0, "\0\0\0\0" ],
    [ 'grub', 0, "\xEBG", 0x17d, "stage1 \0" ],
    [ 'lilo', 0x2,  "LILO" ],
    sub { my ($F) = @_;
	  #- standard grub has no good magic (Mageia's grub is patched to have "GRUB" at offset 6)
	  #- so scanning a range of possible places where grub can have its string
	  my ($min, $max, $magic) = (0x176, 0x181, "GRUB \0");
	  my $tmp;
	  sysseek($F, 0, 0) && sysread($F, $tmp, $max + length($magic)) or return;
	  substr($tmp, 0, 2) eq "\xEBH" or return;
	  index($tmp, $magic, $min) >= 0 && "grub";
      },

where each entry is [ magic_name, offset, string, offset, string, ... ].

=item list_passwd()

return the list of users as given by C<getpwent> (see perlfunc)

=item list_home()

return the list of home (eg: /home/foo, /home/pixel, ...)

=item list_skels()

return the directories where we can find dot files: homes, /root and /etc/skel

=item list_users()

return the list of unprivilegied users (aka those whose uid is greater
than 500 and who are not "nobody").

=item syscall_(NAME, PARA)

calls the syscall NAME

=item psizeof(STRING)

useful to know the length of a C<pack> format string. 

    psizeof("I I I C C S") = 4 + 4 + 4 + 1 + 1 + 2 = 16

=item availableMemory()

size of swap + memory

=item availableRamMB()

size of RAM as reported by the BIOS (it is a round number that can be
displayed or given as "mem=128M" to the kernel)

=item gettimeofday()

returns the epoch in microseconds

=item unix2dos(STRING)

takes care of CR/LF translation

=item whereis_binary(STRING)

return the first absolute file in $PATH (similar to which(1) and whereis(1))

=item getVarsFromSh(FILENAME)

returns a hash associating shell variables to their value. useful for config
files such as /etc/sysconfig files

=item setVarsInSh(FILENAME, HASH REF)

write file in shell format association a shell variable + value for each
key/value

=item setVarsInSh(FILENAME, HASH REF, LIST)

restrict the fields that will be printed to LIST

=item setVarsInShMode(FILENAME, INT, HASH REF, LIST)

like setVarsInSh with INT being the chmod value for the config file

=item addVarsInSh(FILENAME, HASH REF)

like setVarsInSh but keeping the entries in the file

=item addVarsInSh(FILENAME, HASH REF, LIST)

like setVarsInSh but keeping the entries in the file

=item addVarsInShMode(FILENAME, INT, HASH REF, LIST)

like addVarsInShMode but keeping the entries in the file

=item setExportedVarsInCsh(FILENAME, HASH REF, LIST)

same as C<setExportedVarsInSh> for csh format

=item template2file(FILENAME_IN, FILENAME_OUT, HASH)

read in a template file, replace keys @@@key@@@ with value, save it in out
file

=item template2userfile(PREFIX, FILENAME_IN, FILENAME_OUT, BOOL, HASH)

read in a template file, replace keys @@@key@@@ with value, save it in every homes.
If BOOL is true, overwrite existing files. FILENAME_OUT must be a relative filename

=item read_gnomekderc(FILENAME, STRING)

reads GNOME-like and KDE-like config files (aka windows-like).
You must give a category. eg:

    read_gnomekderc("/etc/skels/.kderc", 'KDE')

=item update_gnomekderc(FILENAME, STRING, HASH)

modifies GNOME-like and KDE-like config files (aka windows-like).
If the category doesn't exist, it creates it. eg:

    update_gnomekderc("/etc/skels/.kderc", 'KDE', 
		      kfmIconStyle => "Large")

=item fuzzy_pidofs(REGEXP)

return the list of process ids matching the regexp

=back

=head1 OTHER

=over

=item better_arch(ARCH1, ARCH2)

is ARCH1 compatible with ARCH2?

better_arch('i386', 'ia64') and better_arch('ia64', 'i386') are false

better_arch('k7', 'k6') is true and better_arch('k6', 'k7') is false

=item compat_arch(STRING)

test the architecture compatibility. eg: 

compat_arch('i386') is false on a ia64

compat_arch('k6') is true on a k6 and k7 but false on a i386 and i686

=back

=head1 SEE ALSO

L<MDK::Common>

=cut


use MDK::Common::Math;
use MDK::Common::File;
use MDK::Common::DataStructure;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%compat_arch $printable_chars $sizeof_int $bitof_int arch distrib typeFromMagic list_passwd list_home list_skels list_users syscall_ psizeof availableMemory availableRamMB gettimeofday unix2dos whereis_binary getVarsFromSh setVarsInSh setVarsInShMode addVarsInSh addVarsInShMode setExportedVarsInSh setExportedVarsInCsh template2file template2userfile read_gnomekderc update_gnomekderc fuzzy_pidofs); #);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);


our %compat_arch = ( #- compatibilty arch mapping.
		     'noarch'  => undef,
		     'ia32'    => 'noarch',
		     'i386'    => 'ia32',
		     'i486'    => 'i386',
		     'i586'    => 'i486',
		     'i686'    => 'i586',
		     'i786'    => 'i686',
		     'k6'      => 'i586',
		     'k7'      => 'k6',
		     'k8'      => 'k7',
		     'x86_64'  => 'i686',
		     'amd64'   => 'x86_64',
		     'ia64'    => 'noarch',
		     'ppc'     => 'noarch',
		     'alpha'   => 'noarch',
		     'sparc'   => 'noarch',
		     'sparc32' => 'sparc',
		     'sparc64' => 'sparc32',
		     'ia64'    => 'noarch',
		   );

our $printable_chars = "\x20-\x7E";
our $sizeof_int      = psizeof("i");
our $bitof_int       = $sizeof_int * 8;


sub arch() {
    my $SYS_NMLN = 65;
    my $format = "Z$SYS_NMLN" x 6;
    my $t = pack $format;
    syscall_('uname', $t);
    (unpack($format, $t))[4];
}
sub better_arch {
    my ($new, $old) = @_;
    while ($new && $new ne $old) { $new = $compat_arch{$new} }
    $new;
}
sub compat_arch { better_arch(arch(), $_[0]) }

sub distrib() {
    my $release = MDK::Common::File::cat_('/etc/release');
    my ($real_system, $real_product) = $release =~ /(.*) release ([\d.]+)/;
    my $oem_config = '/etc/sysconfig/oem';
    my %oem = -f $oem_config && getVarsFromSh($oem_config);
    #- (blino) FIXME: merge with release functions from /usr/lib/libDrakX/common.pm (including product.id parsing)
    my ($default_company) = split(' ', $real_system);
    my $company = $oem{COMPANY} || $default_company || 'Unknown vendor';
    my $system = $oem{SYSTEM} || $real_system;
    my $product = $oem{PRODUCT} || $real_product;
    (company => $company, system => $system, product => $product, real_system => $real_system, real_product => $real_product);
}

sub typeFromMagic {
    my $f = shift;
    sysopen(my $F, $f, 0) or return;

    my $tmp;
  M: foreach (@_) {
	if (ref($_) eq 'CODE') {
	    my $name = $_->($F) or next M;
	    return $name;
	} else {
	    my ($name, @l) = @$_;
	    while (@l) {
		my ($offset, $signature) = splice(@l, 0, 2);
		sysseek($F, $offset, 0) or next M;
		sysread($F, $tmp, length $signature);
		$tmp eq $signature or next M;
	    }
	    return $name;
	}
    }
    undef;
}


sub list_passwd() {
    my (@l, @e);
    setpwent();
    while (@e = getpwent()) { push @l, [ @e ] }
    endpwent();
    @l;
}
sub list_home() {
    MDK::Common::DataStructure::uniq(map { $_->[7] } grep { $_->[2] >= 500 } list_passwd());
}
sub list_skels { 
    my ($prefix, $suffix) = @_;
    grep { -d $_ && -w $_ } map { "$prefix$_/$suffix" } '/etc/skel', '/root', list_home();
}

sub list_users() {
    MDK::Common::DataStructure::uniq(map { 500 <= $_->[2] && $_->[0] ne "nobody" ? $_->[0] : () } list_passwd());
}



sub syscall_ {
    my $f = shift;

    #- load syscall.ph in package "main". If every use of syscall.ph do the same, all will be nice
    package main;
    require 'syscall.ph';

    syscall(&{"main::SYS_$f"}, @_) == 0;
}


#- return the size of the partition and its free space in KiB
sub df {
    my ($mntpoint) = @_;
    require Filesys::Df;
    my $df = Filesys::Df::df($mntpoint, 1024); # ask 1kb values
    @$df{qw(blocks bfree)};
}

sub sync() { syscall_('sync') }
sub psizeof { length pack $_[0] }
sub availableMemory() { MDK::Common::Math::sum(map { /(\d+)/ } grep { /^(MemTotal|SwapTotal):/ } MDK::Common::File::cat_("/proc/meminfo")) }
sub availableRamMB() { 4 * MDK::Common::Math::round((-s '/proc/kcore') / 1024 / 1024 / 4) }
sub gettimeofday() { my $t = pack "LL"; syscall_('gettimeofday', $t, 0) or die "gettimeofday failed: $!\n"; unpack("LL", $t) }
sub unix2dos { local $_ = $_[0]; s/\015$//mg; s/$/\015/mg; $_ }

sub expandLinkInChroot {
    my ($file, $prefix) = @_;
    my $l = readlink "$prefix$file";
    return unless $l;
    return $l if $l =~ m!^/!;
    my $path = $file;
    $path =~ s!/[^/]*$!!;
    $path .= "/$l";
    return $path;
}

sub whereis_binary {
    my ($prog, $o_prefix) = @_;
    if ($prog =~ m!/!) {
	warn qq(don't call whereis_binary with a name containing a "/" (the culprit is: $prog)\n);
	return;
    }
    foreach (split(':', $ENV{PATH})) {
	my $f = "$_/$prog";
	my $links = 0;
	my $l = $f;
	while (-l "$o_prefix$l") {
	    $l = expandLinkInChroot($l, $o_prefix);
	    if ($links++ > 16) {
		warn qq(symlink recursion too deep in whereis_binary\n);
		return;
	    }
	}
	-x "$o_prefix$l" and return $f; 
    }
}

sub getVarsFromSh {
    my %l;
    open(my $F, $_[0]) or return;
    local $_;
    while (<$F>) {
	s/^\s*#.*//; # remove comment-only lines
	s/^\s*//; # leading space
	my ($v, $val) = /^(\w+)=(.*)/ or next;
	if ($val =~ /^"(.*)"(\s+#.*)?$/) {
	    $val = $1;
	} elsif ($val =~ /^'(.*)'(\s+#.*)?$/) {
	    $val = $1;
	    $val =~ s/(^|[^'])'\\''/$1'/g;
	}
	$l{$v} = $val;
    }
    %l;
}

sub addVarsInSh {
    my ($file, $l, @fields) = @_;
    addVarsInShMode($file, 0777 ^ umask(), $l, @fields);
}

sub addVarsInShMode {
    my ($file, $mod, $l, @fields) = @_;
    my %l = @fields ? map { $_ => $l->{$_} } @fields : %$l;
    my %l2 = getVarsFromSh($file);

    # below is add2hash_(\%l, \%l2);
    exists $l{$_} or $l{$_} = $l2{$_} foreach keys %l2; 

    setVarsInShMode($file, $mod, \%l);
}

sub setVarsInSh {
    my ($file, $l, @fields) = @_;
    setVarsInShMode($file, 0777 ^ umask(), $l, @fields);
}

sub quoteForSh {
    my ($val) = @_;
    if ($val =~ /["`\$]/) {
	$val =~ s/(')/$1\\$1$1/g;
	$val = qq('$val');
    } elsif ($val =~ /[\(\)'|\s\\;<>&#\[\]~{}*?]/) {
	$val = qq("$val");
    }
    $val;
}

sub setVarsInShMode {
    my ($file, $mod, $l, @fields) = @_;
    @fields = keys %$l unless @fields;
    my $string = join('',
	map { "$_=" . quoteForSh($l->{$_}) . "\n" } grep { $l->{$_} } @fields
    );
    if ($file =~ m!^/home/!) {
        MDK::Common::File::secured_output($file, $string);
    } else {
        MDK::Common::File::output($file, $string);
    }

    chmod $mod, $file;
}

sub setExportedVarsInSh {
    my ($file, $l, @fields) = @_;
    @fields = keys %$l unless @fields;

    MDK::Common::File::output($file, 
	(map { $l->{$_} ? "$_=" . quoteForSh($l->{$_}) . "\n" : () } @fields), 
	@fields ? "export " . join(" ", @fields) . "\n" : (),
    );
}

sub setExportedVarsInCsh {
    my ($file, $l, @fields) = @_;
    @fields = keys %$l unless @fields;

    MDK::Common::File::output($file, map { $l->{$_} ? "setenv $_ " . quoteForSh($l->{$_}) . "\n" : () } @fields);
}

sub template2file {
    my ($in, $out, %toreplace) = @_;
    MDK::Common::File::output($out, map { s/@@@(.*?)@@@/$toreplace{$1}/g; $_ } MDK::Common::File::cat_($in));
}
sub template2userfile {
    my ($prefix, $in, $out_rel, $force, %toreplace) = @_;

    foreach (list_skels($prefix, $out_rel)) {
	-d MDK::Common::File::dirname($_) or !-e $_ or $force or next;

	template2file($in, $_, %toreplace);
	m|/home/(.+?)/| and chown(getpwnam($1), getgrnam($1), $_);
    }
}

sub read_gnomekderc {
    my ($file, $category) = @_;
    my %h;
    foreach (MDK::Common::File::cat_($file), "[NOCATEGORY]\n") {
	if (/^\s*\[\Q$category\E\]/i ... /^\[/) {
	    $h{$1} = $2 if /^\s*([^=]*?)=(.*)/;
	}
    }
    %h;
}

sub update_gnomekderc {
    my ($file, $category, %subst_) = @_;

    my %subst = map { lc($_) => [ $_, $subst_{$_} ] } keys %subst_;

    my $s;
    defined($category) or $category = "DEFAULTCATEGORY";
    foreach ("[DEFAULTCATEGORY]\n", MDK::Common::File::cat_($file), "[NOCATEGORY]\n") {
	if (my $i = /^\s*\[\Q$category\E\]/i ... /^\[/) {
	    if ($i =~ /E/) { #- for last line of category
		chomp $s; $s .= "\n";
		$s .= "$_->[0]=$_->[1]\n" foreach values %subst;
		%subst = ();
	    } elsif (/^\s*([^=]*?)=/) {
		if (my $e = delete $subst{lc($1)}) {
		    $_ = "$1=$e->[1]\n";
		}
	      }
	}
	$s .= $_ if !/^\[(NO|DEFAULT)CATEGORY\]/;
    }

    #- if category has not been found above (DEFAULTCATEGORY is always found).
    if (keys %subst) {
	chomp $s;
	$s .= "\n[$category]\n";
	$s .= "$_->[0]=$_->[1]\n" foreach values %subst;
    }

    MDK::Common::File::output_p($file, $s);

}

sub fuzzy_pidofs {
    my ($regexp) = @_;
    grep { 
	if (/^(\d+)$/) {
	    my $s = MDK::Common::File::cat_("/proc/$_/cmdline") ||
	            readlink("/proc/$_/exe") || 
		    MDK::Common::File::cat_("/proc/$_/stat") =~ /\s(\S+)/ && $1 ||
		    '';
	    $s =~ /$regexp/;
	} else {
	    0;
	}
    } MDK::Common::File::all('/proc');
}

1;
