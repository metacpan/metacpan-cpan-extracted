## Filter::Heredoc

Search and extract "any" here document embedded in scripts from STDIN or an
input file. Pipe output to an external program such as hunspell or aspell.

Filter::Heredoc extracts here documents from POSIX IEEE Std 1003.1-2008
compliant shell scripts. Perl have derived a similar here document syntax
but is at the same time different in many details. Perls here document will
be supported but is in the initial version experimental. 

### SYNOPSIS

    use 5.010;
    use Filter::Heredoc qw( hd_getstate hd_init hd_labels );
    my $line;
    my %state;
    my %label = hd_labels();
    while ( defined( $line = <ARGV> )) {
        %state = hd_getstate( $line );
        print $line if ( $state{statemarker} eq $label{heredoc} );
    }

See the 'examples' directory for code snippets.

### INSTALLATION

The last command requires root/sudo privileges when installing
system wide. To install this module, run the following commands:

    $ perl Build.PL
    $ ./Build
    $ ./Build test
    
    # ./Build install

### DEPENDENCIES

Filter::Heredoc requires Perl 5.10 (or any later version).


### LIMITATIONS

Filter::Heredoc complies with *nix POSIX shells here document syntax.
Non-compliant shells on e.g. MSWin32 platform is not supported.


### SUPPORT AND DOCUMENTATION

When you install Filter::Heredoc, manual pages will automatically be
installed. On *nix systems, type "man Filter::Heredoc" or
"perldoc Filter::Heredoc". See also "perldoc Filter::Heredoc::Cookbook"

You can look for more information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filter-Heredoc

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Filter-Heredoc

    CPAN Ratings
        http://cpanratings.perl.org/d/Filter-Heredoc

    Search CPAN
        http://search.cpan.org/dist/Filter-Heredoc/


### LICENSE AND COPYRIGHT

Copyright (C) 2011 Bertil Kronlund

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

