package Fabnewsru::Utils;
$Fabnewsru::Utils::VERSION = '0.01';
# ABSTRACT: Some useful methods for operating with Mojo::DOM objects


use warnings;
use List::MoreUtils qw( each_array );
# use Data::Dumper;
use common::sense;

use Exporter qw(import);
our @EXPORT_OK = qw(table2hash table2array_of_hashes merge_hashes rm_spec_symbols_from_hash_values rm_spec_symbols_from_string);



sub table2hash {
	my ($dom, $container) = @_; 
	my $h = {};
	my $table_dom = $dom->at($container);
	for my $i ($table_dom->find("tr")->each) {
		my $key_candidate = rm_spec_symbols_from_string($i->find("td")->[0]->all_text);
		my $val_candidate = rm_spec_symbols_from_string($i->find("td")->[1]->all_text);
		$h->{$key_candidate} = $val_candidate;
	}
	return $h;
}



sub table2array_of_hashes {
	my ($dom, $container, $fields_arr) = @_;
	my @array_of_hashes;	#result
	my $fields;		# array of fields
	if (defined $fields_arr) {
		$fields = $fields_arr;
	} else {
		for ($dom->find("thead th")->each) {
			push @$fields, rm_spec_symbols_from_string($_->text);
		}
	}

	# warn Dumper $fields;

	for my $i ($dom->find("tbody tr")->each) {
		my $h = {};
		my @values = $i->find("td")->each;					# html values				
		my $it = each_array(@$fields, @values);
		my @urls;
		while ( my ($x, $y) = $it->() ) {				# start of iteration on each <td></td>	
			$h->{$x}= rm_spec_symbols_from_string($y->all_text); 					# couldn't be text, need to be all_text
			for my $e ($y->find('a[href]')->each) {						# extract all urls;
				push @urls, $e->attr("href");
			  }
			$h->{urls} = \@urls;
			# if (defined $y) {
			# 	push @urls, $y->at("a[href]")->attr("href");
			# }
		}	# end of iteration on each <td></td>
		push @array_of_hashes, $h;
	}
	return \@array_of_hashes;
}


sub merge_hashes {
    my ($fields, $values) = @_;
    my $result ={};
    while ( my ($i, $j) = each(%$values) ) {
        my ($new_key) = grep { $fields->{$_} eq $i } keys $fields;
        $result->{$new_key} = $j;       
    }
    return $result;
}



sub rm_spec_symbols_from_string {
	my $str = shift;
	$str =~ s/[\$#~!&;:]+//g;
	$str =~ s/^\s+//g;
	$str =~ s/\s+$//g;
	$str =~ s/\s{2,}/ /g;
	return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Fabnewsru::Utils - Some useful methods for operating with Mojo::DOM objects

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Fabnews::Utils qw(table2hash table2array_of_hashes merge_hashes);

    my $dom = Mojo::DOM->new('<div class="company-profile-table"><tr><td>key1</td><td>val1</td></tr></div>');
	warn Dumper table2hash($dom, ".company-profile-table");   # { key1 => 'val1' }


    my $h = table2hash($url, $table_container);
	my $h = table2hash("http://fabnews.ru/fablabs/item/ufo/", ".company-profile-table");  # .company-profile-table - container with <table> that is needed to be parsed
	my $arr = table2array_of_hashes("http://fabnews.ru/fablabs/", "table", ["name", "fabnews_subscribers", "fabnews_rating"]);

=head1 METHODS

=head2 table2hash

Accepts as input L<Mojo::DOM> object

Convert table to hash. Each row will be represented as key - value pair

Key will be text at first <td> element, value - at second <td>

Example

Table

header1 | header2
----------------
key1 | value1
key2 | value2

will be processed into a hash

{ key1 => value1, key2 => value2}

Assuming that strigs in $dom it already in internal format and with UTF8 flag set

=head2 table2array_of_hashes 

my $arr = table2array_of_hashes($container, $fields_arr);

$res = table2array_of_hashes($dom, ".company-profile-table", ["name", "fabnews_subscribers", "fabnews_rating"]);
$res = table2array_of_hashes($dom, ".company-profile-table");

Convert table to list of hashes. 

You can pass at $fields_arr how will be hash keys called. 

Otherwise (if no array provided) hash keys will be take	n from <th> tag of <thead>

Example

Table

header1 | header2
----------------
key1 | value1
key2 | value2

will be processed into a hash

[ { header1 => key1, header2 => value1 }, { header1 => key2, header2 => val2 } ]

Also if there will be any urls in table cells it will create a hash key with array val

E.g.

header1 | header2
----------------
key1 | value1
key2 + url | value2

Result will be like

[ { header1 => key1, header2 => value1 }, { header1 => key2, header2 => val2, urls => [] } ]

=head2 merge_hashes

Intellectual merge of two hashes

Return new hash with keys from first hash ($fields) and values from second hash ($values)

All input hashes must be in Perl internal encoding

Useful when substitution of hash keys containing some non-ASCII characters with 
ASCII-only latin characters which are more universal

See unit tests for more examples

=head2 rm_spec_symbols_from_string

Set of regular expressions which are deleting typical unwanted symbols from string:

* [\$#@~!&;:] characters
* any number of whitespaces in the beginning of string
* any number of whitespaces in the end of string
* replace a lot of space symbols into one space

This function is useful when post-processing HTML parsing results 
(in fact not all results looks good without post-processing)

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
