package Dist::Inkt::Role::AddExternalRDF;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.110';

use Moose::Role;
use namespace::autoclean;
use RDF::Trine::Parser;
use Path::Tiny;

with 'Dist::Inkt::Role::RDFModel';

after PopulateModel => sub {
  my $self = shift;

  my $justaddfile = path($ENV{'DIST_INKT_ADD_DATA'} || "~/.dist-inkt-data.ttl");
  my $filteredfile = path($ENV{'DIST_INKT_FILTERED_DATA'} || "~/.dist-inkt-filtered-data.ttl");
  my $base_uri = sprintf('http://purl.org/NET/cpan-uri/dist/%s/', $self->name);

  if ($justaddfile->is_file) {
	 $self->log('Reading %s', $justaddfile);
	 
	 my $p = RDF::Trine::Parser->guess_parser_by_filename($justaddfile->basename);
	 $p->parse_file_into_model($base_uri, $justaddfile->filehandle, $self->model);
  }
  
  if ($filteredfile->is_file) {
	 $self->log('Reading %s', $filteredfile);
	 my %resources;
	 my $iter = $self->model->as_stream;
	 while (my $st = $iter->next) {
		if ($st->subject->is_resource) {
		  $resources{$st->subject->uri_value} = 1;
		}
		if ($st->predicate->is_resource) {
		  $resources{$st->predicate->uri_value} = 1;
		}
		if ($st->object->is_resource) {
		  $resources{$st->object->uri_value} = 1;
		}
	 }
	 my $proto = RDF::Trine::Parser->guess_parser_by_filename($filteredfile->basename);
	 my $p = $proto->new;
	 my $handler = sub {
		my $st = shift;
		if ($resources{$st->subject->uri_value}) {
		  $self->model->add_statement( $st );
		}
	 };
	 $p->parse_file($base_uri, $filteredfile->filehandle, $handler);
  }
  
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Inkt::Role::AddExternalRDF - Role to add data from sources outside the distribution

=head1 DESCRIPTION

This role provides a way to add RDF data from outside the
distribution. This would typically be used for statements that are
common to various distributions.

Two files can be used: One containing statements that will be added to
the DOAP of all distributions unconditionally, and one containing
statements that will be added to the DOAP only if the subject of the
statement matches a URI already in the data. The latter can be used to
augment data conditionally.

The file location can be specified with two environment variables:

C<<DIST_INKT_ADD_DATA>> for the first file, and
C<<DIST_INKT_FILTERED_DATA> for the second file. If they are not
given, the defaults are C<<~/.dist-inkt-data.ttl>>,
C<<~/.dist-inkt-filtered-data.ttl>> respectively.

When these files are parsed, the parser will set the base URI to
C<<http://purl.org/NET/cpan-uri/dist/Distribution-Name/>>, where
C<<Distribution-Name>> is the name of your distribution. Thus, you can
make statements about your project by simply using relative URLs, e.g.

 <project> doap:programming-language "Perl" .


=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2018 Kjetil Kjernsmo

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
