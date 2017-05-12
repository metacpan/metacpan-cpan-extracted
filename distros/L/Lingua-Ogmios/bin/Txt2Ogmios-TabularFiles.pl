#!/usr/bin/perl

use strict;
use XML::Simple;

use Getopt::Long;
use Pod::Usage;

my $doc_id;
my $text;
my $i;
my $title;
my $section_regex = '^\s*[^a-z\d]+($|:)';

my $help = 0;
my $man = 0;

my $filename;
my $lang;

if (scalar(@ARGV) ==0) {
    $help = 1;
}

Getopt::Long::Configure ("bundling");

GetOptions('help|?'       => \$help,
	   'man'          => \$man,
	   'file|f=s'     => \$filename,
	   'docId|i=s'    => \$doc_id,
	   'lang|l=s' => \$lang,
    );

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;



my @doc_initial_text;

open FILE, "<:utf8", $filename;
my @text = <FILE>;
$text[0] =~ s/﻿//;

my @initial_text = @text;

binmode(stdout,":utf8");

map {
    $_ =~ s/&amp;/&/go;
    $_ =~ s/&quot;/\"/og;
    $_ =~ s/&apos;/\'/og;
    $_ =~ s/&lt;/</og;
    $_ =~ s/&gt;/>/og;
#    $_ =~ s/[\x{0000}-\x{001F}]//og;
    chomp;
} @initial_text;

my @text_with_sections;
my $line;


print '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
print '<documentCollection xmlns="http://alvis.info/enriched/" version="1.1">'. "\n";

&print_documentRecord($doc_id, $filename, \@initial_text, $lang);

print '</documentCollection>' . "\n";

exit;

my $initial_text;

close FILE;

print '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
print '<documentCollection xmlns="http://alvis.info/enriched/" version="1.1">'. "\n";

my %titles;

my %documents;
my $section;

my $max_doc_id;

foreach $initial_text (@doc_initial_text) {
    warn "Processing document \n";

    my @text_with_sections = &identify_sections($initial_text);

    my @text_with_sections_and_items;
    my $section_nb = 0;
    my @text_section;

    foreach $section (@text_with_sections) {
	push @text_with_sections_and_items, &identify_listitems($section->{"content"}, \$section_nb);
    }

    $documents{$doc_id} = \@text_with_sections_and_items;
    $max_doc_id = $doc_id;
}

foreach $doc_id (sort {$a <=> $b} keys  %documents) {
    warn "Processing document $doc_id / $max_doc_id (title identification second step)\n";
    
    my @text_with_sections_and_items = @{$documents{$doc_id}};

    foreach $section (@text_with_sections_and_items) {
	if ($title = &identify_title($section->{"content"}, \%titles)) {
	    $section->{"title"} = $title;
	}
    }

    &print_documentRecord($doc_id, $filename, \@text_with_sections_and_items, $lang);
}

print '</documentCollection>' . "\n";

sub new_section {
    my ($ref_section_nb, $ref_text_with_sections, $text, $sectionType) = @_;
    
    $sectionType = "narrative" unless $sectionType;
    $$ref_section_nb++;
    
    $ref_text_with_sections->[$$ref_section_nb]->{"content"} = $text;
    $ref_text_with_sections->[$$ref_section_nb]->{"sectionType"} = $sectionType;

}

sub add_in_section {
    my ($section_nb, $ref_text_with_sections, $text) = @_;

    if (ref($ref_text_with_sections->[$section_nb]->{"content"}) eq "ARRAY") {
	push @{$ref_text_with_sections->[$section_nb]->{"content"}}, $text;
    } else {
	$ref_text_with_sections->[$section_nb]->{"content"} .= $text;
    }
}

sub new_item {
    my ($ref_item_nb, $ref_text_with_items, $text) = @_;
    
    $$ref_item_nb++;
    $ref_text_with_items->[$$ref_item_nb] = $text;
}

sub add_in_item {
    my ($item_nb, $ref_text_with_items, $text) = @_;
    
    $ref_text_with_items->[$item_nb] .= $text;
}

