use inc::Module::Install;
use Config;

use vars qw(@MAKEOPTS $Path);

use File::Spec;
use File::Basename;

BEGIN {
    name     'Encode-HanConvert';
    all_from 'lib/Encode/HanConvert.pm';

    # inhibit incorrect utf8iciation of filehandles on Perl 5.8.0
    $ENV{LC_ALL} = $ENV{LC_CTYPE} = $ENV{LANG} = 'C';

    $Path = dirname($0);
    system($^X, File::Spec->catfile($Path, qw(map map2pm.pl)))
        unless -e File::Spec->catfile($Path, qw(lib Encode HanConvert Perl.pm));

    @MAKEOPTS = (
        EXE_FILES       => [ <bin/*> ],
        ABSTRACT        => 'Traditional and Simplified Chinese mappings',
        AUTHOR          => 'Audrey Tang <cpan@audreyt.org>',
        NAME            => 'Encode::HanConvert',
        VERSION_FROM    => "lib/Encode/HanConvert.pm",
        'dist'          => {
            COMPRESS    => 'gzip -9f',
            SUFFIX      => 'gz',
            DIST_DEFAULT => 'all tardist',
        },
    );
    
    if ($] < 5.007003 or !can_cc) {
        print "Encode.pm support not possible; Byte <=> Unicode mappings will not be available.\n";
        print "Unicode support not possible; Unicode mappings will not be available.\n"
            if $] < 5.006;

        makemaker_args @MAKEOPTS;
        sign; WriteAll;
        exit;
    }
}

# Please edit the following to your taste!
my $name = 'HanConvert';
my %tables = (
    HanConvert_t => [ qw(big5-simp.ucm gbk-trad.ucm simp-trad.ucm trad-simp.ucm) ],
);

if (grep { ! -e $_ } map { @{$_} } values(%tables)) {
    # build .ucm files first.
    system($^X, File::Spec->catfile($Path, qw(map map2ucm.pl)));
    system($^X, File::Spec->catfile($Path, qw(map umap2ucm.pl)));
}

unless ($ENV{AGGREGATE_TABLES}){
    my @ucm;
    for my $k (keys %tables){
        push @ucm, @{$tables{$k}};
    }
    %tables = ();
    my $seq = 0;
    for my $ucm (sort @ucm){
        # 8.3 compliance !
        my $t = sprintf ("%s_%02d_t", substr($ucm, 0, 2), $seq++);
        $tables{$t} = [ $ucm ];
    }
}

#### DO NOT EDIT BEYOND THIS POINT!
require File::Spec;
my ($enc2xs, $encode_h) = ();
PATHLOOP:
for my $d (@Config{qw/bin sitebin vendorbin/}, 
           (split /$Config{path_sep}/o, $ENV{PATH})){
    for my $f (map {$_, "$_.bat"} ('enc2xs', "enc2xs$Config{version}")) {
        my $path = File::Spec->catfile($d, $f);
        -r $path and $enc2xs = $path and last PATHLOOP;
    }
}
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

makemaker_args(
              INC               => "-I$encode_h",
#### END_OF_HEADER -- DO NOT EDIT THIS LINE BY HAND! ####
              NAME              => 'Encode::'.$name,
              VERSION_FROM      => "lib/Encode/$name.pm",
              OBJECT            => '$(O_FILES)',
              'dist'            => {
                  COMPRESS      => 'gzip -9f',
                  SUFFIX        => 'gz',
                  DIST_DEFAULT => 'all tardist',
              },
              MAN3PODS  => {},
              PREREQ_PM => {
                            'Encode'     => "1.41",
                           },
              # OS 390 winges about line numbers > 64K ???
              XSOPT => '-nolinenumbers',
              @MAKEOPTS,
              );
sign; WriteAll;

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
    # The next two lines to make MacPerl Happy -- dankogai via pudge
    $self->{SOURCE} .= " $name.c"
        if $^O eq 'MacOS' && $self->{SOURCE} !~ /\b$name\.c\b/;
    # $self->{'H'} = [$self->catfile($self->updir,'encode.h')];
    my %xs;
    foreach my $table (keys %tables) {
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
    foreach my $table (keys %tables) {
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

MODULE = Encode::$name  PACKAGE = Encode::$name
PROTOTYPES: DISABLE
BOOT:
{
END
    foreach my $table (keys %tables) {
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
    foreach my $table (keys %tables)
    {
        $str .= " $table.c";
    }
    $str .= "\n\n";
    $str .= "$name\$(OBJ_EXT) : $name.c\n\n";

    foreach my $table (keys %tables)
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

