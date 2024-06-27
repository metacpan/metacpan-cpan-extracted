package Linux::Info::SysInfo::CPU;
use strict;
use warnings;
use Carp       qw(confess);
use Hash::Util qw(lock_keys);
use Set::Tiny 0.04;
use Class::XSAccessor getters => {
    get_arch        => 'architecture',
    get_model       => 'model',
    get_bogomips    => 'bogomips',
    get_vendor      => 'vendor',
    get_source_file => 'source_file',
};

our $VERSION = '2.19'; # VERSION

# ABSTRACT: Collects CPU information from /proc/cpuinfo


my $override_error = 'This method must be overrided by subclasses';

sub _set_proc_bits {
    confess $override_error;
}

sub _set_hyperthread {
    confess $override_error;
}

sub _parse {
    confess $override_error;
}


sub processor_regex {
    confess $override_error;
}

sub _custom_attribs {
    confess $override_error;
}


sub get_cores {
    confess $override_error;
}


sub get_threads {
    confess $override_error;
}

sub _parse_list {
    return ( split( /\s+:\s/, shift->{line} ) )[1];
}

sub _parse_flags {
    my ( $self, $line ) = @_;
    $self->{line} = $line;
    my $value = $self->_parse_list;
    $self->{flags}->insert( split( /\s/, $value ) );
    $self->{line} = undef;
}


sub has_flag {
    my ( $self, $flag ) = @_;

    # Set::Tiny uses 1 for truth, undef for false
    return 0 if ( $self->{flags}->is_empty );
    return 1 if ( $self->{flags}->has($flag) );
    return 0;
}


sub get_flags {
    my @flags = sort( shift->{flags}->members );
    return \@flags;
}


sub new {
    my ( $class, $source_file ) = @_;
    my $self = {
        model        => undef,
        processors   => 0,
        flags        => Set::Tiny->new,
        architecture => undef,
        bogomips     => 0,
        vendor       => undef,
    };
    $source_file = '/proc/cpuinfo'
      unless ( ( defined($source_file) ) and ( $source_file ne '' ) );

    confess "The file $source_file is not available for reading"
      unless ( -r $source_file );

    $self->{source_file} = $source_file;
    bless $self, $class;
    $self->_custom_attribs;
    $self->_parse;
    $self->_set_hyperthread;
    $self->_set_proc_bits;
    delete $self->{line};
    lock_keys( %{$self} );
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::SysInfo::CPU - Collects CPU information from /proc/cpuinfo

=head1 VERSION

version 2.19

=head2 SYNOPSIS

Don't create a instance of this class, you will be able to do it only with
subclasses from it.

See L<Linux::Info::SysInfo> methods to retrieve a instance of subclass from
the default L</proc/cpuinfo> file.

=head2 DESCRIPTION

This class provides an abstraction of general attributes a processor used by
Linux has.

It also defines an expected interface for subclasses, with methods that need
to be override in order to avoid an error with L<Carp> C<confess>.

=head1 METHODS

=head2 processor_regex

Returns a regular expression that identifies the processor that is being read.

This is used to identify which subclasses will be required to parse the file
content.

=head2 get_cores

Returns an integer with the number of cores available in the processor.

=head2 get_threads

Returns an integer with the number of hyper threads available in the processor.

=head2 has_flag

Expects as parameter a string with the name of the flag.

Return "true" (1) or "false" (0) if the processor has that specific flag
associated.

=head2 get_flags

Returns all flags related to the processor as a array reference.

=head2 new

Creates and return a new instance of this class.

Expects as parameter a single string as the path to an alternate file instead
of using the default F</proc/cpuinfo>. This is must useful for unit testing and
is not required.

=head2 get_arch

Returns a integer representing if the process is 32 or 64 bits.

=head2 get_bogomips

Returns a decimal number representing the bogomips of the processor.

=head2 get_model

Returns a string with the CPU model.

=head2 get_source_file

Returns the actual location of the cpuinfo read to create a instance of this
class.

=head2 get_vendor

Returns a string of the processor vendor.

=head1 SEE ALSO

=over

=item *

L<Linux::Info::SysInfo>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
