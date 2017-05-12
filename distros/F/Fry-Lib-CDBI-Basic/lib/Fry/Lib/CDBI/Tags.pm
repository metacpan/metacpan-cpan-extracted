#!/usr/bin/perl
package Fry::Lib::CDBI::Tags;
use strict qw/vars refs/; #?forget the subs cause makes hash assignment a pain

#variables
our $tagcolumn='tags';
#our cdbi_search = "search_abstract";
#functions	
	sub _default_data {
		return {
			depend=>[qw/:CDBI::Basic/],
			vars=>{ otlnum=>'3',tag_delimiter=>',' },	
			cmds=>{tagcount=>{qw/a tc aa aliasInputAndSql/},
				tagname=>{qw/a tn aa aliasInputAndSql/},
				auto_outline=>{qw/a ao/},#aa aliasInputAndSql/},
				sorted_tag_list=>{qw/a ts aa aliasInputAndSql/},
				tagcount_obj=>{qw/a :tc/},
				tagname_obj=>{qw/a :tn/},
			},
			opts=>{otlnum=>{qw/a otl type var noreset 1 default 3/ }}
			#	subs=>{qw/g init_tag_group/ }
		}	
	}	

	#shell commands
	sub auto_outline {
		my $class = shift;

		$class->lib->requireLibraries(':CDBI::Outline');
		my @a = $class->aliasInputAndSql(@_);
		my @results = $class->${\$class->Var('cdbi_search')}(@a);
		$class->obj_to_otl(\@_,\@results);
	}
	sub tagcount {
		my $cls =  shift;

		my @results = $cls->${\$cls->Var('cdbi_search')}(@_);
		if (@results > 0) {
			$cls->tagcount_obj(@results)
		}
		else { $cls->view("No search results\n") }
	}
	sub tagname {
		my $cls = shift;
		my @results = $cls->${\$cls->Var('cdbi_search')}(@_);
		if (@results > 0) {
			$cls->tagname_obj(@results)
		}
		else { $cls->view("No search results\n") }
	}
	sub tagcount_obj {
		my ($cls,@obj) = @_;
		my $tags = $cls->get_tags_compact(@obj);
		$cls->print_tags_compact($tags);
	}
	sub tagname_obj {
		my ($cls,@obj) = @_;
		my @sortedtags = $cls->listtags(@obj);
		$cls->print_tags(@sortedtags);
	}
	sub sorted_tag_list {
		my $class = shift;
		my @results = $class->${\$class->Var('cdbi_search')}(@_);
		return sort $class->_unique_result_tags(@results);
	}
	#internal methods
	sub obj_to_otl {
		my $class = shift;
		my @aliasedinput= @{shift()};
		my @results = @{shift()};

		#gives unique tags but in order of most tags
		my @tagnames = map { $_->{name} } $class->listtags(@results);
		if (@tagnames == 0) { $class->view("no taggnames,outline not possible\n"); return}

		#delete first tagname since it's a repeat of parent tag
		shift @tagnames if ("@aliasedinput" =~ /$tagcolumn/);

		#create autoquery
		my @savedtags = splice(@tagnames,0,$class->Var('otlnum'));
		my $input = "@aliasedinput"."(".join(',',@savedtags).")";
		#print "i: $input:\n";

		$class->view($class->outlineSearches($input));
	}
	sub _all_result_tags {
		my ($class,@cdbi) = @_;
		my @tcolumn = map {$_->$tagcolumn} @cdbi;
		return map {split(/${\$class->Var('tag_delimiter')}/,$_) } @tcolumn;
	}
	sub _unique_result_tags {
		my ($class,@cdbi) = @_;
		my @tags = $class->_all_result_tags(@cdbi);
		my %uniq;
		for (@tags) { $uniq{$_}++ }
		return keys %uniq;
	}
	sub listtags {
		#d:returns tags and number of occurences in table
		my ($class,@cdbi) =  @_;
		my @tags = $class->_all_result_tags(@cdbi);
		my (%uniqtag,$result);

		#count + get unique tags
		for (@tags) { $uniqtag{$_}{count}++; }

		#combine count + tagname into @ of %
		@tags=();
		for (keys %uniqtag) {
			push(@tags,{name=>$_,count=>$uniqtag{$_}{count}});
		}
		
		#sort descending
		my @sortedtags = sort {${$b}{count} <=> ${$a}{count}} @tags;
		return @sortedtags;
	} 
	sub get_tags_compact {
		my $class = shift;
		my @sortedtags = $class->listtags(@_);
		my ($i,$j,@body);

		while ($i != @sortedtags -1){
			my $previouscount;

			#print $sortedtags[$i]{count},": ";
			$body[$j]{count} = $sortedtags[$i]{count};
			#print $sortedtags[$i]{name},$class->Var('delim')->{tag};	
			$body[$j]{tags} .= $sortedtags[$i]{name}.  $class->Var('tag_delimiter');

			$previouscount = $sortedtags[$i]{count};
			$i++;

			#create taggroup
			my @taggroup;
			#prints groups of tags with same count 
			while ($sortedtags[$i]{count} == $previouscount) {
				#print $sortedtags[$i]{name},$class->Var('delim')->{tag};	
				push(@taggroup,$sortedtags[$i]{name});
				$previouscount = $sortedtags[$i]{count};
				$i++;
			}	

			$body[$j]{tags} .= join($class->Var('tag_delimiter'),@taggroup);
			$j++;
		}
		return \@body;
	}
	#format fns
	sub print_tags_compact {
		my ($cls,$tags) = @_;
		my $output;

		for (@$tags) {
			$output .= $_->{count}.": ".$_->{tags}."\n";
		}
		$cls->view($output);
	}
	sub print_tags {
		my ($class,@sortedtags) = @_;
		my $result;
		for (@sortedtags) { $result .= "$_->{count}: $_->{name}\n";}
		$class->view($result);
	}


