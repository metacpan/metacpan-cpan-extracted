package Devel::ebug::Backend::Plugin::SymbolBrowser;

use strict;

sub register_commands {
  return ( package_list    => { sub => \&package_list },
           symbol_list     => { sub => \&symbol_list },
           subroutine_info => { sub => \&subroutine_info },
           );
}

sub package_list {
    my( $req, $context ) = @_;
    my $package = $req->{package};

    require Devel::Symdump;
    my @packages = sort Devel::Symdump->packages( $package );

    return { packages => \@packages, package => $package };
}

my %types =
  ( '&' => 'functions',
    '$' => 'scalars',
    '@' => 'arrays',
    '%' => 'hashes',
    );

sub symbol_list {
    my( $req, $context ) = @_;
    my $package = $req->{package};
    my $types = $req->{types};

    require Devel::Symdump;
    my @symbols = map { my $method = $types{$_};
                        sort Devel::Symdump->$method( $package )
                        } @$types;

    return { symbols => \@symbols, package => $package };
}

sub subroutine_info {
    my( $req, $context ) = @_;
    my $subroutine = $req->{subroutine};
    $subroutine =~ s/^main::(?=\w+::)//;
    my( $filename, $start, $end ) =
        $DB::sub{$subroutine} =~ m/^(.+):(\d+)-(\d+)$/;

    return { filename => $filename, start => $start, end => $end };
}

1;
