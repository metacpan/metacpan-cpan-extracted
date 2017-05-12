package File::Pairtree;

use 5.006;
use strict;
use warnings;

our $VERSION;
$VERSION = sprintf "%d.%02d", q$Name: Release-1-02 $ =~ /Release-(\d+)-(\d+)/;
#$VERSION = sprintf "%s", q$Name: Release-v0.304.0$ =~ /Release-(v\d+\.\d+\.\d+)/;
#our $NVERSION;			# pure numeric 2-part equivalent version
#($NVERSION = $VERSION) =~ s/v(\d+\.\d+)\.\d+/$1/;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(
	id2ppath ppath2id s2ppchars id2pairpath pairpath2id
	pt_lsid pt_lstree pt_mkid pt_mktree pt_rmid
	pt_budstr get_prefix
	$pfixtail
	$pair $pairp1 $pairm1
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

our @EXPORT_FAIL = qw(
	pair=1 pair=2 pair=3 pair=4 pair=5 pair=6 pair=7 pair=8 pair=9
);
push @EXPORT_OK, @EXPORT_FAIL;		# add pseudo-symbols we will trap

# This is a magic routine that the Exporter calls for any unknown symbols.
# We use it to permit export of pseudo-symbols "pair=1", "pair=2", ...,
# "pair=9" so the caller can define a pair to mean 1, 2, ..., or 9 octets.
#
sub export_fail { my( $class, @symbols )=@_;

	my @unknowns;
	for (@symbols) {
		! s/^pair=([1-9])$/$1/ and
			push(@unknowns, $_),
			next;
		pair_means($_);		# define how many octets form a pair
	}
	return @unknowns;
}

# xxx Config?
my $default_pathcomp_sep = '/';

# In case we want to experiment with different cardinality of "pair",
# eg, 3 chars, 1 char, 4 chars.  This is mostly untested. XXX
# 
our ($pair, $pairp1, $pairm1);

sub pair_means{ my( $n )=@_;

	die "the number meant by 'pair' must be a positive integer"
		if ($n < 1);
	$pair = $n;
	$pairp1 = $pair + 1;
	$pairm1 = $pair - 1;	# xxx what if $pairm1 is zero?
	return 1;
}
# XXXXXXXX arrange to call this at compile time?? punish the user if
#  they call it themselves???

# If not done so on import, define now how many octets in a pair.
#
defined($pair)		or pair_means(2);
#
# Now it's safe to define compiled regexps based on
# constant values for $pair, $pairp1, and $pairm1.

# this regexp matches a valid base ppath with bud attached
our $proper_ppath_re = "([^/]{$pair}/)*[^/]{1,$pair}";
our $root = "pairtree_root";

my $R = $root;
my $P = $proper_ppath_re;

# Pairtree - Pairtree support software (Perl module)
# 
# Author:  John A. Kunze, jak@ucop.edu, California Digital Library, 2008
#          based on three lines of code originally from Sebastien Korner:
# $pt_objid =~ s/(\"|\*|\+|,|<|=|>|\?|\^|\|)/sprintf("^%x", ord($1))/eg;
# $pt_objid =~ tr/\/:./=+,/;
# my $pt_prefix = $namespace."/pairtree_root/".join('/', $pt_objid =~ /..|.$/g);

# id2ppath - return /-terminated ppath corresponding to id
# 
# For Perl, the platform's path component separator ('/' or '\') is
# automagically converted when needed to do filesystem things; in fact,
# trying to use the correct separator can get you into trouble.  So we
# make it possible to specify the path component separator, but we won't
# do it for you.  Instead we assume '/'.
#
# The return path starts with /pairtree_root to encourage good habits --
# this could backfire.  We use the symbol 'pathcomp_sep' because
# 'path_sep' is already taken by the Config module to designate the
# character that separates entire pathnames, eg, ':' in the PATH
# environment variable.
#
# XXXXX this $pathcomp_sep -- is it worth a variable or is it better to
# let it be constant so we can compile the regexp?
sub id2ppath{ my( $id, $pathcomp_sep )=@_;	# single arg form, second
						# arg not advertized

	$pathcomp_sep ||= $default_pathcomp_sep;
#	$id =~ s{
#		(["*+,<=>?\\^|]			# some visible ASCII and
#		 |[^\x21-\x7e])			# all non-visible ASCII
#	}{
#		sprintf("^%02x", ord($1))	# replacement hex code
#	}xeg;
#
#	# Now do the single-char to single-char mapping.
#	# The / translated next is not to be confused with $pathcomp_sep.
#	#
#	$id =~ tr /\/:./=+,/;			# per spec, /:. become =+,

	$id = s2ppchars($id, $pathcomp_sep);

	return $root
		. $pathcomp_sep
		. join($pathcomp_sep, $id =~ /.{1,$pair}/g)
		. $pathcomp_sep;
		# . join($pathcomp_sep, $id =~ /..|.$/g)
}

