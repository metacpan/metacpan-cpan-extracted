package Dist::Zilla::Plugin::CoalescePod;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: merge .pod files into their .pm counterparts
$Dist::Zilla::Plugin::CoalescePod::VERSION = '1.0.0';
use strict;
use warnings;

use Moose;

with qw(
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::FilePruner
);

has _pod_files => (
   is      => 'rw',
   isa     => 'ArrayRef',
   default => sub { [] },
);

sub munge_file {
    my ( $self, $file ) = @_;

    # only look under /lib
    return unless $file->name =~ m#^lib/.*\.pm$#;

    ( my $podname = $file->name ) =~ s/\.pm$/.pod/;

    my ( $podfile ) = grep { $_->name eq $podname }
                           @{ $self->_pod_files } or return;

    $self->log( "merged " . $podfile->name . " into " . $file->name );

    my @content = ( $file->content );

    push @content, $1 if $content[0] =~ s/(^__DATA__.*)//ms;

    # inject the pod
    splice @content, 1, 0, $podfile->content;

    $file->content( join "\n\n", @content );
}

sub prune_files {
   my ($self) = @_;

   my @files = @{ $self->zilla->files };

   foreach my $file ( @files ) {
      next unless $file->name =~ m/\.pod$/;
      next if $file->name =~ /t\/corpus/;

      my $pm = $file->name =~ s/\.pod$/.pm/r;

      # only deal with pod files with associated pm files
      next unless grep { $_->name eq $pm } @files;

      push @{ $self->_pod_files }, $file;
      $self->zilla->prune_file($file);
   }
}

1;


#PODNAME: Foo

__END__

=pod

=encoding UTF-8

=head1 NAME

Foo - merge .pod files into their .pm counterparts

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    # in dist.ini
    [CoalescePod]

=head1 DESCRIPTION

If the files I<Foo.pm> and I<Foo.pod> both exist, the pod file is removed and
its content appended to the end of the C<.pm> file (or just before a
C<__DATA__> marker if present) 

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
