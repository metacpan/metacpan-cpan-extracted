package FBP::Grid;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Window';

has rows => (
	is  => 'ro',
	isa => 'Int',
);

# Grid

has cols => (
	is  => 'ro',
	isa => 'Int',
);

has editing => (
	is  => 'ro',
	isa => 'Bool',
);

has grid_lines => (
	is  => 'ro',
	isa => 'Bool',
);

has grid_line_color => (
	is  => 'ro',
	isa => 'Str',
);

has drag_grid_size => (
	is  => 'ro',
	isa => 'Bool',
);

has margin_width => (
	is  => 'ro',
	isa => 'Int',
);

has margin_height => (
	is  => 'ro',
	isa => 'Int',
);

# Columns

has column_sizes => (
	is  => 'ro',
	isa => 'Str',
);

has autosize_cols => (
	is  => 'ro',
	isa => 'Bool',
);

has drag_col_move => (
	is  => 'ro',
	isa => 'Bool',
);

has drag_col_size => (
	is  => 'ro',
	isa => 'Bool',
);

has col_label_size => (
	is  => 'ro',
	isa => 'Int',
);

has col_label_values => (
	is  => 'ro',
	isa => 'Str',
);

has col_label_horiz_alignment => (
	is  => 'ro',
	isa => 'Str',
);

has col_label_vert_alignment => (
	is  => 'ro',
	isa => 'Str',
);

# Rows

has row_sizes => (
	is  => 'ro',
	isa => 'Str',
);

has autosize_rows => (
	is  => 'ro',
	isa => 'Bool',
);

has drag_row_size => (
	is  => 'ro',
	isa => 'Bool',
);

has row_label_size => (
	is  => 'ro',
	isa => 'Int',
);

has row_label_values => (
	is  => 'ro',
	isa => 'Str',
);

has row_label_horiz_alignment => (
	is  => 'ro',
	isa => 'Str',
);

has row_label_vert_alignment => (
	is  => 'ro',
	isa => 'Str',
);

# Label Appearance

has label_bg => (
	is  => 'ro',
	isa => 'Str',
);

has label_font => (
	is  => 'ro',
	isa => 'Str',
);

has label_text => (
	is  => 'ro',
	isa => 'Str',
);

# Cell Defaults

has cell_bg => (
	is  => 'ro',
	isa => 'Str',
);

has cell_font => (
	is  => 'ro',
	isa => 'Str',
);

has cell_text => (
	is  => 'ro',
	isa => 'Str',
);

has cell_horiz_alignment => (
	is  => 'ro',
	isa => 'Str',
);

has cell_vert_alignment => (
	is  => 'ro',
	isa => 'Str',
);

# Events

has OnGridCellLeftClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCellRightClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCellLeftDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCellRightDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridLabelLeftClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridLabelRightClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridLabelLeftDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridLabelRightDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCellChange => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridEditorHidden => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridEditorShown => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdCellLeftClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdCellRightClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdCellLeftDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdCellRightDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdLabelLeftClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdLabelRightClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdLabelLeftDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdLabelRightDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdCellChange => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdSelectCell => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdEditorHidden => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdEditorShown => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridColSize => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridRowSize => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdColSize => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdRowSize => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridRangeSelect => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdRangeSelect => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridEditorCreated => (
	is  => 'ro',
	isa => 'Str',
);

has OnGridCmdEditorCreated => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
