use 5.008;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Build;
use My::Module::Meta;
use Module::Build;

(my $mbv = Module::Build->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    dist_author => 'Tom Wyant (wyant at cpan dot org)',
    dist_abstract => 'Get elevation data from the USGS',
    module_name => 'Geo::WebService::Elevation::USGS',
    build_requires => $meta->build_requires(),
    requires => $meta->requires(
	perl	=> $meta->requires_perl(),
    ),
    add_to_cleanup => [ qw{ xt/optionals } ],
    license => 'perl',
    add_to_cleanup	=> [ qw{ cover_db } ],
);

$mbv >= 0.28
    and $args{meta_merge} = $meta->meta_merge();

# Don't require Module::Build if we're making a distribution, since the
# user can use ExtUtils::MakeMaker.
$mbv >= 0.34
    and $args{auto_configure_requires} = !$meta->distribution();

my $bldr = My::Module::Build->new (%args);

$bldr->create_build_script ();

# ex: set textwidth=72 :
