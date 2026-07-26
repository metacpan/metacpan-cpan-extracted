use v5.40;
use blib;
use LibUI qw[:all];

# Port of upstream libui-ng datetime example
# Demonstrates uiDateTimePickerTime / uiDateTimePickerSetTime
uiInit( { Size => 0 } );
my $win = uiNewWindow( 'Date / Time', 400, 300, 0 );
uiWindowSetMargined( $win, 1 );
my $grid = uiNewGrid();
uiGridSetPadded( $grid, 1 );
uiWindowSetChild( $win, $grid );
my $dt_both = uiNewDateTimePicker();
my $dt_date = uiNewDatePicker();
my $dt_time = uiNewTimePicker();

# uiGridAppend(grid, control, left, top, xspan, yspan, hexpand, halign, vexpand, valign)
uiGridAppend( $grid, $dt_both, 0, 0, 2, 1, 1, 0, 0, 0 );
uiGridAppend( $grid, $dt_date, 0, 1, 1, 1, 1, 0, 0, 0 );
uiGridAppend( $grid, $dt_time, 1, 1, 1, 1, 1, 0, 0, 0 );
my $lbl_both = uiNewLabel("");
uiGridAppend( $grid, $lbl_both, 0, 2, 2, 1, 1, 1, 0, 0 );
uiDateTimePickerOnChanged(
    $dt_both,
    sub {
        my $tm = uiDateTimePickerTime($dt_both);
        uiLabelSetText( $lbl_both, format_tm($tm) );
    },
    undef
);
my $lbl_date = uiNewLabel('');
uiGridAppend( $grid, $lbl_date, 0, 3, 1, 1, 1, 1, 0, 0 );
uiDateTimePickerOnChanged(
    $dt_date,
    sub {
        my $tm = uiDateTimePickerTime($dt_date);
        uiLabelSetText( $lbl_date, format_tm $tm, '%x' );
    },
    undef
);
my $lbl_time = uiNewLabel('');
uiGridAppend( $grid, $lbl_time, 1, 3, 1, 1, 1, 1, 0, 0 );
uiDateTimePickerOnChanged(
    $dt_time,
    sub {
        my $tm = uiDateTimePickerTime($dt_time);
        uiLabelSetText( $lbl_time, format_tm $tm, '%X' );
    },
    undef
);
my $btn_now = uiNewButton('Now');
uiButtonOnClicked(
    $btn_now,
    sub {
        my $now = time();
        uiDateTimePickerSetTime( $dt_both, $now );
        my $tm = uiDateTimePickerTime($dt_both);
        uiLabelSetText( $lbl_both, format_tm($tm) );
    },
    undef
);
uiGridAppend( $grid, $btn_now, 0, 4, 1, 1, 1, 0, 1, 3 );
my $btn_set = uiNewButton('Set to epoch');
uiButtonOnClicked(
    $btn_set,
    sub {
        uiDateTimePickerSetTime( $dt_both,
            { tm_sec => 0, tm_min => 0, tm_hour => 0, tm_mday => 1, tm_mon => 0, tm_year => 70, tm_wday => 0, tm_yday => 0, tm_isdst => -1 } );
        my $tm = uiDateTimePickerTime($dt_both);
        uiLabelSetText( $lbl_both, format_tm($tm) );
    },
    undef
);
uiGridAppend( $grid, $btn_set, 1, 4, 1, 1, 1, 0, 1, 3 );
uiWindowOnClosing(
    $win,
    sub {
        uiQuit();
        return 1;
    },
    undef
);
uiControlShow($win);
uiMain();
