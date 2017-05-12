# $Id: Lexed.pm,v 1.14 2006/08/22 13:09:14 rousse Exp $

package Dict::Lexed;

=head1 NAME

Dict::Lexed - Lexed wrapper

=head1 VERSION

Version 0.2.2

=head1 DESCRIPTION

This module is a perl wrapper around Lexed, a lexicalizer developed at INRIA
(http://www.lionel-clement.net/lexed)

=head1 SYNOPSIS

    use Dict::Lexed;

    Dict::Lexed->create_dict($wordlist);

    my $dict = Dict::Lexed->new();

    $dict->check('foo');
    $dict->suggest('foo');

=cut

use IPC::Open2;
use IO::Handle;
use strict;
use warnings;

our $VERSION = '0.2.2';

my $unknown   = "\001";
my $delimiter = "\002";

=head1 Class methods

=head2 Dict::Lexed->create_dict(I<$wordlist>, I<$options>, I<$mode_options>)

Creates a dictionnary from I<$wordlist> suitable for use with lexed.

Optional parameters:

=over

=item I<$options>

general options passed to lexed

=item I<$mode_options>

specific build options passed to lexed

=back

=cut

sub create_dict {
    my ($class, $wordlist, $options, $mode_options) = @_;
    $options ||= "";
    $mode_options ||= "";
    my $command = "lexed $options build $mode_options 2>/dev/null";
    open(LEXED, "| $command") or die "Can't run $command: $!";
    foreach my $word (@{$wordlist}) {
        print LEXED $word . "\t" . $word . "\n";
    }
    close(LEXED);
}

=head1 Constructor

=head2 Dict::Lexed->new(I<$options>, I<$mode_options>)

Creates and returns a new C<Dict::Lexed> object.

Optional parameters:

=over

=item I<$options>

general options passed to lexed

=item I<$mode_options>

specific consultation options passed to lexed

=back

=cut

sub new {
    my ($class, $options, $mode_options) = @_;
    my $self = bless {
        _in  => IO::Handle->new(),
        _out => IO::Handle->new()
    }, $class;
    $options ||= "";
    $mode_options ||= "";
    my $command = "lexed $options consult -f '' '$delimiter' '\n' '$unknown' $mode_options 2>/dev/null";
    open2($self->{_out}, $self->{_in}, "$command") or die "Can't run $command: $!";
    return $self;
}

sub DESTROY {
    my ($self) = @_;
    # close external process handles
    $self->{_in}->close() if $self->{_in};
    $self->{_out}->close() if $self->{_out};
}

=head1 Methods


=head2 $dict->check(I<$word>)

Check the dictionnary for exact match of word I<$word>.
Returns a true value if word is present in the dictionnary, false otherwise.

=cut

sub check {
    my ($self, $word) = @_;

    my @query = $self->query($word);
    return (@query) ?
    grep { /^\Q$word\E$/ } @query :
    0;
}

=head2 $dict->suggest(I<$word>)

Check the dictionnary for approximate match of word I<$word>.
Returns a list of approximated words from the dictionnary, according to
parameters passed when creating the object.

=cut

sub suggest {
    my ($self, $word) = @_;

    my @query = $self->query($word);
    return (@query) ?
        grep { ! /^$word$/ } @query :
        ();
}

=head2 $dict->query(I<$word>)

Query the dictionnary for word I<$word>.
Returns the raw result of the query, as a list of words.

=cut

sub query {
    my ($self, $word) = @_;

    my ($in, $out) = ($self->{_in}, $self->{_out});
    print $in $word . "\n";
    my $line = <$out>;
    chomp $line;

    return $line eq $unknown ?
        () :
        split(/$delimiter/, $line);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, INRIA.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Guillaume Rousse <grousse@cpan.org>

=cut

1;
