package Dist::Zilla::Util::AuthorDeps 6.032;
# ABSTRACT: Utils for listing your distribution's author dependencies

use Dist::Zilla::Pragmas;

use Dist::Zilla::Util;
use Path::Tiny;
use List::Util 1.45 ();

use namespace::autoclean;

sub format_author_deps {
  my ($reqs, $versions) = @_;

  my $formatted = '';
  foreach my $rec (@{ $reqs }) {
    my ($mod, $ver) = each(%{ $rec });
    $formatted .= $versions ? "$mod = $ver\n" : "$mod\n";
  }
  chomp($formatted);
  return $formatted;
}

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
  push(@packages, sort keys %{ $vermap });

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

    @packages =
      grep {
        $_ eq 'perl'
        ? ! ($vermap->{perl} && eval "use $vermap->{perl}; 1")
        : do {
            my $m = $_;
            ! eval {
              local @INC = @INC; push @INC, "$root";
              # This will die if module is missing
              Module::Runtime::require_module($m);
              my $v = $vermap->{$m};
              # This will die if VERSION is too low
              !$v || $m->VERSION($v);
              # Success!
              1
            }
          }
      } @packages;
  }

  # Now that we have a sorted list of packages, use that to build an array of
  # hashrefs for display.
  [ map { { $_ => $vermap->{$_} } } @packages ]
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::AuthorDeps - Utils for listing your distribution's author dependencies

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

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
