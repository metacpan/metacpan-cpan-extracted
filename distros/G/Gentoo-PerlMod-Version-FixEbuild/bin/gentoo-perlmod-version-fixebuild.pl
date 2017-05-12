#!/usr/bin/env perl

use strict;
use warnings;

package Gentoo::PerlMod::Version::Tool::Fix;
BEGIN {
  $Gentoo::PerlMod::Version::Tool::Fix::VERSION = '0.1.1';
}

# PODNAME: gentoo-perlmod-version-fixebuild.pl
# ABSTRACT: Automatically fix an old-style ebuild to a new style ebuild.

use Gentoo::PerlMod::Version::FixEbuild;
use Carp qw( croak );


my $conf = {

  #    lax => 1,
  #    changelog => 0,
  #    manifest => 0,
  #    verbose => 1,
  #    copyright => 1,
};

sub help {
  warn <<'EOF';

usage:
     gentoo-perlmod-version-fixebuild.pl --arg --arg --arg file

        file            The path to an ebuild to fixup.

        --changelog     Automatically update the Changelog. (Default)( Needs 'echangelog' )
        --no-changelog  Disable Automatically updating Changelog.

        --manifest      Automatically update the Manifest. (Default)( Needs 'repoman' )
        --no-manifest   Disable automatically updating the manifest

        --quiet         No messages.
                         ( Alias for --verbose=0 )

        --verbose       Tracing.
                         ( Alias for --verbose=1

        --verbose=n

                0  : No output
                1  : Basic logging
                2  : Extra logging.

        --copyright     Automatically fix up the copyright notices. ( Default )
        --no-copyright  Disable Automatically fixing copyright notices.
                            ( Note that --changelog will force these to be updated )


        --scm-add="cmd %s"

                        Set SCM add command. Defaults to 'git add %s'

        --remove-old    Remove previous version automatically. ( Default )
        --no-remove-old  Dont.

        --commit        Automatically commit ( Default )
        --no-commit      Dont.

EOF
  exit -1;
}

my $seen_ddash = undef;
my @files;

for my $opt (@ARGV) {

  if ( not $seen_ddash and $opt =~ /^--?(.+)$/ ) {
    my $optname = $1 . "";

    if ( $optname =~ /^h/ ) {
      $conf->{help} = 1;
      next;
    }

    if ( $optname =~ /^lax=(\d+)$/ ) {
      $conf->{lax} = $1 + 0;
      next;
    }

    if ( $optname =~ /^verbose$/ ) {
      $conf->{verbose} = 1;
      next;
    }

    if ( $optname =~ /^verbose=(\d+)$/ ) {
      $conf->{verbose} = $1 + 0;
      next;
    }

    if ( $optname =~ /^quiet$/ ) {
      $conf->{verbose} = 0;
      next;
    }

    if ( $optname =~ /^changelog$/ ) {
      $conf->{changelog} = 1;
      next;
    }

    if ( $optname =~ /^no[-_]changelog$/ ) {
      $conf->{changelog} = 0;
      next;
    }

    if ( $optname =~ /^manifest$/ ) {
      $conf->{manifest} = 1;
      next;
    }

    if ( $optname =~ /^no[-_]manifest$/ ) {
      $conf->{manifest} = 0;
      next;
    }

    if ( $optname =~ /^copyright$/ ) {
      $conf->{copyright} = 1;
      next;
    }

    if ( $optname =~ /^no[-_]manifest$/ ) {
      $conf->{copyright} = 0;
      next;
    }

    if ( $optname =~ /^scm[-_]add=(.*$)/ ) {
      $conf->{scm_add} = "$1";
      next;
    }
    if ( $optname =~ /^scm[-_]rm=(.*$)/ ) {
      $conf->{scm_rm} = "$1";
      next;
    }
    if ( $optname =~ /^scm[-_]commit=(.*$)/ ) {
      $conf->{scm_rm} = "$1";
      next;
    }
    if ( $optname =~ /^remove[-_]old$/ ) {
      $conf->{remove_old} = 1;
      next;
    }

    if ( $optname =~ /^no[-_]remove[-_]old$/ ) {
      $conf->{remove_old} = 0;
      next;
    }
    if ( $optname =~ /^commit$/ ) {
      $conf->{commit} = 1;
      next;
    }

    if ( $optname =~ /^no[-_]commit$/ ) {
      $conf->{commit} = 0;
      next;
    }

    warn "Flag $opt not recognised\n\n";
    help();
  }

  if ( not $seen_ddash and $opt =~ /^--$/ ) {
    $seen_ddash = 1;
    next;
  }

  push @files, $opt;

}

my $fixer = Gentoo::PerlMod::Version::FixEbuild->new( %$conf );

for (@files) {
  $fixer->fix_file($_);
}


__END__
=pod

=head1 NAME

gentoo-perlmod-version-fixebuild.pl - Automatically fix an old-style ebuild to a new style ebuild.

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    gentoo-perlmod-version-fixebuild.pl path/too/foo-5.6.ebuild

    gentoo-perlmod-version-fixebuild.pl --changelog --manifest path/too/foo-5.6.ebuild

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

