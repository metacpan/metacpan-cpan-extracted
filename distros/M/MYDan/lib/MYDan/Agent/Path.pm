package MYDan::Agent::Path;

use strict;
use warnings;

=head1 NAME

MYDan::Agent::Path - Implements MYDan::Util::DirConf

=cut
use strict;
use base qw( MYDan::Util::DirConf );

=head1 CONFIGURATION

A YAML file that defines I<code>, I<run> paths.
Each must be a valid directory or symbolic link.

=cut
sub define { qw( code run ) }

1;
