=head1 NAME

Log::Handler::Output::Forward - Forward messages to routines.

=head1 SYNOPSIS

    use Log::Handler::Output::Forward;

    my $forwarder = Log::Handler::Output::Forward->new(
        forward_to => sub { },
        arguments  => [ "foo" ],
    );

    $forwarder->log(message => $message);

=head1 DESCRIPTION

This output module makes it possible to forward messages to sub routines.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::Forward object.

The following options are possible:

=over 4

=item B<forward_to>

This option excepts a code reference.

Please note that the message is forwarded as a hash reference. If you change it
then this would have an effect to all outputs.

=item B<arguments>

With this option you can define arguments that will be passed to the sub
routine.

In the following example the arguments would be passed as a array to
C<Class::method()>.

    my $forwarder = Log::Handler::Output::Forward->new(
        forward_to => \&Class::method,
        arguments  => [ $self, "foo" ],
    );

This would call intern:

    Class::method(@arguments, $message);

If this option is not set then the message will be passed as first argument.

=back

=head2 log()

Call C<log()> if you want to forward messages to the subroutines.

Example:

    $forwarder->log("this message will be forwarded to all sub routines");

=head2 validate()

Validate a configuration.

=head2 reload()

Reload with a new configuration.

=head2 errstr()

This function returns the last error message.

=head1 FORWARDED MESSAGE

Note that the message will be forwarded as a hash reference.

If you make changes to the reference it affects all other outputs.

The hash key C<message> contains the message.

=head1 PREREQUISITES

    Carp
    Params::Validate

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Output::Forward;

use strict;
use warnings;
use Carp;
use Params::Validate qw();

our $VERSION = "0.03";
our $ERRSTR  = "";

sub new {
    my $class   = shift;
    my $options = $class->_validate(@_);
    return bless $options, $class;
}

sub log {
    my $self    = shift;
    my $coderef = $self->{forward_to};
    my $message = @_ > 1 ? {@_} : shift;

    if ($self->{arguments}) {
        eval { &$coderef(@{$self->{arguments}}, $message) };
    } else {
        eval { &$coderef($message) };
    }

    if ($@) {
        return $self->_raise_error($@);
    }

    return 1;
}

sub validate {
    my $self = shift;
    my $opts = ();

    eval { $opts = $self->_validate(@_) };

    if ($@) {
        $ERRSTR = $@;
        return undef;
    }

    return $opts;
}

sub reload {
    my $self = shift;
    my $opts = $self->validate(@_);

    if (!$opts) {
        return undef;
    }

    foreach my $key (keys %$opts) {
        $self->{$key} = $opts->{$key};
    }

    return 1;
}

sub errstr {
    return $ERRSTR;
}

#
# private stuff
#

sub _validate {
    my $class   = shift;

    my %options = Params::Validate::validate(@_, {
        forward_to => {
            type => Params::Validate::CODEREF,
        },
        arguments => {
            type => Params::Validate::ARRAYREF
                  | Params::Validate::SCALAR,
            optional => 1,
        },
    });

    if (defined $options{arguments} && !ref($options{arguments})) {
        $options{arguments} = [ $options{arguments} ];
    }

    return \%options;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
