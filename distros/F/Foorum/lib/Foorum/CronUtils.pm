package Foorum::CronUtils;

use strict;
use warnings;

our $VERSION = '1.001000';

use YAML::XS qw/LoadFile/;    # config
use File::Spec;
use DBI;
use base 'Exporter';
use vars qw/@EXPORT_OK $cron_config/;
@EXPORT_OK = qw/ cron_config /;
use Foorum::XUtils qw/config base_path/;

sub cron_config {

    return $cron_config if ($cron_config);

    my $base_path = base_path();
    $cron_config
        = LoadFile( File::Spec->catfile( $base_path, 'conf', 'cron.yml' ) );

    return $cron_config;
}

1;
__END__

