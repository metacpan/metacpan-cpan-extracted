package Lingua::YaTeA::OptionSet;
use strict;
use warnings;

use Data::Dumper;


our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my %default = ("suffix"=>"default");
    my $this = {};
    bless ($this,$class);
    $this->{OPTIONS} = ();
    $this->addOptionSet(\%default);
    return $this;
}


sub addOptionSet
{
    my ($this,$options_set_h,$message_set,$display_language) = @_;
    my $name;
    my $val;
    while (my ($opt,$val) = each (%$options_set_h))
    {
	$this->addOption($opt,$val,$message_set,$display_language);
    }
}

sub addOption
{
    my ($this,$name,$value,$message_set,$display_language) = @_;

    if(! $this->optionExists($name))
    {
	$this->{OPTIONS}->{$name} = Lingua::YaTeA::Option->new($name,$value);
    }
    else
    {
	$this->getOption($name)->update($value,$message_set,$display_language);
    }

}


sub checkCompulsory
{
    my ($this,$comp_list) = @_;
    my @compulsory_options = split (",",$comp_list);
    my $compulsory;
    foreach $compulsory (@compulsory_options)
    {
	if(!defined $this->optionExists($compulsory))
	{	
	    die "You must define option \"" .$compulsory . "\"\n";
	}
    }
}

sub is_disable
{
    my ($this,$name) = @_;
    my $option;

    if (defined $this->{OPTIONS}->{$name})
    {
	if ($this->{OPTIONS}->{$name} == 0) {
	    return(1);
	}
    } 
    return (0);
}

sub is_enable
{
    my ($this,$name) = @_;
    my $option;

    if (defined $this->{OPTIONS}->{$name})
    {
	if ($this->{OPTIONS}->{$name} == 1) {
	    return(1);
	}
    } 
    return (0);
}


sub optionExists
{
    my ($this,$name) = @_;
    my $option;
    # foreach $option (@{$this->{OPTIONS}})
#     {
# 	if($option->getName eq $name)
# 	{
# 	    return $option;
# 	}
#     }
    if(defined $this->{OPTIONS}->{$name})
    {
	return $this->{OPTIONS}->{$name};
    }
    return(undef);
}

sub getOption
{
    my ($this,$name) = @_;
    
    return ($this->optionExists($name));

#     if(! return $this->optionExists($name))
#     {
# 	die "Option ". $name . " not defined\n";
#     }

}

sub getOptions
{
    my ($this) = @_;
    return $this->{OPTIONS};
}


sub getLanguage
{
    my ($this) = @_;
    return $this->getOption("language")->getValue;
}

sub getChainedLinks
{
    my ($this) = @_;
    if(defined $this->getOption("chained-links"))
    {
	return  1;
    }
    return 0;
}

sub getSentenceBoundary
{
   my ($this) = @_;
   return $this->getOption("SENTENCE_BOUNDARY")->getValue;
}

sub getDocumentBoundary
{
   my ($this) = @_;
   return $this->getOption("DOCUMENT_BOUNDARY")->getValue;
}

sub getParsingDirection
{
   my ($this) = @_;
   return $this->getOption("PARSING_DIRECTION")->getValue;
}

sub MatchTypeValue
{
   my ($this) = @_;
   if ((defined $this->getOption("match-type")) && ($this->getOption("match-type")->getValue() ne "")) {
       return $this->getOption("match-type")->getValue;
   }
   return 0;
}

sub readFromFile
{
    my ($this,$file) = @_;
    my $conf = Config::General->new($file->getPath);
    $this->addOptionSet($conf->{'DefaultConfig'});
    $this->checkMaxLength;
    $conf = undef;
}

sub checkMaxLength
{
    my ($this) = @_;
    if(!$this->optionExists('PHRASE_MAXIMUM_LENGTH'))
    {
	$this->addOption('PHRASE_MAXIMUM_LENGTH',12);
    }
    if(!$this->optionExists('CANDIDATE_MAXIMUM_LENGTH'))
    {
	$this->addOption('CANDIDATE_MAXIMUM_LENGTH',12);
    }
}

sub getMaxLength
{
    my ($this) = @_;
    return $this->getOption("PHRASE_MAXIMUM_LENGTH")->getValue;

}

sub getCompulsory
{
    my ($this) = @_;
    return $this->getOption("COMPULSORY_ITEM")->getValue;

}

sub getSuffix
{
    my ($this) = @_;
    return $this->getOption("suffix")->getValue;

}

sub getDisplayLanguage
{
    my ($this) = @_;
    return $this->getOption("MESSAGE_DISPLAY")->getValue;
}

