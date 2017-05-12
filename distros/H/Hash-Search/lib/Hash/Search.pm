package Hash::Search;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.03';

my %hash_search_result = ();
my $hash_search_result_count = 0;

sub new{

	# new: create a new instance of 

	my $class = shift;
	my $self = {};

	return bless($self, $class);

}

sub hash_search{

	# hash_search: Find matches of names using the regular expression
	# and hash given.

	my $class = shift;
	my ($passed_hash, %passed_hash);
	my $passed_expression;
	my $regex_test = "";

	$passed_expression = shift;
	(%passed_hash) = @_;

	# Check if the hash or the expression passed is blank and
	# write a carp message if blank.

	if (!%passed_hash){
		carp("The hash given is blank");
		return;
	}

	if (!$passed_expression || $passed_expression eq ""){
		carp("The expression given is blank");
		return;
	}

	# Process the hash given putting the results into a
	# seperate hash while increment the search result
	# counter.

	%hash_search_result = ();
	$hash_search_result_count = 0;

	foreach my $hash_key (keys %passed_hash){

		if ($hash_key =~ m/$passed_expression/){

			# We have a match so put the result into the hash.

			$hash_search_result{ $hash_key } = $passed_hash{$hash_key};
			$hash_search_result_count++;
		}

	}

	# Return 1 if there was at least one search result returned and return
	# 0 if not.

	return 1 if $hash_search_result_count >= 1;
	return 0;

}

sub hash_search_resultdata{

	# hash_search_resultdata: Return the result data for
	# the search that has been made.

	return %hash_search_result;

}

sub hash_search_resultcount{

	# hash_search_resultcount: Return the count of results
	# for the search.

	return $hash_search_result_count;

}

1;

__END__

=head1 NAME

Hash::Search - Search and return hash keys using regular expressions

=head1 SYNOPSIS

  use Hash::Search;
  my $hs = new Hash::Search;
  my %hashlist = (
    "one" => "orange", "two" => "banana", "three" => "apple",
    "four" => "pear", "five" => "pineapple"
  );
  $hs->hash_search("e\$", %hashlist);
  my %hashresult = $hs->hash_search_resultdata;
  my $hashresult_count = $hs->hash_search_resultcount;
  print $hashresult_count . " result(s) found: ";
  foreach my $hash_key (keys %hashresult){
    print $hash_key . " ";
  }

=head1 DESCRIPTION

This module allows a search to be made on a hash based on a regular
expressions pattern based on the name of the key and returns the
results as a seperate hash. It also keeps a count of how many
matches have been made.

=head2 Creating an instance

Before Hash::Search can be used, an instance of Hash::Search must be
created.

  use Hash::Search;
  $hs = new Hash::Search;

=head2 Finding keys in a hash

  $hs->hash_search("p\$", %hash);

The hash_search subroutine requires two parameters, one is a regular
expression used for searching the names of keys and another for the
hash itself.

If a blank expression has been specified or an empty hash is given
then a warning (carp) message is written and the subroutine promptly 
returns.

hash_search can also be used in a if statement so that it can process
information depending if hash_search finds matches or not.

=head2 Getting the results data

  %results = $hs->hash_search_resultdata;

The value returned from hash_search_resultdata will be a hash. If no 
matches have been found then it will return an empty hash.

=head2 Getting the count of results

  $searchresults = $hs->hash_search_resultcount;
  print "Matches found: " . $searchresults;
	
  print "Number of results returned: " . $hs->hash_search_resultcount;

The value returned from hash_search_resultcount will be a scalar value.

=head1 EXAMPLES

=head2 Using Hash::Search with CGI

  use CGI qw(:standard);
  use Hash::Search;

  my $q = new CGI;
  my $hs = new Hash::Search;

  my %formdata = $q->Vars;
  $hs->hash_search("^prefix_", %formdata);
  my %resultdata = $hs->hash_search_resultdata;

=head2 Using Hash::Search with CGI::Lite

  use CGI::Lite;
  use Hash::Search;

  my $cgi = new CGI::Lite;
  my $hs = new Hash::Search;
  my %formdata = $cgi->parse_form_data;
  $hs->hash_search("^prefix_", %formdata);
  my %resultdata = $hs->hash_search_resultdata;	

=head1 CAVEATS / KNOWN BUGS

If an invalid regular expression is given to hash_search then the script 
will not run and will give the line number at the point where the regular 
expression is used in this module as there doesn't appear to be a 
relatively straight forward way of checking if the regular expression 
itself is valid or not prior to it being used.

This is currently a perl module that is at the alpha development stage and
as such things in this module can change which may break your scripts in the
future.

=head1 SEE ALSO

L<Carp>, L<CGI> and L<CGI::Lite>

=head1 AUTHOR

Steve Brokenshire, E<lt>sbrokenshire@xestia.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steve Brokenshire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