sub print_list {
    my ($list_ref, $title) = @_;
    my $item;

    my $item_str = "";
    foreach $item (@{$list_ref}) {
	if ($item ne "") {
	    $item_str .=  XMLout($item, "RootName" => "item",
				 'NoIndent' => 1,
		);
	}
    }
    if ($item_str ne "") {
	if (defined $title) {
	    print "<section title=\"$title\"><list>";
	} else {
	    print "<section><list>";
	}
	print $item_str;
	print "</list></section>\n";
    }
}

sub print_documentRecord {

    my ($doc_id, $path, $documentRecord_ref, $language) = @_;

    my $section;
    my $item;

    print '  <documentRecord id="' . $doc_id . '">' . "\n";
    print '    <acquisition>' . "\n";
    print '      <acquisitionData>' . "\n";
    print '        <modifiedDate>' . "2011" . '</modifiedDate>' . "\n";
    print '        <urls>' . "\n";
    print '          <url>file://' . $path . "#$doc_id" . '</url>' . "\n";
    print '        </urls>' . "\n";
    print '      </acquisitionData>' . "\n";
    print '      <canonicalDocument>' . "\n";
    print '      <section>';

    print_sections($documentRecord_ref);

    print '</section>' . "\n";
    print '      </canonicalDocument>' . "\n";
    print '      <analysis>' . "\n";
    print '        <property name="language">' . $language . '</property>' . "\n";
    print '      </analysis>' . "\n";
    print '    </acquisition>' . "\n";
    print '  </documentRecord>' . "\n";
}

sub print_sections {
    my ($sections) =  @_;

    my $section;
    my $sub_section;
    my @sub_sections;
    foreach $section (@$sections) {
	my @sub_sections = split /\t/, $section;
	print "<section>";
	foreach $sub_section (@sub_sections) {
	    print XMLout($sub_section, 'RootName' => "section",
			 'NoIndent' => 1,
		) ;
	}
	print "</section>\n";
    }
}

sub print_section {
    my ($section) =  @_;
    if ($section->{"content"} !~ /^[\s\n]*$/o) {
	if (exists $section->{"title"}) {
	    print XMLout($section, 'RootName' => "section",
			 'NoIndent' => 1,
		) ;
	    print "\n";
	} else {
	    print XMLout($section, 'RootName' => "section",
			 'NoIndent' => 1,
		);
	    print "\n";
	}
    }
}

sub identify_sections {
    my ($text) = @_;

    my $texttmp;
    my @text = split /\n/, $text;

    map {$_ .= "\n"} @text;

    my @text_with_sections;
    my $section_nb = 0;
    $i = 0;

    &new_section(\$section_nb, \@text_with_sections, $text[$i]);

    my @tmp = split /\t/, $text[$i];
    my $sub_section_nb = 0;
    my @sub_sections;
    foreach $texttmp (@tmp) {
	&new_section(\$sub_section_nb, \@sub_sections, $texttmp);
	&add_section_in_section(\$section_nb, \@text_with_sections, $sub_sections[$sub_section_nb]);
    }

    $i++;
    do {
	&add_in_section($section_nb, \@text_with_sections, $text[$i]);
	$i++;
    } while($text[$i] =~ /^\s*\n$/);
    $section_nb++;
    for(;$i <= $#text; $i++) {

	if (($text[$i] =~ /^\s*[^a-z\d]+:/o) || ($text[$i] =~ /^\s*[^a-z\d][^:]+:/o) || (index($text[$i], "******") > -1)){
	    &new_section(\$section_nb, \@text_with_sections, $text[$i]);
	    next;
	}
	&add_in_section($section_nb, \@text_with_sections, $text[$i]);
    }
    return(@text_with_sections);
}

sub add_section_in_section {
    my ($section_nb, $ref_text_with_sections, $text) = @_;

    if (ref($ref_text_with_sections->[$section_nb]->{"content"}) eq "ARRAY") {
	my %tmp = ("content" => $text);
	push @{$ref_text_with_sections->[$section_nb]->{"content"}}, \%tmp;
    } else {
	$ref_text_with_sections->[$section_nb]->{"content"} .= $text;
    }
}

