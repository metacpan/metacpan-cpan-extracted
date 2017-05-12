#$Id: SOAPClient.pm 596 2010-01-20 17:45:52Z maj $
package FSSM::SOAPClient;
use strict;
use warnings;

=head1 NAME

FSSM::SOAPClient - Access the Fortinbras FSSM web service

=head1 SYNOPSIS

 # create client
 my $client = FSSM::SOAPClient->new();

 # set parameters
 $client->search('none');
 $client->predictor('subtype B SI/NSI');
 $client->expansion('avg');
 $client->seqtype('nt');
 # or...
 $client->new( search => 'align', expansion => 'avg',
               seqtype => 'nt', predictor => 'subtype C SI/NSI' );

 # attach sequences
 $client->attach_seqs('my.fas');

 # run query
 my $result = $client->run;

 # parse query
 while ( my $item = $result->next_call ) {
    print $item->{seqid}, "\t";
    if ($item->{predicted}) {
       print "predicted SI\n";
    }
    else {
       print "predicted NSI\n";
    }
 }

=head1 DESCRIPTION

This module allows the user to conveniently call the HIV-1 coreceptor
predictor web service at L<http://fortinbras.us> and parse the
resulting analysis. For details about this service and its purpose,
please visit L<http://fortinbras.us/fssm>.

The external module L<SOAP::Lite> is required, and is available from CPAN.

=head1 USAGE

The basic steps are (1) create a client object, (2) set client
parameters, (3) attach a set of nucleotide or amino acid sequences,
(4) run the query to obtain a result object, (5) iterate the result
object to obtain the analysis for each sequence.

=over

=item Create a client

The client object is a 'factory', from which you can set parameters,
attach sequences, and run your query.

 my $client = FSSM::SOAPClient->new();

=item Set parameters

Parameters for a query include:

 Parameter  Function            Acceptable values
 =========  ===========         =================
 search     how to find V3      none | fast | align
 expansion  handle ambiguities  none | avg | full
 seqtype    residue type        aa | nt | auto
 predictor  desired matrix      names as given at 
                                http://fortinbras.us/fssm

To set parameters, call the corresponding method from the client:

 $client->search('none');
 $client->predictor('subtype B SI/NSI');

or use C<set_parameters()>:

 $client->set_parameters( search => 'none', expansion => 'avg' );

Parameters can also be set when the client is created:

 $client->new( search => 'align', expansion => 'avg',
               seqtype => 'nt', predictor => 'subtype C SI/NSI' );

For details on the meaning of these parameters, see 
L<http://fortinbras.us/fssm>.

If you forget the available parameters or their acceptable values, use
C<available_parameters>:

 @parameter_names = $client->available_parameters;
 @accepted_for_search = $client->available_parameters('search');

=item Attach sequences

To attach your sequences, call C<attach_seqs()>. You may specify

=over

=item * a FASTA-formatted file:

 $client->attach_seqs('my.fas');

=item * a hash reference with elements of the form C<$seq_id => $sequence>:

 $client->attach_seqs( { 'seq1' => 'ATC', 'seq2' => 'GGC' } )

=item * an array reference with hashref elements of the form  
C<{ seqid => $id, sequence => $sequence }>:

 @seqs = ( { seqid => $id, sequence => $sequence } );
 $client->attach_seqs(\@seqs);

