package Lingua::Ogmios::Config::NLPTools;


use strict;
use warnings;

use Config::General;

use Data::Dumper;

my $debug_devel_level = 0;

sub new {
    my $class = shift;
    my $data_config = shift;

    my $CG_data_struct;

    warn "New Configuration for NLP tool\n" unless $debug_devel_level < 1;

    my $config = {
	'ConfigFile' => undef,
	'ConfigData' => undef,
	'CommandsLanguage' => undef,
	'ResourcesLanguages' => undef,
    };

    bless $config, $class;


    if (defined $data_config) {
	if (ref($data_config) eq "HASH") {
	    $config->setConfigData_fromCGStruct($data_config);
	} else {
	    $config->setConfigData_fromFile($data_config);
	}
    }
    return $config;
}

sub wrapper {
    my $self = shift;

#     warn "tool: $self\n";
    $self->getConfigData->{"WRAPPER"} = shift if @_;
#     warn $self->getConfigData->{"WRAPPER"} . "\n";
    return($self->getConfigData->{"WRAPPER"});
}

sub name {
    my $self = shift;

#     warn "tool: $self\n";
    $self->getConfigData->{"NAME"} = shift if @_;
#     warn $self->getConfigData->{"NAME"} . "\n";
    return($self->getConfigData->{"NAME"});
}

sub comments {
    my $self = shift;

#     warn "tool: $self\n";
    $self->getConfigData->{"COMMENTS"} = shift if @_;
#     warn $self->getConfigData->{"NAME"} . "\n";
    return($self->getConfigData->{"COMMENTS"});
}

sub version {
    my $self = shift;

#     warn "tool: $self\n";
    $self->getConfigData->{"VERSION"} = shift if @_;
#     warn $self->getConfigData->{"NAME"} . "\n";
    return($self->getConfigData->{"VERSION"});
}

sub configuration {
    my $self = shift;

#     warn "tool: $self\n";
    $self->getConfigData->{"CONFIGURATION"} = shift if @_;
#     warn $self->getConfigData->{"NAME"} . "\n";
    return($self->getConfigData->{"CONFIGURATION"});
}

sub commands {
    my $self = shift;

    my  $lang = 'EN'; # default language

    $lang = shift if @_;

    $self->configuration->{"COMMANDS"}->{"language=$lang"} = shift if @_;

    return($self->configuration->{"COMMANDS"}->{"language=$lang"});
}

sub getCommandsLanguages {
    my $self = shift;

    my $language;
    my %langs;

    if (!defined $self->{'CommandsLanguage'}) {
	foreach $language (keys %{$self->configuration->{"COMMANDS"}}) {
	    if ($language =~ /language=\"?(?<lang>[A-Za-z]+)\"?/) {
		$langs{$+{lang}}++;
	    }
	}
	$self->{'CommandsLanguage'} = [];
	push @{$self->{'CommandsLanguage'}}, keys %langs;
    } 
    return($self->{'CommandsLanguage'});
}

sub getResourcesLanguages {
    my $self = shift;

    my $language;
    my %langs;

    if (!defined $self->{'ResourcesLanguage'}) {
	foreach $language (keys %{$self->configuration->{"COMMANDS"}}) {
	    if ($language =~ /language=\"?(?<lang>[A-Za-z]+)\"?/) {
		$langs{$+{lang}}++;
	    }
	}
	$self->{'ResourcesLanguage'} = [];
	push @{$self->{'ResourcesLanguage'}}, keys %langs;
    } 
    return($self->{'ResourcesLanguage'});
}


sub getLanguages {
    my $self = shift;

    my %langs;
    my $lang;

    foreach $lang (@{$self->getCommandsLanguages}) {
	$langs{$lang}++;
    }
    foreach $lang (@{$self->getResourcesLanguages}) {
	$langs{$lang}++;
    }
    return(keys %langs);
}

sub existsLanguage {
    my $self = shift;
    my $language = shift;

    my %langs;
    my $lang;

    foreach $lang (@{$self->getCommandsLanguages}) {
	$langs{$lang}++;
    }
    foreach $lang (@{$self->getResourcesLanguages}) {
	$langs{$lang}++;
    }
    warn $self->name . ": " . join('/', keys %langs) . "\n";
    if (exists $langs{$language}) {warn "\tOK\n"};
    return(exists $langs{$language});
}


sub resources {
    my $self = shift;

    my  $lang = 'EN'; # default language

    $lang = shift if @_;

    $self->configuration->{"RESOURCE"}->{"language=$lang"} = shift if @_;

    return($self->configuration->{"RESOURCE"}->{"language=$lang"});
}

