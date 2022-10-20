use 5.006;
use strict;
use warnings;

package LINQ::DSL;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use LINQ ();
use LINQ::Util -all;

use Exporter::Shiny;

our %EXPORT_TAGS = (
	essential => [qw/
		Linq From Where Select Join GroupBy ForEach DefaultIfEmpty HashSmush
	/],
	join => [qw/
		LeftJoin RightJoin InnerJoin OuterJoin GroupJoin
	/],
	sort => [qw/
		OrderBy OrderByDescending Reverse
	/],
	filter => [qw/
		Distinct Take TakeWhile Skip SkipWhile
	/],
	native => [qw/
		ToList ToArray ToDictionary ToIterator
	/],
	aggregate => [qw/
		Min Max Sum Average Aggregate Any All Contains Count SequenceEqual
	/],
	aggregate_safe => [qw/
		Min Max Sum Average Aggregate Contains Count SequenceEqual
	/],
	field => [qw/
		SelectX WhereX field fields check_fields
	/],
	type => [qw/
		Cast OfType AutoObject
	/],
	combine => [qw/
		Concat Union Intersect Except Zip
	/],
	get => [qw/
		First FirstOrDefault Last LastOrDefault
		Single SingleOrDefault ElementAt ElementAtOrDefault
	/],
	default => [qw/
		:essential :sort :join :filter :native :aggregate :field :type :combine :get
	/],
	default_safe => [qw/
		:essential :sort :join :filter :native :aggregate_safe :field :type :combine :get
	/],
);

our @EXPORT = map {
	/^:(.+)$/ ? @{ $EXPORT_TAGS{$1} } : $_;
} @{ $EXPORT_TAGS{'default'} };

our @EXPORT_OK = @EXPORT;

our $Result;
our $Final;

sub Linq (&) {
	my $definition = shift;
	local $Result;
	local $Final = 0;
	$definition->();
	return @$Result if $Final eq 'LIST';
	return $Result;
}

{
	my $ao;
	sub AutoObject () {
		require Types::Standard;
		require Object::Adhoc;
		$ao ||= Types::Standard::Object()->plus_coercions(
			Types::Standard::HashRef(), \&Object::Adhoc::object,
		);
	}
}

sub From ($;$) {
	my $source = pop;
	my $type = @_ ? shift : 'source';
	
	if ( $type eq 'source' ) {
		$Result = LINQ::LINQ( $source );
	}
	elsif ( $type eq 'range' ) {
		$Result = LINQ::Range( @$source );
	}
	elsif ( $type eq 'repeat' ) {
		$Result = LINQ::Repeat( @$source );
	}
	else {
		die 'unknown source';
	}
	return;
}

sub Where (&) {
	die if $Final;
	die unless $Result;
	$Result = $Result->where( @_ );
}

sub WhereX {
	@_ = scalar LINQ::Util::check_fields( @_ );
	goto \&Select;
}

sub Select (&) {
	die if $Final;
	die unless $Result;
	$Result = $Result->select( @_ );
}

sub SelectX {
	@_ = scalar LINQ::Util::fields( @_ );
	goto \&Select;
}

sub Join ($;@) {
	die if $Final;
	die unless $Result;
	my $other = LINQ::LINQ( shift );
	$Result = $Result->join( $other, @_ );
}

sub LeftJoin ($;@) {
	splice( @_, 1, 0, -left );
	goto \&Join;
}

sub RightJoin ($;@) {
	splice( @_, 1, 0, -right );
	goto \&Join;
}

sub InnerJoin ($;@) {
	splice( @_, 1, 0, -inner );
	goto \&Join;
}

sub OuterJoin ($;@) {
	splice( @_, 1, 0, -outer );
	goto \&Join;
}

sub GroupJoin ($;@) {
	die if $Final;
	die unless $Result;
	my $other = LINQ::LINQ( shift );
	$Result = $Result->group_join( $other, @_ );
}

sub GroupBy (&) {
	die if $Final;
	die unless $Result;
	$Result = $Result->group_by( @_ );
}

sub Distinct (&) {
	die if $Final;
	die unless $Result;
	$Result = $Result->distinct( @_ );
}

sub OrderBy {
	die if $Final;
	die unless $Result;
	$Result = $Result->order_by( @_ );
}

sub OrderByDescending {
	die if $Final;
	die unless $Result;
	$Result = $Result->order_by_descending( @_ );
}

sub Take ($) {
	die if $Final;
	die unless $Result;
	$Result = $Result->take( @_ );
}

sub TakeWhile (&) {
	die if $Final;
	die unless $Result;
	$Result = $Result->take_while( @_ );
}

sub Skip ($) {
	die if $Final;
	die unless $Result;
	$Result = $Result->skip( @_ );
}

sub SkipWhile (&) {
	die if $Final;
	die unless $Result;
	$Result = $Result->skip_while( @_ );
}

