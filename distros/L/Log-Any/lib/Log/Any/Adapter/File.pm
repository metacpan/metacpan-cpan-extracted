use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter::File;

# ABSTRACT: Simple adapter for logging to files
our $VERSION = '1.710';

use Config;
use Fcntl qw/:flock/;
use IO::File;
use Log::Any::Adapter::Util ();

use Log::Any::Adapter::Base;
our @ISA = qw/Log::Any::Adapter::Base/;

my $HAS_FLOCK = $Config{d_flock} || $Config{d_fcntl_can_lock} || $Config{d_lockf};

my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');
sub new {
    my ( $class, $file, @args ) = @_;
    return $class->SUPER::new( file => $file, log_level => $trace_level, @args );
}

sub init {
    my $self = shift;
    if ( exists $self->{log_level} && $self->{log_level} =~ /\D/ ) {
        my $numeric_level = Log::Any::Adapter::Util::numeric_level( $self->{log_level} );
        if ( !defined($numeric_level) ) {
            require Carp;
            Carp::carp( sprintf 'Invalid log level "%s". Defaulting to "%s"', $self->{log_level}, 'trace' );
        }
        $self->{log_level} = $numeric_level;
    }
    if ( !defined $self->{log_level} ) {
        $self->{log_level} = $trace_level;
    }
    my $file = $self->{file};
    my $binmode = $self->{binmode} || ':utf8';
    $binmode = ":$binmode" unless substr($binmode,0,1) eq ':';
    open( $self->{fh}, ">>$binmode", $file )
      or die "cannot open '$file' for append: $!";
    $self->{fh}->autoflush(1);
}

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level( $method );
    *{$method} = sub {
        my ( $self, $text ) = @_;
        return if $method_level > $self->{log_level};
        my $msg = sprintf( "[%s] %s\n", scalar(localtime), $text );
        flock($self->{fh}, LOCK_EX) if $HAS_FLOCK;
        $self->{fh}->print($msg);
        flock($self->{fh}, LOCK_UN) if $HAS_FLOCK;
      }
}

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';
    my $base = substr($method,3);
    my $method_level = Log::Any::Adapter::Util::numeric_level( $base );
    *{$method} = sub {
        return !!(  $method_level <= $_[0]->{log_level} );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::File - Simple adapter for logging to files

=head1 VERSION

version 1.710

=head1 SYNOPSIS

    use Log::Any::Adapter ('File', '/path/to/file.log');

    # or

    use Log::Any::Adapter;
    ...
    Log::Any::Adapter->set('File', '/path/to/file.log');

    # with minimum level 'warn'

    use Log::Any::Adapter (
        'File', '/path/to/file.log', log_level => 'warn',
    );

=head1 DESCRIPTION

This simple built-in L<Log::Any|Log::Any> adapter logs each message to the
specified file, with a datestamp prefix and newline appended. The file is
opened for append with autoflush on.  If C<flock> is available, the handle
will be locked when writing.

The C<log_level> attribute may be set to define a minimum level to log.

The C<binmode> attribute may be set to define a PerlIO layer string to use
when opening the file.  The default is C<:utf8>.

Category is ignored.

=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>

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
