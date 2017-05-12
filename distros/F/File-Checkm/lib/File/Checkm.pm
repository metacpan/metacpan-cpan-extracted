package File::Checkm;

use 5.006;
use strict;
use warnings;

our $VERSION;
$VERSION = sprintf "%s", q$Name: Release-v0.3.3$ =~ /Release-(v\d+\.\d+\.\d+)/;

my $checkm_version = "0.7";		# version number of checkm spec

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
);

our @EXPORT_OK = qw(
	checkm_trees make_digester list_digesters
);

our @EXPORT_FAIL = qw(
);
push @EXPORT_OK, @EXPORT_FAIL;		# add pseudo-symbols we will trap

sub export_fail { my( $class, @symbols )=@_;

	my @unknowns;
	for (@symbols) {
		! s/^pair=([1-9])$/$1/ and
			push(@unknowns, $_),
			next;
		#pair_means($_);	# define how many octets form a pair
	}
	return @unknowns;
}

our $manfilename = "manifest.txt";

use Carp;
use File::Find;
#use File::Path;

# Globals set by checkm_trees
my $o_fname;			# whether to include file/URL name
my $o_aname;			# whether to include algorithm name
my $o_alg;			# lowercase algorithm name
my $o_digest;			# whether to include digest
my $o_size;			# whether to include size
my $o_mtime;			# whether to include mtime
my $o_fieldscount;		# how many fields we're to do
my $o_digester;
my $o_verbose;
my $o_temper;
my $o_mani_digester;
my $o_mani_octets = 0;		# count of octets since last checkm_point

my $S = '|';			# separator

my $objectcount = 0;		# number of objects encountered
my $octetcount = 0;		# number of octets encountered xxx
my $filecount = 0;		# number of files encountered xxx
my $dircount = 0;		# number of directories encountered xxx
my $symlinkcount = 0;		# number of symlinks encountered xxx
my $irregcount = 0;		# non file, non dir fs items to report xxx

my $gr_opt;	# global version of r_opt to communicate with find

# "Digest print" for digest lines, which optionally (if first arg is 1
# and the verbose option is set) prints to stderr and adds lines to
# digester so that the manifest itself gets a digest. Always appends "\n".
#
sub dprint {

	my $errtoo = shift @_;
	my $output = join("", @_) . "\n";
	my $ret = print $output;
	$errtoo	&& $o_verbose	and $ret &&= print STDERR $output;
	$o_mani_digester	and $o_mani_digester->add($output);
	$o_mani_octets += length($output);	# track number of octets
	# xxx or should this be length(Encoding::encode_utf8($output))?
	return $ret;
}

sub checkm_point {

	my $manioctets = $o_mani_octets;	# save what we'll report
	$o_mani_digester or		# we're not computing a digest
		return dprint 0, "#%checkm_point$S$S",
			"$S$manioctets$S", checkm_time();

	my $manidigest = $o_mani_digester->hexdigest;	# resets digester
	$o_mani_octets = 0;	# save and reset so dprint starts at zero

	# XXXXX what if alg for this is different from that for addfile?
	return dprint 0, "#%checkm_point$S$o_alg$S$manidigest",
		"$S$manioctets$S", checkm_time();
}

