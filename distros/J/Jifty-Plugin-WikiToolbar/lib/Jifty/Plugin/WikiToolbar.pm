use strict;
use warnings;

package Jifty::Plugin::WikiToolbar;
use base qw/Jifty::Plugin/;

our $VERSION = '1.00';

=head1 NAME

Jifty::Plugin::WikiToolbar - Jifty plugin to add a wiki toolbar to your textarea box

=head1 SYNOPSIS

In etc/config.yml

   Plugins:
     - WikiToolbar: {}

In your Model instead of 

   render_as 'textarea';

use

   is WikiToolbar;

or you can custom rows size with

 sub Jifty::Plugin::WikiToolbar::Textarea::rows { return 15; };

To custom the toolbar, copy wikitoolbar.js in your application, at the end of the file put your changes with addButton function.

=head1 DESCRIPTION

Add a toolbar to your textarea field. Default toolbar provide markdown markup syntax. http://daringfireball.net/projects/markdown/

=head1 METHOD

=head2 init

load wikitoolbar.js on startup

=cut

sub init {
    my $self = shift;
    Jifty->web->javascript_libs([
    @{ Jifty->web->javascript_libs },
    "wikitoolbar.js",
    ]);
};

use Jifty::DBI::Schema;

sub _toolbar {
        my ($column, $from) = @_;
        my $name = $column->name;
        $column->type('text');
};

Jifty::DBI::Schema->register_types(
    WikiToolbar =>
       sub { _init_handler is \&_toolbar, render_as 'Jifty::Plugin::WikiToolbar::Textarea' },
);


=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2007-2010, Yves Agostini

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
