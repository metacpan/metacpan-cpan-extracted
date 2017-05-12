#!perl -w
use strict;
use Test::More tests => 8;
use File::Find::Rule;
use File::Find::Rule::Filesys::Virtual;
use Filesys::Virtual::Plain;
use Cwd;

if (eval { require Test::Differences; 1 }) {
    no warnings 'redefine';
    *is_deeply = \&Test::Differences::eq_or_diff;
}

my $virtual = Filesys::Virtual::Plain->new({
    root_path => getcwd,
    cwd       => '/',
    root      => '/',
});

sub new_real { File::Find::Rule->new }
sub new_virt { File::Find::Rule::Filesys::Virtual->new->virtual( $virtual ) }

isa_ok( new_real, "File::Find::Rule" );
isa_ok( new_virt, "File::Find::Rule::Filesys::Virtual" );
is_deeply( [ new_virt->file->name('*.t')->in( 't' ) ],
           [ new_real->file->name('*.t')->in( 't' ) ],
           "files in t/" );

is_deeply( [ new_virt->size('>600')->name('*.t')->in( 't' ) ],
           [ new_real->size('>600')->name('*.t')->in( 't' ) ],
           "stat in t/" );

is_deeply( [ new_virt->or( new_virt->name('.svn')->prune->discard,
                           new_virt->file )->in( 't' ) ],
           [ new_real->or( new_real->name('.svn')->prune->discard,
                           new_real->file )->in( 't' ) ],
           "prune .svn" );

is_deeply( [ new_virt->grep(qr/irony/)->in('t') ],
           [ new_real->grep(qr/irony/)->in('t') ],
           "find irony in our big file");

# the in may not always be a directory
is_deeply( [ new_virt->size('>600')->name('*.t')->in( 't/findvirtual.t' ) ],
           [ new_real->size('>600')->name('*.t')->in( 't/findvirtual.t' ) ],
           "stat of t/findvirtual.t" );

# and it may be a file and a directory
is_deeply( [ new_virt->size('>600')->name('*.t')->in( 't/findvirtual.t',
                                                      't/subdir' ) ],
           [ new_real->size('>600')->name('*.t')->in( 't/findvirtual.t',
                                                      't/subdir' ) ],
           "stat of t/findvirtual.t t/subdir" );
