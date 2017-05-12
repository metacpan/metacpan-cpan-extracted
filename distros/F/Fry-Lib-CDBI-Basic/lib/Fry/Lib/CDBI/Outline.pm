#!/usr/bin/perl
#declarations
package Fry::Lib::CDBI::Outline;
use strict;
#because of use of local
no strict 'vars';
our $VERSION = '0.14';
#our cdbi_search = "search_abstract";

#our ($left,$right,$even,$otlcol,$indent_char) = ('\)','\(',',','tags',"\t");
#our $tree_result;
#our $ind;

#functions
	sub _default_data {	
		return {
			#causes action_columns to be uninit when using Load
			depend=>[qw/:CDBI::Basic/],
			cmds=>{outlineSearches=>{a=>'O',d=>'presents several database queries in an outline format',
				u=>'($search_term$level_delimiter)+'}},
			vars=>{right_indent=>'\(',no_indent=>',',left_indent=>'\)',otlcol=>'tags',indent_char=>"\t"},
			#tr make_tree_simple trr make_tree_results/},
			#flags=>{qw/L last_tag tt triple_table/},	
		}	
	}
	#print
	sub print_indented_rows {
		my $class =shift;
		my @rows = @{shift()};
		my @columns = @{shift()};
		my $indent = shift;
		my $data;
		my $ind = $indent_char x ($indent + 1);

		return "" if (@rows  == 0);

		for my $row (@rows) {
			for my $c (@columns) {
				$data .= ($row->$c || "");
				$data .= $class->Var('field_delimiter');
			}
			$data .= "\n";
		}

		$data =~ s/^/$ind/mg;
		return $data;
	}
	#internals
	sub search_outline {
		my $class = shift; 

		my @search = $class->aliasInputAndSql(@_);
		my @results = $class->${\$class->Var('cdbi_search')}(@search);
		return @results;

		#if ($class->Flag('triple_table') && $class->can('_triple_table')) {
			#@results =  map { $_->${\$class->_triple_table->{rc23}} }
			#map { $_->${\$class->_triple_table->{many_method}} } @results;
			#use Data::Dumper;
			#print Dumper \@results;
		#}
	}
	sub input_to_nodes {
		my $class = shift;
		my $entry ="@_"; 

		$entry =~ s/[$left$right$even]$//;
		$entry =~ s/([$left$right$even])/\n$1/g;
		$entry =~ s/^/$even/;

		return split(/\n/,$entry);
	}
	sub get_indents {
		#d:create indents associated with @entry
		#increment,decrement or do nothing too match level of $ith item
		my $class = shift;
		my @entry = @_;
		my @indent;
		$indent[0]=0;

		for (my $i=1;$i <@entry;$i++) {
			for (substr($entry[$i],0,1)) {
				/^$left$/ && do {$indent[$i]=$indent[$i-1]-1;last };
				/^$right$/ && do {$indent[$i]=$indent[$i-1]+1;last};
				/^$even$/ && do {$indent[$i] = $indent[$i-1];last };
			}
		}
		return @indent;
	}
	sub get_values {
		my $class = shift;
		my @values = @_;

		for (@values) {$_ = substr($_,1);}	#chop first letters off of array
		return @values;
	}
	sub alias_otl {
		#d:pass search terms to list fn,have special %% term
		my $class = shift;
		my @terms = @_;
		my (@sameterms,@normterms,$sameterm,@rows,@input);
		my $splitter = $class->Var('splitter');

		#parse terms
		for (@terms) {
			#(/=/) ? push(@normterms,$_) : push(@sameterms,$_)  ;
			#above line turned into below if/else

			#default tag column assumed when no splitter present
			if ($_ !~ /$splitter/) {
				push(@input,$otlcol.$splitter.$_);
			}	
			else { push(@input,$_);	}	
		}

		return @input;
	}
	sub set_results {
		#d:inserts results at proper outline levels into @tags
		my $class = shift;
		my @otl_obj = @{shift()};
		my @stack;	#stack stack for a given level
		my $max = scalar(@otl_obj);
		#turn off warnings about uninitialized comparisons
		local $SIG{__WARN__} = sub { return $_[0] unless $_[0] =~ m/Use of uninitialized value/; };

		for (my $i=0;$i <$max;$i++) {		#creates an array of base otl_obj for next search term
			#doesn't have child	
			if ($otl_obj[$i]{indent} >= $otl_obj[$i+1]{indent}) {
				$otl_obj[$i]{result} = [$class->search_outline($class->alias_otl($otl_obj[$i]{value},@stack))];
			}

			#if next obj is a child (a greater indent) then add to stack
			if ($otl_obj[$i]{indent} < $otl_obj[$i+1]{indent}) {push(@stack,$otl_obj[$i]{value});}
			#if not child then pop
			elsif ($otl_obj[$i]{indent} > $otl_obj[$i+1]{indent}) {pop(@stack);}
		}
		pop(@otl_obj); 	#created accidently by autovivification
		return @otl_obj;
	} 
	sub makeNodeOutline {
		#d:display @otl_obj in outline format
		my $class = shift;
		my @otl_obj = @_;
		my @tag;	#tag stack for a given level
		my ($body);
		#h: scalar works here but not in for loop
		my $max = scalar(@otl_obj);
		#turn off warnings about uninitialized comparisons
		local $SIG{__WARN__} = sub { return $_[0] unless $_[0] =~ m/Use of uninitialized value/; };

		for (my $i=0;$i <$max;$i++) {		#creates an array of base otl_obj for next search term
			$ind = $indent_char x $otl_obj[$i]{indent};
			$body .= $ind . "$otl_obj[$i]{value}\n";

			#h: need var for other tables' print columns
			#$class->action_columns([qw/id cmd tags options notes/]) if ($class->can('_triple_table')) ;
			#my @c3_columns = (qw/id name parent_id notes/) ;
			my @columns = @{$class->Var('action_columns')};

				#if ($class->Flag('triple_table')) {
					#($class->can('_triple_table')) 
						#? @columns = $class->_triple_table->{c3}->columns 
						#: warn "_triple_table isn't defined";
				#}		
				#my @c3_columns = $class->_triple_table->{c3}->columns;
				#my @columns = ($class->_flag->{triple_table}) ? @c3_columns : @{$class->action_columns};

			#doesn't have child	+ has results
			if ($otl_obj[$i]{indent} >= $otl_obj[$i+1]{indent}) { 
				$body  .= $class->print_indented_rows ($otl_obj[$i]{result},
				\@columns,$otl_obj[$i]{indent});
			}
		}
		return $body;
	} 
	sub get_outline {
		#d:parses input + returns data to make outline
		my $class = shift;
		my (@otl_obj);
		#@otl_obj are @ of % with indent,value and result keys

		my @bits = $class->input_to_nodes(@_);
		my @indent = $class->get_indents(@bits);
		my @value = $class->get_values(@bits);

		#creating @ of % for otl_obj
		for (my $i=0;$i<@indent;$i++) {
			$otl_obj[$i]{value} = $value[$i];
			$otl_obj[$i]{indent} = $indent[$i];
		} 

		$class->set_results(\@otl_obj);
		return \@otl_obj;
	}	
	#main function calling all the above 
	sub create_outline {
		my $class =  shift;

		my @otl_obj = @{$class->get_outline(@_)};
		my $body = $class->makeNodeOutline(@otl_obj);

		return $body;
	}

