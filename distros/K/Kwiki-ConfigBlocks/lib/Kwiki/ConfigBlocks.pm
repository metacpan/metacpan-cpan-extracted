package Kwiki::ConfigBlocks;

=head1 NAME

Kwiki::ConfigBlocks - Config kwiki page behavior in the kwiki page

=cut

use strict;
use warnings;
use Kwiki::Plugin '-Base';
use YAML;
our $VERSION = '0.01';

const class_id => 'config_blocks';
const class_title => 'Config Blocks';

field pageconf => {};

sub register {
    my $registry = shift;
    $registry->add(wafl => config => 'Kwiki::ConfigBlocks::Wafl');
}

package Kwiki::ConfigBlocks::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    my $conf = {};
    eval { $conf = YAML::Load($self->block_text) };
    $self->hub->config_blocks->pageconf($conf) unless $@;
    my $dump = YAML::Dump($conf);
    return qq{<!-- Config: \n$dump\n-->};
}


1;

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
