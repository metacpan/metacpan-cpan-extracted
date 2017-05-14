package IO::BindHandles;
# ABSTRACT: Bind a set of handles for buffered tunneling

use strict;
use warnings;
use IO::Handle;
use IO::Select;

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my %options = @_;

    my $timeout = 0.5;
    $timeout = $options{timeout} if exists $options{timeout};
    $timeout += 0 if defined $timeout;

    my $handles = $options{handles};
    die "handles must be an ARRAY ref" if ref $handles ne 'ARRAY';
    warn "odd number of handles in BindHandles" if scalar(@$handles) & 1;

    my @all_handles;
    for (my $i = 0; $i < scalar @$handles; $i += 2) {
        my $read = $handles->[$i];
        my $write = $handles->[$i+1];
        $read->autoflush(1);
        $write->autoflush(1);
        my $buffer = '';
        push @all_handles, [ $read, $write, $buffer ];
    }

    my $self = {
                timeout => $timeout,
                handles => \@all_handles,
               };

    bless $self, $class;
    return $self;
}


sub loop {
    my $self = shift;
    $self->timeout(0.1) if defined $self->timeout && $self->timeout == 0;
    #warn "In loop...";
    while ($self->bound()) {
        #warn "rwcycle...";
        $self->rwcycle();
    }
    #warn "Out loop...";
}


sub bound {
    my $self = shift;
    #warn "in bound...";
    my @list =
      grep {
          (
           $_->[0]->opened && $_->[1]->opened &&
           !$_->[0]->error && !$_->[1]->error
          )
            ||
              ( $_->[2] && $_->[1]->opened && !$_->[1]->error )
          } @{$self->{handles}};
    #warn "out bound...";
    return
      scalar @list;
}


sub rwcycle {
    my $self = shift;
    use bytes;
    #warn "in rwcycle...";

    # we listen on all handles all the time for reading...
    my @read_handles = grep { $_->opened && !$_->error }
      map { $_->[0] }
        grep { $_->[1]->opened && !$_->[1]->error }
          @{$self->{handles}};
    #warn "Selecting read on ".join ', ', @read_handles;
    my $read_select = IO::Select->new(@read_handles);


    # but we only listen for writing on those that we have
    # something to write to.
    my @write_handles = grep { $_->opened && !$_->error }
      map { $_->[1] }
        grep { $_->[2] } @{$self->{handles}};
    #warn "Selecting write on ".join ', ', @write_handles;
    my $write_select = IO::Select->new(@write_handles);


    # we check for exception in all handles;
    my @except_handles = (@read_handles, @write_handles);
    #warn "Selecting exception on ".join ', ', @except_handles;
    my $except_select = IO::Select->new(@except_handles);


    # now let's see if there's something to be read or written
    #warn "Select...";
    my ($r_r, $r_w, $e) = IO::Select::select($read_select, $write_select, $except_select, $self->timeout);
    #warn "done...";

    if ($r_r && scalar @$r_r) {
        foreach my $h (@$r_r) {
            my ($h_desc) = grep { $_->[0] eq $h } @{$self->{handles}};
            my $handle = $h_desc->[0];
            my $temp_buf;
            #warn "Reading from $handle.";
            my $num_read = $handle->sysread($temp_buf, 1024);
            if (defined $num_read && $num_read > 0) {
                #warn "Read $num_read";
                $h_desc->[2] .= substr($temp_buf, 0, $num_read);
            } else {
                #warn "Error...";
                $handle->close;
                $h_desc->[3] = 1;
                $h_desc->[1]->close unless $h_desc->[2];
            }
        }
    }

    if ($r_w && scalar @$r_w) {
        foreach my $h (@$r_w) {
            my ($h_desc) = grep { $_->[1] eq $h } @{$self->{handles}};
            my $handle = $h_desc->[1];
            #warn "Writing on $handle.";
            my $num_write = $handle->syswrite($h_desc->[2], length($h_desc->[2]));
            if (defined $num_write && $num_write >= 0) {
                #warn "Wrote $num_write.";
                substr($h_desc->[2],0,$num_write,'');
            } else {
                #warn "Error.";
                $handle->close;
                $h_desc->[0]->close;
            }
        }
    }
    if ($e && scalar @$e) {
        foreach my $h (@$r_w) {
            #warn "Exception in $h";
            my ($h_desc) = grep { $_->[1] eq $h || $_->[0] eq $h } @{$self->{handles}};
            # we close the writing handles unless the
            # exception was in the reading handle and there
            # is still buffered content to be sent.
            unless ($h eq $h_desc->[0] && $h_desc->[2]) {
                $h_desc->[1]->close;
            }
            # in any case we won't read anymore
            $h_desc->[0]->close;
        }
    }

    foreach my $h (@{$self->{handles}}) {
        if (exists $h->[3] && $h->[3] && !$h->[2]) {
            $h->[1]->close()
              unless grep { $_->[0] eq $h->[1] } @{$self->{handles}}
                ;
        }
    }

}


