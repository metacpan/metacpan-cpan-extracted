use strict;
use warnings FATAL => 'all';

package MarpaX::Database::Terminfo;
use MarpaX::Database::Terminfo::Grammar;
use MarpaX::Database::Terminfo::Grammar::Regexp qw/@TOKENSRE/;
use Marpa::R2;

# ABSTRACT: Parse a terminfo data base using Marpa

use Log::Any qw/$log/;
use Carp qw/croak/;

our $VERSION = '0.012'; # VERSION


my %events = (
    'MAXMATCH' => sub {
        my ($recce, $bufferp, $tokensrep, $string, $start, $length) = @_;

        my @expected = @{$recce->terminals_expected()};
        my $prev = pos(${$bufferp});
        pos(${$bufferp}) = $start;
        my $ok = 0;
        if ($log->is_trace) {
            $log->tracef('Expected terminals: %s', \@expected);
        }
        foreach (@{$tokensrep}) {
            my ($token, $re) = @{$_};
            if ((grep {$_ eq $token} @expected)) {
                if (${$bufferp} =~ $re) {
                    $length = $+[1] - $-[1];
                    $string = substr(${$bufferp}, $start, $length);
                    if ($log->is_debug && $token eq 'LONGNAME') {
                        $log->debugf('%s "%s")', $token, $string);
                    } elsif ($log->is_trace) {
                        $log->tracef('lexeme_read(token=%s, start=%d, length=%d, string="%s")', $token, $start, $length, $string);
                    }
                    $recce->lexeme_read($token, $start, $length, $string);
                    $ok = 1;
                    last;
                } else {
                    if ($log->is_trace) {
                        $log->tracef('\"%s\"... does not match %s', substr(${$bufferp}, $start, 20), $re);
                    }
                }
            }
        }
        die "Unmatched token in @expected, current portion of string is \"$string\"" if (! $ok);
        pos(${$bufferp}) = $prev;
    },
);


# ----------------------------------------------------------------------------------------

sub new {
  my $class = shift;

  my $self = {};

  my $grammarObj = MarpaX::Database::Terminfo::Grammar->new(@_);
  my $grammar_option = $grammarObj->grammar_option();
  $grammar_option->{bless_package} = __PACKAGE__;
  $self->{_G} = Marpa::R2::Scanless::G->new($grammar_option);

  my $recce_option = $grammarObj->recce_option();
  $recce_option->{grammar} = $self->{_G};
  $self->{_R} = Marpa::R2::Scanless::R->new($recce_option);

  bless($self, $class);

  return $self;
}
# ----------------------------------------------------------------------------------------

sub _parse {
    my ($self, $bufferp, $tokensrep) = @_;

    my $max = length(${$bufferp});
    for (
        my $pos = $self->{_R}->read($bufferp);
        $pos < $max;
        $pos = $self->{_R}->resume()
    ) {
        my ($start, $length) = $self->{_R}->pause_span();
        my $str = substr(${$bufferp}, $start, $length);
        for my $event_data (@{$self->{_R}->events}) {
            my ($name) = @{$event_data};
            my $code = $events{$name} // die "no code for event $name";
            $self->{_R}->$code($bufferp, $tokensrep, $str, $start, $length);
        }
    }

    return $self;
}

sub parse {
    my ($self, $bufferp) = @_;

    return $self->_parse($bufferp, \@TOKENSRE);
}
# ----------------------------------------------------------------------------------------

sub value {
    my ($self) = @_;

    my $rc = $self->{_R}->value();

    #
    # Another parse tree value ?
    #
    if (defined($self->{_R}->value())) {
        my $msg = 'Ambigous parse tree detected';
        if ($log->is_fatal) {
            $log->fatalf('%s', $msg);
        }
        croak $msg;
    }
    if (! defined($rc)) {
        my $msg = 'Parse tree failure';
        if ($log->is_fatal) {
            $log->fatalf('%s', $msg);
        }
        croak $msg;
    }
    return $rc
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Database::Terminfo - Parse a terminfo data base using Marpa

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Database::Terminfo;
    use Log::Log4perl qw/:easy/;
    use Log::Any::Adapter;
    use Log::Any qw/$log/;
    #
    # Init log
    #
    our $defaultLog4perlConf = '
    log4perl.rootLogger              = WARN, Screen
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout  = PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
    ';
    Log::Log4perl::init(\$defaultLog4perlConf);
    Log::Any::Adapter->set('Log4perl');
    #
    # Parse terminfo
    #
    my $terminfoSourceCode = "ansi|ansi/pc-term compatible with color,\n\tmc5i,\n";
    my $terminfoAstObject = MarpaX::Database::Terminfo->new();
    $terminfoAstObject->parse(\$terminfoSourceCode)->value;

=head1 DESCRIPTION

This module parses a terminfo database and produces an AST from it. If you want to enable logging, be aware that this module is a Log::Any thingy.

The grammar is a slightly revisited version of the one found at L<http://nixdoc.net/man-pages/HP-UX/man4/terminfo.4.html#Formal%20Grammar>, taking into account ncurses compatibility.

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instantiate a new object. Takes no parameter.

=head2 parse($self, $bufferp)

Parses a terminfo database. Takes a pointer to a string as parameter.

=head2 value($self)

Returns Marpa value on the parse tree. Ambiguous parse tree result is disabled and the module will croak if this happen.

=head1 SEE ALSO

L<Unix Documentation Project - terminfo|http://nixdoc.net/man-pages/HP-UX/man4/terminfo.4.html#Formal%20Grammar>

L<GNU Ncurses|http://www.gnu.org/software/ncurses/>

=head1 AUTHOR

jddurand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