sub s2ppchars{ my( $s, $pathcomp_sep )=@_;

	$pathcomp_sep ||= $default_pathcomp_sep;
	$s =~ s{
		(["*+,<=>?\\^|]			# some visible ASCII and
		 |[^\x21-\x7e])			# all non-visible ASCII
	}{
		sprintf("^%02x", ord($1))	# replacement hex code
	}xeg;

	# Now do the single-char to single-char mapping.
	# The / translated next is not to be confused with $pathcomp_sep.
	#
	$s =~ tr /\/:./=+,/;			# per spec, /:. become =+,
	return $s;
}

# XXX ditch 2-arg forms?
# This 2-arg form exists for parallelism with other language interfaces
# (that don't may not have optional arguments).  Perl users would
# normally prefer the id2ppath form for full functionality and speed.
# 
sub id2pairpath{ my( $id, $pathcomp_sep )=@_;	# two-argument form

	return id2ppath($id, $pathcomp_sep);
}

# ppath2id - return id corresponding to ppath, or string of the form
#		"error: <msg>"
# There is more error checking required for ppath2id than id2ppath,
# as the domain is more constrained.
#
sub ppath2id{ my( $path, $pathcomp_sep )=@_;	# single arg form, second
						# arg not advertized
	my $id = $path;			# initialize $id with $path
	my $p = $pathcomp_sep || $default_pathcomp_sep;

	my $expect_hexenc;		# chars expected to be hex encoded
	if ($p eq '\\') {		# \ is a common, problemmatic case
		$expect_hexenc = '"*<>?|';	# don't need to encode \ 
		$p = '\\\\';		# and double escape for use in regex
	} else {
		$expect_hexenc = '"*<>?|\\\\';	# do need to encode \ 
	}

	# Trim everything from the beginning up to the last instance of
	# $root (via a greedy match).  If there's a pairpath to the right
	# of a given pairpath, assume that the most fine grained path
	# (rightmost) is the one the user's interested in.
	#
	$id =~ s/^.*$root//;

	# Normalize so there's no initial or final whitespace, no
	# repeated $pathcomp_sep chars, and exactly one $pathcomp_sep
	# at the beginning and end.
	#
	$id =~ s/^\s*/$p/;
	$id =~ s/\s*$/$p/;
	$id =~ s/$p+/$p/g;

	# Also trim any final junk, eg, anpath extension that is really
	# internal to an object directory.
	#
	$id =~ s/[^$p]{$pairp1,}.*$//;	# trim final junk

	# Finally, trim anything that follows a one-char path component,
	# a one-char component being another signal of the end of a ppath.
	# In a general sense, "one" here really means "one less than the
	# number of chars in a 'pair'".
	#
	$id =~ s/($p([^$p]){1,$pairm1}$p).*$/$1/;   # trim after 1-char comp.

	# Reject if there are any non-visible chars.
	#
	return "error: non-visible chars in $path" if
		$id =~ /[^\x21-\x7e]/;

	# Reject if there are any other chars that should be hex-encoded.
	#
	return "error: found chars expected to be hex-encoded in $path" if
		$id =~ /[$expect_hexenc]/;

	# Now remove the path component separators.
	#
	$id =~ s/$p//g;

	# Reverse the single-char to single-char mapping.
	# This might add formerly hex-encoded chars back in.
	#
	$id =~ tr /=+,/\/:./;		# per spec, =+, become /:.

	# Reject if there are any ^'s not followed by two hex digits.
	#
	return "error: impossible hex-encoding in $path" if
		$id =~ /\^($|.$|[^0-9a-fA-F].|.[^0-9a-fA-F])/;

	# Now reverse the hex conversion.
	#
	$id =~ s{
		\^([0-9a-fA-F]{2})
	}{
		chr(hex("0x"."$1"))
	}xeg;

	return $id;
}

use Carp;
use File::Spec;
use File::Find;
use File::Path;
use File::Namaste qw( nam_add );
use File::Value ':all';
use File::Glob ':glob';		# standard use of module, which we need
				# as vanilla glob won't match whitespace

our $Win;			# whether we're running on Windows
# xxx should probably test directly for symlink capacity
defined($Win) or	# if we're on a Windows platform avoid -l
	$Win = grep(/Win32|OS2/i, @File::Spec::ISA);

my $pfixtail = 'pairtree_prefix';

# Return empty string unless we find a prefix value.
sub get_prefix { my( $parent_dir )=@_;

	my $prefix = "";
	my $pxfile = $parent_dir . $pfixtail;
	return $prefix			unless -e $pxfile;
	my $msg = file_value("< $pxfile", $prefix);
	die "$pxfile: $msg"		if $msg;
	return $prefix;
}

# caller can define inputs $$r_opt{prefix} and $$r_opt{parent_dir} for speed
# we return under keys: msg, ppath, bud
# return 0 on success, 1 on soft fail, >1 on hard fail
# xxxxxxxxx get consistent on these return codes/croaks
#
sub pt_lsid { my( $dir, $id, $r_opt )=@_;

	$dir		or croak "no dir or empty dir";
	$id		or croak "no id or empty id";
	ref($r_opt) eq "HASH" or
		croak "r_opt must reference a hash (for input/output)";

	$dir = fiso_dname($dir, $R);	# make sure we have descender
	my $parent_dir = $$r_opt{parent_dir}
		|| fiso_uname($dir);
	my $prefix = $$r_opt{prefix}
		|| get_prefix($parent_dir);

	# prefix substitution is optional unless -f ??? XXXXX
	# xxx test
	$prefix and ! ($id =~ s/^$prefix//) and $$r_opt{force} and
		($$r_opt{msg} = "no prefix present in: $id"),
		return 2;

	my $ppath = $parent_dir . id2ppath($id);
	-e $ppath or
		($$r_opt{msg} = "non-existent ppath ($ppath)"),
		($$r_opt{ppath} = ""),
		return 1;		# softer failure than return 2
	$$r_opt{ppath} = $ppath;

	# Now that we have a valid ppath, we still don't know what
	# the encapsulating directory (or anything else for that
	# matter) looks like, so we use glob to look for things.
	# Recall that $ppath ends in a '/' (from id2ppath).
	# xxx sepchar better than / ?
	#
	my @buds = grep ! m{(^|/)\.\.?$},	# except for . and ..
		bsd_glob($ppath . "{*,.*}");	# look for all files
	my $nbuds = scalar @buds;		# how many buds?
	$nbuds == 0 and				# empty ppath, not a node
		($$r_opt{msg} = "no bud: $ppath"),
		($$r_opt{bud} = ""),
		return 2;

	# If we get here, there's one or more things at end of ppath.
	#
	$nbuds > 1 and
		($$r_opt{msg} = "expected one bud but got $nbuds buds"),
		($$r_opt{bud} = join " ", @buds),
		return 2;

	# If we get here, only one thing at end of ppath (the common case).
	#
	$$r_opt{bud} = shift @buds;

	# XXXXX  ??? $$r_opt{oxum},  $$r_opt{details} ?  $$r_opt{long}
	#        ? $$r_opt{all}
	return 0;
}

my $homily = "(pairpath end should be followed by only one thing -- " .
		"a directory name more than $pair characters long)";

# Create a closure to hold a stateful node-visiting subroutine and other
# options suitable to be passed as the options parameter to File::Find.
# Returns the small hash { 'wanted' => $visitor, 'follow' => 1 } and a
# subroutine $visit_over that can be called to summarize the visit.
#
sub make_visitor { my( $r_opt )=@_;

	my $om = $r_opt->{om} or
		return undef;

	my $objectcount = 0;		# number of objects encountered
	my $filecount = 0;		# number of files encountered xxx
	my $dircount = 0;		# number of directories encountered xxx
	my $symlinkcount = 0;		# number of symlinks encountered xxx
	my $irregularcount = 0;		# non file, non dir fs items to report

	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze);
	my ($pdname, $tpname, $wpname);
	my $symlinks_followed = 1;

	# yyy do as $curobj = {...}; ?
	my %curobj = (
		'ppath' => '',
		'encaperr' => 0,
		'octets' => 0,
		'streams' => 0,
	);

    # xxx move this outside closure and give it a $currobj arg?
    #     or is this much more efficient as-is?
    # xxx nail down everything that won't change during lstree
    my $newobj = sub { my( $ppath, $encaperr, $octets, $streams )=@_;

	# warning: ugly code ahead
	if ($curobj{'ppath'}) {		# print record of previous obj
		$_ = ppath2id($curobj{'ppath'});
		s/^/$r_opt->{prefix}/;		# uses global set in lstree()
		$r_opt->{long} and
			$om->elem('node',
				join("  ", $_, $curobj{'ppath'},
				"$curobj{'octets'}.$curobj{'streams'}")), 1
		or
			$om->elem('node', $_), 1
		;
		$curobj{'ppath'} eq $ppath and
			print "error: corrupted pairtree at pairpath ",
				"$ppath/: split end $homily\n";
		# xxx use om?
	}
	# xxx strange
	die "newobj: all args must be defined"
		unless (defined($ppath) && defined($encaperr)
			&& defined($octets) && defined($streams));
	$curobj{'ppath'} = $ppath;
	$curobj{'encaperr'} = $encaperr;
	$curobj{'octets'} = $octets;
	$curobj{'streams'} = $streams;
    };

    my $visitor = sub {		# receives no args from File::Find

	$pdname = $File::Find::dir;		# current parent directory name
	$tpname = $_;				# current filename in that dir
	$_ = $wpname = $File::Find::name;	# whole pathname to file

	# We always need lstat() info on the current node XXX why?
	# xxx tells us all, but if following symlinks the lstat is done
	# ... by find:  use (-X _), but of the nifty facts below we
	# still need to harvest the size ($sze) by hand.
	#
	($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze) = lstat($tpname)
		unless ($symlinks_followed and ($sze = -s _));

	#print "NEXT: $pdname $_ $wpname\n";

	# If we follow symlinks (usual), we have to expect the -l type,
	# which hides the type of the link target (what we really want).
	#
	if (! $Win and -l _) {
		$symlinkcount++;
		#print "XXXX SYMLINK $_\n";
		# yyy presumably this branch never happens when
		#     _not_ following links?
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze)
			= stat($tpname);	# get the real thing
	}
	# After this, tests of the form (-X _) give almost everything.

	if (-f $tpname) {
		$filecount++;
		if (m@^.*$R/(.*/)?pairtree.*$@o) {
			### print "$pdname PTREEFILE $tpname\n";
			# xxx    if $verbose;
			# else -prune ??
		}
		elsif (m@^.*$R/$P/[^/]+$@o) {
			#print "m@.*$R/$P/[^/]+@: $_\n";
		 	#print "$pdname UF $tpname\n";
			print "error: corrupted pairtree at pairpath ",
				"$pdname/: found unencapsulated file ",
				"'$tpname' $homily\n";
		}
		else {
			# xxx sanity check that $curobj is defined
			$curobj{'octets'} += $sze;
			### print "sssss $curobj{'octets'}\n";
			$curobj{'streams'}++;
		#	-fprintf $altout 'IN %p %s\n'
		#	$noprune
		}
	}
	elsif (-d $tpname) {
		$dircount++;
		if (m@^.*$R/(.*/)?pairtree.*$@o) {
			#print "$pdname PTREEDIR $tpname\n";
			# xxx if $verbose;
		#	-prune
		}
		# At last, we're entering a "regular" object.
		elsif (m@^.*$R/($P/)?[^/]{$pairp1,}$@o) {
			# start new object; but end previous object first
			# form: ppath, EncapErr, octets, streams
			$objectcount++;
			&$newobj($pdname, 0, 0, 0);
			# print "$pdname NS $tpname\n";
			#	-fprintf $altout 'START %h 0\n'
			#	$noprune
		}
		elsif (m@^.*$R/$P$@o) {
			#	-empty
			# xxx if $verbose...	-printf '%p EP -\n'
		}
		# $pair, $pairm1, $pairp1
		# We have a post-morty encapsulation error
		elsif (m@^.*$R/([^/]{$pair}/)*[^/]{1,$pairm1}/[^/]{1,$pair}$@o) {
			#print "$pdname PM $tpname\n";
			print "error: corrupted pairtree at pairpath ",
				"$pdname/: found '$tpname' after forced ",
				"path ending $homily\n";
				
			#	-fprintf $altout 'START %h 0\n'
			#	$noprune
		}
	}
	else {
		$irregularcount++;
	}
    };

    my $visit_over = sub { my( $ret, $tree )=@_;

	$ret ||= 0;

	# Dummy call to pt_newobj() to cough up the last buffered object.
	# xxx not multi-threadable!  how to give newobj its own context?
	&$newobj("", 0, 0, 0);			# shake out the last one

	# XXX what does find return?
	$om->elem("lstree", "find returned '$ret' for $tree")	if $ret;
	$om->elem("objectcount", "$objectcount object" .
		($objectcount == 1 ? "" : "s"));

	return ($objectcount);
    };

    	return ({ 'wanted' => $visitor, 'follow' => $r_opt->{follow_fast} },
		$visit_over);
}

