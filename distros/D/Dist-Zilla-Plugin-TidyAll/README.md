NAME

    Dist::Zilla::Plugin::TidyAll - Apply tidyall to files in Dist::Zilla

SYNOPSIS

        # dist.ini
        [TidyAll]
    
        # or
        [TidyAll]
        tidyall_ini = /path/to/tidyall.ini

DESCRIPTION

    Processes each file with tidyall, via the Dist::Zilla::Role::FileMunger
    role.

    You may specify the path to the tidyall.ini; otherwise it is expected
    to be in the dzil root (same as dist.ini).

SEE ALSO

    tidyall

