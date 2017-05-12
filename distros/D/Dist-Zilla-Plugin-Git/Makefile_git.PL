#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# this section comes from Makefile.git.PL and is inserted into Makefile.PL
# Git 1.5.4 introduced the --exclude-standard option to git ls-files,
# which Git::Check needs to work properly.
use version;
my $need_version = version->parse('1.5.4');
eval {
  my $git_version = `git --version` or die "Unable to execute git\n";
  $git_version =~ /git \s+ version \s* ( \d+ (?: \.\d+ )+ )( [-.]rc\d+)?/x
      or die "Unable to determine git version\n";
  my $rc = $2 || '';

  $git_version = version->parse("$1");
  die "git $need_version or later required, you have $git_version$rc\n"
      if $git_version < $need_version or $git_version == $need_version and $rc;
  1;
} or do {
  print $@;

  if (parse_args()->{FORCE_INSTALL}) {
    print "FORCE_INSTALL specified, attempting to install anyway.\n";
  } else {
    print <<"END MESSAGE";
\nDist::Zilla::Plugin::Git requires git $need_version or later in your PATH,
and it wasn't found.  If you want to install anyway, run

  PERL_MM_OPT=FORCE_INSTALL $^X Makefile.PL
END MESSAGE

    exit 0;                  # Indicate missing non-Perl prerequisite
  } # end else not FORCE_INSTALL
}; # end do when Git prerequisite is not met

sub parse_args {
  require ExtUtils::MakeMaker;
  require Text::ParseWords;
  ExtUtils::MakeMaker::parse_args(
    my $tmp = {},
    Text::ParseWords::shellwords($ENV{PERL_MM_OPT} || ''),
    @ARGV,
  );
  return $tmp->{ARGS} || {};
}
