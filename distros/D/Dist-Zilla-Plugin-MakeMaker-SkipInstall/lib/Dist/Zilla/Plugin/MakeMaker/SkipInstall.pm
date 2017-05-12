package Dist::Zilla::Plugin::MakeMaker::SkipInstall;
$Dist::Zilla::Plugin::MakeMaker::SkipInstall::VERSION = '1.201';
use Moose;
use File::Spec;

with 'Dist::Zilla::Role::AfterBuild';

has filename => (
  isa => 'Str',
  is  => 'ro',
  default =>  'Makefile.PL',
);

sub after_build {
  my ($self, $args) = @_;
  my $build_root = $args->{build_root};
  my $filename = File::Spec->catfile($build_root, $self->filename);
  
  my $content = _slurp($filename);
  my ($pre, $post) = split(/^\s*WriteMakefile[(]/sm, $content);
  $content = $pre
           . q{

exit 0 if $ENV{AUTOMATED_TESTING};
sub MY::install { "install ::\n" }

           }
           . "\nWriteMakefile("
           . $post;
  
  open(my $fh, '>', $filename) or Carp::croak("error opening file '$filename' for writing: $!");
  print $fh $content or Carp::croak("error writing to $filename: $!");
  close($fh) or Carp::croak("error closing $filename: $!");
}

sub _slurp {
  local $/;
  open(my $fh, '<', $_[0]) or Carp::croak("error opening file '$_[0]' for reading: $!");
  my $content = <$fh>;
  close($fh) or Carp::croak("error closing $_[0]: $!");

  return $content;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::MakeMaker::SkipInstall - skip the install rule of MakeMaker

=head1 VERSION

version 1.201

=head1 SYNOPSIS

In your C<dist.ini> file:

    [MakeMaker::SkipInstall]

=head1 DESCRIPTION

This small plugin will edit the C<Makefile.PL> file, and override the
install target to become a no-op.

This will make your module fail the install phase. It will be built, and
tested but will never be installed.

The most common use for this techinique is for L<Task> modules. Without
a proper install phase, you can install your Task module repetedly.


=head1 CREDITS

The technique was described by Marcel Gruenauer (hanekomu) in his
article "Repeatedly installing Task::* distributions":

L<http://hanekomu.at/blog/dev/20091005-1227-repeatedly_installing_task_distributions.html>

The author just wrapped the concept into a L<Dist::Zilla> plugin.


=head1 SEE ALSO

L<Dist::Zilla>.


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Melo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=begin make-pod-coverage-happy

=over 4

=item after_build()

Edits the C<Makefile.PL> in place, searches for C<WriteMakefile> and
prepends our override.

=back

=end make-pod-coverage-happy

=cut
