package Lim::Error;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);

=encoding utf8

=head1 NAME

Lim::Error - Encapsulate an error within Lim

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

=head1 SYNOPSIS

=over 4

use Lim::Error;

$error = Lim::Error->new('This is a simple error');

=back

=head1 METHODS

=over 4

=item $error = Lim::Error->new(key => value...)

Create a new Lim::Error object.

=over 4

=item code => 500

Specify the error code, used in HTTP responses as well as RPC protocols.

=item message => $message

Specify the error message.

=item module => $module

Specify the module that created this error, if its a blessed object the L<ref>()
of that object will be used.

=back

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        code => 500,
        message => 'Unknown Error',
        module => 'UNKNOWN'
    };
    bless $self, $class;
    
    if (defined $args{code}) {
        unless ($args{code} >= 300 and $args{code} < 600) {
            confess __PACKAGE__, ': Invalid code [', $args{code}, '] given in error';
        }
        $self->{code} = $args{code};
    }
    if (defined $args{message}) {
        $self->{message} = $args{message};
    }
    if (defined $args{module}) {
        if (blessed($args{module})) {
            $self->{module} = ref($args{module});
        }
        else {
            $self->{module} = $args{module};
        }
    }

    $self;
}

sub DESTROY {
}

=item $error->set($hash_ref)

Populate an error object from a hash reference.

=cut

sub set {
    if (ref($_[1]) eq 'HASH') {
        if (exists $_[1]->{'Lim::Error'}) {
            foreach (qw(code message module)) {
                if (exists $_[1]->{'Lim::Error'}->{$_}) {
                    $_[0]->{$_} = $_[1]->{'Lim::Error'}->{$_};
                }
            }
        }
    }
    
    $_[0];
}

=item $error->code

Return the code of the error.

=cut

sub code {
    $_[0]->{code};
}

=item $error->set_code($code)

Set the error code to C<$code>.

=cut

sub set_code {
    $_[0]->{code} = $_[1];
    
    $_[0];
}

=item $error->message

Return the message of the error.

=cut

sub message {
    $_[0]->{message};
}

=item $error->set_message($message)

Set the error message to C<$message>

=cut

sub set_message {
    $_[0]->{message} = $_[1];
    
    $_[0];
}

=item $error->module

Return the module name of the error.

=cut

sub module {
    $_[0]->{module};
}

=item $error->set_module($module_name)

Set the module name of the error, this can not take blessed objects.

=cut

sub set_module {
    $_[0]->{module} = $_[1];
    
    $_[0];
}

=item $hash_ref = $error->TO_JSON

Returns a hash reference describing the error, this is to support passing
objects to L<JSON::XS>.

=cut

sub TO_JSON {
    {
        'Lim::Error' => {
            code => $_[0]->{code},
            message => $_[0]->{message},
            module => $_[0]->{module}
        }
    };
}

=item $string = $error->toString

Returns a string that describes the error.

=cut

sub toString {
    'Module: ' . $_[0]->{module} . ' Code: ' . $_[0]->{code} . ' Message: ' . $_[0]->{message};
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Error

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Error
