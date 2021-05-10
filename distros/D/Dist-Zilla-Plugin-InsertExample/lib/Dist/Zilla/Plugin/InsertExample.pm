use strict;
use warnings;
use 5.020;

package Dist::Zilla::Plugin::InsertExample 0.12 {

  use Moose;
  use Encode qw( encode );
  use List::Util qw( first );
  use experimental qw( signatures postderef );

  # ABSTRACT: Insert example into your POD from a file


  with 'Dist::Zilla::Role::FileMunger';
  with 'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ qw( :InstallModules :ExecFiles ) ],
  };

  has remove_boiler => (is => 'ro', isa => 'Int');
  has indent        => (is => 'ro', isa => 'Int', default => 1);

  sub munge_files ($self)
  {
    $self->munge_file($_) for $self->found_files->@*;
  }

  sub munge_file ($self, $file)
  {
    my $content = $file->content;
    if($content =~ s{^#\s*EXAMPLE:\s*(.*)\s*$}{$self->_slurp_example($1)."\n"}meg)
    {
      $self->log([ 'adding examples in %s', $file->name]);
      $file->content($content);
    }
  }

  sub _slurp_example ($self, $filename)
  {
    my $fh;

    if(my $file = first { $_->name eq $filename } $self->zilla->files->@*)
    {
      my $content = encode 'UTF-8', $file->content;
      open $fh, '<', \$content
        or $self->log_fatal("unable to open content of @{[ $file->name ]} as in memory string");
      binmode $fh, ':utf8';
    }
    elsif($file = $self->zilla->root->child($filename))
    {
      $self->log_fatal("no such example file $filename") unless -r $file;
      $fh = $file->openr_utf8;
    }

    my $indent = ' ' x $self->indent;

    while(my $line = <$fh>)
    {
      if($self->remove_boiler)
      {
        next if $line =~ /^\s*$/;
        next if $line =~ /^#!\/usr\/bin\/perl/;
        next if $line =~ /^#!\/usr\/bin\/env perl/;
        next if $line =~ /^use strict;$/;
        next if $line =~ /^use warnings;$/;
        return '' if eof $fh;
      }
      return join "\n", map { "$indent$_" } split /\n/, $line . do { local $/; my $rest = <$fh>; defined $rest ? $rest : '' };
    }

  }

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertExample - Insert example into your POD from a file

=head1 VERSION

version 0.12

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

=head2 indent

Specifies the number of spaces to indent by.  This is 1 by default,
because it is sufficient to force POD to consider it a verbatim
paragraph.  I understand a lot of Perl programmers out there prefer
4 spaces.  You can also set this to 0 to get no indentation at all
and it won't be a verbatim paragraph at all.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
