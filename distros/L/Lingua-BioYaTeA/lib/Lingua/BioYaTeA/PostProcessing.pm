package Lingua::BioYaTeA::PostProcessing;

use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

Lingua::BioYaTeA::PostProcessing - Perl extension for postprocessing BioYaTeA term extraction.

=head1 SYNOPSIS

use Lingua::BioYaTeA::PostProcessing;

my $postProc = Lingua::BioYaTeA::PostProcessing->new(
   {
    'input-file' => "sampleEN-output.xml",
    'output-file' => "sampleEN-bioyatea-out-pp.xml",
    'configuration' => "post-processing-filtering.conf",
   }
);
$postProc->logfile(dirname($postProc->output_file) . '/term-filtering.log');
$postProc->load_configuration;
$postProc->defineTwigParser;
$postProc->filtering;
$postProc->printResume;


=head1 DESCRIPTION

The module implements an extension for the post-processing of the
BioYaTeA (C<Lingua::BioYaTeA> output. Currently, the XML BioYaTeA
output is filtered according to rules in order to remove non relevant
extracted terms.

The input and output files are in the XML YaTeA format.

The configuration file provides patterns related to various types:
inflected forms (C<FORM>) or lemmatized forms (C<LEMMA>) of terms or
term components and action to perform. Currently only the C<CLEAN>
action (to remove terms) is implemented.


=head1 METHODS

=head2 new()

    new(\%options);

The method creates a post-processing component of BioYaTeA and sets
the option attribute with the hashtable C<@options>, and returns the
created object.

The hashtable C<@options> contains several fields: the input file name
C<input-file>, the output file name C<output-file>, the configuration
file name C<configuration> and the temporary directory name
C<tmp-dir>.

Other attributes are: the C<XML::Twig> parser C<twig_parser>, the
counter of term candidates C<tc_counter>, the counter of rejected
terms C<count_rejected>, the list of regular expressions used to
identify terms to reject C<reg_exps>, the indication whether the
application of each regular expression is case insensitive
C<case_insensitive>, the log file handler C<logfh>, the output file
handler C<logout>, and the log file name C<logfile>.

C<reg_exps> is a hashtable where keys are C<FORM> and values are an
array of regular expressions.

C<case_insensitive> is a hashtable where keys are regular expressions.

=head2 tc_counter()

    tc_counter($tc_counter);

This method sets the attribute C<tc_counter> with the value
C<$tc_counter> and returns it. When no argument is given, the value of
the attribute C<tc_counter> is return.

=head2 logfh()

    logfh($logfh);

This method sets the attribute C<logfh> with the handler
C<$logfh> and returns it. When no argument is given, the value of
the attribute C<logfh> is return.

=head2 outfh()

    outfh();

This method sets the attribute C<outfh> with the handler
C<$outfh> and returns it. When no argument is given, the value of
the attribute C<outfh> is return.

=head2 count_rejected()

    count_rejected($count_rejected);

This method sets the attribute C<count_rejected> with the value
C<$count_rejected> and returns it. When no argument is given, the
value of the attribute C<count_rejected> is return.

=head2 case_insensitive()

    case_insensitive(\%case_insensitive);

This method sets the attribute C<case_insensitive> with the hashtable
C<%case_insensitive> and returns it. When no argument is given, the
hashtable reference of the attribute C<case_insensitive> is return.

=head2 case_insensitive_elt()

    case_insensitive_elt($case_insensitive_name, case_insensitive_value);

This method sets the indication whether the regular expression
C<$case_insensitive_name> is case insensitive or not (value
C<$case_insensitive_value>) in the hashtable referred by the attribute
C<case_insensitive> and returns it.  When one argument is set, the
value associated to the regular expression C<$case_insensitive_name>
is return. When no argument is given, an undefined value is return.

=head2 exists_case_insensitive_elt()

    exists_case_insensitive_elt($case_insensitive_name);

The method indicates if the application of the regular expression
C<$case_insensitive_name> is case insensitive or not.

=head2 options()

    options(\%options);

This method sets the attribute C<options> with the hashtable
C<%options> and returns it. When no argument is given, the
hashtable reference of the attribute C<options> is return.

=head2 configuration()

    configuration($configuration);

This method sets the attribute C<configuration> with the value
C<$configuration> and returns it. When no argument is given, the
value of the attribute C<configuration> is return.

=head2 input_file()

    input_file($input_file);

This method sets the field C<input-file> of the attribute C<options>
with the value C<$input_file> (input file name) and returns it. When
no argument is given, the value of the field C<input-file> of the
attribute C<options> is return.

=head2 logfile()

    logfile($logfile);

This method sets the field C<log-file> of the attribute C<options>
with the value C<$log_file> (log file name) and returns it. When no
argument is given, the value of the field C<log-file> of the attribute
C<options> is return.

=head2 tmp_dir()

    tmp_dir($tmp_dir);

This method sets the field C<tmp-dir> of the attribute C<options>
with the value C<$output_file> (output file name) and returns it. When
no argument is given, the value of the field C<output_file> of the
attribute C<options> is return.

=head2 output_file()

    output_file($output_file);

This method sets the field C<output-file> of the attribute C<options>
with the value C<$output_file> (output file name) and returns it. When
no argument is given, the value of the field C<output-file> of the
attribute C<options> is return.

=head2 reg_exps()

    reg_exps(\%reg_exps);

This method sets the attribute C<reg_exps> with the hashtable
C<%reg_exps> and returns it. When no argument is given, the hashtable
reference of the attribute C<reg_exps> is return.

=head2 reg_exp_elt()

    reg_exp_elt($reg_exp_name, $reg_exp_value);

This method adds the regular expression C<$reg_exp_value> to the
array related to the type of patterns C<$reg_exp_name> and returns
it. When one argument is set, the array referred by C<$reg_exp_name>
is return. When no argument is given, a reference to an empty array is
return.

=head2 twig_parser()

    twig_parser($twig_parser);

This method sets the attribute C<twig_parser> with the C<XML:Twig>
parser C<$twig_parser> and returns it. When no argument is given, the
value of the attribute C<twig_parser> is return.

=head2 defineTwigParser()

    defineTwigParser();

The method defines the C<XML::Twig> parser and associates to the
object.

=head2 processTerms()

    processTerms($twig_parser,$data);

The function processes terms which match regular expressions by
applying associated actions (as defined in the configuration file, for
instance). The terms are in XML tree C<$data>. 

Note: this is a function which uses in the C<XML::Twig> parser (called
as function pointer).

=head2 load_configuration()

    load_configuration();

The method process and loads the configuration file (set in the
attribute C<configuration> of the current object). The attributes
C<reg_exps> and C<case_insensitive> are set by this method.

=head2 filtering()

    filtering();

The method performs the full filtering of the terms:

=over

=item setting of the temporary file if not defined

=item opening the XML output file

=item setting the C<XML::Twig> parser 

=item processing of the XML input file in order to apply action
associated to the regular expressions

=back

=head2 printResume()

    printResume();

The method prints the number of rejected terms and the number of
remaining candidate terms.

=head2 rmlog()

    rmlog();

The method deletes the log file.

=head1 CONFIGURATION FILE FORMAT

The configuration file defines the action to perform when an
associated regular expression matches a term form. For instance:

C<CLEAN=FORM::/[Vv]arious/>

Each line defines an association between an action (only C<CLEAN> for
the moment) and a regular expression to apply to a form of a term
(C<FORM> for the inflected form, C<LEMMA> for the lemmatised form).

The action and regular expression parts are separated by the character
C<=>. The two elements of the regular expression are separated by two
collons (C<::>).

Comments are introduced by a C<#> character at the begin of the line.

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

use Lingua::BioYaTeA::TwigXML;
# use XML::Twig;

our $VERSION='0.1';

sub new {
    my ($class, $options) = @_;

    my $this = {
	'options' => {},
	'twig_parser' => undef,
	'tc_counter' => 0,
	'count_rejected' => 0,
	'reg_exps' => {},
	'case_insensitive' => {},
	'logfh' => undef,
	'outfh' => undef,
	'logfile' => undef,
    };

    bless $this, $class;

    $this->options($options);

    return($this);
}

sub tc_counter {
    my ($self, $tc_counter) = @_;

    if (defined $tc_counter) {
	$self->{'tc_counter'} = $tc_counter;
    }
    return($self->{'tc_counter'});
}

sub logfh {
    my ($self, $logfh) = @_;

    if (defined $logfh) {
	$self->{'logfh'} = $logfh;
    }
    return($self->{'logfh'});
}

sub outfh {
    my ($self, $outfh) = @_;

    if (defined $outfh) {
	$self->{'outfh'} = $outfh;
    }
    return($self->{'outfh'});
}

sub count_rejected {
    my ($self, $count_rejected) = @_;

    if (defined $count_rejected) {
	$self->{'count_rejected'} = $count_rejected;
    }
    return($self->{'count_rejected'});
}

sub case_insensitive {
    my ($self, $case_insensitive) = @_;

    if (defined $case_insensitive) {
	%{$self->{'case_insensitive'}} = %$case_insensitive;
    }
    return($self->{'case_insensitive'});
}

sub case_insensitive_elt {
    my $self = shift;

    my $case_insensitive_name;
    my $case_insensitive_value;

    if (scalar(@_) >= 2) {
	($self, $case_insensitive_name, $case_insensitive_value) = @_;
	$self->{'case_insensitive'}->{$case_insensitive_name} = $case_insensitive_value;
    } else {
	if (scalar(@_) == 1) {
	    $case_insensitive_name = $_[0];
	    return($self->{'case_insensitive'}->{$case_insensitive_name});
	}
    }
    return(undef);
}


sub exists_case_insensitive_elt {
    my ($self, $case_insensitive_name) = @_;

    return(exists($self->{'case_insensitive'}->{$case_insensitive_name}));
}

sub options {
    my ($self, $options) = @_;

    if (defined $options) {
	%{$self->{'options'}} = %$options;
    }
    return($self->{'options'});
}

sub configuration {
    my ($self, $configuration) = @_;

    if (defined $configuration) {
	$self->options->{'configuration'} = $configuration;
    }
    return($self->options->{'configuration'});
}

sub input_file {
    my ($self, $input_file) = @_;

    if (defined $input_file) {
	$self->options->{'input-file'} = $input_file;
    }
    return($self->options->{'input-file'});
}

sub logfile {
    my ($self, $logfile) = @_;

    if (defined $logfile) {
	$self->options->{'logfile'} = $logfile;
    }
    return($self->options->{'logfile'});
}

sub tmp_dir {
    my ($self, $tmp_dir) = @_;

    if (defined $tmp_dir) {
	$self->options->{'tmp-dir'} = $tmp_dir;
    }
    return($self->options->{'tmp-dir'});
}

sub output_file {
    my ($self, $output_file) = @_;

    if (defined $output_file) {
	$self->options->{'output-file'} = $output_file;
    }
    return($self->options->{'output-file'});
}

sub reg_exps {
    my ($self, $reg_exps) = @_;

    if (defined $reg_exps) {
	%{$self->{'reg_exps'}} = %$reg_exps;
    }
    return($self->{'reg_exps'});
}

sub reg_exp_elt {
    my $self = shift;
    my $name;
    my $value;

    if (scalar(@_) >= 2) {
	($name, $value) = @_;
	# if (!defined $self->reg_exps->{$name}) {
	#     $self->reg_exps->{$name} = [];
	# }

	push @{$self->reg_exps->{$name}}, $value;
	return($self->reg_exps->{$name});
#	warn $self->reg_exps->{$name} . "\n";
    } else {
	if (scalar(@_) == 1) {
	    $name = $_[0];
	    return($self->reg_exps->{$name});
	}
    }
    return([]);
}


sub twig_parser {
    my ($self, $twig_parser) = @_;

    if (defined $twig_parser) {
	$self->{'twig_parser'} = $twig_parser;
    }
    return($self->{'twig_parser'});
}

sub _printOptions {
    my ($self, $fh) = @_;
    my $option;
    my %options = %{$self->options};

    if (!defined $fh) {
	$fh = \*stdout;
    }

    print $fh "\nOptions: \n";
    foreach $option (keys %options) {
	print $fh "\t$option: " . $options{$option} . "\n";
    }
    print $fh "\n";
}

sub defineTwigParser {
    my ($self) = @_;

    my $start_handlers = {
	'TERM_CANDIDATE' => \&processTerms,
    };
    my $twig_parser = Lingua::BioYaTeA::TwigXML->new(TwigHandlers => $start_handlers, 
						     keep_spaces_in => [''], 
						     pretty_print => 'indented', 
						     load_DTD=>0, 
						     keep_encoding=>1
	);
    $twig_parser->objectSelf($self);
    $self->twig_parser($twig_parser);
}

sub processTerms {
    my ($twig_parser,$data) = @_;

    my $field;
    my $regs_a;
    my $reg;
    my $term_data;
    my $dismissed = 0;

    # my $twig_parser = $self->twig_parser;

    # warn "\n$twig_parser\n";

    my $self = $twig_parser->objectSelf;

    my $logfh = $self->logfh;
    my $outfh = $self->outfh;

    # warn "\n$self\n";
    # warn "\n". $self->tc_counter . "\n";
    $self->tc_counter($self->tc_counter + 1);
    #print "Data ", $data->child(0)->text(), " ", scalar(keys %{$self->reg_exps}), "\t";

    mainloop:
    while (($field, $regs_a) = each (%{$self->reg_exps})) {
  	$term_data = $data->first_child_text($field);
	#print "Filter '$term_data'\t";

	foreach $reg (@$regs_a) {
	    if($self->exists_case_insensitive_elt($reg)) {
		if($term_data =~ /$reg/i) {
		    print $logfh $term_data;
		    print $logfh "\t(i) " . $field;
		    print $logfh "\t" . $reg . "\n";
		    $self->count_rejected($self->count_rejected + 1);
		    $data->set_att("DISMISSED"=>"TRUE");
		    $dismissed = 1;
		    #return;
			last mainloop;
		}
	    } else {
#               print "\n\t/$reg/";

# 		warn "\n$reg:\n";
		if($term_data =~ /$reg/) {
		    print $logfh $term_data;
		    print $logfh "\t" . $field;
		    print $logfh "\t" . $reg . "\n";
		    $self->count_rejected($self->count_rejected + 1);
		    $data->set_att("DISMISSED"=>"TRUE");
		    $dismissed = 1;
		    #return;
			last mainloop;
#		    return;
		}
	    }
	}
    }
    if ($dismissed) {
	$data->set_att("DISMISSED"=>"TRUE");
	#print " DISMISSED\n";
    } else {
	$data->set_att("DISMISSED"=>"FALSE");
	#print " not dismissed\n";
    }
    
    $twig_parser->flush($outfh);

}


sub load_configuration {
    my ($self) = @_;

    my $line;
    my $num_line=0;
    my $name;
    my $value;

    open (CONFIG, "<" . $self->configuration) || die "cannot open configutation file : " . $self->configuration . "\n"; 
    while ($line = <CONFIG>) {
	$num_line++;
	if(($line !~ /^\s*#/) && ($line !~ /^\s*$/)) {
	    chomp $line;
	    $line =~ s/\s+$//;
	    # warn "$line\n";
	    if($line =~ /^\s*CLEAN=([^:]+)::(.+)$/) {
		$name = $1;
		$value = $2;
		if($value =~ /^\/(.+)\/(i)$/) {
		    $self->case_insensitive_elt($1,$2);	
		    $self->reg_exp_elt($name, $1);
#		    $self->reg_exp_elt($name, $2);
		    
		} else {
		    $value =~ /^\/(.+)\/$/;
		    $self->reg_exp_elt($name, $1);
		}
	    } else {
		print STDERR "Invalid line in configuration file, line: " . $num_line . "\n"; 
	    }
	}
    }
    # print Dumper(\%reg_exp);
    print STDERR "Configuration file loaded\n";
# exit;
}

sub filtering {
    my ($self) = @_;

    my ($second,$minute,$hour,$day,$month,$year,$weekday,$yearday,$isdailysavingtime) = localtime(time);
    $year += 1900;

    if (!defined $self->logfile) {
	$self->logfile($self->tmp_dir . '/term-filtering-tmp-' . "date-$year-$month-${day}_${hour}_$minute" . '.log');
    }
    warn "openning " . $self->logfile . "\n";
    open (LOG, ">>" . $self->logfile)  || die "Cannot open " . $self->logfile . "\n";
    $self->logfh(\*LOG); 

    open(OUT, ">>".$self->output_file) || die "Cannot open " . $self->output_file . "\n";
    $self->outfh(\*OUT);

    warn "start parsing of " . $self->input_file . "\n";

    $self->twig_parser->{'SELF'} = $self;
    $self->twig_parser->parsefile($self->input_file); 

    $self->twig_parser->flush(\*OUT);
    close LOG;
    close OUT;
    return(1);
}

sub printResume {
    my ($self) = @_;

    print STDERR $self->tc_counter . " terms at the beginning\n";
    print STDERR ($self->tc_counter - $self->count_rejected) . " term candidate after filtering\n";
}

sub rmlog {
    my ($self) = @_;

    unlink($self->logfile);
}

1;
