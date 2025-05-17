package EBook::Gutenberg::Dialog;
use 5.016;
our $VERSION = '1.00';
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(
    DIALOG_OK
    DIALOG_CANCEL
    DIALOG_HELP
    DIALOG_EXTRA
    DIALOG_ITEM_HELP
    DIALOG_TIMEOUT
    DIALOG_ERROR
    DIALOG_ESC
);

our %EXPORT_TAGS = (
    codes => [ qw(
        DIALOG_OK
        DIALOG_CANCEL
        DIALOG_HELP
        DIALOG_EXTRA
        DIALOG_ITEM_HELP
        DIALOG_TIMEOUT
        DIALOG_ERROR
        DIALOG_ESC
    ) ],
);

use File::Temp qw(tempfile);

use constant {
    DIALOG_OK        => 0,
    DIALOG_CANCEL    => 1,
    DIALOG_HELP      => 2,
    DIALOG_EXTRA     => 3,
    DIALOG_ITEM_HELP => 4,
    DIALOG_TIMEOUT   => 5,
    DIALOG_ERROR     => 6,
    DIALOG_ESC       => 7,
};

@ENV{ qw(
    DIALOG_OK
    DIALOG_CANCEL
    DIALOG_HELP
    DIALOG_EXTRA
    DIALOG_ITEM_HELP
    DIALOG_TIMEOUT
    DIALOG_ERROR
    DIALOG_ESC
) } = (
    DIALOG_OK,
    DIALOG_CANCEL,
    DIALOG_HELP,
    DIALOG_EXTRA,
    DIALOG_ITEM_HELP,
    DIALOG_TIMEOUT,
    DIALOG_ERROR,
    DIALOG_ESC
);

my %MTHD_OPTS = (
    title         => [ '--title %s',        1 ],
    ok_label      => [ '--ok-label %s',     1 ],
    yes_label     => [ '--yes-label %s',    1 ],
    cancel_label  => [ '--cancel-label %s', 1 ],
    no_label      => [ '--no-label %s',     1 ],
    extra_button  => [ '--extra-button',    0 ],
    extra_label   => [ '--extra-label %s',  1 ],
    help_button   => [ '--help-button',     0 ],
    help_label    => [ '--help-label %s',   1 ],
    erase_on_exit => [ '--erase-on-exit',   0 ],
);

my %ATTR_OPTS = (
    backtitle => [ '--backtitle %s', 1 ],
);

my $TMP = do {
    my ($fh, $fn) = tempfile;
    close $fh;
    $fn;
};

sub _quote {

    my $str = shift;

    $str =~ s/(["\\`"\$])/\\$1/g;

    return qq("$str");

}

sub _cmd {

    my $cmd = shift;

   system "$cmd 2>$TMP";

   open my $fh, '<', $TMP
        or die "Failed to open $TMP for reading: $!\n";
    my $text = do { local $/ = undef; <$fh> };
    close $fh;

    return ($? >> 8, $text);

}

sub _build_dialog_cmd {

    my $self  = shift;
    my $param = shift;
    my $args  = shift;

    my $cmd = "$self->{ backend } ";

    for my $k (keys %ATTR_OPTS) {
        next unless defined $self->{ $k };
        $cmd .= $ATTR_OPTS{ $k }->[1]
            ? sprintf "$ATTR_OPTS{ $k }->[0] ", _quote($self->{ $k })
            : "$ATTR_OPTS{ $k }->[0] ";
    }

    for my $k (keys %$param) {
        next unless exists $MTHD_OPTS{ $k };
        $cmd .= $MTHD_OPTS{ $k }->[1]
            ? sprintf "$MTHD_OPTS{ $k }->[0] ", _quote($param->{ $k })
            : "$MTHD_OPTS{ $k }->[0] ";
    }

    $cmd .= join ' ', map { _quote($_) } @$args;

    $cmd =~ s/ $//;

    return $cmd;

}

sub _backend_ok {

    my $self = shift;
    my $backend = shift // $self->{ backend };

    qx/$backend -v 2>&1/;

    return $? == 0;

}

sub new {

    my $class = shift;
    my %param = @_;

    my $self = {};

    $self->{ backend } = $param{ backend } // 'dialog';
    $self->{ backtitle } = $param{ backtitle } // undef;

    bless $self, $class;

    unless ($self->_backend_ok) {
        die "Failed to initialize dialog interface: $self->{ backend } is not available\n";
    }

    return $self;

}

sub backend {

    my $self = shift;

    return $self->{ backend };

}

sub set_backend {

    my $self    = shift;
    my $backend = shift;

    unless ($self->_backend_ok($backend)) {
        die "$backend is not available";
    }

    $self->{ backend } = $backend;

}

sub backtitle {

    my $self = shift;

    return $self->{ backtitle };

}

sub set_backtitle {

    my $self      = shift;
    my $backtitle = shift;

    $self->{ backtitle } = $backtitle;

}

sub form {

    my $self = shift;
    my @args = @_;
    my $param = ref $args[-1] eq 'HASH' ? pop @args : {};

    my $cmd = $self->_build_dialog_cmd(
        $param,
        [ '--form', @args ],
    );

    my ($rv, $rt) = _cmd($cmd);

    return ($rv, [ $rt =~ m/([^\n]*)\n/g ]);

}

