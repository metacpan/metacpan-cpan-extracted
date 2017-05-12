package IO::Socket::ByteCounter;

use base 'IO::Socket';

use strict;
# use warnings;

use version;our $VERSION = qv('0.0.2');

sub import {
    shift->record_bytes(@_) if @_;
}

sub record_bytes {
	my ($self, @pkgs)     =  @_;

    for my $pkg (@pkgs) {
        $pkg = ref $pkg if ref $pkg;
        
        my $inc = $pkg;
        $inc =~ s{::}{/}g;
        if(!exists $INC{$inc . '.pm'}) {
            eval "use $pkg;";
            warn $@ if $@;
            next if $@;
        }
         
        no strict;
        next if ${ "$pkg\::io_socket_bytecounter_on" };
        
        eval <<"OVERRIDE_END";
            \$$pkg\::io_socket_bytecounter_on = 1;
           
            #### IO::Socket methods ##
            # IO::Socket::send   
            my \$send = \\&$pkg\::send;
            \*$pkg\::send = sub {
                my \$self = \$_[0];
                \${\*\$self}{'io_socket_bytecounter_out'} += IO::Socket::ByteCounter->_get_byte_size(\$_[1]);
	            \$send->(\@_); 
            };
		 	
            # IO::Socket::recv 
            my \$recv = \\&$pkg\::recv;
            \*$pkg\::recv = sub {
                my \$self = \$_[0];
		        \${\*\$self}{'io_socket_bytecounter_in'} += \$_[2];
		        \$recv->(\@_);
            };
           
            #### IO::Handle methods ##
 
 
            #### new methods ##
           
            sub $pkg\::get_bytes_in {
                my \$self = \$_[0];
                \${\*\$self}{'io_socket_bytecounter_in'};
            }

            sub $pkg\::get_bytes_out {
                my \$self = \$_[0];
                \${\*\$self}{'io_socket_bytecounter_out'};
            }
            
            sub $pkg\::get_bytes_total {
                my \$self = \$_[0];
                \${\*\$self}{'io_socket_bytecounter_in'} + \${\*\$self}{'io_socket_bytecounter_out'};
            }

OVERRIDE_END
    }

    return $@ ? 0 : 1;
}

sub _get_byte_size {
    my($self, @strings) = @_;
    my $bytes = 0;
    
    {
        use bytes;
        for my $string (@strings) {
            $bytes += length($string);
        }
    }
    
    return $bytes;
}

1;

__END__

=head1 NAME

IO::Socket::ByteCounter - Perl extension to track the byte sizes of data in and out of a socket

=head1 SYNOPSIS

    use IO::Socket::ByteCounter qw('IO::Socket');

or:

    use IO::Socket::ByteCounter;
    ...
    IO::Socket::ByteCounter->record_bytes('IO::Socket');

then:

    ... normal IO::Socket::INET object (as $sock) use ...

    print 'Bytes out: ',   $sock->get_bytes_out,   "\n";  
    print 'Bytes in: ',    $sock->get_bytes_in ,   "\n";
    print 'Bytes total: ', $sock->get_bytes_total, "\n";  

=head1 METHODS

=head2 record_bytes()

Takes a list of package names (or IO::Socket based objects) for which to turn on byte counting.

Its also creates 3, hopefully, self explanitory methods for the socket in question:

=over 4

=item $sock->get_bytes_in()

=item $sock->get_bytes_out()

=item $sock->get_bytes_total()

=back

=head2 _get_byte_size()

Returns size of strings passed in bytes. Used internally.

=head1 TODO

Add [m]any methods that need bytes counted.

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
