package File::RDir;
$File::RDir::VERSION = '0.02';
use strict;
use warnings;

use Carp qw(croak);

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(read_rdir) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

sub new {
    my $pkg = shift;
    my ($root, $opt) = @_;
    $root =~ s{\\}'/'xmsg;

    my @PList;

    if (ref($opt) eq 'HASH' and defined($opt->{'prune'})) {
        for (split m{;}xms, $opt->{'prune'}) {
            my ($item, $mod) = m{\A ([^:]*) : ([A-Z]*)\z}xmsi ? ($1, $2) : ($_, '');

            my $rstring = '';

            for my $frag (split m{([\*\?])}xms, $item) {
                if ($frag eq '*') {
                    $rstring .= '.*?';
                }
                elsif ($frag eq '?') {
                    $rstring .= '.';
                }
                else {
                    $rstring .= quotemeta($frag);
                }
            }

            push @PList, $mod =~ m{i}xmsi ? qr{\A $rstring \z}xmsi : qr{\A $rstring \z}xms;
        }
    }

    opendir my $hdl, $root or croak "Can't opendir '$root' because $!";

    my $self = { 'root' => $root, 'ndir' => '', 'dlist' => [], 'hdl' => $hdl, 'pl' => \@PList };

    bless $self, $pkg;
}

sub match {
    my $self = shift;
    return unless $self->{'hdl'};

    my $ele;
    my $full_dir = $self->{'root'}.$self->{'ndir'};

    LOOP1: {
        $ele = readdir $self->{'hdl'};

        unless (defined $ele) {
            closedir $self->{'hdl'};
            $self->{'hdl'} = undef;

            my $ndir = shift @{$self->{'dlist'}};
            last LOOP1 unless defined $ndir;

            $self->{'ndir'} = $ndir;

            $full_dir = $self->{'root'}.$self->{'ndir'};
            opendir $self->{'hdl'}, $full_dir or croak "Can't opendir '$full_dir' because $!";
            redo LOOP1;
        }

        my $full_ele = $full_dir.'/'.$ele;

        if (-d $full_ele) {
            redo LOOP1 if $ele eq '.' or $ele eq '..';

            for my $p (@{$self->{'pl'}}) {
                redo LOOP1 if $ele =~ $p;
            }

            push @{$self->{'dlist'}}, $self->{'ndir'}.'/'.$ele;
            redo LOOP1;
        }
    }

    return unless defined $ele;

    return $self->{'ndir'}.'/'.$ele;
}

sub read_rdir {
    my ($root, $opt) = @_;

    my @FList;

    my $iter = File::RDir->new($root, $opt);

    while (defined(my $file = $iter->match)) {
        push @FList, $file;
    }

    return @FList;
}

1;

__END__

=head1 NAME

File::RDir - List directories and recurse into subdirectories.

=head1 SYNOPSIS

  use File::RDir qw(read_rdir);

  my $iter = File::RDir->new('C:\Windows\System', { prune => '.git:i;dat*' });

  while (defined(my $file = $iter->match)) {
      # do stuff with $file...
  }

=head1 AUTHOR

Klaus Eichner, November 2015

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Klaus Eichner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
