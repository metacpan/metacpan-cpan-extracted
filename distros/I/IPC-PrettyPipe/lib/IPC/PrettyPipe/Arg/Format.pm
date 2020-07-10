package IPC::PrettyPipe::Arg::Format;

# ABSTRACT: Encapsulate argument formatting attributes

use Types::Standard qw[ Str ];

use Moo;

our $VERSION = '0.13';

with 'IPC::PrettyPipe::Format';


shadowable_attrs( qw[ pfx sep ] );

use namespace::clean;





















has pfx => (
    is        => 'rw',
    isa       => Str,
    clearer   => 1,
    predicate => 1,
);













has sep => (
    is        => 'rw',
    isa       => Str,
    clearer   => 1,
    predicate => 1,
);









sub copy_into { $_[0]->_copy_attrs( $_[1], 'sep', 'pfx' ); }


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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory pfx sep

=head1 NAME

IPC::PrettyPipe::Arg::Format - Encapsulate argument formatting attributes

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  use IPC::PrettyPipe::Arg::Format;

  $fmt = IPC::PrettyPipe::Arg::Format->new( %attr );

=head1 DESCRIPTION

This class encapsulates argument formatting attributes

=head1 ATTRIBUTES

=head2 pfx

The prefix to apply to an argument

=head2 has_pfx

A predicate for the C<pfx> attribute.

=head2 sep

The string which will separate option names and values.  If C<undef> (the default),
option names and values will be treated as separate entities.

=head2 has_sep

A predicate for the C<sep> attribute.

=head1 METHODS

=head2 B<new>

  $fmt = IPC::PrettyPipe::Arg::Format->new( %attr );

The constructor.

=head2 copy_into

  $self->copy_into( $dest, @attrs );

Copy the C<sep> and C<pfx> attributes from the object to the destination object.

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
