use v5.10;
use warnings;

use File::Copy;
use File::Spec;
use ExtUtils::MakeMaker;

use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

$cc->assert_compile_run(
    diag   => "Please install dialog first, http://invisible-island.net/dialog",
    source => <<'EOF'
 #include <stdio.h>
 #include <dialog.h>
 int main(int argc, char *argv[]) {
   return DLG_EXIT_OK;
 }
EOF
);

WriteMakefile(
    NAME          => 'Hobocamp::Dialog',
    VERSION_FROM  => 'lib/Hobocamp.pm',
    ABSTRACT_FROM => 'lib/Hobocamp.pm',
    BUILD_REQUIRES => {
        'ExtUtils::CChecker' => 0,
    },
    PREREQ_PM     => {
        'Sub::Exporter' => 0,
        'Moose' => 0
    },
    ABSTRACT_FROM => 'lib/Hobocamp.pm',
    AUTHOR        => 'Adam Flott <adam@npjh.com>',

    #    OPTIMIZE      => '-g -O0',
    LIBS   => '-lncursesw -ldialog',
    DEFINE => '-DDLG_HAVE_NCURSESW_NCURSES_H',
    INC    => '-I.',
);
if (eval { require ExtUtils::Constant; 1 }) {

    # If you edit these definitions to change the constants used by this module,
    # you will need to use the generated const-c.inc and const-xs.inc
    # files to replace their "fallback" counterparts before distributing your
    # changes.
    my @names = (
        qw(
          DLG_EXIT_CANCEL DLG_EXIT_ERROR
          DLG_EXIT_ESC DLG_EXIT_EXTRA DLG_EXIT_HELP DLG_EXIT_ITEM_HELP
          DLG_EXIT_OK DLG_EXIT_UNKNOWN
          )
    );
    ExtUtils::Constant::WriteConstants(
        NAME         => 'Hobocamp',
        NAMES        => \@names,
        DEFAULT_TYPE => 'IV',
        C_FILE       => 'const-c.inc',
        XS_FILE      => 'const-xs.inc',
    );
}
else {

    foreach my $file ('const-c.inc', 'const-xs.inc') {
        my $fallback = File::Spec->catfile('fallback', $file);
        copy($fallback, $file) or die "Can't copy $fallback to $file: $!";
    }
}
