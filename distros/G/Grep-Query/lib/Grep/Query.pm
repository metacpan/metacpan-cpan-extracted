package Grep::Query;

use 5.010;

use strict;
use warnings;

our $VERSION = '1.008';
$VERSION = eval $VERSION;

use Grep::Query::Parser;
use Grep::Query::FieldAccessor;

use Scalar::Util qw(blessed);
use Carp;

# allow importing the qgrep function/method
# to enable non-OO use
#
use Exporter qw(import);
our @EXPORT_OK = qw(qgrep);

## CTOR
##
sub new
{
	my $class = shift;
	my $query = shift;
	
	croak("No query provided") unless defined($query);
	
	# parse the query right now
	# 
	my ($parsedQuery, $fieldRefs) = Grep::Query::Parser::parsequery($query); 
	my $self =
		{
			_query => $query,
			_parsedquery => $parsedQuery,
			_fieldrefs => $fieldRefs
		};
	bless($self, $class);
	
	return $self;
}

## METHODS
##

sub qgrep
{
	croak("missing parameters") unless @_;

	my $arg = shift;
	
	my $obj = 
				(blessed($arg) // '') eq __PACKAGE__
			?	$arg
			:	__PACKAGE__->new($arg);
			
	return $obj->__qgrep(@_);
}

sub getQuery
{
	my $self = shift;
	
	return $self->{_query};
}

# don't call this directly, use the above
#
sub __qgrep
{
	# why even bother if you're not interested in the result?
	#
	return undef unless defined(wantarray());
	
	my $self = shift(@_);

	# first check if the first argument is/should be a field accessor
	#
	my $fieldAccessor;
	if (@{$self->{_fieldrefs}})
	{
		# the query uses fields, so there must be field accessor first 
		#
		$fieldAccessor = shift(@_);
		
		if (defined($fieldAccessor))
		{
			# verify that the field accessor is of the right sort and has the known fields
			#
			croak("field names used in query; first argument must be a field accessor") unless ref($fieldAccessor) eq 'Grep::Query::FieldAccessor';
			$fieldAccessor->assertField($_) foreach (@{$self->{_fieldrefs}});
		}
		else
		{
			# for laziness, the caller passed undef and so we can assume the objects to be queried
			# are in fact plain hashes so we manufacture a field accessor for that
			#
			$fieldAccessor = Grep::Query::FieldAccessor->new();
			foreach my $field (@{$self->{_fieldrefs}})
			{
				$fieldAccessor->add($field, sub { $_[0]->{$field} } );
			}
		}
	}
	else
	{
		# it's weird if a field accessor is present, but the query uses no fields - flag that mistake
		#
		croak("no fields used in query, yet the first argument is a field accessor?") if ref($_[0]) eq 'Grep::Query::FieldAccessor';
	}

	my $list = \@_;
	
	# a special case:
	# if there is only one argument AND it is a hash ref, we can let loose a query on it
	# assuming we restructure the incoming data as a list of individual key/value pairs
	#
	# for this, we must have a fieldaccessor 
	#
	my $lonehash = 0;
	if (scalar(@$list) == 1 && ref($list->[0]) eq 'HASH')
	{
		croak("a lone hash used in query; first argument must be a field accessor") unless $fieldAccessor;
		my @eachList;
		while (my @kv = each %{$list->[0]})
		{
			push(@eachList, \@kv);
		}
		$list = \@eachList;
		$lonehash = 1;
	} 
	
	# the list we were given needs to be made into a hash with unique keys so we
	# identify 'rows' while evaluating the query
	# 
	# that means we can return multiple identical hits and that we can sort the return list
	# in the same order we got it
	#
	# keys are simply a number, and values are refs to the individual scalars/objects to avoid copying them
	#
	my $id = 0;
	my %data = map { $id++ => \$_ } @$list;
	
	# kick off the query 
	#
	%data = %{ $self->{_parsedquery}->xeq($fieldAccessor, \%data) };

	# only return the number of matches if the full list isn't desired
	#	
	return scalar(keys(%data)) unless wantarray();

	# fix up an array with the matches 
	#	
	my @matched;
	if ($lonehash)
	{
		# we started with a hash, so that is what should be returned
		#
		my %h;
		$h{${$data{$_}}->[0]} = ${$data{$_}}->[1] foreach (keys(%data));
		push(@matched, \%h);
	}
	else
	{
		# keep the (relative) order they we're given to us by sorting on the artificial
		# key index we gave them
		#
		foreach my $k (sort { $a <=> $b } (keys(%data)))
		{
			push(@matched, ${$data{$k}});
		} 
	}
		
	# now return the result list
	#
	return @matched;
}

1;

=head1 NAME

Grep::Query - Query logic for lists of scalars/objects 

=head1 VERSION

Version 1.008

=head1 SYNOPSIS

  use Grep::Query qw(qgrep);
  
  my @data = ( 'a' .. 'z' );
  my @result;

  # very simple query equal to a standard "grep(/[dkob]/, @data)"
  #
  @result = qgrep('REGEXP([dkob])', @data);
  #
  # @result contains ( 'd', 'k', 'o', 'b' )
  
  # go more wild
  #
  @result = qgrep('REGEXP([dkob]) AND ( REGEXP([yaxkz]) OR REGEXP([almn]) )', @data);
  #
  # @result contains ( 'k' )

  # or use it in OO fashion
  #
  my $gq = Grep::Query->new('REGEXP([dkob]) AND ( REGEXP([yaxkz]) OR REGEXP([almn]) )');
  @result = $gq->qgrep(@data);
  
  # also query a list of objects, and use numerical comparisons too
  #
  my @persons = ...; # assume person objects can respond to '->getName()' and '->calculateAge()'
  
  # create a query object - note that the syntax now references 'field' names of name/age in the query
  #
  my $personQuery = Grep::Query->new('name.REGEXP(^A) AND age.>=(42)');
  
  # set up a field accessor to teach G::Q how to match field names to whatever's needed to get data from the objects
  #
  my $fieldAccessor = Grep::Query::FieldAccessor->new();
  $fieldAccessor->add('name', sub { $_[0]->getName() });
  $fieldAccessor->add('age', sub { $_[0]->calculateAge() });
  
  # now execute the query by passing the field accessor before the person list
  #
  @result = $personQuery->qgrep($fieldAccessor, @persons);
  #
  # @result contains a list of person objects that has a name starting with 'A' and an age greater than or equal to 42
  
  # If what you have is a single hash (rather than a list of them) and you wish to query it and pick out key/values
  # that matches, the query is special cased for passing just a single hash.
  # A field accessor is necessary, and it will receive individual key/value pairs as small lists.
  # 
  # Assume a %videos hash, keyed by video name, and value is another hash with at least the key 'length' holding the video
  # length in seconds...:
  #
  my $fieldAccessor = Grep::Query::FieldAccessor->new();
  $fieldAccessor->add('key', sub { $_[0]->[0] });
  $fieldAccessor->add('length', sub { $_[0]->[1]->{length} });
  my $videoQuery = Grep::Query->new('key.REGEXP(^Alias) AND length.gt(2500)');
  @result = $videoQuery->qgrep($fieldAccessor, \%videos);
  #
  # $result[0] contains a hash ref with all videos with name starting with 'Alias' and at least 2500 seconds long
    
=head1 BACKGROUND

Why use this module when you could easily write a grep BLOCK or plain regexp
EXPR to select things in a list using whatever criteria you desired?

=head2 The original use-case was this: 

Given a number of commandline tools I provide to users in my workplace, quite
frequently I wanted the user to be able to express, with some flag(s), a
selection among a list of 'somethings' computed at runtime - the most common
probably a list of file/directory names. It was also common to have this type
of filtering defined in various configuration files and persistently apply them
every time a command was run.  

Example: the user gives the command:

  SomeCommand /some/path

The 'SomeCommand' may, for example, scan the given path and for all files it finds it will
do something useful. So, I also wanted to provide flags for the command such
that they can say...

  SomeCommand -exclude 'some_regexp' /some/path

...in order to filter the list of files that should be worked on.

Obviously not a problem, and I also provided the reverse if that was more
convenient:

  SomeCommand -include 'another_regexp' /some/path

And the idea was extended so flags could be given multiple times and
interweaved:

  SomeCommand -include 'rx1' -exclude 'rx2' -include 'rx3' ... /some/path

Thus, the original set was shrunk by first selecting only those matching the
regexp C<rx1> and then shrink that by excluding those matching C<rx2> etc. - I
think you get the idea.

What I found however is that it becomes hard to string together regexps to find
the exact subset you want when the rules are a bit more complex. In fact, while
regexps are powerful, they're not that suited to easily mix multiple of them
(and some expressions are basically impossible, e.g. 'I want this but not this'),
especially when you try to provide a commandline interface to them...

Thus, instead I'd wanted to provide a more capable way for a user to give a
more complex query, i.e. where it'd be possible to use AND/OR/NOT as well as
parenthesized groups, e.g. something like this (very contrived and structured
on several lines for readability):

    (
      REGEXP/some_rx_1/ AND REGEXP/some_rx_2/
    )
  OR
    (
      REGEXP/some_rx_3/ AND NOT REGEXP/some_rx_4/
    )
  OR
    NOT
      (
        REGEXP/some_rx_5/ OR NOT REGEXP/some_rx_6/
      )

Basically, feed 'something' the query and a list of scalars and get back a list
of the subset of scalars that fulfills the query. In short, behaving like a
grep, you might say, but where the normal BLOCK or EXPR is a query decided by
the user

As it turned out, once the basics above was functioning I added some other
features, such as realizing that lists were not always just simple scalars, but
could just as well be "objects" and also that it then was useful to use
numerical comparisons rather than just regular expressions.

Hence, this module to encapsulate the mechanism.

=head3 Is it for you?

It may be comparatively slow and very memory-intensive depending on the
complexity of the query and the size of the original data set.

If your needs can be met by a regular grep call, utilizing a regular expression
directly, or using a block of code you can write beforehand, this module
probably isn't necessary, although it might be convenient if your block is
complex enough.

=head1 DESCRIPTION

The visible API is made to be simple but also compact - the single method/function
C<qgrep>, actually. For the slightly more complex scenarios a helper class is
required, but generally a very simple one giving high flexibility in how to structure
the query itself regardless of how the list itself is laid out.

It has a behavior similar to C<grep> - give it a list and get back a list (or
in scalar context, the number of matches). The main difference is that the
matching stuff is a query expressed in a fairly simple language. 

It can be used in both non-OO and OO styles. The latter obviously useful when
the query will be used multiple times so as to avoid parsing the query every
time.

The basic intent is to make it easy to do the easy stuff while still making it
easy to move up to something more complex, without having a wide or wordy API.
This is a two-edged sword - I hope this will not be confusing.

=head2 QUERY LANGUAGE

A query effectively have two slightly different "modes", depending on if the
query is aimed at a list of ordinary scalars or if the list consists of objects
(or plain hashes, which is regarded as a special case of objects). There is
also a special case when you pass only a single hash ref - it can be treated
as a list, and a new hash ref with matching key/value pairs passed back. 

=over

=item Scalars

In the first case, the query doesn't use "field" names - it is implicit that
the comparison should be made directly on scalars in the list.

Note that is possible to use field names if desired - just make the accessors
so that it properly extracts parts of each scalar.

=item Hashes/Objects

In the second case, the query uses field names for the comparisons and
therefore a "field accessor" object is required when executing the query so as
to provide the query engine with the mapping between a field name and the data.

A special case occurs when the list consists of hashes with keys being exactly
the field names - if so, the query engine can transparently create the
necessary field accessor if one is not passed in. 

=back

It's important to note that either the query uses field names everywhere, or
not at all. Mixing comparisons with field names and others without is illegal.

For hashes/objects it's necessary to use field names - otherwise you will match
against scalar representations of hashref values for example, e.g. 'HASH(0x12345678)'.
Hardly useful.

=head3 SYNTAX

The query language syntax is fairly straightforward and can be divided in two main
parts: the logical connectors and the comparison atoms.

In the tables below, note that case is irrelevant, i.e. 'AND' is equal to 'and' which is
equal to 'And' and so on.

=over

=item Comments

Comments can be used in the query using the begin/end style like '/* some comment */'.

=item Logical connectors

In this category we find the basic logic operators used to tie comparisons
together, i.e AND/OR/NOT and parentheses to enforce order.

=over

=item * B<NOT> or B<!> 

Used to negate the list generated by an expression.

=item * B<AND> or B<&&>

Used to select the intersection of two lists formed by expressions before and
after. 

=item * B<OR> or B<||>

Used to select the union of two lists formed by expressions before and
after. 

=item * B<()> 

Used to enforce a grouping order.

=back

=item Comparison atoms

A comparison atom is how to describe a match. It can be divided in string and
numeric matches. A complete atom can contain the following:

I<fieldname>B<.>I<operator>B<startdelimiter>I<value>B<stopdelimiter>

The I<fieldname> is optional. If given, it is terminated with a period (B<.>).
It cannot contain a period or a space, but otherwise it can be any text that
can be used as a hash key.

The rest of the expression consists of an I<operator> and a I<value> to be used
by that operator delimited by B<startdelimiter> and B<stopdelimiter>. To
accommodate values happening to use characters normally used in a delimiter,
choice of character(s) is very flexible. The delimiters can be of two different
kinds. Either common start/stop pairs like parentheses: I<()>, braces: I<{}>,
brackets: I<[]> or angles: I<E<lt>E<gt>>. Or, it can be an arbitrary character except
space, and the same character again after the value, e.g. I</>.

The I<operator>s are:

=over

=item * B<TRUE> or B<FALSE>

These operators always evaluate to true and false respectively.

=item * B<REGEXP> or B<=~>

This operator expects to use the I<value> as a regular expression for use in
matching.

=item * B<EQ>, B<NE>, B<LT>, B<LE>, B<GT>, B<GE>

These are B<string> based matches, i.e. I<equal>, I<not equal>, I<less than>,
I<less than or equal>, I<greater than> and I<greater than or equal>.

Don't confuse these with the B<numeric> comparisons - results will likely
be unexpected since using these means that "2" is greater than "19"... 

=item * B<==>, B<!=>, B<E<lt>>, B<E<lt>=>, B<E<gt>>, B<E<gt>=>

These are B<numerical> matches.

=back 

=back

=head3 EXAMPLES

  # in normal Perl code, we would for example write:
  #
  my $v = "abcdefgh";
  if ($v =~ /abc/)
  {
    ...
  }
  
  # equivalent ways to write the regexp in a query would be:
  #
  REGEXP(abc)
  regexp(abc)  # case doesn't matter
  =~(abc)      # in case you're more comfortable with the Perl operator
  =~{abc}      # braces as delimiters 
  =~[abc]      # brackets as delimiters 
  =~<abc>      # angles as delimiters 
  =~/abc/      # Perlish
  =~dabcd      # works, but quite confusing
  
  # a compound query with fields
  #
  name.REGEXP(^A) AND age.>=(42)  # field names before the operators

=head1 METHODS/FUNCTIONS

=head2 new( $query )

Constructor for a Grep::Query object if using the OO interface.

The argument query string is required.

Croaks if a problem is discovered.

=head3 EXAMPLE

  # create a G::Q object
  #
  my $gq = Grep::Query->new('==(42) OR >(100)');

=head2 getQuery()

Returns the original query text.

=head2 qgrep

Execute a query.

This method can be called in a few different ways, depending on if it's used in
an OO fashion or not, or if the query contains field names or not.

Croaks if something is wrong.

Return value: Number of matches in the given data list if called in scalar
context, the matching list otherwise. The return list will keep the relative order as the
original data list. A notable exception: if called in void context, the query
is skipped altogether - seems to be no point in spending a lot of work when no
one's interested in the results, right? 

=over

=item * Non-OO, no fields: qgrep( $query, @data )

The given C<$query> string will be parsed on the fly and executed against the
C<@data>.

=item * Non-OO, with fields: qgrep( $query, $fieldAccessor, @data )

The given C<$query> string will be parsed on the fly and executed against the
data, using the C<$fieldAccessor> object to get values from C<@data> objects.

Note: In a certain case, the C<$fieldAccessor> argument can be passed as
C<undef> and it will be auto-generated. See below for details.
 

=item * OO, no fields: $obj->qgrep( @data )

The C<$obj> must first have been created using L</new> and then it can be
executed against the C<@data>.

=item * OO, with fields: $obj->qgrep( $fieldAccessor, @data )

The C<$obj> must first have been created using L</new> and then it can be
executed, using the C<$fieldAccessor> object to get values from C<@data>
objects.

Note: In a certain case, the C<$fieldAccessor> argument can be passed as
C<undef> and it will be auto-generated. See below for details. 

=item * Passing a single hashref: qgrep($fieldAccessor, \%hash)

In this case, the field accessor methods will be called with two-item
arrayrefs, e.g. the key is in the first (0) slot, and the value is in the
second (1) slot.

=back

=head3 Autogenerated field accessor

If the C<@data> holds plain hashes with keys exactly corresponding to the field
names used in the query, the query engine can autogenerate a field accessor.

This is only a convenience, a manually constructed field accessor will be used
if given. To take advantage of the convenience, simply pass C<undef> as the
C<$fieldAccessor> argument. 

=head3 EXAMPLES

  # sample data
  my @scalarData = ( 105, 3, 98, 100, 42, 101, 42 );

  # make sure to import the qgrep function
  #
  use Grep::Query qw(qgrep);
  
  # now call it directly
  #
  my $matches = qgrep('==(42) OR >(100)', @scalarData);
  #
  # $matches is now 4 (matching 105, 42, 101, 42)
  
  # or equivalently, create a G::E object and call the method on it
  #
  my $gq = Grep::Query->new('==(42) OR >(100)');
  $matches = $gq->qgrep(@scalarData);
  #
  # $matches again 4
  
  # some sample fielded data in a hash
  #
  my @hashData = 
  	(
  		{ x => 52, y => 38 },
  		{ x => 94, y => 42 },
  		{ x => 25, y => 77 }
  	);
  
  # autogenerate a field accessor since the query matches the fields
  #
  $matches = qgrep('x.>(20) AND y.>(40)', undef, @hashData);
  #
  # $matches is now 2 (matching last two entries)
  
  # but using different field names (or if it was opaque objects used)
  # we must provide an explicit field accessor
  #
  my $fieldAccessor = Grep::Query::FieldAccessor->new
                                               (
                                                 {
                                                   fieldY => sub { $_[0]->{y} },
                                                   fieldX => sub { $_[0]->{x} },
                                                 }
                                               );
  $matches = qgrep('fieldX.>(20) AND fieldY.>(40)', $fieldAccessor, @hashData);
  #
  # $matches again 2
  
=head1 AUTHOR

Kenneth Olwing, C<< <knth at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-grep-query at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Grep-Query>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Grep::Query

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Grep-Query>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Grep-Query>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Grep-Query>

=item * Search CPAN

L<http://metacpan.org/dist/Grep-Query/>

=back

=head1 ACKNOWLEDGEMENTS

First and foremost, I thank my family for putting up with me!

=over

=item David Mertens, C<< <dcmertens.perl(at)gmail.com> >> for the name.

=item Ron Savage, C<< <ron(at)savage.net.au> >> for helping follow current best
practices for modules.

=back

=head1 REPOSITORY

L<https://github.com/kenneth-olwing/Grep-Query>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Kenneth Olwing.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