sub getDefaultOutput
{
    my ($this) = @_;
    return $this->getOption("default_output")->getValue;
}

sub setMatchType
{
    my ($this,$match_type) = @_;
    
    $this->addOption('match-type',$match_type);
}

sub getTermListStyle
{
    my ($this) = @_;
    return $this->getOption("termList")->getValue;
}

sub getTTGStyle
{
    my ($this) = @_;
    return $this->getOption("TTG-style-term-candidates")->getValue;
}

sub getOutputPath
{
    my ($this) = @_;
    return $this->getOption("output-path")->getValue;
}

sub setDefaultOutputPath
{
    my ($this) = @_;

    if((!defined $this->getOption("output-path")) ||($this->getOption("output-path")->getValue =~ /^\s*$/))
    {
	$this->addOption("output-path",".");
    }
}

sub getTCMaxLength
{
    my ($this) = @_;
    return $this->getOption("CANDIDATE_MAXIMUM_LENGTH")->getValue;
}


sub disable
{
    my ($this,$option_name,$message_set,$display_language) = @_;
    
    if($this->optionExists($option_name))
    {
	delete($this->{OPTIONS}->{$option_name});
    }
    print STDERR "WARNING: " . $message_set->getMessage('DISABLE_OPTION')->getContent($display_language) . $option_name ." \n";
}

sub enable
{
    my ($this,$option_name,$option_value,$message_set,$display_language) = @_;
    
    if(! $this->optionExists($option_name))
    {
	$this->addOption($option_name,$option_value,$message_set,$display_language);
	print STDERR "WARNING: \"" . $option_name ."\"" . $message_set->getMessage('ENABLE_OPTION')->getContent($display_language);
	if(defined $option_value)
	{
	    print STDERR  "." . $message_set->getMessage('OPTION_VALUE')->getContent($display_language) . "\"". $this->getOption($option_name)->getValue . "\"";
	}
	print STDERR "\n";
    }
   
}


sub handleOptionDependencies
{
    my ($this,$message_set) = @_;
    my %incompatibilities = ('annotate-only' => ["TC-for-BioLG", "debug"]);
    my %necessarily_linked = ('TT-for-BioLG' => ["termino", "match-type:if"],
			      'bootstrap' => ["termList"]);
    my $incompatible_option;
    my $necessary_option;
    my @necessary_option;
    my $option;
    my $value;
    


    foreach $option (keys %incompatibilities)
    {
	if ($this->optionExists($option))
	{
	    foreach $incompatible_option (@{$incompatibilities{$option}})
	    {
		if (($this->optionExists($incompatible_option)) && ($this->is_enable($incompatible_option)))
		{
		    print STDERR "WARNING: \"" . $incompatible_option  . "\" & \"" . $option . "\"" .  $message_set->getMessage('INCOMPATIBLE_OPTIONS')->getContent($this->getDisplayLanguage) . " \n";
		    $this->disable($option,$message_set,$this->getDisplayLanguage);
		    last;
		}
	    }
	}
    }

    foreach $option (keys %necessarily_linked)
    {
	if (($this->optionExists($option)) && ($this->getOption('TT-for-BioLG')->getValue() == 1))
	{
	    foreach $necessary_option (@{$necessarily_linked{$option}})
	    {
		@necessary_option = split (/:/,$necessary_option);
		if(!$this->optionExists($necessary_option[0]))
		{
		    if($necessary_option[0] eq "termino")
		    {
			print STDERR $option . ": " . $message_set->getMessage('TERMINO_NEEDED')->getContent($this->getDisplayLanguage) . " \n";
			die "\n";
		    }
		    else
		    {
			$this->enable($necessary_option[0],$necessary_option[1],$message_set,$this->getDisplayLanguage);
		    }
		}
		else
		{
		    if(defined $necessary_option[1])
		    {
			if($this->getOption($necessary_option[0])->getValue ne $necessary_option[1])
			{
			    $this->getOption($necessary_option[0])->update($necessary_option[1],$message_set,$this->getDisplayLanguage);
			}
		    }
		}
	    }
	}
    }

}

1;

__END__

=head1 NAME

Lingua::YaTeA::OptionSet - Perl extension for handling option set in
YaTeA

=head1 SYNOPSIS

  use Lingua::YaTeA::OptionSet;
  Lingua::YaTeA::OptionSet->new();


=head1 DESCRIPTION


This module provides methods for handling option set. The list of
options is stored in the field C<OPTIONS>. 



=head1 METHODS


