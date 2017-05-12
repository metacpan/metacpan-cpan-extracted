#!/usr/bin/perl

use strict;
use warnings;

use lib qw([% this.get_base_path %]/lib);

use Hyper::Developer::Server;
Hyper::Developer::Server->new({
    'Hyper::Developer::Server' => {
        config_file => '[% this.get_base_path %]/etc/[% this.get_namespace %]/Context.ini',
    },
})->run();

__END__
[%# work around for CPAN's indexer, which gets disturbed by pod in templates -%]
[% pod = BLOCK %]=pod[% END -%]

=head1 NAME

 [% this.get_namespace %] - a Hyper Developer Test Server

=head1 DESCRIPTION

 Test Server for [% this.get_namespace %]

=cut
