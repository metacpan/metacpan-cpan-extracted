package Log::Any::Adapter::Callback;

use strict;
use warnings;

use Log::Any::Adapter::Util qw(make_method);
use base qw(Log::Any::Adapter::Base);

our $VERSION = '0.09'; # VERSION

my @logging_methods = Log::Any->logging_methods;
my %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}

sub _default_level {
    return $ENV{LOG_LEVEL}
        if $ENV{LOG_LEVEL} && $logging_levels{$ENV{LOG_LEVEL}};
    return 'trace' if $ENV{TRACE};
    return 'debug' if $ENV{DEBUG};
    return 'info'  if $ENV{VERBOSE};
    return 'error' if $ENV{QUIET};
    'warning';
}

my ($logging_cb, $detection_cb);
sub init {
    my ($self) = @_;
    $logging_cb   = $self->{logging_cb}
        or die "Please provide logging_cb when initializing ".__PACKAGE__;
    if ($self->{detection_cb}) {
        $detection_cb = $self->{detection_cb};
    } else {
        $detection_cb = sub { 1 };
    }
    if (!defined($self->{min_level})) { $self->{min_level} = _default_level() }
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my $self = shift;
            return if $logging_levels{$method} <
                $logging_levels{ $self->{min_level} };
            $logging_cb->($method, $self, @_);
        });
}

for my $method (Log::Any->detection_methods()) {
    make_method(
        $method,
        sub {
            $detection_cb->($method, @_);
        });
}

1;
# ABSTRACT: Send Log::Any logs to a subroutine

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Callback - Send Log::Any logs to a subroutine

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 # say, let's POST each log message to an HTTP API server
 use LWP::UserAgent;
 my $ua = LWP::UserAgent->new;

 use Log::Any::Adapter;
 Log::Any::Adapter->set('Callback',
     min_level    => 'warn',
     logging_cb   => sub {
         my ($method, $self, $format, @params) = @_;
         $ua->post("https://localdomain/log", level=>$method, Content=>$format);
         sleep 1; # don't overload the server
     },
     detection_cb => sub { ... }, # optional, default is: sub { 1 }
 );

=head1 DESCRIPTION

This adapter lets you specify callback subroutine to be called by Log::Any's
logging methods (like $log->debug(), $log->error(), etc) and detection methods
(like $log->is_warning(), $log->is_fatal(), etc.).

This adapter is used for customized logging, and is mostly a convenient
construct to save a few lines of code. You could achieve the same effect by
creating a full Log::Any adapter class.

Your logging callback subroutine will be called with these arguments:

 ($method, $self, $format, @params)

where $method is the name of method (like "debug") and ($self, $format, @params)
are given by Log::Any.

=for Pod::Coverage init

=head1 SEE ALSO

L<Log::Any>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-Adapter-Callback>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Log-Any-Adapter-Callback>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-Adapter-Callback>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
