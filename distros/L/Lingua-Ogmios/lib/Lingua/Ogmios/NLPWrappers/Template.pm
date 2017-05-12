package Lingua::Ogmios::NLPWrappers::Template;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the Template\n";

    my $Template = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    if (defined $Template->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$Template->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;

		$Template->_setOption($lang2, "MODE", "mode", "eval");
		# if (defined $Template->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"}) {
		#     $Template->{'parameter'}->{$lang2} = $Template->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"};
		# } else {
		#     $Template->{'parameter'}->{"FR"} = "?.!";
		#     $Template->{'parameter'}->{"EN"} = "?.!";
		#     warn "*** OPTION is not set ***\n";
		# }
	    # } else {
	    # 	$Template->{'parameter'}->{"FR"} = "?.!";
	    # 	$Template->{'parameter'}->{"EN"} = "?.!";
	    # 	warn "*** OPTION is not set ***\n";
	    }
	}
    # } else {
    # 	$Template->{'parameter'}->{"FR"} = "?.!";
    # 	$Template->{'parameter'}->{"EN"} = "?.!";	
    }


    $Template->_input_filename($tmpfile_prefix . ".Template.in");
    $Template->_output_filename($tmpfile_prefix . ".Template.out");

    return($Template);

}

sub _processTemplate {
    my ($self, $lang) = @_;

    warn "[LOG] Template\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{Template_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputTemplate {
    my ($self) = @_;

    warn "[LOG] making Template input\n";
    
    warn "[LOG] done\n";
}


sub _outputTemplate {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputTemplate;

    my $command_line = $self->_processTemplate;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
	$self->_outputTemplate;
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

