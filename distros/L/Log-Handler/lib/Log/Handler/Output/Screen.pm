=head1 NAME

Log::Handler::Output::Screen - Log messages to the screen.

=head1 SYNOPSIS

    use Log::Handler::Output::Screen;

    my $screen = Log::Handler::Output::Screen->new(
        log_to => "STDERR",
        dump   => 1,
    );

    $screen->log($message);

=head1 DESCRIPTION

This output module makes it possible to log messages to your screen.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::Screen object.

The following options are possible:

=over 4

=item B<log_to>

Where do you want to log? Possible is: STDOUT, STDERR and WARN.

WARN means to call C<warn()>.

The default is STDOUT.

=item B<dump>

Set this option to 1 if you want that the message will be dumped with
C<Data::Dumper> to the screen.

=item B<utf8>, B<utf-8>

Set utf8 or utf-8 on STDOUT or STDERR. It depends on the parameter B<log_to>.

    utf8   =  binmode, $fh, ":utf8";
    utf-8  =  binmode, $fh, "encoding(utf-8)"; 

Yes, there is a difference.

L<http://perldoc.perl.org/perldiag.html#Malformed-UTF-8-character-(%25s)>

L<http://perldoc.perl.org/Encode.html#UTF-8-vs.-utf8-vs.-UTF8>

=back

=head2 log()

Call C<log()> if you want to log a message to the screen.

Example:

    $screen->log("this message goes to the screen");

=head2 validate()

Validate a configuration.

=head2 reload()

Reload with a new configuration.

=head2 errstr()

This function returns the last error message.

=head1 PREREQUISITES

    Data::Dumper
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

package Log::Handler::Output::Screen;

use strict;
use warnings;
use Data::Dumper;
use Params::Validate qw();

our $VERSION = "0.07";
our $ERRSTR  = "";

sub new {
    my $class   = shift;
    my $options = $class->_validate(@_);
    return bless $options, $class;
}

sub log {
    my $self    = shift;
    my $message = @_ > 1 ? {@_} : shift;
    local $|=1;

    if ($self->{dump}) {
        $message->{message} = Dumper($message);
    }

    if ($self->{log_to} eq "STDOUT") {
        if ($self->{utf8}) {
            binmode STDOUT, ":utf8";
        } elsif ($self->{"utf-8"}) {
            binmode STDOUT, "encoding(utf-8)";
        }
        print STDOUT $message->{message}
            or return $self->_raise_error($!);
    } elsif ($self->{log_to} eq "STDERR") {
        if ($self->{utf8}) {
            binmode STDERR, ":utf8";
        } elsif ($self->{"utf-8"}) {
            binmode STDERR, "encoding(utf-8)";
        }
        print STDERR $message->{message}
            or return $self->_raise_error($!);
    } elsif ($self->{log_to} eq "WARN") {
        # hmmm, should I really set utf8 for warnings?
        warn $message->{message};
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
        log_to => {
            type => Params::Validate::SCALAR,
            regex => qr/^(?:STDOUT|STDERR|WARN)\z/,
            default => "STDOUT",
        },
        utf8 => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
        "utf-8" => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
        dump => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
    });

    return \%options;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