sub pt_lstree { my( $tree, $r_opt, $r_visit_node, $r_wrapup )=@_;

	$tree		or croak "no tree dir or empty tree dir";
	ref($r_opt) eq "HASH" or
		croak "r_opt must reference a hash (for input/output)";
	ref( $r_visit_node ||= \&pt_visit_node ) eq "CODE" or
		croak "r_visit_node must reference a node-visiting function";
	#ref( $r_wrapup ||= \&pt_lstree_wrapup ) eq "CODE" or
	#	croak "r_wrapup must reference a node-visiting function";

	$tree = fiso_dname($tree, $R);	# make sure we have descender
	$$r_opt{parent_dir} ||= fiso_uname($tree);
	$$r_opt{prefix} ||= get_prefix($$r_opt{prefix});

	my ($find_opt, $visit_over) = make_visitor($r_opt);
	$find_opt or
		croak "make_visitor() failed";
	my $ret = find($find_opt, $tree);
	$visit_over and
		&$visit_over($ret, $tree);
	return $ret;
}

# Create the bud string that will encapsulate the leaf node
#
sub pt_budstr { my( $id, $bud_style )=@_;

	# Xxx add chars if less than $pair chars in $_
	$id ||= "";
	! $id and				# valid but empty id/ppath
		return "supernode";
	$bud_style ||= 0;			# xxx

	my $n = length($id) - 1;
	$n < $pair and				# pad on left with zeroes
		$id = ("0" x ($pair - $n)) . $id;

	# xxx optional variation on endings
	$bud_style == 0 and			# "full"
		return s2ppchars($id);
	#or			# XXX no other possibility right now
	;
	return s2ppchars($id);
}

