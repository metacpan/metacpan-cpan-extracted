#!/usr/bin/perl

use strict;
use warnings;

use lib qw([% this.get_base_path %]/lib);

use Hyper;
use Hyper::Error fatal => 1, warn => 0;
use Hyper::Singleton::Context;
Hyper::Singleton::Context->new({
    file => '[% this.get_base_path %]/etc/[% this.get_namespace %]/Context.ini',
});

Hyper->new()->work();

__END__
[%# work around for CPAN's indexer, which gets disturbed by pod in templates -%]
[% pod = BLOCK %]=pod[% END -%]

=head1 NAME

 [% this.get_namespace %] - a Hyper based Application

=head1 DESCRIPTION

 CGI User Interface for all Applications of [% this.get_namespace %]

=cut