sub Concat ($) {
	die if $Final;
	die unless $Result;
	my $other = LINQ::LINQ( shift );
	$Result = $Result->concat( $other, @_ );
}

sub Reverse () {
	die if $Final;
	die unless $Result;
	$Result = $Result->reverse();
}

sub Zip {
	die if $Final;
	die unless $Result;
	my $other = LINQ::LINQ( shift );
	$Result = $Result->zip( $other, @_ );
}

sub DefaultIfEmpty ($) {
	die if $Final;
	die unless $Result;
	$Result = $Result->default_if_empty( @_ );
}

sub Cast ($) {
	die if $Final;
	die unless $Result;
	$Result = $Result->cast( @_ );
}

sub OfType ($) {
	die if $Final;
	die unless $Result;
	$Result = $Result->of_type( @_ );
}

sub Min (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->min( @_ );
}

sub Max (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->max( @_ );
}

sub Sum (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->sum( @_ );
}

sub Average (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->average( @_ );
}

sub Aggregate (&;@) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->aggregate( @_ );
}

sub First (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->first( @_ );
}

sub FirstOrDefault (&$) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->first_or_default( @_ );
}

sub Last (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->last( @_ );
}

sub LastOrDefault (&$) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->last_or_default( @_ );
}

sub Single (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->single( @_ );
}

sub SingleOrDefault (&$) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->single_or_default( @_ );
}

sub ElementAt (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->element_at( @_ );
}

sub ElementAtOrDefault (&$) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->element_at_or_default( @_ );
}

sub Any (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->any( @_ );
}

sub All (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->all( @_ );
}

sub Contains {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->contains( @_ );
}

sub Count () {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->count();
}

sub ToList () {
	die if $Final; $Final = 'LIST';
	die unless $Result;
	$Result = [ $Result->to_list() ];
}

sub ToArray () {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->to_array();
}

sub ToDictionary (&) {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->to_dictionary( @_ );
}

sub ToIterator () {
	die if $Final; ++$Final;
	die unless $Result;
	$Result = $Result->to_iterator();
}

sub ForEach (&) {
	die if $Final;
	die unless $Result;
	$Result->foreach( @_ );
}

sub Union {
	die if $Final;
	die unless $Result;
	my $other = LINQ::LINQ( shift );
	$Result = $Result->union( $other, @_ );
}

sub Intersect {
	die if $Final;
	die unless $Result;
	my $other = LINQ::LINQ( shift );
	$Result = $Result->intersect( $other, @_ );
}

sub Except {
	die if $Final;
	die unless $Result;
	my $other = LINQ::LINQ( shift );
	$Result = $Result->except( $other, @_ );
}

sub SequenceEqual {
	die if $Final; ++$Final;
	die unless $Result;
	my $other = LINQ::LINQ( shift );
	$Result = $Result->sequence_equal( $other, @_ );
}