sub pt_mkid { my( $dir, $id, $r_opt )=@_;

	$dir		or croak "no dir or empty dir";
	$id		or croak "no id or empty id";
	ref($r_opt) eq "HASH" or
		croak "r_opt must reference a hash (for input/output)";

	$dir = fiso_dname($dir, $R);	# make sure we have descender
	my $parent_dir = $$r_opt{parent_dir}
		|| fiso_uname($dir);
	my $prefix = $$r_opt{prefix}
		|| get_prefix($parent_dir);

	# prefix substitution is optional unless -f
	$prefix and ! ($id =~ s/^$prefix//) and $$r_opt{force} and
		($$r_opt{msg} = "no prefix present in: $id"),
		return 0;
	$id !~ m/^\s*$/ or		# double check that we won't xxx?
		croak "bad node";	# create a malformed pairtree

	-d $dir or			# need to create base directory
		pt_mktree($dir, "", $r_opt) and		# if error
		($$r_opt{msg} = "pt_mkid: $$r_opt{msg}"),
		return 1;		# return after adding our stamp
	my $ppath = $parent_dir . id2ppath($id);
	my $bud = $ppath . pt_budstr($id, $$r_opt{bud_style});

	my $ret;
	eval { $ret = mkpath($bud) };
	$@		and croak "Couldn't create $bud: $@";
	if ($ret == 0) {
		croak "pt_mkid: mkpath returned '0' for $bud"
			unless -e $bud;
		$$r_opt{msg} = "error: $bud ($id) already exists\n";
		return 0;
	}
	$$r_opt{ppath} = $ppath;
	$$r_opt{bud} = $bud;

	return 1;
}

sub pt_mktree { my( $dir, $prefix, $r_opt )=@_;

	# XXXX make up my mind about when to croak and when to
	#      use $$r_opt{msg}
	$dir		or croak "no tree dir or empty tree dir";
	$prefix ||= "";
	ref($r_opt) eq "HASH" or
		croak "r_opt must reference a hash (for input/output)";
			# except that we ignore any r_opt inputs here

	$dir = fiso_dname($dir, $R);	# make sure we have descender
	my $parent_dir = fiso_uname($dir);
	my $ret;
	eval { $ret = mkpath($dir) };
	if ($@) {
		$$r_opt{msg} = "Couldn't create $dir tree: $@";
		return 1;
	}
	if ($ret == 0) {
		$$r_opt{msg} = -e $dir ? "$dir already exists"
			: "pt_mktree: mkpath returned '0' for $dir";
		return 1;
	}

	my $pxfile = File::Spec->catfile($parent_dir, $pfixtail);
	my $msg = file_value("> $pxfile", $prefix)
		if ($prefix);
	if ($msg) {
		$$r_opt{msg} = "$pxfile: $msg";
		return 1;
	}
	$msg		and croak "Couldn't create namaste tag in $dir: $msg";
	$msg = nam_add($parent_dir, undef, '0', "pairtree_$VERSION", 0);
		# yyy better to use 0 to mean "don't truncate"
		#length("pairtree_$VERSION"));
	# xxxx croak or return via r_opt{msg}
	$msg	and croak "Couldn't create namaste tag in $parent_dir: $msg";

	return 0;
}

sub pt_rmid { my( $dir, $id, $r_opt )=@_;

	$dir		or croak "no dir or empty dir";
	$id		or croak "no id or empty id";
	ref($r_opt) eq "HASH" or
		croak "r_opt must reference a hash (for input/output)";

	$dir = fiso_dname($dir, $R);	# make sure we have descender
	my $parent_dir = $$r_opt{parent_dir}
		|| fiso_uname($dir);
	my $prefix = $$r_opt{prefix}
		|| get_prefix($parent_dir);

	# prefix substitution is optional unless -f
	$prefix and ! ($id =~ s/^$prefix//) and $$r_opt{force} and
		($$r_opt{msg} = "no prefix present in: $id"),
		return 0;
	$id !~ m/^\s*$/ or		# double check that we won't xxx?
		croak "bad node";	# create a malformed pairtree
#xxxxx this double check above should be against whole path
	## double check that we won't delete whole pairtree
	#die "bad node: $_"
	#	if m,$R/*$,;

	my $ppath = $parent_dir . id2ppath($id);
	-e $ppath or			# if it doesn't exist
		($$r_opt{msg} = "non-existent ppath ($ppath)"),
		($$r_opt{ppath} = ""),
		return 1;		# softer failure than return 2

	$$r_opt{ppath} = $ppath;
	my $ret;
	eval { $ret = rmtree($ppath) };
	if ($@) {
		$$r_opt{msg} = "Couldn't remove $ppath tree: $@";
		return 1;
	}
	if ($ret == 0) {
		$$r_opt{msg} = "warning: $id ($ppath) " .
			(-e $ppath ?  "not removed" : "doesn't exist");
		return 1;		# soft failure
	}
	return 0;			# success
}

1;

__END__

=head1 NAME

File::Pairtree - routines to manage pairtrees

=head1 SYNOPSIS

 use File::Pairtree;           # imports routines into a Perl script

 id2ppath($id);                # returns pairpath corresponding to $id
 id2ppath($id, $separator);    # if you want an alternate separator char

 ppath2id($path);              # returns id corresponding to $path
 ppath2id($path, $separator);  # if you want an alternate separator char

 pt_budstr();
 pt_mkid();
 pt_mktree();
 pt_rmid();
 pt_lsid();

=head1 DESCRIPTION

This is very brief documentation for the B<Pairtree> Perl module.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2011 UC Regents.  Open source BSD license.

=cut

__END__

=for removing

#use File::Find;
# $File::Find::prune = 1

# XXX add to spec: two ways that a pairpath ends: 1) the form of the
# ppath (ie, ends in a morty) and 2) you run "aground" smack into
# a "longy" ("thingy") or a file

# xxx other stats to gather: total dir count, total count of all things
# that aren't either reg files or dirs; plus max and averages for all
# things like depth of ppaths (ids), depth of objects, sizes of objects,
# fanout; same numbers for "pairtree.*" branches

my ($pdname, $tpname, $wpname);
my $symlinks_followed = 1;
my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze);
my %curobj = (
	'ppath' => '',
	'encaperr' => 0,
	'octets' => 0,
	'streams' => 0,
);

sub pt_newobj { my( $ppath, $encaperr, $octets, $streams )=@_;

	# warning: ugly code ahead
	if ($curobj{'ppath'}) {		# print record of previous obj
		$_ = ppath2id($curobj{'ppath'});
		s/^/$$gr_opt{prefix}/;		# uses global set in lstree()
		$$gr_opt{long} and
			$gr_opt->{om}->elem('node',
				join("  ", $_, $curobj{'ppath'},
				"$curobj{'octets'}.$curobj{'streams'}")), 1
		or
			$gr_opt->{om}->elem('node', $_), 1
		;
		$curobj{'ppath'} eq $ppath and
			print "error: corrupted pairtree at pairpath ",
				"$ppath/: split end $homily\n";
		# xxx use om?
	}
	# xxx strange
	die "pt_newobj: all args must be defined"
		unless (defined($ppath) && defined($encaperr)
			&& defined($octets) && defined($streams));
	$curobj{'ppath'} = $ppath;
	$curobj{'encaperr'} = $encaperr;
	$curobj{'octets'} = $octets;
	$curobj{'streams'} = $streams;
}

sub pt_visit_node {	# receives no args

	$pdname = $File::Find::dir;		# current parent directory name
	$tpname = $_;				# current filename in that dir
	$_ = $wpname = $File::Find::name;	# whole pathname to file

	# We always need lstat() info on the current node XXX why?
	# xxx tells us all, but if following symlinks the lstat is done
	# ... by find:  use (-X _), but of the nifty facts below we
	# still need to harvest the size ($sze) by hand.
	#
	($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze) = lstat($tpname)
		unless ($symlinks_followed and ($sze = -s _));

	#print "NEXT: $pdname $_ $wpname\n";

	# If we follow symlinks (usual), we have to expect the -l type,
	# which hides the type of the link target (what we really want).
	#
	if (! $Win and -l _) {
		$symlinkcount++;
		print "XXXX SYMLINK $_\n";
		# yyy presumably this branch never happens when
		#     _not_ following links?
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze)
			= stat($tpname);	# get the real thing
	}
	# After this, tests of the form (-X _) give almost everything.

	if (-f $tpname) {
		$filecount++;
		if (m@^.*$R/(.*/)?pairtree.*$@o) {
			### print "$pdname PTREEFILE $tpname\n";
			# xxx    if $verbose;
			# else -prune ??
		}
		elsif (m@^.*$R/$P/[^/]+$@o) {
			#print "m@.*$R/$P/[^/]+@: $_\n";
		 	#print "$pdname UF $tpname\n";
			print "error: corrupted pairtree at pairpath ",
				"$pdname/: found unencapsulated file ",
				"'$tpname' $homily\n";
		}
		else {
			# xxx sanity check that $curobj is defined
			$curobj{'octets'} += $sze;
			### print "sssss $curobj{'octets'}\n";
			$curobj{'streams'}++;
		#	-fprintf $altout 'IN %p %s\n'
		#	$noprune
		}
	}
	elsif (-d $tpname) {
		$dircount++;
		if (m@^.*$R/(.*/)?pairtree.*$@o) {
			#print "$pdname PTREEDIR $tpname\n";
			# xxx if $verbose;
		#	-prune
		}
		# At last, we're entering a "regular" object.
		# XXXXXXX add re qualifier so Perl knows re's not changing
		elsif (m@^.*$R/($P/)?[^/]{$pairp1,}$@o) {
			# start new object; but end previous object first
			# form: ppath, EncapErr, octets, streams
			$objectcount++;
			pt_newobj($pdname, 0, 0, 0);
			# print "$pdname NS $tpname\n";
			#	-fprintf $altout 'START %h 0\n'
			#	$noprune
		}
		elsif (m@^.*$R/$P$@o) {
			#	-empty
			# xxx if $verbose...	-printf '%p EP -\n'
		}
		# $pair, $pairm1, $pairp1
		# We have a post-morty encapsulation error
		elsif (m@^.*$R/([^/]{$pair}/)*[^/]{1,$pairm1}/[^/]{1,$pair}$@o) {
			#print "$pdname PM $tpname\n";
			print "error: corrupted pairtree at pairpath ",
				"$pdname/: found '$tpname' after forced ",
				"path ending $homily\n";
				
			#	-fprintf $altout 'START %h 0\n'
			#	$noprune
		}
	}
	else {
		$irregularcount++;
	}
}

