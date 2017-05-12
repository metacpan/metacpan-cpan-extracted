package Lingua::BioYaTeA;

use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

Lingua::BioYaTeA - Perl extension of Lingua::YaTeA for extracting terms from a biomedical corpus.

=head1 SYNOPSIS

use Lingua::BioYaTeA;

my %config = Lingua::YaTeA::load_config($rcfile);

$yatea = Lingua::YaTeA->new($config{"OPTIONS"}, \%config);

$corpus = Lingua::YaTeA::Corpus->new($corpus_path,$yatea->getOptionSet,$yatea->getMessageSet);

$yatea->termExtraction($corpus);


=head1 DESCRIPTION

This module is the main module of the software BioYaTeA which is an
adaptation of YaTeA (C<Lingua::YaTeA>) for biomedical text.

The module inherits from all the class and attributes of
C<Lingua::YaTeA>. The input and output files but also the
configuration files follow the same format as YaTeA.
The tuning concerns the configuration files (in the directory
C<share/BioYaTeA>.

Default configuration is assumed to be C</etc/bioyatea/bioyatea.rc>.

For the use of BioYaTeA, see the documentation with the script
C<bioyatea>.

=head1 METHODS

=head2 new()

    new($command_line_options_h,$system_config_h);

The methods creates a new term extractor and sets options from the
command line (C<$commend_line_options_h>) and options defined in the
hashtable (C<$system_config_h>) given by address. The methods returns
the created object.

=head2 load_config()

    load_config($rcfile);

The method loads the configuration of the NLP Platform by reading the
configuration file given in argument. It returns the hashtable
containing the configuration.


=head1 SEE ALSO

Documentation of Lingua::YaTeA

=head1 AUTHORS

Wiktoria Golik <wiktoria.golik@jouy.inra.fr>, Zorana Ratkovic <Zorana.Ratkovic@jouy.inra.fr>, Robert Bossy <Robert.Bossy@jouy.inra.fr>, Claire Nédellec <claire.nedellec@jouy.inra.fr>, Thierry Hamon <thierry.hamon@univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2012 Wiktoria Golik, Zorana Ratkovic, Robert Bossy, Claire Nédellec and Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

use Lingua::YaTeA;

our @ISA = qw(Lingua::YaTeA);

our $VERSION='0.11';

sub new {
    my ($class,$command_line_options_h,$system_config_h) = @_;

    if ($Lingua::YaTeA::VERSION < 0.6) {
	warn "***************************************************************************\n";
	warn "Something wrong: attempting to use a version Lingua::YaTeA greater than 0.6\n";
	warn "while found version is " . $Lingua::YaTeA::VERSION . "\n";
        warn "Please install the right version\n\n";
	warn "Exiting...\n";
	warn "***************************************************************************\n";
	exit -1;
    }
    my $this = $class->SUPER::new($command_line_options_h,$system_config_h);
    bless ($this,$class);

    return $this;
}

sub load_config {
    # my ($class, $rcfile) = @_;

    my $rcfile;
    my $class = shift;

    if (@_) {
	$rcfile = shift;
    } else {
	$rcfile = $class;
    }
    
    
    if ((! defined $rcfile) || ($rcfile eq "")) {
	$rcfile = "/etc/bioyatea/bioyatea.rc";    
    }

    print STDERR "$rcfile : $class\n";

    return(Lingua::YaTeA::load_config($rcfile));
}

1;
