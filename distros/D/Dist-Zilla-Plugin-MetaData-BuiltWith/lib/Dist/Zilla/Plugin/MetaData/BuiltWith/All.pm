use 5.006;
use strict;
use warnings;

package Dist::Zilla::Plugin::MetaData::BuiltWith::All;

our $VERSION = '1.004005';

# ABSTRACT: Go overkill and report everything in all name-spaces.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( extends has around );
use namespace::autoclean;
extends 'Dist::Zilla::Plugin::MetaData::BuiltWith';






























































has 'show_failures' => ( is => 'ro', isa => 'Bool', default => 0 );

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $payload = $config->{ +__PACKAGE__ } = {};
  $payload->{show_failures} = $self->show_failures;
  $payload->{ q[$] . __PACKAGE__ . q[::VERSION] } = $VERSION unless __PACKAGE__ eq ref $self;
  return $config;
};

around '_metadata' => sub {
  my ( $orig, $self, @args ) = @_;
  my $stash = $self->$orig(@args);
  return { %{$stash}, %{ $self->_get_all() } };
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub _list_modules_in_memory {
  my ( $self, $package ) = @_;

  return $package if 'main' eq $package or $package =~ /\Amain::/msx;

  my $ns = do {
    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    \%{ $package . q{::} };
  };
  my (@child_namespaces);
  for my $child ( keys %{$ns} ) {
    next unless $child =~ /\A(.*)::$/msx;
    my $child_pkg = $1;
    $child_pkg = $package . q[::] . $child_pkg if $package;
    push @child_namespaces, $child_pkg;
  }

  return ( ( $package || () ), map { $self->_list_modules_in_memory($_) } @child_namespaces );
}

sub _get_all {
  my ($self) = @_;
  my %modtable;
  my %failures;

  for my $module ( $self->_list_modules_in_memory(q{}), $self->include ) {
    if ( $module =~ /\A__ANON__/msx ) {
      $failures{$module} = 'Skipped: Anonymous Class';
      next;
    }
    if ( $module =~ /\[/msx ) {
      $failures{$module} = 'Skipped: Parameterized Type';
      next;
    }
    my $result = $self->_detect_installed($module);

    $modtable{$module} = $result->[0] if defined $result->[0];
    $failures{$module} = $result->[1] if defined $result->[1];

  }

  for my $badmodule ( $self->exclude ) {
    delete $modtable{$badmodule} if exists $modtable{$badmodule};
    delete $failures{$badmodule} if exists $failures{$badmodule};
  }
  my $rval = { allmodules => \%modtable };
  $rval->{allfailures} = \%failures if keys %failures and $self->show_failures;
  return $rval;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaData::BuiltWith::All - Go overkill and report everything in all name-spaces.

=head1 VERSION

version 1.004005

=head1 SYNOPSIS

  [MetaData::BuiltWith::All]
  show_failures = 1 ; Not recommended

This module is otherwise identical to L<< C<MetaData::BuiltWith>|Dist::Zilla::Plugin::MetaData::BuiltWith >>.

=head1 DESCRIPTION

This further extends the verbosity of the information reported by the L<< C<BuiltWith>|Dist::Zilla::Plugin::MetaData::BuiltWith >> plug-in,
by recursively rooting around in the name-spaces and reporting every version of everything it finds.

Only recommended for the most extreme of situations where you find your code breaking all over the show between different versions of things, or for personal amusement.

=head1 OPTIONS

=head2 show_failures

Because this module reports B<ALL> C<namespaces>, it will likely report very many C<namespaces>
which simply do not exist on disk as a distinct file, and as a result, are unlikely to have C<$VERSION> data.

As a result, enabling this option will drop a mother load of failures into a hash somewhere in C<x_BuiltWith>.

For instance, there's one for every single package in C<B::>

And there's one for every single instance of C<Eval::Closure::Sandbox> named C<Eval::Closure::Sandbox_.*>

There's one for every instance of C<Module::Metadata> ( I spotted about 80 myself )

And there's one for each and every thing that uses C<__ANON__::>

You get the idea?

B<Do not turn this option on>

You have been warned.

=head2 exclude

Specify modules to exclude from version reporting

    exclude = Foo
    exclude = Bar

=head2 include

Specify additional modules to include the version of

    include = Foo
    include = Bar

=head2 show_config

Report "interesting" values from C<%Config::Config>

    show_config = 1 ; Boolean

=head2 show_uname

Report the output from C<uname>

    show_uname = 1 ; Boolean

=head2 uname_call

Specify what the system C<uname> function is called

    uname_call = uname ; String

=head2 uname_args

Specify arguments passed to the C<uname> call.

    uname_args = -a ; String

=head1 WARNING

At present this code does no recursion prevention, apart from excluding the C<main> name-space.

If it sees other name-spaces which recur into their self indefinitely ( like main does ), then it may not terminate normally.

Also, using this module will likely add 1000 lines to C<META.yml>, so please for the love of sanity don't use this too often.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