=cut

#!/usr/bin/perl -w -Ilib

# XXX to pairtree spec add appendix enumerating some named methods for
#   deriving objdir names
# XXX add to spec: two ways that a pairpath ends: 1) the form of the
# ppath (ie, ends in a morty) and 2) you run "aground" smack into
# a "longy" ("thingy") or a file

# xxx other stats to gather: total dir count, total count of all things
# that aren't either reg files or dirs; plus max and averages for all
# things like depth of ppaths (ids), depth of objects, sizes of objects,
# fanout; same numbers for "pairtree.*" branches

use strict;
use File::Find;
#use File::Pairtree qw( $pair $pairp1 $pairm1 );
use File::Pairtree qw( $pair $pairp1 $pairm1 );

my $R = $File::Pairtree::root;

#XXX check for bad char encodings?  (Cory S.)

# Set up a big "find" expression that depends on these features of GNU find:
#   -regex for high-functioning, wholepath matching
#   -printf to tag files/dirs found with certain characteristics
#
# The basic idea is to walk a given hierarchy and tag stuff that looks
# like an object.  Mainstream objects are encapsulated in directory names
# of three characters or more, but we still have to detect the edge cases.
# All candidate object cases are printed on a line with the pairpath
# (ppath) first (as primary sort field), the tagged case, and the file/dir
# name found at the end of the ppath.
#
# XXXXXXXX better tags needed
#	NS=Non-Shorty directory (normal object)
#	UF=Unencapsulated File (encaps. warning),
#	PM=Post-Morty Shorty or Morty encountered (encaps. warning)
#	UG=Unencapsulated Group (encaps. warning)
#       EP=Empty Pairpath (indicator)
#
# The output of the 'find' is sorted (important) so that leaves descending
# from a given ppath cluster in groups.  The resulting groups are used to
# figure out how best to detect and repair any encapsulation problems.
# We offer xxx to repair encapsulation problems because they're non-trivial
# to detect (ie, there will be pairtree walkers that don't detect them) and
# we want to encourage proper encapsulation for the sake of interoperability.
#
# One odd case is an object right at the root of a pairtree, which means
# an empty path, hence an empty identifier.  Because systems frequently
# reserve special meaning for an empty or root value, and they/we might
# want to put something at that special location (eg, an object describing
# the pairtree), we will detect and count it as an object; its meaning and
# (il)legality is up to the implementor.  This has the nice side-effect
# that we'll have no fatal errors in processing a pairtree.
#
# XXX do edge case of pairtree_root/foo.txt
# XXX what to do with symlinks? and unusual filenames?

# Set $verbosefind to '-print' to show everything that 'find' handles,
# but normally don't show by setting it to '-true'.
my $verbosefind='-print';
#my $verbosefind = '-true';

# Normally prune for speed.  Set $verbosefind='-print' and noprune='-true'
# to see what processing steps would happen if you don't prune. xxx
my $noprune='-true';
#my $noprune = '-prune';

# This matches the base ppath in 'find'.
my $PP = '\([^/][^/]/\)*[^/][^/]?';

# This matches the base ppath in 'perl'.
my $P = "([^/]{$pair}/)*[^/]{1,$pair}";

my $tree = $ARGV[0];

$| = 1;		# XXXX unbuffer output   

my $irregularcount = 0;		# non file, non dir fs items to report xxx
my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze);

my $in_object = 0;

my $wpname = '';		# whole pathname
my $tpname = '';		# tail of name
my $pdname = '';		# current directory name

my %curobj = ( 'ppath' => '', 'encaperr' => 0, 'octets' => 0, 'streams' => 0 );

my @ppstack = ();

sub mkstackent{ my( $ppath )=@_;
	return { 'pp' => $ppath, 'bytes' => 0, 'items' => [],
			'objtype' => 1, 'flag' => 0 };
}

my ($ci_state, $ci_wpname, $ci_ppath, $ci_octets, $ci_streams);
$ci_ppath = '';

push(@ppstack, mkstackent(''));
my $top;
my $oldpdname = '';
my $symlinks_followed = 1;			# to minimize lstat calls
my $follow_fast = 1;	# follow symlinks without rigorous checking
			# also means that (-X _) works without stat
#$symlinks_followed = $follow_fast = 0;		# xxx make option-controled

my $in_item = 0;		# we're either in an item or not

find({ wanted => \&visit, follow_fast => $follow_fast }, $tree);

# Using the find() routine is not exactly straightforward.  We cannot
# directly track find()'s stack operations because we may want to follow
# symlinks, in which case find()'s 'preprocess' and 'postprocess' options
# become no-ops.  Instead, the callbacks to 'wanted' (our visit())
# effectively present us with a sequence of node pathnames, p1, p2, ...,
# that are related, we hope, by the following assumptions:
#
#    1. One-step descent: if pN+1 has more path components than pN,
#       it has only one more component.
# ....

