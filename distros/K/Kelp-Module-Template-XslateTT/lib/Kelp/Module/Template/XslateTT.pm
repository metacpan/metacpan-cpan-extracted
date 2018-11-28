package Kelp::Module::Template::XslateTT;

# $Id: XslateTT.pm 66 2018-11-21 18:22:53Z stro $

use strict;
use warnings;

use Kelp::Base 'Kelp::Module::Template::Xslate';
use Text::Xslate;

our $VERSION = 1.002;

attr ext => 'tt';

sub build_engine {
  my ($self, %args) = @_;
  $args{'syntax'} = 'TTerse';
  $args{'suffix'} = '.tt';
  Text::Xslate->new(%args);
}

=head1 NAME

Kelp::Module::Template::XslateTT - process .tt files with Text::Xslate

=head1 SYNOPSIS

config.yml:

  modules:
    Template::XslateTT
  modules_init:
    Template::XslateTT:
      path:
        - ./views
        - ../views

config.pl:

  'modules' => [ qw/ Template::XslateTT / ],
  'modules_init' => {
    'Template::XslateTT' => {
      'path' => [
        './views',
        '../views',
      ],
    },
  },

=head1 DESCRIPTION

Kelp::Module::Template::XslateTT is a drop-in replacement for Template-Tiny and Template-Toolkit engines in Kelp.
It allows to use faster Xslate template engine without modifying your templates, renaming files, or changing the code.
All you need is changing a few lines in your Kelp config file.

=head1 VERSION

1.002

=head1 AUTHOR

(c) 2018 Serguei Trouchelle E<lt>stro@cpan.orgE<gt>.

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Kelp>,
L<Text::Xslate>,
L<Kelp::Module::Template::Xslate>

=cut

1;
