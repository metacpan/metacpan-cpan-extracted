#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Movie;

use strict qw(vars refs subs);
use Meta::Xml::Parsers::Collector qw();
use Meta::Ds::Array qw();
use Meta::Utils::Time qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.14";
@ISA=qw(Meta::Xml::Parsers::Collector);

#sub new($);
#sub handle_start($$);
#sub handle_end($$);
#sub handle_endchar($$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Xml::Parsers::Collector->new();
	$self->setHandlers(
		"Start"=>\&handle_start,
		"End"=>\&handle_end,
#		"Char"=>\&handle_char,
	);
	bless($self,$class);
	return($self);
}

sub set_dbi($$) {
	my($self,$val)=@_;
	$self->{DBI}=$val;
	$self->{PREP_DIRECTOR}=$val->prepare("INSERT INTO person (id,firstname,lineage,surname,sequential) VALUES (?,?,?,?,?);");
	$self->{PREP_TITLE}=$val->prepare("INSERT INTO movie (id,name,description) VALUES (?,?,?);");
	$self->{PREP_NODATE_VIEW}=$val->prepare("INSERT INTO view (movie) VALUES (?);");
	$self->{PREP_VIEW}=$val->prepare("INSERT INTO view (movie,date) VALUES (?,?);");
	$self->{PREP_AUTH}=$val->prepare("INSERT INTO credit (movie,verification) VALUES (?,?);");
	$self->{PREP_DIRE}=$val->prepare("INSERT INTO participant (person,movie,role) VALUES (?,?,?);");
}

