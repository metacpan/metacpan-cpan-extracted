#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 10;

use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";

my $file = 't/sample.data';
my $copy = 't/inject.copy';
my @code = <DATA>;

my $des = Devel::Examine::Subs->new (
    file => $file,
    copy => $copy,
);

my $rw = File::Edit::Portable->new;

{
    $des->inject(code => \@code, line_num => 0);
    
    my @c = $rw->read($copy);

    is ($c[0], 'one', "inject() inserts at the proper spot with line_num => 0");

    eval { unlink $copy; };
    is ($@, '', "unlinked copy file $copy ok");
}
{
    $des->inject(code => \@code, line_num => 5);

    my @c = $rw->read($copy);

    is ($c[5], 'one', "inject() inserts at the proper spot with line_num => 5");

    eval { unlink $copy; };
    is ($@, '', "unlinked copy file $copy ok");
}
{
    # inject use

    my @code = ('use This::Test;');

    $des->inject(inject_use => \@code);
    
    my @c = $rw->read($copy);

    is ($c[2], 'use This::Test;', "inject() inserts use statement properly");

    eval { unlink $copy; };
    is ($@, '', "unlinked copy file $copy ok");
}
{
    # inject after sub def

    my $copy = 't/inject.debug';

    my $des = Devel::Examine::Subs->new(
        file => 't/orig/inject.data',
        copy => $copy,
    );

    $des->inject(inject_after_sub_def => \@code);

    my @c = $rw->read($copy);

    is ($c[4], '    one', "inject() inserts use statement properly after multi-line sub def");

    print "$_\n" for @c;

    eval { unlink $copy; };
    is ($@, '', "unlinked copy file $copy ok");
}
__DATA__
one
two

three
