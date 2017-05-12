use Test::More qw(no_plan);
#########################

BEGIN { use_ok( 'Gtk2::Ex::DBI' ); }

#########################
# are all the known methods accounted for?

my @methods = qw(
			apply
			assemble_new_record
			build_right_click_menu
			calculator
			calculator_process_editing
			changed
			count
			delete
			destroy
			destroy_self
			destroy_signal_handlers
			fetch_new_slice
			fieldlist
			find_dialog
			find_dialog_add_criteria
			find_do_search
			formatter_date_from_widget
			formatter_date_to_widget
			formatter_number_from_widget
			formatter_number_to_widget
			get_widget_value
			insert
			last_insert_id
			lock
			move
			new
			paint
			paint_calculated
			parse_sql_server_default
			position
			process_entry_keypress
			query
			record_status_label_set
			reset_record_status
			revert
			set_active_iter_for_broken_combo_box
			set_record_spinner_range
			set_widget_value
			setup_combo
			sum_widgets
			undo
			unlock
					);

can_ok( 'Gtk2::Ex::DBI', @methods );
