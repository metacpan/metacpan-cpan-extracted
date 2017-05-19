#line 1
package Test::LoadAllModules;
use strict;
use warnings;
use Module::Pluggable::Object;
use List::MoreUtils qw(any);
use Test::More ();

our $VERSION = '0.021';

use Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/all_uses_ok/;

sub all_uses_ok {
    my %param       = @_;
    my $search_path = $param{search_path};
    unless ($search_path) {
        Test::More::plan skip_all => 'no search path';
        exit;
    }
    Test::More::plan('no_plan');
    my @exceptions = @{ $param{except} || [] };
    my @lib
        = @{ $param{lib} || [ 'lib' ] };
    foreach my $class (
        grep { !is_excluded( $_, @exceptions ) }
        sort do {
            local @INC = @lib;
            my $finder = Module::Pluggable::Object->new(
                search_path => $search_path );
            ( $search_path, $finder->plugins );
        }
        )
    {
        Test::More::use_ok($class);
    }
}

sub is_excluded {
    my ( $module, @exceptions ) = @_;
    any { $module eq $_ || $module =~ /$_/ } @exceptions;
}

1;

__END__

#line 110
