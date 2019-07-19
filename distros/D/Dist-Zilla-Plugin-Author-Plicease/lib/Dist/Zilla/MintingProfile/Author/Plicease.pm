package Dist::Zilla::MintingProfile::Author::Plicease 2.37 {

  use 5.014;
  use Moose;
  with qw( Dist::Zilla::Role::MintingProfile );
  use namespace::autoclean;
  use File::ShareDir::Dist ();
  use Path::Tiny ();
  use Carp ();

  # ABSTRACT: Minting profile for Plicease


  sub profile_dir
  {
    my($self, $profile_name) = @_;
  
    # use a dist share instead of a class share
  
    my $dir1 = Path::Tiny->new( File::ShareDir::Dist::dist_share( 'Dist-Zilla-Plugin-Author-Plicease' ) );
    
    my $dir2 = defined $profile_name
      ? $dir1->child("profiles/$profile_name")
      : $dir1->child("profiles");
  
    return $dir2 if -d $dir2;
  
    Carp::confess "Can't find profile $profile_name via $self";
  }

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Author::Plicease - Minting profile for Plicease

=head1 VERSION

version 2.37

=head1 SYNOPSIS

 dzil new -P Author::Plicease Module::Name

=head1 DESCRIPTION

This is the normal minting profile used by Plicease.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