sub visit{	# receives no args

	$pdname = $File::Find::dir;		# current parent directory name
	$tpname = $_;				# current filename in that dir
	$wpname = $File::Find::name;		# whole pathname to file
	($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze) = lstat($tpname)
		unless ($symlinks_followed);	# else lstat done for us already
	print "NEXT: $pdname $_ $wpname\n";

	# Node invariants:
	#   1.  During main execution of a node visit, the stack top
	#       names the parent dir (pdname) of the current node.
	#   2.  To achieve this, before main execution our node's parent
	#       is compared to the stack top, from which we expect one of
	#       two outcomes.
	#            ab/cd/ef
	#            ab/cd/efg
	#   3.  Either our node is an immediate descendant of the stack top,
	#       or the stack top is from a completed subtree on a different
	#       branch.
	#   4.  In the latter case we "unvisit" each node in the stack top,
	#       popping the stack as we go.
	#   5.  Lstat will always have been called before the real work
	#       begins, regardless of whether symlinks are being followed.
	#   6.  Upon exit, if we are a directory, the current wpname is
	#       pushed on the stack in anticipation of descent into it;
	#       if we want to detect the case of an empty path or
	#       directory, it is necessary to push onto the stack now
	#       because we won't have a record of it (because there's
	#       no further descent into it if the directory is empty).
	# 
	# Check our current ancestory and pop the stack as needed
	# until stack top equals the parent for this (current) node.
	# If there's a current item (open), we have to check for item
	# boundaries; if we pop back through an item name, we need to
	# close it.

	# We may accumulate an item at any level.  We need to close an
	# item when (a) we pop out of it or (b) descend into a ppath
	# that extends from the same level.  If we pop out of it (a), a
	# common case is when its enclosing directory is the only thing
	# at the end of a ppath.  If we descend (b) into a ppath
	# extension, we'll have to save the current item info on the
	# stack first, as we might encounter other items before we pop
	# back up an know whether our item is properly encapsulated.
	#

	# Feb 16:
	# Modeling assumptions below.  If these are wrong then our theory
	# is wrong, and we bail with "broken model".
	# 
	# Search is a depth-first, pre-order traversal.  Because we want
	# to follow symlinks, we can't take advantage of the preprocess
	# and postprocess options, which become no-ops in this case.
	# This means we have to build our own stack.
	# 
	# We compute object sizes with a straightforward but naive use of
	# what stat() returns for files that we visit.  This means we will
	# be inaccurate when hard links or symlinks point to a file more
	# than once (xxx and for sparse files?).  In principle, find()
	# detects cycles (follow_fast), so whole directories shouldn't
	# be counted twice.
	# 
	# When visiting a node, we assume there are three cases.
	#  (a) We are at the same level as previously visited node, ie,
	#      current parent equals previous parent.
	#  (b) We just descended, ie, current parent extends previous
	#      parent.  Assume also that because of pre-order traversal,
	#      descent is "by one" and ascent blows past previous nodes
	#      to jump into next subtree (post-order would invert these).
	#  (c) We just exhausted the subtree we were in and jumped to a
	#      new subtree that was on find()'s stack, ie, current parent
	#      neither equanls nor extends the previous parent.  In this
	#      case we have to pop our own stack, reporting on all
	#      completed nodes along the way (the whole reason for doing
	#      this work) until reaching the first match against a subpath
	#      of the current parent.  Assume, by pre-order traversal,
	#      that we will be a "by one" descendant of a path that was
	#      on our stack, ie, that we can pop until we exactly match
	#      against the current parent.
	#
	# Roughly, nodes are either directories or non-directories.
	# Nodes are treated one way when descending (here, via visit())
	# and another way when ascending (via unvisit()).
	# 
	# Put top of stack in shorter name.
	$top = $ppstack[$#ppstack];		# xxx is this $#... safe?

	# Because we push a directory onto the stack before we get here,
	# we don't distinguish here between case (a) and case (b).
	#
	#if ($pdname eq $top->{'pp'}) {		# Same level -- case (a)
	#	print "descendant or peer $_\n";	# xxx now what?
	#	#push(@{$top->{'items'}}, $_);
	#	#$top->{'flag'} |= 1;
	#}
	#elsif ($pdname =~ m@^$top->{'pp'}@) {
	#	die("find unexpectedly jumped more than one level deeper"
	#			. ": ppath=$top->{'pp'}, pdname=$pdname")
	#		if ($top->{'pp'} ne '');
	#	# else still initializing (first visit), so fall through
	#}
	if ($pdname ne $top->{'pp'} &&	# if we're not at same or lower level
		$top->{'pp'} ne '') {	# ... and it's not first node ever
		do {
			# XXXXX much reporting during "unvisit"
			unvisit(pop(@ppstack));
			$top = $ppstack[$#ppstack];	# xxx $#... safe?
			# xxx check for underflow
		} until ($pdname eq $top->{'pp'});
	}

	# If we get here, the stack top's pp is the same as our parent
	# (or it's empty because we're at our first node ever).
	#
	if (! $Win and -l _) {
		print "XXXX SYMLINK $_\n";
		# XXX what does this branch do when _not_ following links?
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze)
			= stat($tpname);		# get the real thing
			# get type that symlink points to
	}

# $in_item means we're in an item directory; only turn $in_item off when leaving
# if (! $in_item && ! -d _) {
#	then we have to count current node as part of something
# }
# if $in_item {
#	if -f   add file stats
#	elsif -d  add dir stats
#	else    add other node stats
# }
#
	# If here, we've done stat or lstat for the actual file or dir,
	# therefore the filehandle '_' contains what we need.
	#
	if (-f _) {

		# Regular File Branch.
		#
		# Every file belongs to some item.  Every item is either an
		# object or, if improperly encapsulated, part of an object.
		# If we encounter a file and we're not 'in_item', then
		# it's not properly encapsulated; otherwise, our file
		# gets counted as part of the current item's stats.
		#
		#xxxxx put this back in _after_ processing node (during
		# unvisit:  if ($wpname =~ m@^.*$R/(.*/)?pairtree.*$@) {
		#	-prune
		#}
		if ($in_item) {
			# yyy add size to stacked object
			$curobj{'bytes'} += (-s _);
			$curobj{'streams'}++;
			#print "cobjbytes=$curobj{'bytes'}, cobjstreams=",
			#	$curobj{'streams'}, "\n";
		#	-fprintf $altout 'IN %p %s\n'
		#	$noprune
		}
		else {
			# XXX create item, not properly encapsulated,
			#     in which to put the file
		 	print "$pdname UF $tpname\n";
		#if ($wpname =~ m@^.*$R/$P/[^/]+$@) {
		#	#print "m@.*$R/$P/[^/]+@: $_\n";
		#	# yyy add item to stacked object top level,
		#	#     flag encap err
		#	# yyy add size to stacked object
		#	-fprintf $altout 'UF %h %s\n'
		}
		return;
	}
	elsif (! -d _) {

		# Non-regular file, non-directory Branch.
		#
		$irregularcount++;
		# xxxx can't under follow_fast, _ caches stat results; can't I
		# get the file types (to count)  without doing another stat?
		return;
	}

	# Directory (or symlink) Branch.
	#
	# If we're here we know that we have a directory (-d _).

	# Now, look at the form of pathname.
	#
	#xxxxx put this back in _after_ processing node (during
	# unvisit: if ($wpname =~ m@^.*$R/(.*/)?pairtree.*$@) {
	#	-prune
	#	$top = mkstackent($pdname);
	#	push(@ppstack, $top);
	#}

	# XXX add re qualifier so Perl knows re's not changing
	# if we've hit what might be a regular object dir...
	if ($wpname =~ m@^.*$R/($P/)?[^/]{$pairp1,}$@) {

		# We're at an item directory; hopefully it's a properly
		# encapsulated object, but we won't know until all of its
		# peers have been seen.  So we "start" new current item
		# after first closing any previously open item.  It is a
		# fatal error if any previous item is either not at the
		# same level or not closed (fatal because our assumptions
		# about the algorithm may be wrong).
		#
		if ($ci_ppath eq '') {		# previous item was closed
			$ci_ppath = $pdname;
		}
		elsif ($ci_ppath eq $pdname) {	# still open at the same level

			# Need to close previous item and store on stack
			push(@{$top->{'items'}}, {	# push, later shift
				'ppath' => $ci_ppath,
				'wpname' => $ci_wpname,
				'octets' => $ci_octets,
				'streams' => $ci_streams,
			});
		}
		else {
			die("in $pdname, previous item '$ci_wpname' "
				. "wasn't closed");
		}

		# Initialize new item.  $ci_ppath already set correctly.
		#
		$ci_wpname = $wpname;
		$ci_octets = $ci_streams = 0;

		$top = mkstackent($wpname);	# xxx PM?
		push(@ppstack, $top);

		# yyy compare pdname to stack top.
		#     if pdname is same as stack top, {add item
		#     to list contained in stack top, flag encaperr}
		#     elsif pdname is not superstring of stack top {
		#     we've just closed off a ppath and we need
		#     to pop the stack top and report (a) proper
		#     or improper encapsulation (#items > 1 or
		#     any file item) and (b) accumulated oxum (if
		#     no items, report EP empty ppath.}
		#     In any case, push curr ppath as new stack
		#     top and add item to list at stack top, but
		#     flag encap err if PM err)
		#     (at end, report stack top)
		# start new object; but end previous object first
		# form: ppath, EncapErr, bytes, streams
		print "$pdname NS $tpname\n";
		#	-fprintf $altout 'START %h 0\n'
		#	$noprune
	}
	elsif ($wpname =~ m@^.*$R/$P$@) {

		# Extending the ppath, no item impact.
		#
		$top = mkstackent($wpname);
		push(@ppstack, $top);

		# yyy see above
		#	-empty
		#	-printf '%p EP -\n'
	}
	# $pair, $pairm1, $pairp1
	elsif ($wpname =~
	    m@^.*$R/([^/]{$pair}/)*[^/]{1,$pairm1}/[^/]{1,$pair}$@) {

		# We have a short directory following the end of a ppath.
		# This means a Post-Morty warning and starts a new item.

		# yyy [combine with NS regexp and do similarly???]
		# xxx push dir node
#	XXXXXXXXXXXXX check and close any current item
		print "$pdname PM $tpname\n";
		$top = mkstackent($wpname);
		#push(@{$top->{'items'}}, $_);
		push(@ppstack, $top);
		#	-fprintf $altout 'START %h 0\n'
		#	$noprune
	}
	else {
		$top = mkstackent($pdname);
		push(@ppstack, $top);
	}

	return;
}

use constant CI_CLOSED => 0;
use constant CI_OPEN => 1;

sub unvisit{ my( $top )=@_;

	die "can't unvisit undefined stack node"
		if (! defined($top));

	# if stack top eq current item, close out item
	# xxx maybe 'pp' should be 'wpname' for clarity
	if ($top->{'pp'} eq $ci_wpname) {
		$ci_state = CI_CLOSED;		# close
#		xxxxx flag parent so it knows there's an item, but try
#		      to avoid (optimistically) copying item onto stack
	}
	# xxxx print cur_item
	# xxxx if in item...
	print "unvisiting $top->{'pp'}, objtype=$top->{'objtype'}, ",
		"item(s)=", join(", ", @{$top->{'items'}}),
		", size=$top->{'bytes'}, ", "flag=$top->{'flag'}\n";
	for (@{$top->{'items'}}) {
		print $_->{'wpname'}, $_->{'octets'} . "." . $_->{'streams'};
	}
	return;
}

sub postnode{
	return;
}

sub newptobj{ my( $ppath, $encaperr, $bytes, $streams )=@_;

	if ($curobj{'ppath'}) {		# print record of previous obj
		print "id: $curobj{'ppath'}, $curobj{'encaperr'}, $curobj{'bytes'}.$curobj{'streams'}\n";
	}
	die("newptobj: all args must be defined")
		unless (defined($ppath) && defined($encaperr)
			&& defined($bytes) && defined($streams));
	$curobj{'ppath'} = $ppath;
	$curobj{'flag'} = $encaperr;
	$curobj{'bytes'} = $bytes;
	$curobj{'streams'} = $streams;
}

exit(0);

sub prenode{

	return () if (scalar(@_) == 0);		# no work if no items
	return @_ if ($in_object);		# no-op if inside object
	my @ground = ();
	my @objdirs = ();
	for (@_) {
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $sze)
			= stat($_);
		#if (m@^[^/]{$pairp1,}@ || S_ISREG($mode)) {	# xxx efficiency?
		if (m@^[^/]{$pairp1,}@ || -f $_) {
			push(@ground, $_);
		}
		elsif (-d $_)  {
			push(@objdirs, $_);
		}
		else {		# nothing else will be processed
			$irregularcount++;
		}
	}
	print("Ground files: ", join(", ", @ground), "\n")
		if (scalar(@ground) > 0);
	push @ground, sort(@objdirs);
	return @ground;
}

