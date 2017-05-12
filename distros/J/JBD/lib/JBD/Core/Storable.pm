package JBD::Core::Storable;
# ABSTRACT: abstraction around retrieve/nstore
our $VERSION = '0.04'; # VERSION

#/ A JBD::Core::Storable object provides two methods:
#/ - load(), which takes a callback sub, attempts to retrieve
#/   the object's Storable data, or falls back to the returned
#/   returned value from $callback, which, if called, gets saved
#/   into the object's Storable file.
#/ - erase() removes the object's Storable file.

use JBD::Core::stern;
use Storable qw(retrieve nstore);

sub FILE {0}
sub MTIM {1}
sub OPTS {2}
sub STOR {3}


#////////////////////////////////////////////////////////////////
#/ Object Interface /////////////////////////////////////////////

#/ @param string $type    object type
#/ @param string $file    full path to Storable file
#/ @param hashref [optional] $opts    options
#/     ttl  => a time-to-live, for $file
#/     mode => file mode, for chmod(), e.g., 0777
#/     call => callback sub, which is used to load data
#/             if the data is not found in $file
#/ @return JBD::Core::Storable    blessed arrayref
sub new {
    die 'File required' if @_ < 2;
    my ($type, $file, $opts) = (shift, shift, shift || {});
    my $stat = -e $file ? (stat $file)[9] : 0;
    bless [$file, $stat, $opts, undef], $type;
}

#/ @param JBD::Core::Storable $this
#/ @return mixed    data from Storable file / callback sub
sub load {
    my $this = shift;

    my $file = $this->[FILE];
    my $store = $this->[STOR];

    defined $store or eval {
        #/ file too old?
        my $ttl = $this->[OPTS]{ttl};
        return if $ttl && time - $this->[MTIM] > $ttl;
        
        #/ try retrieve()
        $store = retrieve $file;
    };

    defined $store or do {
        my $callback = $this->[OPTS]{call};
        die 'Missing callback' unless ref $callback eq 'CODE';

        #/ try callback()
        $store = $callback->();
        ref $store or die 'Invalid callback return';

        #/ save to Storable file
        $this->save($store);

        #/ chmod() Storable file?
        my $mode = $this->[OPTS]{mode};
        defined $mode and chmod $mode, $file or die $!;
    };

    $store;
}

#/ Save given data to Storable file.
#/ @param JBD::Core::Storable $this
#/ @param scalar [optional] $ref    data to save: default $this->[STOR]
sub save {
    my $this = shift;
    my $ref = shift || $this->[STOR];
    nstore $ref, $this->[FILE] or die $!;
}

#/ Remove object's Storable file.
#/ @param JBD::Core::Storable $this
sub erase {
    my $this = shift;
    return unless -e $this->[FILE];
    unlink $this->[FILE] or die $!;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Core::Storable - abstraction around retrieve/nstore

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
