package Dist::Zilla::Plugin::AlienBase::Wrapper 0.27 {

  use 5.014;
  use Moose;
  use List::Util qw( first );

  # ABSTRACT: Use aliens in your Makefile.PL or Build.PL
  # VERSION


  with 'Dist::Zilla::Role::FileMunger',
       'Dist::Zilla::Role::PrereqSource';

  has alien => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
  );

  has _installer => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      my $name = first { /^(Build|Makefile)\.PL$/ } map { $_->name } @{ $self->zilla->files };
      $self->log_fatal('Unable to find Makefile.PL or Build.PL') unless $name;
      $name;
    },
  );

  around mvp_multivalue_args => sub {
    my($orig, $self) = @_;
    ($self->$orig, 'alien');
  };

  my $comment_begin  = "# BEGIN code inserted by @{[ __PACKAGE__ ]}\n";
  my $comment_end    = "# END code inserted by @{[ __PACKAGE__ ]}\n";

  sub register_prereqs
  {
    my($self) = @_;

    my $zilla = $self->zilla;

    $zilla->register_prereqs({
      phase => 'configure',
    }, 'Alien::Base::Wrapper' => '1.02' );

    foreach my $spec (@{ $self->alien })
    {
      my ($alien, $version) = split /\@/, $spec;
      $version //= "0";
      $zilla->register_prereqs({
        phase => 'configure',
      }, $alien => $version);
    }
  }

  sub munge_files
  {
    my($self) = @_;

    my @aliens = map { s/\@.*$//r }  @{ $self->alien };

    if($self->_installer eq 'Makefile.PL')
    {
      my $code = "use Alien::Base::Wrapper qw( @aliens !export );\n" .
                 "\%WriteMakefileArgs = (\%WriteMakefileArgs, Alien::Base::Wrapper->mm_args);\n";

      my $file = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
      my $content = $file->content;

      my $ok = $content =~ s/(unless \( eval \{ ExtUtils::MakeMaker)/"$comment_begin$code$comment_end\n\n$1"/e;
      $self->log_fatal('unable to find the correct location to insert prereqs')
        unless $ok;

      $file->content($content);
    }

    elsif($self->_installer eq 'Build.PL')
    {
      my $code = "use Alien::Base::Wrapper qw( @aliens !export );\n" .
                 "\%module_build_args = (\%module_build_args, Alien::Base::Wrapper->mb_args);\n";

      my $file = first { $_->name eq 'Build.PL' } @{ $self->zilla->files };
      my $content = $file->content;

      my $ok = $content =~ s/(unless \( eval \{ Module::Build)/"$comment_begin$code$comment_end\n\n$1"/e;
      $self->log_fatal('unable to find the correct location to insert prereqs')
        unless $ok;

      $file->content($content);
    }
    else
    {
      $self->log_fatal('unable to find Makefile.PL or Build.PL');
    }
  }

  __PACKAGE__->meta->make_immutable;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AlienBase::Wrapper - Use aliens in your Makefile.PL or Build.PL

=head1 VERSION

version 0.27

=head1 SYNOPSIS

 [AlienBase::Wrapper]
 alien = Alien::libfoo1@1.24
 alien = Alien::libfoo2

=head1 DESCRIPTION

This L<Dist::Zilla> plugin adjusts the C<Makefile.PL> or C<Build.PL> in your C<XS> project to
use L<Alien::Base::Wrapper> which allows you to use one or more L<Alien::Base> based L<Aliens>.

=head1 PROPERTIES

=head2 alien

List of aliens that you want to use in your XS code.  You ca suffix this with a at-version
to specify a minimum version requirement.  (Example C<Alien::Libarchive3@0.28>).

=head1 SEE ALSO

=over 4

=item L<Alien::Base>

=item L<Alien::Build::Manual::AlienUser>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