__END__	

	#sub order
		tn
			$search
			tn_obj
				listtags
				print_tags
		tc
			$search
			tc_obj(@cdbi)
				get_tags_compact(@cdbi)
					(@tag_count) listtags
				print_tags_compact
		auto_outline
			$search	
			obj_to_otl(\@search_term,\@cdbi)
		sorted_tag_list
			$search
			unique_result_tags
		
#UPCOMING CODE
	#NEW 3 table model
	sub init_tag_group {
		my $class =  shift; my $c1 = $class;
		no strict 'refs';

		#current table has to be on the 1 end of 1-M relationship
		my $one_table = $class->tb; 
		my $many_table= ($_[0] =~ /^[a-zA-z]/) ? $_[0] : 'tag';
		#because first table always come before tag
		my $second_table = ($many_table ne "tag") ?
		"$many_table\_to_$one_table" : "$one_table\_to_$many_table";

		#define relationship columns(rc)
		#n: could change with new tables
		my ($rc1,$rc21,$rc23,$rc3) = (qw/id cmds_id tag_id id/);
		($rc21,$rc23) = ($rc23,$rc21) if ($one_table eq "tag");

		my $many_method = "many_$many_table";
		my %field_hash = (tag=>'name',cmds=>'cmd');
		my $manycol = $field_hash{$many_table};
		my $one_columns = $class->print_columns;

		#set tables
			$class->set_table($second_table);
			$class->set_table($many_table);
			$class->_flag->{change_class} = 0;

			#h: should be able to set new tables w/o affecting current tables + cols
			$class->tb($one_table);
			$class->print_columns($one_columns);
			$class->cols($one_columns);

		#Three tables' classes
		my $c1 = $class;
		my $c2 = $class->_loader->find_class($second_table);
		my $c3 = $class->_loader->find_class($many_table);

		my %has_arg = (many_method=>$many_method,rc21=>$rc21,rc23=>$rc23,c1=>,$c1,c2=>$c2,c3=>$c3);
		$class->has_triple_table(%has_arg);

		#define triple_table hash
		my %triple_obj = (one_table=>$class->tb,many_table=>$many_table, second_table=>$second_table);
		%triple_obj = (%triple_obj,%has_arg);
		$class->mk_cdata_global(_triple_table=>\%triple_obj);

		#$class->set_columns;
		$c2->columns(TEMP=>$manycol);

		#subs:repeat for each many_col
			#c2 points directly to c3 for this column  
			*{$c2."::".$manycol} = sub { shift->$rc23->$manycol } ;
			#c1 points to c2
			*manycol = 
			sub {
				my ($obj) = shift;
				my @c3_value = map {$_->$manycol} $obj->$many_method;
				return join(',',@c3_value);
			};
			push(@{$class->print_columns},'manycol');
	}
	sub has_triple_table {
		my ($class,%arg) = @_;
		$arg{c2}->has_a($arg{rc23},$arg{c3});
		$arg{c2}->has_a($arg{rc21},$arg{c1});
		$arg{c1}->has_many($arg{many_method}=>$arg{c2});
	}	
	sub insert_tt {
		my $class = shift; 
		my $o1	= shift;
		my %parsed = $class->parseinsert(@_); 
		my @c3_parsed = $class->strip_c3(\%parsed);
		my @o1 = $class->create(\%parsed);
		my ($c2,$c3,@c3);

		#trigger methods or
		for (@c3_parsed) {
			push(@c3,$c3->create($_));
			$c2->create($class->make_dt($_->id,$o1[0]->id));
		}	
	}
	sub strip_c3 {
		my ($class,$parsed) = @_;
		my @c3;
			my %c3;

		for my $k (keys %$parsed) {
			if ($k =~ /^c3\.(.*)/) {	
				my @c3values = split ($class->Var('tag_delimiter'),$parsed->{$k});
				for (my $i =0; $i <= $#c3values; $i++){
					$c3[$i]{$1};
				delete $parsed->{$k};
				}
			}	
		}	
	}	
	sub delete_tt {
		#delete c1
		#del c2
		#del c3 if tag name doesn't exist in *_to_tag
	}