sub timeout {
    my $self = shift;
    my $ret = $self->{timeout};
    $self->{timeout} = shift if @_;
    return $ret;
}


1;

__END__

=pod

=head1 NAME

IO::BindHandles - Bind a set of handles for buffered tunneling

=head1 VERSION

version 0.006

=head1 SYNOPSIS

Simple usage:

  use IO::BindHandles;
  # connect $r1 to $w1 and $r2 to $w2
  my $bh = IO::BindHandles->new(
    handles => [
      $r1, $w1, # read from $r1, write to $w1
      $r2, $w2, # read from $r2, write to $r2
    ]
  );
  
  # block until the handles close themselves
  $bh->loop;

More complex scenario with non-blocking calls

  # connect STDIN and STDOUT to a socket in non-blocking way
  $socket->blocking(0);
  STDIN->blocking(0);
  STDOUT->blocking(0);
  my $bh = IO::BindHandles->new(
    timeout => 0, # non-blocking
    handles => [
      *STDIN, $socket,  # read from STDIN, write to socket
      $socket, *STDOUT, # read from socket, write to STDOUT
    ]
  );
  
  # do it in an explicit unblocking loop
  while (1) {
    $bh->rwcycle;
    # do something else that takes some time
    my $cond = do_something_else();
    # you can check if the bind is still valid
    last if $cond && $bh->bound;
  }

=head1 DESCRIPTION

This module implements a buffered tunneling between a set of arbitrary
IO handles. It basically implements a select loop on a set of handles,
reading and writing from them using an internal buffer.

This replicates what a dup or fdopen call would do when you can't
actually do it, i.e.: attach STDIN/STDOUT to a socket or attach two
different sockets toguether.

This module doesn't perform any low-level operation on the handles, so
it should support any IO::Handle that is supported by IO::Select.

=head1 METHODS

=head2 new(timeout => $val, handles => [ $h1, $h2 ])

Initializes a new BindHandles instance. The timeout value defaults to
0.5. The handles argument receives an arrayref with pairs of handles.
Each pair represents a binding between a read and a write handle.

You can pass as many handle pairs as you want, and you can even use
the same handle for a read and a write role. But you should not use
the same handle for more then one read or one write operation.

Future versions of this module might support "read one write many",
"read many write one" or even "read many write many". Contact me if
you think this features are important and I might even implement it.

This method will call autoflush(1) on all handles.

=head2 loop()

Blocking loop to consume all read handles and write the data to their
bound handles until they are no longer bound, i.e.: when the remote
socket is closed.

In order to avoid consuming all the CPU, this method will override the
timeout configuration to 0.1 if it is set to 0.

=head2 bound()

Checks if there are still bound handles. It will return false when no
more write handles are open or when read handles close without any
write buffer left. This can be used as a "while" condition.

It returns the number of valid bindings.

=head2 rwcycle()

Selects handles ready to read, write or with exceptions and act
accordingly. The select might block according to the configured
timeout value.

This method will close handles in the following situations:

=over

=item

When a read operation returns undef or 0 it will close the read
handle. It will also close the write handle if there are no contents
in the related write buffer.

=item

When a write operation returns undef or 0 it will close both the read
and write handle.

=item

When an exception is detected in one handle, it will close it. It will
also close the bound handle unless the exception hapenned in the read
handle and there are contents in the write buffer.

=back

=head2 timeout

Accessor for the timeout value.

=head1 BUGS

Please submit all bugs regarding IO::BindHandles to bug-io-bindhandles@rt.cpan.org

=head1 AUTHOR

Daniel Ruoso <daniel@ruoso.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Daniel Ruoso.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
