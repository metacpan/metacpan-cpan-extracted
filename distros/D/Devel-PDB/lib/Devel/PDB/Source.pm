# vi: set autoindent shiftwidth=4 tabstop=8 softtabstop=4 expandtab:
package Devel::PDB::Source;
use strict;
use warnings;

use base qw(Class::Accessor::Faster);

use Carp;

__PACKAGE__->mk_accessors(qw(
      filename
      lines
      breaks
      current_line
      scr_x
      scr_y
      cur_x
      cur_y
      view
));

sub new {
    my $class  = shift;
    my %params = @_;

    my $this = $class->SUPER::new({
            filename     => undef,
            lines        => undef,
            breaks       => undef,
            current_line => -1,
            scr_x        => 0,
            scr_y        => 0,
            cur_x        => 0,
            cur_y        => 0,
            @_,
        });

    croak 'undefined source?'           unless defined $this->lines;
    croak 'undefined breakpoint table?' unless defined $this->breaks;

    return $this;
}

sub current_line {
    my $this = shift;
    my $ret  = $this->_current_line_accessor(@_);

    if (@_) {
        $this->cur_x(0);
        $this->cur_y(@_);

        my $view = $this->view;
        $view->scroll_to_line if @_ && defined $view;
    }

    return $ret;
}

sub cur_y {
    my $this = shift;

    if (@_) {
        my ($line) = @_;
        my $line_cnt = scalar @{$this->lines};

        $line = 0             if $line < 0;
        $line = $line_cnt - 1 if $line >= $line_cnt;

        my $ret = $this->_cur_y_accessor($line);

        return $ret;
    }

    return $this->_cur_y_accessor;
}

sub toogle_break_cond {
    my ($this, $line, $str) = @_;
    my $breaks = $this->breaks;

    my ($stop, $action) = split(/\0/, $breaks->{$line});

    my $x = "";
    for (1 .. ($ENV{COLS} - 20)) {
        $x .= "-";
    }

    my $cond = $Curses::UI::rootobject->question(
        -question => $str . "\n$x",
        DB::window_style(),
        -title  => "Eval in breakpoint",
        -answer => $action,
    );
    return 0 if (!$cond || !length($cond));
    my $text = $cond;
    $text =~ s/ //g;
    return 0 unless length($text);
    return "1\0" . $cond;
}

sub ret_line_number {
    my $this = shift;

    my $line     = $this->cur_y;
    my $line_cnt = scalar @{$this->lines};

    ++$line while (${$this->lines}[$line] == 0 && $line_cnt > $line);
    return 0 if $line_cnt <= $line;

    return $line;
}

sub ret_line_breakpoint {
    my $this   = shift;
    my $line   = $this->ret_line_number() || return;
    my $breaks = $this->breaks;

    return $breaks->{$line};
}

sub toggle_break {
    my ($this, $code, $r_str) = @_;

    my $line   = $this->ret_line_number() || return 0;
    my $breaks = $this->breaks;
    my $ret    = 0;
    my $view   = $this->view;
    my $text   = ref($r_str) ? "Problem : $$r_str" : "In line $line";

    if ($breaks->{$line}) {
        if ($code) {
            my $result = $this->toogle_break_cond($line, $text);
            return $this->toggle_break() unless ($result);
            $ret = $breaks->{$line} = $result;
        } else {
            $breaks->{$line} = 0;
            delete $breaks->{$line};
        }
    } else {
        my $result = $code ? $this->toogle_break_cond($line, $text) : 1;
        $ret = $breaks->{$line} = $result;
    }

    if (defined $view) {
        if ($ret && $this->cur_y != $line) {
            $view->cursor_down(undef, $line - $this->cur_y);
        } else {
            $view->intellidraw;
        }
    }

    return $ret;
}

1;
