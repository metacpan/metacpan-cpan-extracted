#!/usr/bin/perl -w
use strict;

use File::Basename          qw< dirname >;
use lib dirname(__FILE__) . '/../inc';

use MyTest  qw< plan Okay SkipIf Lives Dies >;

use File::FindLib();

plan( tests => 7 );

my $path = 'word/not-word/one1/2two/tre_3/4for/5.pm';
$INC{$path} = "/root/$path";
{   no strict 'refs';
    ${'word::not-word::one1::2two::tre_3::4for::5::VERSION'} = 1.01;
    ${'not-word::one1::2two::tre_3::4for::5::VERSION'} = 1.01;
    ${'one1::2two::tre_3::4for::'}{'5::'} = 1.01;   # Not package
    ${'2two::tre_3::4for::5::VERSION'} = 1.01;
    ${'tre_3::4for::5::VERSION'} = 1.01;
    ${'4for::5::VERSION'} = 1.01;
    ${'5::VERSION'} = 1.01;
}
my $r = 'tre_3/4for/5.pm';

*UpdateInc = \&File::FindLib::UpdateInc;


# Success case:

my %bef = %INC;
my $start = 0 + keys %INC;

Okay( 1, UpdateInc( $path ), 'claims to update inc' );

Okay( 1, keys(%INC) - $start, 'one more item in %INC' );

Okay( "/root/$path", $INC{$r}, 'worked' );

my @suffs;
my $suff = $path;
push @suffs, $suff
    while  $suff =~ s|^[^/]+/||;
my @set = grep exists $INC{$_}, @suffs;

Okay( $r, "@set", 'which prefix' );

@set = grep ! exists $bef{$_}, keys %INC;

Okay( $r, "@set", 'what is new' );


# Skip module not ending in ".pm":
Okay( 0, UpdateInc('foo/bar.pl'), 'claims no update for .pl' );

# Return 0 if no match found:
Okay( 0, UpdateInc('Foo/Bar.pm'), 'claims no update for no match' );
