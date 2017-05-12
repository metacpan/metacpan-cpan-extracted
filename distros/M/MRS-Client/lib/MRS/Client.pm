#-----------------------------------------------------------------
# MRS::Client
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#
# ABSTRACT: A SOAP-based client of the MRS Retrieval server
# PODNAME: MRS::Client
#-----------------------------------------------------------------
use strict;
use warnings;

package MRS::Client;

our $VERSION = '1.0.1'; # VERSION

use vars qw( $AUTOLOAD );
use Carp;
use XML::Compile::SOAP11 2.26;
use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use File::Basename;
use Data::Dumper;

use MRS::Constants;
use MRS::Client::Databank;
use MRS::Client::Find;
use MRS::Client::Blast;
use MRS::Client::Clustal;

#-----------------------------------------------------------------
#
#  Expoted constants
#
#-----------------------------------------------------------------
use constant DEFAULT_SEARCH_ENDPOINT  => 'http://mrs.cmbi.ru.nl/m6/mrsws/search';
use constant DEFAULT_BLAST_ENDPOINT   => 'http://mrs.cmbi.ru.nl/m6/mrsws/blast';
use constant DEFAULT_CLUSTAL_ENDPOINT => 'http://mrs.cmbi.ru.nl/m6/mrsws/clustal';
use constant DEFAULT_ADMIN_ENDPOINT   => 'http://mrs.cmbi.ru.nl/m6/mrsws/admin';
use constant DEFAULT_SEARCH_WSDL      => 'search.wsdl.template';
use constant DEFAULT_BLAST_WSDL       => 'blast.wsdl.template';
use constant DEFAULT_CLUSTAL_WSDL     => 'clustal.wsdl.template';
use constant DEFAULT_ADMIN_WSDL       => 'admin.wsdl.template';
use constant DEFAULT_SEARCH_WSDL_6    => 'search.wsdl.template.v6';
use constant DEFAULT_BLAST_WSDL_6     => 'blast.wsdl.template.v6';
use constant DEFAULT_CLUSTAL_WSDL_6   => 'clustal.wsdl.template';   # no ClustalW in MRS 6
use constant DEFAULT_ADMIN_WSDL_6     => 'admin.wsdl.template';     # no Admin in MRS 6
use constant DEFAULT_SEARCH_SERVICE   => 'mrsws_search';
use constant DEFAULT_BLAST_SERVICE    => 'mrsws_blast';
use constant DEFAULT_CLUSTAL_SERVICE  => 'mrsws_clustal';
use constant DEFAULT_ADMIN_SERVICE    => 'mrsws_admin';


#-----------------------------------------------------------------
# A list of allowed options/arguments (used in the new() method)
#-----------------------------------------------------------------
{
    my %_allowed =
        (
         search_url       => 1,
         blast_url        => 1,
         clustal_url      => 1,
         admin_url        => 1,

         search_service   => 1,
         blast_service    => 1,
         clustal_service  => 1,
         admin_service    => 1,

         search_wsdl      => 1,
         blast_wsdl       => 1,
         clustal_wsdl     => 1,
         admin_wsdl       => 1,

         host             => 1,
         mrs_version      => 1,
         debug            => 1,
         );

    sub _accessible {
        my ($self, $attr) = @_;
        exists $_allowed{$attr};
    }
}

#-----------------------------------------------------------------
# Deal with 'set' and 'get' methods.
#-----------------------------------------------------------------
sub AUTOLOAD {
    my ($self, $value) = @_;
    my $ref_sub;
    if ($AUTOLOAD =~ /.*::(\w+)/ && $self->_accessible ("$1")) {

        # get/set method
        my $attr_name = "$1";
        $ref_sub =
            sub {
                # get method
                local *__ANON__ = "__ANON__$attr_name" . "_" . ref ($self);
                my ($this, $value) = @_;
                return $this->{$attr_name} unless defined $value;

                # set method
                $this->{$attr_name} = $value;
                return $this->{$attr_name};
            };

    } else {
        throw ("No such method: $AUTOLOAD");
    }

    ## no critic
    no strict 'refs';
    *{$AUTOLOAD} = $ref_sub;
    use strict 'refs';
    return $ref_sub->($self, $value);
}

