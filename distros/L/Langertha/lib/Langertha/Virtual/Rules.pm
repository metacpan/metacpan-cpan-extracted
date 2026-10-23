package Langertha::Virtual::Rules;
# ABSTRACT: Helpers that build the rules of Langertha::Engine::Virtual
our $VERSION = '0.504';
use strict;
use warnings;
use Carp qw( croak );
use Exporter 'import';

our @EXPORT_OK   = qw( answer tool tools after error );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


# The optional arguments of a reaction helper: only usage, a HashRef.
sub _reaction_options {
  my ( $helper, @options ) = @_;
  croak __PACKAGE__."::$helper takes usage => \\%usage after its arguments" if @options % 2;
  my %options = @options;
  my @unknown = grep { $_ ne 'usage' } sort keys %options;
  croak __PACKAGE__."::$helper has unknown options: @unknown (known: usage)" if @unknown;
  return () unless exists $options{usage};
  croak __PACKAGE__."::$helper usage must be a HashRef" unless ref $options{usage} eq 'HASH';
  return ( usage => $options{usage} );
}

sub answer {
  my ( $text, @options ) = @_;
  croak __PACKAGE__.'::answer needs a text' unless defined $text && !ref $text;
  return { answer => $text, _reaction_options( answer => @options ) };
}


sub tool {
  my ( $name, $arguments, @options ) = @_;
  croak __PACKAGE__.'::tool needs a tool name' unless defined $name && !ref $name && length $name;
  $arguments //= {};
  croak __PACKAGE__.'::tool arguments must be a HashRef' unless ref $arguments eq 'HASH';
  return { tool_calls => [ [ $name, $arguments ] ], _reaction_options( tool => @options ) };
}


sub tools {
  my ( $calls, @options ) = @_;
  croak __PACKAGE__.'::tools needs an ArrayRef of calls' unless ref $calls eq 'ARRAY' && @$calls;
  my @tool_calls;
  for my $call (@$calls) {
    if ( ref $call eq 'ARRAY' && @$call <= 2 ) {
      push @tool_calls, @{ tool(@$call)->{tool_calls} };
    }
    elsif ( ref $call eq 'HASH' && ref $call->{tool_calls} eq 'ARRAY' ) {
      croak __PACKAGE__.'::tools takes the usage of the whole turn: give it to tools(...), not to a tool(...) in it'
        if exists $call->{usage};
      push @tool_calls, @{ $call->{tool_calls} };
    }
    else {
      croak __PACKAGE__.'::tools takes [ $name, \%arguments ] pairs or tool(...) reactions';
    }
  }
  return { tool_calls => \@tool_calls, _reaction_options( tools => @options ) };
}


sub error {
  my ( $status, $message ) = @_;
  croak __PACKAGE__.'::error needs an HTTP status from 400 to 599'
    unless defined $status && !ref $status && $status =~ /\A[45]\d\d\z/;
  croak __PACKAGE__.'::error needs a message' unless defined $message && !ref $message;
  return { error => { status => 0 + $status, message => $message } };
}


my %AFTER_KEYS = map { $_ => 1 } qw( tool result );

sub after {
  my ( @args ) = @_;
  my %match = @args == 1 ? ( tool => $args[0] ) : @args % 2 ? () : @args;
  croak __PACKAGE__.'::after takes a tool name, or tool => ... and result => ...; '
    .'it is a trigger: write after(...) => $reaction'
    if ( @args > 1 && @args % 2 ) || grep { !$AFTER_KEYS{$_} } keys %match;
  for my $key ( keys %match ) {
    my $value = $match{$key};
    croak __PACKAGE__."::after $key must be a string or a Regexp"
      if defined $value && ref $value && ref $value ne 'Regexp';
  }
  return { after => \%match };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Virtual::Rules - Helpers that build the rules of Langertha::Engine::Virtual

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    use Langertha::Engine::Virtual;
    use Langertha::Virtual::Rules qw( answer tool tools after error );

    my $engine = Langertha::Engine::Virtual->new(
      rules => [
        'Hello'                 => answer('Hi there'),
        qr/\ARead (\S+)\z/      => sub { my ( $req, $path ) = @_; tool( read_file => { path => $path } ) },
        'Look around'           => tools( [ [ bash => { command => 'ls' } ], [ bash => { command => 'pwd' } ] ] ),
        after('read_file')      => answer('I read it.'),
      ],
      fallback => answer('I do not know that one.'),
    );

=head1 DESCRIPTION

Small functions that build the data L<Langertha::Engine::Virtual> reads as
reactions and triggers. They return plain Perl data, so a rule written
without them works the same: C<answer('x')> is C<< { answer => 'x' } >>.
Nothing is exported by default; ask for the names, or C<:all>.

C<after> shares its name with the L<Moose> method modifier: import it into a
test script or a plain package, not into a L<Moose> class, or call it as
C<Langertha::Virtual::Rules::after(...)>.

=head1 FUNCTIONS

=head2 answer

    answer('The answer is 42.')
    answer( 'The answer is 42.', usage => { prompt_tokens => 12, completion_tokens => 5 } )

The reaction "reply with this text": C<< { answer => $text } >>. With
C<usage>, the reply carries that token usage (see
L<Langertha::Engine::Virtual/USAGE>): C<< { answer => $text, usage => \%usage } >>.

=head2 tool

    tool( read_file => { path => 'a.txt' } )
    tool( read_file => { path => 'a.txt' }, usage => { prompt_tokens => 30, completion_tokens => 9 } )

The reaction "call this tool with these arguments":
C<< { tool_calls => [ [ $name, \%arguments ] ] } >>. The arguments default to
C<{}>; to give C<usage>, pass them, even as C<{}>.

=head2 tools

    tools( [ [ read_file => { path => 'a.txt' } ], [ bash => { command => 'ls' } ] ] )
    tools( [ tool( read_file => { path => 'a.txt' } ), tool( bash => { command => 'ls' } ) ] )
    tools( [ [ read_file => { path => 'a.txt' } ] ], usage => { prompt_tokens => 30, completion_tokens => 18 } )

The reaction "call these tools in one turn", in order. Each element is a
C<[ $name, \%arguments ]> pair or a L</tool> reaction. C<usage> belongs to the
turn, so it is given to C<tools>; a L</tool> in the list that carries one
croaks.

=head2 error

    error( 429, 'Rate limit reached' )

The reaction "fail like a server that answers with this status and message":
C<< { error => { status => 429, message => '...' } } >>. The status is an
HTTP error status (400 to 599). The caller sees its usual error path: a
C<croak> from C<simple_chat>, a failed future from the C<_f> calls.

=head2 after

    after()                                        # after any tool result
    after('read_file')                             # after a read_file result
    after( tool => qr/_file\z/ )                   # tool name matches
    after( tool => 'bash', result => qr/Exit code: (\d+)/ )

The trigger "the last message is a tool result" - it goes on the left of a
rule, C<< after('read_file') => answer('Done.') >>. C<tool> is the tool's
name: a string is compared exactly, a C<Regexp> is matched, and without it any
tool counts. C<result> does the same against the result's text. The captures
of the C<Regexp>s (the tool's first, then the result's) are passed to a
C<sub> reaction. Returns C<< { after => { tool => ..., result => ... } } >>.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Virtual> - The engine these rules drive, and the rule language

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
