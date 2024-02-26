package Devel::Confess::Source::Patch::ExcludePackage;

use 5.010001;
use strict;
no warnings;

use Module::Patch;
use base qw(Module::Patch);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-06'; # DATE
our $DIST = 'Devel-Confess-Source-Patch-ExcludePackage'; # DIST
our $VERSION = '0.002'; # VERSION

our %config;

my $want_color = $^O ne 'MSWin32' ? 1 : eval {
  require Win32::Console::ANSI;
  Win32::Console::ANSI->import;
  1;
};

my $p_source_trace = sub {
  my ($skip, $context, $evalonly) = @_;
  $skip ||= 1;
  $skip += $Carp::CarpLevel;
  $context ||= 3;
  my $i = $skip;
  my @out;
  while (my ($pack, $file, $line) = (caller($i++))[0..2]) {
      next
          if $Carp::Internal{$pack} || $Carp::CarpInternal{$pack};
      next
          if $evalonly && $file !~ /^\(eval \d+\)(?:\[|$)/;
      if (defined $config{-exclude_pat} && $pack =~ /$config{-exclude_pat}/) {
          $context .= "Skipped stack trace level (package $pack excluded)\n" if $config{-show_excluded};
          next;
      }
      if (defined $config{-include_pat} && $pack !~ /$config{-include_pat}/) {
          $context .= "Skipped stack trace level (package $pack not included)\n" if $config{-show_excluded};
          next;
      }
      die;
    my $lines = _get_content($file) || next;

    my $start = $line - $context;
    $start = 1 if $start < 1;
    $start = $#$lines if $start > $#$lines;
    my $end = $line + $context;
    $end = $#$lines if $end > $#$lines;

    my $context = "context for $file line $line:\n";
    for my $read_line ($start..$end) {
      my $code = $lines->[$read_line];
      $code =~ s/\n\z//;
      if ($want_color && $read_line == $line) {
        $code = "\e[30;43m$code\e[m";
      }
      $context .= sprintf "%5s : %s\n", $read_line, $code;
    }
    push @out, $context;
  }
  return ''
    if !@out;
  return join(('=' x 75) . "\n",
    '',
    join(('-' x 75) . "\n", @out),
    '',
  );
};

sub patch_data {
    return {
        v => 3,
        config => {
            -exclude_pat => {
                schema => 're*',
            },
            -include_pat => {
                schema => 're*',
            },
            -show_excluded => {
                schema => 'bool*',
            },
        },
        patches => [
            {
                action      => 'replace',
                sub_name    => 'source_trace',
                code        => $p_source_trace,
            },
        ],
   };
}

1;
# ABSTRACT: Exclude some packages from source trace

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Confess::Source::Patch::ExcludePackage - Exclude some packages from source trace

=head1 VERSION

This document describes version 0.002 of Devel::Confess::Source::Patch::ExcludePackage (from Perl distribution Devel-Confess-Source-Patch-ExcludePackage), released on 2024-02-06.

=head1 SYNOPSIS

 % PERL5OPT=-MDevel::Confess::Source::Patch::ExcludePackage=-exclude_pat,'^MyApp::' -d:Confess=dump yourscript.pl

=head1 DESCRIPTION

=for Pod::Coverage ^()$

=head1 CONFIGURATION

=head2 -exclude_pat

Regexp pattern. If this is specified then packages matching this regexp pattern
will not be shown in stack traces.

=head2 -include_pat

Regexp pattern. If this is specified then only package matching this regexp
pattern will be shown in stack traces.

=head2 -show_excluded

Bool. If set to true, will show:

 Skipped stack trace level (package $FOO)

lines for excluded stack trace level.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-Confess-Source-Patch-ExcludePackage>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-Confess-Source-Patch-ExcludePackage>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Confess-Source-Patch-ExcludePackage>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
