package Dist::Zilla::Util::AuthorDeps 6.036;
# ABSTRACT: Utils for listing your distribution's author dependencies

use Dist::Zilla::Pragmas;

use Dist::Zilla::Util;
use Path::Tiny;
use List::Util 1.45 ();

use namespace::autoclean;

#pod =func extract_author_deps
#pod
#pod   my $prereqs = extract_author_deps($dist_root, $missing_only);
#pod
#pod This returns a reference to an array in the form:
#pod
#pod   [
#pod     { $module1 => $ver1 },
#pod     { $module2 => $ver2 },
#pod     ...
#pod   ]
#pod
#pod Each entry is one of the likely author dependencies for the distribution at the
#pod root path C<$dist_root>.  If C<$missing_only> is true, then prereqs that appear
#pod to be available under the running perl will not be included.
#pod
#pod I<This function is not really meant to be reliable.>  It was undocumented and
#pod subject to change at any time, but some downstream libraries chose to use it
#pod anyway.  I may provide a replacement, at some point, at which point this method
#pod will be deprecated and begin issuing a warning.  I have documented this method
#pod only to provide this warning!
#pod
#pod =cut

sub extract_author_deps {
  my ($root, $missing) = @_;

  my $ini = path($root, 'dist.ini');

  die "dzil authordeps only works on dist.ini files, and you don't have one\n"
    unless -e $ini;

  my $fh = $ini->openr_utf8;

  require Config::INI::Reader;
  my $config = Config::INI::Reader->read_handle($fh);

  require CPAN::Meta::Requirements;
  my $reqs = CPAN::Meta::Requirements->new;

  if (defined (my $license = $config->{_}->{license})) {
    $license = 'Software::License::'.$license;
    $reqs->add_minimum($license => 0);
  }

  for my $section ( sort keys %$config ) {
    if (q[_] eq $section) {
      my $version = $config->{_}{':version'};
      $reqs->add_minimum('Dist::Zilla' => $version) if $version;
      next;
    }

    my $pack = $section;
    $pack =~ s{\s*/.*$}{}; # trim optional space and slash-delimited suffix

    my $version = 0;
    $version = $config->{$section}->{':version'} if exists $config->{$section}->{':version'};

    my $realname = Dist::Zilla::Util->expand_config_package_name($pack);
    $reqs->add_minimum($realname => $version);
  }

  seek $fh, 0, 0;

  my $in_filter = 0;
  while (<$fh>) {
    next unless $in_filter or /^\[\s*\@Filter/;
    $in_filter = 0, next if /^\[/ and ! /^\[\s*\@Filter/;
    $in_filter = 1;

    next unless /\A-bundle\s*=\s*([^;\s]+)/;
    my $pname = $1;
    chomp($pname);
    $reqs->add_minimum(Dist::Zilla::Util->expand_config_package_name($1) => 0)
  }

  seek $fh, 0, 0;

  my @packages;
  while (<$fh>) {
    chomp;
    next unless /\A\s*;\s*authordep\s*(\S+)\s*(?:=\s*([^;]+))?\s*/;
    my $module = $1;
    my $ver = $2 // "0";
    $ver =~ s/\s+$//;
    # Any "; authordep " is inserted at the beginning of the list
    # in the file order so the user can control the order of at least a part of
    # the plugin list
    push @packages, $module;
    # And added to the requirements so we can use it later
    $reqs->add_string_requirement($module => $ver);
  }

  my $vermap = $reqs->as_string_hash;
  # Add the other requirements
  push @packages, sort keys %$vermap;

  # Move inc:: first in list as they may impact the loading of other
  # plugins (in particular local ones).
  # Also order inc:: so that those that want to hack @INC with inc:: plugins
  # can have a consistent playground.
  # We don't sort the others packages to preserve the same (random) ordering
  # for the common case (no inc::, no '; authordep') as in previous dzil
  # releases.
  @packages = ((sort grep /^inc::/, @packages), (grep !/^inc::/, @packages));
  @packages = List::Util::uniq(@packages);

  if ($missing) {
    require Module::Runtime;

    my @new_packages;
    PACKAGE: for my $package (@packages) {
      if ($package eq 'perl') {
        # This is weird, perl can never really be a prereq to fulfill but...
        # it was like this. -- rjbs, 2024-06-02
        if ($vermap->{perl} && ! eval "use $vermap->{perl}; 1") {
          push @new_packages, 'perl';
        }

        next PACKAGE;
      }

      my $ok = eval {
        local @INC = (@INC, "$root");

        # This will die if module is missing
        Module::Runtime::require_module($package);
        my $v = $vermap->{$package};

        # This will die if VERSION is too low
        !$v || $package->VERSION($v);

        # Success!
        1;
      };

      unless ($ok) {
        push @new_packages, $package;
      }
    }

    @packages = @new_packages;
  }

  # Now that we have a sorted list of packages, use that to build an array of
  # hashrefs for display.
  [ map { { $_ => $vermap->{$_} } } @packages ]
}

#pod =func format_author_deps
#pod
#pod   my $string = format_author_deps($prereqs, $include_versions);
#pod
#pod Given a reference to an array in the format returned by C<extract_author_deps>,
#pod this returns a string in the form:
#pod
#pod   Module::One
#pod   Module::Two
#pod   Module::Three
#pod
#pod or, if C<$include_versions> is true:
#pod
#pod   Module::One = 1.00
#pod   Module::Two = 1.23
#pod   Module::Three = 8.910213
#pod
#pod I<This function is not really meant to be reliable.>  It was undocumented and
#pod subject to change at any time, but some downstream libraries chose to use it
#pod anyway.  I may provide a replacement, at some point, at which point this method
#pod will be deprecated and begin issuing a warning.  I have documented this method
#pod only to provide this warning!
#pod
#pod =cut

sub format_author_deps {
  my ($prereqs, $versions) = @_;
  return _format_author_deps($prereqs, $versions);
}

sub _format_author_deps {
  my ($prereqs, $versions, $cpanm_versions) = @_;

  my $formatted = '';
  for my $rec (@$prereqs) {
    my ($mod, $ver) = %$rec;
    $formatted .= $cpanm_versions ? "$mod~$ver\n"
                : $versions       ? "$mod = $ver\n"
                :                   "$mod\n";
  }

  chomp $formatted;

  return $formatted;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::AuthorDeps - Utils for listing your distribution's author dependencies

=head1 VERSION

version 6.036

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

=head1 FUNCTIONS

=head2 extract_author_deps

  my $prereqs = extract_author_deps($dist_root, $missing_only);

This returns a reference to an array in the form:

  [
    { $module1 => $ver1 },
    { $module2 => $ver2 },
    ...
  ]

Each entry is one of the likely author dependencies for the distribution at the
root path C<$dist_root>.  If C<$missing_only> is true, then prereqs that appear
to be available under the running perl will not be included.

I<This function is not really meant to be reliable.>  It was undocumented and
subject to change at any time, but some downstream libraries chose to use it
anyway.  I may provide a replacement, at some point, at which point this method
will be deprecated and begin issuing a warning.  I have documented this method
only to provide this warning!

=head2 format_author_deps

  my $string = format_author_deps($prereqs, $include_versions);

Given a reference to an array in the format returned by C<extract_author_deps>,
this returns a string in the form:

  Module::One
  Module::Two
  Module::Three

or, if C<$include_versions> is true:

  Module::One = 1.00
  Module::Two = 1.23
  Module::Three = 8.910213

I<This function is not really meant to be reliable.>  It was undocumented and
subject to change at any time, but some downstream libraries chose to use it
anyway.  I may provide a replacement, at some point, at which point this method
will be deprecated and begin issuing a warning.  I have documented this method
only to provide this warning!

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
