package Ftree::FamilyTreeInfo;

use strict;
use warnings;

use Ftree::FamilyTreeBase;

use v5.10.1;
use experimental 'smartmatch';
use Params::Validate qw(:all);
use Sub::Exporter -setup => { exports => [qw(new main)] };
use Encode qw(decode_utf8);
use utf8;

our $VERSION = '2.3.41';

my $q = new CGI;

use base 'Ftree::FamilyTreeBase';

sub new {
	my $type = shift;
	my $self = $type->SUPER::new(@_);
	$self->{family_tree_data} =
	  Ftree::FamilyTreeDataFactory::getFamilyTree(
		$self->{settings}{data_source} );
	$self->{pagetype} = undef;
	return $self;
}

sub main {
	my ($self) = validate_pos( @_, { type => HASHREF } );
	$self->_process_parameters();
	$self->SUPER::_password_check();

	for ( $self->{pagetype} ) {
		when (/^$/)          { $self->_draw_index_page(); }
		when (/subfamily/) { $self->_draw_same_surname_page(); }
		when (/snames/)    { $self->_draw_surname_page(); }
		when (/faces/)     { $self->_draw_facehall_page(); }
		when (/emails/) {
			$self->_draw_general_page(
				\&Ftree::Person::get_email, 'email',
				$self->{textGenerator}->{Emails},
				$self->{textGenerator}->{Total_with_email}
			);
		}
		when (/hpages/) {
			$self->_draw_general_page(
				\&Ftree::Person::get_homepage,
				'homepage',
				$self->{textGenerator}->{Homepages},
				$self->{textGenerator}->{Total_with_homepage}
			);
		}
		when (/bdays/) { $self->_draw_birthday_page(); }
		default        { $self->_draw_invalid_page(); }
	}

	return;
}

#######################################################
# processing the parameters (type and passwd)
sub _process_parameters {
	my ($self) = validate_pos( @_, { type => HASHREF } );
	$self->SUPER::_process_parameters();
	$self->{pagetype} = $self->{cgi}->param('type');
	$self->{pagetype} = "" unless ( defined $self->{pagetype} );

	return;
}

# private functions
sub _draw_people_table {
	my ( $self, $people, $column_number ) = validate_pos(
		@_,
		{ type    => HASHREF },
		{ type    => ARRAYREF },
		{ defaulf => 5 }
	);
	$column_number = 5 unless defined $column_number;    #AAARRRRGGGHHH
	my $nr_of_man   = 0;
	my $nr_of_woman = 0;
	print $self->{cgi}->start_table(
		{ -cellpadding => '5', -border => '1', -align => 'center' } ), "\n";

	for my $index ( 0 .. @{$people} - 1 ) {
		print $self->{cgi}->start_Tr() if ( $index % $column_number == 0 );
		my $class = $self->get_cell_class( $people->[$index], \$nr_of_man,
			\$nr_of_woman );
		print $self->{cgi}->td(
			{ -class => $class },
			$self->aref_tree(
				$people->[$index]->get_name()->get_long_name(),
				$people->[$index]
			)
		  ),
		  "\n";
		print $self->{cgi}->end_Tr()
		  if ( ( $index % $column_number ) == $column_number - 1 );
	}
	print $self->{cgi}->end_Tr(), "\n"
	  if ( ( @{$people} % $column_number ) != 1 );

	print $self->{cgi}->end_table(), "\n", $self->{cgi}->br,
	  $self->{textGenerator}->summary( scalar( @{$people} ) ),
	  " ($self->{textGenerator}{man}: ",   $nr_of_man,
	  ", $self->{textGenerator}{woman}: ", $nr_of_woman,
	  ", $self->{textGenerator}{unknown}: ",
	  scalar( @{$people} ) - $nr_of_man - $nr_of_woman, ')';

	return;
}
#########################################################
# INDEX PAGE
#########################################################
sub _draw_index_page {
	my ( $self, $column_number ) = validate_pos( @_,
		{ type => HASHREF }, { type => SCALAR, optional => 1 } );
	my @people = grep { defined $_->get_name() }
	  $self->{family_tree_data}->get_all_people();
	@people = sort {
		$a->get_name()->get_full_name() cmp $b->get_name()->get_full_name()
	} @people;
	$self->_toppage( $self->{textGenerator}->{members} );
	$self->_draw_people_table( \@people, $column_number );
	$self->_endpage();

	return;
}