sub checkm_trees { my( $r_trees, $r_opt, $r_visit_node, $r_wrapup )=@_;
				# xxx $r_visit_node? $r_wrapup?

	# XXXX shouldn't croak from module?  what is error return?
	# Check that we can trust our arguments.
	#
	ref($r_trees) eq "ARRAY" or
		croak "r_trees must reference an array";
	ref($r_opt) eq "HASH" or
		croak "r_opt must reference a hash (for input/output)";
	ref( $r_visit_node ||= \&checkm_visit_node ) eq "CODE" or
		croak "r_visit_node must reference a node-visiting function";
	#ref( $r_wrapup ||= \&checkm_lstree_wrapup ) eq "CODE" or
	#	croak "r_wrapup must reference a node-visiting function";

	# xxx needed?
	$gr_opt = $r_opt;	# make options available to find

	# Preset some globals as a small optimization to reduce
	# reference time for each file.
	#
	$o_aname = $r_opt->{aname};
	$o_fname = $r_opt->{fname};
	$o_alg = $r_opt->{alg};
	$o_digest = $r_opt->{digest};
	$o_size = $r_opt->{size};
	$o_mtime = $r_opt->{mtime};
	$o_fieldscount = $r_opt->{fieldscount};
	$o_digester = $r_opt->{digester};
	$o_mani_digester = $r_opt->{mani_digester};
	$o_verbose = $r_opt->{verbose};
	$o_temper = $r_opt->{temper};

	my %find_opt = (
		'wanted'	=>  $r_visit_node,
		'follow_fast'	=>  (! $r_opt->{preventlinks}),
	);

	#$o{follow_fast} = 1		# xxx set with $opt?
	#	unless defined $o{follow_fast};
	# Set follow_fast=1 to mean follow symlinks without rigorous
	# checking (faster); it also means that (-X _) works from
	# within &visit without doing an extra stat call, where -X
	# is any file test operator and _ is the magic file handle.

	#dprint 0, "Id      Oxum\n";		# XXXXXX this is our r_startup
	dprint 0, "#%checkm_$checkm_version";
	# XXX shouldn't these filenames be checkm_encoded?
	dprint 0, "#%checkm_over$S", join(" ", @$r_trees);

	my $ret = 0;
	for my $tree (@$r_trees) {
		if (! -e $tree) {
			# xxx ? $exit_status = 1;
			# xxx $om->elem('error', "$tree: no such file or directory");
			next;
		}

		# If follow_fast is set and the top of the tree is not an
		# actual directory name, then it appears that File::Find
		# reports absolute pathnames, which breaks the pattern
		# we're trying to create; we handle this specially by
		# calling checkm_visit_node by hand.
		#
		if (! -d $tree and $find_opt{follow_fast}) {
			#$pdname = $File::Find::dir;
			$File::Find::dir = '.';	# current parent directory name
			#$tpname = $_;		# current filename in that dir
			$_ = $tree;		# current filename in that dir
			#$wpname = $File::Find::name;	# whole pathname to file
			$File::Find::name = $tree;	# unused? xxx
			lstat($tree);		# set up magic '_' tests
			checkm_visit_node();
			next;
		}

	#xxx print "tree=$tree, follow_fast=", $find_opt{follow_fast}, "\n";
		$ret = find(\%find_opt, $tree);
		$ret or		# if success
			next;

		# xxx what does find return?
		dprint 1, "%error$S", "find returned '$ret' for $tree"	if $ret;
		# xxx $om->elem('error', "$tree: $o{msg}");	# XXX?
	}

	#$gr_opt->{om}->elem('filecount', "$filecount file" .
	#	($filecount == 1 ? "" : "s"));
	dprint 0, "#%checkm_stats$S",
		"oxum+dinks=$octetcount.$filecount+",
		"$dircount.$symlinkcount.$irregcount";
	$o_verbose and dprint 0, "#%checkm_statstics$S",
		"$octetcount octet", ($octetcount == 1 ? "" : "s"), 
		", $filecount file", ($filecount == 1 ? "" : "s"),
		", $dircount director", ($dircount == 1 ? "y" : "ies"),
		", $symlinkcount link", ($symlinkcount == 1 ? "" : "s"),
		", $irregcount special file", ($irregcount == 1 ? "" : "s");
	#$gr_opt->{om}->elem('filecount', "$filecount file" .
	#	($filecount == 1 ? "" : "s"));

	checkm_point();
	# a next call to checkm_point includes line above just printed
	return $ret;
}

#use File::Find;
# $File::Find::prune = 1

# XXX add to spec: two ways that a pairpath ends: 1) the form of the
# ppath (ie, ends in a morty) and 2) you run "aground" smack into
# a "longy" ("thingy") or a file

