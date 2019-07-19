package Dist::Zilla::Plugin::Author::Plicease::NoUnsafeInc 2.37 {

  use 5.014;
  use Moose;

  # ABSTRACT: Set x_use_unsafe_inc = 0


  # Similar to [UseUnsafeInc], except, we don't require a recent Perl
  # for releases without a environment variable.  Risky!  But at
  # least not annoying.  We also don't provide an interface to setting
  # to 1.  Code should instead be fixed.

  with 'Dist::Zilla::Role::MetaProvider',
       'Dist::Zilla::Role::AfterBuild';
  
  use namespace::autoclean;

  sub metadata
  {
    my($self) = @_;
    return { x_use_unsafe_inc => 0 };
  }
  
  sub after_build
  {
    my($self) = @_;
    $ENV{PERL_USE_UNSAFE_INC} = 0;
  }
  
  __PACKAGE__->meta->make_immutable;

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::NoUnsafeInc - Set x_use_unsafe_inc = 0

=head1 VERSION

version 2.37

=head1 SYNOPSIS

 [Author::Plicease::NoUnsafeInc]

=head1 DESCRIPTION

Use C<[UseUnsafeInc]> with dot_in_INC set to 0 instead.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
