package Inline::Module::LeanDist::DistDir;

use strict;

use File::Find;
use File::Copy;

require Inline::Module::LeanDist;


## Inline::C makes it kind of hard to get access to this, so just copy/paste it in here for now (I know, I know, ick...)

our $inline_h_file = <<'END_OF_INLINE_H';
#define Inline_Stack_Vars dXSARGS
#define Inline_Stack_Items items
#define Inline_Stack_Item(x) ST(x)
#define Inline_Stack_Reset sp = mark
#define Inline_Stack_Push(x) XPUSHs(x)
#define Inline_Stack_Done PUTBACK
#define Inline_Stack_Return(x) XSRETURN(x)
#define Inline_Stack_Void XSRETURN(0)

#define INLINE_STACK_VARS Inline_Stack_Vars
#define INLINE_STACK_ITEMS Inline_Stack_Items
#define INLINE_STACK_ITEM(x) Inline_Stack_Item(x)
#define INLINE_STACK_RESET Inline_Stack_Reset
#define INLINE_STACK_PUSH(x) Inline_Stack_Push(x)
#define INLINE_STACK_DONE Inline_Stack_Done
#define INLINE_STACK_RETURN(x) Inline_Stack_Return(x)
#define INLINE_STACK_VOID Inline_Stack_Void

#define inline_stack_vars Inline_Stack_Vars
#define inline_stack_items Inline_Stack_Items
#define inline_stack_item(x) Inline_Stack_Item(x)
#define inline_stack_reset Inline_Stack_Reset
#define inline_stack_push(x) Inline_Stack_Push(x)
#define inline_stack_done Inline_Stack_Done
#define inline_stack_return(x) Inline_Stack_Return(x)
#define inline_stack_void Inline_Stack_Void
END_OF_INLINE_H


sub run {
    my ($distvname, $inline_file) = @ARGV;

    edit_file("$distvname/Makefile.PL", sub {
        s/^(use Inline::Module::LeanDist.*?)$/# Commented out for distribution by Inline::Module::LeanDist\n#$1/mg
          || die "unable to find 'use Inline::Module::LeanDist' directive in Makefile.PL";
    });

    edit_file("$distvname/$inline_file", sub {
        my $xsloader_snippet = qq{# XSLoader added for distribution by Inline::Module::LeanDist:\nrequire XSLoader; XSLoader::load(__PACKAGE__, \$VERSION);\n};
        s/^(use Inline::Module::LeanDist.*?)$/# Commented out for distribution by Inline::Module::LeanDist\n#$1\n\n$xsloader_snippet/mg
          || die "unable to find 'use Inline' directive in $inline_file";
    });

    $inline_file =~ m{([^/]+)[.]pm$}
        || die "couldn't extract base filename from filename $inline_file";

    my $base_filename = $1;

    edit_file("$distvname/Makefile.PL", sub {
        s/^(\s*OBJECT\s*=>\s*')(.*?')/$1${base_filename}.o $2/mg
            || die "couldn't find OBJECT => '' in Makefile.PL";
    });

    my $xs_file;

    File::Find::find({
        wanted => sub {
            -f or return;

            if (m{/$base_filename[.]xs$}) {
                die "found multiple $base_filename.xs files in the $Inline::Module::LeanDist::inline_build_path dir"
                    if defined $xs_file;

                $xs_file = $_;
            }
        },
        no_chdir => 1,
    }, $Inline::Module::LeanDist::inline_build_path);

    die "unable to find $base_filename.xs in $Inline::Module::LeanDist::inline_build_path"
        if !defined $xs_file;

    copy($xs_file, "$distvname/$base_filename.xs") || die "copy of xs file failed: $!";

    add_to_manifest("$distvname/MANIFEST", "$base_filename.xs");

    edit_file("$distvname/$base_filename.xs", sub {
        s/^#include "INLINE.h"\s*$/$inline_h_file/mg
            || die "couldn't find INLINE.h include in $distvname/$base_filename.xs";
    });
}



sub edit_file {
    my ($filename, $cb) = @_;

    open(my $fh, '<', $filename) || die "unable to open $filename for reading: $!";

    local $_;

    {
        local $/;
        $_ = <$fh>;
    }

    undef $fh;

    $cb->();

    ## Write to $filename.edit because MakeMaker likes to use hard-links. You can always over-ride this
    ## in the Makefile.PL with DIST_CP => 'cp', but this way it will work even if a user forgets to do this.

    open($fh, '>', "$filename.edit") || die "unable to open $filename.edit for writing: $!";

    print $fh $_;

    undef $fh;

    rename("$filename.edit", $filename) || die "couldn't rename $filename.edit to $filename: $!";
}


sub add_to_manifest {
    my ($manifest_file, $line) = @_;

    copy($manifest_file, "$manifest_file.edit");

    rename("$manifest_file.edit", $manifest_file) || die "couldn't rename $manifest_file.edit to $manifest_file: $!";

    open(my $fh, '>>', $manifest_file) || die "couldn't open $manifest_file for append: $!";

    print $fh "$line\n";
}


1;
