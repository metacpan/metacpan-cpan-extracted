package Dist::Zilla::Role::PrereqScanner 6.032;
# ABSTRACT: automatically extract prereqs from your modules

use Moose::Role;
with(
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_test_files',
    finder_arg_names => [ 'test_finder' ],
    default_finders  => [ ':TestFiles' ],
  },
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_configure_files',
    finder_arg_names => [ 'configure_finder' ],
    default_finders  => [],
  },
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_develop_files',
    finder_arg_names => [ 'develop_finder' ],
    default_finders  => [ ':ExtraTestFiles' ],
  },
);

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use MooseX::Types;

#pod =attr finder
#pod
#pod This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder>
#pod whose files will be scanned to determine runtime prerequisites.  It
#pod may be specified multiple times.  The default value is
#pod C<:InstallModules> and C<:ExecFiles>.
#pod
#pod =attr test_finder
#pod
#pod Just like C<finder>, but for test-phase prerequisites.  The default
#pod value is C<:TestFiles>.
#pod
#pod =attr configure_finder
#pod
#pod Just like C<finder>, but for configure-phase prerequisites.  There is
#pod no default value; AutoPrereqs will not determine configure-phase
#pod prerequisites unless you set configure_finder.
#pod
#pod =attr develop_finder
#pod
#pod Just like <finder>, but for develop-phase prerequisites.  The default value
#pod is C<:ExtraTestFiles>.
#pod
#pod =attr skips
#pod
#pod This is an arrayref of regular expressions, derived from all the 'skip' lines
#pod in the configuration.  Any module names matching any of these regexes will not
#pod be registered as prerequisites.
#pod
#pod =cut

has skips => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
);

around mvp_multivalue_args => sub {
  my ($orig, $self) = @_;
  ($self->$orig, 'skips')
};
around mvp_aliases => sub {
  my ($orig, $self) = @_;
  my $aliases = $self->$orig;
  $aliases->{skip}       = 'skips';
  return $aliases
};


requires 'scan_file_reqs';

sub scan_prereqs {
  my $self = shift;

  require CPAN::Meta::Requirements;
  require List::Util;
  List::Util->VERSION(1.45);  # uniq

  # not a hash, because order is important
  my @sets = (
    # phase => file finder method
    [ configure => 'found_configure_files' ], # must come before runtime
    [ runtime => 'found_files'      ],
    [ test    => 'found_test_files' ],
    [ develop => 'found_develop_files' ],
  );

  my %reqs_by_phase;
  my %runtime_final;
  my @modules;

  for my $fileset (@sets) {
    my ($phase, $method) = @$fileset;

    my $req   = CPAN::Meta::Requirements->new;
    my $files = $self->$method;

    foreach my $file (@$files) {
      # skip binary files
      next if $file->is_bytes;
      # parse only perl files
      next unless $file->name =~ /\.(?:pm|pl|t|psgi)$/i
               || $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
      # RT#76305 skip extra tests produced by ExtraTests plugin
      next if $file->name =~ m{^t/(?:author|release)-[^/]*\.t$};

      # store module name, to trim it from require list later on
      my @this_thing = $file->name;

      # t/lib/Foo.pm is treated as providing t::lib::Foo, lib::Foo, and Foo
      if ($this_thing[0] =~ /^t/) {
        push @this_thing, ($this_thing[0]) x 2;
        $this_thing[1] =~ s{^t/}{};
        $this_thing[2] =~ s{^t/lib/}{};
      } else {
        $this_thing[0] =~ s{^lib/}{};
      }
      s{\.pm$}{} for @this_thing;
      s{/}{::}g for @this_thing;

      # this is a bunk heuristic and can still capture strings from pod - the
      # proper thing to do is grab all packages from Module::Metadata
      push @this_thing, $file->content =~ /^[^#]*?(?:^|\s)package\s+([^\s;#]+)/mg;
      push @modules, @this_thing;

      # parse a file, and merge with existing prereqs
      $self->log_debug([ 'scanning %s for %s prereqs', $file->name, $phase ]);
      my $file_req = $self->scan_file_reqs($file);

      $req->add_requirements($file_req);

    }

    # remove prereqs from skiplist
    for my $skip (@{ $self->skips || [] }) {
      my $re   = qr/$skip/;

      foreach my $k ($req->required_modules) {
        $req->clear_requirement($k) if $k =~ $re;
      }
    }

    # remove prereqs shipped with current dist
    if (@modules) {
      $self->log_debug([
        'excluding local packages: %s',
        sub { join(', ', List::Util::uniq(@modules)) } ]
      )
    }
    $req->clear_requirement($_) for @modules;

    $req->clear_requirement($_) for qw(Config DB Errno NEXT Pod::Functions); # never indexed

    # we're done, return what we've found
    my %got = %{ $req->as_string_hash };
    if ($phase eq 'runtime') {
      %runtime_final = %got;
    } else {
      # do not test-require things required for runtime
      delete $got{$_} for
        grep { exists $got{$_} and $runtime_final{$_} ge $got{$_} }
        keys %runtime_final;
    }

    $reqs_by_phase{$phase} = \%got;
  }

  return \%reqs_by_phase
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PrereqScanner - automatically extract prereqs from your modules

=head1 VERSION

version 6.032

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 finder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder>
whose files will be scanned to determine runtime prerequisites.  It
may be specified multiple times.  The default value is
C<:InstallModules> and C<:ExecFiles>.

=head2 test_finder

Just like C<finder>, but for test-phase prerequisites.  The default
value is C<:TestFiles>.

=head2 configure_finder

Just like C<finder>, but for configure-phase prerequisites.  There is
no default value; AutoPrereqs will not determine configure-phase
prerequisites unless you set configure_finder.

=head2 develop_finder

Just like <finder>, but for develop-phase prerequisites.  The default value
is C<:ExtraTestFiles>.

=head2 skips

This is an arrayref of regular expressions, derived from all the 'skip' lines
in the configuration.  Any module names matching any of these regexes will not
be registered as prerequisites.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::AutoPrereqs>.

=head1 CREDITS

The role was provided by Olivier Mengué (DOLMEN) and Philippe Bruhat (BOOK) at Perl QA Hackathon 2016
(but it is just a refactor of the AutoPrereqs plugin).

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SEE ALSO
#pod
#pod L<Dist::Zilla::Plugin::AutoPrereqs>.
#pod
#pod =head1 CREDITS
#pod
#pod The role was provided by Olivier Mengué (DOLMEN) and Philippe Bruhat (BOOK) at Perl QA Hackathon 2016
#pod (but it is just a refactor of the AutoPrereqs plugin).
#pod
#pod =cut