sub identify_listitems {
    my ($section, $section_nb_ref) = @_;
    my @text_with_sections_and_items;

    my $item_regex = '^\b\d+\.\s+';
    my @listSection = (
	"DISCHARGE MEDICATIONS",
	"DISCHARGE MEDS",
	"MEDICATIONS ON ADMISSION",
	"MEDICATIONS ON DISCHARGE",
	"ADMISSION MEDICATIONS",
	"ADMISSION MEDS",
	"MEDICATIONS UPON TRANSFER",
	"PREOPERATIVE MEDICATIONS",
	"PRN MEDICATIONS",
	"ADDENDUM TO MEDICATIONS ON DISCHARGE",
	"MEDICATION AT TIME OF DISCHARGE",
 	"CURRENT MEDICATIONS",
 	"DRUG HISTORY",
	"HOME MEDICATIONS",
 	"HOME MEDS",
	"MEDICATIONS UPON DISCHARGE",
	"MEDICATIONS UPON ADMISSION",
	"PREOP MEDICATIONS",
 	"MEDS",
 	"MEDICATIONS",
	);

# ???	"MEDICATIONS ON \nADMISSION",


# DRUG HISTORY (to confirm)

    my $item_nb = -1;
    my @items;    

    my $j;
    my @text_section;

    my $section_tail = undef;
    if ($section =~ /\n(\n+)$/) {
	$section_tail = $1;
    }
    my $k = 0;

    while(index($section, $listSection[$k]) < 0) {
	$k++;
    }

    my $sectionType = "narrative";
    if ($k < scalar(@listSection)) {
	my @sections;

	if ($section =~ /$listSection[$k]\s*:?\s*/) {
	    $section = $'; # ' }
	    &add_in_section($$section_nb_ref, \@text_with_sections_and_items, $`);

	my %tmp = ("content" => $&,
# 		   "title" => $listSection[$k],
	);
	
	push @sections, \%tmp;
  	&new_section($section_nb_ref, \@text_with_sections_and_items, \@sections);
	$text_with_sections_and_items[$$section_nb_ref]->{"title"} = $listSection[$k];

	$sectionType = "list";
	
  	&new_item(\$item_nb, \@items, ""); 
#      	&add_in_section($$section_nb_ref, \@text_with_sections_and_items, \@items);
	my %tmp2 = ("content" => \@items,
		     "sectionType" => "list",
	);

	push @sections, \%tmp2;
	}
#	$text_with_sections_and_items[$$section_nb_ref]->{"title"} = $listSection[$k];
#  	&add_in_section($section_nb_ref, \@text_with_sections_and_items, \@items);
    } else {

	if ($section =~ /^(\s*([A-Z][^:\d\+\.]+):\s*)(\d+\.\s+)/o) {	
	    my @sections;
	    my $start_listsection = $1;
	    my $start_listsection_title = $2;
	    $section = "$3$'"; # ' }
   	    my %tmp = ("content" => $start_listsection,
# 		   "title" => $listSection[$k],
		);
	    
	    push @sections, \%tmp;
	    &new_section($section_nb_ref, \@text_with_sections_and_items, \@sections);
	    $text_with_sections_and_items[$$section_nb_ref]->{"title"} = $start_listsection_title;

	    $sectionType = "list";

	    &new_item(\$item_nb, \@items, ""); 
#      	&add_in_section($$section_nb_ref, \@text_with_sections_and_items, \@items);
	    my %tmp2 = ("content" => \@items,
			"sectionType" => "list",
		);

	    push @sections, \%tmp2;
	}
    }

    @text_section = split /\n/, $section;

    map{$_ .= "\n"} @text_section;

    for($j=0;$j<= $#text_section;$j++) {
	if ($text_section[$j] =~ /$item_regex/) {
	    if (($item_nb == -1) && ($sectionType ne "list")) {
		my $title;
		my @sections;
		if ($text_section[$j] =~ /^(\s*([A-Z][^:\d\+\.]+):\s*)/o) {
		    $title = $2;
		    $sectionType = "list";
		    my %tmp = ("content" => $1,
# 		   "title" => $listSection[$k],
			);
		    &new_item(\$item_nb, \@items, $');  # ' }
		    push @sections, \%tmp;
		    &new_section($section_nb_ref, \@text_with_sections_and_items, \@sections, $sectionType);
		    $text_with_sections_and_items[$$section_nb_ref]->{"title"} = $title;
		    
		    my %tmp2 = ("content" => \@items,
				"sectionType" => "list",
			);
		    
		    push @sections, \%tmp2;
		    
		} else {
		    &add_in_section($$section_nb_ref, \@text_with_sections_and_items, $text_section[$j]);
		}

# 		&new_section($section_nb_ref, \@text_with_sections_and_items, \@items, "list");
# 		$text_with_sections_and_items->{"title"} = $title;
	    } else {
		&new_item(\$item_nb, \@items, $text_section[$j]); 
	    }
	    next;
	}
	if ($item_nb == -1) {
	    &add_in_section($$section_nb_ref, \@text_with_sections_and_items, $text_section[$j]);
	} else {
	    &add_in_item($item_nb, \@items, $text_section[$j]);
	}
    }
    if (defined $section_tail) {
	&add_in_section($$section_nb_ref, \@text_with_sections_and_items, $section_tail);
    }
    $$section_nb_ref++;
    return(@text_with_sections_and_items);
}

sub identify_title  {
    my ($text, $titles_ref) = @_;
    my $title = "";

    if (($text ne "") && (ref($text) ne "ARRAY")) {
	$text =~ s/^\n+//o;

	if ($text =~ /^\**([A-Z][^:\d\+\.]+):/o) {
	    $title = $1;
	    if (length($title) != 1) {
		$titles_ref->{$title}++;
	    }
	}   else {
	    if ($text =~ /^([A-Z\- ]+):/o) {
		$title = $1;
		if (length($title) != 1) {
		    $titles_ref->{$title}++;
		}
	    }
	}
    }
    return($title);
}

sub identify_title_from_known_titles {
    my ($section, $titles_ref) = @_;
    my $known_title;
    my $text;
    my @sections_text;
    my @sections;
    my $exists_title = 0;
    my $i = 0;
    my $title;
    my $new_text;
    my $end_title_pos;

    if (ref($section->{"content"}) ne "ARRAY") {
#     if (!exists($section->{"title"})) {
	$text = $section->{"content"};
	foreach $known_title (keys %{$titles_ref}) {
	    if (index($text, $known_title, 1) != -1) {
		if ($text =~ s/(\b)(\Q$known_title\E\b)/\1<SECTION>\2<TITLE>\2/) {
		    $exists_title++;
		}
	    }
	}
	if ($exists_title) {
	    @sections_text = split /<SECTION>/, $text;
	    # Processing the first sectino separately
	    $sections[0] = {"content" => $sections_text[0],};
	    if (exists $section->{"title"}) {
		$sections[0]->{"title"} = $section->{"title"};
	    }
	    for($i=1; $i<scalar(@sections_text);$i++) {
		$end_title_pos = index($sections_text[$i], "<TITLE>",0);
		$title = substr($sections_text[$i], 0, $end_title_pos);
		$new_text = substr($sections_text[$i], $end_title_pos+7);
		$sections[$i] = {"content" => $new_text,
				 "title" => $title,
			     };
	    }
	}
    }
    return(@sections);
}

########################################################################

=encoding utf8

=head1 NAME

Txt2Ogmios-TabularFiles.pl - Script for converting tabular files in XML Ogmios files

=head1 SYNOPSIS

Txt2Ogmios-TabularFiles.pl [option] --file <filename> --lang <language> --docId <documentId>

where option can be --help --man

=head1 OPTIONS AND ARGUMENTS

=over 4

=item --file <filename>

The switch sets the input tabular file (to convert).

=item --lang <language>

The switch sets the language of the input text file (to convert). The
value are set with a ISO 639-1 code (fr for French, en for English).

=item --docId <documentId>>

This sets the document identifier in the xml file.

=item --help

print help message for using grepTerms.pl

=item --man

print man page of grepTerms.pl

=back

=head1 DESCRIPTION

This script converts a tabular file as input (switch C<file>) into a XML
Omgios file. It is assumed that some columns contain free text.

The language property field is set with the switch C<lang>, and the
document identifier is set with the switch C<dociI>.

=head1 SEE ALSO

=head1 AUTHOR

Thierry Hamon, E<lt>thierry.hamon@limsi.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 Thierry Hamon

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.4 or, at your
option, any later version of Perl 5 you may have available.

=cut

