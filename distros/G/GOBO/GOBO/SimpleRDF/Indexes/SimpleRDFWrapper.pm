package GOBO::SimpleRDF::Indexes::SimpleRDFWrapper;
use Moose::Role;
use strict;
use RDF::Redland;
use RDF::Redland::Statement;
use Carp;

has model => (is=>'rw', isa=>'RDF::Redland::Model',
    default=>sub 
              {
              });

has prefix_map => (is=>'rw', isa=>'HashRef',
                   default=>sub {
                       {
                       }
                   });

sub get_model { shift->init_model }

sub init_model {
    my $self = shift;
    return $self->model if $self->model;
    my $storage = new RDF::Redland::Storage("memory");
    die "unable to create storage"	unless $storage;
    
    ## Create a model using our storage.
    my $rdf_model = new RDF::Redland::Model($storage, "");
    die "unable to create model" unless $rdf_model;
    printf STDERR "model = $rdf_model\n";
    $self->model($rdf_model);
    return $rdf_model;
}

sub bind_to_file {
    my $self = shift;
    my $file = shift;

    ## We want to access a local copy of our FOAF file, so define that here.
    my $uri = new RDF::Redland::URI("file:$file");

    ## create an RDF XML parser as that's the format of our FOAF file.
    my $parser = new RDF::Redland::Parser("rdfxml", "application/rdf+xml");
    die "unable to create parser" unless $parser;

    ## parse the file and add each triple found to our model.
    my $stream = $parser->parse_as_stream($uri, $uri);
    my $rdf_model = $self->model;
    while(!$stream->end) {
	$rdf_model->add_statement($stream->current);
	$stream->next;
    }
}

sub to_rdf {
    my $self = shift;
    my $x;
    if (@_ > 1 || scalar(@_) == 0) {
        $x = new GOBO::LinkStatement(@_);
    }
    else {
        $x = shift;
    }
    return undef unless defined $x;
    #confess("no_arg to to_rdf") unless defined $x;
    if ($x->isa('GOBO::Statement')) {
        my $rs = new RDF::Redland::Statement(map {$self->to_rdf($_)} ($x->node,$x->relation,$x->target));
        return $rs;
    }
    elsif ($x->isa('GOBO::Node')) {
        my $uri = $x->id;
        if ($uri =~ /^http/) {
        }
        elsif ($uri =~ /(\w+):(\S+)/) {
            my $prefix = $self->get_uriprefix($1);
            $uri = "$prefix/$1"."_$2";
        }
        else {
           my $prefix = $self->get_uriprefix('_');
            $uri = "$prefix/$uri";
        }
        my $rs = new RDF::Redland::URINode($uri);
        return $rs;
    }
    else {
        return $x;
    }
}

sub from_rdf {
    my $self = shift;
    my $x = shift;
    if ($x->isa('RDF::Redland::Statement')) {
        my $rs = new GOBO::LinkStatement(node=>$self->from_rdf($x->subject),
                                        relation=>$self->from_rdf($x->predicate),
                                        target=>$self->from_rdf($x->object));
        return $rs;
    }
    elsif ($x->isa('RDF::Redland::Node')) {
        my $uri = $x->uri->as_string;
        if ($uri =~ m@http://purl.org/obo/owl/(\S+)/(\S+)\_(\S+)@ && $1 eq $2) {
            return "$1:$3";
        }
        elsif ($uri =~ m@http://purl.org/obo/owl/\_/(.*)@) {
            return "$1";
        }
        else {
            return $uri;
        }
    }
    else {
        confess($x);
    }
    
}

sub get_uriprefix {
    my $self = shift;
    my $s = shift;
    return "http://purl.org/obo/owl/$s";
}



1;


=head1 NAME

GOBO::SimpleRDF::Indexes::SimpleRDFWrapper

=head1 SYNOPSIS

do not use this method directly

=head1 DESCRIPTION

Role of providing direct DB connectivity to RDF

=cut