sub configFile {
    my $self = shift;

    my  $lang = 'EN';

    $lang = shift if @_;

    $self->configuration->{"CONFIG"}->{"language=$lang"} = shift if @_;

    return($self->configuration->{"CONFIG"}->{"language=$lang"});
}


sub getVars {
    my $self = shift;
    
    my $var;
    my %reservedFields = ('CONFIG' => 1, 'COMMANDS' => 1, 'RESOURCE' => 1);

    foreach $var (keys %{$self->configuration}) {
	if (!exists $reservedFields{$var}) {
	    warn "\t\t$var: " . $self->configuration->{$var} . "\n";
	}
    }
}

sub getConfigData {
    my $self = shift;

    return($self->{"ConfigData"});
}

sub setConfigData_fromFile {
    my $self = shift;
    my $rcfile = shift;

    my $conf = new Config::General('-ConfigFile' => $rcfile,
 				   '-InterPolateVars' => 1,
 				   '-InterPolateEnv' => 1
	);
    
    my %config = $conf->getall;

#     warn Dumper \%config;

    $self->{'ConfigFile'} = $rcfile;

    $self->{'ConfigData'} = $config{'TOOL'};
    

}

sub setConfigData_fromCGStruct {
    my $self = shift;
    
    $self->{"ConfigData"} = shift;

    $self->{"ConfigFile"} = "internal";
}

sub print {
    my ($self, $language) = @_;
    my $lang;

    my @langs = ("EN", "FR");

    if (defined $language) {
	@langs = ($language);
    }

#     if (defined $self->getNLPTools) {
# 	my %nlptools_vars = ();
	
    print STDERR "      Section NLP tool " . $self->name . "\n";

#    print STDERR Dumper $self->getConfigData;
    warn "\tNAME: " . $self->name . "\n";
    warn "\tVERSION: " . $self->version . "\n";
    warn "\tDESCRIPTION: " . $self->comments . "\n";
    warn "\tWRAPPER: " . $self->wrapper . "\n";
    foreach $lang (@langs) {
	warn "\tCONFIGURATION ($lang): \n";
 	warn "\t    COMMANDS: \n";  
 	$self->_printVars($self->commands($lang));
 	warn "\t    CONFIG: \n";
	$self->_printVars($self->configFile($lang));
 	warn "\t    VARIABLES: \n";
	$self->getVars($lang);
	warn "\tRESOURCE ($lang): \n";
 	$self->_printVars($self->resources($lang));
    }
    warn "\tComments: " . $self->comments . "\n";
    print STDERR "\n\n";
}

sub printDOT {
    my ($self, $language) = @_;
    my $lang;

    my @langs = ("EN", "FR");

    if (defined $language) {
	@langs = ($language);
    }

#     if (defined $self->getNLPTools) {
# 	my %nlptools_vars = ();
	
    #print STDERR "      Section NLP tool " . $self->name . "\n";

#    print STDERR Dumper $self->getConfigData;
    # warn "lang: $language\n";
    if ((!defined $language) || ($self->existsLanguage(uc($language)))) {
	# warn "\tok\n";
	my $name = $self->name;
	$name =~ s/ /_/g;
	print "\t$name [label=\"" . $self->comments . " (" . join("/", $self->getLanguages) . ")\"]\n";
    }
    # warn "\tNAME: " . $self->name . "\n";
    # warn "\tVERSION: " . $self->version . "\n";
    # warn "\tDESCRIPTION: " . $self->comments . "\n";
    # warn "\tWRAPPER: " . $self->wrapper . "\n";
    # foreach $lang (@langs) {
    # 	warn "\tCONFIGURATION ($lang): \n";
    # 	warn "\t    COMMANDS: \n";  
    # 	$self->_printVars($self->commands($lang));
    # 	warn "\t    CONFIG: \n";
    # 	$self->_printVars($self->configFile($lang));
    # 	warn "\t    VARIABLES: \n";
    # 	$self->getVars($lang);
    # 	warn "\tRESOURCE ($lang): \n";
    # 	$self->_printVars($self->resources($lang));
    # }
    # warn "\tComments: " . $self->comments . "\n";
    #print STDERR "\n\n";
}

sub _printVars {
    my ($self) = shift;
    my $vars = shift;
   
    my $var;

    foreach $var (keys %$vars) {
	print STDERR "\t\t$var: ";
	warn $vars->{$var} . "\n";
    }
    
}

1;

__END__

=head1 NAME

Lingua::Ogmios::Config::NLPTools - Perl extension for the configuration of the NLP tools

=head1 SYNOPSIS

use Lingua::Ogmios::Config::???;

my $word = Lingua::Ogmios::Config::???::new($fields);


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

