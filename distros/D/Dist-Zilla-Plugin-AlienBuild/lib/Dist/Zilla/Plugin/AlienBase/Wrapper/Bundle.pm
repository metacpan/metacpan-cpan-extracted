package Dist::Zilla::Plugin::AlienBase::Wrapper::Bundle 0.33 {

  use 5.014;
  use Moose;
  use Path::Tiny ();
  use List::Util ();

  # ABSTRACT: Bundle a copy of Alien::Base::Wrapper with your dist
  # VERSION


  with 'Dist::Zilla::Role::FileGatherer',
       'Dist::Zilla::Role::PrereqSource',
       'Dist::Zilla::Role::FileMunger';

  has filename => (
    is  => 'ro',
    isa => 'Str',
    default => 'inc/Alien/Base/Wrapper.pm',
  );

  has system_check => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
  );

  has system => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
  );

  has alien => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
  );

  around mvp_multivalue_args => sub {
    my($orig, $self) = @_;
    ($self->$orig, 'alien', 'system', 'system_check' );
  };

  sub gather_files
  {
    my($self) = @_;

    require Alien::Base::Wrapper;
    unless(Alien::Base::Wrapper->VERSION('1.28'))
    {
      $self->log_fatal("requires Alien::Base::Wrapper 1.28, but we have @{[ Alien::Base::Wrapper->VERSION ]}");
    }

    my $content = Path::Tiny->new($INC{'Alien/Base/Wrapper.pm'})->slurp_utf8;

    my $file;

    $file = List::Util::first { $_->name eq $self->filename } @{ $self->zilla->files };

    if($file)
    {
      $file->content($content);
    }
    else
    {
      $file = Dist::Zilla::File::InMemory->new({
        name    => $self->filename,
        content => $content,
      });
      $self->add_file($file);
    }
  }

  my $comment_begin  = "# BEGIN code inserted by @{[ __PACKAGE__ ]}\n";
  my $comment_end    = "# END code inserted by @{[ __PACKAGE__ ]}\n";

  sub _string ($$)
  {
    my($indent, $array) = @_;
    join "\n", map { "$indent$_" } map { s/^\| //r } @$array;
  }

  sub munge_files
  {
    my($self) = @_;
    return unless defined $self->system_check;

    $self->log_fatal("system_check, but no system block") unless defined $self->system;

    my $system_check = _string '', $self->system_check;
    my $system       = _string '  ', $self->system;

    my $file = List::Util::first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
    $self->log_fatal("Makefile.PL not found") unless $file;

    my $code = "my \$system_install = $system_check;\n" .
               "if(\$system_install) {\n" .
               "$system\n" .
               "} else {\n";

    my @aliens;
    foreach my $spec (@{ $self->alien })
    {
      my ($alien, $version) = split /\@/, $spec;
      $version //= "0";
      $code .= "  \$WriteMakefileArgs{BUILD_REQUIRES}->{'$alien'} = \"$version\";\n";
      push @aliens, $alien;
    }

    $code .= "  \$WriteMakefileArgs{CC} = '\$(FULLPERL) -Iinc -MAlien::Base::Wrapper=@{[ join ',', @aliens ]} -e cc --';\n" .
             "  \$writeMakefileArgs{LD} = '\$(FULLPERL) -Iinc -MAlien::Base::Wrapper=@{[ join ',', @aliens ]} -e ld --';\n" .
             "}\n";

    my $content = $file->content;

    my $ok = $content =~ s/(unless \( eval \{ ExtUtils::MakeMaker)/"$comment_begin$code$comment_end\n\n$1"/e;
    $self->log_fatal('unable to find the correct location to insert prereqs')
      unless $ok;

    $file->content($content);
  }

  sub register_prereqs
  {
    my($self) = @_;

    $self->zilla->prereqs->requirements_for($_, 'requires')->clear_requirement('Alien::Base::Wrapper')
      for qw( configure build );
    return unless defined $self->system_check;
    $self->zilla->register_prereqs({ type => 'requires', phase => 'configure' }, 'ExtUtils::MakeMaker' => '6.52');
  }

  __PACKAGE__->meta->make_immutable;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AlienBase::Wrapper::Bundle - Bundle a copy of Alien::Base::Wrapper with your dist

=head1 VERSION

version 0.33

=head1 SYNOPSIS

 [AlienBase::Wrapper::Bundle]
 system_check = | do { # check for libfoo!
 system_check = |   use Devel::CheckLib qw( check_lib );
 system_check = |   check_lib( lib => [ 'foo' ] );
 system_check = | }
 
 system       = | # use libfoo!
 system       = | $WriteMakefileArgs{LIBS} = [ '-lfoo' ];
 
 alien        = Alien::libfoo

=head1 DESCRIPTION

B<NOTE>: This technique and plugin is EXPERIMENTAL.  Please visit us at #native on irc.perl.org
if you want to use this technique.

This module bundled L<Alien::Base::Wrapper> with your distribution, which allows for
late-binding fallback of an alien when a system probe fails.  It removes C<Alien::Base::Wrapper>
as a configure or build prerequisite if found, in case you have a plugin automatically computing
it as a prereq.  (Note that if the prereq is added after this plugin it won't be removed, so
be sure to use this plugin AFTER any auto prereqs plugin).

=head1 ATTRIBUTES

=head2 filename

This specifies the name of the bundled L<Alien::Base::Wrapper>, the default is
C<inc/Alien/Base/Wrapper.pm>.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curtis Jewell (CSJEWELL)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2025 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
