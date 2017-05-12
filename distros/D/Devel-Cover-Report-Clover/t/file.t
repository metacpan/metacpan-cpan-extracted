#!perl

use Test::More;

use Devel::Cover::Report::Clover::Builder;

use FindBin;
use lib ($FindBin::Bin);
use testcover;

my $DB = testcover::run('multi_file');

my $b = BUILDER( { name => 'test', db => $DB } );
my @files = @{ $b->file_registry->files };

my @test = (
    sub {
        my $t = "files - file registry has all files listed";
        is( scalar @files, 3, $t );
    },
);

my %expected_file_stats = (
    'MultiFile/First.pm' => {
        loc         => 3,
        ncloc       => 6,
        line_count  => 9,
        class_count => 1,
        total       => {
            covered    => 3,
            percentage => 100,
            total      => 3,
        }
    },
    'MultiFile/Second.pm' => {
        loc         => 2,
        ncloc       => 6,
        line_count  => 8,
        class_count => 1,
        total       => {
            covered    => 3,
            percentage => 100,
            total      => 3,
        }
    },
    'MultiFile.pm' => {
        loc         => 12,
        ncloc       => 22,
        line_count  => 34,
        class_count => 2,
        total       => {
            covered    => 19,
            error      => 3,
            percentage => '86.3636363636364',
            total      => 29,
        }
    },
);

foreach my $file (@files) {
    ( my $rel_path = $file ) =~ s{.*cover_db_test/multi_file/}{};
    my $expected = $expected_file_stats{$rel_path};
    push @test, sub {
        my $t   = "loc - $file";
        my $got = $file->loc;
        is( $got, $expected->{loc}, $t );
    };
    push @test, sub {
        my $t   = "ncloc - $file";
        my $got = $file->ncloc;
        is( $got, $expected->{ncloc}, $t );
    };
    push @test, sub {
        my $t   = "line count - $file";
        my $got = scalar @{ $file->lines };
        is( $got, $expected->{line_count}, $t );
    };
    push @test, sub {
        my $t   = "summary calculation - $file";
        my $got = $file->summarize();

        is( $got->{total}->{total},   $expected->{total}->{total},   "$t - total" );
        is( $got->{total}->{covered}, $expected->{total}->{covered}, "$t - covered" );
    };
    push @test, sub {
        my $t       = "class count -> $file";
        my @classes = @{ $file->classes };
        my $got     = scalar @classes;
        is( $got, $expected->{class_count}, $t );
        }
}

plan tests => scalar @test + ( 1 * scalar @files );

$_->() foreach @test;

sub BUILDER {
    return Devel::Cover::Report::Clover::Builder->new(shift);
}

