package Dist::Zilla::Plugin::Author::Plicease::Cleaner 2.76 {

  use 5.020;
  use Moose;
  use Path::Tiny qw( path );
  use Scalar::Util qw( refaddr );
  use Class::Method::Modifiers qw( install_modifier );
  use experimental qw( signatures postderef );

  with 'Dist::Zilla::Role::Plugin';

  # ABSTRACT: Clean things up


  has clean => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
  );

  sub mvp_multivalue_args { qw( clean ) }

  sub BUILD ($self, $) {

    my @clean_list = qw(
      .tmp
      _alien
    );

    # rust:   target
    # zig:    zig-cache, zig-out
    # c:      *.o *.obj *.so *.dll *.dylib
    # Pascal: *.ppu
    foreach my $x (qw( target zig-cache zig-out *.o *.obj *.so *.dll *.dylib *.ppu))
    {
      push @clean_list, join('/', 'ffi', $x), join('/', 't/ffi', $x)
    }

    push @clean_list, $self->clean->@*;

    install_modifier 'Dist::Zilla::Dist::Builder', 'after', 'clean' => sub ($bld, $dry) {

      return unless refaddr($self->zilla) == refaddr($bld);

      foreach my $rule (@clean_list)
      {
        if($rule =~ m!/!)
        {
          foreach my $path (glob $rule =~ s!^/!!r)
          {
            next unless -e $path;
            $self->remove_file_or_dir($path, $dry);
          }
        }
        else
        {
          foreach my $path (glob "$rule")
          {
            next unless -e $path;
            $self->remove_file_or_dir($path, $dry);
          }
          Path::Tiny->new('.')->visit(sub {
            my $dir = shift;
            return unless -d $dir;
            foreach my $path (glob "$dir/$rule")
            {
              next unless -e $path;
              $self->remove_file_or_dir($path, $dry);
            }
          }, { recurse => 1 });
        }
      }

    };

    sub remove_file_or_dir ($self, $path, $dry)
    {
      if($dry)
      {
        $self->log("clean: would remove $path");
      }
      else
      {
        $self->log("clean: removing $path");
        if(-d $path)
        {
          Path::Tiny->new($path)->remove_tree;
        }
        elsif(-e $path)
        {
          Path::Tiny->new($path)->remove;
        }
        else
        {
          $self->log("clean: is neither a file nor directory? $path");
        }
      }
    }

  }

  __PACKAGE__->meta->make_immutable;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::Cleaner - Clean things up

=head1 VERSION

version 2.76

=head1 SYNOPSIS

 [Author::Plicease::Cleaner]
 clean = *.o

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::PluginBundle::Author::Plicease>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