#shell function
	sub outlineSearches {
		my $cls = shift;
		#td: change to global variables
		local ($right,$even,$left,$otlcol,$indent_char) =
			$cls->varMany(qw/right_indent no_indent left_indent otlcol indent_char/);
		local $tree_result;
		local $ind;
		$cls->view($cls->create_outline(@_));
	}	
1;

__END__	

#UPCOMING CODE
	sub make_tree_results {
		my ($class,$tagname) = @_;

		$class->make_tree(sub {tree2otl(@_) },$tagname);

		#since results from make_tree should only feed back to tag.name
		$otlcol = "name";
		$class->_flag->{last_tag} = 1;
		$class->outlineSearches($tree_result);
		$class->_flag->{last_tag} = 0;

		#print "t: $tree_result\n";
		$otlcol = "tags";
		$tree_result = "";
	}
	sub make_tree_simple { 
		my ($class,$tagname) = @_;
		$class->make_tree(sub {disp_tree(@_)},$tagname);
	}

	#tree innards
	{
	my $lastlevel =0;
	sub tree2otl {
		my %parms = @_;
		my $item  = $parms{item};
		my $level = $parms{level};

		$item =~ s/^\s+//;
		$item =~ s/\s+$//;

		my $difference = $level - $lastlevel;
		my $level_char;
		if ($difference >= 1) { $level_char = "(" }
		elsif ($difference == 0) { $level_char = ","}
		elsif ($difference == -1) {$level_char = ")" }
		else { die "difference error of tree levels from $lastlevel to $level"; return }	

		#initialize search w/o '('
		$tree_result .= ($tree_result) ? "$level_char$item" : $item;
		$lastlevel = $level;
	}
	sub disp_tree {
		my %parms = @_;
		my $item  = $parms{item};
		my $level = $parms{level};

		$item =~ s/^\s+//;
		$item =~ s/\s+$//;

		print "\t" x ($level - 1), "$item\n";
		$lastlevel = $level;
	}
	}
	sub make_tree {
		my ($class,$tree_method,$tagname) = @_;

		use DBIx::Tree;
		my ($db,$tb) = (qw/useful tag/);
		my @dbiparms = ("dbi:Pg:dbname=$db",'bozo','');
		use DBI;
		my $dbh = DBI->connect(@dbiparms);
		if ( !defined $dbh ) { die $DBI::errstr; }
		my $tag_id = (defined $tagname) ? ($dbh->selectrow_array("select id from $tb where name =
		'$tagname'"))[0] : '0';

		my $tree = new DBIx::Tree( connection => $dbh, 
			table      => $tb, 
			#method     => sub { disp_tree(@_) },
			method     => $tree_method,
			#columns    => ['food_id', 'food', 'parent_id'],
			columns=>[qw/id name parent_id/], 
			start_id   => $tag_id);

		$tree->traverse;
		$dbh->disconnect;

	}

=head1 NAME

Fry::Lib::CDBI::Outline - A Class::DBI library for Fry::Shell which displays several database queries in an
outline format.

=head1 VERSION

This document describes version 0.14

=head1 DESCRIPTION 

This module has one command, outlineSearches, which takes a query outline and produces results in the same
outline format.  To write an outline in one line for commandline apps, there is a shorthand syntax.
Take the sample outline:

	0 dog
		1 rex
		1 cartoon
			2 snoopy
			2 brian
	0 cat	

	Note: the numbers are the outline levels and aren't usually seen

In shorthand syntax this is 'dog(rex,cartoon(snoopy,brian))cat'.
I'll use node to refer to a line in an outline ie 'dog'.
There are three characters that delimit indent levels between nodes:

	'(':following node is indented one level
	')': following node is unindented one level
	',': following node remains at same level

Each node is a query chunk which uses the same syntax as
the search commands in Fry::Lib::CDBI::Basic. 

For example, here's a simple query outline:

	tag=perl(tag=dbi,read)name=Shell::

which means the following query outline:

	tags=perl
		tags=dbi
		read
	name=Shell::

which would produce:  

	tags=perl
		tags=dbi
			#results of tags=dbi and tags=perl
		read
			#results of tags=read and tags=perl
	name=Shell::
		#results of name=Shell:

The resulting outline produces results under the last level children. By default the query chunks
('tags=perl') are ANDed. If no $splitter ('=' here) is in a given query chunk then a default column name
is assumed by $otlcol. In this example, $otlcol = 'tags' for the 'read' node.

Although there is no required table format I usually use this module for tables that I'm tagging.
See Fry::Lib::CDBI::Tags for more detail.

=head1 LIBRARY VARIABLES

	right_indent: Increases outline level by one.
	no_indent: Outline level remains the same.
	left_indent:  Decreases outline level by one.
	otlcol:  column assumed in searches when no column given
	indent_char: Character used to indent nodes

=head1 INNARDS of outlineSearches

The subroutines are indented by subroutine frame and are called in the order
they appear.

	outlineSearches
		create_outline
			get_outline	
				input_to_nodes
				get_indents
				get_values
				set_results
					alias_otl
					search_outline
			makeNodeOutline
				print_indented_rows

	outlineSearches(@outline_terms): command which returns outline of search results,
		an $outline_term is equal to $search_term$level_delimiter where
		$search_term is the same as in Fry::Lib::CDBI::Basic and a
		$level_delimiter is one of the variables $indent,$no_indent or
		$left_indent
	create_outline(@outline_terms): wrapper sub
	get_outline(@outline_terms): Returns an arrayref of node objects. A node
		object contains the following attributes:
			value: search term used by search functions
			results: Class::DBI objects from search
			indent: indent/outline level
	input_to_nodes(@outline_terms): splits input on a $level_delimiter to return array of nodes
	get_indents(@input_to_nodes): returns an indent value for each node based on a $level_delimiter
	get_values(@get_indents): returns a value for each node
	set_results(\@node): sets results attribute of a node object
	alias_otl(@search_terms): unaliases outline search terms to make it compatible with
		:CDBI::Basic search terms 
	search_outline(@search_terms): does a search using one of the search functions from
		:CDBI::Basic
	makeNodeOutline(@node): makes a node outline by indenting properly and displaying Class::DBI
		search results

=head1 SEE ALSO

L<Fry::Shell>,L<Fry::Lib::CDBI::Tags>

=head1 AUTHOR

Me. Gabriel that is. If you want to bug me with a bug: cldwalker@chwhat.com
If you like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.