# /dev/stderr seems to be the only file name you can give to the fprintf
# action of 'find' so output from different clauses will be correctly
# interleaved.  We assume that stderr will be closed and all output
# flushed by the time the sort is finished, so when later we read
# both outputs, we won't get ahead of things. xxx say this better
#
my $altout = '/dev/stderr';

# Test for .*$R/(.*/)?pairtree.* must occur early.
#
# xxx report null: for pairtree.* case? and possibly size?
my $findexpr = qq@$verbosefind , \\
	-regex ".*$R/\\(.*/\\)?pairtree.*" \\
		-prune \\
	-o \\
	-type d \\
		-regex ".*$R/\\($PP/\\)?[^/][^/][^/]+" \\
		-printf '%h NS %f\\n' \\
		-fprintf $altout 'START %h 0\\n' \\
		$noprune \\
	-o \\
	-type d \\
		-regex ".*$R/$PP" \\
		-empty \\
		-printf '%p EP -\\n' \\
	-o \\
	-type f \\
		-regex ".*$R/$PP/[^/]+" \\
		-printf '%h UF %f\\n' \\
		-fprintf $altout 'UF %h %s\\n' \\
	-o \\
	-type d \\
		-regex ".*$R/\\([^/][^/]/\\)*[^/]/[^/][^/]?" \\
		-printf '%h PM %f\\n' \\
		-fprintf $altout 'START %h 0\\n' \\
		$noprune \\
	-o \\
	-type f \\
		-fprintf $altout 'IN %p %s\\n' \\
		$noprune \\
@;

#XXXXX yuck.  I may not be able to size improperly unencapsulated files
#  with 'find'

# The -type f test to get filesizes should occur after the UF file test
# XXX move up to first test? for efficiency?

#print "findexpr=$findexpr\n";

# xxx change pt_z to a mktemp, in case two scans are going at once
my $szfile = 'pt_z';

open(FIND, "find $tree $findexpr 2>$szfile | sort |")
	|| die("can't start find");

open(SIZES, "< $szfile") || die("can't open size file");

