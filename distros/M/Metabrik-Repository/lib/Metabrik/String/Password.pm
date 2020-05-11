#
# $Id$
#
# string::password Brik
#
package Metabrik::String::Password;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable random) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         charset => [ qw($character_list) ],
         length => [ qw(integer) ],
         count => [ qw(integer) ],
      },
      attributes_default => {
         charset => [ 'A'..'K', 'M'..'Z', 'a'..'k', 'm'..'z', 2..9, '_', '-', '#', '!' ],
         length => 10,
         count => 5,
      },
      commands => {
         generate => [ qw(length|OPTIONAL count|OPTIONAL) ],
         prompt => [ qw(string|OPTIONAL) ],
      },
      require_modules => {
         'String::Random' => [ ],
         'Term::ReadPassword' => [ ],
      },
   };
}

sub generate {
   my $self = shift;
   my ($length, $count) = @_;

   $length ||= $self->length;
   $count ||= $self->count;

   my $charset = $self->charset;

   my $rand = String::Random->new;
   $rand->{A} = $charset;

   my @passwords = ();
   for (1..$count) {
      push @passwords, $rand->randpattern("A"x$length);
   }

   return \@passwords;
}

sub prompt {
   my $self = shift;
   my ($string) = @_;

   $string ||= 'Password: ';

   my $password;
   while (1) {
      my $this = Term::ReadPassword::read_password($string);
      if (defined($this)) {
         $password = $this;
         last;
      }
   }

   return $password;
}

1;

__END__

=head1 NAME

Metabrik::String::Password - string::password Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
