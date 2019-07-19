package Dist::Zilla::Plugin::Author::Plicease::Thanks 2.37 {

  use 5.014;
  use Moose;

  with 'Dist::Zilla::Role::MetaProvider';
  with 'Dist::Zilla::Role::FileMunger';
  with 'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  };

  # ABSTRACT: munge the AUTHOR section


  has original => (
    is  => 'ro',
    isa => 'Str',
  );
  
  has current => (
    is  => 'ro',
    isa => 'Str',
  );
  
  has contributor => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
  );
  
  sub mvp_multivalue_args { qw( contributor ) }
  
  sub munge_files
  {
    my($self) = @_;
    $self->munge_file($_) for @{ $self->found_files };
  }
  
  sub _escape ($)
  {
    my($txt) = @_;
    my %map = qw(
      < lt
      > gt
    );
    $txt =~ s{([<>])}{E<$map{$1}>}g;
    $txt;
  }
  
  sub munge_file
  {
    my($self, $file) = @_;
    
    $self->log_fatal('requires at least current')
      unless $self->current;
    
    my $replacer = sub {
      my @list;
      push @list, '=head1 AUTHOR', '';
      if($self->original)
      {
        push @list, 'Original author: ' . _escape $self->original,
                    '',
                    'Current maintainer: ' . _escape $self->current,
                    '';
      }
      else
      {
        push @list, 'Author: ' . _escape $self->current,
                    '';
      }
      if(@{ $self->contributor } > 0)
      {
        push @list, 'Contributors:', '', map { (_escape $_, '') } @{ $self->contributor }; 
      }
      return join "\n", @list, '';
    };
    
    my $content = $file->content;
    unless($content =~ s{^=head1 AUTHOR.*(=head1 COPYRIGHT)}{$replacer->() . $1}sem)
    {
      $self->log_fatal('could not replace AUTHOR section');
    }
    $file->content($content);
    
    return;
  }
  
  sub metadata
  {
    my ($self) = @_;
  
    my @contributors = @{$self->contributor};
    unshift @contributors, $self->current  if $self->current;
    unshift @contributors, $self->original if $self->original;
  
    return +{ x_contributors => \@contributors };
  }
  
  __PACKAGE__->meta->make_immutable;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::Thanks - munge the AUTHOR section

=head1 VERSION

version 2.37

=head1 SYNOPSIS

 [Author::Plicease::Thanks]
 original = Original Author
 current = Current Maintainer
 contributor = Contributor One
 contributor = Contributor Two

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::PluginBundle::Author::Plicease>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
