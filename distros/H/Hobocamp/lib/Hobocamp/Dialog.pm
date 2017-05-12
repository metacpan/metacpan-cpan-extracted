package Hobocamp::Dialog;
{
  $Hobocamp::Dialog::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: Perl access to L<dialog(1)>s widget set

use Carp qw(croak);

use Sub::Exporter;

my @constants = qw(
  DLG_EXIT_CANCEL
  DLG_EXIT_ERROR
  DLG_EXIT_ESC
  DLG_EXIT_EXTRA
  DLG_EXIT_HELP
  DLG_EXIT_ITEM_HELP
  DLG_EXIT_OK
  DLG_EXIT_UNKNOWN
);

my @widgets = qw(
  dialog_calendar
  dialog_checklist
  dialog_dselect
  dialog_editbox
  dialog_fselect
  dialog_gauge
  dialog_inputbox
  dialog_menu
  dialog_msgbox
  dialog_pause
  dialog_textbox
  dialog_timebox
  dialog_yesno
);

my @util = qw(
  init
  destroy
  dialog_version
  dlg_clr_result
  dlg_put_backtitle
);

my @extra = qw(
  _dialog_result
  _dialog_set_backtitle
);

Sub::Exporter::setup_exporter(
    {
        'exports' => \@constants,
        'groups'  => {'constants' => \@constants, 'widgets' => \@widgets, 'util' => \@util}
    }
);

sub AUTOLOAD {

    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak '&Hobocamp::constant not defined' if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs'; ## no critic
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Hobocamp::Dialog', $Hobocamp::Dialog::VERSION);

1;


__END__
=pod

=head1 NAME

Hobocamp::Dialog - Perl access to L<dialog(1)>s widget set

=head1 VERSION

version 0.600

=head1 SYNOPSIS

    use Hobocamp::Dialog;

    Hobocamp::Dialog::init(*STDIN, *STDOUT);

    my $widget = Hobocamp::Menu->new(
        'items'       => [ { 'name' => 'item 1', 'text' => 'thing 1' },
                           { 'name' => 'item 2', 'text' => 'thing 2' }],
        'list_height' => 5,
        'title'       => 'A simple menu',
        'prompt'      => 'Choose one'
    );

    $widget->run; # skipped checking returned dialog code for brevity

    print 'You chose: ', $widget->value->{'name'};

=head1 DESCRIPTION

Hobocamp::Dialog is a direct interface to L<dialog(1)>. It does almost a one to
one mapping as defined in F<dialog.h>.

=head1 MISSING WIDGETS

dialog_form, dialog_gauge, dialog_mixedform, dialog_mixedgauge, dialog_progressbox, dialog_tailbox

=head2 EXPORT

=head2 :widgets

=over

=item * C<dialog_calendar($title, $subtitle, $height, $width, $day, $month, $year)>

Defaults: C<$day = 1>, C<$month = 1>, C<$year = 1970>

Widget: L<Hobocamp::Calendar>

=item * C<dialog_checklist($title, $prompt, $height, $width, $list_height, [ { name => $name, text => $text, on => $bool }, ... ])>

Defaults: C<$list_height = 1>

Widget: L<Hobocamp::CheckList>

=item * C<dialog_dselect($title, $path, $height, $width)>

Widget: L<Hobocamp::DirectorySelect>

=item * C<dialog_editbox($title, $file, $height, $width)>

Widget: L<Hobocamp::EditBox>

=item * C<dialog_fselect($title, $path, $height, $width)>

Widget: L<Hobocamp::FileSelect>

=item * C<dialog_inputbox($title, $prompt, $height, $width, $initial_text, $password_field_or_not)>

Widget: L<Hobocamp::InputBox>

=item * C<dialog_menu($title, $prompt, $height, $width, $menu_height, [ { name => $name, text => $text }, ... ])>

Defaults: C<$menu_height = 1>

Widget: L<Hobocamp::Menu>

=item * C<dialog_msgbox($title, $title, $height, $width, $pause_or_not)>

Defaults: C<$pause_or_not = 1>

Widget: L<Hobocamp::MessageBox>

=item * C<dialog_pause($title, $prompt, $height, $width, $seconds)>

Defaults: C<$seconds = 10>

Widget: L<Hobocamp::Pause>

=item * C<dialog_textbox($title, $file, $height, $width)>

Widget: L<Hobocamp::TextBox>

=item * C<dialog_radiolist($title, $prompt, $height, $width, $list_height, [ { name => $name, text => $text, on => $bool }, ... ])>

Defaults: C<$list_height = 1>

Widget: L<Hobocamp::RadioList>

=item * C<dialog_timebox($title, $subtitle, $height, $width, $hour, $minute, $second)>

Defaults: C<$hour = 12>, C<$minute = 0>, C<$second = 0>

Widget: L<Hobocamp::TimeBox>

=item * C<dialog_yesno($title, $prompt, $height, $width)>

Widget: L<Hobocamp::YesNo>

=back

=head2 :util

  init
  destroy
  dialog_version
  dlg_clr_result
  dlg_put_backtitle

=head2 :constants

These correspond to what is in F<dialog.h>.

    DLG_EXIT_CANCEL
    DLG_EXIT_ERROR
    DLG_EXIT_ESC
    DLG_EXIT_EXTRA
    DLG_EXIT_HELP
    DLG_EXIT_ITEM_HELP
    DLG_EXIT_OK
    DLG_EXIT_UNKNOWN

=head2 :extra

    _dialog_result
    _dialog_set_backtitle

=head1 SEE ALSO

=over

=item * L<dialog(1)>, F<dialog.h>

=back

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

