#
# $Id: Psv.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# string::psv Brik
#
package Metabrik::String::Psv;
use strict;
use warnings;

use base qw(Metabrik::String::Csv);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         first_line_is_header => [ qw(0|1) ],
         separator => [ qw(character) ],
         header => [ qw($column_header_list) ],
         encoding => [ qw(utf8|ascii) ],
      },
      attributes_default => {
         first_line_is_header => 0,
         header => [ ],
         separator => '|',
         encoding => 'utf8',
      },
      commands => {
         encode => [ qw($data) ],
         decode => [ qw($data) ],
      },
   };
}

1;

__END__

=head1 NAME

Metabrik::String::Psv - string::psv Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
