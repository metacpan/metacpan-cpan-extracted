use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::lib;

our $VERSION = '0.001002';

# ABSTRACT: A simpler bootstrap for a more civilised world

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with around has );
use MooseX::Types::Moose qw( ArrayRef Str );
use Path::Tiny qw( path );
use lib qw();

with 'Dist::Zilla::Role::Plugin';






sub mvp_multivalue_args { return qw( lib ) }

has 'lib' => (
  is       => 'ro',
  isa      => ArrayRef [Str],
  required => 1,
);

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{lib} = $self->lib;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

# Injecting at init time
around plugin_from_config => sub {
  my ( $orig, $plugin_class, $name, $payload, $section ) = @_;
  my $instance = $plugin_class->$orig( $name, $payload, $section );
  my $root = path( $instance->zilla->root )->absolute;    # https://github.com/rjbs/Dist-Zilla/issues/579
  $instance->log_debug("zilla root: $root");

  lib->import(
    map { "$_" }
    grep { $_->is_dir ? 1 : ( $instance->log("library path \"$_\" does not exist or is not a directory"), undef ) }
    map { path($_)->absolute($root) } @{ $instance->lib || [] },
  );
  $instance->log_debug("\@INC is [@INC]");
  return $instance;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::lib - A simpler bootstrap for a more civilised world

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

  name = My-Dist
  author = Mr CPAN Person <person@cpan.example.org>
  license = Perl_5
  ...

  ; push ./inc into @INC
  [lib]
  lib = inc

  ; loads inc/My/GatherDir.pm
  [=My::GatherDir]

=head1 DESCRIPTION

Dist::Zilla::Plugin::lib serves as a relatively straight-forward and
uncomplicated way to wire certain local paths in your distributions
source tree into Perl's C<@INC> library load path.

Its primary audiences are twofold.

=over 4

=item Self-Building Dist::Zilla Plugins

Many recent L<Dist::Zilla|Dist::Zilla> plugin workflows champion a
state of C<lib/> which are usable "as is" without needing to cycle
through a C<dzil build> phase first, and this plugin offers a simple
way to stash C<lib/> in C<@INC> without needing to pass C<-Ilib> every
time you run C<dzil>.

Workflows that require a build cycle to self-build should use
L<< C<[Bootstrap::lib]>|Dist::Zilla::Plugin::Bootstrap::lib >> instead.

=item Bundled Dist::Zilla Plugins

Many heavy C<CPAN> distributions have bundled within them custom C<Dist::Zilla>
plugins stashed in C<inc/>

Traditionally, these are loaded via C<[=inc::Foo::Package]> exploiting
the long held assumption that C<"."> ( C<$CWD> ) is contained in C<@INC>

However, that is becoming a L<less safe assumption|/RELATED READING>, and this
plugin aims to make such equivalent behaviour practical without needing to
rely on that assumption.

=back

=for Pod::Coverage mvp_multivalue_args

=head1 USAGE

Inserting a section in your C<dist.ini> as follows:

  [lib]
  lib = some/path

  [=Some::Plugin]

  [Some::Other::Plugin]

Will prepend C<some/path> (relative to your distribution root) into
C<@INC>, and allow loading of not just plugins, but plugin dependencies
from the designated path.

C<[=Some::Plugin]> will be able to load, as per existing C<Dist::Zilla> convention,
via C<inc/Some/Plugin.pm>, and then fall back to searching other C<@INC> paths.

C<[Some::Other::Plugin]> will B<also> be able to load from C<inc/>,
via C<inc/Dist/Zilla/Plugin/Some/Other/Plugin.pm>

=head1 Ensuring dot-in-INC

Its not sure when C<"."> in C<@INC> will actually go away, or which parts of the C<dzil>
ecosystem will be re-patched to retain this assumption.

But the simplest thing that would work with changing the least amount of code would be
simply inserting

  [lib]
  lib = .

Early in your C<dist.ini>

This will have a C<mostly> the same effect as retaining C<dot-in-INC> even in the
event you run on a newer Perl where that is removed by default.

The differences however are subtle and maybe better depending on what you're doing

=over 4

=item * C<"."> will be prepended to C<@INC>, not appended.

This means C<[=inc::Foo]> will actually hit C<inc/> first, not simply as an afterthought
if it isn't found in other paths in C<@INC>

For instance, currently, I could create a lot of havoc by simply shipping a C<dzil> plugin with
the same name as somebody already is using for their private C<inc/> hacks, and then trip them
into installing it. Because currently, C<site beats "."> where authors intended to source
from C<"."> not C<site>

=item * C<"."> will be absolutized to C<< $zilla->root >>

As it stands, the C<"."> in C<@INC> is only ever C<".">, which means calling
C<chdir> between calls to C<require> effectively changes what C<@INC> means.

Given that is the specific threat surface for that issue, it would be silly
to repeat that mistake, especially as when you write C<"."> you typically want to
imply "Where I am now" not "Wherever the code will be 30 seconds after now after
it C<chdir>s to random locations at the discretion of code I haven't even read"

There's still some annoying scope for this absolutization going wrong,
due to C<Dist::Zilla> not L<< ensuring this path is fixed early on|https://github.com/rjbs/Dist-Zilla/issues/579 >>
but C<[lib]> fixes and absolutizes it as early as possible,
with the hope we'll know what you meant by C<cwd> before somebody can change C<cwd>

( And if that fails, it will fail spectacularly, not selectively work some of the
time if your stars align )

=back

=head1 Migrating from dot-in-INC code

If you have existing code that relies on the C<.>-in-C<@INC> assumption,
migrating to use this plugin in way that would seem "proper" would play as follows:

=over 4

=item 1. Rename your plugins in C<inc/>

All those packages called C<inc::Some::Plugin> become
C<Some::Plugin>

=item 2. Replace your section lines

C<inc> is no longer needed as part of the plugin, so
replacing all sections

  -[=inc::Some::Plugin]
  +[=Some::Plugin]

In line with step 1.

=item 3. Add a C<[lib]> section before all your plugins

And tell it to assume that C<inc/> is now in the load path.

  +[lib]
  +lib = inc

=back

=head1 ATTRIBUTES

=head2 C<lib>

This attribute can be specified 1 or more times, each time specifying
a path which will be assumed to be a path relative to C<< $zilla->root >>

Paths specified will be passed to L<< C<lib.pm>|lib >>C<< ->import >> in the
same order as they appear in your configuration, after absolutizing them.

C<lib.pm> prepends the values to C<< @INC >> in a nature akin to

  unshift(@INC, @{ $lib })

Which is functionally similar to:

  @INC = ( @{ $lib }, @INC )

That is, retaining the specified order in C< @INC >.

=head1 RELATED READING

=head2 C<dot-in-INC>

=over 4

=item * L<< Todd Rinaldo - How removing C<"."> from C<@INC> is about to break CPAN|http://blogs.perl.org/users/todd_rinaldo/2016/11/how-removing-from-inc-is-about-to-break-cpan.html >>

=item * L<< Todd Rinaldo - What happened to C<"."> in C<@INC>|http://blogs.perl.org/users/todd_rinaldo/2016/11/what-happened-to-dot-in-inc.html >>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
