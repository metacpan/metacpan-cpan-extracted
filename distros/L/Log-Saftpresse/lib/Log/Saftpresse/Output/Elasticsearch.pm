package Log::Saftpresse::Output::Elasticsearch;

use Moose;

# ABSTRACT: plugin to write events to elasticsearch
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Output';

use Log::Saftpresse::Log4perl;

use Time::Piece;
use Search::Elasticsearch;
use JSON;
use File::Slurp;

has 'nodes' => ( is => 'rw', isa => 'Str', default => 'localhost:9200' );
has 'cxn_pool' => ( is => 'rw', isa => 'Str', default => 'Static' );
has 'type' => ( is => 'rw', isa => 'Str', default => 'log' );

has 'indices_template' => (
	is => 'rw', isa => 'Str', default => 'saftpresse-%Y-%m-%d' );

has 'template_name' => ( is => 'ro', isa => 'Str', default => 'saftpresse' );
has 'install_template' => ( is => 'ro', isa => 'Bool', default => 1 );
has 'template_file' => ( is => 'ro', isa => 'Maybe[Str]' );

has '_template_body' => ( is => 'ro', isa => 'HashRef', lazy => 1,
  default => sub {
    my $self = shift;
    my $json_text;
    if( defined $self->template_file ) {
      $json_text = read_file( $self->template_file );
    } else {
      $json_text = read_file( \*DATA );
    }
    return( from_json( $json_text ) );
  },
);

sub current_index {
	my $self = shift;
	return( Time::Piece->new->strftime( $self->indices_template ) );
}

has 'es' => ( is => 'ro', lazy => 1,
	default => sub {
		my $self = shift;
    $log->debug('connecting to elasticsearch: '.$self->nodes.'...');
		my $es = Search::Elasticsearch->new(
			nodes => [ split(/\s*,\s*/, $self->nodes) ],
			cxn_pool => $self->cxn_pool,
		);
    if( $self->install_template ) {
      $self->_es_install_template( $es );
    }
    return $es;
	},
);

has 'flush' => ( is => 'rw', isa => 'Bool', default => 1 );

has 'autoflush_count' => ( is => 'rw', isa => 'Int', default => 1000 );
has 'autoflush_size' => ( is => 'rw', isa => 'Int', default => 1000000 );
has 'autoflush_time' => ( is => 'rw', isa => 'Int', default => 10 );

has 'bulk' => (
  is => 'ro', isa => 'Search::Elasticsearch::Bulk', lazy => 1,
  default => sub {
    my $self = shift;
    return $self->es->bulk_helper(
      max_count => $self->autoflush_count,
      max_size => $self->autoflush_size,
      max_time => $self->autoflush_time,
    );
  },
);

sub _es_install_template {
  my ( $self, $es ) = @_;
  my $name = $self->template_name;
  if( $es->indices->exists_template( name => $name ) ) {
    $log->debug("index template '$name' already in place");
  } else {
    $log->info("installing index template '$name'...");
    $es->indices->put_template(
      name => $name,
      body => $self->_template_body,
    );
  }
  return;
}

sub index_event {
	my ( $self, $e ) = @_;

	if( defined $e->{'time'} &&
			ref($e->{'time'}) eq 'Time::Piece' ) {
		$e->{'@timestamp'} = $e->{'time'}->datetime;
		delete $e->{'time'};
	}
	$self->bulk->index( {
	    index  => $self->current_index,
	    type   => $self->type,
	    source => $e,
  } );

	return;
}

sub output {
	my ( $self, @events ) = @_;

	foreach my $event (@events) { 
		if( defined $event->{'type'} && $event->{'type'} ne $self->type ) {
			next;
		}
		$self->index_event( $event );
	}

  if( $self->flush ) { $self->bulk->flush; }

	return;
}


1;

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Output::Elasticsearch - plugin to write events to elasticsearch

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

__DATA__
{
  "template" : "saftpresse-*",
  "mappings" : {
    "_default_" : {
       "_all" : {"enabled" : true, "omit_norms" : true},
       "dynamic_templates" : [ {
         "floating-numbers" : {
           "match_pattern" : "regex",
           "match" : "delay",
           "mapping" : {
             "type" : "float"
           }
         }
       } , {
         "integer-numbers" : {
           "match_pattern" : "regex",
           "match" : "pid|size|port|len|dpt|spt|ttl|tls_keylen|connection_time|code",
           "mapping" : {
             "type" : "integer"
           }
         }
       } , {
         "simple_strings" : {
           "match_pattern" : "regex",
           "match" : "facility|priority|queue_id|service|method",
           "match_mapping_type" : "string",
           "mapping" : {
             "type" : "string",
             "index" : "not_analyzed",
             "omit_norms" : true
           }
         }
       } , {
         "string_fields" : {
           "match" : "*",
           "match_mapping_type" : "string",
           "mapping" : {
             "type" : "string",
             "index" : "analyzed",
             "omit_norms" : true,
             "fields" : {
               "raw" : {
                  "type": "string",
                  "index" : "not_analyzed",
                  "ignore_above" : 256
               }
             }
           }
         }
       } ]
    }
  }
}
