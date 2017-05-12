#-*- perl -*-
#-*- coding: us-ascii -*-

use 5.7.2;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

my %tables = (
    raw_t => [
	qw(jis-x-0208.ucm jis-x-0208-0213.ucm
	jis-x-0213-plane1-2000.ucm jis-x-0213-plane1.ucm
	jis-x-0213-plane2.ucm)
    ],
    sjis_t => [qw(jis-x-0213-annex1.ucm)],
);

unless ($ENV{AGGREGATE_TABLES}) {
    my @ucm;
    for my $k (keys %tables) {
	push @ucm, @{$tables{$k}};
    }
    %tables = ();
    my $seq = 0;
    for my $ucm (sort @ucm) {

	# 8.3 compliance !
	my $t = sprintf("%s_%02d_t", substr($ucm, 0, 2), $seq++);
	$tables{$t} = [$ucm];
    }
}

my ($enc2xs, $encode_h) = ('enc2xs', '.');
my @path_ext = ('');
@path_ext = split(';', $ENV{PATHEXT}) if $^O eq 'MSWin32';
PATHLOOP:
for my $d (@Config{qw/bin sitebin vendorbin/},
        (split /$Config{path_sep}/o, $ENV{PATH})){
    for my $f (qw/enc2xs enc2xs5.7.3/){
        my $path = File::Spec->catfile($d, $f);
        for my $ext (@path_ext) {
            my $bin = "$path$ext";
            -r "$bin" and $enc2xs = $bin and last PATHLOOP;
        }
    }
}
$enc2xs or die "enc2xs not found!";
print "enc2xs is $enc2xs\n";

my %encode_h = ();
for my $d (@INC) {
    my $dir  = File::Spec->catfile($d,   "Encode");
    my $file = File::Spec->catfile($dir, "encode.h");
    -f $file and $encode_h{$dir} = -M $file;
}
%encode_h or die "encode.h not found!";

# find the latest one
($encode_h) = sort { $encode_h{$b} <=> $encode_h{$a} } keys %encode_h;
print "encode.h is at $encode_h\n";

# get XS version.
open my $pm_file, 'lib/Encode/JISX0213/CCS.pm';
my $xs_version = eval [grep {s/^our \$VERSION\s*=\s//} <$pm_file>]->[0];
close $pm_file;

my $name = 'JISX0213';

WriteMakefile(
    INC           => "-I$encode_h",
    NAME          => 'Encode::' . $name,
    VERSION_FROM  => 'lib/Encode/JISX0213.pm',
    ABSTRACT_FROM => 'lib/Encode/JISX0213.pm',
    AUTHOR        => 'Hatuka*nezumi - IKEDA Soji <hatuka@nezumi.nu>',
    LICENSE       => 'perl',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => {
        'ExtUtils::MakeMaker' => 0,
        'Test::More'          => 0,
    },
    PREREQ_PM     => {
        'Encode::ISO2022'     => '0.03',
    },
    META_MERGE    => {
        resources     => {
            license       => 'http://dev.perl.org/licenses/',
            repository    => 'https://github.com/hatukanezumi/Encode-JISX0213/',
        },
    },

    XS_VERSION => $xs_version,
    OBJECT  => '$(O_FILES)',
    'dist'  => {
	COMPRESS     => 'gzip -9f',
	SUFFIX       => 'gz',
	DIST_DEFAULT => 'all tardist',
    },
    #MAN3PODS => {},
    # OS 390 winges about line numbers > 64K ???
    XSOPT => '-nolinenumbers',
);

package MY;

sub post_initialize {
    my ($self) = @_;
    my %o;
    my $x = $self->{'OBJ_EXT'};

    # Add the table O_FILES
    foreach my $e (keys %tables) {
	$o{$e . $x} = 1;
    }
    $o{"$name$x"} = 1;
    $self->{'O_FILES'} = [sort keys %o];
    my @files = ("$name.xs");
    $self->{'C'} = ["$name.c"];
    $self->{SOURCE} .= " $name.c"
	if $^O eq 'MacOS' && $self->{SOURCE} !~ /\b$name\.c\b/;
    #$self->{'H'} = [$self->catfile($self->updir,'Encode', 'encode.h')];
    my %xs;
    foreach my $table (keys %tables) {
	push(@{$self->{'C'}}, "$table.c");
	# Do NOT add $table.h etc. to H_FILES unless we own up as to how they
	# get built.
	foreach my $ext (qw($(OBJ_EXT) .c .h .exh .fnm)) {
	    push(@files, $table . $ext);
	}
	$self->{SOURCE} .= " $table.c"
	    if $^O eq 'MacOS' && $self->{SOURCE} !~ /\b$table\.c\b/;
    }
    $self->{'XS'} = {"$name.xs" => "$name.c"};
    $self->{'clean'}{'FILES'} .= join(' ', @files);
    open(XS, ">$name.xs") || die "Cannot open $name.xs:$!";
    print XS <<'END';
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define U8 U8
#include "encode.h"
END
    foreach my $table (sort keys %tables) {
	print XS qq[#include "${table}.h"\n];
    }
    print XS <<"END";

static void
Encode_XSEncoding(pTHX_ encode_t *enc)
{
 dSP;
 HV *stash = gv_stashpv("Encode::XS", TRUE);
 SV *sv    = sv_bless(newRV_noinc(newSViv(PTR2IV(enc))),stash);
 int i = 0;
 PUSHMARK(sp);
 XPUSHs(sv);
 while (enc->name[i])
  {
   const char *name = enc->name[i++];
   XPUSHs(sv_2mortal(newSVpvn(name,strlen(name))));
  }
 PUTBACK;
 call_pv("Encode::define_encoding",G_DISCARD);
 SvREFCNT_dec(sv);
}

MODULE = Encode::$name	PACKAGE = Encode::$name
PROTOTYPES: DISABLE
BOOT:
{
END
    foreach my $table (sort keys %tables) {
	print XS qq[#include "${table}.exh"\n];
    }
    print XS "}\n";
    close(XS);
    return "# Built $name.xs\n\n";
}

sub postamble {
    my $self = shift;
    my $dir = 'ucm';
    my $str =
	"# $name\$(OBJ_EXT) depends on .h and .exh files not .c files - but all written by enc2xs\n";
    $str .= "$name.c : $name.xs ";
    foreach my $table (keys %tables) {
	$str .= " $table.c";
    }
    $str .= "\n\n";
    $str .= "$name\$(OBJ_EXT) : $name.c\n\n";

    foreach my $table (keys %tables) {
	my $numlines    = 1;
	my $lengthsofar = length($str);
	my $continuator = '';
	$str .= "$table.c : $enc2xs Makefile.PL";
	foreach my $file (@{$tables{$table}}) {
	    $str .= $continuator . ' ' . $self->catfile($dir, $file);
	    if (length($str) - $lengthsofar > 128 * $numlines) {
		$continuator .= " \\\n\t";
		$numlines++;
	    } else {
		$continuator = '';
	    }
	}
	my $plib = $self->{PERL_CORE} ? '"-I$(PERL_LIB)"' : '';
	$plib .= " -MCross=$::Cross::platform" if defined $::Cross::platform;
	my $ucopts = '-"Q"';
	$str .=
	    qq{\n\t\$(PERL) $plib $enc2xs $ucopts -o \$\@ -f $table.fnm\n\n};
	open(FILELIST, ">$table.fnm") ||
	    die "Could not open $table.fnm: $!";
	foreach my $file (@{$tables{$table}}) {
	    print FILELIST $self->catfile($dir, $file) . "\n";
	}
	close(FILELIST);
    }
    return $str;
}

