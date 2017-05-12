package Lingua::Ogmios::NLPWrappers::SectionIdentification;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;
use Lingua::Ogmios::Annotations::Section;


use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG] Creating a wrapper of the SectionIdentification\n";

    my $SectionIdentification = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $SectionIdentification->_input_filename($tmpfile_prefix . ".SectionIdentification.in");
    $SectionIdentification->_output_filename($tmpfile_prefix . ".SectionIdentification.out");

    return($SectionIdentification);

}

sub _processSectionIdentification {
    my ($self) = @_;

    warn "[LOG] SectionIdentification\n";

    my $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    # signature type : '-- '
    #                  '_______'
    #                  '-------'

#     foreach $document (@{$self->_documentSet}) {
# 	foreach $token (@{$document->getAnnotations->getTokenLevel->getElements}) {
# #	warn "$token: " . $token->getContent . ";\n";
# # 	    $corpus_in .= $token->getContent;

# 	    # '-- '
# 	    if ($token->getContent eq "-") {
# 		if (($token->next->getContent eq "-") && ($token->next->next->getContent eq " ")) {
		    
# 		}
# 	    }
# 	    # '------'
# 	    if ($token->getContent eq "-") {
# 		my $minnb = 4;
		
# 	    }
	    
# 	    # '_____'
# 	    if ($token->getContent eq "_") {
# 		my $minnb = 4;
		
# 	    }
	    

# 	}
#     }
#     $corpus_in =~ s/[\x{A0}\x{2000}-\x{200B}]/ /go;
#     $corpus_in =~ s/\x{0153}/oe/go;
#     $corpus_in =~ s/\x{0152}/OE/go;
   

     return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{SectionIdentification_CMD} . " " . $self->_input_filename . " " . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputSectionIdentification {
    my ($self) = @_;

    my $document;
    my $section;
    my $i;
    my $start_token;
    my $end_token;
    my $sectionForm;

    my @lines;

    warn "[LOG] making SectionIdentification input\n";

    open FILE_IN, ">" . $self->_input_filename;
    binmode(FILE_IN, ":utf8");

    $self->{'Id2documents'} = {};

    foreach $document (@{$self->_documentSet}) {
	$i = 0;
	$self->{'Id2documents'}->{$document->getId} = $document;
	foreach $section (@{$document->getAnnotations->getSectionLevel->getElements}) {
# 	for($i = 0; $i < scalar(@{$document->getAnnotations->getSectionLevel->getElements}); $i++) {
	    ($start_token, $end_token, $sectionForm)  = $section->getForm($document->getAnnotations->getTokenLevel);
	    print FILE_IN "section = " . $section->getId . "\n";
	    print FILE_IN "doc = " . $document->getId . "\n";
	    print FILE_IN "start = " . $start_token->getFrom . "\n";
	    print FILE_IN "end = " . $end_token->getTo . "\n";
	    if (defined $section->type) {
		print FILE_IN "type = " . $section->type . "\n";
	    }
	    if (defined $section->parent_section) {
		print FILE_IN "parent_section = " . $section->parent_section->getId . "\n";
	    }
# 	    @lines = split /\n/, $sectionForm;
# 	    print FILE_IN "text (" . scalar(@lines) . ") = " . $sectionForm . "\n";
	    my $pos = -1;
	    my $newlines = 0;
	    while(($pos = index($sectionForm, "\n", $pos + 1)) > -1) {
		$newlines ++;
	    }
	    if ($newlines ==0) {
		$newlines++;
	    }
# 	    if ($pos != length($sectionForm)) {
# 		$newlines++;
# 	    }
	    print FILE_IN "text ($newlines) = " . $sectionForm;
	    print FILE_IN "--\n";
# 	    if (($section->getFromOffset == $firsttoken->getFrom) && ($section->getToOffset == $lasttoken->getTo)) {
# $section->getForm($document->getAnnotations->getTokenLevel);	    
#	    ($start_token, $end_token, $sectionForm)  = $section->getForm($document->getAnnotations->getTokenLevel);
	    $i++;
	}	
    } 
    close FILE_IN;
    warn "[LOG] done\n";
}


sub _outputSectionIdentification {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";
    my $line;
    my @sections;
    my $size;
    my $section_out;
    my $document;
    my $newSection;

    my $tokenFrom;
    my $tokenTo;

# addSection

    open FILE_OUT, $self->_output_filename;
    binmode(FILE_OUT, ":utf8");

    while($line = <FILE_OUT>) {
	chomp $line;
	if ($line =~ /^section = /o) {
	    # warn "$line\n";
	    my $section = {
		"section" => $', # '
	    };
	    $line = <FILE_OUT>;
	    chomp $line;
	    if ($line =~ /^doc = /o) {
		$section->{"doc"} = $'; # '
		$line = <FILE_OUT>;
		chomp $line;
	    }
	    if ($line =~ /^start = /o) {
		# warn "$line\n";
		$section->{"start"} = $'; # '
	        $line = <FILE_OUT>;
	        chomp $line;
	    }
	    if ($line =~ /^end = /o) {
		$section->{"end"} = $'; # '
		$line = <FILE_OUT>;
		chomp $line;
	    }
	    if ($line =~ /^type = /o) {
		$section->{"type"} = $'; # '
		$line = <FILE_OUT>;
		chomp $line;
	    }
	    if ($line =~ /^parent_section = /o) {
		$section->{"parent_section"} = $'; # '
		$line = <FILE_OUT>;
		chomp $line;
	    }
	    if ($line =~ /^title = /o) {
		$section->{"title"} = $'; # '
		$line = <FILE_OUT>;
		chomp $line;
	    }
	    if ($line =~ /^text \(([0-9]+)\) = /o) {
		$size = $1;
		# warn "$line\n";
		# warn $section->{"start"} . "\n";
		$section->{"text"} = [$']; # '
		$size--;
		while($size > 0) {
		    $line = <FILE_OUT>;
 		    chomp $line;
		    if (length($line) == 0) {
			$line = "";
		    }
		    push @{$section->{"text"}}, $line;
		    $size--;
		}
	    }
	    # 	warn "####\n";
	    # warn "new Section" . $section->{'section'} . "\n";
	    # warn $section->{"start"} . "\n";

	    push @sections, $section;
	}
    }
    close(FILE_OUT);

	# warn "*****\n";
    foreach $section_out (@sections) {
	# warn "new Section" . $section_out->{'section'} . "\n";
	# warn $section_out->{"start"} . "\n";
	# warn $section_out->{"end"} . "\n";
	
	$document = $self->{'Id2documents'}->{$section_out->{'doc'}};
	if (!$document->getAnnotations->getSectionLevel->existsElement($section_out->{'section'})) {

	if ($document->getAnnotations->getTokenLevel->existsElementFromIndex('from', $section_out->{'start'})) {
	    $tokenFrom = $document->getAnnotations->getTokenLevel->getElementFromIndex('from', $section_out->{'start'})->[0];
	    # warn "$tokenFrom\n";
	}
	if ($document->getAnnotations->getTokenLevel->existsElementFromIndex('to', $section_out->{'end'})) {
	    $tokenTo = $document->getAnnotations->getTokenLevel->getElementFromIndex('to', $section_out->{'end'})->[0];
	}

	# warn "add section: " . $section_out->{'section'} . " : $tokenFrom : $tokenTo\n";

	$newSection = Lingua::Ogmios::Annotations::Section->new({
	    'from' => $tokenFrom,
	    'to' => $tokenTo,
	    'title' => $section_out->{'title'},
	    'type' => "narrative",
 	    'child_sections' => [],
# 	    'rank' => $rank++,
							     }
	    );
	    
	# warn "newSection: $newSection\n";
	$document->getAnnotations->addSection($newSection, $section_out->{'parent_section'});
# 	if ($document->getAnnotations->getSectionLevel->existsElement($section_out->{'parent_section'})) {
# 	    $newSection->parent_section($document->getAnnotations->getSectionLevel->getElement($section_out->{'parent_section'}));
# 	    push @{$newSection->parent_section->child_sections}, $newSection;
# 	}
	}
    }	
    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputSectionIdentification;

    my $command_line = $self->_processSectionIdentification;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
	$self->_outputSectionIdentification;
    }
#     $self->_outputParsing;


    # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => [''],
    };
    $self->_log($information);


#     die "You call the 'rum' method of the wrapper class base\n
#          You should define a 'run' method for your wrapper\n";
    warn "[LOG] done\n";
}


1;

__END__

=head1 NAME

Lingua::Ogmios::NLPWrappers::??? - Perl extension for ???.

=head1 SYNOPSIS

use Lingua::Ogmios::NLPWrappers::???;

my %config = Lingua::Ogmios::NLPWrappers::???::load_config($rcfile);

$module = Lingua::Ogmios::NLPWrappers::???->new($config{"OPTIONS"}, \%config);

$module->function($corpus);


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 CONFIGURATION

=over

=item *


=back

=head1 NON STANDARD OUTPUT


=over

=item *


=back

=head1 REQUIRED ANNOTATIONS

=over

=item *


=back


=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

