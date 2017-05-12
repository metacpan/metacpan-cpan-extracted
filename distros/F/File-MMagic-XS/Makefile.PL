BEGIN {
    if (-e ".git") {
        my $errors = 0;
        foreach my $module (qw(Module::Install Module::Install::AuthorTests Module::Install::Repository Module::Install::XSUtil)) {
            eval "require $module";
            if ($@) {
                $errors++;
                print $module, "\n";
            }
        }

        if ($errors) {
            exit 1;
        }
    }
}

use inc::Module::Install;

# if you are getting this from git repo, you need to have
#   * Module::Install
#   * Module::Install::AuthorTests
#   * Module::Install::Repository
#   * Module::Install::XSUtil
# installed

name 'File-MMagic-XS';
all_from 'lib/File/MMagic/XS.pm';

if ($^O eq 'MSWin32') {
    print STDERR 
        "File::MMagic::XS does not compile on Windows\n",
        "(patches welcome)\n"
    ;
    exit 0;
}

use_ppport;
cc_warnings;
cc_src_paths 'src';
author_tests 'xt';

auto_set_repository;

WriteAll;
