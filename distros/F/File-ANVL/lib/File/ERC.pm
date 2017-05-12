package File::ERC;

use 5.006;
use strict;
use warnings;

our $VERSION;
$VERSION = sprintf "%d.%02d", q$Name: Release-1-05 $ =~ /Release-(\d+)-(\d+)/;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
);

our @EXPORT_OK = qw(
	num2tag tag2num tag2num_init
);

our %erc_terms = (
	'h10'	=> 'about-erc',	# analog for dir_type?
	'h12'	=> 'about-what',
	'h13'	=> 'about-when',
	'h14'	=> 'about-where',
	'h11'	=> 'about-who',
	'h15'	=> 'about-how',
	'h506'	=> 'contributor',
	'h514'	=> 'coverage',
	'h502'	=> 'creator',
	'h507'	=> 'date',
	'h504'	=> 'description',
	'c1'	=> 'ERC',
	'h9'	=> 'erc',	# h0->h9 to not collide with dir_type
	'h0'	=> 'dir_type',
	'v1'	=> ':etal',
	'h509'	=> 'format',
	'c2'	=> 'four h\'s',
	'h510'	=> 'identifier',
	'h602'	=> 'in',
	'h5'	=> 'how',
	'h512'	=> 'language',
	'c3'	=> 'metadata',
	'h30'	=> 'meta-erc',	# dirtype?
	'h32'	=> 'meta-what',
	'h33'	=> 'meta-when',
	'h34'	=> 'meta-where',
	'h31'	=> 'meta-who',
	'v2'	=> ':none',
	'h601'	=> 'note',
	'v3'	=> ':null',
	'c4'	=> 'object',
	'h505'	=> 'publisher',
	'c5'	=> 'resource',
	'h513'	=> 'relation',
	'h515'	=> 'rights',
	'h511'	=> 'source',
	'h503'	=> 'subject',
	'h20'	=> 'support-erc',	# dirtype?
	'h22'	=> 'support-what',
	'h23'	=> 'support-when',
	'h24'	=> 'support-where',
	'h21'	=> 'support-who',
	'c6'	=> 'stub ERC',
	'v4'	=> ':tba',
	'h501'	=> 'title',
	'h508'	=> 'type',
	'v5'	=> ':unac',
	'v6'	=> ':unal',
	'v7'	=> ':unap',
	'v8'	=> ':unas',
	'v9'	=> ':unav',
	'v10'	=> ':unkn',
	'h2'	=> 'what',
	'h3'	=> 'when',
	'h4'	=> 'where',
	'h1'	=> 'who',
);

our %erc_tags;			# for lazy evaluation
our @erc_termlist;		# for lazy evaluation

sub tag2num_init {

	@erc_termlist = sort values %erc_terms;	# so we can grep
	$erc_tags{$erc_terms{$_}} = $_		# so we can inverse map
		for (keys %erc_terms);
}

sub tag2num {

	@erc_termlist && %erc_tags or
		tag2num_init();		# one-time lazy definition
	my (@ret, $tag);
	foreach $tag (@_) {
		# if it doesn't look like a regexp, do exact match
		push(@ret, grep(
			($tag =~ /[\\\*\|\[\+\?\{\^\$]/ ? /$tag/ : /^$tag$/),
			@erc_termlist));
	}
	return @ret;
}

# Returns an array of terms corresponding to args given as coded
# synonyms for Dublin Kernel elements, eg, num2tag('h1') -> 'who'.
#
sub num2tag {

	my (@ret, $code);
	for (@_) {
		# Assume an 'h' in front if it starts with a digit.
		#
		($code = $_) =~ s/^(\d)/h$1/;

		# Return a defined hash value or the empty string.
		#
		push @ret, defined($erc_terms{$code}) ?
			$erc_terms{$code} : '';
	}
	return @ret;
}

1;

__END__

=head1 NAME

File::ERC - Electronic Resource Citation routines

=head1 SYNOPSIS

 use File::ERC;           # to import routines into a Perl script

 File::ERC::num2tag(      # return terms (array) corresponding to args
         $num, ... );     # given as coded synonyms for Dublin Kernel
	                  # elements, eg, num2tag('h1') -> 'who'; `h' is
			  # assumed in front of arg that is pure digits

=head1 DESCRIPTION

This is documentation for the B<ERC> Perl module, with support for
metadata labels in an ERC (Electronic Resource Citation) record, which
can be represented in a variety of underlying syntaxes, such as ANVL,
Turtle, XML, and JSON.  The ERC elements include Dublin Core Kernel
metadata.

=head1 SEE ALSO

A Metadata Kernel for Electronic Permanence (PDF)
	L<http://journals.tdl.org/jodi/article/view/43>

=head1 HISTORY

This is an alpha version of an ERC tool.  It is written in Perl.

=head1 AUTHOR

John A. Kunze I<jak at ucop dot edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2011 UC Regents.  Open source BSD license.

=head1 PREREQUISITES

Script Categories:

=pod SCRIPT CATEGORIES

UNIX : System_administration

=cut

