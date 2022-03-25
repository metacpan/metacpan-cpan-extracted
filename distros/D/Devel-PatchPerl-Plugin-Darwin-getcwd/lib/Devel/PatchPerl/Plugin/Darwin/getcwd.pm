package Devel::PatchPerl::Plugin::Darwin::getcwd;
use strict;
use warnings;

our $VERSION = '0.003';

use version;

sub patchperl {
    my ($class, %argv) = @_;

    if ($^O ne "darwin") {
        return 1; # OK
    }
    my $version = version->parse($argv{version});
    if ($version >= v5.30.0) {
        return 1; # OK
    }

    my ($file) = grep -f, qw(
        dist/PathTools/Cwd.pm
        dist/Cwd/Cwd.pm
        cpan/Cwd/Cwd.pm
        lib/Cwd.pm
    );
    die "Missing Cwd.pm" if !$file;

    warn "patching $file\n";

    my $find = q[my $start = @_ ? shift : '.';];
    open my $in, "<", $file or die;
    open my $out, ">", "$file.tmp" or die;
    while (my $l = <$in>) {
        print {$out} $l;
        if ($l =~ /\Q$find\E/) {
            print {$out} q[    if ($start eq ".") { return _backtick_pwd() } # XXX patched by Devel-PatchPerl-Plugin-Darwin-getcwd], "\n";
        }
    }
    close $in;
    close $out;
    rename "$file.tmp", $file or die "rename $!";
    return 1;
}


1;
__END__

=encoding utf-8

=head1 NAME

Devel::PatchPerl::Plugin::Darwin::getcwd - (DEPRECATED) a workaround for getcwd in macOS

=head1 SYNOPSIS

  env PERL5_PATCHPERL_PLUGIN=Darwin::getcwd patchperl

If you use L<plenv|https://github.com/tokuhirom/plenv>
with L<Perl-Build|https://github.com/tokuhirom/Perl-Build> then,

  env PERL5_PATCHPERL_PLUGIN=Darwin::getcwd plenv install 5.28.3

=head1 DESCRIPTION

B<UPDATE>: It seems that the bug has been fixed in macOS 12.3, so we don't need this module anymore.

macOS has a bug described in L<https://gist.github.com/skaji/84a4ea75480298f839f7cf4adcc109c9>

As a result, building perl 5.28 or below often fails:

  Running Makefile.PL in cpan/libnet
  ../../miniperl -I../../lib Makefile.PL INSTALLDIRS=perl INSTALLMAN1DIR=none INSTALLMAN3DIR=none PERL_CORE=1 LIBPERL_A=libperl.a
  readdir(./../../../../../../../../..): No such file or directory at /Users/skaji/env/plenv/build/perl-5.18.4-QBrBC/lib/File/Find.pm line 484.
  Use of chdir('') or chdir(undef) as chdir() is deprecated at /Users/skaji/env/plenv/build/perl-5.18.4-QBrBC/lib/File/Find.pm line 624.
  Writing Makefile for Net
  Warning: No Makefile!
  make[2]: *** No rule to make target `config'.  Stop.
   /Applications/Xcode.app/Contents/Developer/usr/bin/make config PERL_CORE=1 LIBPERL_A=libperl.a failed, continuing anyway...
  Making all in cpan/libnet
   /Applications/Xcode.app/Contents/Developer/usr/bin/make all PERL_CORE=1 LIBPERL_A=libperl.a
  make[2]: *** No rule to make target `all'.  Stop.
  Unsuccessful make(cpan/libnet): code=512 at make_ext.pl line 490.
  make[1]: *** [cpan/libnet/pm_to_blib] Error 2
  make: *** [install] Error 2

This plugin adds a workaround so that we use C<pwd> to get the current directory.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
