package MColPro::Util::Plugin;

=head1 NAME

 MColPro::Util::Plugin - Load plugin code

=cut

use strict;
use warnings;

use Carp;

sub new
{   
    my ( $class, $code ) = splice @_;

    confess "undefined code" unless $code;
    $code = readlink $code if -l $code;

    my $error = "invalid code $code";
    confess "$error: not a regular file" unless -f $code;

    $code = do $code;
    confess "$error: $@" if $@;

    bless $code, ref $class || $class;
}

1;
