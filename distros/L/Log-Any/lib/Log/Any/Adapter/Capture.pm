use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter::Capture;

# ABSTRACT: Adapter for capturing log messages into an arrayref
our $VERSION = '1.717';

use Log::Any::Adapter::Util ();

use Log::Any::Adapter::Base;
our @ISA = qw/Log::Any::Adapter::Base/;

# Subclass for optional structured logging
@Log::Any::Adapter::Capture::_Structured::ISA = ( __PACKAGE__ );

sub init {
    my ($self) = @_;

    # Handle 'text' and 'structured' aliases
    if ( defined $self->{text} ) {
        $self->{format} = 'text';
        $self->{to} = delete $self->{text};
    }
    if ( defined $self->{structured} ) {
        $self->{format} = 'structured';
        $self->{to} = delete $self->{structured};
    }

    my $to = $self->{to};
    unless ( $to and ref $to eq 'CODE' || ref $to eq 'ARRAY' ) {
        require Carp;
        Carp::croak( "Capture destination 'to' must be an arrayref or coderef" );
    }

    my $format = $self->{format} || 'messages';
    if ( $format eq 'text' ) {
        $self->{_callback} = # only pass the message text argument
            ref $to eq 'CODE' ? sub { $to->($_[2]) }
            : sub { push @$to, $_[2] };
    }
    elsif ( $format eq 'messages' ) {
        $self->{_callback} = ref $to eq 'CODE' ? $to : sub { push @$to, [ @_ ] };
    }
    elsif ( $format eq 'structured' ) {
        $self->{_callback} = ref $to eq 'CODE' ? $to : sub { push @$to, [ @_ ] };
        # Structured logging is determined by whether or not the package
        # contains a method of that name.  If structured logging were enabled,
        # the proxy would always call ->structured rather than its default
        # behavior of flattening to a string, even for the case where the user
        # of this module wanted strings.  So, enable/disable of structured
        # capture requires changing the class of this object.
        # This line is written in a way to make subclassing possible.
        bless $self, ref($self).'::_Structured' unless $self->can('structured');
    }
    else {
        require Carp;
        Carp::croak( "Unknown capture format '$format' (expected 'text', 'messages', or 'structured')" );
    }

    if ( defined $self->{log_level} && $self->{log_level} =~ /\D/ ) {
        my $numeric_level = Log::Any::Adapter::Util::numeric_level( $self->{log_level} );
        if ( !defined($numeric_level) ) {
            require Carp;
            Carp::carp( "Invalid log level '$self->{log_level}'.  Will capture all messages." );
        }
        $self->{log_level} = $numeric_level;
    }
}

# Each logging method simply passes its arguments (minus $self) to the _callback
# Logging can be skipped if a log_level is in effect.
foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level($method);
    *{$method} = sub {
        my ( $self, $text ) = @_;
        return if defined $self->{log_level} and $method_level > $self->{log_level};
        $self->{_callback}->( $method, $self->{category}, $text );
    };
}

# Detection methods return true unless a log_level is in effect
foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';
    my $base = substr( $method, 3 );
    my $method_level = Log::Any::Adapter::Util::numeric_level($base);
    *{$method} = sub {
        return !defined $_[0]{log_level} || !!( $method_level <= $_[0]{log_level} );
    };
}

# A separate package is required for handling the ->structured Adapter API.
# See notes in init()
sub Log::Any::Adapter::Capture::_Structured::structured {
    my ( $self, $method, $category, @parts ) = @_;
    return if defined $self->{log_level}
        and Log::Any::Adapter::Util::numeric_level($method) > $self->{log_level};
    $self->{_callback}->( $method, $category, @parts );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Capture - Adapter for capturing log messages into an arrayref

=head1 VERSION

version 1.717

=head1 SYNOPSIS

  # temporarily redirect arrays of [ $level, $category, $message ] into an array
  Log::Any::Adapter->set( { lexically => \my $scope }, Capture => to => \my @array );

  # temporarily redirect just the text of log messages into an array
  Log::Any::Adapter->set( { lexically => \my $scope }, Capture => text => \my @array );

  # temporarily redirect the full argument list and context of each call, but only for
  # log levels 'info' and above.
  Log::Any::Adapter->set(
    { lexically => \my $scope },
    Capture =>
        format => 'structured',
        to => \my @array,
        log_level => 'info'
  );

=head1 DESCRIPTION

This logging adapter provides a convenient way to capture log messages into a callback
or arrayref of your choice without needing to write your own adapter.  It is intended
for cases where you want to temporarily capture log messages, such as showing them to
a user of your application rather than having them written to a log file.

=head1 ATTRIBUTES

=head2 to

Specify a coderef or arrayref where the messages will be delivered.  The content pushed onto
the array or passed to the coderef depends on L</format>.

=head2 format

=over

=item C<'messages'>

  sub ( $level, $category, $message_text ) { ... }
  push @to, [ $level, $category, $message_text ];

This is the default format.  It passes/pushes 3 arguments: the name of the log level,
the logging category, and the message text as a plain string.

=item C<'text'>

  sub ( $message_text ) { ... }
  push @to, $message_text;

This format is the simplest, and only passes/pushes the text of the message.

=item C<'structured'>

  sub ( $level, $category, @message_parts, \%context? ) { ... }
  push @to, [ $level, $category, @message_parts, \%context? ];

This passes/pushes the full information available about the call to the logging method.
The C<@message_parts> are the actual arguments passed to the logging method, and if the final
argument is a hashref, it is the combined C<context> from the logging proxy and any overrides
passed to the logging method.

=back

=head2 log_level

Like other logging adapters, this optional argument can filter out any log messages above the
specified threshhold.  The default is to pass through all messages regardless of level.

=head1 ATTRIBUTE ALIASES

These are not actual attributes, just shortcuts for others:

=head2 text

  text => $dest

is shorthand for

  format => 'text', to => $dest

=head2 structured

  structured => $dest

is shorthand for

  format => 'structured', to => $dest

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