#########################################################
# Same surname people
#########################################################
sub _draw_same_surname_page {
	my ( $self, $column_number ) = validate_pos( @_,
		{ type => HASHREF }, { type => SCALAR, optional => 1 } );
	my $surname = decode_utf8( $self->{cgi}->param('surname') );
	$surname = "" unless ( defined $surname );
	my @people = grep {
		defined $_->get_name()
		  && $_->get_name()->get_last_name() eq $surname
	} $self->{family_tree_data}->get_all_people();

	@people = sort {
		$a->get_name()->get_full_name() cmp $b->get_name()->get_full_name()
	} (@people);
	$self->_toppage( $self->{textGenerator}->People_with_surname($surname) );
	$self->_draw_people_table( \@people, $column_number );
	$self->_endpage();

	return;
}

#########################################################
# SURNAME PAGE
#########################################################
sub _draw_surname_page {
	my ( $self, $column_number ) = validate_pos( @_,
		{ type => HASHREF }, { type => SCALAR, optional => 1 } );
	$column_number = 8 unless ( defined $column_number );

	require Set::Scalar;
	my $last_name_set = Set::Scalar->new;
	for my $person ( $self->{family_tree_data}->get_all_people() ) {
		$last_name_set->insert( $person->get_name()->get_last_name() )
		  if ( ( defined $person->get_name() )
			&& ( defined $person->get_name()->get_last_name() ) );
	}

	$self->_toppage( $self->{textGenerator}->{Surnames} );

	while ( defined( my $a_last_name = $last_name_set->each ) ) {
		push @{ $self->{nodes} }, $a_last_name;
	}
	my @sortednodes = sort @{ $self->{nodes} };

	print $self->{cgi}->start_table(
		{ -cellpadding => '5', -border => '1', -align => 'center' } ), "\n";
	for my $people_count ( 0 .. $#sortednodes ) {
		print $self->{cgi}->start_Tr()
		  if ( $people_count % $column_number == 0 );
		print $self->{cgi}->td(
			$self->{cgi}->a(
				{
					-href =>
"$self->{treeScript}?type=subfamily&surname=$sortednodes[$people_count]&lang=$self->{lang}"
				},
				$sortednodes[$people_count]
			)
		);
		print $self->{cgi}->end_Tr(), "\n"
		  if ( $people_count % $column_number == $column_number - 1 );
	}
	print $self->{cgi}->end_Tr(), "\n"
	  if ( $#sortednodes % $column_number != 0 );
	print $self->{cgi}->end_table(), "\n", $self->{cgi}->br,
	    $self->{textGenerator}->{Total} . ' '
	  . $last_name_set->size . ' '
	  . $self->{textGenerator}->{people};
	$self->_endpage();

	return;
}

sub _draw_general_table {
	my ( $self, $func, $attribute, $people_with_type_r, $text2 ) = validate_pos(
		@_,
		{ type => HASHREF },
		{ type => CODEREF },
		{ type => SCALAR },
		{ type => ARRAYREF },
		{ type => SCALAR }
	);
	my $nr_of_man   = 0;
	my $nr_of_woman = 0;

	print $self->{cgi}->start_table(
		{ -cellpadding => '5', -border => '1', -align => 'center' } ), "\n",
	  $self->{cgi}->Tr(
		$self->{cgi}->th( $self->{textGenerator}{photo} ),
		$self->{cgi}->th( $self->{textGenerator}{name} ),
		$self->{cgi}->th( $self->{textGenerator}{$attribute} )
	  );

	foreach my $a_person ( @{$people_with_type_r} ) {
		my $class =
		  $self->get_cell_class( $a_person, \$nr_of_man, \$nr_of_woman );
		print $self->{cgi}->start_Tr( { -class => $class } ),
		  $self->{cgi}->td( $self->html_img($a_person) ),

		  $self->{cgi}->td(
			$self->aref_tree(
				$a_person->get_name()->get_full_name(), $a_person
			)
		  ),
		  $self->{cgi}->td( $func->($a_person) ),
		  $self->{cgi}->end_Tr, "\n";
	}
	print $self->{cgi}->end_table, "\n", $self->{cgi}->br, $text2,
	  scalar( @{$people_with_type_r} ),
	  " ($self->{textGenerator}{man}: ",   $nr_of_man,
	  ", $self->{textGenerator}{woman}: ", $nr_of_woman,
	  ", $self->{textGenerator}{unknown}: ",
	  scalar( @{$people_with_type_r} ) - $nr_of_man - $nr_of_woman, ")";

	return;
}
#########################################################
# GENERAL PAGE
#########################################################
sub _draw_general_page {
	my ( $self, $func, $attribute, $title, $text2 ) = validate_pos(
		@_,
		{ type => HASHREF },
		{ type => CODEREF },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR }
	);

	my @people_with_type =
	  grep { defined $func->($_) }
	  ( grep { defined $_->get_name() }
		  $self->{family_tree_data}->get_all_people() );
	@people_with_type = sort {
		$a->get_name()->get_full_name() cmp $b->get_name()->get_full_name()
	} (@people_with_type);

	$self->_toppage($title);
	$self->_draw_general_table( $func, $attribute, \@people_with_type, $text2 );
	$self->_endpage();

	return;
}