=item * or, if you use BioPerl (L<http://bioperl.org>), an arrayref of 
BioPerl sequence objects of any type:

 @seqs = $align->each_seq;
 $client->attach_seqs( \@seqs );

=back

=item Running a query

Simply call C<run()> :

 my $result = $client->run;

=item Parsing the result

The result is returned in another Perl object (of class
C<FSSM::SOAPClient::Result>). Use C<next_call> from this object to
iterate through the analyses:

 while ( my $item = $result->next_call ) {
    print $item->{seqid}, "\t";
    if ($item->{predicted}) {
       print "predicted SI\n";
    }
    else {
       print "predicted NSI\n";
    }
 }

To obtain an array of all items at once, use C<each_call>:

 @items = $result->each_call;

Rewind the iterator with C<rewind>:

 $result->rewind;
 # starting over...
 while ( my $item = $result->next_call ) {
   # ...
 }

Use C<metadata()> to obtain the date, ip-address, and predictor used
for the run:
 
 $date_run = $result->metadata->{'date'};
 $ip = $result->metadata->{'your-ip'};
 $predictor_used = $result->metadata->{'predictor'};

=back

=head1 UNDER THE HOOD

The L<SOAP::Lite> client object can be retrieved with

 $soap = $client->soap_client()

The L<SOAP::SOM> message can be retrieved with

 $som = $client->som;

Request data in L<SOAP::Data> format can be retrieved with 

 $data = $client->request_data;

and cleared with

 $client->clear_request;

=head1 AUTHOR - Mark A. Jensen

    CPAN ID: MAJENSEN
    Fortinbras Research
    http://fortinbras.us

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<SOAP::Lite>, L<http://fortinbras.us/fssm>

=head1 METHODS

=cut

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.012';
    @ISA         = qw(Exporter);

    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
    use lib '..';
    use FSSM::SOAPClient::Config;
}

use SOAP::Lite +autodispatch => uri => 'FSSMService',
    proxy => $SERVICE_URL;
use SOAP::Transport::HTTP;

our $AUTOLOAD;

sub new
{
    my ($class, %parameters) = @_;
    my $self = bless ({}, ref ($class) || $class);
    # init
    $self->{_soap} = SOAP::Lite->new();
    $self->set_parameters( %parameters ) if %parameters;
    
    return $self;
}

=head3 run()

 Title   : run
 Usage   : $client->run;
 Function: run FSSM query using currently set client
           parameters
 Returns : result object on succesful query,
           undef on SOAP fault (see
           errcode() and errstr() for 
           detail)
 Args    : none

=cut

sub run {
    my $self = shift;
    unless ($self->request_data) {
	warn "No request created; query not run";
	return;
    }
    $self->{_errcode} = $self->{_errstr} = undef;
    $self->{_som} = $self->soap_client->run($self->request_data);
    if ( $self->som->fault) {
	$self->{_errcode} = $self->som->faultcode;
	$self->{_errstr} = $self->som->faultstring;
	return;
    }
    return FSSM::SOAPClient::Result->new($self->som);
}

=head3 attach_seqs()

 Title   : attach_seqs
 Usage   : 
 Function: attach a set of sequences to the client in 
           preparation for query
 Returns : true on sucess
 Args    : fasta file name | array of BioPerl seq objects |
	   arrayref of hashes { seqid => $id, sequence => $seq }|
	   hashref of { $id => $sequence, ... }

=cut

sub attach_seqs {
    my $self = shift;
    my $collection = shift;
    my $seqs;
    unless ($collection) {
	die "attach_seqs() requires a sequence collection argument";
    }
    for (ref($collection)) {
	!$_ && do {
	    # assume file name
	    unless (-e $collection) {
		die "attach_seqs(): File '$collection' cannot be found";
	    }
	    $seqs = _parse_fasta($collection);
	    unless ($seqs) {
		die "attach_seqs(): Could not parse file '$collection' as FASTA";
	    }
	    last;
	};
	$_ eq 'ARRAY' && do {
	    if (ref($collection->[0]) eq 'HASH') {
		unless ($$collection[0]->{seqid} &&
			$$collection[0]->{sequence}) {
		    die "attach_seqs(): Could not parse array elements";
		}
		$seqs = $collection;
		last;
	    }
	    elsif (ref($collection->[0]) =~ /^Bio::/) {
		unless ($$collection[0]->can('id') &&
			$$collection[0]->can('seq') &&
			$$collection[0]->can('alphabet')) {
		    die "attach_seqs(): Could not parse array elements";
		}
		$seqs = [];
		foreach my $seq (@$collection) {
		    push @$seqs, { 'seqid' => $seq->id,
				   'type' =>  ($seq->alphabet =~ /^.na/) ?
				       'nt' : 'aa',
				       'sequence' => $seq->seq };
		}
		last;
	    }
	    else {
		die "attch_seqs(): Could not parse array elements";
	    }
	};
	$_ eq 'HASH' && do {
	    $seqs = [];
	    foreach my $id ( keys %$collection ) {
		push @$seqs, { 'seqid' => $id,
			       'sequence' => $$collection{$id} };
	    }
	    last;
	};
	do { #else
	    die "attach_seqs(): sequence collection argument not recognized";
	};
    }
    $self->{_seqs} = $seqs;
    return 1;
}

