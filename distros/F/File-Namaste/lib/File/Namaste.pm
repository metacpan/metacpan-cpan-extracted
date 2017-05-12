package File::Namaste;

use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION;
$VERSION = sprintf "%d.%02d", q$Name: Release-1-04 $ =~ /Release-(\d+)-(\d+)/;

our @EXPORT = qw();
#our @EXPORT_OK = qw();
our @EXPORT_OK = qw(
	nam_get nam_add nam_elide
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);
#our @EXPORT_OK = qw();

use File::Spec::Functions;		# we want catfile()

# Default setting for tranformations is non-portable for Unix.
our $portable_default = grep(/Win32|OS2/i, @File::Spec::ISA);

# Instead of "use File::Value;" for a small dependency, use this
# abbreviated version of "raw" File::Value::file_value() (that we
# also use commonly in test scripts).
#
sub filval { my( $file, $value )=@_;	# $file must begin with >, <, or >>
	if ($file =~ /^\s*>>?/) {
		open(OUT, $file)	or return "$file: $!";
		my $r = print OUT $value;
		close(OUT);		return ($r ? '' : "write failed: $!");
	} # If we get here, we're doing file-to-value case.
	open(IN, $file)		or return "$file: $!";
	local $/;		$_[1] = <IN>;	# slurp mode (entire file)
	close(IN);		return '';
}