sub infobox {

    my $self = shift;
    my @args = @_;
    my $param = ref $args[-1] eq 'HASH' ? pop @args : {};

    my $cmd = $self->_build_dialog_cmd(
        $param,
        [ '--infobox', @args ],
    );

    my $rv = _cmd($cmd);

    return $rv;

}

sub inputbox {

    my $self = shift;
    my @args = @_;
    my $param = ref $args[-1] eq 'HASH' ? pop @args : {};

    my $cmd = $self->_build_dialog_cmd(
        $param,
        [ '--inputbox', @args ],
    );

    my ($rv, $rt) = _cmd($cmd);
    chomp $rt;

    return ($rv, $rt);

}

sub menu {

    my $self = shift;
    my @args = @_;
    my $param = ref $args[-1] eq 'HASH' ? pop @args : {};

    my $cmd = $self->_build_dialog_cmd(
        $param,
        [ '--menu', @args ],
    );

    my ($rv, $rt) = _cmd($cmd);
    chomp $rt;

    return ($rv, $rt);

}

sub msgbox {

    my $self = shift;
    my @args = @_;
    my $param = ref $args[-1] eq 'HASH' ? pop @args : {};

    my $cmd = $self->_build_dialog_cmd(
        $param,
        [ '--msgbox', @args ],
    );

    my ($rv, $rt) = _cmd($cmd);

    return $rv;

}

sub textbox {

    my $self = shift;
    my @args = @_;
    my $param = ref $args[-1] eq 'HASH' ? pop @args : {};

    my $cmd = $self->_build_dialog_cmd(
        $param,
        [ '--textbox', @args ],
    );

    my ($rv, $rt) = _cmd($cmd);

    return $rv;

}

sub yesno {

    my $self = shift;
    my @args = @_;
    my $param = ref $args[-1] eq 'HASH' ? pop @args : {};

    my $cmd = $self->_build_dialog_cmd(
        $param,
        [ '--yesno', @args ],
    );

    my ($rv, $rt) = _cmd($cmd);

    return $rv;

}

sub pager {

    my $self = shift;
    my $file = shift;
    my $pgr  = shift // $ENV{ PAGER } // 'less';

    $file = _quote($file);

    return system "$pgr $file";

}

END {
    unlink $TMP if -e $TMP;
}

1;

=head1 NAME

EBook::Gutenberg::Dialog - Interface to dialog command.

=head1 SYNOPSIS

  use EBook::Gutenberg::Dialog;

  my $dialog = EBook::Gutenberg::Dialog->new(backtitle => 'gutenberg');

=head1 DESCRIPTION

B<EBook::Gutenberg::Dialog> is the L<gutenberg> interface to the Unix
L<dialog(1)> program. This is developer documentation, for user documentation
you should consult the L<gutenberg> manual.

=head1 METHODS

=over 4

=item $dialog = EBook::Gutenberg::Dialog->new(%params)

Returns a newly blessed B<EBook::Gutenberg::Dialog> object.

The following are valid C<%params> fields.

=over 4

=item backend

The backend dialog command to use. Defaults to L<dialog(1)>.

=item backtitle

String to use for the C<--backtitle> option. Unset by default.

=back

=back

=head2 Accessors

=over 4

=item $backend = $dialog->backend

=item $dialog->set_backend($backend)

Getter/setter for the backend attribute.

=item $backtitle = $dialog->backtitle

=item $dialog->set_backtitle($backtitle)

Getter/setter for the backtitle attribute.

=back

=head2 Widgets

These methods correspond to C<dialog(1)> widget options. Each method accepts a
hashref as an optional final argument that can contain the following fields:

=over 4

=item title

=item ok_label

=item yes_label

=item cancel_label

=item no_label

=item extra_button

=item extra_label

=item help_button

=item help_label

=item erase_on_exit

=back

Each correspond to a C<dialog(1)> option.

=over 4

=item ($rv, $forms) = $dialog->form($text, $height, $width, $list_height, [ $ly, $lx, $i1, $iy, $ix, $flen, $ilen ] ..., [ \%param ])

=item $rv = $dialog->infobox($text, $height, $width, [ $init ], [ \%param ])

=item ($rv, $in) = $dialog->inputbox($text, $height, $width, $menu_height, [ $tag, $item ] ..., [ \%param ])

=item ($rv, $item) = $dialog->menu($text, $height, $width, $menu_height, [ $tag, $item ] ..., [ \%param ])

=item $rv = $dialog->msgbox($text, $height, $width, [ \%param ])

=item $rv = $dialog->textbox($file, $height, $width, [ \%param ])

=item $rv = $dialog->yesno($text, $height, $width, [ \%param ])

=item $rv = $dialog->pager($file, [ $pgr ])

C<pager()> uses a given pager to read C<$file>. It does not actually correspond
to a C<dialog(1)> widget.

=back

=head1 EXPORTS

=over 4

=item :codes

C<dialog(1)> return code constants.

=over 4

=item DIALOG_OK

=item DIALOG_CANCEL

=item DIALOG_HELP

=item DIALOG_EXTRA

=item DIALOG_ITEM_HELP

=item DIALOG_TIMEOUT

=item DIALOG_ERROR

=item DIALOG_ESC

=back

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/gutenberg>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<gutenberg>, L<dialog(1)>

=cut

# vim: expandtab shiftwidth=4
