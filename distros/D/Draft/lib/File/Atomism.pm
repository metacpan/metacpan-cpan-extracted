package File::Atomism;

=head1 NAME

File::Atomism - atomised directory file formats

=head1 SYNOPSIS

A directory containing a number of files that are used collectively
as a random access data store.

=head1 DESCRIPTION

An atomised directory can be identified by a F<DIRTYPE> file located in
the root, this file contains the type and version on the first line
(separated by the first whitespace) and an explanatory URL on the
second line.

Alternatively, atomised directories could be identified using
heuristics - The existence of cur/ new/ and tmp/ folders would
identify a Maildir.

Typically access to the individual files is provided via L<SGI::FAM>
which monitors file addition, changes or deletions.

=cut

use strict;
use warnings;

our $VERSION = 0.1;
our $EVENT = undef;

use vars qw /@ISA/;

=pod

=head1 USAGE

Create an atomised directory object like so:

    use File::Atomism;
    my $drawing = File::Atomism->new ('/path/to/drawing/');

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {}, $class;
    $self->{_path} = shift;

    open FILE, "<". $self->{_path} ."DIRTYPE" or warn $self->{_path} ." not found.\n";
    my @lines = <FILE>;
    close FILE;
    chomp for (@lines);
    $self->{_dirtype} = \@lines;

=pod

An attempt is made to reclass the object according to the "type".
For instance if the type is "protozoa", the object will be given the
class "File::Atomism::Protozoa".

=cut

    my $newclass = "File::Atomism::". $self->Type;
    eval "use $newclass";
    # FIXME should use bless to reclass as @ISA applies to all instances
    @ISA = eval "qw /$newclass/";

    return $self;
}

sub Capitalise
{
    my $self = shift;
    my $word = shift;
    my $first = substr ($word, 0, 1, '');
    return uc ($first) . lc ($word);
}

=pod

A canonicalised and sanitised "type" can be retrieved like so:

    my $type = $dir->Type;

The unsanitised version string (if it exists) can be retrieved
similarly:

    my $version = $dir->Version;

The explanatory URL can be accessed:

    my $description = $dir->Description;

=cut

sub Type
{
    my $self = shift;
    my $type = $self->{_dirtype}->[0] || 'protozoa';
    $type =~ s/ .*//;
    $type =~ s/[^a-z0-9_]//gi;
    $self->Capitalise ($type);
}

sub Version
{
    my $self = shift;
    my $version = $self->{_dirtype}->[0];
    return 0 unless $version =~ / [^ ]/;
    $version =~ s/^[^ ]+ //;
}

sub Description
{
    my $self = shift;
    $self->{_dirtype}->[1];
}

=head1 SEE ALSO

L<Draft>, L<File::Atomism::Protozoa>, L<SGI::FAM>

=head1 AUTHORS

=item *
Bruno Postle <bruno@postle.net>

=head1 COPYRIGHT

Copyright (c) 2004 Bruno Postle.  This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut


1;

