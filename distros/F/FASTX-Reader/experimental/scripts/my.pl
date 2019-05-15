#!/usr/bin/perl
use warnings;
use strict;

{   package My::Class;
    use Moose;

    has filename => (is => 'ro', isa => 'Str', required => 1);
    has fh => (is => 'rw', isa => 'FileHandle', lazy => 1, builder => '_build_fh');
    #                                           ~~~~~~~~~

    sub _build_fh {
        my ($self) = @_;
        open my $fh, '<', $self->filename or die $!;
        return $fh
    }
}

my $o = 'My::Class'->new(filename => $ARGV[0]);
print while readline $o->fh;
