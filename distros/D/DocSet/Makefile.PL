package DocSet;

use ExtUtils::MakeMaker;

require 5.005;

use strict;

my @programs_to_install = qw(docset_build html2ps);

my %require =
  (
   'Storable'     => '',
   'HTML::Parser' => '3.25',
   'Pod::POM'     => '0.15',
   'Template'     => '2.0',
  );

for (keys %require) {
    chk_version($_ => $require{$_})
     or warn  "\n" .
        "*** For ".__PACKAGE__." to work you need version $require{$_}, " .
        "or later, of $_ from CPAN\n\n";
}

WriteMakefile(
    NAME         => __PACKAGE__,
    VERSION_FROM => 'lib/DocSet.pm',
    (
     $] < 5.005 ? () :
     (
      AUTHOR		=> 'Stas Bekman <stas@stason.org>',
      ABSTRACT_FROM	=> 'lib/DocSet.pm',
     )
    ),
    EXE_FILES    => [ map {"bin/$_"} @programs_to_install ],
    dist => {
             PREOP        => 'pod2text lib/DocSet.pm > $(DISTVNAME)/README',
             COMPRESS     => 'gzip -9f',
             SUFFIX       => '.gz', 
             ZIP	    => 'zip',
             ZIPFLAGS     => '-r',
             DIST_DEFAULT => 'tardist',
            },
    PREREQ_PM => \%require,
);

sub chk_version{
  my ($pkg, $wanted) = @_;

  no strict 'refs'; 
  local $| = 1;

  print "Checking for $pkg...";

  eval { (my $p = $pkg . ".pm") =~ s#::#/#g; require $p;};

  print("not ok\n$@"),return if $@;

  my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
                                 : "not found";
  my $vnum = ${"${pkg}::VERSION"} || 0;

  print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

  $vnum >= $wanted;

}
