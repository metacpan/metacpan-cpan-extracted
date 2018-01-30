use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF;

# ABSTRACT: ESLIF is Extended ScanLess InterFace

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use vars qw/$VERSION/;

BEGIN {
    our $VERSION = '2.0.34'; # VERSION

    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
}

# Load our explicit sub-modules
use MarpaX::ESLIF::Event::Type;
use MarpaX::ESLIF::Grammar;
use MarpaX::ESLIF::Grammar::Properties;
use MarpaX::ESLIF::Grammar::Rule::Properties;
use MarpaX::ESLIF::Grammar::Symbol::Properties;
use MarpaX::ESLIF::Logger::Level;
use MarpaX::ESLIF::Symbol::PropertyBitSet;
use MarpaX::ESLIF::Symbol::Type;
use MarpaX::ESLIF::Value::Type;
use MarpaX::ESLIF::Rule::PropertyBitSet;


my @REGISTRY = ();

sub _logger_to_self {
    my ($class, $loggerInterface) = @_;

    my $definedLoggerInterface = defined($loggerInterface);

    foreach (@REGISTRY) {
        my $_loggerInterface = $_->_getLoggerInterface;
        my $_definedLoggerInterface = defined($_loggerInterface);
	return $_
            if (
                (! $definedLoggerInterface && ! $_definedLoggerInterface)
                ||
                ($definedLoggerInterface && $_definedLoggerInterface && ($loggerInterface == $_loggerInterface))
            )
    }

    return
}

sub new {
  my ($class, $loggerInterface) = @_;

  my $self = $class->_logger_to_self($loggerInterface);

  push(@REGISTRY, $self = bless [ MarpaX::ESLIF::Engine->allocate($loggerInterface), $loggerInterface ], $class) if ! defined($self);

  return $self
}

sub getInstance {
    goto &new
}

sub version {
    return MarpaX::ESLIF::Engine::version
}

sub _getInstance {
    return $_[0]->[0]
}

sub _getLoggerInterface {
    return $_[0]->[1]
}

sub CLONE {
    #
    # One perl thread <-> one perl interpreter
    #
    map { $_->[0] = MarpaX::ESLIF::Engine->allocate($_->_getLoggerInterface) } @REGISTRY
}

sub DESTROY {
    MarpaX::ESLIF::Engine->dispose($_[0]->[0])
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF - ESLIF is Extended ScanLess InterFace

=head1 VERSION

version 2.0.34

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $eslif = MarpaX::ESLIF->new();
  printf "ESLIF library version: %s\n", $eslif->version;

With a logger, using Log::Any::Adapter::Stderr as an example:

  use MarpaX::ESLIF;
  use Log::Any qw/$log/;
  use Log::Any::Adapter ('Stderr', log_level => 'trace' );

  my $eslif = MarpaX::ESLIF->new($log);
  printf "ESLIF library version: %s\n", $eslif->version;

This class and its derivatives are thread-safe. Although there can be many ESLIF instances, in practice a single instance is enough, unless you want different logging interfaces. This is why the C<new> method is implemented as a I<multiton>. Once a MarpaX::ESLIF instance is created, the user should create a L<MarpaX::ESLIF::Grammar> instance to have a working grammar.

=head1 DESCRIPTION

ESLIF is derived from perl's L<Marpa::R2>, and has its own BNF, documented in L<MarpaX::ESLIF::BNF>.

The main features of this BNF are:

=over

=item Sub-grammars

The number of sub grammars is unlimited.

=item Regular expressions

Native support of regular expression using the L<PCRE2|http://www.pcre.org/> library (i.e. this is <not> exactly perl regexps, although very closed).

=item Streaming

Native support of streaming input.

=back

Beginners might want to look at L<MarpaX::ESLIF::Introduction>.

=head1 METHODS

=head2 MarpaX::ESLIF->new($loggerInterface)

  my $loggerInterface = My::Logger::Interface->new();
  my $eslif = MarpaX::ESLIF->new();

Returns an instance of MarpaX::ESLIF, noted C<$eslif> below.

C<$loggerInterface> is an optional parameter that, when its exists, must be an object instance that can do the methods documented in L<MarpaX::ESLIF::Logger::Interface>, or C<undef>.

An example of logging implementation can be a L<Log::Any> adapter.

=head2 MarpaX::ESLIF->getInstance($loggerInterface)

Alias to C<new>.

=head2 $eslif->version()

  printf "ESLIF library version: %s\n", $eslif->version;

Returns a string containing the current underlying ESLIF library version.

=head1 NOTES

The perl interface is an I<all-in-one> version of L<marpaESLIF|https://github.com/jddurand/c-marpaESLIF> library, which means that character conversion is using C<iconv> (or C<iconv>-like on Windows) instead of ICU, even if the later is available on your system.

=head1 SEE ALSO

L<MarpaX::ESLIF::Introduction>, L<PCRE2|http://www.pcre.org/>, L<MarpaX::ESLIF::BNF>, L<MarpaX::ESLIF::Logger::Interface>, L<MarpaX::ESLIF::Grammar>, L<MarpaX::ESLIF::Recognizer>.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