# xxx other stats to gather: total dir count, total count of all things
# that aren't either reg files or dirs; plus max and averages for all
# things like depth of ppaths (ids), depth of objects, sizes of objects,
# fanout; same numbers for "pairtree.*" branches

my ($pdname, $tpname, $wpname, $funame);
my $symlinks_followed = 1;
my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze, $atime, $mtime);

use Digest;

# returns scalar message string on error or ref to a digester object
sub make_digester { my( $algname )=@_;

	my $digester;
	#eval { require $a; import $a }; $@ and print "xxx$@\n";

	# protect us from exceptions
	eval { $digester = Digest->new($algname); };
	$@	and return undef;	# $algname not installed

	return $digester;		# success
}

# Return formatted list of known digest algorithms
sub list_digesters {

	my ($a, $digester, @ret);
	for $a ( qw(	MD4/Digest::MD4
			MD5/Digest::MD5
			SHA‐256/Digest::SHA2
			SHA‐1/Digest::SHA
			SHA‐256/Digest::SHA
			Haval‐256/Digest::Haval256
			SHA‐384/Digest::SHA2
			SHA‐384/Digest::SHA
			SHA‐512/Digest::SHA
			Whirlpool/Digest::Whirlpool
			MD2/Digest::MD2
			Adler‐32/Digest::Adler32
			CRC‐16/Digest::CRC
			CRC‐32/Digest::CRC
			MD5/Digest::Perl::MD5
			CRC‐CCITT/Digest::CRC ) ) {

		my ($alg, $module) = split('/', $a);
		# XXXXX why aren't these found ?
		#print STDERR "looking for $alg";

		$digester = make_digester($alg);

		unless ($digester) {
		#	print STDERR "--not found\n";
			next;		# $alg not installed
		}
		#print STDERR "--found\n";

		undef $digester;

		#eval {
		#	$digester = Digest->new($alg);
		#};
		#$@	and print("@=$@"), next;	# $alg not installed
		#undef $digester;
		push @ret, "\t$alg ($module)";
	}
	return @ret;
}

# returns hex digest or string beginning "error:"
sub digest_file { my( $fname, $digester )=@_;

	$fname			or return "error: no filename given";
	$digester		or return "error: no Digest object given";
	open(FH, "<$fname") 	or return "error: open <$fname failed: $!";
	binmode(FH)		or return "error: binmode failed: $!";

	# xxx catch croaks in addfile, or let go? see perldoc Digest
	$digester->addfile(*FH) or
		close(FH), return "error: Digest->addfile failed: $!";

	my $digest = $digester->hexdigest;

	$digester->reset() or
		close(FH), return "error: Digest->reset failed: $!";
	close(FH);
	return $digest;
}

# Hex-encode any '|' and '\n' that might appear (in filename)
#
sub checkm_encode { my( $s )=@_;

	$s =~ s/([\n|])/sprintf("%%%02x", ord($1))/eg;
	return $s;
}