=head2 Parameters

=head3 seqtype()

 Title   : seqtype
 Usage   : 
 Function: get/set sequence type [aa|nt|auto] for the client
 Returns : scalar string
 Args    : [aa|nt|auto]
           aa   : amino acid data
           nt   : nucleotide data
           auto : let BioPerl guess each sequence (unreliable when
                  many ambiguity symbols present)

=cut

sub seqtype {
    my $self = shift;
    my $seqtype = shift;
    unless ($seqtype) {
	$self->parameters_changed(0);
	return $self->{_seqtype};
    }
    unless ( $seqtype =~ /^a[a|uto]|[dr]na|nt|protein$/i ) {
	die __PACKAGE__."::seqtype(): Invalid sequence type";
    }
    $self->parameters_changed(1);
    return $self->{_seqtype} = 'auto' if ($seqtype =~ /auto/i);
    return $self->{_seqtype} = 'aa' if ($seqtype =~ /^aa|protein$/i);
    return $self->{_seqtype} = 'nt' if ($seqtype =~ /^.na$/i);
}

=head3 predictor()

 Title   : predictor
 Usage   : $client->predictor('subtype B SI/NSI');
 Function: get/set underlying predictor for client
 Returns : scalar string
 Args    : run $client->available_parameters('predictor') 
           for a list of accepted predictors

=head3 expansion()

 Title   : expansion
 Usage   : $client->expansion('avg');
 Function: get/set ambiguity expansion selector for client
 Returns : scalar string
 Args    : none | avg | full
           none : no amibiguity expansion (ambig treated like 'X')
           avg  : return average score over all possible non-ambig seqs
           full : return individual scores for all non-ambig seqs 
                  (can fail if too many)

=head3 search()

 Title   : search
 Usage   : $client->search('align');
 Function: get/set search selector for client
 Returns : scalar string
 Args    : none | fast | align
           none : treat each sequence as already aligned
           fast : find V3 loop using a regular expression heuristic
           align: align seqs to PSSM matrix to find V3 loop

=cut

=head2 Parameter manipulation

=head3 set_parameters()

 Title   : set_parameters
 Usage   : 
 Function: set client parameters
 Returns : 
 Args    : 

=cut

sub set_parameters {
    my $self = shift;
    my %args = @_;
    if (@_ % 2) {
	die "set_parameters requires named parameters";
    }
    foreach (keys %args) {
	if (! grep /^$_$/, keys %PARAM_VALUES) {
	    warn "Parameter '$_' not recognized; skipping...";
	    next;
	}
	$self->$_($args{$_});
    }
    return $self->parameters_changed(1);
}

=head3 get_parameters()

 Title   : get_parameters
 Usage   : 
 Function: get current client parameters
 Returns : array
 Args    : none

=cut

sub get_parameters {
    my $self = shift;
    my @ret;
    for (keys %PARAM_VALUES) {
	push @ret, $_, $self->$_;
    }
    $self->parameters_changed(0);
    return @ret;
}

=head3 reset_parameters()

 Title   : reset_parameters
 Usage   : 
 Function: reset client parameters
 Returns : 
 Args    : 

=cut

sub reset_parameters {
    my $self = shift;
    my %args = @_;
    if (@_ % 2) {
	die "set_parameters requires named parameters";
    }
    foreach (keys %PARAM_VALUES) {
	undef $self->{"_$_"};
    }
    $self->set_parameters(%args);
}

=head3 available_parameters()

 Title   : available_parameters
 Usage   : @parms = $client->available_parameters;
           @accept = $client->available_parameters('seqtype');
 Function: list available parameters or acceptable values
 Returns : array of scalar strings or undef
 Args    : scalar string (a valid parameter name)

=cut

