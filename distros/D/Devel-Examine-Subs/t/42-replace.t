#!perl 
use warnings;
use strict;

use Test::More tests => 25;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $file = 't/sample.data';
my $copy = 't/replace_copy.data';

{
    my $des = Devel::Examine::Subs->new(file => $file, copy => $copy);

    my $cref = sub { $_[0] =~ s/^(package\s+\w+(?:::\w+)*)\s+\d+\.\d{2}/$1 1.43/; };

    my $ret = $des->replace(exec => $cref, limit => 1);

    is ( $ret, 1, "limit ensured only one replace was made" );

    open my $fh, '<', $copy or die $!;

    my @file = <$fh>;

    ok ( $file[1] =~ qr/package This::That 1.43/, "replace has done the right thing" );
    ok ( $file[2] =~ qr/package This::Those 0.01/, "replace has done the right thing with limit" );

    eval { unlink $copy };
    ok (! $@, "temp file removed ok" );
} 

{
    my $des = Devel::Examine::Subs->new(file => $file, copy => $copy);

    my $cref = sub { $_[0] =~ s/this/that/g; };

    my $ret = $des->replace(exec => $cref, limit => 1);

    is ( $ret, 1, "limit ensured only one replace was made" );

    open my $fh, '<', $copy or die $!;

    eval { unlink $copy };
    ok (! $@, "temp file removed ok" );
} 
{
    my $des = Devel::Examine::Subs->new(file => $file, copy => $copy);

    my $cref = sub { $_[0] =~ s/this/that/g; };

    my $ret = $des->replace(exec => $cref, limit => 3);

    is ( $ret, 3, "limit set to 3 replaces 3 items" );

    open my $fh, '<', $copy or die $!;

    eval { unlink $copy };
    ok (! $@, "temp file removed ok" );
}
{
    my $des = Devel::Examine::Subs->new(file => $file, copy => $copy);

    my $cref = sub { $_[0] =~ s/this/that/; };

    my $ret = $des->replace(exec => $cref, limit => -1);

    is ( $ret, 5, "limit set to negative int does the right thing" );

    open my $fh, '<', $copy or die $!;

    eval { unlink $copy };
    ok (! $@, "temp file removed ok" );
}
{
    my $des = Devel::Examine::Subs->new(file => $file, copy => $copy);

    my $cref = '';

    eval {
        my $ret = $des->replace(exec => $cref, limit => -1);
    };

    like ( $@, qr/DES::replace/,  "failure if a cref isn't passed into replace()" );
}
{
    my $file = 't/orig';
    my $copy = 't/dir_copy';

    my $warning;
    $SIG{__WARN__} = sub { $warning = shift; };

    my $des = Devel::Examine::Subs->new(
        file => $file, 
        copy => $copy,
        extensions => ['*.data'],
    );

    my $cref = sub { $_[0] =~ s/(?:\}|\{)//g; };

    my $ret = $des->replace(exec => $cref, limit => -1);

    like ($warning, qr/in directory mode, all files/, "_write_file() properly warns");

    is (-d $copy, 1, "copy dir created properly when file param is a dir and we're writing");

    my @files = glob "$copy/*";
    is (@files, 4, "the proper number of files were copied to the new dir");

    for (@files){
        open my $fh, '<', $_ or die $!;
        my $lines = <$fh>;
        my $ok;

        if ($lines !~ /(?:\}|\{)/){
            $ok = 10;
        }
        is ($ok, 10, "$_ has been copied and modified properly"); 

        close $fh;        
        eval { unlink $_ or die $!; };
        is ($@, '', "unlinked $_ copy file ok");
    }

    eval { rmdir $copy or die $!; };
    is ($@, '', "copy dir removed ok");
}
{
    my $file = 't/orig';
    my $copy = '/c:';

    my $warning;
    $SIG{__WARN__} = sub { $warning = shift; };

    my $des = Devel::Examine::Subs->new(
        file => $file, 
        copy => $copy,
        extensions => ['*.data'],
    );

    my $cref = sub { $_[0] =~ s/(?:\}|\{)//g; };

    eval { $des->replace(exec => $cref, limit => -1); };

    my $err;
    $err = 1 if $@;

    is ($err, 1, "_write_file croaks in dir mode if the copy dir can't be created");
}
