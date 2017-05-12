use strict;
use warnings;

package Jifty::Plugin::SimpleColor;
use base qw/Jifty::Plugin Class::Accessor::Fast/;

our $VERSION = '0.20';


=head1 NAME

Jifty::Plugin::SimpleColor - Provides simple jQuery color picker for Jifty

=head1 SYNOPSIS

In your model class schema description, add the following:

   column color1 => is SimpleColor;

In your jifty config.yml under the framework section:

    Plugins:
      - SimpleColor: {}

or

    Plugins:
      - SimpleColor:
          defaultColors:
             - F00
             - 00FF00
             - 00F
             - FFF
             - 000

you can add colors in each model class schema description with

  sub Jifty::Plugin::SimpleColor::Widget::addColors { return "['900', '090', '009', 'ccc']"; }

=cut

__PACKAGE__->mk_accessors(qw(defaultColors));

=head2 init

load config values, javascript and css

=cut


sub init {
    my $self = shift;
    my %opt  = @_;

    my $javatab = ($opt{defaultColors}) ?
            join "','" , @{$opt{defaultColors}} :
            "F00','00FF00','00F','FFF','000','FF9100','FFFA00','C000FF";
    $self->defaultColors( '[\''. $javatab .'\']' );
    Jifty->web->add_javascript(qw( jquery.colorPicker.js ) );
    Jifty->web->add_css('colorPicker.css');
};

use Jifty::DBI::Schema;

sub _simplecolor {
        my ($column, $from) = @_;
        my $name = $column->name;
        $column->type('text');
}

Jifty::DBI::Schema->register_types(
    SimpleColor =>
       sub { _init_handler is \&_simplecolor, render_as 'Jifty::Plugin::SimpleColor::Widget' },
);

=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2010, Yves Agostini.

This program is free software and may be modified and distributed under the same terms as Perl itself.

Embeded jquery.colorPicker.js  Copyright (c) 2008 Lakshan Perera (www.laktek.com)

Licensed under the MIT licenses

=cut


1;
