
package File::FilterFuncs;
use strict;
use warnings;
use Exporter ();
use Carp qw(croak confess);

BEGIN {
	our $VERSION = '0.53';
	$VERSION = eval $VERSION;
	our @EXPORT_OK = qw(filters filter_funcs $KEEP_LINE $IGNORE_LINE);
	our %EXPORT_TAGS = (all => [@EXPORT_OK]);
	our @ISA = qw(Exporter);
	*KEEP_LINE = \1;
	*IGNORE_LINE = \0;
}

# These are options that accept arguments.
my @arg_options = qw(binmode boutmode grepper $/);
my %arg_options = map +($_ => 1), @arg_options;

sub filters {
	local $_;
	local $/ = $/;
	my %opts = &parse_args;

	open my $in, '<', $opts{source}
		or croak("Can't open '$opts{source}' for reading: $!");
	open my $out, '>', $opts{dest}
		or croak("Can't open '$opts{dest}' for writing: $!");
	binmode $in, $opts{binmode} if $opts{binmode};
	binmode $out, $opts{boutmode} if $opts{boutmode};
	$/ = $opts{'$/'} if exists($opts{'$/'});

	NEXTLINE:
	while ($_ = <$in>) {

		foreach my $transform (@{$opts{subs}}) {
			next NEXTLINE unless $transform->();
		}
		print $out $_;
	}

	close $out or croak("Can't close '$opts{dest}'");
	close $in or croak("Can't close '$opts{source}'");

}

sub parse_args {
	local $_;
	my %hash;

	die "No source file name" unless ($_[0] && '' eq ref $_[0]);
	die "No destination file name" unless ($_[-1] && '' eq ref $_[-1]);
	$hash{source} = '' . shift;
	$hash{dest} = '' . pop;

	if ($hash{dest} eq $hash{source}) {
		die("Cannot filter '$hash{source}' onto itself.");
	}

	while (@_) {
		$_ = shift;
		if ($arg_options{$_}) {
			$hash{$_} = shift;
		} elsif ('CODE' eq ref($_)) {
		 	push @{$hash{subs}}, $_;
		}
	}

	%hash;
}

BEGIN {
	*filter_funcs = \&filters;
}



1;

