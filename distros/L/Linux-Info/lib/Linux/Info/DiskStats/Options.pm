package Linux::Info::DiskStats::Options;
use warnings;
use strict;
use Hash::Util qw(lock_keys);
use Carp       qw(confess);
use parent 'Class::Accessor';

use Regexp::Common 2017060201;
use Set::Tiny 0.04;

use Linux::Info::KernelRelease;

our $VERSION = '2.0'; # VERSION

my @_attribs = (
    'init_file',            'source_file',
    'backwards_compatible', 'global_block_size',
    'block_sizes',          'current_kernel'
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(@_attribs);

=head1 NAME

Linux::Info::DiskStats::Options - Configuration for Linux::Info::DiskStats instances.

=head1 SYNOPSIS

    $opts = Linux::Info::DiskStats::Options->new({
        backwards_compatible => 1,
        source_file          => '/tmp/foobar.txt',
        init_file            => '/tmp/diskstats.yml',
        global_block_size    => 4096,
        current_kernel       => '2.6.18-0-generic',
    })

=head1 DESCRIPTION

Configuration for L<Linux::Info::DiskStats> can get so complex that is worth
creating a class to describe and validate it.

The good news is that a instance of C<Linux::Info::DiskStats::Options> doesn't
need to be that complex in every situation. But you will be glad to get
validations in place anyway.

=head1 METHODS

=head2 new

The optional keys:

=over

=item *

C<backwards_compatible>: if true (1), the returned statistics will be those
provided by backwards compatibility. Also, it defines that block size
information is required.

If false (0), the new set of fields will be available.

Defaults to true.

=item *

C<source_file>: if provided, that will be the source file were the statistics
will be read from. Otherwise, the default location (based on Linux kernel
version) will be used instead. It is basically used to enable unit testing.

=item *

C<init_file>: if set, you may to store/load the initial statistics to/from a
file:

    my $lxs = Linux::Info::DiskStats->new({init_file => '/tmp/diskstats.yml'});

If you set C<init_file> it's not necessary to call C<sleep> before C<get>.

=item *

C<global_block_size>: with an integer as the value, all attached disks will
have calculated statistics based on this value. You may use this if all the
disks are using the same file system type.

It is checked only if C<backwards_compatible> is true.

=item *

C<block_sizes>: if there are different file systems mounted, you will need
to resort to a more complex configuration setting:

    my $opts_ref = {
        block_sizes => {
            deviceA => 512,
            deviceB => 4096,
        }
    };

It is checked only if C<backwards_compatible> is true.

=back

Regarding block sizes, you must choose one key or the other if
C<backwards_compatible> is true. If both are absent, instances will C<die>
during creation by invoking C<new>.

=cut

sub new {
    my ( $class, $opts_ref ) = @_;
    my $self = {
        global_block_size => undef,
        block_sizes       => undef,
        source_file       => undef,
        init_file         => undef,
        current_kernel    => undef,
    };

    if ( defined($opts_ref) ) {
        confess 'The options reference must be a hash reference'
          unless ( ref $opts_ref eq 'HASH' );
    }

    my $valid_keys = Set::Tiny->new(@_attribs);

    foreach my $key ( keys %{$opts_ref} ) {
        confess "The key $key in the hash reference is not valid"
          unless ( $valid_keys->has($key) );
    }

    if ( ( exists $opts_ref->{backwards_compatible} )
        and defined( $opts_ref->{backwards_compatible} ) )
    {
        $self->{backwards_compatible} = $opts_ref->{backwards_compatible};
    }
    else {
        $self->{backwards_compatible} = 1;
    }

    if ( $self->{backwards_compatible} ) {
        confess
'Must setup global_block_size or block_sizes unless backwards_compatible is disabled'
          unless ( ( exists $opts_ref->{global_block_size} )
            or ( exists $opts_ref->{block_sizes} ) );

        my $int_regex = qr/^$RE{num}->{int}$/;

        if ( exists $opts_ref->{global_block_size} ) {
            confess 'global_block_size must have an integer as value'
              unless ( ( defined( $opts_ref->{global_block_size} ) )
                and ( $opts_ref->{global_block_size} =~ $int_regex ) );

            $self->{global_block_size} = $opts_ref->{global_block_size};
        }

        if ( exists $opts_ref->{block_sizes} ) {
            confess 'block_sizes must be a hash reference'
              unless ( ( defined $opts_ref->{block_sizes} )
                and ( ref $opts_ref->{block_sizes} eq 'HASH' ) );

            confess 'block_sizes must have at least one disk'
              unless ( ( scalar( keys %{ $opts_ref->{block_sizes} } ) ) > 0 );

            foreach my $disk ( keys %{ $opts_ref->{block_sizes} } ) {
                confess 'block size must be an integer'
                  unless ( $opts_ref->{block_sizes}->{$disk} =~ $int_regex );
                $opts_ref->{block_sizes}->{$disk} =
                  $opts_ref->{block_sizes}->{$disk};
            }
        }

    }

    my @files_to_test = qw(init_file source_file);

    foreach my $source_file (@files_to_test) {
        if (    ( exists $opts_ref->{$source_file} )
            and ( defined $opts_ref->{$source_file} ) )
        {
            confess 'the source file '
              . $opts_ref->{$source_file}
              . ' does not exist'
              unless ( -r $opts_ref->{$source_file} );

            $self->{$source_file} = $opts_ref->{$source_file};
        }
    }

    if (    ( exists $opts_ref->{current_kernel} )
        and ( defined $opts_ref->{current_kernel} ) )
    {
        $self->{current_kernel} =
          Linux::Info::KernelRelease->new( $opts_ref->{current_kernel} );
    }

    bless $self, $class;
    lock_keys( %{$self} );
    return $self;
}

=head2 get_init_file

Getter for the C<init_file> attribute.

It will return C<undef> if the property wasn't defined.

=head2 get_source_file

Getter for the C<source_file> attribute.

It will return C<undef> if the property wasn't defined.

=head2 get_backwards_compatible

Getter for the C<backwards_compatible> attribute.

It will return C<undef> if the property wasn't defined.

=head2 get_block_sizes

Getter for the C<block_sizes> attribute.

It will return C<undef> if the property wasn't defined.

=head2 get_global_block_size

Getter for the C<global_block_size> attribute.

It will return C<undef> if the property wasn't defined.

=head2 get_current_kernel

Getter for the C<current_kernel> attribute.

It will return C<undef> if the property wasn't defined.

=cut

=head1 SEE ALSO

=over

=item *

L<Linux::Info::DiskStats>

=item *

L<Linux::Info::KernelRelease>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
E<lt>glasswalk3r@yahoo.com.brE<gt>

This file is part of Linux Info project.

Linux-Info is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Linux-Info is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Linux Info. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
