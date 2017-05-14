# $Id: Python.pm,v 1.3 2002/05/12 14:54:12 itz Exp $

package Debian::Debarnacle::Python;

use File::Find;

our @python_dirs = ('/usr/lib/idle-python2.1',
                       '/usr/lib/python2.1',
                       '/usr/lib/site-python',
                       '/usr/lib/sketch-0.6.13',
                       );

our @python_files;

sub add_pyfile {
    push @python_files, $File::Find::name
        if -f $File::Find::name && $File::Find::name =~ /\.py[co]$/ ;
}

sub get_list {
    @python_files = ();
    find (\&add_pyfile, @python_dirs);
    return \@python_files;
}

1;