# xxx not yet doing unicode or i18n
# only first arg required
# return tvalue given fvalue
sub nam_tvalue { my( $fvalue, $portable, $max, $ellipsis )=@_;

	defined($portable)	or $portable = $portable_default;
	my $tvalue = $fvalue;
	$tvalue =~ s,/,=,g;
	$tvalue =~ s,\s+, ,g;
	$tvalue =~ s,\p{IsC},?,g;	# control characters

	$portable and			# more portable (Win32) mapping
		$tvalue =~ tr {"*/:<>?|\\}{.};

	return nam_elide($tvalue, $max, $ellipsis);
}

# Ordered list of labels, mostly kernel element names
#   yyy should this be coming from ERC module, or is that creating
#   a big dependency hurdle for a sliver of functionality?
our @namaste_labels = qw(
	dir_type
	who
	what
	when
	where
	how
	why
	huh
);

sub num2label { my $num = shift;

	my $last = $#namaste_labels;
	$num =~ s/^(\d+).*/$1/;				# forgive, eg, 3=foo
	$num =~ /\D/ || $num < 0 || $num > $last and
		return $namaste_labels[$last];		# last label
		# last label doubles as unknown (huh?) if number is bad
	return $namaste_labels[$num];			# normal return
}


# xxx should create shadow tag files with highly deterministic names?
#     easier for a machine to fine a specific element
my $dtname = ".dir_type";	# canonical name of directory type file
# xxx .=dir_type
# xxx .=how
# xxx .=huh
# xxx .=what
# xxx .=when
# xxx .=where
# xxx .=who
# xxx .=why

# xxx to do
# N means create N=...
# .N means create or add to .=wh{o,at,en,ere}
# N. means do both N and .N

# $num and $fvalue required
# returns empty string on success, otherwise a diagnostic
sub nam_add { my( $dir, $portable, $num, $fvalue, $max, $ellipsis )=@_;

	return 0
		if (! defined($num) || ! defined($fvalue));

	$dir ||= "";
	#$dir = catfile($dir, "")	# add portable separator
	#	if $dir;		# (eg, slash) if there's a dir name

	#my $fname = $dir . $dtname;	# path to .dir_type, if needed
	my $fname = catfile($dir, $dtname);	# path to .dir_type, if needed
	my $tvalue = nam_tvalue($fvalue, $portable, $max, $ellipsis);
	# ".0" means set .dir_type also; "." means only set .dir_type
	if ($num =~ s/^\.0/0/ || $num eq ".") {
		# "append only" supports multi-typing in .dir_type, so
		# caller must remove .dir_type to re-set (see "nam" script)
		# right now $fname contains catfile($dir, $dtname)
		my $ret = filval(">>$fname", $fvalue);
		return $ret		# return if error or only .dir_type
			if $ret || $num eq ".";
	}

	#$fname = "$dir$num=$tvalue";
	$fname = catfile($dir, "$num=$tvalue");
		#nam_tvalue($fvalue, $portable, $max, $ellipsis);
		# why is this sometimes null?

	return filval(">$fname", $fvalue);
}

use File::Glob ':glob';		# standard use of module, which we need
				# as vanilla glob won't match whitespace

# first arg is directory, remaining args give numbers to fetch;
# no args means return all
# args can be file globs
# returns array of number/fname/value triples (every third elem is number)
sub nam_get {

	my $dir = shift @_;

	$dir ||= "";
	#$dir = catfile($dir, "")	# add portable separator
	#	if $dir;		# (eg, slash) if there's a dir name
	#my $dir_type = $dir . $dtname;	# path to .dir_type, if needed
	my $dir_type = catfile($dir, $dtname);	# path to .dir_type, if needed

	my (@in, @out);
	if ($#_ < 0) {			# if no args, get all files starting
		# Surprisingly, with bsd_glob a / separator works in Win32
		@in = bsd_glob("$dir/[0-9]=*");	# so no need for catfile()
	#	@in = bsd_glob(catfile($dir, '[0-9]=*'));	# "<digit>=..."
		-e $dir_type and		# since we're getting all,
			unshift @in, $dir_type;	# if it exists, add .dir_type
	}
	else {				# else do globs for each arg
		while (defined(my $n = shift @_)) {	# next number
			if (($n =~ s/^\.0/0/ || $n eq ".") && -e $dir_type) {
				# if requested and it exists, add .dir_type
				push @in, $dir_type;
				next		# next if only .dir_type
					if $n eq ".";
			}
			push @in, bsd_glob("$dir/$n=*");
			#push @in, bsd_glob(catfile($dir, $n . '=*'));
		}
	}
	# Now create the output array.
	my ($number, $fname, $fvalue, $status, $regex);
	while (defined($fname = shift(@in))) {

		$status = filval("<$fname", $fvalue);

		#($number) = ($fname =~ m{^$dir(\d*)=});
		#$regex = catfile($dir, '(\d*)=');

#		# ask for a dummy file 'x' in order to get a dir separator
#		#
#		$regex = catfile($dir, 'x');	# separator might be \ or /
# temporary crap to flush out bug in Windows version
#$regex =~ s,/,\\,g;
#$fname =~ s,/,\\,g;
#		$regex =~ s/\\/\\\\/g;	# preserve any \ separators for regex
#
#		# replace dummy file with pattern we want, leaving separator
#		#
#		$regex =~ s/x$/(\\d*)=/;	# replace with literal pattern
#print "xxx regex=$regex\n";
#		($number) = ($fname =~ m{^$regex});
#print "xxx number=$number, fname=$fname\n";
		($number) = ($fname =~ m{^$dir/(\d*)=});

		# if there's no number matched, it may be for .dir_type,
		# in which case use "." for number, else give up with ""
		#
#		$regex = catfile($dir, $dtname);
#$regex =~ s,/,\\,g;
#		$regex =~ s/\\/\\\\/g;	# preserve any \ separators for regex
#print "xxx dtname=$dtname, regex=$regex\n";
		#$number = ($fname =~ m{^$dir$dtname} ? "." : "")
		# yyy matching on $dtname is imperfect if it contains
		#     a '.' -- eg, ".dir_type" matches "adir_type"
		# contains a
		#$number = ($fname =~ m{^$regex} ? "." : "")

		# \Q prevents chars in $dtname (eg, '.') being used in regex
		$number = ($fname =~ m{^$dir/\Q$dtname\E} ? "." : "")
			if (! defined($number));

		push @out, $number, $fname, ($status ? $status : $fvalue);
	}
	return @out;
}

# xxx unicode friendly??
our $max_default = 16;		# is there some sense to this? xxx use
				# fraction of display width maybe?

sub nam_elide { my( $s, $max, $ellipsis )=@_;

	$s	or return undef;
	# $max can be zero (0) so that nam_add() can ask for no elision.
	defined($max)		or $max = $max_default;
	$max !~ /^(\d+)([esmESM]*)([+-]\d+%?)?$/ and
		return undef;
	my ($maxlen, $where, $tweak) = ($1, $2, $3);

	$where ||= "e";
	$where = lc($where);

	$ellipsis ||= ($where eq "m" ? "..." : "..");
	my $elen = length($ellipsis);

	my ($side, $offset, $percent);		# xxx only used for "m"?
	if (defined($tweak)) {
		($side, $offset, $percent) = ($tweak =~ /^([+-])(\d+)(%?)$/);
	}
	$side ||= ""; $offset ||= 0; $percent ||= "";
	# XXXXX finish this! print "side=$side, n=$offset, p=$percent\n";

	my $slen = length($s);
	return $s
		if ($slen <= $maxlen || $maxlen == 0);	# doesn't need elision

	my $re;		# we will create a regex to edit the string
	# length of orig string after that will be left after edit
	my $left = $maxlen - $elen;

	my $retval = $s;
	# Example: if $left is 5, then
	#   if "e" then s/^(.....).*$/$1$ellipsis/
	#   if "s" then s/^.*(.....)$/$ellipsis$1/
	#   if "m" then s/^.*(...).*(..)$/$1$ellipsis$2/
	# In order to make '.' match \n, we use s///s ('s' modifier).
	if ($where eq "m") {
		# if middle, we split the string
		my $half = int($left / 2);
		$half += 1	# bias larger half to front if $left is odd
			if ($half > $left - $half);	# xxx test
		$re = "^(" . ("." x $half) . ").*("
			. ("." x ($left - $half)) . ")\$";
			# $left - $half might be zero, but this still works
		$retval =~ s/$re/$1$ellipsis$2/s;
	}
	else {
		my $dots = "." x $left;
		$re = ($where eq "e" ? "^($dots).*\$" : "^.*($dots)\$");
		if ($where eq "e") {
			$retval =~ s/$re/$1$ellipsis/s;
		}
		else {			# else "s"
			$retval =~ s/$re/$ellipsis$1/s;
		}
	}
	return $retval;
}

1;

__END__

=head1 NAME

File::Namaste - routines to manage NAMe-AS-TExt tags

=head1 SYNOPSIS

 use File::Namaste;  # to import routines into a Perl script

 $stat = nam_add($dir, $portable, $number, $fvalue, $max, $ellipsis);
                     # Return empty string on success, else an error
                     # message.  The first four arguments required;
                     # remaining args are passed to nam_elide().
                     # Uses $dir or the current directory.  Specify
		     # $portable as undef to get best character mapping
		     # for the platform.  To request the more general
		     # Win32 mapping, set $portable to 1.

 # Example: set the directory type and title tag files.
 ($msg = nam_add(0, 0, "dflat_0.4")
          || nam_add(2, 0, "Crime and Punishment"))
     and die("nam_add: $msg\n");

 @num_nam_val_triples = nam_get($dir, $filenameglob, ...);
                     # Return an array of number/filename/value triples
                     # (eg, every 3rd elem is number).  Args give numbers
                     # (as file globs) to fetch # (eg, "0" or "[1-4]")
                     # and no args is same as "[0-9]".  Uses $dir or the
                     # current directory.

 # Example: fetch all namaste tags and print.
 my @nnv = nam_get();
 while (defined($num = shift(@nnv))) {  # first of triple is tag number;
     $fname = shift(@nnv);              # second is filename derived...
     $fvalue = shift(@nnv);             # from third (the full value)
     print "Tag $num (from $fname): $fvalue\n";
 }

 $transformed_value =       # filename-safe transform of metadata value
        nam_tvalue( $full_value, $portable, $max, $ellipsis);

 print nam_elide($title, "${displaywidth}m")  # Example: fit long title
        if length($title) > $displaywidth;    # by eliding from middle

=head1 DESCRIPTION

This is very brief documentation for the B<Namaste> Perl module, which
implements the Namaste (Name as Text) convention for containing a data
element completely within the content of a file, using as filename an
approximation of the value preceded by a numeric tag.

=head2 nam_elide( $s, $max, $ellipsis )

Take input string $s and return a shorter string with an ellipsis marking
what was deleted.  The optional $max parameter (default 16) specifies the
maximum length of the returned string, and may optionally be followed by
a letter indicating where the deletion should take place:  'e' means the
end of the string (default), 's' the start of the string, and 'm' the
middle of the string.  The optional $ellipsis parameter specifies how the
deleted characters will be represented; it defaults to ".." for 'e' or 's'
deletion, and to "..." for 'm' deletion.

=head1 SEE ALSO

Directory Description with Namaste Tags
    L<https://confluence.ucop.edu/display/Curation/Namaste>

L<nam(1)>

=head1 HISTORY

This is a beta version of Namaste tools.  It is written in Perl.

=head1 AUTHOR

John A. Kunze I<jak at ucop dot edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 UC Regents.  Open source BSD license.

=head1 PREREQUISITES

Perl Modules: L<File::Glob>

Script Categories:

=pod SCRIPT CATEGORIES

UNIX : System_administration
