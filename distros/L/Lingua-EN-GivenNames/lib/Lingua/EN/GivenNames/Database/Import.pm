package Lingua::EN::GivenNames::Database::Import;

use feature 'say';
use parent 'Lingua::EN::GivenNames::Database';
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Data::Dumper::Concise; # For Dumper().

use DBI;

use File::Spec;

use HTML::TreeBuilder;

use Moo;

use Text::CSV;
use Text::CSV::Slurp;

use Unicode::CaseFold;  # For fc().

use Types::Standard qw/Int/;

has page_number =>
(
	default  => sub{return 1},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '1.04';

# ----------------------------------------------

sub _extract_derivation_set
{
	my($self, $sex, $file_name) = @_;
	my($root)   = HTML::TreeBuilder -> new;

	# This produces an erroneous result :-(.
	# my $content = slurp '< :raw', $file_name; # Scalar context!

	open(INX, '<', $file_name);
	binmode INX;
	my(@context) = <INX>;
	close INX;
	chomp @context;

	my($result) = $root -> parse_content(join('', @context) );

	my(@name);

	push @name, map
	{
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /gs;
		s/\xc2//gs;          # Don't you just want to throttle some bastard.
		$_ =~ s/St\. /St /g; # Simplify by removing internal full-stops from saint names.
		$_;
	} $_ -> as_text for $root -> look_down(_tag => 'li');

	# Skip add-one lines where name is like ADEN, and the lines are
	# commentary in a stand-alone <ol> <li>1...</li> <li>2...</li> </ol> set.

	@name = map{"$sex. $_"} grep {/^[A-Z][A-Z]/} @name;

	$root -> delete();

	my($out_file_name) = File::Spec -> catfile($self -> data_dir, 'derivations.raw');

	# sub import_derivations() assumes the file is sorted.
	# This really means we parsed data/*.htm in order.

	open(OUT, '>>', $out_file_name) || die "Can't open(>> $out_file_name): $!\n";
	binmode OUT;
	print OUT map{"$_\n"} sort @name;
	close OUT;

	$self -> log(debug => "Updated $out_file_name");

} # End of _extract_derivation_set.

# ----------------------------------------------

sub extract_derivations
{
	my($self) = @_;
	my($page) = $self -> page_number;

	if ($page == 1)
	{
		$page = '';
	}
	else
	{
		$page = sprintf '_%02d', $page;
	}

	my($sex)          = $self -> sex;
	my($in_file_name) = File::Spec -> catfile($self -> data_dir, "${sex}_english_names$page.htm");

	$self -> log(debug => "Extracting derivations from $in_file_name");

	$self -> _extract_derivation_set($sex, $in_file_name);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of extract_derivations.

# -----------------------------------------------

sub generate_derivation
{
	my($self, $item) = @_;

	my($s);

	# These strings use qq|...| and not "..." because $$item{meaning} contains " chars.

	if ($$item{original} eq '-')
	{
		$s = qq|$$item{kind} $$item{form}, $$item{rating} $$item{meaning}|;
	}
	else
	{
		$s = qq|$$item{kind} $$item{form} of $$item{source} $$item{original}, $$item{rating} $$item{meaning}|;
	}

	return $s;

} # End of generate_derivation.

# ----------------------------------------------

sub import_derivations
{
	my($self)       = @_;
	my($derivation) = $self -> read_derivations;
	my($duplicate)  = 0;

	# Build lists to store all tables except 'names'.
	# Lastly, process the 'names' table.

	my(@derivation);
	my($s, %seen);

	for my $item (@$derivation)
	{
		$s = $self -> generate_derivation($item);

		if ($seen{$s})
		{
			$duplicate++;

			$self -> log(debug => "Skipping duplicate: $$item{name}: $s");

			next;
		}

		$seen{"$$item{name} $s"} = 1;
		$$item{derivation}       = $s;

		push @derivation, $item;
	}

	$self -> log(debug => "Skipping $duplicate duplicate derivations");

	my($table_name) = $self -> get_table_names;

	my(%foreign_key);

	# The sort here is just to help debugging.

	for my $table (sort grep{! /name/} keys %$table_name)
	{
		$foreign_key{$table} = $self -> write_table($$table_name{$table}, [map{$$_{$table} } @derivation]);
	}

	$self -> write_names($$table_name{name}, \@derivation, \%foreign_key);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of import_derivations.

# ----------------------------------------------

sub _parse_definition
{
	my($self, $matched, $key, $pattern, $unparsable, $skip, $candidate) = @_;
	my($match) = 0;

	my($derivation); # This is a temp var.
	my($form);
	my($kind);
	my($meaning);
	my($name);
	my($original);
	my($rating);
	my($sex, $source);

	if ($candidate =~ $pattern)
	{
		# Warning: You cannot use regpexps here. They reset $1 etc.

		if ( ($key eq 'a') || ($key eq 'b') )
		{
			$form     = $4 || '';
			$kind     = $3;
			$meaning  = $8;
			$name     = $2;
			$original = $6;
			$rating   = $7;
			$sex      = $1;
			$source   = $5;
		}
		elsif ($key eq 'c')
		{
			$form     = $4;
			$kind     = $3;
			$meaning  = $6;
			$name     = $2;
			$original = '-';
			$rating   = $5;
			$sex      = $1;
			$source   = '-';
		}
		elsif ($key eq 'd')
		{
			$form     = $4;
			$kind     = $3;
			$meaning  = $7;
			$name     = $2;
			$original = $6;
			$rating   = 'meaning';
			$sex      = $1;
			$source   = $5;
		}

		# Warning: These must follow all the assignments above,
		# because they reset $1 .. $7.

		$form    =~ s/\s$//;
		$meaning =~ s/^"\s/"/;
		$meaning =~ s/[,.]"$/"/;
		$name    =~ s/\s+\(.+\)//;
		$rating  =~ s/\s$//;

		# Skip freaks which trick my 'parser'.

		if ($$unparsable{$name} || ($name !~ /^[-A-Za-z]+$/) )
		{
			# This sub is called from within a loop over regexps.
			# We only want to output this message once per name.

			$self -> log(notice => "Ignoring candidate $candidate") if (! $$skip{$name});

			$$skip{$name} = 1;
		}
		else
		{
			$match = 1;

			push @{$$matched{$key}{form} },       $form;
			push @{$$matched{$key}{kind} },       $kind;
			push @{$$matched{$key}{meaning} },    $meaning;
			push @{$$matched{$key}{name} },       $name;
			push @{$$matched{$key}{original} },   $original;
			push @{$$matched{$key}{rating} },     $rating;
			push @{$$matched{$key}{sex} },        $sex;
			push @{$$matched{$key}{source} },     $source;

			if ( ($key eq 'c') || ($key eq 'd') )
			{
				$self -> log(debug => "$key => F: $form. K: $kind. M: $meaning. N: $name. O: $original. R: $rating. S: $sex. S: $source");
			}
		}
	}

	return $match;

} # End of _parse_definition.

# ----------------------------------------------

sub parse_derivations
{
	my($self)      = @_;
	my($file_name) = File::Spec -> catfile($self -> data_dir, 'derivations.raw');

	$self -> log(debug => "Processing $file_name");

	# This produces an erroneous result :-(.
	# my(@name) = slurp '< :raw', $file_name, {chomp => 1};

	open(INX, '<', $file_name) || die "Can't open($file_name): $!\n";
	binmode INX;
	my(@derivation) = <INX>;
	close INX;
	chomp @derivation;

	my($un_file_name) = File::Spec -> catfile($self -> data_dir, 'unparsable.txt');

	open(INX, '<', $un_file_name) || die "Can't open($un_file_name): $!";
	binmode INX;
	my(@unparsable) = map{tr/a-z/A-Z/; $_} <INX>;
	close INX;
	chomp @unparsable;

	$self -> log(debug => 'Names which are currently unparsable:');
	$self -> log(debug => $_) for sort @unparsable;

	my(%unparsable);

	@unparsable{@unparsable} = (1) x @unparsable;

	my($sub_pattern_1) = <<'EOS';
Abbreviated|Anglicized|Breton|Celtic|Contracted|Diminutive|Dutch|Egyptian|Elaborated|
English|English\s+?and\s+?(?:French|German|Latin|Scottish)|
(?:(?:American|British|Early|Old)\s+?)?English|
Feminine|French|Hungarian|
Irish|Irish\s+?and\s+?Scottish\s+?Anglicized|Irish\s+?(?:Anglicized|Gaelic)|Italian|
Greek|Hebrew|Latin|Latvian|
(?:Medieval|Middle|Modern)(?:\s+?(?:English|French|Latin))?|Masculine|Modern|
Old(?:[Pp]et)?|Older|Pet|Polish|Roman\s+?Latin|Russian|
Scottish(?:\s+Anglicized)?|Short|Slovak|Spanish|Swedish|
Unisex|(?:V|v)ariant|Welsh
EOS
	my($sub_pattern_2) = <<'EOS';
(?:(?:adopted|contracted|diminutive|elaborated|feminine|pet|short|unisex|variant)?\s*?
EOS
	my($sub_pattern_3) = <<'EOS';
(?:possibly\s+?)?meaning\s*?(?:(?:both|either|simply)\s*)?
EOS
	# Note for '2 => Name' below: Beware 'NAME (Text): etc'. Also, Text can contain ':'.

	my(%pattern) =
	(
		a => qr/
			(.+?)\.\s                             # 1 => Sex.
			(.+?):\s*                             # 2 => Name.
			($sub_pattern_1)\s+?                  # 3 => Kind.
			($sub_pattern_2)                      # 4 => Form.
			(?:equivalent|form|from|spelling|use)\s+?) # 'from' is a input typo for 'form'.
			(?:of\s+?)?(.+?)\s+?                  # 5 => Source.
			(.+?)\s*?(?:,\s*?)?                   # 6 => Original.
			($sub_pattern_3)                      # 7 => Rating.
			(".+")                                # 8 => Meaning.
			/x,
		b => qr/
			(.+?)\.\s                  # 1 => Sex.
			(.+?):\s*                  # 2 => Name.
			($sub_pattern_1)\s+?       # 3 => Kind.
			(form)\s+?                 # 4 => Form.
			(?:of\s+?)(.+?\s+?.+?)\s+? # 5 => Source.
			(.+?)(?:,\s*?)?            # 6 => Original.
			($sub_pattern_3)           # 7 => Rating.
			(".+")                     # 8 => Meaning.
			/x,
		c => qr/
			(.+?)\.\s            # 1 => Sex.
			(.+?):\s*            # 2 => Name.
			($sub_pattern_1)\s+? # 3 => Kind.
			(name)\s+?           # 4 => Form.
			($sub_pattern_3)     # 5 => Rating.
			(".+")               # 6 => Meaning.
			/x,
		d => qr/
			(.+?)\.\s            # 1 => Sex.
			(.+?):\s*            # 2 => Name.
			($sub_pattern_1)\s+? # 3 => Kind.
			(form)\s+?           # 4 => Form.
			(?:of\s+?)?(.+?)\s+? # 5 => Source.
			(.+?)\s*?(?:,\s*?)?  # 6 => Original.
			(".+")               # 7 => Meaning.
			/x,
	);
	my($table_name) = $self -> get_table_names;

	# Values captured by the above regexp are stored in a set of arrayrefs.
	# The arrayref $matched{$key}{derivation} is not used.

	my(%matched);

	for my $key (keys %pattern)
	{
		$matched{$key}{$_} = [] for (keys %$table_name);
	}

	my($match_count) = 0;

	my($found);
	my(@mis_match);
	my(%skip);

	for my $candidate (@derivation)
	{
		$found = 0;

		for my $key (sort keys %pattern)
		{
			if ($self -> _parse_definition(\%matched, $key, $pattern{$key}, \%unparsable, \%skip, $candidate) )
			{
				$found = $key;

				last;
			}
		}

		if ($found)
		{
			$match_count++;
		}
		else
		{
			# Rearrange $candidate so the actual name is at the end,
			# and the prefix is 'notice: ...'.
			# This means we can sort the output looking for patterns to match.

			if ($candidate =~ /(.+?):\s*(.+)/s)
			{
				$candidate = "1: $2 | $1";
			}
			elsif ($candidate !~ /^[A-Z]{2,}/)
			{
				$candidate = "2: $candidate";
			}
			else
			{
				$candidate = "3: $candidate";
			}

			push @mis_match, $candidate;
		}
	}

	my($mismatch_count)   = scalar @derivation - $match_count;
	my($mismatch_message) = "Target count: " . scalar @derivation . ". Match count: $match_count. Mis-match count: $mismatch_count";

	$self -> log(debug => $mismatch_message);

	my($csv) = Text::CSV -> new({binary => 1});

	my(@column);
	my(@row);

	for my $key (keys %pattern)
	{
		# Loop over all stacks. Any field besides kind could be used.

		for my $index (0 .. $#{$matched{$key}{kind} })
		{
			@column = ();

			for my $set (sort grep{! /derivation/} keys %$table_name)
			{
				push @column, $matched{$key}{$set}[$index];
			}

			die "Can't combine fields into a CSV string\n" if (! $csv -> combine(@column) );

			push @row, $csv -> string;
		}
	}

	my($derived_file_name) = File::Spec -> catfile($self -> data_dir, 'derivations.csv');

	open(OUT, '>>', $derived_file_name) || die "Can't open($derived_file_name): $!\n";
	binmode OUT;
	print OUT join(',', sort grep{! /derivation/} keys %$table_name), "\n";
	print OUT map{"$_\n"} @row;
	close OUT;

	$self -> log(debug => "Updated $derived_file_name");

	my($mismatch_file_name) = File::Spec -> catfile($self -> data_dir, 'mismatches.log');

	open(OUT, '>>', $mismatch_file_name) || die "Can't open($mismatch_file_name): $!\n";
	binmode OUT;
	print OUT map{"$_\n"} @mis_match;
	close OUT;

	$self -> log(debug => "Updated $mismatch_file_name");

	my($parse_file_name) = File::Spec -> catfile($self -> data_dir, 'parse.log');

	open(OUT, '>>', $parse_file_name) || die "Can't open($parse_file_name): $!\n";
	print OUT "Updated $file_name. $mismatch_message. \n";
	close OUT;

	$self -> log(debug => "Updated $parse_file_name");

	# Return 0 for success and 1 for failure.

	return 0;

} # End of parse_derivations.

# ----------------------------------------------

sub read_derivations
{
	my($self)      = @_;
	my($file_name) = File::Spec -> catfile($self -> data_dir, 'derivations.csv');
	my($line)      = Text::CSV::Slurp -> new -> load(file => $file_name, allow_whitespace => 1);
	my($count)     = 0;

	$self -> log(debug => "File: $file_name. Derivation count: " . scalar @$line);

	my(%derivation);

	for my $field (@$line)
	{
		$count++;

		for my $key (keys %$field)
		{
			if (! $$field{$key})
			{
				$self -> log(debug => join(', ', map{"$_ => $$field{$_}"} sort keys %$field) );

				die "$count: Missing value for key $key";
			}

			$derivation{$key}                 = {} if (! $derivation{$key});
			$derivation{$key}{$$field{$key} } = 1;
		}
	}

	$self -> validate_derivations($file_name, \%derivation);

	return $line;

} # End of read_derivations.

# -----------------------------------------------

sub validate_derivations
{
	my($self, $file_name, $derivation) = @_;
	my($expected_key) = $self -> get_table_names;

	for my $key (sort keys %$derivation)
	{
		die "Input file: $file_name. Unexpected key: $key. \n" if (! $$expected_key{$key});
	}

	for my $name (sort keys %{$$derivation{name} })
	{
		$self -> log(notice => "Non-ASCII name: $name") if ($name !~ /^[-A-Za-z]+$/);
	}

} # End of validate_derivations.

# -----------------------------------------------

sub write_names
{
	my($self, $table, $derivation, $foreign_key) = @_;
	my($table_name) = $self -> get_table_names;

	# Convert strings to foreign keys.

	my(@data);

	for my $item (@$derivation)
	{
		for my $table (grep{! /name/} keys %$table_name)
		{
			$$item{$table} = $$foreign_key{$table}{$$item{$table} };
		}

		push @data, $item;
	}

	$self -> dbh -> do("delete from $$table_name{name}");

	my($i)   = 0;
	my($sql) = "insert into $$table_name{name} (derivation_id, form_id, kind_id, meaning_id, original_id, rating_id, sex_id, source_id, fc_name, name) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
	my($sth) = $self -> dbh -> prepare($sql) || die "Unable to prepare SQL: $sql\n";

	my($name);
	my(@record);

	for my $item (sort{$$a{name} cmp $$b{name} } @data)
	{
		$i++;

		$name = ucfirst lc $$item{name};

		@record = ($$item{derivation}, $$item{form}, $$item{kind}, $$item{meaning}, $$item{original}, $$item{rating}, $$item{sex}, $$item{source}, fc $name, $name);

		$self -> log(debug => join(', ', @record) ) if ($self -> verbose > 1);

		$sth -> execute(@record);
	}

	$sth -> finish;

	$self -> log(debug => "Saved $i entries in the $$table_name{name} table");

} # End of write_names.

# -----------------------------------------------

sub write_table
{
	my($self, $table, $item) = @_;

	my(%seen);

	$seen{$_} = 1 for @$item;

	$self -> dbh -> do("delete from $table");

	my($i)   = 0;
	my($sql) = "insert into $table (fc_name, name) values (?, ?)";
	my($sth) = $self -> dbh -> prepare($sql) || die "Unable to prepare SQL: $sql\n";

	for my $key (sort keys %seen)
	{
		$i++;

		$seen{$key} = $i;

		$sth -> execute(fc $key, $key);
	}

	$sth -> finish;

	$self -> log(debug => "Saved $i entries in the $table table");

	return {%seen};

} # End of write_table.

# -----------------------------------------------

1;

=pod

=head1 NAME

Lingua::EN::GivenNames::Database::Import - An SQLite database of derivations of English given names

=head1 Synopsis

See L<Lingua::EN::GivenNames/Synopsis> for a long synopsis.

See also L<Lingua::EN::GivenNames/How do the scripts and modules interact to produce the data?>.

=head1 Description

Documents the methods used to populate the SQLite database,
I<lingua.en.givennames.sqlite>, which ships with this distro.

See L<Lingua::EN::GivenNames/Description> for a long description.

Also, it's vital you study L<Lingua::EN::GivenNames/How do the scripts and modules interact to produce the data?>.
See also scripts/import.sh for the order in which they must be run.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<Lingua::EN::GivenNames::Database::Import>.

This is the class's contructor.

Usage: C<< Lingua::EN::GivenNames::Database::Import -> new() >>.

=head1 Methods

This module is a sub-class of L<Lingua::EN::GivenNames::Database> and consequently inherits its methods.

=head2 extract_derivations()

Extract the derivations from 1 page of either female or male English given names, and write them to
data/derivations.raw.

This file is opened during each method call in append mode ('>>'), meaning if you wish to
start from scratch, that file must be deleted before scripts/extract.derivations.pl is run. See
scripts/import.sh for details.

Since the input data/*.htm files contain data in alphabetical order (usually), the output is also in order.

The output file is processed by parse_derivations().

Returns 0 to indicate success.

=head2 generate_derivation($item)

Takes a hashref, $item, and constructs a string which is the derivation of the given name whose components
are the values of various keys in this hashref.

The string returned depends on which regexp was used to parse the input.

See L<Lingua::EN::GivenNames/FAQ> for details.

=head2 import_derivations()

Reads the file data/derivations.csv created by sub parse_derivations() by calling read_derivations().

It checks for duplicate records, and then writes all the data to the appropriate database tables.

Returns 0 to indicate success.

=head2 new()

See L</Constructor and initialization>.

=head2 parse_derivations()

Reads the file data/derivations.raw created by sub extract_derivations(), applies a set of regexps to each
line, and writes data/derivations.csv.

Mismatches are written to data/mismatches.log, and a 1-line report is written to data/parse.log.

Clearly, this is where most of the work takes place.

Returns 0 to indicate success.

=head2 read_derivations()

This method is called by sub import_derivations(). It reads and validates data/derivations.raw.

Also, this method checks to ensure no data is missing, which would indicate a programming error in the
handling of the output from the regexp processing phase.

Returns an arrayref.

=head2 validate_derivations($file_name, $derivation)

$file_name is the file currently being processed (data/derivations.csv), and is used for error messages.

$derivation is a hashref keyed by columns in the input file, so unique entries in each column can be checked.

This method is called by sub read_derivations(). It performs a simple reasonableness check on each input line,
and also logs, at level I<notice>, all non-ASCII names.

=head2 write_names($table, $derivation, $foreign_key)

$table is the name of the table to write, which is always I<names>.

$derivation is an arrayref of derivations to write.

$foreign_key is a hashref of primary keys returned by L</write_table($table, $item)> for each table other than
the I<names> table.

Called by sub import_derivations() and writes the I<names> table.

=head2 write_table($table, $item)

$table is the name of the table to write.

$item is an arrayref of values to write.

Called by sub import_derivations() and writes all tables except the I<names> table.

Returns a hashref of primary key ids for use as foreign keys when the I<names> table is written.

=head1 FAQ

See L<Lingua::EN::GivenNames/FAQ>.

=head2 How is the input scanned?

The regexps in sub parse_derivations() split each line of data/derivations.raw into these fields,
when using the regexp called 'a':

=over 4

=item o $1 => Sex

=item o $2 => Name

=item o $3 => Kind

=item o $4 => Form

=item o $5 => Source

=item o $6 => Original

=item o $7 => Rating

=item o $8 => Meaning

=back

These fields are described in L<Lingua::EN::GivenNames/FAQ>. Other regexps have similar outputs.

=head3 Matches using pattern 'a'

1) 'male. ALLISTAIR: Anglicized form of Scottish Gaelic Alastair, meaning "defender of mankind."' becomes the
hashref (with keys in alphabetical order, and text from data/derivations.raw):

	{
		form     => 'form',
		kind     => 'Anglicized',
		meaning  => 'defender of mankind',
		name     => 'ALLISTAIR',
		original => 'Alastair',
		rating   => 'meaning',
		sex      => 'male',
		source   => 'Scottish Gaelic',
	}

The derivation is: Anglicized form of Scottish Gaelic Alastair, meaning "defender of mankind".

2) 'male. ANTONY: Variant spelling of English Anthony, possibly meaning "invaluable."' becomes:

	{
		form     => 'spelling',
		kind     => 'Variant',
		meaning  => 'invaluable',
		name     => 'ANTONY',
		original => 'Anthony',
		rating   => 'possibly meaning',
		sex      => 'male',
		source   => 'English',
	}

The derivation is: Variant spelling of English Anthony, possibly meaning "invaluable".

In each case the derivation is built by sub generate_derivation($item) as:

	qq|$$item{kind} $$item{form} of $$item{source} $$item{original}, $$item{rating} $$item{meaning}|

=head3 Matches using pattern 'b'

3) 'female. ANTONIA: Feminine form of Roman Latin Antonius, possibly meaning "invaluable." In use by the English, Italians and Spanish. Compare with another form of Antonia.'
becomes:

	{
		form     => 'form',
		kind     => 'Feminine',
		meaning  => 'invaluable',
		name     => 'ANTONIA',
		original => 'Anthony',
		rating   => 'possibly meaning',
		sex      => 'female',
		source   => 'Roman Latin',
	}

The derivation is: Feminine form of Roman Latin Antonius, possibly meaning "invaluable".

The derivation is built by sub generate_derivation($item) as:

	qq|$$item{kind} $$item{form} of $$item{source} $$item{original}, $$item{rating} $$item{meaning}|

=head3 Matches using pattern 'c'

4) 'male. HENGIST: Old English name meaning "stallion." In English legend, this is the name of the brother of Horsa, and ruler of Kent. In Arthurian legend, he was killed by Uther Pendragon.'
becomes:

	{
		form     => 'name',
		kind     => 'Old English',
		meaning  => 'stallion',
		name     => 'HENGIST',
		original => '-',
		rating   => 'meaning',
		sex      => 'male',
		source   => '-',
	}

The derivation is: Old English name, meaning "stallion".

The derivation is built by sub generate_derivation($item) as:

	qq|$$item{kind} $$item{form}, $$item{rating} $$item{meaning}|

=head3 Matches using pattern 'd'

5) 'female. PRU: Short form of English Prudence "cautious" and Prunella "little prune."'
becomes:

	{
		form     => 'form',
		kind     => 'Short',
		meaning  => '"cautious" and Prunella "little prune"',
		name     => 'PRU',
		original => 'Prudence',
		rating   => 'meaning',
		sex      => 'female',
		source   => 'English',
	}

The derivation is: Short form of English Prudence, meaning "cautious" and Prunella "little prune".

The derivation is built by sub generate_derivation($item) as:

	qq|$$item{kind} $$item{form} of $$item{source} $$item{original}, $$item{rating} $$item{meaning}|

=head1 References

See L<Lingua::EN::GivenNames/References>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua::EN::GivenNames>.

=head1 Author

C<Lingua::EN::GivenNames> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
