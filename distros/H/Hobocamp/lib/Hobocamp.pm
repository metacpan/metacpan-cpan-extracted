package Hobocamp;
{
  $Hobocamp::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: Moose-based interface to dialog (simple text based GUI)

use Moose;

use Hobocamp::Dialog;

require Hobocamp::Calendar;
require Hobocamp::CheckList;
require Hobocamp::DirectorySelect;
require Hobocamp::EditBox;
require Hobocamp::FileSelect;
require Hobocamp::InputBox;
require Hobocamp::Menu;
require Hobocamp::MessageBox;
require Hobocamp::Pause;
require Hobocamp::RadioList;
require Hobocamp::TextBox;
require Hobocamp::TimeBox;
require Hobocamp::YesNo;

sub import {
    Hobocamp::Calendar->import;
    Hobocamp::CheckList->import;
    Hobocamp::DirectorySelect->import;
    Hobocamp::EditBox->import;
    Hobocamp::FileSelect->import;
    Hobocamp::InputBox->import;
    Hobocamp::Menu->import;
    Hobocamp::MessageBox->import;
    Hobocamp::Pause->import;
    Hobocamp::RadioList->import;
    Hobocamp::TextBox->import;
    Hobocamp::TimeBox->import;
    Hobocamp::YesNo->import;

    return;
}

sub init {
    my ($self, $in_stream, $out_stream) = @_;

    $in_stream  ||= *STDIN;
    $out_stream ||= *STDOUT;

    return Hobocamp::Dialog::init($in_stream, $out_stream);
}

sub destroy {
    return Hobocamp::Dialog::destroy();
}

1;


__END__
=pod

=head1 NAME

Hobocamp - Moose-based interface to dialog (simple text based GUI)

=head1 VERSION

version 0.600

=head1 SYNOPSIS

    use Hobocamp;

    my $main = Hobocamp->new->init; # prep terminal

    my $menu = Hobocamp::Menu->new; # pass in options...

    $menu->run;

    print 'You selected: ', $menu->value->{'name'};

    # ...

    $main->destroy; # restores terminal

=head1 DESCRIPTION

L<Hobocamp> is for building simple console user interfaces through L<dialog(1)>
in an object oriented way via L<Moose>. L<Hobocamp::Dialog> is a library with a
near 1 to 1 interface of L<dialog(1)>s interface. You can use this independently
of the object oriented way.

This class is used to initialize and destroy the L<dialog(1)>
interface. Additionally auto imports all the widgets into the calling name
space.

Currently L<Hobocamp::Dialog> has the most documentation.

=head1 WHATS A HOBOCAMP?

Not sure, but you could try asking the writers of "Strangers With Candy".

urbandictionary.com had this to say:

    A catchall for words that one doesn't know how to spell. Interchangeable
    with fandango.

    Coach Wulf: "Um, Jerri, what does V-I-C-T-O-R-Y spell?"

    Jerri: "Fandango...? No, hobocamp. Hobocamp!"

I'm terrible at spelling, so this name is adequate. I do want to give a big
shout out to Emacs' flyspell-prog-mode and L<Test::Spelling> for catching my
mistakes while developing this.

=head1 CURRENT CAVEATS

=over

=item * Missing widgets: dialog_form, dialog_gauge, dialog_mixedform,
dialog_mixedgauge, dialog_progressbox, dialog_tailbox

=item * Requires Perl 5.12.2 (until I can test on other versions).

=item * I'm happy with the API, but I may not be tomorrow so consider it close
enough.

=item * Documentation is a little lacking.

=back

=head1 SEE ALSO

=over

=item * dialog/ncurses: L<http://invisible-island.net/dialog> and
L<http://invisible-island.net/ncurses>

=item * F<dialog.h>

=item * L<Moose>

=back

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