=head2 new()

The method creates a empty option set. The list of options is stored
in the field C<OPTIONS>. It sets the default value C<default>of the
option C<suffix>.

=head2 addOptionSet()

   addOptionSet($options_set_h,$message_set,$display_language);

The method adds the options defined in a hashtable to the option
set. C<$options_set_h> is the reference to the hashtable of the
options.

The variables C<$message_set> and C<$display_language> are used for
displaying a warning or error message.

=head2 addOption()

    addOption($name,$value,$message_set,$display_language);

The method add or updates the option C<$name> with the value C<value>.

The variables C<$message_set> and C<$display_language> are used for
displaying a warning or error message.

=head2 checkCompulsory()

    checkCompulsory($option_list)

This method checks if the options given in C<$option_list> are defined
in the option set.

The variable C<$option_list> is a string and contains the list of
option names separated by commas.



=head2 is_disable()

    is_disable($name);

The method indicates if the option C<$name> is disable. 

It returns C<1> if the option is disable, C<0> else.

=head2 is_enable()

    is_enable($name);

The method indicates if the option C<$name> is enable. 

It returns C<1> if the option is enable, C<0> else.


=head2 optionExists()

    oprionExists($name);

The method indicates if the option C<$name> exists.

It returns the object if the option exists, C<0> else.

=head2 getOption()

    getOption($name);

The method returns the option object referred by C<$name>if the option
name exists, or die.

=head2 getOptions()

    getOptions();

The method returns the hashtable of the options.

=head2 getLanguage()

    getLanguage();

The method returns the value of the C<language> option.


=head2 getChainedLinks()

    getChainedLinks();

The method returns the value C<1> if the option named C<chained-links>
is set, C<0> else.

=head2 getSentenceBoundary()

    getSentenceBoundary();

The method returns the value of the C<SENTENCE_BONDARY> option.

=head2 getDocumentBoundary()

    getDocumentBoundary();

The method returns the value of the C<DOCUMENT_BONDARY> option.

=head2 getParsingDirection()

    getParsingDirection();

The method returns the value of the C<PARSING_DIRECTION> option.

=head2 MatchTypeValue()

    MatchTypeValue();

The method returns the value of the C<match-type> option.

=head2 readFromFile()

    readFromFile($file);

The method reads the configuration file and set the options defined is
the C<DefaultConfig> section. The option C<PHRASE_MAXIMUM_LENGTH> is
checked and set to a default value if the option is not specified in
the configuration file.

The configuration file C<$file> is a C<Lingua::YaTeA::File> object.

=head2 checkMaxLength()

    checkMaxLength();

The method checks if the option C<PHRASE_MAXIMUM_LENGTH> is set in the
configuration and sets it to a default value (C<12>).

=head2 getMaxLength()

    getMaxLength();

The method returns the value of the C<PHRASE_MAXIMUM_LENGTH> option.

=head2 getCompulsory()

    getCompulsory();

The method returns the value of the C<COMPULSORY_ITEM> option.


=head2 getSuffix()

    getSuffix();

The method returns the value of the C<suffix> option.


=head2 getDisplayLanguage()

    getDisplayLanguage();

The method returns the value of the C<MESSAGE_DISPLAY> option.


=head2 getDefaultOutput()

    getDefaultOutput();

The method returns the value of the C<default_output> option.


=head2 setMatchType()

setMatchType($match_type);

The method adds or updates the type of matching C<$match_type>)
i.e. the option C<match-type>.

=head2 getTermListStyle()

The method returns the value of the C<termList> option.

=head2 getTTGStyle()

The method returns the value of the C<TTG-style-term-candidates> option.

=head2 getOutputPath()

The method returns the value of the C<output-path> option.

=head2 setDefaultOutputPath()

    setDefaultOutputPath();

The method sets the current directory ("C<.>") as default output
directory if the option is not output-path.

=head2 disable()

    disable($option_name,$message_set,$display_language);

The methods disables the option C<$option_name>.

The variables C<$message_set> and C<$display_language> are used for
displaying a warning or error message.


=head2 enable()

    enable($option_name,$option_value,$message_set,$display_language);

The method enables the option C<$option_name> with the value
C<$option_value> if the option does not exist.

The variables C<$message_set> and C<$display_language> are used for
displaying a warning or error message.


=head2 handleOptionDependencies()

    handleOptionDependencies($message_set);

The method checks the dependencies between the options.

Options C<TC-for-BioLG> and C<debug> are incompatibles, while both the
options C<termino> and C<match-type> with the value C<strict> must be
specified.


=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
