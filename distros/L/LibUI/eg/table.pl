use v5.40;
use blib;
use LibUI qw[:all];
$|++;
#
my @contacts = (
    { name => 'Alice', age => 30, email => 'alice@example.com' },
    { name => 'Bob',   age => 25, email => 'bob@example.com' },
    { name => 'Carol', age => 35, email => 'carol@example.com' },
    { name => 'Dave',  age => 28, email => 'dave@example.com' },
    { name => 'Eve',   age => 22, email => 'eve@example.com' },
    { name => 'Frank', age => 40, email => 'frank@example.com' }
);

# Sort state
my $sort_col = -1;                                                                                                     # -1 = unsorted
my $sort_asc = 1;                                                                                                      # 1 = ascending, 0 = descending
my @cols     = ( { key => 'name', numeric => 0 }, { key => 'age', numeric => 1 }, { key => 'email', numeric => 0 } );

sub do_sort ( $col, $asc ) {
    my $c = $cols[$col];
    @contacts = sort {
        if ( $c->{numeric} ) {
            $asc ? ( $a->{ $c->{key} } <=> $b->{ $c->{key} } ) : ( $b->{ $c->{key} } <=> $a->{ $c->{key} } );
        }
        else {
            $asc ? ( $a->{ $c->{key} } cmp $b->{ $c->{key} } ) : ( $b->{ $c->{key} } cmp $a->{ $c->{key} } );
        }
    } @contacts;
}
say '1. uiInit...';
uiInit( { Size => 0 } );
say '2. uiNewWindow...';
my $mainwin = uiNewWindow( 'Contacts Table (click headers to sort)', 600, 400, 0 );
uiWindowSetMargined( $mainwin, 1 );
say '3. uiNewTableModel...';
my $model = uiNewTableModel(
    {   NumColumns => sub ( $h, $m ) { return 3 },
        ColumnType => sub ( $h, $m, $col ) { return UI_TABLE_COLUMN_STRING },
        NumRows    => sub ( $h, $m ) { return scalar @contacts },
        CellValue  => sub ( $h, $m, $row, $col ) {
            my $c = $contacts[$row] // { name => 'X', age => 0, email => 'x' };
            my $val;
            if    ( $col == 0 ) { $val = $c->{name}; }
            elsif ( $col == 1 ) { $val = "$c->{age}"; }
            elsif ( $col == 2 ) { $val = $c->{email}; }
            else                { $val = '?'; }
            return uiNewTableValueString($val);
        },
        SetCellValue => sub ( $h, $m, $row, $col, $v ) { }
    }
);
say '4. uiNewTable...';
my $table = uiNewTable($model);
say '5. uiTableAppendTextColumn...';
uiTableAppendTextColumn( $table, 'Name',  0, -1, undef );
uiTableAppendTextColumn( $table, 'Age',   1, -1, undef );
uiTableAppendTextColumn( $table, 'Email', 2, -1, undef );
say '6. Inserting rows...';
uiTableModelRowInserted( $model, $_ ) for 0 .. $#contacts;
say '7. Wiring sort callbacks...';
uiTableHeaderOnClicked(
    $table,
    sub ( $t, $col, $data ) {
        if ( $col < 0 || $col > $#cols ) {return}
        if ( $sort_col == $col ) {
            $sort_asc = !$sort_asc;
        }
        else {
            $sort_col = $col;
            $sort_asc = 1;
        }
        do_sort( $col, $sort_asc );
        for my $i ( 0 .. $#contacts ) {
            uiTableModelRowChanged( $model, $i );
        }
        for my $c ( 0 .. 2 ) {
            if ( $c == $col ) {
                uiTableHeaderSetSortIndicator( $table, $c, $sort_asc ? 1 : 2 );
            }
            else {
                uiTableHeaderSetSortIndicator( $table, $c, 0 );
            }
        }
    },
    undef
);
say '8. Layout...';
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
my $lbl = uiNewLabel('Click a column header to sort. Click again to reverse.');
uiBoxAppend( $vbox, $lbl,   0 );
uiBoxAppend( $vbox, $table, 1 );
uiWindowSetChild( $mainwin, $vbox );
say '9. Showing...';
uiControlShow($mainwin);
uiWindowOnClosing( $mainwin, sub { uiQuit(); 1 }, undef );
uiOnShouldQuit( sub { uiControlHide($mainwin); 1 }, undef );
say '10. Entering main loop...';
uiMain();
say '11. Bye!'    # goes to 11
