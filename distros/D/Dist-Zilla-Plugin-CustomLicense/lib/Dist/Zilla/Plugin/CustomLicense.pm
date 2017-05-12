package Dist::Zilla::Plugin::CustomLicense;
BEGIN {
  $Dist::Zilla::Plugin::CustomLicense::VERSION = '1.0.2';
}
# ABSTRACT: setting legal stuff of Dist::Zilla while keeping control

use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

has filename => ( is => 'ro', isa => 'Str', default => 'LEGAL' );

sub before_build {
   my ($self) = @_;
   $self->zilla()->license()->load_sections_from($self->filename());
   return $self;
}

__PACKAGE__->meta()->make_immutable();
no Moose;
1;


=pod

=head1 NAME

Dist::Zilla::Plugin::CustomLicense - setting legal stuff of Dist::Zilla while keeping control

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This plugin allows using L<Software::License::Custom> to get software
licensing information from a custom file. In other terms, you can
specify C<Custom> in the license configuration inside L<dist.ini>:

   name     = Foo-Bar
   abstract = basic Bar for Foo
   author   = A.U. Thor <author@example.com>
   license  = Custom
   copyright_holder = A.U.Thor

By default the custom file
is F<LEGAL> in the main directory, but it can be configured with the
C<filename> option in the F<dist.ini> configuration file:

   [CustomLicense]
   filename = MY-LEGAL-ASPECTS

Unfortunately, as of the handover of L<Software::License::Custom> module it
seems that its documentation disappeared; see below
for details about how file F<LEGAL>
should be written. Most probably you will not want to include this file
in the final distro, so you should prune it out like this:

   [PruneFiles]
   filename = LEGAL

Of course you have to put any name you decided to call your file with!

=head1 WRITING THE LICENSE FILE

The default license file is F<LEGAL> in the main directory. Setting it
properly, you should be able to customise some aspects of the licensing
messages that would otherwise be difficult to tinker, e.g. adding a note
in the notice, setting multiple years for the copyright notice or set multiple
authors and/or copyright holders. See the L</COPYRIGHT AND LICENSE> section
below for an example of this.

The license file contains different sections. Each section has the
following format:

=over

=item *

header line

a line that begins and ends with two underscores C<__>. The string
between the begin and the end of the line is first depured of any
non-word character, then used as the name of the section;

=item *

body

a L<Text::Template> (possibly a plain text file) where items to be
expanded are enclosed between double braces.

=back

Each section is terminated by the header of the following section or by
the end of the file. Example:

   __[ NAME ]__
   The Foo-Bar License
   __URL__
   http://www.example.com/foo-bar.txt
   __[ META_NAME ]__
   foo_bar_meta
   __{ META2_NAME }__
   foo_bar_meta2
   __[ NOTICE ]__
   Copyright (C) 2000-2002 by P.R. Evious
   Copyright (C) {{$self->year}} by {{$self->holder}}.

   This is free software, licensed under {{$self->name}}.

   __[ LICENSE ]__
               The Foo-Bar License

   Well... this is only some sample text. I'm true... only sample text!!!

   Yes, spanning more lines and more paragraphs.

The different formats for specifying the section name in the example
above are only examples, you're invited to use a consistent approach.

The sections that you should include are the following:

=over

=item B<< NAME >>

The name of the license, suitable for shoving in the middle of a
sentence, generally with a leading capitalized "The".

=item B<< URL >>

The URL at which a canonical text of the license can be found,
if one is available. If possible, this will point at plain text,
but it may point to an HTML resource.

=item B<< META_NAME >>

The string that should be used for this license in the CPAN F<META.yml> file,
according to the CPAN Meta spec v1. Leave out if there is no known
string to use.

=item B<< META2_NAME >>

The string that should be used for this license in the CPAN F<META.json>
or F<META.yml> file, according to the CPAN Meta spec v2. Leave out 
if there is no known string to use; in this case, see L<Software::License>
to understand what will be used.

=item B<< NOTICE >>

A snippet of text, usually a few lines, indicating the copyright holder
and year of copyright, as well as an indication of the license under
which the software is distributed.

=item B<< LICENSE >>

The full text of the license, including customisation of any part of
it (e.g. a translation of some sections).

=back

The explanations in the list above has been munged from the documentation
of C<Software::License>.

=begin not_needed

=head2 before_build

Method required by L<Dist::Zilla::Role::BeforeBuild> for this plugin to work.


=end not_needed

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Flavio Poletti <polettix@cpan.org>.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut


__END__