sub checkm_time { my( $time )=@_;

	$time ||= time();	# use supplied time or current time
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
		gmtime($time);
	return sprintf(($o_temper ?	# yyy short temper?
		"%04d.%02d.%02d.%02d:%02d:%02dZ" :
		"%04d-%02d-%02dT%02d:%02d:%02dZ"),
		$year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

# XXX add ability to print #%checkm_perm | drwxr-xr-x ... type info
# $tpname = current filename in directory, $wpname = full pathname
sub checkm_fileobj { my( $tpname, $wpname, $mtime )=@_;

	# Initialize checkm line and whether an error as occurred.
	my $line = "";
	my $err = 0;			# 0 = no error, 1 = error
	my $msg;			# what digester returns
	defined($wpname) or
		die "checkm_fileobj error: wpname arg must be defined";
	# yyy should "" or "-" mean stdin?
	
	unless ($tpname) {
		$line .= checkm_encode($wpname) . $S .
			"error: dangling symlink (target doesn't exist)";
		return dprint 1, $line;
	}
	unless (-e _) {
		$line .= checkm_encode($wpname) . $S .
			"error: file doesn't exist";
		return dprint 1, $line;
	}

	my $fields_left = $o_fieldscount;	# how many fields we're to do
	$fields_left <= 0	and return 1;	# print nothing

	$o_fname and
		$fields_left--,
		($line .= checkm_encode($wpname));
	# else { }				# else nothing to do
	$fields_left <= 0	and return dprint $err, $line;

	$line .= $S;
	$o_aname and
		$fields_left--,
		($line .= $o_alg);
	$fields_left <= 0	and return dprint $err, $line;

	$line .= $S;
	$o_digest and
		$fields_left--,
		($msg = digest_file($tpname, $o_digester)),
		($line .= $msg),		# may contain error message
		($msg =~ /^error:/	and $err ||= 1);
	$fields_left <= 0	and return dprint $err, $line;

	$line .= $S;
	$o_size and
		$fields_left--,
		($line .= (-s _));
	$fields_left <= 0	and return dprint $err, $line;

	$line .= $S;
	$o_mtime and
		$fields_left--,
		($line .= checkm_time($mtime));
	$fields_left <= 0	and return dprint $err, $line;

	return dprint $err, $line;		# need this?
}

sub checkm_visit_node {	# receives no args

	$pdname = $File::Find::dir;		# current parent directory name
	$tpname = $_;				# current filename in that dir
	$wpname = $File::Find::name;		# whole pathname to file
	$funame = $symlinks_followed ?		# full name, symlinks resolved
		$File::Find::fullname : $wpname;

#print "======tp=$tpname, wp=$wpname, pd=$pdname, fn=$File::Find::fullname\n";
#print "======fullname=$File::Find::fullname\n";
	# We want to harvest all the inode info for each visit, which
	# usually means stat.  Since we want also to know when we have a
	# symlink, we actually need lstat.  An lstat is done by "find"
	# anyway if following symlinks, so we avoid the work of a real
	# lstat on the file and instead call it on the magic handle "_".
	#
	($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze, $atime, $mtime)
			= lstat($tpname)
		#unless ($symlinks_followed and ($sze = -s _));
		unless (defined($funame) and	# _ fails if symlink dangles
	($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze, $atime, $mtime)
			= lstat(_));

	#print "NEXT: $pdname $_ $wpname\n";

	# If we follow symlinks (usual), we have to expect the -l type,
	# which hides the type of the link target (what we really want).
	#
	if (-l _) {
		$symlinkcount++;
		#print "XXXX SYMLINK $wpname\n";
		# yyy presumably this branch never happens when
		#     _not_ following links?
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze, $atime,
			$mtime) = stat($tpname);	# harvest real file
		unless ($funame) {			# bail if dangling link
			checkm_fileobj($funame, $wpname, $mtime);
			return;
		}
		# Now that we have the actual inode info, fall through.
	}
	# After this, tests of the form (-X _) give almost everything.
	# XXX output DLS (+Dirs.Links.Specials)

	if (-f _) {
		$filecount++;
		$octetcount += $sze;
		checkm_fileobj($tpname, $wpname, $mtime);
	}
	elsif (-d _) {
		$dircount++;
		$gr_opt->{long}		and checkm_dirobj();
	}
	else {
		$irregcount++;
		$gr_opt->{long}		and checkm_specialobj();
	}
}

1;

__END__

=head1 NAME

File::Checkm - routines to manage Checkm manifests

=head1 SYNOPSIS

 use File::Checkm;           # imports routines into a Perl script

 checkm_trees();
 make_digester();
 list_digesters();

=head1 DESCRIPTION

This is very brief documentation for the B<Checkm> Perl module.

=head1 AUTHOR

John Kunze I<jak at ucop dot edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 UC Regents.  Open source BSD license.

=cut

__END__
