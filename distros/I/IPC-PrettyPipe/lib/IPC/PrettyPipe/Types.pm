package IPC::PrettyPipe::Types;

# ABSTRACT: Types

use strict;
use warnings;

our $VERSION = '0.13';

use Type::Library
  -base,
  -declare => qw[
  Arg
  AutoArrayRef
  Cmd
  Pipe
];

use Type::Utils -all;
use Types::Standard -types;

use List::Util qw[ pairmap ];

declare AutoArrayRef, as ArrayRef;
coerce AutoArrayRef,
  from Any, via { [$_] };

class_type Pipe, { class => 'IPC::PrettyPipe' };
class_type Cmd,  { class => 'IPC::PrettyPipe::Cmd' };
class_type Arg,  { class => 'IPC::PrettyPipe::Arg' };


1;

#
# This file is part of IPC-PrettyPipe
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

IPC::PrettyPipe::Types - Types

=head1 VERSION

version 0.13

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-ipc-prettypipe@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-PrettyPipe

=head2 Source

Source is available at

  https://gitlab.com/djerius/ipc-prettypipe

and may be cloned from

  https://gitlab.com/djerius/ipc-prettypipe.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<IPC::PrettyPipe|IPC::PrettyPipe>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
