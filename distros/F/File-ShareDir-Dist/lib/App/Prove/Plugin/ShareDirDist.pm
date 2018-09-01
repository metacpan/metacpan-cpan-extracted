package App::Prove::Plugin::ShareDirDist;

use strict;
use warnings;
use 5.008001;
use File::Spec;
use File::Basename ();

# ABSTRACT: A prove plugin that works with File::ShareDir::Dist
our $VERSION = '0.07'; # VERSION


sub load
{
  my($class, $p) = @_;
  if(-d "share")
  {
    my $dist_name = File::Basename::basename(File::Spec->rel2abs("."));
    $ENV{PERL_FILE_SHAREDIR_DIST} = "$dist_name=share";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Plugin::ShareDirDist - A prove plugin that works with File::ShareDir::Dist

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 % prove -PShareDirDist -lv t

=head1 DESCRIPTION

This plugin sets the override for L<File::ShareDir::Dist> based on
the current directory name, if there is a C<share> directory.  It
assumes that the directory name is the same as the dist name.  This
may not be the case, but it happens to be the convention that I use.

=head1 SEE ALSO

=over 4

=item L<prove>

=item L<App::Prove>

=item L<Test::Harness>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Yanick Champoux (yanick)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017,2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
