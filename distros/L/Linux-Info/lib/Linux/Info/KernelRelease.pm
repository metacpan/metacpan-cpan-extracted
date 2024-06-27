package Linux::Info::KernelRelease;
use strict;
use warnings;
use Carp qw(confess carp);
use Set::Tiny 0.04;
use Linux::Info::KernelSource;
use Class::XSAccessor getters => {
    get_raw            => 'raw',
    get_major          => 'major',
    get_minor          => 'minor',
    get_patch          => 'patch',
    get_compiled_by    => 'compiled_by',
    get_gcc_version    => 'gcc_version',
    get_type           => 'type',
    get_build_datetime => 'build_datetime',
};

our $VERSION = '2.19'; # VERSION

# ABSTRACT: parses and provide Linux kernel detailed information


sub _set_proc_ver_regex {
    my $self = shift;
    $self->{proc_regex} = undef;
}

sub _parse_proc_ver {
    my $self = shift;
    my $line;

    if ( defined $self->{raw} ) {
        $line = $self->{raw};
    }
    elsif ( defined $self->{source} ) {
        $line = $self->{source}->get_version;
        $self->{raw} = $line;
    }
    else {
        confess 'Inconsistent object state: no raw string or source to use';
    }

    if ( $line =~ $self->{proc_regex} ) {

        my @required = qw(compiled_by gcc_version build_datetime version);

        foreach my $key (@required) {
            confess "Missing '$key' in the regex match groups"
              unless ( exists $+{$key} );
        }

        map { $self->{$_} = $+{$_} } ( keys %+ );
    }
    else {
        confess(
            "Failed to match '$line' against '" . $self->{proc_regex} . '\'' );
    }
}

# regex must be relaxed because distros can put anything after the first three
# digits
my $version_regex = qr/^(\d+)\.(\d+)\.(\d+)/;

sub _parse_version {
    my ( $self, $raw ) = @_;
    $raw =~ $version_regex;
    $self->{major} = $1 + 0;
    $self->{minor} = $2 + 0;
    $self->{patch} = $3 + 0;
}


sub new {
    my ( $class, $release, $source ) = @_;
    my $self = {};
    bless $self, $class;

    if ( defined($release) ) {
        confess "The string for release '$release' is invalid"
          unless ( $release =~ $version_regex );
        $self->{raw} = $release;
        $self->_parse_version($release);
        $self->{source} = undef;
    }
    else {
        my $source_class = 'Linux::Info::KernelSource';
        if ( defined($source) ) {
            confess "Must receive a instance of $source_class"
              unless ( ( ref $source ne '' )
                and ( $source->isa($source_class) ) );
        }
        else {
            $source = $source_class->new;
        }

        $self->{source} = $source;
        $self->_set_proc_ver_regex;

        if ( defined( $self->{proc_regex} ) ) {
            $self->_parse_proc_ver;
        }

        $self->_parse_version( $self->{source}->get_sys_osrelease );
    }

    return $self;
}


sub _validate_other {
    my ( $self, $other ) = @_;
    my $class     = ref $self;
    my $other_ref = ref $other;

    confess 'The other parameter must be a reference' if ( $other_ref eq '' );
    confess 'The other instance must be a instance of'
      . $class
      . ', not '
      . $other_ref
      unless ( $other->isa($class) );
}

sub _ge_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 1 if ( $self->{major} > $other->get_major );
    return 0 if ( $self->{major} < $other->get_major );
    return 1 if ( $self->{minor} > $other->get_minor );
    return 0 if ( $self->{minor} < $other->get_minor );
    return 1 if ( $self->{patch} > $other->get_patch );
    return 0 if ( $self->{patch} < $other->get_patch );
    return 1;
}

sub _gt_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 1 if ( $self->{major} > $other->get_major );
    return 0 if ( $self->{major} < $other->get_major );
    return 1 if ( $self->{minor} > $other->get_minor );
    return 0 if ( $self->{minor} < $other->get_minor );
    return 1 if ( $self->{patch} > $other->get_patch );
    return 0 if ( $self->{patch} < $other->get_patch );
    return 0;
}

sub _lt_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 0 if ( $self->{major} > $other->get_major );
    return 1 if ( $self->{major} < $other->get_major );
    return 0 if ( $self->{minor} > $other->get_minor );
    return 1 if ( $self->{minor} < $other->get_minor );
    return 0 if ( $self->{patch} > $other->get_patch );
    return 1 if ( $self->{patch} < $other->get_patch );
    return 0;
}

use overload
  '>=' => '_ge_version',
  '>'  => '_gt_version',
  '<'  => '_lt_version';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::KernelRelease - parses and provide Linux kernel detailed information

=head1 VERSION

version 2.19

=head1 SYNOPSIS

Getting the current kernel information:

    my $current = Linux::Info::KernelRelease->new;

Or using L<Linux::Info::SysInfo> syntax sugar to achieve the same result:

    my $sys = Linux::Info::SysInfo->new;
    my $current = $sys->get_detailed_kernel;

Or using a given Linux kernel release string:

    my $kernel = Linux::Info::KernelRelease->new('2.4.20-0-generic');

Now you can compare the version of both of them:

    say 'Kernel was upgraded!' if ($current > $kernel);

=head1 DESCRIPTION

This module parses the Linux kernel information obtained from sources like the
C<uname> command and others.

This make it easier to fetch each piece of information from a string and also
to compare different kernels (C<KernelRelease> sub classes) versions, since sub
classes of this class will overload operators like ">=", ">" and "<".

=head1 METHODS

=head2 new

Creates a new instance.

Optionally, it might receive the following arguments:

=over

=item 1.

A string as parameter like the kernel release information from
F</proc/sys/kernel/osrelease>.

=item 2.

A instance of L<Linux::Info::KernelSource>.

=back

The string, if defined, will always have preference to setup the version based
on it and the instance passed will be ignored.

If you want to use L<Linux::Info::KernelSource>, be sure to pass C<undef> as
the first argument.

If none arguments are passed, a new instance of L<Linux::Info::KernelSource>
will be created, and the default locations of files to parsed will be used.

This method will also invoke the C<_set_proc_ver_regex> method, used to
parse the string at F</proc/version>. Subclasses must override this method,
since this class won't know how to do it.

=head2 get_raw

Returns the raw information stored, as read from F</proc/sys/kernel/osrelease>
or passed to the C<new> method.

=head2 get_major

Returns from the version, returns the integer corresponding to the major number.

=head2 get_minor

Returns from the version, returns the integer corresponding to the minor number.

=head2 get_patch

From the version, returns the integer corresponding to the patch number.

=head2 get_build_datetime

Returns a string representing when the kernel was built, or C<undef> if not
possible to parse it.

=head2 get_compiled_by

Returns a string, representing the user who compiled the kernel, or C<undef> if
not possible to parse it.

=head2 get_gcc_version

Returns a string, representing gcc compiler version used to compile the kernel,
or C<undef> if not possible to parse it.

=head2 get_type

Returns a string, representing the features which define the kernel type, or
C<undef> if not possible to parse it.

=head1 SEE ALSO

=over

=item *

https://www.unixtutorial.org/use-proc-version-to-identify-your-linux-release/

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
