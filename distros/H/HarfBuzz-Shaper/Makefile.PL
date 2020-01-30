#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use Devel::CheckLib;

my $master = 'lib/HarfBuzz/Shaper.pm';
my $version = MM->parse_version($master);

my %args = (
 NAME                => 'HarfBuzz::Shaper',
 AUTHOR              => 'Johan Vromans <jv@cpan.org>',
 VERSION             => $version,
 ABSTRACT_FROM       => $master,
 LICENSE             => 'perl_5',
 PL_FILES            => {},
 LIBS                => [ '-lharfbuzz' ],
 INC                 => '',
 MIN_PERL_VERSION    => '5.010001',
 PREREQ_PM => {
     'ExtUtils::MakeMaker' => 6.46, # for META_MERGE, LICENSE
     'Test::More' => 0,
 },
 TEST_REQUIRES  => {
		   },
 META_MERGE => {
   resources    => {
     repository => {
       type => 'git',
	web  => 'https://github.com/sciurius/perl-HarfBuzz-Shaper',
	url  => 'https://github.com/sciurius/perl-HarfBuzz-Shaper.git',
      },
      bugtracker => "https://github.com/sciurius/perl-HarfBuzz-Shaper/issues",
     },
     'meta-spec' => {
       version => '2',
       url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
     },
     provides => {
	 "HarfBuzz::Shaper"
		  => { file => "lib/HarfBuzz/Shaper.pm",
		       version => $version },
     },

     no_index => {
         directory => [
		       "inc", "t", "harfbuzz",
	 ],
     },
 }
);

my $hb_include;
my $hb_src = "harfbuzz/harfbuzz.cc";

if ( check_lib( lib      => "harfbuzz",
		header   => "harfbuzz/hb.h",
		function => <<EOF )
/* Need at least 1.7.7 */
hb_blob_create_from_file("");
return 0;
EOF
   ) {
    warn("Using platform harfbuzz library\n");
}
elsif ( -s $hb_src ) {
    $hb_include = 1;
    warn("Including harfbuzz library\n");
    $args{MYEXTLIB} = 'harfbuzz.o';
    $args{LIBS}     = [ '-lstdc++' ];
    $args{INC}      = '-I.';
}
else {
    warn("HarfBuzz::Shaper needs the harfbuzz library, version 1.7.7 or later.\n",
         "Please install it first. See file INSTALL for details.\n");
    exit(0);
}

WriteMakefile(%args);

sub MY::postamble {
    return unless $hb_include;
    return <<'EOF';
$(MYEXTLIB) : harfbuzz/harfbuzz.cc
	$(CXX) -c -o $@ -DHB_NO_MT -fPIC $(CCFLAGS) $<

EOF
}
