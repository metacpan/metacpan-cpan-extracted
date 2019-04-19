#!perl -w
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;
use Config;

my $verbose = $ENV{IM_VERBOSE};
my @libpaths;
my @incpaths;

GetOptions("incpath=s", \@incpaths,
           "libpath=s" => \@libpaths,
           "verbose|v" => \$verbose);

our $BUILDING_IMAGER;
our %IMAGER_LIBS;

my %opts =
  (
   NAME => 'Imager::File::WEBP',
   VERSION_FROM => 'WEBP.pm',
   OBJECT => 'WEBP.o imwebp.o',
   #DEFINE => $define,
   clean => { FILES => 'testout' },
  );

if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
  $opts{LICENSE} = "perl_5";
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'WEBP image file support for Imager';
  $opts{META_MERGE} =
    {
     'meta-spec' =>
     {
      version => "2",
      url => "https://metacpan.org/pod/CPAN::Meta::Spec",
     },
     resources =>
     {
      homepage => "http://imager.perl.org/",
      repository =>
      {
       type => "git",
       url => "git://github.com/tonycoz/imager-file-webp.git",
       web => "http://github.com/tonycoz/imager-file-webp.git",
      },
      bugtracker =>
      {
       web => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Imager-File-WEBP",
       mailto => 'bug-Imager-File-WEBP@rt.cpan.org',
      },
     },
    };
}

my @inc;
unshift @INC, "inc";
require Imager::ExtUtils;
push @inc, Imager::ExtUtils->includes;
$opts{TYPEMAPS} = [ Imager::ExtUtils->typemap ];

# Imager required configure through use
my @Imager_req = ( Imager => "0.94" );
if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
  $opts{META_MERGE}{prereqs} =
    {
     configure =>
     {
      requires =>
      {
       @Imager_req,
      },
     },
     build =>
     {
      requires =>
      {
       @Imager_req,
       "Test::More" => "0.47",
      }
     },
     runtime =>
     {
      requires =>
      {
       @Imager_req,
      }
     },
     test =>
     {
      requires =>
      {
       "Test::More" => "0.47",
      }
     },
    };
  $opts{PREREQ_PM} =
    {
     @Imager_req,
     XSLoader => 0,
    };
}

require Imager::Probe;

my %probe =
  (
   name => "WEBP",
   inccheck => sub { -e File::Spec->catfile($_[0], "webp/mux.h") },
   libbase => [ "webpmux", "webp" ],
   testcode => _webp_test_code(),
   testcodeheaders => [ "webp/encode.h", "webp/decode.h", "webp/mux.h", "stdio.h", "string.h" ],
   libopts => "-lwebpmux -lwebp",
   incpath => \@incpaths,
   libpath => \@libpaths,
   verbose => $verbose,
   pkg => [ "libwebpmux" ],
  );

my $probe_res = Imager::Probe->probe(\%probe);
if ($probe_res) {
  push @inc, $probe_res->{INC};
  $opts{LIBS} = $probe_res->{LIBS};
  $opts{DEFINE} .= " $probe_res->{DEFINE}";
  $opts{INC} = "@inc";

  if ($Config{d_snprintf}) {
    $opts{DEFINE} .= " -DHAVE_SNPRINTF";
  }

  WriteMakefile(%opts);
}
else {
  die "OS unsupported: WEBP libraries or headers not found\n";
}

sub _webp_test_code {
  return <<'CODE';
  unsigned int mux_ver = WebPGetMuxVersion();
  unsigned int enc_ver = WebPGetEncoderVersion();
  unsigned int dec_ver = WebPGetDecoderVersion();
  printf("encoder %d.%d.%d (%x)\ndecoder %d.%d.%d (%x)\nmux %d.%d.%d (%x)\n",
         enc_ver >> 16, (enc_ver >> 8) & 0xFF, enc_ver & 0xFF, enc_ver,
         dec_ver >> 16, (dec_ver >> 8) & 0xFF, dec_ver & 0xFF, dec_ver,
         mux_ver >> 16, (mux_ver >> 8) & 0xFF, mux_ver & 0xFF, mux_ver);
  if (enc_ver < 0x000500 || dec_ver < 0x000500) {
    printf("Need at least version 0.5.0 of libwebp\n");
    return 1;
  }
  if (mux_ver < 0x000300) {
    printf("Need at least version 0.3.0 of libwebpmux (libwebp 0.5.0)\n");
    return 1;
  }
return 0;
CODE
}
