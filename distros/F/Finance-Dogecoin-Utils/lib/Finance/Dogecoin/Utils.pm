package Finance::Dogecoin::Utils;
# ABSTRACT: Libraries and Utilities to work with Dogecoin
$Finance::Dogecoin::Utils::VERSION = '1.20230424.0253';
use strict;
use warnings;

use File::HomeDir;
use Path::Tiny;

use Exporter::Shiny our @EXPORT = qw( get_conf_dir get_auth_file get_dogecoin_conf_dir );

sub get_conf_dir {
    return path(File::HomeDir->my_data)->child('dogeutils')->mkdir;
}

sub get_auth_file {
    return get_conf_dir()->child( 'auth.json' );
}

sub get_dogecoin_conf_dir {
    return path(File::HomeDir->my_home)->child('.dogecoin')->child('backups');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Dogecoin::Utils - Libraries and Utilities to work with Dogecoin

=head1 VERSION

version 1.20230424.0253

=head1 SYNOPSIS

See L<dogeutils>

=head1 COPYRIGHT

Copyright (c) 2022-2023 chromatic

=head1 AUTHOR

chromatic

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by chromatic.

This is free software, licensed under:

  The MIT (X11) License

=cut