=head1 NAME

Fry::Lib::CDBI::Tags - A Class::DBI library of Fry::Shell for dealing with tables containing a tag column.

=head1 DESCRIPTION 

These functions deal with tables that contain tags. A tag is a keyword
associated with a row. Usually there are multiple tags associated with a row.
Currently all tags for a given row are put in one column 'tags' (name can be
changed via $tag_column) delimited by a comma (changed via the variable
tag_delimiter).  This is a temporary solution since the table isn't normalized
due to the multivalued tags column.

How could I use a tagged table?

Mainly as a mnemonic device.
For example, I have a table that contains all CPAN
modules. To easily remember a module I'll tag it with words like
'handy,todo,try,dbi'. These tags serve as categories for a given module
and thus serve as a good memory aid when trying to remember a module that's
'on the tip of my tongue'.

=head1 COMMANDS

	Note: @search_term indicates same input syntax as search commands in Fry::Lib::CDBI::Basic

	Search based

		tagcount(@search_term): returns groups of tags, grouping them by count
		tagname(@search_term): returns tag count for every tag
		auto_outline(@search_term): returns an outline result of the top $otlnum tags for the given search  
			Ie if a search ('tags=perl) 's three most numerous tags are
			'dbi,magazine,sites', this function would return a result as follows:

				dbi
					#results containing tags dbi and perl
				magazine	
					#results containing tags magazine and perl
				sites
					#results containing tags sites and perl
		sorted_tag_list(@search_term): returns list of sorted tags
					
	Menu based
		tagname_obj(@cdbi): returns &tagname output
		tagcount_obj(@cdbi): returns &tagcount output

=head1 SEE ALSO

L<Fry::Shell>,L<Fry::Lib::CDBI::Outline>

http://del.icio.us is a community bookmarking site which uses tags heavily.

L<Rubric> is a CPAN implementation similar to it.

=head1 TODO

Normalize the tags column by adding another table to add a LOT more functionality to
tags.

=head1 AUTHOR

Me. Gabriel that is. If you want to bug me with a bug: cldwalker@chwhat.com
If you like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.