#########################################################
# BIRTHDAYS PAGE
#########################################################
sub _draw_birthday_page {
	my ($self) = validate_pos( @_, { type => HASHREF } );
	my $months = $self->{textGenerator}->{months_array};
	my $month = decode_utf8( $self->{cgi}->param('month') );

	if ( !defined $month ) {
		$month = (localtime)[4] + 1;
	}
	else {
		my $index = 0;
		++$index while ( $months->[$index] ne $month );
		$month = $index + 1;
	}

	my @people_with_bday = grep {
		     defined $_->get_name()
		  && defined $_->get_date_of_birth()
		  && defined $_->get_date_of_birth()->{month}
		  && $_->get_date_of_birth()->{month} == $month
	} ( $self->{family_tree_data}->get_all_people() );

	my $title = $self->{textGenerator}->birthday_reminder( $month - 1 );
	$self->_toppage($title);
	@people_with_bday = sort {
		$a->get_name()->get_full_name() cmp $b->get_name()->get_full_name()
	} (@people_with_bday);

	$self->_draw_general_table( \&Ftree::Person::get_date_of_birth,
		'date_of_birth', \@people_with_bday,
		$self->{textGenerator}->total_living_with_birthday( $month - 1 ) );

	# Add the button for other months
	print $self->{cgi}->start_form(
		{
			-action => $self->{treeScript},
			-method => 'get'
		}
	  ),
	  "\n$self->{textGenerator}->{CheckAnotherMonth}:\n",
	  $self->{cgi}->start_Select(
		{
			-name => 'month',
			-size => 1
		}
	  ),
	  "\n";
	for my $index ( 0 .. 11 ) {
		if ( $index == ( $month - 1 ) ) {
			print $self->{cgi}
			  ->option( { -selected => "selected" }, $months->[$index] ), "\n";
		}
		else {
			print $self->{cgi}->option( $months->[$index] ), "\n";
		}
	}
	print $self->{cgi}->end_Select, "\n",
	  $self->{cgi}
	  ->input( { -type => 'hidden', -name => "type", -value => "bdays" } ),
	  "\n",
	  $self->{cgi}->input(
		{
			-type  => 'hidden',
			-name  => 'password',
			-value => $self->{settings}{password}
		}
	  ),
	  "\n",
	  $self->{cgi}->input(
		{ -type => 'hidden', -name => 'lang', -value => $self->{lang} } ), "\n",

	  $self->{cgi}->input(
		{ -type => "submit", -value => "$self->{textGenerator}->{Go}" } ),
	  $self->{cgi}->end_form;

	$self->_endpage();

	return;
}
#########################################################
# Facehall page
#########################################################
sub _draw_facehall_page {
	my ($self) = validate_pos( @_, { type => HASHREF } );
	my $column_number = 5;

	my @people_with_photo =
	  grep { defined $_->get_name() && defined $_->get_default_picture() }
	  ( $self->{family_tree_data}->get_all_people() );
	@people_with_photo = sort {
		$a->get_name()->get_full_name() cmp $b->get_name()->get_full_name()
	} (@people_with_photo);

	$self->_toppage( $self->{textGenerator}->{Hall_of_faces} );

	my $nr_of_man   = 0;
	my $nr_of_woman = 0;
	print $self->{cgi}
	  ->start_table( { -cellpadding => '7', -align => 'center' } ), "\n";

	foreach my $index ( 0 .. $#people_with_photo ) {
		print $self->{cgi}->start_Tr, "\n" if ( $index % $column_number == 0 );
		my $class = $self->get_cell_class( $people_with_photo[$index],
			\$nr_of_man, \$nr_of_woman );
		print $self->{cgi}
		  ->start_td( { -class => $class, -align => 'center' } ),
		  $self->aref_tree( $self->html_img( $people_with_photo[$index] ),
			$people_with_photo[$index] ),
		  $self->{cgi}->br,
		  $people_with_photo[$index]->get_name()->get_full_name(),
		  $self->{cgi}->end_td;
		print $self->{cgi}->end_Tr, "\n"
		  if ( $index % $column_number == $column_number - 1 );
	}
	print $self->{cgi}->end_Tr, "\n"
	  if ( $#people_with_photo % $column_number != 0 );
	print $self->{cgi}->end_table, "\n", $self->{cgi}->br,
	  $self->{textGenerator}->{Total_with_photo}, scalar(@people_with_photo),
	  " ($self->{textGenerator}{man}: ",   $nr_of_man,
	  ", $self->{textGenerator}{woman}: ", $nr_of_woman,
	  ", $self->{textGenerator}{unknown}: ",
	  scalar(@people_with_photo) - $nr_of_man - $nr_of_woman, ")";
	print $self->{cgi}
	  ->start_table( { -cellpadding => '7', -align => 'center' } ), "\n";
	print $self->{cgi}->start_Tr;
	print $self->{cgi}->start_td( { -align => 'center' } );
	print $self->{cgi}->br, " $self->{textGenerator}{Prayer_for_the_living}: ";

	foreach my $index ( 0 .. $#people_with_photo ) {
		if ( $people_with_photo[$index]->get_is_living() ) {
			print $self->{cgi}->br,
			  $people_with_photo[$index]->get_name()->get_first_name(), ' (',
			  $people_with_photo[$index]->get_name()->get_full_name(),  ')';
		}
	}

	print $self->{cgi}->end_td;

	print $self->{cgi}->start_td( { -align => 'center' } );
	print $self->{cgi}->br,
	  " $self->{textGenerator}{Prayer_for_the_departed}: ";
	foreach my $index ( 0 .. $#people_with_photo ) {
		if ( !$people_with_photo[$index]->get_is_living() ) {
			print $self->{cgi}->br,
			  $people_with_photo[$index]->get_name()->get_first_name(), ' (',
			  $people_with_photo[$index]->get_name()->get_full_name(),  ')';
		}
	}
	print $self->{cgi}->end_td;

	print $self->{cgi}->end_Tr, "\n";

	print $self->{cgi}->end_table, "\n", $self->{cgi}->br;

	$self->_endpage();

	return;
}
#########################################################
# INVALID PAGE TYPE ERROR
#########################################################
sub _draw_invalid_page {
	my ($self) = validate_pos( @_, { type => HASHREF } );
	$self->_toppage( $self->{textGenerator}->{Error} );

	print $self->{textGenerator}->{Invalid_option}, $self->{cgi}->br, "\n",
	  $self->{textGenerator}->{Valid_options};

	$self->_endpage();
	exit 1;
}

1;
__END__
=encoding utf-8

=for stopwords

=head1 NAME

Ftree - family tree generator

=head1 EXAMPLE

L<https://still-lowlands-7377.herokuapp.com>

=head1 SYNOPSIS

installator for Windows 7 32bit
L<https://sourceforge.net/projects/family-tree-32/files/latest/download?source=navbar>

  #If install it
  cpanm FamilyTreeInfo

  #copy the folder cgi-bin from the distribution
  cp cgi-bin c:\ftree\cgi-bin

  #then got to it directory
  c:\ftree\cgi-bin
  #and run
  plackup

  #HTTP::Server::PSGI: Accepting connections at http://0:5000/

  #now go to the browser
  http://127.0.0.1:5000/

  #and we can see a family tree, and
  #to his Office just need to edit the file
  c:\ftree\cgi-bin\tree.xls

  #or the file with a different name, but then this name must indicate file
  ftree.config
  #changing parameter
  file_name tree.xls
  #on your

  #and pictures of relatives should be 3 x 4
  #and they need to be put in the directory
  c:\ftree\cgi-bin\pictures
  #where the name of the picture must be a person id + .jpg
  #all works!

  #for Unix you will need to fix option

  photo_dir c:/ftree/cgi-bin/pictures/

  #on your

=head1 OTHER Guts (you never need to read it)

=head1 PACKAGE CONTENTS:

  readme.txt                     This file
  config/PerlSettingsImporter.pm Settings file
  cgi/ftree.cgi                  The main perl script
  cgi/*.pm                       Other perl modules
  tree.txt, tree.xls, royal.ged  Example family tree data files
  license.txt                    The GNU GPL license details
  changes.txt					   Change history
  pictures/*.[gif,png,jpg,tif]   The pictures of the relatives
  graphics/*.gif                 The system graphic files

=head1 OVERVIEW:

When I designed the Family Tree Generator, I wanted more than just an online version of a traditional tree. With this software it is possible to draw a tree of ancestors and descendants for any person, showing any number of generations (where the information exists).
Most other web-based "trees" are little more than text listings of people.

A simple datafile contains details of people and their relationships. All the HTML pages are generated on the fly. This means that the tree is easy to maintain.

Note that the tree shows the "genetic" family tree. It contains no information about marriages and adaptation.

For a demonstration of this software, visit http://www.ilab.sztaki.hu/~bodon/Simpsons/cgi/ftree.cgi or http://www.ilab.sztaki.hu/~bodon/ftree2/cgi/ftree.cgi.

The program is written in Perl.
It runs as a CGI program - its output is the HTML of the page that you see.
The program reads in the data file, and analyzes the relationships to determine the ancestors, siblings and descendants of the person selected.
HTML tables are generated to display these trees, linking in the portrait images where they exist.

=head1 INSTALLATION INSTRUCTIONS:

1. Set up your web server (apache or IIS) so that it can run Perl scripts (e.g. mod-perl).

2. Uncompress and copy the demo package (make sure that you reserve the rights, i.e. files with extension pm, gif, jpg, png, tif, csv, txt, xls must be readable, files with extension cgi and pl must be executable).

3. Modify tree.xls so that it contains the details of your family. Tip: Select the second row, click on menu Window and select Freeze Panels. This will freeze the first row and you can see the title of columns.
   See format description below.

4. Update the config/PerlSettingsImporter.pm file (you can specify the administrator's email, homepage, default language etc.).

5. Copy the pictures of your family members to the pictures directory.

6. That's it.
   Call the ftree.cgi script with no parameters to get your index page.

7. If you are unhappy with the style and colors of the output then point the css_filename entry in PerlSettingsImporter.pm into your stly sheet.

=head1 INSTALLATION INSTRUCTIONS FOR XAMPP for Windows 5.6.12:

Download I use xampp XAMPP for Windows 5.6.12 (https://www.apachefriends.org/ru/download.html) to install and configure Apache

  <IfModule alias_module>
  ScriptAlias /cgi-bin/ "C:/xampp/cgi-bin/ftree/cgi/"
  </IfModule>

  <Directory "C:/xampp/cgi-bin/ftree/cgi">
  AllowOverride All
  Options None
  Require all granted
  </Directory>

My shebang in ftree.cgi is #!"c:\Dwimperl\perl\bin\perl.exe" (by Gabor Sabo)

  copy c:\xampp\cgi-bin\ftree\graphics\
  to
  c:\xampp\htdocs\graphics\

to correct show images

I catch error couldn't create child process: 720002
------------------------
It was the first line in the .cgi file that needed to be adapted to Xamp's configuration:

  #!"c:\xampp\perl\bin\perl.exe"
  Instead of:

  #!"c:\perl\bin\perl.exe"

https://forum.xojo.com/20697-couldn-t-create-child-process-720002-error-when-deploying-on-wi/0
http://open-server.ru/forum/viewtopic.php?f=6&t=1059

=head1 NAME OF THE PICTURE:

  One picture may belong to each person.
  No image put here and name=id.jpg
  c:\xampp\cgi-bin\ftree\pictures\

=head1 DATAFILE FORMAT:

  The program can handle excel, csv (txt), gedcom, serialized files and can get data from database. Follow these rules to decide which one to use:
  1, Use gedcom if you already have your family tree data in a gedcom file and the fields that the program is able to import is sufficient.
  2, Use the excel format if you just started to build your family tree data.
  3, Convert your data file into serialized format if the data file contains many people (like some thousand) and you would like to reduce response time and memory need.

  Data format history:
  Originally the input file was a csv flat file with semicolon as the separator. It could store 6 fields for each person (name, father name, mother name, email, webpage, date of birth/death). As new fields were required (like gender, place of birth, cemetery, etc.) and the number of optional fields increased from 5 to 22, the csv format turned out to be hard to maintain. Although it is possible to be imported/exported into excel, it would be better to use excel spreadsheets directly. From version 2.2 this is possible. For backward compatibility it is still possible to use csv files. The new fields can be used in csv fields as well. From version 2.3 gedcom files can also be used.

  We encourage everybody to use the excel format. To convert from the csv format to the excel format, use script script/convertFormat.pl

  TIP 1.: Maintain your family tree data in excel using the Form option. Select all the columns, then press DATA->Form. It is convenient to add new people or to modify information of existing persons.
  TIP 2.: Freeze the first line so that header does not disappear when scrolling down.

=head1 The excel format:

  The excel format is quite straightforward based on the example file. Each row (except the header) represents a person. The fields are:
   * ID: the ID of the person. It can be anything (like 123 or Bart_Simpson), but it should only contain alphanumeric characters and underscore (no whitespace is allowed).
   * title: like: Dr., Prof.
   * prefix: like: sir
   * first name
   * middle name
   * last Name
   * suffix: like: VIII
   * nickname
   * father's ID
   * mother's ID
   * email
   * webpage
   * date of birth: the format is day/month/year, like: 24/3/1977
   * date of death: the format is day/month/year, like: 24/3/1977
   * gender: 0 for male, 1 female
   * is living?: 0 for live 1 for dead
   * place of birth: the format is: "country" "city". The city part may be omitted. Quotation marks are mandatory.
   * place of death: the format is: "country" "city". The city part may be omitted. Quotation marks are mandatory.
   * cemetery: the format is: "country" "city" "cemetery", like: "USA" "Washington D.C." "Arlington National Cemetery"
   * schools: use comma as separator, like: Harward, MIT
   * jobs: use comma as separator
   * work places: use comma as separator
   * places of living: places separated by comma, like: "USA" "Springfield", "USA" "Connecticut"
   * general: you would typically write something general about the person.
  Note, that the extension of an excel data file must be xls.

  Tip: Select the second row, click on menu Window and select Freeze Panels.
  This will freeze the first row and you can see the title of columns.

=head1 The csv format:

  Semicolon is the separator. The fields are:

  1. Full name.
   Middle names can be included in this field.
   If more than one person share the same name, a number can be appended (not shown in the displayed output). For example, "Bart Simpson2".
  2. Father (optional - leave blank if not known). No middle names.
  3. Mother (optional)
  4. email address (optional)
  5. web page (optional)
  6. Dates, birth-death (both optional).
  Examples: "17/10/49-24/11/83", "10/69-"
   Note that the year of birth is not displayed for people who are still alive.
  7. Gender (0 for male, 1 for female)
  8. title: like: Dr., Prof.
  9. prefix: like: sir
  10. suffix: like: VIII
  11. is living?: 0 for live 1 for dead
  12. place of birth: the format is: "country" "city". The city part may be omitted. Quotation marks are mandatory.
  13. place of death: the format is: "country" "city". The city part may be omitted. Quotation marks are mandatory.
  14. cemetery: the format is: "country" "city" "cemetery", like: "USA" "Washington D.C." "Arlington National Cemetery"
  15. schools: use comma as separator, like: Harward,MIT
  16. jobs: use comma as separator
  17. work places: use comma as separator
  18. places of living: places separated by comma, like: "USA" "Springfield", "USA" "Connecticut"
  19. general: you would typically write something general about the person.
  Note, that the extension of a csv data file must be either csv or txt. To define the encoding of the file use option encoding in the config file.

=head1 Convert from csv (txt) format to excel format:

  To switch from comma separated value file to excel spreadsheet, do the following:
  cd ftree2
  perl ./scripts/convertFormat.pl ./tree.txt ./tree.xls
  This will generate (overwrite) a tree.xls file.

  The GEDCOM format:
  GEDCOM, an acronym for GEnealogical Data COMmunication, is a specification for exchanging genealogical data between different genealogy software. GEDCOM was developed by The Church of Jesus Christ of Latter-day Saints as an aid in their extensive genealogical research. A GEDCOM file is plain text (an obscure text encoding named ANSEL, though often in ASCII in the United States) containing genealogical information about individuals, and data linking these records together. Most genealogy software supports importing from and/or exporting to GEDCOM format.

  Beside the father, mother relationships, the program handles the following information of a person:
  1, gender
  2, date of birth
  3, date of death
  4, place of birth (only city and country are extracted)
  5, place of death (only city and country are extracted)
  6, cemetery (only cemetery, city and country are extracted)
  7, email address
  8, homepage

  It is possible to switch from GEDCOM to excel (or serialized) format. Use the scripts/convertFormat.pl script. For example
  cd ftree2
  perl ./scripts/convertFormat.pl ./tree.ged ./tree.xls

The ser format:
  The drawback of excel, csv and GEDCOM format is that it has to be parsed and processed every time the program runs. It is possible to speed-up the program (and hence reduce response time) and reduce memory usage if you use the serialized format. The serialized format cannot be edited directly. Basically you maintain your family tree data in excel (or in csv or GEDCOM) then create a serialized file using scripts/convertFormat.pl program. If the name of the family tree data is ftree.xls then, the following commands will generate the serialized file:

  cd ftree2
  perl ./scripts/convertFormat.pl ./tree.xls ./tree.ser

  Don't forget to set the data_source to "../tree.ser" in the PerlSettingsImporter.pm file.

  Note, that the extension of a serialized data file must be ser. Also keep in mind that different versions of perl may produce incompatible serialized versions. It is advised to run the convertFormat.pl script on the same mashine where the webserver runs.

=head1 NAME OF THE PICTURE:

One picture may belong to each person. The name of the picture file reflects the person it belongs to. The picture file is obtained from the lowercased full name by substituting spaces with underscores and adding the file extension to it. From example from "Ferenc Bodon3" we get "ferenc_bodon3.jpg".

=head1 PERFORMANCE ISSUES:

This sofware was not designed so that it can handle very large family trees. It can easily cope with few thousands of members, but latency (time till page is generated) grows as the size of the family tree increases.
The main bottleneck of performance is that (1.) mod_perl is not used, therefore perl interpreter is starts for every request (2.) family tree is not cached but data file is parsed and tree is built-up for every request (using serialized format helps a little).
Since the purpose of this software is to provide a free and simple tool for those who would like to maintain their family tree themself, performance is not the primary concern.

=head1 SECURITY ISSUES:

The protection provided by password request (set in config file) is quite primitive, i.e. it is easy to break it.
Ther are historical reasons for being available. We suggest to use server side protection like .htaccess files in case of apache web servers.

=head1 AUTHORS

Dr. Ferenc Bodon and Simon Ward and Nikolay Mishin
http://www.cs.bme.hu/~bodon/en/index.html
http://simonward.com

=head1 MAINTAINER

Nikolay Mishin

=head1 COPYRIGHT

Copyright 2015- Dr. Ferenc Bodon and Simon Ward and Nikolay Mishin

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

I am in debt to the translators:
Csaba Kiss (French)
Gergely Kovacs (German),
Przemek Swiderski (Polish),
Rober Miles (Italian),
Lajos Malozsak (Romanian),
Vladimir Kangin (Russian)

I also would like to thank the feedback/help of (in no particular order) Alex Roitman, Anthony Fletcher,
Richard Bos, Sylvia McKenzie and Sean Symes.

=head1 SEE ALSO

=cut

