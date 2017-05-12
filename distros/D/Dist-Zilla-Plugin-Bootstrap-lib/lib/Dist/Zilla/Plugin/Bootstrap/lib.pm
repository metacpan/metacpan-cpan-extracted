use 5.006;    # our
use strict;
use warnings;

## no critic ( NamingConventions::Capitalization )
package Dist::Zilla::Plugin::Bootstrap::lib;
## use critic;

our $VERSION = '1.001002';

# ABSTRACT: A minimal boot-strapping for Dist::Zilla Plug-ins.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moose qw( with around );
with 'Dist::Zilla::Role::Bootstrap';

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config    = $self->$orig(@args);
  my $localconf = {};

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION unless __PACKAGE__ eq ref $self;
  $config->{ +__PACKAGE__ } = $localconf if keys %{$localconf};
  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub bootstrap {
  my ($self) = @_;

  my $bootstrap_root = $self->_bootstrap_root;

  if ( not $bootstrap_root ) {
    return;
  }

  my $bootstrap_path = $bootstrap_root->child('lib');
  $self->_add_inc("$bootstrap_path");
  $self->log( [ 'Bootstrapping %s', "$bootstrap_path" ] );
  my $it = $bootstrap_path->iterator( { recurse => 1 } );

  while ( my $file = $it->() ) {
    next unless $file->basename =~ /[.]pm$/msx;
    my $rpath = $file->relative($bootstrap_path)->stringify;
    if ( exists $INC{$rpath} ) {
      $self->log( [ '%s was not bootstrapped. You need to move Bootstrap::lib higher', $rpath ] );
    }
  }

  return 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Bootstrap::lib - A minimal boot-strapping for Dist::Zilla Plug-ins.

=head1 VERSION

version 1.001002

=head1 SYNOPSIS

    [Bootstrap::lib]
    try_built   = 1  ; try using an existing built distribution named Dist-Name-*
    fallback    = 0  ; if try_built can't find a built distribution, or there's more than one, don't bootstrap
                     ; using lib/ instead

=head1 DESCRIPTION

This module exists for loading either C</lib> or C</Dist-Name-$VERSION/lib> into your C<@INC> early on.

This is mostly useful for writing L<< C<Dist::Zilla>|Dist::Zilla >> plug-ins, so that you may build and release
a plug-in using itself.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Bootstrap::lib",
    "interface":"class",
    "does":"Dist::Zilla::Role::Bootstrap"
}


=end MetaPOD::JSON

=head1 USE CASES

=head2 Simple single-phase self-dependency

This module really is only useful in the case where you need to use something like

    dzil -Ilib

For I<every> call to L<< C<Dist::Zilla>|Dist::Zilla >>, and this is mainly a convenience.

For that

    [Bootstrap::lib]

on its own will do the right thing.

=head2 Installed-Only self-dependency

The other useful case is when you would normally do

    dzil build                 # pass 1 that generates Foo-1.234 with a pre-installed Foo-1.233
    dzil -IFoo-1.234/lib build # pass 2 that generates Foo-1.234 with Foo-1.234

For that

    [Bootstap::lib]
    try_built   = 1
    fallback    = 0

Will do what you want.

    dzil build   # pass1 -> creates Foo-1.234 without bootstrapping
    dzil build   # pass2 -> creates Foo-1.234 boot-strapped from the previous build

=head2 2-step self-dependency

There's a 3rd useful case which is a hybrid of the 2, where you /can/ build from your own sources without needing a
pre-installed version, just you don't want that for release code ( e.g.: $VERSION being C<undef> in code that is run during
release is "bad" )

    [Bootstrap::lib]
    try_built = 1
    fallback  = 1

Then

    dzil build  # pass1 -> creates Foo-1.234 from bootstrapped $root/lib
    dzil build  # pass2 -> creates Foo-1.234 from bootstrapped $root/Foo-1.234

=head1 PRECAUTIONS

=head2 DO NOT

B<DO NOT> use this library from inside a bundle. It will not likely work as expected, and you B<DO NOT> want
to bootstrap everything in all cases.

=head2 NO VERSION

On its own,

    [Bootstrap::lib]

At present, using this module in conjunction with a module with no explicitly defined version in the
source will result in the I<executed> instance of that plug-in I<also> having B<NO VERSION>.

If this is a problem for you, then its suggested you try either variation of using

    [Bootstrap::lib]
    try_built = 1
    ; no_fallback = 1   #

=head2 SUCKS AT GUESSING

The core mechanism behind C<try_built> relies on looking in your project directory for a previous build directory of some kind.

And there's no way for it to presently pick a "best" version when there are more than one, or magically provide a better
solution if there are "zero" versions readily available.

This is mostly because there is no way to determine the "current" version we are building for, because the point in the
execution cycle is so early, no version plugins are likely to be even instantiated yet, and some version plugins are dependent on
incredibly complex precursors ( like git ), so by even trying to garner the version we're currently building, we could be
prematurely cutting off a vast majority of modules from even being able to bootstrap.

Even as it is, us using C<< zilla->name >> means that if your dist relies on some process to divine its name, the module that
does this must:

=over 4

=item * be loaded and declared prior to C<Bootstrap::lib> in the C<dist.ini>

=item * not itself be the module you are presently developing/bootstrapping

=back

The only way of working around that I can envision is adding parameters to C<Bootstrap::lib> to specify the dist name and version
name... but if you're going to do that, you may as well stop using external plugins to discover that, and hard-code those values
in C<dist.ini> to start with.

=head2 STILL NOT REALLY A PLUGIN

Starting at version 0.04000000 ( read: 0.04_0000_00 aka 0.04 + 0 x 4 + 0 x 2 ) this module is a fully fledged class, different
only from standard Dist::Zilla Plugins in that it doesn't partake in normal phase order, and only executes during a special
custom C<::Bootstrap> phase, which is more or less a different name and implementation of C<BUILD>, in that C<bootstrap> is
invoked after C<plugin_from_config> is called ( where C<new> is called ), which occurs somewhere in the middle of
C<register_component>

This module also appears on the plugin stash, and responds naturally to C<metaconfig> requests.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
