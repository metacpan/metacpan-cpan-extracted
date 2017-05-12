#
# $Id: Makefile.PL,v 0.03 2015/06/05 03:57:30 dankogai Exp dankogai $
#
use 5.7.2;
use strict;
use File::Spec;
use ExtUtils::MakeMaker;

# Please edit the following to the taste!
my $name = 'JIS2K';
my %tables = (
	     euc2k_t   => [ File::Spec->catfile(qw/ucm euc-jp2k.ucm/) ],
	     sjis2k_t  => [ File::Spec->catfile(qw/ucm sjis-2k.ucm/) ],
	     raw_t     => [ map { File::Spec->catfile('ucm', $_) }
			    qw/x0213-1.ucm x0213-2.ucm/
			    ],
	     );


# from perlvar
use Config;  # first appeared in 5.00307
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
    my $secure_perl_path .= $Config{_exe}
        unless $secure_perl_path =~ m/$Config{_exe}$/i;
}
die "can't determine path to the perl I'm running under"
    unless ($secure_perl_path);
use File::Basename qw(dirname);
my $dpath = dirname $secure_perl_path;
my ($enc2xs, $encode_h) = ();
my $enc2xs_fpath = File::Spec->catfile($dpath, 'enc2xs');
$enc2xs = $enc2xs_fpath
    if (-x $enc2xs_fpath);
$enc2xs or die "enc2xs not found!";
print "enc2xs is $enc2xs\n";
my %encode_h = ();
for my $d (@INC){
    my $dir = File::Spec->catfile($d, "Encode");
    my $file =  File::Spec->catfile($dir, "encode.h");
    -f $file and $encode_h{$dir} = -M $file;
}
%encode_h or die "encode.h not found!";
# find the latest one
($encode_h) = sort {$encode_h{$b} <=> $encode_h{$a}} keys %encode_h;
print "encode.h is at $encode_h\n";

WriteMakefile(
              INC		=> "-I$encode_h",
	      NAME		=> 'Encode::'.$name,
	      VERSION_FROM	=> "$name.pm",
	      OBJECT		=> '$(O_FILES)',
	      'dist'		=> {
		  COMPRESS	=> 'gzip -9f',
		  SUFFIX	=> 'gz',
		  DIST_DEFAULT => 'all tardist',
	      },
	      MAN3PODS	=> {},
	      PREREQ_PM => {
			    'Encode'     => "1.41",
                           },
	      # OS 390 winges about line numbers > 64K ???
	      XSOPT => '-nolinenumbers',
	      );

package MY;

sub post_initialize
{
    my ($self) = @_;
    my %o;
    my $x = $self->{'OBJ_EXT'};
    # Add the table O_FILES
    foreach my $e (keys %tables)
    {
	$o{$e.$x} = 1;
    }
    $o{"$name$x"} = 1;
    $self->{'O_FILES'} = [sort keys %o];
    my @files = ("$name.xs");
    $self->{'C'} = ["$name.c"];
    # $self->{'H'} = [$self->catfile($self->updir,'encode.h')];
    my %xs;
    foreach my $table (sort keys %tables) {
	push (@{$self->{'C'}},"$table.c");
	# Do NOT add $table.h etc. to H_FILES unless we own up as to how they
	# get built.
	foreach my $ext (qw($(OBJ_EXT) .c .h .exh .fnm)) {
	    push (@files,$table.$ext);
	}
    }
    $self->{'XS'} = { "$name.xs" => "$name.c" };
    $self->{'clean'}{'FILES'} .= join(' ',@files);
    open(XS,">$name.xs") || die "Cannot open $name.xs:$!";
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

sub postamble
{
    my $self = shift;
    my $dir  = "."; # $self->catdir('Encode');
    my $str  = "# $name\$(OBJ_EXT) depends on .h and .exh files not .c files - but all written by enc2xs\n";
    $str    .= "$name.c : $name.xs ";
    foreach my $table (sort keys %tables)
    {
	$str .= " $table.c";
    }
    $str .= "\n\n";
    $str .= "$name\$(OBJ_EXT) : $name.c\n\n";

    foreach my $table (sort keys %tables)
    {
	my $numlines = 1;
	my $lengthsofar = length($str);
	my $continuator = '';
	$str .= "$table.c : Makefile.PL";
	foreach my $file (@{$tables{$table}})
	{
	    $str .= $continuator.' '.$self->catfile($dir,$file);
	    if ( length($str)-$lengthsofar > 128*$numlines )
	    {
		$continuator .= " \\\n\t";
		$numlines++;
	    } else {
		$continuator = '';
	    }
	}
	my $plib   = $self->{PERL_CORE} ? '"-I$(PERL_LIB)"' : '';
	my $ucopts = '-"Q"';
	$str .=  
	    qq{\n\t\$(PERL) $plib $enc2xs $ucopts -o \$\@ -f $table.fnm\n\n};
	open (FILELIST, ">$table.fnm")
	    || die "Could not open $table.fnm: $!";
	foreach my $file (@{$tables{$table}})
	{
	    print FILELIST $self->catfile($dir,$file) . "\n";
	}
	close(FILELIST);
    }
    return $str;
}

