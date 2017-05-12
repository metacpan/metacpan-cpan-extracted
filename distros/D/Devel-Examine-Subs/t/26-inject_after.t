#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{#1
    my $base_file = 't/orig/inject_after.data';

    my %params = (
                    file => 't/sample.data',
                    copy => 't/inject_after.data',
                    post_proc => ['file_lines_contain', 'subs', 'objects'],
                    engine => 'inject_after',
                    search => 'this',
                    code => ['# comment line one', '# comment line 2' ],
                  );

    my $des = Devel::Examine::Subs->new(%params);

    my $struct = $des->run();

    ok ( ref($struct) eq 'ARRAY', "search_replace engine returns an aref" );
    ok ( $struct->[0] =~ qr/\w+/, "elems of inject_after are simple names of subs" );
    is ( @$struct, 5, "return from inject_after contains the proper number of subs with 'file_lines_contain' post_proc" );

    my (@base_file, @test_file);

    eval { open my $fh, '<', $base_file or die $!; @base_file = <$fh>;};
    ok (! $@, "tied $base_file ok for inject_after" );

    eval { open my $fh, '<', $params{copy} or die $!; @test_file = <$fh>;};
    ok (! $@, "tied $params{copy} ok for inject_after" );

    my $i = 0;
    for (@base_file){
        #if ($i == 7){
        #    print ">$base_file[$i]< :: >$test_file[$i]<\n";
        #};
        ok ($base_file[$i] eq $test_file[$i], "Line $i in base file matches line $i in test file" );
        $i++;
    }
}
{#2
    my $base_file = 't/orig/inject_after.data';

    my %params = (
                    file => 't/sample.data',
                    copy => 't/inject_after.data',
                    search => 'this',
                    code => ['# comment line one', '# comment line 2' ],
                  );

    my $des = Devel::Examine::Subs->new(%params);

    my $struct = $des->inject_after();

    ok ( ref($struct) eq 'ARRAY', "inject_after() returns an aref" );
    ok ( $struct->[0] =~ qr/\w+/, "elems of inject_after() are simple names of subs" );
    is ( @$struct, 5, "return from inject_after() contains the proper number of subs with 'file_lines_contain' post_proc" );

    my (@base_file, @test_file);

    eval { open my $fh, '<', $base_file or die $!; @base_file = <$fh>;};
    ok (! $@, "tied $base_file ok for inject_after" );

    eval { open my $fh, '<', $params{copy} or die $!; @test_file = <$fh>;};
    ok (! $@, "tied $params{copy} ok for inject_after" );

    my $i = 0;
    for (@base_file){
        ok ($base_file[$i] eq $test_file[$i], "Line $i in base file matches line $i in test file for inject_after()" );
        $i++;
    }
}
{#3
    my $file = 't/test/inject_after/inject_after.pm';

    my %params = (
                    file => $file,
                    copy => 't/test/inject_after/inject_after.copy',
                    search => 'this',
                    code => ['# inject_after_test'],
                    injects => 1,
                  );

    my $des = Devel::Examine::Subs->new(%params);

    my $struct = $des->inject_after(%params);

    eval { open my $fh, '<', $params{copy} or die $!; };
    ok (! $@, "can open the inject_after copy file" );
    open my $fh, '<', $params{copy} or die $!;
    
    my @fh = <$fh>;
    close $fh;
    
    my $count = grep /inject_after_test/, @fh;

    is ($count, 1, "setting 'injects' to 1 injects only once");
}
{#4
    my $file = 't/test/inject_after/inject_after.pm';

    my %params = (
                    file => $file,
                    copy => 't/test/inject_after/inject_after.copy',
                    search => 'this',
                    code => ['# inject_after_test'],
                    injects => 2,
                  );

    my $des = Devel::Examine::Subs->new(%params);

    my $struct = $des->inject_after(%params);

    eval { open my $fh, '<', $params{copy} or die $!; };
    ok (! $@, "can open the inject_after copy file" );
    open my $fh, '<', $params{copy} or die $!;
    
    my @fh = <$fh>;
    close $fh;

    my $count = grep /inject_after_test/, @fh;

    is ($count, 2, "setting 'injects' to 2 injects only once");
}
{#5
    my $file = 't/test/inject_after/inject_after.pm';

    my %params = (
                    file => $file,
                    copy => 't/test/inject_after/inject_after.copy',
                    search => 'this',
                    code => ['# inject_after_test'],
                  );

    delete $params{inject};
    is ($params{inject}, undef, "successfully deleted 'inject' param" );

    my $des = Devel::Examine::Subs->new(%params);

    my $struct = $des->inject_after(%params);

    eval { open my $fh, '<', $params{copy} or die $!; };
    ok (! $@, "can open the inject_after copy file" );
    open my $fh, '<', $params{copy} or die $!;
    
    my @fh = <$fh>;
    close $fh;

    my $count = grep /inject_after_test/, @fh;

    is ($count, 1, "'injects' defaults to one inject only");
}
{#6
    my $file = 't/test/inject_after/inject_after.pm';

    my %params = (
                    file => $file,
                    copy => 't/test/inject_after/inject_after.copy',
                    search => 'this',
                    code => ['# inject_after_test'],
                    injects => -1,
                  );

    my $des = Devel::Examine::Subs->new(%params);

    my $struct = $des->inject_after(%params);

    eval { open my $fh, '<', $params{copy} or die $!; };
    ok (! $@, "can open the inject_after copy file" );
    open my $fh, '<', $params{copy} or die $!;
    
    my @fh = <$fh>;
    close $fh;

    my $count = grep /inject_after_test/, @fh;

    is ($count, 3, "'injects' injects after all search finds if a negative int is sent in");
}
{#7
    my $file = 't/test/inject_after/inject_after.pm';

    my %params = (
                    file => $file,
                    copy => 't/test/inject_after/inject_after.copy',
                    search => 'this',
                    code => ['# inject_after_test'],
                  );

    delete $params{inject};
    is ($params{inject}, undef, "successfully deleted 'inject' param" );

    my $des = Devel::Examine::Subs->new(injects => 2);

    my $struct = $des->inject_after(%params);

    eval { open my $fh, '<', $params{copy} or die $!; };
    ok (! $@, "can open the inject_after copy file" );
    open my $fh, '<', $params{copy} or die $!;
    
    my @fh = <$fh>;
    close $fh;

    my $count = grep /inject_after_test/, @fh;

    is ($count, 2, "'injects' param is carried through from new()");
}
{
    my $base_file = 't/orig/inject_after.data';

    my %params = (
        file      => 't/sample.data',
        copy      => 't/inject_after.data',
        post_proc => [ 'file_lines_contain', 'subs', 'objects' ],
        engine    => 'inject_after',
        #search => 'this',
        code      => [ '# comment line one', '# comment line 2' ],
    );

    my $des = Devel::Examine::Subs->new(%params);

    eval { my $struct = $des->run(); };
    like ($@,
          qr/inject_after engine without specifying a search term/,
          "without a search term, inject_after() croaks"
    );
}
{
    my $base_file = 't/orig/inject_after.data';

    my %params = (
        file      => 't/sample.data',
        copy      => 't/inject_after.data',
        post_proc => [ 'file_lines_contain', 'subs', 'objects' ],
        engine    => 'inject_after',
        search => 'this',
        #code      => [ '# comment line one', '# comment line 2' ],
    );

    my $des = Devel::Examine::Subs->new(%params);

    eval { my $struct = $des->run(); };
    like ($@,
          qr/inject_after engine without code to inject/,
          "without the code param, inject_after() croaks"
    );
}
{
    my $base_file = 't/orig/inject_after.data';

    my %params = (
        file      => 't/sample.data',
        copy      => 't/inject_after.data',
        post_proc => [ 'file_lines_contain', 'subs', 'objects' ],
        engine    => 'inject_after',
        search    => 'this',
        code      => [ '# comment line one', '# comment line 2' ],
        regex     => 0,
    );

    my $des = Devel::Examine::Subs->new(%params);

    eval { my $struct = $des->run(); };
    is ($@, '', "with regex off, inject_after() still works");
}

my @tempfiles = (
                't/test/inject_after/inject_after.copy',
                # inject_after.pm.bak #FIXME: backup() currently disabled
              );

my $fh;

for (@tempfiles){

    eval { open $fh, '<', $_ or die $!; };
    ok (! $@, "inject_after() properly creates a $_ file and it can be opened" );
    eval {close $fh;};
    ok (! $@, "successfully closed the $_ file" );

    eval { unlink $_; };
    ok (! $@, "unlinked $_ temp file" );
    eval { open my $fh, '<', $_ or die $!; };
    ok ($@, "temp file really is deleted" );
}

done_testing();
