use Test::More qw(no_plan);
#########################

BEGIN { use_ok( 'Gtk2::Ex::Datasheet::DBI' ); }

#########################
# are all the known methods accounted for?

my @methods = qw(
			new
			setup_treeview
			render_pixbuf_cell
			render_combo_cell
			process_text_editing
			process_toggle
			query
			insert
			apply
			changed
			delete
			column_value
			last_insert_id
		);

can_ok( 'Gtk2::Ex::Datasheet::DBI', @methods );