#-----------------------------------------------------------------
# Keep it here! The reason is the existence of AUTOLOAD...
#-----------------------------------------------------------------
sub DESTROY {
}

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
    my ($class, @args) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    # set default values
    $self->search_url ($ENV{'MRS_SEARCH_URL'} or DEFAULT_SEARCH_ENDPOINT);
    $self->blast_url ($ENV{'MRS_BLAST_URL'} or DEFAULT_BLAST_ENDPOINT);
    $self->clustal_url ($ENV{'MRS_CLUSTAL_URL'} or DEFAULT_CLUSTAL_ENDPOINT);
    $self->admin_url ($ENV{'MRS_ADMIN_URL'} or DEFAULT_ADMIN_ENDPOINT);
    $self->search_service (DEFAULT_SEARCH_SERVICE);
    $self->blast_service (DEFAULT_BLAST_SERVICE);
    $self->clustal_service (DEFAULT_CLUSTAL_SERVICE);
    $self->admin_service (DEFAULT_ADMIN_SERVICE);

    $self->{compiled_operations} = {};

    # set all @args into this object with 'set' values
    my (%args) = (@args == 1 ? (value => $args[0]) : @args);
    foreach my $key (keys %args) {
        ## no critic
        no strict 'refs';
        $self->$key ($args {$key});
    }
    $self->host ($ENV{'MRS_HOST'}) if $ENV{'MRS_HOST'};

    # set MRS version
    $self->{mrs_version} = $ENV{'MRS_VERSION'} if $ENV{'MRS_VERSION'};
    $self->{mrs_version} = 6 unless $self->{mrs_version};

    # done
    return $self;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub is_v6 {
    my $self = shift;
    return (defined $self->{mrs_version} and $self->{mrs_version} eq '6');
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub host {
    my ($self, $host) = @_;
    return $self->{host} unless $host;

    my $current = $self->{host};

    # use $host and default ports,
    # unless some URLs were given specifically
    if ( $self->search_url eq DEFAULT_SEARCH_ENDPOINT or
         ($current and $self->search_url eq "http://$current:18081/") ) {
        $self->search_url  ("http://$host:18081/");
    }
    if ( $self->blast_url eq DEFAULT_BLAST_ENDPOINT or
         ($current and $self->blast_url eq "http://$current:18082/") ) {
        $self->blast_url  ("http://$host:18082/");
    }
    if ( $self->clustal_url eq DEFAULT_CLUSTAL_ENDPOINT or
         ($current and $self->clustal_url eq "http://$current:18083/") ) {
        $self->clustal_url  ("http://$host:18083/");
    }
    if ( $self->admin_url eq DEFAULT_ADMIN_ENDPOINT or
         ($current and $self->admin_url eq "http://$current:18084/") ) {
        $self->admin_url  ("http://$host:18084/");
    }

    $self->{host} = $host;
}

#-----------------------------------------------------------------
# Read the WSDL file, create from it a proxy and store it in
# itself. Do it only once unless $force_creation is defined.
#
# $ptype tells what kind of proxy to create: search, blast, clustal or
# admin.
#
# What WSDL file is read: It reads file previously set by one of the
# methods (depending which proxy should be read): search_wsdl(),
# blast_wsdl(), clustal_wsdl or admin_wsdl(). If such method was not
# called, the default WSDL is read from the file named '$ptype
# . _proxy', located in the same directory as this module.
# -----------------------------------------------------------------
sub _create_proxy {
    my ($self, $ptype, $default_wsdl, $force_creation) = @_;
    $self->{$ptype . '_proxy'} = undef if $force_creation;
    if (not defined $self->{$ptype . '_proxy'}) {
        my $wsdl;
        if (not defined $self->{$ptype . '_wsdl'}) {
            $wsdl = _readfile ( (fileparse (__FILE__))[-2] . $self->_default_wsdl ($ptype) );
            $wsdl =~ s/\${LOCATION}/$self->{$ptype . '_url'}/eg;
            $wsdl =~ s/\${SERVICE}/$self->{$ptype . '_service'}/eg;
        } else {
            $wsdl  = XML::LibXML->new->parse_file ($self->{$ptype . '_wsdl'});
        }
        $self->{$ptype . '_proxy'} = XML::Compile::WSDL11->new ($wsdl);
    }
}

sub _default_wsdl {
    my ($self, $ptype) = @_;

    if ($self->is_v6) {
        return DEFAULT_SEARCH_WSDL_6  if $ptype eq 'search';
        return DEFAULT_BLAST_WSDL_6   if $ptype eq 'blast';
        return DEFAULT_CLUSTAL_WSDL_6 if $ptype eq 'clustal';
        return DEFAULT_ADMIN_WSDL_6   if $ptype eq 'admin';
    } else {
        return DEFAULT_SEARCH_WSDL  if $ptype eq 'search';
        return DEFAULT_BLAST_WSDL   if $ptype eq 'blast';
        return DEFAULT_CLUSTAL_WSDL if $ptype eq 'clustal';
        return DEFAULT_ADMIN_WSDL   if $ptype eq 'admin';
    }
    die "Uknown proxy type '" . $ptype . "'\n";
}

sub _readfile {
    my $filename = shift;
    my $data;
    {
        local $/=undef;
        open my $file, '<', $filename or croak "Couldn't open file $filename: $!\n";
        $data = <$file>;
        close $file;
    }
    return $data;
}

#-----------------------------------------------------------------
# Make a SOAP call to a MRS server, using $proxy (created usually by
# _create_proxy), invoking $operation with $parameters (a hash
# reference).
# -----------------------------------------------------------------
sub _call {
    my ($self, $proxy, $operation, $parameters) = @_;

    # the compiled client for the same operation may be already
    # cached; if not then compile it and save for later
    my $call = $self->{compiled_operations}->{$operation};
    unless (defined $call) {
        $call = $proxy->compileClient ($operation);
        $self->{compiled_operations}->{$operation} = $call;
    }

    # make a SOAP call
    my ($answer, $trace) = $call->( %$parameters );

    if ($self->{debug}) {
        print "OPERATION: $operation, PARAMS:\n".Dumper ($parameters);
        print "RESPONSE:\n".Dumper ($answer);
        print $trace->printResponse unless defined $answer;
    }
    # print "CALL TRA:\n".Dumper ($trace);
    # $trace->printTimings;
    # $trace->printRequest;
    # $trace->printResponse;

    croak 'ERROR: ' . $answer->{Fault}->{'faultstring'} . "\n"
        if defined $answer and defined $answer->{Fault};

    return $answer;
}

#-----------------------------------------------------------------
# Factory method for creating one or more databanks:
#   it returns an array of MRS::Client::Databank if $db is undef or empty or 'all'
#   else it returns a databank indicated by $db (which is an Id)
#-----------------------------------------------------------------
sub db {
    my ($self, $db) = @_;

    return MRS::Client::Databank->new (id => $db, client => $self)
        if $db and $db ne 'all';

    $self->_create_proxy ('search');
    my $answer = $self->_call (
        $self->{search_proxy}, 'GetDatabankInfo', { db => 'all' });
    my @dbs = ();
    return @dbs unless defined $answer;
    foreach my $info (@{ $answer->{parameters}->{info} }) {
        push (@dbs, MRS::Client::Databank->new (%$info, client => $self, info_retrieved => 1));
    }
    return @dbs;
}

#-----------------------------------------------------------------
# The same as db->find but acting on all available databanks
#-----------------------------------------------------------------
sub find {
    my $self = shift;

    my $multi = MRS::Client::MultiFind->new ($self, @_);
    # $multi->{client} = $self;

    # create individual finds for each available databank
    $multi->{args} = \@_;   # will be needed for cloning
    $multi->{children} = $multi->_read_first_hits;
    $multi->{current} = 0;

    # do we have any hits, at all?
    $multi->{eod} = 1 if @{ $multi->{children} } == 0;

    return $multi;
}

#-----------------------------------------------------------------
# Create a blast object - it can be used for running more jobs, with
# different parameters [TBD: , giving a statistics about all jobs?]
#
# Create maximum one blast object; we do not need more.
# -----------------------------------------------------------------
sub blast {
    my $self = shift;
    return $self->{blastobj} if $self->{blastobj};
    $self->{blastobj} = MRS::Client::Blast->_new (client => $self);
    return $self->{blastobj};
}

#-----------------------------------------------------------------
# Create a clustal object; a simple factory method.
# -----------------------------------------------------------------
sub clustal {
    my $self = shift;
    croak "ClustalW service is not available in MRS server version 6 and above.\n"
        if $self->is_v6;
    return MRS::Client::Clustal->_new (client => $self);
}

#-----------------------------------------------------------------
#
# Admin calls ... work in progress, and not really supported, AND it
# disappeared completely in MRS 6
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# Return a script that parses a databank. $script is its name.
#-----------------------------------------------------------------
sub parser {
    my ($self, $script) = @_;

    croak "Empty parser name. Cannot retrieve it, I am afraid.\n"
        unless $script;

    $self->_create_proxy ('admin');
    my $answer = $self->_call (
        $self->{admin_proxy}, 'GetParserScript',
        { script => $script,
          format => 'plain' });
    return  $answer->{parameters}->{response};
}

1;


=pod

=head1 NAME

MRS::Client - A SOAP-based client of the MRS Retrieval server

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    # 1. create a client that does all the work:
    use MRS::Client;

    # ...by default it connects to the MRS service at http://mrs.cmbi.ru.nl/m6
    my $client = MRS::Client->new();

    # ...or let the client talk to your own MRS servers
    my $client = MRS::Client->new ( search_url  => 'http://localhost:18081/',
                                    blast_url   => 'http://localhost:18082/',;
                                    clustal_url => 'http://localhost:18083/');  # this only for MRS 5

    # ...or specify only a host, assuming the default ports are used
    my $client = MRS::Client->new ( host => 'localhost');

    # 2a. make various queries to a selected database:
    print $client->db ('uniprot')->find ('sapiens')->count;
    175642

    print $client->db ('uniprot')->find ('sapiens')->next;
    ID   Q14547_HUMAN            Unreviewed;        60 AA.
    AC   Q14547;
    DT   01-NOV-1996, integrated into UniProtKB/TrEMBL.
    DT   01-NOV-1996, sequence version 1.
    DT   19-JAN-2010, entry version 51.
    DE   SubName: Full=Homeobox-like;
    DE   Flags: Fragment;
    OS   Homo sapiens (Human).
    ...

    # show id, relevance score and title of two terms connected by AND
    my $query = $client->db ('enzyme')->find ('and' => ['snake', 'human'],
                                              'format' => MRS::EntryFormat->HEADER);
    while (my $record = $query->next) {
       print $record . "\n";
    }
    enzyme  3.4.21.95   17.6527424   Snake venom factor V activator.

    # ...show only title, but now the same two terms are connected by OR
    my $query = $client->db ('enzyme')->find ('or' => ['snake', 'human'],
                                              'format' => MRS::EntryFormat->TITLE);
    while (my $record = $query->next) {
       print $record . "\n";
    }
    Snake venom factor V activator.
    Jararhagin.
    Bothropasin.
    Trimerelysin I.
    ...

    # combine term-based (ranked) query with additional boolean expression
    my $query = $client->db ('uniprot')->find ('and' => ['snake', 'human'],
                                               query => 'NOT (kinase OR reductase)',
                                               'format' => MRS::EntryFormat->HEADER);
    print "Count: " . $query->count . "\n";
    while (my $record = $query->next) {
       print $record . "\n";
    }
    Count: 75
    nxs11_micsu     23.3861961      Short neurotoxin MS11;
    nxl2_micsu      22.7922745      Long neurotoxin MS2;
    nxl5_micsu      22.2648716      Long neurotoxin MS5;
    ...

    # 2b. explore full information about a database
    print $client->db ('enzyme');

    # ...or extract only information parts you want
    print $client->db ('enzyme')->version;
    print $client->db ('enzyme')->count;

    # 3. Or, almost all functionality is also available in a provided
    # script I<mrsclient>:

    mrsclient -h
    mrsclient -C
    mrsclient -c -n insulin
    mrsclient -c -p -d enzyme -a 'endothelin tyrosine'

    # 4. Run blastp on protein sequences:

    my @run_args = (fasta_file => 'protein.fasta', db => 'uniprot');
    my $job = $client->blast->run (@run_args);
    print STDERR 'JOB ID: ' . $job->id . ' [' . $job->status . "]\n";
    print $job;
    while (not $job->completed) {
       print STDERR 'Waiting for 10 seconds... [status: ' . $job->status . "]\n";
       sleep 10;
    }
    print $job->error if $job->failed;
    print $job->results;

    # Or, use for it the provide script I<mrsblast>:

    mrsblast -h
    mrsblast -i /tmp/snake.protein.fasta -d uniprot -x result.xml

    # 5. Run clustalw multiple alignment:
    # (available only for MRS version 5 and lower)

    my $result = $client->clustal->run (fasta_file => 'multiple.fasta' );
    print "ERROR: " . $result->failed if $result->failed;
    print $result->diagnostics;
    print $result;

    # Or, use for it the provide script I<mrsclustal>:

    mrsclustal -h
    mrsclustal -i multiple.fasta

=head1 DESCRIPTION

This module is a SOAP-based (Web Services) client that can talk, and
get data from an B<MRS server>, a search engine for biological and
medical databanks that searches well over a terabyte of indexed
text. See details about MRS and its author Maarten Hekkelman in
L</"ACKNOWLEDGMENTS">.

Because this module is only a client, you need an MRS server
running. You can install your own (see details in the MRS
distribution), or you need to know a site that runs it. By default,
this module contacts the MRS server at CMBI
(F<http://mrs.cmbi.ru.nl/m6/>).

The usual scenario is the following:

=over

=item *

Create a new instance of a client by calling:

    my $client = MRS::Client->new (%args);

=item *

Optionally, find out what databanks are available by calling:

    my @ids = map { $_->id } $client->db;
    print "Names:\n" . join ("\n", @ids) . "\n";

=item *

Make one or more queries on a selected databanks and iterate over the
result:

    my $query = $client->db ('enzyme')->find (['cone', 'snail']);
    while (my $record = $query->next) {
       print $record . "\n";
    }

Or, make the same query on all available databanks:

    my $query = $client->find (['cone', 'snail']);
    while (my $record = $query->next) {
       print $record . "\n";
    }

The format of returned records is specified by a parameter of the
I<find> method (see more in L<"METHODS">).

=item *

Additionally, this module provides access to I<blastp> program, using
MRS indexed databases. And it can invoke multiple alignment program
I<clustalw>.

=back

=head1 ATTENTION

I<For those updating from previous versions of> C<MRS::Client>: Because
the latest version of MRS server (version 6) is not backward
compatible with the previous version of the MRS server (version 5),
there are some significant (but fortunately not huge) changes needed
in your programs. Read details in L</"MRS VERSIONS">.

=head1 METHODS

=head2 MRS::Client

The main module is C<MRS::Client>. It lets the user specify which MRS
server to use, and few other global options. It also has a factory
method for creating individual databanks objects. Additionally, it
allows making query over all databanks. Finally, it covers all the
SOAP communication with the server.

=head3 new

    use MRS::Client;
    my $client = MRS::Client->new (@parameters);

The parameters are name-value pairs. The following names are recognized:

=over

=item search_url, blast_url, clustal_url

The URLs of the individual MRS servers, one providing searches (the
main one), one running blast and one running clustal. Default values
lead your searches to CMBI. If you have installed MRS servers on your
own site, and you are using the default values coming with the MRS
distribution, you create a client by (but see below parameter I<host>
for a shortcut):

    my $client = MRS::Client->new ( search_url  => 'http://localhost:18081/',
                                    blast_url   => 'http://localhost:18082/',
                                    clustal_url => 'http://localhost:18083/',   # this only for MRS 5
                                   );

Technical detail: These URLs will be used in the location field of the
WSDL description.

Alternatively, you can specify these parameters by environment
variables (because they will be probably same for most users from the
same site). The parameters, however, still have precedence over the
values of environment variables (even if they exist). The variables
are: I<MRS_SEARCH_URL>, I<MRS_BLAST_URL> and I<MRS_CLUSTAL_URL>.

B<NOTE:> Some sites may not have all MRS servers running.

=item host

A shortcut for specifying a host name in all URLs. The same as in the
above example can be accomplished by:

    my $client = MRS::Client->new (host => 'localhost');

Again, you can specify this parameter by an environment variables
MRS_HOST.

=item search_service, blast_service, clustal_service

The MRS servers are SOAP-based Web Services. Every Web Service has its
own I<service name> (the name used in the WSDL). You can change this
service name if you are accessing site where they use non-default
names. The default names - I guess almost always used - are:
mrsws_search, mrsws_blast, mrsws_clustal.

=item search_wsdl, blast_wsdl, clustal_wsdl

You can also specify your own WSDL file, each one for each set of
operations. It is meant more for debugging purposes because this
C<MRS::Client> module understands only current operations and adding
new ones to a new WSDL does not magically start using them. These
parameters may be useful when extending the C<MRS::Client>.

=back

=head3 setters/getters

The same names as the argument names described above can be used as
method names to get or set the parameter value. A method without an
argument gets the current value, a method with an argument sets the
new value. For example:

   print $client->search_url;
   $client->search_url ('http://my.own.server/mrs/search');

=head3 db

This is a factory method creating one or more databanks instances. It
accepts a single argument, a databank ID:

   print $client->db ('enzyme');

   Id:      enzyme
   Name:    Enzyme
   Version: 2013-05-27
   Count:   6115
   URL:     http://ca.expasy.org/enzyme/
   Parser:  enzyme
   Files:
           Version:       2013-05-27
           Modified:      2013-05-27 11:46 GMT
           Entries count: 6115
           Raw data size: 7436504
           File size:     45563041
           Unique Id:     fc0540bd-58a2-4de7-b3ff-6daff64ca13c
   Indices:
           enzyme         text               14881  Unique
           enzyme         de                  3650  Unique    Description
           enzyme         dr                420832  Unique    Database Reference
           enzyme         id                  6114  Unique    Identification
           enzyme         pr                   398  Unique    Prosite Reference

You can find out what databanks IDs are available by:

   print join ("\n", map { $_->id } $client->db);

Which brings us to the usage of the I<db> method without any
parameter, or with an empty parameter. In such cases, it creates an
array of C<MRS::Client::Databank> instances.

=head3 find

Make the same query to all databanks. The parameters are the same as
for the I<find> method called for an individual databank (see below).

   print "Databank\tID\tScore\tTitle\n";
   my $query = $client->find ('and' => ['cone', 'snail'],
                              'format' => MRS::EntryFormat->HEADER);
   while (my
      $record = $query->next) {
      print $record . "\n";
   }
   print $query->count . "\n";

   Databank  ID           Score       Title
   interpro  ipr020242    29.7122746  Conotoxin I2-superfamily
   interpro  ipr012322    27.8191032  Conotoxin, delta-type, conserved site
   ...
   omim      114020       3.40963793  cadherin 2
   omim      192090       3.40769672  cadherin 1
   sprot     cxd6d_concn  19.4017849  Delta-conotoxin CnVID;
   sprot     cxd6c_concn  19.3984871  Delta-conotoxin CnVIC;
   ...
   taxonomy  6495         53.980381   Conus tulipa fish-hunting cone snail
   trembl    q71ks8_contu 22.1446457  Four-loop conotoxin preproprotein;
   trembl    q9u7q6_contu 20.6787205  Calmodulin;
   ...
   149

The query (method I<next>) returns entries sequentially, one databank
after another. As with individual databanks, even here you can select
maximum number of entries to deliver - the number is applied for each
databank separately:

   my $query = $client->find ('and' => ['cone', 'snail'],
                              max_entries => 2,
                              'format' => MRS::EntryFormat->HEADER);
   while (my
      $record = $query->next) {
      print $record . "\n";
   }

   interpro  ipr020242    29.7122746  Conotoxin I2-superfamily
   interpro  ipr012322    27.8191032  Conotoxin, delta-type, conserved site
   omim      114020       3.40963793  cadherin 2
   omim      192090       3.40769672  cadherin 1
   sprot     cxd6d_concn  19.4017849  Delta-conotoxin CnVID;
   sprot     cxd6c_concn  19.3984871  Delta-conotoxin CnVIC;
   taxonomy  6495         53.980381   Conus tulipa fish-hunting cone snail
   trembl    q71ks8_contu 22.1446457  Four-loop conotoxin preproprotein;
   trembl    q9u7q6_contu 20.6787205  Calmodulin;

=head3 blast

   $client->blast

A factory method for creating a singleton instance of
F<MRS::Client::Blast>.

=head3 clustal

   $client->clustal

A factory method for creating instances of F<MRS::Client::Clustal>.

=head2 MRS::Client::Databank

This package represents an MRS databank and allows to query it. Each
databank consists of one or more files (represented by
C<MRS::Client::Databank::File>) and of indices
(C<MRS::Client::Databank::Index>).

A databank instance can be created by a I<new> method but usually it
is created by a factory method available in the C<MRS::Client>:

   my $db = $client->db ('enzyme');

The factory method, as well as the I<new> method, creates only a
"shell" databank instance - that is good enough for making queries but
which does not contain any databank properties (name, indices,
etc.) yet. The properties will be fetched from the MRS server only when
you ask for them (using the "getter" methods described below).

=head3 new

The only, and mandatory, parameter is I<id>:

   $db = MRS::Client::Databank->new (id => 'interpro');

The arguments syntax (the hash) is prepared for more arguments later
(perhaps). But it should not bother you because you would rarely use
this method - having the factory method I<db> in the client.

I<Recommendation:> Do not use this method directly, or check first how
it is used in the module C<MRS::Client>.

=head3 find

This is the crucial method of the whole C<MRS::Client> module. It
queries a databank and returns an C<MRS::Client::Find> instance that
can be used to iterate over found entries.

It takes many arguments. At least one of the "query" arguments (which
are I<query>, I<and> and I<or>) must be supplied; other arguments are
optional.

The arguments can always be specified as a hash, but for usual cases
there are few shortcuts. Let's look at the arguments as used in the
hash:

=over

=item C<and>

The value is an array reference where elements are terms that will be
combined by the AND boolean operator in a ranked query. For example:

   $find = $db->find ('and' => ['human', 'snake']);

This argument can also be used directly, not as a hash, assuming that
you do not need to use any other arguments:

   $find = $db->find (['human', 'snake']);

=item C<or>

The value is an array reference where elements are terms that will be
combined by the OR boolean operator in a ranked query. For example:

   $find = $db->find ('or' => ['human', 'snake']);

There can be either an I<and> or an I<or> argument, but not both. If
there are used both, a warning is issued and the I<and> one will take
precedence.

=item C<query>

The value is an expression, usually using some boolean operators (in
upper cases!):

   $find = $db->find (query => 'hemoglobinase AND NOT human');

If there are no boolean operators, it is used as a single term. For
example, these are equivalent:

   $find = $db->find (query => 'hemoglobinase activity');
   $find = $db->find ('and' => ['hemoglobinase activity']);

You can also use both, I<and> or I<or>, and I<query>. The query then
is an additional filter applied to the results found by the I<and> or
I<or> terms. For example:

   $find = $db->find ('and' => ['human', 'snake'],
                      query => 'NOT neurotoxin');

As a shortcut, the query parameter can also be used without a hash,
assuming again that you do not need to use any other arguments:

   $find = $db->find ('hemoglobinase AND NOT human');

=item C<algorithm>

B<Attention:> This argument is used only by MRS version 5,
See L<MRS VERSIONS> for details.

The ranked queries (the ones achieved by I<and> or I<or> arguments)
have assigned relevance score to their hits. The relevance score
depends on the used algorithm. The available values for this arguments
are defined in C<MRS::Algorithm>:

   package MRS::Algorithm;
   use constant {
      VECTOR   => 'Vector',
      DICE     => 'Dice',
      JACCARD  => 'Jaccard',
   };

The default algorithm is "Vector". For example (using the format
"header" - which is the only one that shows relevance scores):

   $client->$db('enzyme')->find ('and' => 'venom',
                                 algorithm => MRS::Algorithm->Dice,
                                 max_entries => 3,
                                 'format' => MRS::EntryFormat->HEADER);
   enzyme  3.4.24.43    14.9607477      Atroxase.
   enzyme  3.4.24.49    13.6817474      Bothropasin.
   enzyme  3.4.24.73    13.2007284      Jararhagin.

   $client->$db('enzyme')->find ('and' => 'venom',
                                 algorithm => MRS::Algorithm->Vector,
                                 max_entries => 3,
                                 'format' => MRS::EntryFormat->HEADER);
   enzyme  3.1.15.1     21.6520195      Venom exonuclease.
   enzyme  3.4.21.60    19.3931656      Scutelarin.
   enzyme  5.1.1.16     16.7410889      Protein-serine epimerase.

=item C<start>, C<offset>, C<max_entries>

These arguments do not affect the query itself but it tells which
entries from the found ones to retrieve (by the I<next> method - see
below).

All these three arguments have an integer value.

C<start> tells to skip entries at the beginning of the whole result
and start returning only with the entry with this order number. The
counting start from 1.

C<offset> is the same as the C<start>, except the counting starts from
zero.

C<max_entries> is the maximum entries to retrieve.

=item C<format>

This argument also does not affect the query itself but it defines the
format of the returned entries. The available values for this arguments
are defined in C<MRS::EntryFormat>:

   package MRS::EntryFormat;
   use constant {
       PLAIN    => 'plain',
       TITLE    => 'title',
       HTML     => 'html',
       FASTA    => 'fasta',
       SEQUENCE => 'sequence',
       HEADER   => 'header',
   };

The default format is 'plain'. The 'fasta' and 'sequence' formats are
available only for databanks that have sequence data. For all formats,
except for the 'header', the entries are returned as strings. For
'header', the entries are instances of C<MRS::Client::Hit>.

Be aware that C<format> is also a built-in Perl function, so better
quote it when used as a hash key (it seems to work also without quotes
except the emacs TAB key is confused if there are no surrounding
quotes; just a minor annoyance).

=item C<xformat>

This argument (C<eXtended format>) enhances the C<format> argument. It
is used (at least at the moment) only for HTML format; for other
formats, it is ignored. See, however, the L</"MRS VERSIONS"> about the
abandoned HTML format.

Be aware, however, that the C<xformat> depends on the structure of the
HTML provided by the MRS. This structure is not defined in the MRS
server API, so it can change easily. It even depends on the way how
the authors write their parsing scripts. When the HTML
output changes this module must be changed, as well. Caveat emptor.

The C<xformat> is a hashref with keys that change (slightly or
significantly) the returned HTML. Here are all possible keys
(with a randomly picked up values):

   xformat => { MRS::XFormat::CSS_CLASS()   => 'mrslink',
                MRS::XFormat::URL_PREFIX()  => 'http://cbrcgit:8080/mrs-web/'
                MRS::XFormat::REMOVE_DEAD() => 1, # 'or' => ['...']
                MRS::XFormat::ONLY_LINKS()  => 1 }

C<MRS::XFormat::CSS_CLASS> specifies a CSS-class name that will be
added to all C<a> tags in the returned HTML. It allows, for example,
an easy post-processing by various JavaScript libraries. For example,
if the original HTML contains:

   <a href="entry.do?db=go&amp;id=0005576"></a>

it will become (using the value shown above):

   <a class="mrslinks" href="entry.do?db=go&amp;id=0005576"></a>

C<MRS::XFormat::URL_PREFIX> helps to keep the returned HTML
independent on the machine where it was created. This option pre-pends
the given prefix to the relative URLs in the hyperlinks that point to
the data in an MRS web application. For example, if the original HTML
contains:

   <a href="entry.do?db=go&amp;id=0005576"></a>

it will become:

   <a href="http://cbrcgit:8080/mrs-web/entry.do?db=go&amp;id=0005576"></a>

Other hyperlinks - those not starting with C<query> or C<entry> - are
not affected.

C<XFormat::REMOVE_DEAD> deals with the fact that the MRS server
creates hyperlinks pointing to other MRS databanks without checking
that they actually exists in the local MRS installation. This may be
fixed later (quoting Maarten) but before it happens this option (if with a true
value) removes (from the returned HTML) all hyperlinks that point to
the not-installed MRS databanks. For example, if the original HTML has
these hyperlinks:

    <a href="query.do?db=embl&amp;query=ac:AF536179">AF536179</a>
    <a href="query.do?db=embl&amp;query=ac:D00735">D00735</a>
    <a href="entry.do?db=pdb&amp;id=1VZN">1VZN</a>
    <a href="entry.do?db=pdb&amp;id=2FK4">2FK4</a>

and the C<pdb> database is not locally installed, the returned HTML
will change to:

    <a href="query.do?db=embl&amp;query=ac:AF536179">AF536179</a>
    <a href="query.do?db=embl&amp;query=ac:D00735">D00735</a>
    1VZN
    2FK4

There is a small caveat, however. The MRS::Client needs to know what
databanks are installed. It finds out by asking the MRS server by
using the method C<db()> (explained elsewhere in this document). This
method returns much more than is needed, so it can be slightly
expensive. Therefore, if your concern is the highest speed, you can
help the MRS::Client by providing a list of databanks that you know
you have installed. Actually, in most cases, you can create such list
also by calling the C<db()> method but depending on your code you can
call it just ones an reuse it. For example, if you wish to keep
hyperlinks only for 'uniprot' and 'embl', you specify;

     xformat  => { MRS::XFormat::REMOVE_DEAD() => ['uniprot', 'embl'] }

Finally, there is an option C<MRS::XFormat::ONLY_LINKS>. It has a very
specific function: to extract and return C<only> the hyperlinks, not
the whole HTML. It is, therefore, predestined for further
post-processing. Note that all changes in the hyperlinks described
earlier are also applied here (e.g. adding an absolute URL or a CSS
class).

When this option is used, the whole method "$find->next" (or
"db->entry") returns a reference to an array of extracted
hyperlinks:

    my $find = $client->db('sprot')->find
        (and      => ['DNP_DENAN'],
         'format' => MRS::EntryFormat->HTML,
         xformat  => {
             MRS::XFormat::ONLY_LINKS()  => 1,
             MRS::XFormat::CSS_CLASS()   => 'mrslink',
         },
    );
    while (my $record = $find->next) {
    print join ("\n", @$record) . "\n";

Which prints something like:

    <a class="mrslink" href="entry.do?db=taxonomy&amp;id=8618">8618</a>
    <a class="mrslink" href="query.do?db=taxonomy&amp;query=Eukaryota">Eukaryota</a>
    ...
    <a class="mrslink" href="query.do?db=uniprot&amp;query=kw:Disulfide kw:bond ">Disulfide bond</a>
    ...
    <a class="mrslink" href="http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=...">92332489</a>
    ...
    <a class="mrslink" href="entry.do?db=go&amp;id=0009405"></a>

=back

=head3 count

It returns a number of entries in the whole databank.

   print $client->db ('enzyme')->count;
   4645

Do not confuse it with the method of the same name but called on the
object returned by the I<find> method - that one returns a number of
hits of that particular query.

=head3 entry

It takes an entry ID (mandatory), and optionally its format and
extended format, and it returns the given entry:

   print $client->db ('enzyme')->entry ('3.4.21.60');
   ID   3.4.21.60
   DE   Scutelarin.
   AN   Taipan activator.
   CA   Selective cleavage of Arg-|-Thr and Arg-|-Ile in prothrombin to form
   CA   thrombin and two inactive fragments.
   CC   -!- From the venom of Taipan snake (Oxyuranus scutellatus).
   CC   -!- Converts prothrombin to thrombin in the absence of coagulation factor
   CC       Va, and is potentiated by phospholipid and calcium.
   CC   -!- Specificity is similar to that of factor Xa.
   CC   -!- Binds calcium via gamma-carboxyglutamic acid residues.
   CC   -!- Similar enzymes are known from the venom of other Australian elapid
   CC       snakes Pseudonaja textilis, Oxyuranus microlepidotus and Demansia
   CC       nuchalis affinis.
   CC   -!- Formerly EC 3.4.99.28.
   //

    print $client->db ('enzyme')->entry ('3.4.21.60',
                                         MRS::EntryFormat->TITLE);
    Scutelarin.

The optional C<extended format> is a hashref and it was explained
earlier in the section about the C<find()> method.

=head3 id, name, version, blastable, url, script, files, indices, aliases

There are several methods delivering databank properties. They have no
arguments:

   my $db = $client->db('omim');
   print $db->id        . "\n";
   print $db->name      . "\n";
   print $db->version   . "\n";
   print $db->blastable . "\n";
   print $db->url       . "\n";
   print $db->script    . "\n";
   print $db->aliases   . "\n";

=head3 files

Each databank consists of one or more files. This method returns a
reference to an array of C<MRS::Client::Databank::File>
instances. Each such instance has properties reachable by the
following "getters" methods:

   sub say { print @_, "\n"; }

   my $db_files = $client->db('uniprot')->files;
   foreach my $file (@{ $db_files }) {
      say $file->id;
      say $file->version;
      say $file->last_modified;
      say $file->entries_count;
      say $file->raw_data_size;
      say $file->file_size;
      say '';
   }

=head3 indices

Each databank is indexed by (usually several) indices. This method
returns a reference to an array of C<MRS::Client::Databank::Index>
instances. Each such instance has properties reachable by the
"getters" method:

   my $db_indices = $client->db('uniprot')->indices;
   foreach my $idx (@{ $db_indices }) {
      printf ("%-15s%-15s%9d  %-9s %s\n",
              $idx->db,
              $idx->id,
              $idx->count,
              $idx->type,
              $idx->description);
   }

The index I<id> is important because it can be used in the
queries. For example, assuming that the database has an index I<os>
(organism species):

   $db->find (query => 'rds AND os:human');

=head2 MRS::Client::Find

This object carries results of a query; it is returned by the I<find>
method, called either on a databank instance or on the whole
client. Actually, in case of the whole client, the returned type is of
type C<MRS::Client::MultiFind> which is a subclass
C<MRS::Client::Find>.

=head3 db, terms, query, all_terms_required, max_entries

The getter methods just reflect query arguments (the ones given to the
C<find> method):

   sub say { print @_, "\n"; }

   my $find = $client->db('uniprot')->find('sapiens');
   say $find->db;
   say join (", ", @ {$find->terms });
   say $find->query;
   say $find->max_entries;
   say $find->all_terms_required;

The I<terms> (a ref array) are either from the I<and> or I<or>
argument, and the I<all_terms_required> is 1 (when terms are coming
from the I<and>) or zero.

=head3 count

Finally, you can get the number of hits of this query. Be aware (as
mentioned elsewhere in this document) that boolean queries return only
an estimate, usually much higher than is the reality.

=head2 MRS::Client::MultiFind

This object is returned from the C<find> method made to all
databanks. It is a subclass of the C<MRS::Client::Find> with one
additional method:

=head3 db_counts

It returns databank names and their total counts in a hash (not a
reference) where keys are the databank names and values the entry
counts:

    my %counts = $find->db_counts;
    foreach my $db (sort keys %counts) {
        printf ("%-15s %9d\n", $db, $counts{$db});
    }

=head2 MRS::Client::Hit

Finally, a tiny object representing a hit, a result of a query before
going to a databank for the full contents of a found entry. It
contains the databank's ID (where the hit was found), the score that
this hit achieved (for boolean queries, the score is always 1) and the
ID and title of the entry represented by this hit.

The corresponding getters methods are I<db>, I<score>, I<id> and
I<title>.

The I<next> method (as shown above) returns just hits (instead of the
full entries) when the format I<MRS::EntryFormat->HEADER> is
specified.

=head2 MRS::Client::Blast

The MRS servers provide sequence homology searches, the famous Blast
program (namely the I<blastp> program for protein sequences). An input
sequence (in FASTA format) is searched against one of the MRS
databanks. It can be any MRS databank whose method C<blastable>
returns true (e.g. uniprot). An input sequence and a databank are the
only mandatory input parameters. Other common Blast parameters are
also supported.

The invocation is asynchronous. It means that the I<run> method
returns immediately, without waiting for the Blast program to finish,
giving back a I<job id>, a handler that can be used later for polling
for status, and, once status indicates the Blast finishes, for getting
results (or an error message). This is the typical usage:

    my @run_args = (fasta_file => '...', db => '...', ...);
    my $job = $client->blast->run (@run_args);
    sleep 10 while (not $job->completed);
    print $job->error if $job->failed;
    print $job->results;

    529.0   1.346582e-149  [vsph_trije  ]  1 Snake venom serine protease homolog;
    509.0   1.411994e-143  [vspa_triga  ]  1 Venom serine proteinase 2A;
    508.0   2.823987e-143  [vsp1m_trist ]  1 Venom serine protease 1 homolog;
    506.0   1.129595e-142  [vsp07_trist ]  1 Venom serine protease KN7 homolog;
    488.0   2.961165e-137  [vsp2_trifl  ]  1 Venom serine proteinase 2;
    487.0   5.922331e-137  [vsp1_trije  ]  1 Venom serine proteinase-like protein;
    456.0   1.271811e-127  [vsp04_trist ]  1 Venom serine protease KN4 homolog;
    ...

You can also use provided script C<mrsblast> that polls for you (if
you wish so).

In order to create an C<MRS::Client::Blast> instance, use the factory method:

   my $blast = $client->blast;

=head3 run

The main method that starts Blast with the given parameters and
immediately returns an object C<MRS::Client::Blast::Job> that can be
used for all other important methods. If you plan to stop your Perl
program and start it again later, you need to remember the job ID:

   my $job = $blast->run (...);
   print $job->id;

The job ID can be later used to re-create the same (well, similar) Job
object (see method I<job> below) that again provides all important
methods (such as getting results).

The method I<run> has following arguments (the Job object has the same
"getter" methods), all given as a hash:

=over

=item db

An MRS databank to search against. Mandatory parameter.

=item fasta

A protein sequence in a FASTA format. Mandatory parameter unless
C<fasta_file> is given.

=item fasta_file

A name of a file containing a protein sequence in a FASTA
format. Mandatory parameter unless C<fasta> is given.

=item filter

Low complexity filter. Boolean parameter. Default is 1.

=item expect

E-value cutoff. A float value. Default is 10.0.

=item word_size

An integer. Default is 3.

=item matrix

Scoring matrix. Default BLOSUM62.

=item open_cost

Gap opening penalty. An integer. Default is 11.

=item extend_cost

Gap extension penalty. Default is 1.

=item query

An MRS boolean query to limit the search space.

=item gapped

A boolean parameter. Its true value performs gapped alignment. Default
is true.

=item max_hits

Limit reported hits. An integer. Default is 250.

=back

=head3 job

The method finds or re-creates a Job object of the given ID:

   my $job = $client->blast->job ('0f37a544-a7a2-4239-b950-65a6aa07d1ef');
   print $job->id;
   print $job->status;

It dies with an error if such Job is not known to the MRS server.

The returned Job object can be used to ask for the Job status, or for
getting the Job results. There is one caveat, however. The re-created
Job object is not that "rich" as was its original version: it does not
know, for example, what parameters were used to start this blast
job. Unfortunately, the MRS server keeps only the Job ID and nothing
else. Fortunately, the parameters are needed only for the results in
the XML format (see more about available formats below, in the method
I<$job-E<gt>results>) - and you can add them (if you still have them), as a
hash, to the C<job> method when re-creating a new Job instance:

   my $job - $client->blast->job ('0f37a544-a7a2-4239-b950-65a6aa07d1ef',
                                  fasta => '...',
                                  db    => 'iniprot', ...);

=head2 MRS::Client::Blast::Job

The Job object represents a single Blast invocation with a set of
input parameters and, later, with results. It is also used to poll for
the status of the running job. Instances of this objects are created
by the I<run> or I<job> methods of the C<blast> object. The Job's
methods are:

=over

=item id

Job ID, an important handler if you have to re-create an
C<MRS::Client::Blast::Job> object.

=item "getter" methods

All these methods are equivalent to (and named the same as) the
parameters given to the C<run> method (described above):

=over

=item db

=item fasta

=item fasta_file

=item filter

=item expect

=item word_size

=item matrix

=item open_cost

=item extend_cost

=item query

=item max_hits

=item gapped

=item

=back

=item status, completed, failed

The I<status> returns one of the C<MRS::JobStatus>:

   use constant {
      UNKNOWN  => 'unknown',
      QUEUED   => 'queued',
      RUNNING  => 'running',
      ERROR    => 'error',
      FINISHED => 'finished',
    };

The I<completed> returns true if the status is either C<ERROR> or
C<FINISHED>. The I<failed> returns true if the status is
C<ERROR>. Typical usage for polling a running job is:

   sleep 10 while (not $job->completed);

=item error

It returns an error message, or undef if the status is not
C<ERROR>. Typical usage is:

   print $job->error if $job->failed;

=item results

Finally, the more interesting method. It returns an object of type
C<MRS::Client::Blast::Result> that can be either used on its own (see
its "getter" method below), or converted to strings of one of the
format predefined in C<MRS::BlastOutputFormat>:

   use constant {
      XML   => 'xml',
      HITS  => 'hits',
      FULL  => 'full',
      STATS => 'stats',
   };

The format is the only parameter of this method. Default format is
C<HITS>. The conversion to the given format is done by overloading the
double quotes operator, calling internally the method "as_string". You
just print the object:

   print $job->results;

   447.0   6.511672e-125  [vspgl_glosh ]  1 Thrombin-like enzyme gloshedobin;
   429.0   1.706996e-119  [vsp2_viple  ]  1 Venom serine proteinase-like protein 2;
   421.0   4.369909e-117  [vsp12_trist ]  1 Venom serine protease KN12;
   419.0   1.747964e-116  [vsps1_trist ]  1 Thrombin-like enzyme stejnefibrase-1;
   ...

Where lines are individual hits and columns are: I<bit_score>,
I<expect>, sequence ID, number of HSPs for this hit, sequence
description.

Or, giving just the Blast run statistics:

   print $job->results (MRS::BlastOutputFormat->STATS);

   DB count:     514212
   DB length:    180900945
   Search space: 23664675636
   Kappa:        0.041
   Lambda:       0.267
   Entropy:      0.140

Or, showing everything (in a rather un-parsable form, useful more for
testing than anything else):

   print $job->results (MRS::BlastOutputFormat->FULL);

Or, in an XML format:

   print $job->results (MRS::BlastOutputFormat->XML);

=back

=head2 MRS::Client::Blast::Result

You can explore the returned Blast results by the following "getter"
methods - going from the whole result to the individual hits and
inside hits to the individual HSPs (High-scoring pairs):

=over

=item db_count

=item db_length

=item db_space

   Effective search space.

=item kappa

=item lambda

=item entropy

=item hits

It returns a reference to an array of C<MRS::Client::Blast::Hit>s
where each hit has methods:

=over

=item id

=item title

=item sequences

It is a reference to an array of sequence IDs.

=item hsps

It is a reference to an array of C<MRS::Client::Blast::HSP>s
where each HSP has methods:

=over

=item score

=item bit_score

=item expect

=item query_start

=item subject_start

=item identity

=item positive

=item gaps

=item subject_length

=item query_align

=item subject_align

=item midline

=back

=back

=back

Try to explore various result formats by using the provided script
C<mrsblast>. This waits for a job to be completed and then prints its
hits:

   mrsblast -d sprot -i 'your.fasta'

This shows Blast statistics:

   mrsblast -d sprot -i 'your.fasta' -N

This produces an XML output to a given file:

   mrsblast -d sprot -i 'your.fasta' -x results.xml

Finally, this gives a long listing with all details:

   mrsblast -d sprot -i 'your.fasta' -f

=head2 MRS::Client::Clustal

B<Attention:> This module is used only by MRS version 5,
See L<MRS VERSIONS> for details.

The module wrapping the multiple alignment program I<clustalw>. The
program is optional and, therefore, not all MRS servers may have
it. Use the factory method for creating instances of
F<MRS::Client::Clustal>:

   $client->clustal

=head3 run

The main method, invoking I<clustalw> with mandatory input sequences
and optionally a couple of other parameters:

   my $result = $client->clustal->run (fasta_file => 'my.proteins.fasta');

=over

=item fasta_file

A file with multiple sequences in FASTA format.

=item open_cost

A gap opening penalty (an integer).

=item extend_cost

A gap extension penalty (a float).

=back

It returns result in an instance of F<MRS::Client::Clustal::Result>.

=head3 open_cost

It returns what gap opening penalty has been set in the I<run> method.

=head3 extend_cost

It returns what gap extension penalty has been set in the I<run> method.

=head2 MRS::Client::Clustal::Result

It is created by running:

   $client->clustal->run (...);

=head3 alignment

It returns a reference to an array of
F<MRS::Client::Clustal::Sequence> instances. Each of them has methods
I<id> and I<sequence>. You can also just print the formatted alignment
(it uses its own I<as_string> method that overloads double quotes
operator):

   print $client->clustal->run (fasta_file => 'several.proteins.fasta');

   vsph_trije : -VMGWGTISATKETHPDVPYCANINILDYSVCRAAYARLPATSRTLCAGILE-----GGKDSCLTD----SGGPLICNGQFQGIVSWGGHPCGQP-RKPGLYTKVFDHLDWIKSIIAGNKDATCPP
   nxsa_latse : ----MKTLLLTLVVVTIV--CLDLGYTR--ICFNHQSSQPQTTKT-CS---------PGESSCYNK----QWS------DFRGTIIERG--CGCPTVKPGI------KLSCCESEVCNN-------
   pa21b_pseau: NLIQFGNMIQCANKGSRP--SLDYADYG-CYCGWGGSGTPVDELDRCCQVHDNCYEQAGKKGCFPKLTLYSWKCTGNVPTCNSKPGCKSFVCACDAAAAKC----FAKAPYKKENYNIDTKKRCK-

=head3 diagnostics

It shows the standard output of the underlying F<clustalw> program:

   my $result = $client->clustal->run (fasta_file => 'several.proteins.fasta');
   print $result->diagnostics;

    CLUSTAL 2.0.10 Multiple Sequence Alignments

   Sequence type explicitly set to Protein
   Sequence format is Pearson
   Sequence 1: vsph_trije    115 aa
   Sequence 2: nxsa_latse     83 aa
   Sequence 3: pa21b_pseau   118 aa
   Start of Pairwise alignments
   Aligning...

   Sequences (1:2) Aligned. Score:  13
   Sequences (1:3) Aligned. Score:  5
   Sequences (2:3) Aligned. Score:  8
   Guide tree file created: ...

   There are 2 groups
   Start of Multiple Alignment

   Aligning...
   Group 1:                     Delayed
   Group 2:                     Delayed
   Alignment Score -93

   GDE-Alignment file created ...

=head3 failed

It returns standard error output of the underlying F<clustalw>
program. It the program finished without problems, it returns undef.

=head1 MRS VERSIONS

The SOAP API of the MRS server slightly (or significantly, depending
on what you were using) changed between version 5 and 6 (the version
numbers indicate the MRS server version, not the version of the
C<MRS::Client> module). The C<MRS::Client> module can work with both
MRS server versions, but sometimes you have to tell what version you
are planning to connect to.

=head3 new parameter C<mrs_version>

By default, the C<MRS::Client> assumes that it connects to an MRS
server version 6 (or higher). But for MRS servers version 5 you need
to add a new argument B<mrs_version> to the client instance
constructor with a value that differs from 6 (and it not zero or
undef):

   my $client = MRS::Client->new (mrs_version => 5, host => '...');

You can also set the expected version by an environment variable
C<MRS_VERSION>:

   $ENV{MRS_VERSION} = 5;
   my $client = MRS::Client->new (host => '...');

You can also check what version your client is talking to, by a new
method B<is_v6> (mostly used rather internally):

   $client->is_v6()   # returns 1 or 0

The command-line tool C<mrsclient> got an additional parameter B<-V>:

   mrsclient -V5 -H... -l

=head3 missing some result formats

The MRS 6 server does not support anymore B<HTML> and B<sequence>
result formats. The C<sequence> format does not matter much because
the C<fasta> format continues to be provided and it is easy to get the
pure sequence from it. But the lack of the C<HTML> format is probably
the most significant (downgrade) change.

=head3 search algorithm not supported

The MRS 6 server does not accept anymore requests for different search
algorithms; it uses always the B<Vector> algorithm.

=head3 no ClustalW service

The MRS 6 server does not provide multiple sequence alignment
service. All remarks about ClustalW in this document are, therefore,
valid only for the MRS 5.

=head3 aliases

The MRS 6 brings a new concept: I<aliases>. An alias is a set of
databases, usually closely related. A typical example is an alias
C<uniprot> that combines together two databases, the C<sprot>
(SwissProt) and C<trembl> (TrEMBL). You can use an alias in all places
where so far only database IDs were possible.

However, the list of databases returned by the "db()" method does not
include the aliases. You need to ask individual databases for their
aliases:

   $client->db('sprot')->aliases();

=head1 MISSING FEATURES, CAVEATS, BUGS

=over

=item *

The MRS distinguishes between so-called I<ranked queries> and
I<boolean queries>, and it recognizes also I<boolean filters>. I
probably need to learn more about their differences. That's why you
may see some differences in query results shown by this module and the
B<mrsweb> web application (an application distributed together with
the implementation of the MRS servers).

The contents of the search field in the I<mrsweb> is first parsed in
order to find out if it is a boolean expression, or not. Depending on
the result it uses either a ranked or boolean query. It also splits
the terms and combine them (by default) with the logical AND. For
example, in I<mrsweb> if you type (using the F<uniprot>):

   cone snail

you get 134 entries. You get the same number of hits by the
C<MRS::Client> module when using an I<and> argument:

   print $client->db('uniprot')->find ('and' => ['cone','snail'])->count;
   134

But you cannot just pass the whole expression as a query string (as
you do in I<mrsweb>):

   print $client->db('uniprot')->find ('cone snail')->count;
   0

You get zero entries because the C<MRS::Client> considers the above as
one term. And if you add a boolean operator:

   print $client->db('uniprot')->find ('cone AND snail')->count;
   4609

then the boolean query was used and, as explained by the MRS, the
"query did not return an exact result, displaying the closest
matches". But, fortunately, when you iterate over this result, you
will get, correctly, just the 134 entries.

=item *

The MRS servers provide few more operations that are not-yet covered
by this module. It would be useful to discuss which of those are worth
to implement. They are:

   GetMetaData
   FindSimilar
   GetLinked
   Cooccurrence
   SpellCheck
   SuggestSearchTerms
   CompareDocuments
   ClusterDocuments

There is also a potentially useful attribute I<links> in the
databank's info which has not been yet explored by this module.

=back

=head1 ADDITIONAL FILES

Almost all functionality of the C<MRS::Client> module is also
available from a command-line controlled scripts F<mrsclient>,
F<mrsblast> and F<mrsclustal>. Try , for example:

    mrsclient -h
    mrsclient -C
    mrsclient -c -n insulin
    mrsclient -c -p -d enzyme -a 'endothelin tyrosine'
    mrsblast -h
    mrsclustal -h

=head1 DEPENDENCIES

The C<MRS::Client> module uses the following modules:

   XML::Compile::SOAP11
   XML::Compile::WSDL11
   XML::Compile::Transport::SOAPHTTP
   File::Basename
   File::Path
   Math::BigInt
   FindBin
   Getopt::Std

=head1 BUGS

Please report any bugs or feature requests to
L<http://github.com/msenger/MRS-Client/issues>.

=head1 ACKNOWLEDGMENTS

This client module would be useless without having an MRS server
(e.g. at F<http://mrs.cmbi.ru.nl/m6/>). The MRS stands for
B<Maarten's Retrieval System> and was developed (and is maintained) by
I<Maarten Hekkelman> at the CMBI (F<http://www.cmbi.ru.nl/>), with the
help and contributions from many others.

The MRS itself has also its own Perl module F<MRS.pm>, called plugin
and distributed together with the MRS, that accesses MRS server(s)
directly, without using the SOAP Web Services protocol. The plugin
was helpful to find out what the server might expect.

Additionally, the MRS distribution has few testing scripts that use
SOAP protocol to access data in the same way as this C<MRS::Client>
module does. Therefore, this module can be seen as an extension of
these testing scripts into a slightly more comprehensive and perhaps
more documented package.

The MRS server provides Blast results that are not in XML. In order to
make an XML output, this module uses, hopefully, the same format and
conversion as found in the MRS web application.

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


#-----------------------------------------------------------------
# only for debugging
#-----------------------------------------------------------------
# sub _print_operations {
#     my ($proxy) = @_;
#     my @opers = $proxy->operations();
#     foreach my $oper (@opers) {
#       print $oper->name . "\n";
#     }
#     print "\n";
# }

# sub _list_of_all_operations {
#     my $self = shift;
#     $self->_create_proxy ('search');
#     $self->_create_proxy ('blast');
#     $self->_create_proxy ('clustal');
#     $self->_create_proxy ('admin');

#     _print_operations ($self->{search_proxy});
#     _print_operations ($self->{blast_proxy});
#     _print_operations ($self->{clustal_proxy});
#     _print_operations ($self->{admin_proxy});
# }

