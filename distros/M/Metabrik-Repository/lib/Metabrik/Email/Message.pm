#
# $Id: Message.pm,v 246044148483 2017/03/18 14:13:18 gomor $
#
# email::message Brik
#
package Metabrik::Email::Message;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 246044148483 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
         subject => [ qw(subject|OPTIONAL) ],
         from => [ qw(from|OPTIONAL) ],
         to => [ qw(to|OPTIONAL) ],
      },
      attributes_default => {
         from => 'from@example.com',
         to => 'to@example.com',
         subject => 'Example.com subject',
      },
      commands => {
         create => [ qw(content) ],
         parse => [ qw(string) ],
         save_attachments => [ qw(string) ],
      },
      require_modules => {
         'Metabrik::System::File' => [ ],
         'Metabrik::File::Base64' => [ ],
         'Email::Simple' => [ ],
         'Email::MIME' => [ ],
      },
   };
}

sub create {
   my $self = shift;
   my ($content) = @_;

   $self->brik_help_run_undef_arg('create', $content) or return;

   my $from = $self->from;
   my $to = $self->to;
   my $subject = $self->subject;

   my $email = Email::Simple->create(
      header => [
         From => $from,
         To => $to,
         Subject => $subject,
      ],
      body => $content,
   );

   return $email;
}

sub parse {
   my $self = shift;
   my ($message) = @_;

   $self->brik_help_run_undef_arg('parse', $message) or return;

   my $parsed = Email::MIME->new($message);
   if (! defined($parsed)) {
      return $self->log->error("parse: MIME failed for message");
   }

   my $simple = Email::Simple->new($message);

   my @headers = $simple->headers;
   my %header = ();
   for my $this (@headers) {
      my @values = $simple->header($this);
      if (@values == 1) {
         $header{$this} = $values[0];
      }
      else {
         $header{$this} = \@values;
      }
   }

   my @list = ();
   push @list, \%header;

   my @parts = $parsed->parts;
   for (@parts) {
      my $this = { %$_ };  # unbless it.

      my $filename = $_->filename;
      my $file_content = $_->body_raw;
      if (defined($filename) && defined($file_content)) {
         $this->{filename} = $filename;
         $file_content =~ s{[\r\n]*$}{};
         $this->{file_content} = $file_content;
      }

      if (exists($this->{header}) && exists($this->{header}{headers})) {
         my $headers = $this->{header}{headers};
         my $new_headers = {};
         my $name;
         my $value;
         for (@$headers) {
            if (ref($_) eq '') { # This is a name
               $name = $_;
            }
            elsif (ref($_) eq 'ARRAY') {  # This is a value
               $value = $_->[0];  # 0: has the header value, 1 has the header + value
            }
            if (defined($name) && defined($value)) {
               $new_headers->{$name} = $value;
               $name = undef;
               $value = undef;
            }
         }
         $this->{header} = $new_headers;
      }
      push @list, $this;
   }

   return \@list;
}

sub save_attachments {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('parse', $string) or return;

   my $datadir = $self->datadir;
   my $message = $self->parse($string) or return;
   my $headers = $message->[0];

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   my $fb = Metabrik::File::Base64->new_from_brik_init($self) or return;

   my @files = ();
   for my $part (@$message) {
      if (exists($part->{filename}) && length($part->{filename})) {
         my $from = $headers->{From};
         my $to = $headers->{To};
         my $subject = $headers->{Subject};
         my $filename = $sf->basefile($part->{filename});
         $filename =~ s{\s+}{_}g; # I hate spaces in filenames.
         my $output = $fb->decode_from_string(
            $part->{file_content}, $datadir."/$filename"
         );
         push @files, {
            headers => $headers,
            file => $output,
         };
      }
   }

   return \@files;
}

1;

__END__

=head1 NAME

Metabrik::Email::Message - email::message Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