sub HashSmush {
	require Object::Adhoc;
	return sub {
		my %smushed = map %$_, grep defined, reverse @_;
		Object::Adhoc::object(\%smushed);
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::DSL - alternative syntax for LINQ

=head2 ABSTRACT

    use LINQ::DSL ':default_safe';
    
    my @people = (
        { name => "Alice", dept => 8 },
        { name => "Bob",   dept => 7, this_will => 'be ignored' },
        { name => "Carol", dept => 7 },
        { name => "Dave",  dept => 8 },
        { name => "Eve",   dept => 1 },
    );
    
    my @depts = (
        { dept_name => 'Accounts',  id => 1 },
        { dept_name => 'IT',        id => 7 },
        { dept_name => 'Marketing', id => 8 },
    );
    
    my $collection = Linq {
        From \@people;
        SelectX 'name', 'dept';
        LeftJoin \@depts, field('dept'), field('id'), HashSmush;
        OrderBy -string, field('name');
        Cast AutoObject;
    };
    
    $collection->foreach( sub {
        printf "%s from %s\n", $_->name, $_->dept_name;
    } );

=head1 DESCRIPTION

This module allows you to create and manipulate L<LINQ::Collection>
objects using functions instead of chained method calls. The result
is a fairly SQL-like syntax.

C<< Linq {...} >> returns a L<LINQ::Collection> unless the block
includes an aggregating keyword (which must be the final statement
in the block). An aggregating keyword will cause C<Linq> to return
the result of that keyword, which is usually a scalar, except in
the case of the keyword C<ToList>.

=head2 C<< :essential >>

These can be imported using C<< use LINQ::DSL ':essential' >>.

=over

=item C<< Linq { BLOCK } >>

=item C<< From \@array >>

=item C<< From sub { ITERATOR } >>

=item C<< From range => [ $start, $end ] >>

=item C<< From repeat => [ $value, $count ] >>

=item C<< Where { CONDITION } >>

=item C<< Select { EXPRESSION } >>

=item C<< Join $collection, $hints, $leftexpr, $rightexpr, $joinexpr >>

=item C<< GroupBy { EXPRESSION } >>

=item C<< ForEach { BLOCK } >>

=item C<< DefaultIfEmpty $value >>

=back

Additionally, C<:essential> includes C<< HashSmush( $href1, $href2 ) >>.
This combines multiple hashrefs into a single hashref and then converts
that to a blessed object using L<Object::Adhoc>. If the hashrefs contain
overlapping keys, the first one "wins".

=begin Pod::Coverage

=item C<HashSmush>

=end Pod::Coverage

=head2 C<< :join >>

These can be imported using C<< use LINQ::DSL ':join' >>.

=over

=item C<< LeftJoin $collection, $leftexpr, $rightexpr, $joinexpr >>

=item C<< RightJoin $collection, $leftexpr, $rightexpr, $joinexpr >>

=item C<< InnerJoin $collection, $leftexpr, $rightexpr, $joinexpr >>

=item C<< OuterJoin $collection, $leftexpr, $rightexpr, $joinexpr >>

=item C<< GroupJoin $collection, $hints, $leftexpr, $rightexpr, $joinexpr >>

=back

=head2 C<< :sort >>

These can be imported using C<< use LINQ::DSL ':sort' >>.

=over

=item C<< OrderBy $hints, sub { EXPRESSION } >>

=item C<< OrderByDescending $hints, sub { EXPRESSION } >>

=item C<< Reverse >>

=back

=head2 C<< :filter >>

These can be imported using C<< use LINQ::DSL ':filter' >>.

=over

=item C<< Distinct { EXPRESSION } >>

=item C<< Take $count >>

=item C<< TakeWhile { EXPRESSION } >>

=item C<< Skip $count >>

=item C<< SkipWhile { EXPRESSION } >>

=back

=head2 C<< :native >>

These can be imported using C<< use LINQ::DSL ':native' >>.
These keywords are aggregating keywords!

=over

=item C<< ToList >>

=item C<< ToArray >>

=item C<< ToDictionary { KEY EXPRESSION } >>

=item C<< ToIterator >>

=back

=head2 C<< :aggregate >>

These can be imported using C<< use LINQ::DSL ':aggregate' >>.
These keywords are aggregating keywords!

=over

=item C<< Min { EXPRESSION } >>

=item C<< Max { EXPRESSION } >>

=item C<< Sum { EXPRESSION } >>

=item C<< Average { EXPRESSION } >>

=item C<< Aggregate { EXPRESSION } >>

=item C<< Any { TRUTH EXPRESSION } >>

=item C<< All { TRUTH EXPRESSION } >>

=item C<< Contains $item, sub { COMPARATOR } >>

=item C<< Count >>

=item C<< SequenceEqual $other_collection >>

=back

C<Any> and C<All> are very generic-sounding keywords, and C<Any> conflicts
with the function of the same name from L<Types::Standard>, so
C<< use LINQ::DSL ':aggregate_safe' >> can be used to avoid importing
those functions.

=head2 C<< :field >>

These can be imported using C<< use LINQ::DSL ':field' >>.

=over

=item C<< SelectX @fields >>

=item C<< WhereX @checks >>

=item C<< field $name >> 

=item C<< fields @fields >>

=item C<< check_fields @checks >>

=back

See L<LINQ::Util>.
C<SelectX> combines C<Select> and C<fields>.
C<WhereX> combines C<Where> and C<check_fields>.

=head2 C<< :type >>

These can be imported using C<< use LINQ::DSL ':type' >>.

=over

=item C<< Cast $type >>

=item C<< Cast AutoObject >>

=item C<< OfType $type >>

=back

=head2 C<< :combine >>

These can be imported using C<< use LINQ::DSL ':combine' >>.

=over

=item C<< Concat $collection >>

=item C<< Union $collection, sub { COMPARATOR } >>

=item C<< Intersect $collection, sub { COMPARATOR } >>

=item C<< Except $collection, sub { COMPARATOR } >>

=item C<< Zip $collection, sub { EXPRESSION } >>

=back

=head2 C<< :get >>

These can be imported using C<< use LINQ::DSL ':get' >>.
These keywords are aggregating keywords!

=over

=item C<< First { TRUTH EXPRESSION } >>

=item C<< FirstOrDefault { TRUTH EXPRESSION } $default >>

=item C<< Last { TRUTH EXPRESSION } >>

=item C<< LastOrDefault { TRUTH EXPRESSION } $default >>

=item C<< Single { TRUTH EXPRESSION } >>

=item C<< SingleOrDefault { TRUTH EXPRESSION } $default >>

=item C<< ElementAt $index >>

=item C<< ElementAtOrDefault $index, $default >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ::Collection>, L<LINQ::Utils>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
