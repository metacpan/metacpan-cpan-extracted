#
# $Id$
#
# database::cwe Brik
#
package Metabrik::Database::Cwe;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable cve) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         file => [ qw(file) ],
         xml => [ qw($xml_data) ],
      },
      attributes_default => {
         file => '2000.xml',
      },
      commands => {
         update => [ ],
         load => [ qw(cwe_xml_file) ],
         search => [ qw(cwe_pattern) ],
      },
      require_modules => {
         'Metabrik::File::Compress' => [ ],
         'Metabrik::File::Xml' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my $uri = 'http://cwe.mitre.org/data/xml/views/2000.xml.zip';
   my $file_zip = "2000.xml.zip";

   my @updated = ();
   my $files = $self->mirror($uri, $file_zip) or return;
   if (@$files > 0) {  # Some new stuff
      my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
      for my $file (@$files) {
         (my $outfile = $file) =~ s/\.zip$//;
         my $new_files = $fc->uncompress($file, $outfile, $datadir) or next;
         push @updated, @$new_files;
      }
   }

   return \@updated;
}

sub load {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->file;
   $self->brik_help_run_undef_arg('load', $file) or return;
   $self->brik_help_run_file_not_found('load', $file) or return;

   my $datadir = $self->datadir;

   my $fx = Metabrik::File::Xml->new_from_brik_init($self) or return;

   my $xml = $fx->read($datadir.'/'.$file) or return;

   return $self->xml($xml);
}

sub show {
   my $self = shift;
   my ($h) = @_;

   $self->brik_help_run_undef_arg('show', $h) or return;
   $self->brik_help_run_invalid_arg('show', $h, 'HASH') or return;

   my $buf = "ID: ".$h->{id}."\n";
   $buf .= "Type: ".$h->{type}."\n";
   $buf .= "Name: ".$h->{name}."\n";
   $buf .= "Status: ".$h->{status}."\n";
   $buf .= "URL: ".$h->{url}."\n";
   $buf .= "Description Summary: ".($h->{description_summary} || '(undef)')."\n";
   $buf .= "Likelihood of Exploit: ".($h->{likelihood_of_exploit} || '(undef)')."\n";
   $buf .= "Relationships:\n";
   for my $r (@{$h->{relationships}}) {
      $buf .= "   ".$r->{relationship_nature}." ".$r->{relationship_target_form}." ".
              $r->{relationship_target_id}."\n";
   }

   return $buf;
}

sub _to_hash {
   my $self = shift;
   my ($w, $type) = @_;

   my $id = $w->{ID};
   my $name = $w->{Name};
   my $status = $w->{Status};
   my $likelihood_of_exploit = $w->{Likelihood_of_Exploit};
   my $weakness_abstraction = $w->{Weakness_Abstraction};
   my $description_summary = $w->{Description}->{Description_Summary};
   if (defined($description_summary)) {
      $description_summary =~ s/\s*\n\s*/ /gs;
   }
   my $extended_description = $w->{Description}->{Extended_Description}->{Text};
   if (defined($extended_description)) {
      $extended_description =~ s/\s*\n\s*/ /gs;
   }
   my $relationships = $w->{Relationships}->{Relationship};
   # Potential_Mitigations
   # Affected_Resources

   my @relationships = ();
   if (defined($relationships)) {
      #print "DEBUG Processing ID [$id]\n";
      #print "DEBUG ".ref($relationships)."\n";
      # $relationships can be ARRAY or HASH, we convert to ARRAY
      if (ref($relationships) eq 'HASH') {
         $relationships = [ $relationships ];
      }
      for my $r (@$relationships) {
         my $relationship_nature = $r->{Relationship_Nature};
         my $relationship_target_id = $r->{Relationship_Target_ID};
         my $relationship_target_form = $r->{Relationship_Target_Form};
         push @relationships, {
            relationship_nature => $relationship_nature,
            relationship_target_id => $relationship_target_id,
            relationship_target_form => $relationship_target_form,
         };
      }
   }

   return {
      id => $id,
      type => $type,
      name => $name,
      status => $status,
      url => 'http://cwe.mitre.org/data/definitions/'.$id.'.html',
      likelihood_of_exploit => $likelihood_of_exploit,
      description_summary => $description_summary,
      relationships => \@relationships,
   };
}

sub search {
   my $self = shift;
   my ($pattern) = @_;

   my $xml = $self->xml;
   $self->brik_help_run_undef_arg('load', $xml) or return;
   $self->brik_help_run_undef_arg('search', $pattern) or return;

   my @list = ();
   if (exists $xml->{Weaknesses} && exists $xml->{Weaknesses}->{Weakness}) {
      my $weaknesses = $xml->{Weaknesses}->{Weakness};
      for my $w (@$weaknesses) {
         my $this = $self->_to_hash($w, 'Weakness');
         if ($this->{name} =~ /$pattern/i || $this->{id} =~ /^$pattern$/) {
            print $self->show($this)."\n";
            push @list, $this;
         }
      }
   }

   if (exists $xml->{Categories} && exists $xml->{Categories}->{Category}) {
      my $categories = $xml->{Categories}->{Category};
      for my $c (@$categories) {
         my $this = $self->_to_hash($c, 'Category');
         if ($this->{name} =~ /$pattern/i || $this->{id} =~ /^$pattern$/) {
            print $self->show($this)."\n";
            push @list, $this;
         }
      }
   }

   # XXX: TODO: type: Compound_Element

   return \@list;
}

1;

__END__

=head1 NAME

Metabrik::Database::Cwe - database::cwe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