sub available_parameters {
    my $self = shift;
    my $parm = shift;
    unless ($parm) {
	return sort keys %PARAM_VALUES;
    }
    return unless grep /^$parm$/, keys %PARAM_VALUES;
    return @{$PARAM_VALUES{$parm}};
}

=head3 parameters_changed()

 Title   : parameters_changed
 Usage   : 
 Function: set if client parameters have been changed
           since last parameter access
 Returns : boolean
 Args    : new value or undef

=cut

sub parameters_changed { 
    my $self = shift;
    return $self->{_parameters_changed} = shift if @_;
    return $self->{_parameters_changed};
}

=head2 Accessors/Attributes

=head3 soap_client()

 Title   : soap_client
 Usage   : $soap = $client->soap_client
 Function: Get the SOAP::Lite client attached to this object
 Returns : a SOAP::Lite object or undef
 Args    : none

=cut

sub soap_client { shift->{_soap} }

=head3 som()

 Title   : som
 Alias   : message
 Usage   : $som = $client->som
 Function: get the current SOAP::SOM (message) object 
           attached to the client
 Returns : a SOAP::SOM object or undef
 Args    : none

=cut

sub som { shift->{_som} }
sub message { shift->{_som} }

=head3 request_data()

 Title   : request_data
 Usage   : $data =$self->request_data
 Function: creates/gets the SOAP::Data structure forming the 
           request
 Returns : a SOAP::Data object
 Args    : none

=cut

sub request_data {
    my $self = shift;
    return $self->{_request_data} if $self->{_request_data};
    my $go = 1;
    $go &&= $_ for ( map { $self->$_ } keys %PARAM_VALUES );
    unless ($go) {
	warn "Missing parameters; can't create request (try get_parameters())";
	return;
    }
    $go &&= $self->{_seqs};
    unless ($go) {
	warn "No sequences attached; can't create request (try attach_seqs())";
	return;
    }

    my $expand = ($self->expansion eq 'none' ? 0 : 1);
    my @x;
    if ($self->expansion eq 'none') {
	push @x, SOAP::Data->name( 'ExpandQ' => 0 );
    }
    else {
	push @x, (SOAP::Data->name( 'ExpandQ' => 1 ), 
		  SOAP::Data->name( 'ExpandParam' => 
				    $XPND_TBL{$self->expansion}));
    }
    return $self->{_request_data} =
	SOAP::Data->name('request' => \SOAP::Data->value(
			     SOAP::Data->name('Residue' => $self->seqtype),
			     SOAP::Data->name('PredictorParam' =>
					      $self->predictor),
			     SOAP::Data->name('SearchParam' =>
					      $self->search),
			     @x,
			     SOAP::Data->name(
				 'SeqSet' => \SOAP::Data->value(
				     $self->_package_seqs
				 )
			     )
			 )
	);
}

=head3 clear_request()

 Title   : clear_request
 Usage   : $client->clear_request
 Function: reset the request data
 Returns : true
 Args    : none

=cut

sub clear_request { delete shift->{_request_data}; return 1 }


=head3 ok(), errcode(), errstr()()

 Title   : ok(), errcode(), errstr()
 Usage   : if (!$client->ok()) { warn $client->errstr }
 Function: test the SOAP response message for faults
 Returns : ok() : true if success, false if fault present
           errcode() : the SOAP fault code (scalar int)
           errstr() : the SOAP faultstring (scalar string)
 Args    : none

=cut

sub errcode { my $self = shift; $self->som && $self->som->faultcode; }
sub errstr { my $self = shift; $self->som && $self->som->faultstring; }
sub ok { my $self = shift; $self->som && !$self->som->fault; }

# package sequence collection into SOAP::Data objects

sub _package_seqs {
    my $self = shift;
    return unless $self->{_seqs};
    my @ret;
    
    foreach (@{$self->{_seqs}}) {
	push @ret, SOAP::Data->name('sequence' => $_->{sequence})
	    ->attr( { seqid => $_->{seqid} } );
    }
    return @ret;
}

