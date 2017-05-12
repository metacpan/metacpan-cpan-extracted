# $Id: FSA.pm,v 1.8 2006/08/22 13:11:43 rousse Exp $

package Dict::FSA;

=head1 NAME

Dict::FSA - FSA wrapper

=head1 VERSION

Version 0.1.2

=head1 DESCRIPTION

This module is a perl wrapper around fsa, a set of tools based on finite
state automata (http://www.eti.pg.gda.pl/~jandac/fsa.html).

=head1 SYNOPSIS

    use Dict::FSA;

    Dict::FSA->create_dict($wordlist, $file);

    my $dict = Dict::FSA->new();

    $dict->check('foo');
    $dict->suggest('foo');

=cut

use IPC::Open2;
use IO::Handle;
use strict;
use warnings;

our $VERSION = '0.1.2';

=head1 Class methods

=head2 Dict::FSA->create_dict(I<$wordlist>, I<$file>)

Creates a dictionnary from I<$wordlist> suitable for use with fsa, and save
it in file I<$file>.

=cut

sub create_dict {
    my ($class, $wordlist, $file) = @_;
    open(FSA, "| fsa_ubuild > $file") or die "Can't run fsa_ubuild: $!";
    print FSA join("\n", @{$wordlist});
    close(FSA);
}

=head1 Constructor

=head2 Dict::FSALexed->new(I<$distance>, I<$wordfiles>)

Creates and returns a new C<Dict::FSA> object.

Optional parameters:

=over

=item I<$distance>

maximum distance for approximated matches

=item I<$wordfiles>

an hashref of word file to use

=back

=cut

sub new {
    my ($class, $distance, $wordfiles) = @_;
    my $self = bless {
        _in  => IO::Handle->new(),
        _out => IO::Handle->new()
    }, $class;
    my $command = "fsa_spell -f -e $distance " . join(" ", map { "-d $_" } @{$wordfiles});
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
    return ($query[0] eq '*not found*') ?
        0 :
        grep { /^$word$/ } @query;
}

=head2 $dict->suggest(I<$word>)

Check the dictionnary for approximate match of word I<$word>.
Returns a list of approximated words from the dictionnary, according to
parameters passed when creating the object.

=cut

sub suggest {
    my ($self, $word) = @_;

    my @query = $self->query($word);
    return ($query[0] eq '*not found*') ?
        () :
        grep { ! /^$word$/ } @query;
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

    $line =~ s/^$word: //;
    $line =~ tr/^/ /;
    my %seen;
    return grep { ! $seen{$_}++ } split(/, /, $line);
}

1;