my $defsize = '(:unas)';		# xxx needed?
my ($sztype, $which, $size) = ('', '', 0);
my ($ptbcount, $ptfcount) = (0, 0);

sub getsizeline{
	$_ = <SIZES>;
	die("Error: unexpected size line format: $_")
		if (! /^(\S+) (\S+) (.*)/);
	return ($1, $2, $3);		# $sztype, $which, $size
}

sub getsize{ my( $ppath )=@_;

	my ($ppbcount, $ppfcount);

	# Much depends on the assumption that we're called
	# with a ppath that we are "at" in the sizes file due to
	# lookahead.  We initialize late (first call), since no input
	# will be ready for a while.  With luck the input stream will
	# be completely defined by the time we ask for the first line.
	# The line should be of type START or UF; lines of type IN we
	# should have read through until we encounter a line not of
	# type IN (always preceded by START).
	#
	if (! $sztype) {		# lazy initialization step
		($sztype, $which, $size) = getsizeline();
	}

	# Check that the $ppath we're called with matches the current
	# size line.  The check depends on the $sztype.  Remember:
	#	START %h 0	(for types NS and PM)
	#	UF %h %s	(our $ppath _is_ %h)
	#	IN %p %s	(our $ppath is contained in %p)
	# UF can be followed by START at same level (UG)
	# START can be followed by START at same level (UG)
	# xxx all these string comparisons... more efficient with ints?
	die("unexpected size line type: $sztype")
		unless ($sztype eq "START" || $sztype eq "UF");
	die("didn't find $ppath in triple: $sztype, $which, $size")
		if ($which ne $ppath);
	$ppbcount = $size;		# initialize
	$ppfcount = ($sztype eq "UF" ? 1 : 0);
	while (1) {
		($sztype, $which, $size) = getsizeline();

		if ($sztype eq "IN" && $which =~ /^$ppath/) {
			$ppbcount += $size;
		}
		elsif ($sztype eq "START") {
			last if ($which ne $ppath);
		}
		elsif ($sztype eq "UF") {
			last if ($which ne $ppath);
			$ppbcount += $size;
		}
		else {
			die("unexpected triple in size run for $ppath: "
				. "$sztype, $which, $size");
		}
		$ppfcount++;		# another file counted
	}

	# If we're here, we have total size for the given $ppath.
	# Before returning, update the overall byte and file counts
	# for the pairtree.
	#
	$ptbcount += $ppbcount;
	$ptfcount += $ppfcount;

	return "$ppbcount.$ppfcount";

	# xxxx
	#    find $f -type f | sed "s/.*/'&'/" | xargs stat -t | \
	#        awk -v f=$f '{s += $2} END {printf "%s.%s %s\n", s, NR, f}'
}

# xxx get the path right for this file
open(FIX, "> pt_fix") || warn("xxx can't open fix file");

my ($pp, $found, $type, $object);
$pp = $found = $type = $object = '';
my ($prevpp, $prevfound, $prevtype);
my $done = 0;
my $encaperrs = 0;
my $encapoks = 0;
my $emptyppaths = 0;
my $sizestr = '(:unas)';
my $msg = '';
my $verbose = 0;

# Process the 'find' output lines for objects and look for anomalies.
# Can't conclude about unencapsulated objects until we're past the
# object (this requires sort to cluster candidate objects), which means
# that we always know what the previous line and current line have on them.
#
while (1) {
	$prevpp = $pp;
	$prevfound = $found;
	$prevtype = $type;

	$_ = <FIND>;
	if (defined($_)) {
		chomp;
		if (! /^(\S+) (\S+) (.*)/) {
			# a "show all" line; pass thru
			#print "xxx: $_\n";
			next;
		}
		($pp, $type, $found) = ($1, $2, $3);
		print "Verbose: $_\n" if ($verbose);
		if ($type eq "EP") {
			# This is the only type of "found" item that doesn't
			# correspond to an object, so we can deal with it
			# without waiting for the next line to tell us what
			# it is.  We still have to fall through for the
			# sake of what encountering this item means for our
			# deduction about previous line's role, ie, we can't
			# just short cut to the next iteration with 'next;'
			#
			print "null: $pp\n";
			print FIX "null: $pp\n";
			$emptyppaths++;
		}
	}
	else {		# EOF reached -- this will be last time thru loop
		# When EOF is found, want $pp empty for one last run through
		# loop in order to properly eject final line.
		$pp = '';	# want $pp empty for last run
		$_ = '';	# want $_ defined in case of debug print
		$done = 1;
	}

	# Report is one-line per object.  Line format is one of two types
	# ok: id|filename|size|path
	# warn: id|something|size|path|message

	# This is the main part of the loop.  Normally, there would be
	# one line per object, but in the presence of encapsulation errors
	# there will be more than one line having the same ppath.  Because
	# the input was sorted first, we know that any such lines will be
	# clustered in a group, and all we have to do is detect when we
	# enter a group (sharing a ppath) and leave a group.  We do this
	# by processing the current line while remembering the previous
	# line.  There are two states: "in object" ($object ne '') or not
	# "in object" ($object eq '').
	#
	if ($object) {				# if "in object"
		if ($pp eq $prevpp) {		#    and ppath is same
			# stay "in object" and add to existing object
			$object .= " $found";
		}
		else {				# else leave object
			# dump and zero out object in preparation for another
			# xxx write fixit script to create temp dir, move
			# stuff into it, then rename to 'obj'
			$sizestr = getsize($prevpp);
			$msg = "warn: " . ppath2id($prevpp) .
				" | UG $object | " .
				$sizestr . " | $prevpp | " . 
				"unencapsulated file/dir group\n";
			print $msg;
			print FIX $msg;
			$object = "";
			$encaperrs++;
		}
	}
	else {					# if not "in object"
		#print "pp=$pp, prevpp=$prevpp, $_\n";
		if ($pp eq $prevpp) {		#    and ppath is same
			# then start new object
			$object = "$prevfound $found";
		}
		# else not entering an object; check UF and PM cases
		elsif ($prevtype eq "UF" || $prevtype eq "PM") {
			# offer to encapusulate a lone file
			$sizestr = getsize($prevpp);
			$msg = "warn: " . ppath2id($prevpp) .
				" | $prevtype $prevfound | " .
				$sizestr . " | $prevpp | " .
				($prevtype eq "UF" ? "unencapsulated file" :
				    "encapsulating directory name too short")
				. "\n";
			print $msg;
			print FIX $msg;
			$encaperrs++;
		}
		# else in mainstream case, except line 1 ($prevtype eq '')
		# XXX explain why EP needs to run through and can't
		# short cut "next" the loop
		elsif ($prevtype && $prevtype ne "EP") {
			$sizestr = getsize($prevpp);
			print "ok: ", ppath2id($prevpp), " | $prevfound | ",
				$sizestr, " | $prevpp\n";
			$encapoks++;
		}
	}
	last
		if ($done);
}

close(FIND);
close(FIX);
close(SIZES);

my $objcount = $encapoks + $encaperrs;

print "$objcount objects, including $encaperrs encapsulation warnings.  ";
print "There are $emptyppaths empty pairpaths\n";

# XXXX make sure to declare/catch /be/nt/o/r/ as improper encapsulation
