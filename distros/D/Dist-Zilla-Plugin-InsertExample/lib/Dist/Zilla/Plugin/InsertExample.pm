package Dist::Zilla::Plugin::InsertExample;

use strict;
use warnings;
use Moose;
use Path::Class qw( dir );
use List::Util qw( first );

# ABSTRACT: Insert example into your POD from a file
our $VERSION = '0.07'; # VERSION


with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::FileFinderUser' => {
  default_finders => [ qw( :InstallModules :ExecFiles ) ],
};

has remove_boiler => (is => 'ro', isa => 'Int');

sub munge_files
{
  my($self) = @_;
  $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file
{
  my($self, $file) = @_;

  my $content = $file->content;
  if($content =~ s{^#\s*EXAMPLE:\s*(.*)\s*$}{$self->_slurp_example($1)."\n"}meg)
  {
    $self->log([ 'adding examples in %s', $file->name]);
    $file->content($content);
  }
}

sub _slurp_example
{
  my($self, $filename) = @_;

  my $fh;

  if(my $file = first { $_->name eq $filename } @{ $self->zilla->files })
  {
    my $content = $file->content;
    open $fh, '<', \$content;
  }
  elsif($file = dir($self->zilla->root)->file($filename))
  {
    $self->log_fatal("no such example file $filename") unless -r $file;
    $fh = $file->openr;  
  }

  while(<$fh>)
  {
    if($self->remove_boiler)
    {
      next if /^\s*$/;
      next if /^#!\/usr\/bin\/perl/;
      next if /^use strict;$/;
      next if /^use warnings;$/;
      return '' if eof $fh;
    }
    return join "\n", map { " $_" } split /\n/, $_ . do { local $/; my $rest = <$fh>; defined $rest ? $rest : '' };
  }

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertExample - Insert example into your POD from a file

=head1 VERSION

version 0.07

=head1 SYNOPSIS

In your dist.ini:

 [InsertExample]

In your POD:

 =head1 EXAMPLE
 
 Here is an exaple that writes hello world to the terminal:
 
 # EXAMPLE: example/hello.pl

File in your dist named example/hello.pl

 #!/usr/bin/perl
 say 'hello world';

After dzil build your POD becomes:

 =head1 EXAMPLE
 
 Here is an example that writes hello world to the terminal:
 
  #!/usr/bin/perl
  say 'hello world';

and example/hello.pl is there too (unless you prune it with another
plugin).

=head1 DESCRIPTION

This plugin takes examples included in your distribution and
inserts them in your POD where you have an EXAMPLE directive.
This allows you to keep a version in the distribution which
can be run by you and your users, as well as making it
available in your POD documentation, without the need for 
updating example scripts in multiple places.

When the example is inserted into your pod a space will be appended
at the start of each line so that it is printed in a fixed width
font.

This plugin will first look for examples in the currently
building distribution, including generated and munged files.
If no matching filename is found, it will look in the distribution
source root.

=head1 OPTIONS

=head2 remove_boiler

Remove the C<#!/usr/bin/perl>, C<use strict;> or C<use warnings;> from
the beginning of your example before inserting them into the POD.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
