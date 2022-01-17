#
# $Id$
#
# lookup::countrycode Brik
#
package Metabrik::Lookup::Countrycode;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable iana cc tld) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(file) ],
         _data => [ qw(INTERNAL) ],
         _data_by_tld => [ qw(INTERNAL) ],
      },
      commands => {
         update => [ ],
         load => [ qw(input|OPTIONAL) ],
         load_by_tld => [ qw(input|OPTIONAL) ],
         list_types => [ ],
         list_tlds => [ ],
         from_tld => [ qw(tld) ],
      },
      require_modules => {
         'Metabrik::File::Csv' => [ ],
         'Metabrik::System::File' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;

   return {
      attributes_default => {
         input => $datadir.'/country-codes.csv',
      },
   };
}

sub _load {
   my $self = shift;

   my $data = $self->_data;
   if (! defined($data)) {
      $data = $self->load or return;
      $self->_data($data);
   }

   return $data;
}

sub _load_by_tld {
   my $self = shift;

   my $data = $self->_data_by_tld;
   if (! defined($data)) {
      $data = $self->load_by_tld or return;
      $self->_data_by_tld($data);
   }

   return $data;
}

sub list_types {
   my $self = shift;

   my $data = $self->_load or return;

   my %list = ();
   for my $this (@$data) {
      $list{$this->{type}}++;
   }

   my @types = sort { $a cmp $b } keys %list;

   return \@types;
}

sub list_tlds {
   my $self = shift;

   my $data = $self->_load or return;

   my %list = ();
   for my $this (@$data) {
      $list{$this->{tld}}++;
   }

   my @tlds = sort { $a cmp $b } keys %list;

   return \@tlds;
}

#
# Port numbers:
# http://www.iana.org/protocols
# http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
#
sub update {
   my $self = shift;

   my $input = $self->input;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->remove($input);

   my $uri = 'http://www.iana.org/domains/root/db';

   my $get = $self->get($uri) or return;
   my $html = $get->{content};

   my @cc = ();
   while ($html =~ m{<span class="domain tld">(.*?)</tr>}gcs) {
      my $this = $1;

      $this =~ s/\n//g;

      $self->log->debug("update: this[$this]");

      # <tr>
      #  <td>
      #   <span class="domain tld"><a href="/domains/root/db/aaa.html">.aaa</a></span></td>
      #  <td>generic</td>
      #  <td>American Automobile Association, Inc.</td>
      # </tr>

      my ($tld, $type, $sponsor) =
         ($this =~ m{^.*?<a href.*?>(.*?)<.*?<td>(.*?)<.*?<td>(.*?)<.*$});

      # Remove leading . and put to lowercase
      $tld =~ s{^\.}{};
      $tld = lc($tld);

      push @cc, {
         tld => $tld,
         type => "\"$type\"",
         sponsor => "\"$sponsor\"",
      };
   }

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->append(0);
   $fc->overwrite(1);
   $fc->encoding('utf8');
   $fc->write_header(1);
   $fc->separator(',');
   $fc->header([qw(tld type sponsor)]);

   $fc->write(\@cc, $input) or return;

   return $input;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('load', $input) or return;
   $self->brik_help_run_file_not_found('load', $input) or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->encoding('utf8');
   $fc->first_line_is_header(1);
   $fc->separator(',');

   my $csv = $fc->read($input) or return;

   return $csv;
}

sub load_by_tld {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('load_by_tld', $input) or return;
   $self->brik_help_run_file_not_found('load_by_tld', $input) or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->encoding('utf8');
   $fc->first_line_is_header(1);
   $fc->separator(',');

   my $csv = $fc->read($input) or return;

   my %by_tld = ();
   for (@$csv) {
      $by_tld{$_->{tld}} = $_;
   }

   return \%by_tld;
}

sub from_tld {
   my $self = shift;
   my ($tld) = @_;

   $self->brik_help_run_undef_arg('from_tld', $tld) or return;

   my $data = $self->_load_by_tld or return;

   if (exists($data->{lc($tld)})) {
      return $data->{lc($tld)};
   }

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Countrycode - lookup::countrycode Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
