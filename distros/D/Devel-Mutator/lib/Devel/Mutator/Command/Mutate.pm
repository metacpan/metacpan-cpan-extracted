package Devel::Mutator::Command::Mutate;

use strict;
use warnings;

use File::Find     ();
use File::Slurp    ();
use File::Path     ();
use File::Basename ();
use File::Spec;
use Devel::Mutator::Generator;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{recursive} = $params{recursive} || 0;
    $self->{verbose}   = $params{verbose}   || 0;
    $self->{root}      = $params{root}      || '.';
    $self->{generator} = $params{generator} || Devel::Mutator::Generator->new;

    return $self;
}

sub run {
    my $self = shift;
    my (@files) = @_;

    my $mutated = 0;
    my $mutants = 0;
    foreach my $file (@files) {
        if (-d $file && $self->{recursive}) {
            my @subfiles;

            File::Find::find(
                sub { push @subfiles, $File::Find::name if /\.p(?:m|l)$/; },
                $file);

            foreach my $subfile (@subfiles) {
                $mutants += $self->_mutate_file($subfile);
                $mutated++;
            }
        }
        elsif (-f $file) {
            $mutants += $self->_mutate_file($file);
            $mutated++;
        }
    }

    print "Mutated files: $mutated, mutants: $mutants\n";

    return $self;
}

sub _mutate_file {
    my $self = shift;
    my ($file) = @_;

    print "Reading $file ... \n" if $self->{verbose};
    my $content = File::Slurp::read_file($file);

    print "Generating mutants ... " if $self->{verbose};
    my @mutants = $self->{generator}->generate($content);

    print scalar(@mutants), "\n" if $self->{verbose};

    print "Saving mutants ... " if $self->{verbose};
    foreach my $mutant (@mutants) {
        my $new_path =
          File::Spec->catfile($self->{root}, 'mutants', $mutant->{id}, $file);

        File::Path::make_path(File::Basename::dirname($new_path));

        File::Slurp::write_file($new_path, $mutant->{content});
    }
    print "ok\n" if $self->{verbose};

    return scalar @mutants;
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Devel::Mutator::Command::Mutate - Module

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new>

=head2 C<run(@files)>

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