sub handle_start($$) {
	my($self,$elem)=@_;
	$self->SUPER::handle_start($elem);
	if($self->in_context("movie.directors.director",$elem)) {
		$self->{TEMP_DIRECTOR_ID}=undef;
		$self->{TEMP_DIRECTOR_FIRSTNAME}=undef;
		$self->{TEMP_DIRECTOR_LINEAGE}=undef;
		$self->{TEMP_DIRECTOR_SURNAME}=undef;
		$self->{TEMP_DIRECTOR_SEQUENTIAL}=undef;
	}
	if($self->in_context("movie.titles.title",$elem)) {
		$self->{TEMP_TITLE_ID}=undef;
		$self->{TEMP_TITLE_DIRECTOR_LIST}=Meta::Ds::Array->new();
		$self->{TEMP_TITLE_NAME}=undef;
		$self->{TEMP_TITLE_DESCRIPTION}=undef;
		$self->{TEMP_TITLE_VIEWS}=undef;
		$self->{TEMP_TITLE_VIEW_LIST}=Meta::Ds::Array->new();
		$self->{TEMP_TITLE_AUTHORIZATIONS}=undef;
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	$self->SUPER::handle_end($elem);
	if($self->in_context("movie.directors.director",$elem)) {
		#insert director
		my($prep)=$self->{PREP_DIRECTOR};
		my($rv1)=$prep->bind_param(1,$self->{TEMP_DIRECTOR_ID});
		if(!$rv1) { throw Meta::Error::Simple("unable to bind param 1");}
		my($rv2)=$prep->bind_param(2,$self->{TEMP_DIRECTOR_FIRSTNAME});
		if(!$rv2) { throw Meta::Error::Simple("unable to bind param 2");}
		my($rv3)=$prep->bind_param(3,$self->{TEMP_DIRECTOR_LINEAGE});
		if(!$rv3) { throw Meta::Error::Simple("unable to bind param 3");}
		my($rv4)=$prep->bind_param(4,$self->{TEMP_DIRECTOR_SURNAME});
		if(!$rv4) { throw Meta::Error::Simple("unable to bind param 4");}
		my($rv5)=$prep->bind_param(5,$self->{TEMP_DIRECTOR_SEQUENTIAL});
		if(!$rv5) { throw Meta::Error::Simple("unable to bind param 5");}
		my($prv)=$prep->execute();
		if(!$prv) {
			throw Meta::Error::Simple("unable to execute statement");
		}
	}
	if($self->in_context("movie.titles.title",$elem)) {
		#insert title 
		my($prep)=$self->{PREP_TITLE};
		my($rv1)=$prep->bind_param(1,$self->{TEMP_TITLE_ID});
		if(!$rv1) { throw Meta::Error::Simple("unable to bind param 1");}
		my($rv2)=$prep->bind_param(2,$self->{TEMP_TITLE_NAME});
		if(!$rv2) { throw Meta::Error::Simple("unable to bind param 2");}
		my($rv3)=$prep->bind_param(3,$self->{TEMP_TITLE_DESCRIPTION});
		if(!$rv3) { throw Meta::Error::Simple("unable to bind param 3");}
		my($prv)=$prep->execute();
		if(!$prv) {
			throw Meta::Error::Simple("unable to execute statement");
		}
		#insert views with no dates
		$prep=$self->{PREP_NODATE_VIEW};
		$rv1=$prep->bind_param(1,$self->{TEMP_TITLE_ID});
		if(!$rv1) { throw Meta::Error::Simple("unable to bind param 1");}
		my($views)=$self->{TEMP_TITLE_VIEWS};
		for(my($i)=0;$i<$views;$i++) {
			my($prv)=$prep->execute();
			if(!$prv) {
				throw Meta::Error::Simple("unable to execute statement");
			}
		}
		#insert views with dates
		$prep=$self->{PREP_VIEW};
		$rv1=$prep->bind_param(1,$self->{TEMP_TITLE_ID});
		if(!$rv1) { throw Meta::Error::Simple("unable to bind param 1");}
		my($list)=$self->{TEMP_TITLE_VIEW_LIST};
		for(my($i)=0;$i<$list->size();$i++) {
			my($curr)=$list->getx($i);
			$prep->bind_param(2,$curr);
			my($prv)=$prep->execute();
			if(!$prv) {
				throw Meta::Error::Simple("unable to execute statement");
			}
		}
		#insert authorizations
		$prep=$self->{PREP_AUTH};
		$rv1=$prep->bind_param(1,$self->{TEMP_TITLE_ID});
		if(!$rv1) { throw Meta::Error::Simple("unable to bind param 1");}
		my($auth_string)=$self->{TEMP_TITLE_AUTHORIZATIONS};
		my($auth_hash)={
			"i","imdb",
			"v","video_rental",
			"d","have_dvd",
			"b","books",
			"x","have_vhs",
			"m","movie_theater",
			"f","famous",
			"c","cable_view",
			"t","television",
			"p","personal_knowledge",
			"r","dvd_rental",
		};
		for(my($i)=0;$i<length($auth_string);$i++) {
			my($curr)=substr($auth_string,$i,1);
			if(!exists($auth_hash->{$curr})) {
				throw Meta::Error::Simple("unable to translate authorization for [".$curr."]");
			}
			my($auth)=$auth_hash->{$curr};
			$rv2=$prep->bind_param(2,$auth);
			if(!$rv2) { throw Meta::Error::Simple("unable to bind param 2");}
			my($prv)=$prep->execute();
			if(!$prv) {
				throw Meta::Error::Simple("unable to execute statement");
			}
		}
		#insert director (if we have one that is)
		$prep=$self->{PREP_DIRE};
		my($list)=$self->{TEMP_TITLE_DIRECTOR_LIST};
		$rv2=$prep->bind_param(2,$self->{TEMP_TITLE_ID});
		if(!$rv2) { throw Meta::Error::Simple("unable to bind param 2");}
		$rv3=$prep->bind_param(3,"Director");
		if(!$rv3) { throw Meta::Error::Simple("unable to bind param 3");}
		for(my($i)=0;$i<$list->size();$i++) {
			my($curr)=$list->getx($i);
			$rv1=$prep->bind_param(1,$curr);
			if(!$rv1) { throw Meta::Error::Simple("unable to bind param 1");}
			my($prvf)=$prep->execute();
			if(!$prvf) {
				throw Meta::Error::Simple("unable to execute statement");
			}
		}
	}
}

sub handle_endchar($$$) {
	my($self,$elem,$name)=@_;
	$self->SUPER::handle_endchar($elem,$name);
	if($self->in_context("movie.directors.director.id",$name)) {
		$self->{TEMP_DIRECTOR_ID}=$elem;
	}
	if($self->in_context("movie.directors.director.firstname",$name)) {
		$self->{TEMP_DIRECTOR_FIRSTNAME}=$elem;
	}
	if($self->in_context("movie.directors.director.lineage",$name)) {
		$self->{TEMP_DIRECTOR_LINEAGE}=$elem;
	}
	if($self->in_context("movie.directors.director.surname",$name)) {
		$self->{TEMP_DIRECTOR_SURNAME}=$elem;
	}
	if($self->in_context("movie.directors.director.sequential",$name)) {
		$self->{TEMP_DIRECTOR_SEQUENTIAL}=$elem;
	}
	if($self->in_context("movie.titles.title.id",$name)) {
		$self->{TEMP_TITLE_ID}=$elem;
	}
	if($self->in_context("movie.titles.title.directorids.directorid",$name)) {
		$self->{TEMP_TITLE_DIRECTOR_LIST}->push($elem);
	}
	if($self->in_context("movie.titles.title.name",$name)) {
		$self->{TEMP_TITLE_NAME}=$elem;
	}
	if($self->in_context("movie.titles.title.description",$name)) {
		$self->{TEMP_TITLE_DESCRIPTION}=$elem;
	}
	if($self->in_context("movie.titles.title.views",$name)) {
		$self->{TEMP_TITLE_VIEWS}=$elem;
	}
	if($self->in_context("movie.titles.title.viewdates.viewdate",$name)) {
		my($date)=Meta::Utils::Time::unixdate2mysql($elem);
		$self->{TEMP_TITLE_VIEW_LIST}->push($date);
	}
	if($self->in_context("movie.titles.title.authorizations",$name)) {
		$self->{TEMP_TITLE_AUTHORIZATIONS}=$elem;
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Movie - object to import movie XML data into a database.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Movie.pm
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Movie qw();
	my($parser)=Meta::Xml::Parsers::Movie->new();
	$parser->parsefile($file);

=head1 DESCRIPTION

This object parses a movie XML file and plugs the data into a database.
This is much better than using DOM type techniques since it doesnt mean
that the entire data will be at RAM in any single time (more streamlined).

=head1 FUNCTIONS

	new($)
	handle_start($$)
	handle_end($$)
	handle_endchar($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<set_dbi($$)>

This method will set the dbi handle that will be used to insert
the data into the database.

=item B<handle_start($$)>

This will handle start tags.

=item B<handle_end($$)>

This will handle end tags.
This currently does nothing.

=item B<handle_endchar($$$)>

This will handle actual text.
This currently, according to context, sets attributes for the various objects.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Xml::Parsers::Collector(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV some chess work
	0.01 MV more movies
	0.02 MV fix database problems
	0.03 MV books XML into database
	0.04 MV md5 project
	0.05 MV database
	0.06 MV perl module versions in files
	0.07 MV movies and small fixes
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV teachers project
	0.14 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Ds::Array(3), Meta::Utils::Time(3), Meta::Xml::Parsers::Collector(3), strict(3)

=head1 TODO

-what about simultaneously inserting data to two databases ?

-watch the hack in movie.titles.title.name (the .=) - this is because this handler is called more than once for a single string - how can I bypass this shit ?. In addition - why does the parser change charcter entities (&amp;) in the source XML to actual character (&) when giving them to me ? Is my string Unicode ?