sub _parse_fasta {
    my $file = shift;
    open (my $fh, "<", $file) or die "parse_fasta(): Input file issue : $!";
    my $ret = [];
    my $item;
    my $in_seq;
    my $i = 1;
    my @lines = <$fh>;
    foreach (@lines) {
	chomp;
	/^>/ && do {
	    if ($in_seq) {
		push @$ret, $item;
	    }
	    my ($nm) = /^>([^[:space:]]+)/;
	    $nm ||= "seq".$i++;
	    $item = { 'seqid' => $nm,
		      'sequence' => ''};
	    $in_seq = 0;
	    next;
	};
	do {
	    unless (defined $in_seq) {
		die "parse_fasta(): file does not appear to be in FASTA format";
	    }
	    $in_seq = 1;
	    s/\s//g;
	    if (/[^-~?A-Za-z]/) {
		die "parse_fasta(): unrecognized sequence characters";
	    }
	    $item->{'sequence'} .= $_;
	    next;
	};
    }
    # last one
    push @$ret, $item;
    return $ret;
}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    if (grep /^$method$/, keys %PARAM_VALUES) {
	my $arg = shift;
	$self->parameters_changed(0);
	return $self->{"_$method"} unless $arg;
	unless (grep /^$arg$/, @{$PARAM_VALUES{$method}}) {
	    die "Invalid argument '$arg' for parameter '$method' in ".__PACKAGE__;
	}
	$self->parameters_changed(1);
	return $self->{"_$method"} = $arg;
    }
    else {
	die "Can't locate method '$method' in ".__PACKAGE__;
    }
}

sub DESTROY {}

1;

package FSSM::SOAPClient::Result;
use strict;
use warnings;

=head1 NAME

FSSM::SOAPClient::Result - access the returned FSSM analysis

C<FSSM::SOAPClient::Result> objects are returned by C<FSSM::SOAPClient::run()>. Use the following methods to retrieve the analysis.

=head1 METHODS

=cut

sub new { 
    my $class = shift;
    my $som = shift;
    die "SOM object required at arg 1" unless $som and 
	ref($som) eq 'SOAP::SOM';
    bless {
	_som => $som,
	_idx => 0
    }, $class;
}

=head3 next_call()

 Title   : next_call
 Usage   : $item = $result->next_call
 Function: get the FSSM call for the next submitted sequence
 Returns : hashref of data, with the following key => value pairs:
           seqid => the submitted sequence name/id
           ourid => the id as modified by FSSM (for differentiating
                    among strand/frame/non-amibig translations of
                    a single submitted sequence, with symbol
                    indicating comment)
           score => PSSM score
           left-end => 5' or N-terminal coordinate of V3
           right-end => 3' or C-terminal coordinate of V3
           comment => describes a possible caveat for this sequence
           predicted => 1 if X4/SI or dual, 0 if R5/NSI
           plabel => predicted phenotype in this predictor's context
 Args    : none

=cut

sub next_call {
    my $self = shift;
    my $ret = ($self->{_som}->valueof("//Result/seq-result"))[$self->{_idx}];
    return unless $ret;
    ($self->{_idx})++;
    return $ret;
    
}

=head3 rewind()

 Title   : rewind
 Usage   : $result->rewind
 Function: reset the next_call iterator to the beginning
 Returns : true
 Args    : none

=cut

sub rewind { shift->{_idx} = 0; 1 };

=head3 each_call()

 Title   : each_call
 Usage   : @calls = $result->each_call;
 Function: returns an array of call hashes as described 
           in next_call()
 Returns : array of hashrefs
 Args    : none

=cut

sub each_call {
    my @ret = shift->{_som}->valueof("//Result/seq-result/");
    return @ret;
}

=head3 metadata()

 Title   : metadata
 Alias   : meta
 Usage   : $run_info = $result->metadata
 Function: Obtains some data about the run
 Returns : hashref with following key => value pairs
           date : date/time of run
           your-ip : ip address from which the run originated
           predictor : predictor used
 Args    : none

=cut

sub metadata {
    return shift->{_som}->valueof("//Result/meta");
}

sub meta { shift->metadata }

sub DESTROY {
    my $self = shift;
    delete $self->{_som};
}
