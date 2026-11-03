#!/usr/bin/env perl
# Print the modules the locale-simple CLI loads, one per line (Foo::Bar), by running the
# real commands. Run it as `perl -Ilib scripts/loaded-modules.pl` from the checkout root.
# build-binary.sh turns the list into pp -M options; verify-binary.sh requires every
# entry inside the packed archive. One source, so build and verify cannot drift.
# Problems go to STDERR; the list goes to STDOUT.
use strict; use warnings;
use File::Find ();
use File::Temp ();
my %mods;
for my $dir ( grep { !ref } @INC ) {
  next unless -d "$dir/Locale/Simple";
  File::Find::find( { no_chdir => 1, wanted => sub {
    return unless /\.pm\z/;
    ( my $m = substr $_, length($dir) + 1 ) =~ s{/}{::}g;
    $m =~ s/\.pm\z//;
    $mods{$m} = 1;
  } }, "$dir/Locale/Simple" );
}
# The gettext backends of Locale::TextDomain (gettext_pp / gettext_dumb are chosen at run time).
$mods{$_} = 1 for qw(
  Locale::TextDomain Locale::Messages Locale::gettext_pp Locale::gettext_dumb
  Locale::Recode Locale::Recode::_Aliases
);
for my $m ( sort keys %mods ) {
  eval "require $m; 1" or warn "loaded-modules: not loadable: $m (" . ( split /\n/, $@ )[0] . ")\n";
}
# Run both commands for real, so the lazy loads happen.
require Locale::Simple::CLI;
my $dir = File::Temp::tempdir( CLEANUP => 1 );
open my $fh, '>', "$dir/a.pl" or die $!;
print $fh qq{use Locale::Simple;\nl("hello");\nln("one","many",2);\nlp("ctx","x");\n};
close $fh;
open my $po, '>', "$dir/x.po" or die $!;
print $po qq{msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Plural-Forms: nplurals=2; plural=(n != 1);\\n"\n\nmsgid "a"\nmsgstr "b"\n};
close $po;
{
  chdir $dir or die $!;
  open my $oldout, '>&', \*STDOUT or die;
  open STDOUT, '>', '/dev/null' or die;
  open my $olderr, '>&', \*STDERR or die;
  open STDERR, '>', '/dev/null' or die;
  for my $fmt (qw(po json perl)) {
    Locale::Simple::CLI::run( 'scrape', '--output', $fmt );
  }
  Locale::Simple::CLI::run( 'po2json', '--pretty', "$dir/x.po" );
  # The paths verify-binary.sh also walks: help, version, usage errors, a missing file.
  Locale::Simple::CLI::run(@$_) for ( [], ['help'], ['--help'], ['-h'], ['--version'], ['nope'] );
  Locale::Simple::CLI::run( 'po2json', "$dir/nope.po" );
  Locale::Simple::CLI::run( 'po2json' );
  open STDOUT, '>&', $oldout or die;
  open STDERR, '>&', $olderr or die;
  chdir '/';
}
for my $file ( sort keys %INC ) {
  next unless $file =~ m{\A[\w/]+\.pm\z};
  next unless defined $INC{$file} && !ref $INC{$file} && $INC{$file} =~ m{/\Q$file\E\z};
  ( my $m = $file ) =~ s{/}{::}g;
  $m =~ s/\.pm\z//;
  next if $m eq 'YAML';    # left out of every build (-X YAML in build-binary.sh)
  print "$m\n";
}
