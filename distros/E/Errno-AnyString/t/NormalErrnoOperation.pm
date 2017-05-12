package NormalErrnoOperation;
use strict;
use warnings;

=head1 NAME

NormalErrnoOperation - capture normal $! operation

=head1 SYNOPSIS

  use Test::More;
  use NormalErrnoOperation;

  # Do something to $! that should leave its behavior unchanged
  # with respect to system error messages.
  interfere_with_magic($!);

  foreach my $normal (NormalErrnoOperation->new) {
      $normal->set;

      is $!+0, $normal->errno,  "\$! errno ok for ".$normal->errno;
      is "$!", $normal->errstr, "\$! errstr ok for ".$normal->errno;

      is $normal->flathash_now, $normal->normal_flathash,
            "%! ok for ".$normal->errno;

      ...
  }

=head1 DESCRIPTION

Samples the operation of C<$!>, allowing test code to later check that C<$!> is still working as expected. The behavior of C<$!> is sampled when this module is first loaded.

An object of class C<NormalErrnoOperation> encapsulates the expected behavior of C<$!> with respect to one particular error code.

=cut

use Errno;

our @_system_errors;
our $_flathash_none;
_init();

=head1 CONSTRUCTOR

=head2 new ()

Returns a single C<NormalErrnoOperation> object if called in a scalar context, or several (for different error codes) if called in a list context.

=cut

sub new {
    if (wantarray) {
        return @_system_errors;
    } else {
        return $_system_errors[0];
    }
}

sub _init {
    my @errorno_setters = (
        sub { open my $fh, "<", "osaudf080s8f0sa8fasf" and die "open failed to fail"; },
        sub { open my $fh, ">", "/oaudf080s8f0sa8fasf" and die "open failed to fail"; },
        sub {
            local $SIG{__WARN__} = sub {};
            setsockopt(3,3,3,3) and die "setsockopt failed to fail";
        },
        sub { local $SIG{__WARN__} = sub {}; $! = "9999 is the error code" }, # normal $! will see 9999.
        sub { local $SIG{__WARN__} = sub {}; $! = "this is the error code" }, # normal $! will see 0.
        sub { $! = 3148753 },
    );

    my %had_errno;
    foreach my $setter (@errorno_setters) {
        eval { $setter->() };
      next if $@;
        my $errno = 0+$!;
        my $errstr = "$!";
        my ($symbol) = grep { $!{$_} } keys(%!);
        my $flathash = join ",", map {"$_=$!{$_}"} sort keys(%!);
      next if $had_errno{$errno}++;
        push @_system_errors, bless {
            Setter   => $setter,
            Errno    => $errno,
            Errstr   => $errstr,
            Symbol   => $symbol,
            FlatHash => $flathash,
        };
    }

    $_flathash_none = $_system_errors[-1]{FlatHash};
}

=head1 METHODS

=head2 set ()

Sets C<$!> to this error.

=cut

sub set {
    my $self = shift;

    $self->{Setter}();
}

=head2 errno ()

Returns the error number for this error.

=cut

sub errno {
    my $self = shift;

    return $self->{Errno};
}

=head2 errstr ()

Returns the error string for this error.

=cut

sub errstr {
    my $self = shift;

    return $self->{Errstr};
}

=head2 symbol ()

Returns a string holding the L<Errno> symbol for this error (C<ENOENT>, etc) if there is one, otherwise returns false.

=cut

sub symbol {
    my $self = shift;

    return $self->{Symbol};
}

=head2 normal_flathash ()

Returns a snapshot of C<%!> with this error set, flattened into a string.

=cut

sub normal_flathash {
    my $self = shift;

    return $self->{FlatHash};
}

=head2 flathash_now ()

Returns the current contents of C<%!> flattened into a string, in the same way that C<%!> was flattened when the normal_flathash() value was sampled.

Can be called as a class method.

=cut

sub flathash_now {
    return join ",", map {"$_=$!{$_}"} sort keys(%!);
}

=head2 flathash_none ()

Returns saved contents of C<%!> flattened into a string, sampled when C<$!> was not set to any error for which L<Errno> has a symbol.

Can be called as a class method.

=cut

sub flathash_none {
    return $_flathash_none;
}

1;

