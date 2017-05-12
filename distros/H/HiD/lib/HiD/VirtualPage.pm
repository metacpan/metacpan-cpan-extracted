# ABSTRACT: Pages injected during the build process that don't have corresponding files


package HiD::VirtualPage;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::VirtualPage::VERSION = '1.98';
use Moose;
use namespace::autoclean;

use 5.014; # strict, unicode_strings
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;

use Path::Tiny;


has output_filename => (
  is       => 'ro' ,
  isa      => 'Str' ,
  required => 1 ,
);

has content => (
  is       => 'ro' ,
  isa      => 'Str' ,
  required => 1 ,
);


sub publish {
  my $self = shift;

  my $out = path( $self->output_filename );
  my $dir = $out->parent;

  $dir->mkpath() unless $dir->is_dir;

  $out->spew_utf8( $self->content );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::VirtualPage - Pages injected during the build process that don't have corresponding files

=head1 SYNOPSIS

    my $page = HiD::VirtualPage->new({
      output_filename => 'path/to/output/file' ,
      content         => 'content to go into file',
    });

=head1 DESCRIPTION

Class representing a virtual "page" object -- that is, a page that will be
generated during the publishing process, but that doesn't have a direct
on-disk component or input prior to that. VirtualPages need to have their
content completely built and provided at the time they are
instantiated. Examples would be Atom and RSS feeds.

=head1 ATTRIBUTES

=head2 output_filename

=head1 METHODS

=head2 publish

Publish -- write out to disk -- this data from this object.

=head1 VERSION

version 1.98

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
