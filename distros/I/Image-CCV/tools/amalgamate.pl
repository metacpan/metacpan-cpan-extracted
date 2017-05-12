#!perl -w
use strict;
use File::Glob 'bsd_glob';
use Getopt::Long;

use vars '$VERSION';
$VERSION = '0.01';

# This takes a list of .c and .h files and concatenates them
# into one long file. It traces #include statements as well.

GetOptions(
    'output|o:s' => \my $outfile,
    'libdir:s' => \my $libdir,
    'include:s' => \my @include,
);

#XXX Should read CCV version from CCV.h or wherever
$outfile ||= "ccv_amalgamated.c";
$libdir ||= 'ccv-src/lib'; # XXX Default should be src/lib

if(! @include) {
    push @include,
             $libdir,
             bsd_glob "$libdir/3rdparty/*"
    ;
};
my %included;
my %not_found;

sub find_include {
    my ($file) = @_;
    -f $file and return $file;
    #-f "$libdir/$file" and return "$libdir/$file";
    
    map {-f "$_/$file"
          ? "$_/$file"
          : () } @include;
};

sub slurp($$) {
    my ($filename, $alias) = @_;
    $filename =~ s!\\!/!g;
    $included{ $filename }++;
    $included{ $alias }++;
    
    
    warn "Loading $filename from $alias";
    
    local $/;
    open my $fh, '<', $filename
        or die "Couldn't read '$filename:' $!";
    join "\n",
        map { s/\s+$//g if length; $_ }
            qq<#line 1 "$alias">,
            <$fh>,
            "",
            "/* End of $alias */",
            ""
    ;
};

sub maybe_slurp {
    my ($filename, $alias) = @_;
    
    # Find the potential alias for the filename
    my $found;
    if( ! $alias ) {
        my @found = find_include( $filename );
        $found = $found[0];
        $alias = $filename;
        
        if(! @found) {
            warn "No include found for $filename";
        };
        
        return "" unless @found;
    };
    
    if( not $included{$found} and not $included{ $alias } and not $included{ $filename }) {
        return slurp( $found, $alias );
    } else {
        warn "$filename already included as $alias";
        return "/* $alias already included */\n";
    };
};

my @files = map { s/\s+$//g; 
                  find_include( $_ )
                } <DATA>;

open my $out, '>', $outfile
    or die "Couldn't create '$outfile': $!";

print {$out} <<HEADER;
/*
** This file is an amalgamation of many separate C source files from CCV
** version $VERSION.  By combining all the individual C code files into this
** single large file, the entire code can be compiled as a single translation
** unit.  This hopefully allows many compilers to do optimizations that would
** not be possible if the files were compiled separately.  Also, this makes
** compilation with XS much easier.
**
HEADER

for my $file (@files) {
    next if $file =~ /^#/;
    next if $included{ $file };
    
    warn $file;
    my $content = maybe_slurp($file);
    warn $content;
    die "'$file' not found in @include"
        if ! $content;
    
    # Process #includes
    # #include "io/_ccv_io_libjpeg.c"
    #warn $_ for ($content =~ m!^\s*#include\s+(["<]?([-a-zA-Z0-9._/]+)[">]?)$!mg);
    $content =~ s!^\s*#include\s+(["<]?([-a-zA-Z0-9._/]+)[">]?)!maybe_slurp($2)||$&!gem;
    print {$out} $content;
};

__DATA__
sha1.h
kiss_fft.h
ccv.h
ccv_io.c
*.c
