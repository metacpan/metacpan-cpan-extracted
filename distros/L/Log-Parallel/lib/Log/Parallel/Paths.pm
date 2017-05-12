
package Log::Parallel::Paths;

use strict;
use warnings;
use Carp;
require Exporter;
use Eval::LineNumbers qw(eval_line_numbers);

our @ISA = qw(Exporter);
our @EXPORT = qw(path_to_shell_glob path_to_regex path_to_filename);

my $debug = 0;

sub path_to_filename
{
	my ($raw, %data) = @_;

	my %formats = (
		BUCKET		=> '%05d',
		SOURCE_BKT	=> '%05d',
		YYYY		=> '%04d',
		MM		=> '%02d',
		DD		=> '%02d',
		HH		=> '%02d',
		FROM_YYYY	=> '%04d',
		FROM_MM		=> '%02d',
		FROM_DD		=> '%02d',
	);

	my $path = $raw;

	$path =~ s/%([A-Z_]+)%/do { 
		confess "No %$1% data element defined" unless defined $data{$1}; 
		my $format = $formats{$1} || "%s";
		my $data = $data{$1};
		$data =~ s{ }{-}g;
		sprintf($format, $data);
	}/ge;

	print "path_to_filename($raw) = $path\n" if $debug;

	return $path;
}

sub path_to_shell_glob
{
	my ($path) = @_;
	my $orig = $path;

	$path =~ s/%BUCKET%/[0-9][0-9][0-9][0-9][0-9]/g;	# buckets are five digits
	$path =~ s/%SOURCE_BKT%/[0-9][0-9][0-9][0-9][0-9]/g;	# buckets are five digits
	$path =~ s/%YYYY%/20[0-9][0-9]/g;  			# will stop working in 2100 !
	$path =~ s/%MM%/[01][0-9]/g;
	$path =~ s/%DD%/[0-3][0-9]/g;
	$path =~ s/%HH%/[0-3][0-9]/g;
	$path =~ s/%FROM_YYYY%/20[0-9][0-9]/g;  		# will stop working in 2100 !
	$path =~ s/%FROM_MM%/[01][0-9]/g;
	$path =~ s/%FROM_DD%/[0-3][0-9]/g;
	$path =~ s/%\w*=.*?%/*/g;
	$path =~ s/%%%/%/g;
	die $path if $path =~ /%/;

	print "path_to_shell_glob($orig) = $path\n" if $debug;

	return $path;
}

sub alternates
{
	my ($alts) = @_;
	my @terms = split(/,/, $alts, -1);
	return "(?:" . join('|', map { "\Q$_\E" } @terms) . ")";
}

sub path_to_regex
{
	my ($path, $c) = @_;

	my $orig = $path;

	$c = 1 unless $c;
	my @var_list;
	my %canned = (
		BUCKET		=> qr/\d{5}/,
		SOURCE_BKT	=> qr/\d{5}/,
		YYYY		=> qr/\d{4}/,
		MM		=> qr/\d\d/,
		DD		=> qr/\d\d/,
		HH		=> qr/\d\d/,
		FROM_YYYY	=> qr/\d{4}/,
		FROM_MM		=> qr/\d\d/,
		FROM_DD		=> qr/\d\d/,
		DURATION	=> qr/(?:\d+(?:day|week|month|quarter|year)|(?:daily|weekly|monthly|quarterly|yearly))/,
	);
	my %reserved = (
		%canned,
		size		=> 1,
		timestr		=> 1,
		timezone 	=> 1,
		file		=> 1,
	);

	my $replace = sub {
		my $old = shift;
		if ($canned{$old}) {
			push(@var_list, $old);
			return qr/($canned{$old})/;
		} elsif ($old =~ /(\w*)=(.*)/) {
			die if $reserved{$old};
			if (defined($1) && $1 ne '') {
				push(@var_list, $1);
			} else {
				push(@var_list, 's k i p');
			}
			return qr/($2)/;
		} else {
			die "No path substitution for '%$old%'\n";
		}
	};

	# everything but %stuff% should be literal
	$path =~ s/
			(?:
				(?:
					%([^%]*)%
				)
			|
				(
					[^-%a-z0-9A-Z_{}]+
					(?:
						%
						(?!
							.*%
						)
					)?
					|
					(?:
						%
						(?!
							.*%
						)
					)
					[^-%a-z0-9A-Z_{}]*
				)
			|
				\{([^{}]+)\}
			|
				([^-a-z0-9A-Z_]+)
			)
		/
			$1 		? $replace->($1)
			: defined($2)	? $2
			: defined($3)	? alternates($3) 
			: "\Q$4\E"
		/gsex;
	$path =~ s/%%%/%/g;

	$path .= '$';

	# handle %YYYY% and such specially
	# $path =~ s/%(YYYY|MM|DD|HH|[a-z]\w*=[^%]*?)%/$replace->($1)/ge;

	my $code = eval_line_numbers(<<'END_CODE');
		sub {
			return (
END_CODE
	for my $v (@var_list) {
		$code .= "\t\t\t\t'$v' => \$$c,\n"
			unless $v eq 's k i p';
		$c++;
	}
	$code .= eval_line_numbers(<<'END_CODE2');
			);
		};
END_CODE2
	my $sub = eval $code;
	die $@ if $@;

	print "path to regex($orig) = $path\n" if $debug;

	return (qr/$path/, $sub);
}

1;

__END__

=head1 NAME

Log::Parallel::Paths - variable expansion, capture, globs, regex on filenames

=head1 SYNOPSIS

 use Log::Parallel::Paths;

 $filename = path_to_filename($spec, %data);

 $glob = path_to_shell_glob($spec);

 ($regex, $closure) = path_to_regex($spec);

=head1 DESCRIPTION

Within the batch log processing system, L<Log::Parallel>, filenames are 
specified with magic cookies embeded in them.  For example:

  path: '%DATADIR%/%YYYY%/%MM%/%DD%/%JOBNAME%.%DURATION%.%BUCKET%.%SOURCE_BKT%.gz'

These magic cookes need to be expanded in various way: for making a new filename
(C<path_to_filename()>);
for handing to a shell to glob to look for files (C<path_to_shell_glob()>);
for a perl regular expression to extract these parameters from a filename
(C<path_to_regex()>).

The magic cookies that are recognized are:

=over

=item BUCKET

I<Format: %05d>.  The bucket number for this file.

=item SOURCE_BKT

I<Format: %05d>.  When one job writes to buckets, the next job
will process each bucket separately, often in parallel.  The new bucket
for a bit of data may be different than the old bucket.  The C<SOURCE_BKT>
is the old bucket number.

=item YYYY

I<Format: %04d>.  Year part of the end date for this data.

=item MM

I<Format: %02d>.  Month part of the end date for this data.

=item DD

I<Format: %02>.  Day part of the end date for this data.

=item HH

I<Format: %02>.  Hour part of time.

=item FROM_YYYY

I<Format: %04d>.  Year part of the beginning date for this data.

=item FROM_MM

I<Format: %02d>.  Month part of the beginning date for this data.

=item FROM_DD

I<Format: %02>.  Day part of the beginning date for this data.

=item DURATION

I<Format: %s>.  C<day>, C<daily>, C<week>, C<weekly>, etc.

=item %%%

The C<%> character.

=item %word=regex%

The specification can have user specified formats.   For C<path_to_regex()>, the
key for the bit matched by the I<regex> is I<word>.

=back

The C<path_to_regex()> function returns both a regular expression and a bit of
code that will translate the positional matches (C<$1>, C<$2>, etc) into 
key/value pairs.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

