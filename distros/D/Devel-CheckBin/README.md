# NAME

Devel::CheckBin - check that a command is available

# SYNOPSIS

    use Devel::CheckBin;

# DESCRIPTION

Devel::CheckBin is a perl module that checks whether a particular command is available.

# USING IT IN Makefile.PL or Build.PL

If you want to use this from Makefile.PL or Build.PL, do not simply copy the module into your distribution as this may cause problems when PAUSE and search.cpan.org index the distro. Instead, use the 'configure\_requires'.

# LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
