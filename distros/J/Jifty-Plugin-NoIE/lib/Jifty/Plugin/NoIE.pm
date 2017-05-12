package Jifty::Plugin::NoIE;
use base qw/Jifty::Plugin/;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Jifty::Plugin::NoIE - For IE (Internet Explorer) users , we suggest them to use other web browsers.

=head1 DESCRIPTION

For IE (Internet Explorer) users , we suggest them to use other web browsers.

=head1 SYNOPSIS

render browser detect javascript, IE users will be redirected to /noie page .

    show '/noie_redirect';

=head1 AUTHOR

Cornelius C< <cornelius.howl {at} gmail.com> >

=cut

1;
