	
MODULE = Gtk	PACKAGE = Gtk::Adjustment		PREFIX = gtk_adjustment_

#ifdef GTK_ADJUSTMENT

int
gtk_adjustment_get_type(self)
	Gtk::Adjustment	self
	CODE:
	RETVAL = gtk_adjustment_get_type();
	OUTPUT:
	RETVAL

int
gtk_adjustment_get_size(self)
	Gtk::Adjustment	self
	CODE:
	RETVAL = sizeof(GtkAdjustment);
	OUTPUT:
	RETVAL


int
gtk_adjustment_get_class_size(self)
	Gtk::Adjustment	self
	CODE:
	RETVAL = sizeof(GtkAdjustmentClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Alignment		PREFIX = gtk_alignment_

#ifdef GTK_ALIGNMENT

int
gtk_alignment_get_type(self)
	Gtk::Alignment	self
	CODE:
	RETVAL = gtk_alignment_get_type();
	OUTPUT:
	RETVAL

int
gtk_alignment_get_size(self)
	Gtk::Alignment	self
	CODE:
	RETVAL = sizeof(GtkAlignment);
	OUTPUT:
	RETVAL


int
gtk_alignment_get_class_size(self)
	Gtk::Alignment	self
	CODE:
	RETVAL = sizeof(GtkAlignmentClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Arrow		PREFIX = gtk_arrow_

#ifdef GTK_ARROW

int
gtk_arrow_get_type(self)
	Gtk::Arrow	self
	CODE:
	RETVAL = gtk_arrow_get_type();
	OUTPUT:
	RETVAL

int
gtk_arrow_get_size(self)
	Gtk::Arrow	self
	CODE:
	RETVAL = sizeof(GtkArrow);
	OUTPUT:
	RETVAL


int
gtk_arrow_get_class_size(self)
	Gtk::Arrow	self
	CODE:
	RETVAL = sizeof(GtkArrowClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::AspectFrame		PREFIX = gtk_aspect_frame_

#ifdef GTK_ASPECT_FRAME

int
gtk_aspect_frame_get_type(self)
	Gtk::AspectFrame	self
	CODE:
	RETVAL = gtk_aspect_frame_get_type();
	OUTPUT:
	RETVAL

int
gtk_aspect_frame_get_size(self)
	Gtk::AspectFrame	self
	CODE:
	RETVAL = sizeof(GtkAspectFrame);
	OUTPUT:
	RETVAL


int
gtk_aspect_frame_get_class_size(self)
	Gtk::AspectFrame	self
	CODE:
	RETVAL = sizeof(GtkAspectFrameClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Bin		PREFIX = gtk_bin_

#ifdef GTK_BIN

int
gtk_bin_get_type(self)
	Gtk::Bin	self
	CODE:
	RETVAL = gtk_bin_get_type();
	OUTPUT:
	RETVAL

int
gtk_bin_get_size(self)
	Gtk::Bin	self
	CODE:
	RETVAL = sizeof(GtkBin);
	OUTPUT:
	RETVAL


int
gtk_bin_get_class_size(self)
	Gtk::Bin	self
	CODE:
	RETVAL = sizeof(GtkBinClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Box		PREFIX = gtk_box_

#ifdef GTK_BOX

int
gtk_box_get_type(self)
	Gtk::Box	self
	CODE:
	RETVAL = gtk_box_get_type();
	OUTPUT:
	RETVAL

int
gtk_box_get_size(self)
	Gtk::Box	self
	CODE:
	RETVAL = sizeof(GtkBox);
	OUTPUT:
	RETVAL


int
gtk_box_get_class_size(self)
	Gtk::Box	self
	CODE:
	RETVAL = sizeof(GtkBoxClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Button		PREFIX = gtk_button_

#ifdef GTK_BUTTON

int
gtk_button_get_type(self)
	Gtk::Button	self
	CODE:
	RETVAL = gtk_button_get_type();
	OUTPUT:
	RETVAL

int
gtk_button_get_size(self)
	Gtk::Button	self
	CODE:
	RETVAL = sizeof(GtkButton);
	OUTPUT:
	RETVAL


int
gtk_button_get_class_size(self)
	Gtk::Button	self
	CODE:
	RETVAL = sizeof(GtkButtonClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::ButtonBox		PREFIX = gtk_button_box_

#ifdef GTK_BUTTON_BOX

int
gtk_button_box_get_type(self)
	Gtk::ButtonBox	self
	CODE:
	RETVAL = gtk_button_box_get_type();
	OUTPUT:
	RETVAL

int
gtk_button_box_get_size(self)
	Gtk::ButtonBox	self
	CODE:
	RETVAL = sizeof(GtkButtonBox);
	OUTPUT:
	RETVAL


int
gtk_button_box_get_class_size(self)
	Gtk::ButtonBox	self
	CODE:
	RETVAL = sizeof(GtkButtonBoxClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::CList		PREFIX = gtk_clist_

#ifdef GTK_CLIST

int
gtk_clist_get_type(self)
	Gtk::CList	self
	CODE:
	RETVAL = gtk_clist_get_type();
	OUTPUT:
	RETVAL

int
gtk_clist_get_size(self)
	Gtk::CList	self
	CODE:
	RETVAL = sizeof(GtkCList);
	OUTPUT:
	RETVAL


int
gtk_clist_get_class_size(self)
	Gtk::CList	self
	CODE:
	RETVAL = sizeof(GtkCListClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::CheckButton		PREFIX = gtk_check_button_

#ifdef GTK_CHECK_BUTTON

int
gtk_check_button_get_type(self)
	Gtk::CheckButton	self
	CODE:
	RETVAL = gtk_check_button_get_type();
	OUTPUT:
	RETVAL

int
gtk_check_button_get_size(self)
	Gtk::CheckButton	self
	CODE:
	RETVAL = sizeof(GtkCheckButton);
	OUTPUT:
	RETVAL


int
gtk_check_button_get_class_size(self)
	Gtk::CheckButton	self
	CODE:
	RETVAL = sizeof(GtkCheckButtonClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::CheckMenuItem		PREFIX = gtk_check_menu_item_

#ifdef GTK_CHECK_MENU_ITEM

int
gtk_check_menu_item_get_type(self)
	Gtk::CheckMenuItem	self
	CODE:
	RETVAL = gtk_check_menu_item_get_type();
	OUTPUT:
	RETVAL

int
gtk_check_menu_item_get_size(self)
	Gtk::CheckMenuItem	self
	CODE:
	RETVAL = sizeof(GtkCheckMenuItem);
	OUTPUT:
	RETVAL


int
gtk_check_menu_item_get_class_size(self)
	Gtk::CheckMenuItem	self
	CODE:
	RETVAL = sizeof(GtkCheckMenuItemClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::ColorSelection		PREFIX = gtk_color_selection_

#ifdef GTK_COLOR_SELECTION

int
gtk_color_selection_get_type(self)
	Gtk::ColorSelection	self
	CODE:
	RETVAL = gtk_color_selection_get_type();
	OUTPUT:
	RETVAL

int
gtk_color_selection_get_size(self)
	Gtk::ColorSelection	self
	CODE:
	RETVAL = sizeof(GtkColorSelection);
	OUTPUT:
	RETVAL


int
gtk_color_selection_get_class_size(self)
	Gtk::ColorSelection	self
	CODE:
	RETVAL = sizeof(GtkColorSelectionClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::ColorSelectionDialog		PREFIX = gtk_color_selection_dialog_

#ifdef GTK_COLOR_SELECTION_DIALOG

int
gtk_color_selection_dialog_get_type(self)
	Gtk::ColorSelectionDialog	self
	CODE:
	RETVAL = gtk_color_selection_dialog_get_type();
	OUTPUT:
	RETVAL

int
gtk_color_selection_dialog_get_size(self)
	Gtk::ColorSelectionDialog	self
	CODE:
	RETVAL = sizeof(GtkColorSelectionDialog);
	OUTPUT:
	RETVAL


int
gtk_color_selection_dialog_get_class_size(self)
	Gtk::ColorSelectionDialog	self
	CODE:
	RETVAL = sizeof(GtkColorSelectionDialogClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Combo		PREFIX = gtk_combo_

#ifdef GTK_COMBO

int
gtk_combo_get_type(self)
	Gtk::Combo	self
	CODE:
	RETVAL = gtk_combo_get_type();
	OUTPUT:
	RETVAL

int
gtk_combo_get_size(self)
	Gtk::Combo	self
	CODE:
	RETVAL = sizeof(GtkCombo);
	OUTPUT:
	RETVAL


int
gtk_combo_get_class_size(self)
	Gtk::Combo	self
	CODE:
	RETVAL = sizeof(GtkComboClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Container		PREFIX = gtk_container_

#ifdef GTK_CONTAINER

int
gtk_container_get_type(self)
	Gtk::Container	self
	CODE:
	RETVAL = gtk_container_get_type();
	OUTPUT:
	RETVAL

int
gtk_container_get_size(self)
	Gtk::Container	self
	CODE:
	RETVAL = sizeof(GtkContainer);
	OUTPUT:
	RETVAL


int
gtk_container_get_class_size(self)
	Gtk::Container	self
	CODE:
	RETVAL = sizeof(GtkContainerClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Curve		PREFIX = gtk_curve_

#ifdef GTK_CURVE

int
gtk_curve_get_type(self)
	Gtk::Curve	self
	CODE:
	RETVAL = gtk_curve_get_type();
	OUTPUT:
	RETVAL

int
gtk_curve_get_size(self)
	Gtk::Curve	self
	CODE:
	RETVAL = sizeof(GtkCurve);
	OUTPUT:
	RETVAL


int
gtk_curve_get_class_size(self)
	Gtk::Curve	self
	CODE:
	RETVAL = sizeof(GtkCurveClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Data		PREFIX = gtk_data_

#ifdef GTK_DATA

int
gtk_data_get_type(self)
	Gtk::Data	self
	CODE:
	RETVAL = gtk_data_get_type();
	OUTPUT:
	RETVAL

int
gtk_data_get_size(self)
	Gtk::Data	self
	CODE:
	RETVAL = sizeof(GtkData);
	OUTPUT:
	RETVAL


int
gtk_data_get_class_size(self)
	Gtk::Data	self
	CODE:
	RETVAL = sizeof(GtkDataClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Dialog		PREFIX = gtk_dialog_

#ifdef GTK_DIALOG

int
gtk_dialog_get_type(self)
	Gtk::Dialog	self
	CODE:
	RETVAL = gtk_dialog_get_type();
	OUTPUT:
	RETVAL

int
gtk_dialog_get_size(self)
	Gtk::Dialog	self
	CODE:
	RETVAL = sizeof(GtkDialog);
	OUTPUT:
	RETVAL


int
gtk_dialog_get_class_size(self)
	Gtk::Dialog	self
	CODE:
	RETVAL = sizeof(GtkDialogClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::DrawingArea		PREFIX = gtk_drawing_area_

#ifdef GTK_DRAWING_AREA

int
gtk_drawing_area_get_type(self)
	Gtk::DrawingArea	self
	CODE:
	RETVAL = gtk_drawing_area_get_type();
	OUTPUT:
	RETVAL

int
gtk_drawing_area_get_size(self)
	Gtk::DrawingArea	self
	CODE:
	RETVAL = sizeof(GtkDrawingArea);
	OUTPUT:
	RETVAL


int
gtk_drawing_area_get_class_size(self)
	Gtk::DrawingArea	self
	CODE:
	RETVAL = sizeof(GtkDrawingAreaClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Editable		PREFIX = gtk_editable_

#ifdef GTK_EDITABLE

int
gtk_editable_get_type(self)
	Gtk::Editable	self
	CODE:
	RETVAL = gtk_editable_get_type();
	OUTPUT:
	RETVAL

int
gtk_editable_get_size(self)
	Gtk::Editable	self
	CODE:
	RETVAL = sizeof(GtkEditable);
	OUTPUT:
	RETVAL


int
gtk_editable_get_class_size(self)
	Gtk::Editable	self
	CODE:
	RETVAL = sizeof(GtkEditableClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Entry		PREFIX = gtk_entry_

#ifdef GTK_ENTRY

int
gtk_entry_get_type(self)
	Gtk::Entry	self
	CODE:
	RETVAL = gtk_entry_get_type();
	OUTPUT:
	RETVAL

int
gtk_entry_get_size(self)
	Gtk::Entry	self
	CODE:
	RETVAL = sizeof(GtkEntry);
	OUTPUT:
	RETVAL


int
gtk_entry_get_class_size(self)
	Gtk::Entry	self
	CODE:
	RETVAL = sizeof(GtkEntryClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::EventBox		PREFIX = gtk_event_box_

#ifdef GTK_EVENT_BOX

int
gtk_event_box_get_type(self)
	Gtk::EventBox	self
	CODE:
	RETVAL = gtk_event_box_get_type();
	OUTPUT:
	RETVAL

int
gtk_event_box_get_size(self)
	Gtk::EventBox	self
	CODE:
	RETVAL = sizeof(GtkEventBox);
	OUTPUT:
	RETVAL


int
gtk_event_box_get_class_size(self)
	Gtk::EventBox	self
	CODE:
	RETVAL = sizeof(GtkEventBoxClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::FileSelection		PREFIX = gtk_file_selection_

#ifdef GTK_FILE_SELECTION

int
gtk_file_selection_get_type(self)
	Gtk::FileSelection	self
	CODE:
	RETVAL = gtk_file_selection_get_type();
	OUTPUT:
	RETVAL

int
gtk_file_selection_get_size(self)
	Gtk::FileSelection	self
	CODE:
	RETVAL = sizeof(GtkFileSelection);
	OUTPUT:
	RETVAL


int
gtk_file_selection_get_class_size(self)
	Gtk::FileSelection	self
	CODE:
	RETVAL = sizeof(GtkFileSelectionClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Fixed		PREFIX = gtk_fixed_

#ifdef GTK_FIXED

int
gtk_fixed_get_type(self)
	Gtk::Fixed	self
	CODE:
	RETVAL = gtk_fixed_get_type();
	OUTPUT:
	RETVAL

int
gtk_fixed_get_size(self)
	Gtk::Fixed	self
	CODE:
	RETVAL = sizeof(GtkFixed);
	OUTPUT:
	RETVAL


int
gtk_fixed_get_class_size(self)
	Gtk::Fixed	self
	CODE:
	RETVAL = sizeof(GtkFixedClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Frame		PREFIX = gtk_frame_

#ifdef GTK_FRAME

int
gtk_frame_get_type(self)
	Gtk::Frame	self
	CODE:
	RETVAL = gtk_frame_get_type();
	OUTPUT:
	RETVAL

int
gtk_frame_get_size(self)
	Gtk::Frame	self
	CODE:
	RETVAL = sizeof(GtkFrame);
	OUTPUT:
	RETVAL


int
gtk_frame_get_class_size(self)
	Gtk::Frame	self
	CODE:
	RETVAL = sizeof(GtkFrameClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::GammaCurve		PREFIX = gtk_gamma_curve_

#ifdef GTK_GAMMA_CURVE

int
gtk_gamma_curve_get_type(self)
	Gtk::GammaCurve	self
	CODE:
	RETVAL = gtk_gamma_curve_get_type();
	OUTPUT:
	RETVAL

int
gtk_gamma_curve_get_size(self)
	Gtk::GammaCurve	self
	CODE:
	RETVAL = sizeof(GtkGammaCurve);
	OUTPUT:
	RETVAL


int
gtk_gamma_curve_get_class_size(self)
	Gtk::GammaCurve	self
	CODE:
	RETVAL = sizeof(GtkGammaCurveClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::HBox		PREFIX = gtk_hbox_

#ifdef GTK_HBOX

int
gtk_hbox_get_type(self)
	Gtk::HBox	self
	CODE:
	RETVAL = gtk_hbox_get_type();
	OUTPUT:
	RETVAL

int
gtk_hbox_get_size(self)
	Gtk::HBox	self
	CODE:
	RETVAL = sizeof(GtkHBox);
	OUTPUT:
	RETVAL


int
gtk_hbox_get_class_size(self)
	Gtk::HBox	self
	CODE:
	RETVAL = sizeof(GtkHBoxClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::HButtonBox		PREFIX = gtk_hbutton_box_

#ifdef GTK_HBUTTON_BOX

int
gtk_hbutton_box_get_type(self)
	Gtk::HButtonBox	self
	CODE:
	RETVAL = gtk_hbutton_box_get_type();
	OUTPUT:
	RETVAL

int
gtk_hbutton_box_get_size(self)
	Gtk::HButtonBox	self
	CODE:
	RETVAL = sizeof(GtkHButtonBox);
	OUTPUT:
	RETVAL


int
gtk_hbutton_box_get_class_size(self)
	Gtk::HButtonBox	self
	CODE:
	RETVAL = sizeof(GtkHButtonBoxClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::HPaned		PREFIX = gtk_hpaned_

#ifdef GTK_HPANED

int
gtk_hpaned_get_type(self)
	Gtk::HPaned	self
	CODE:
	RETVAL = gtk_hpaned_get_type();
	OUTPUT:
	RETVAL

int
gtk_hpaned_get_size(self)
	Gtk::HPaned	self
	CODE:
	RETVAL = sizeof(GtkHPaned);
	OUTPUT:
	RETVAL


int
gtk_hpaned_get_class_size(self)
	Gtk::HPaned	self
	CODE:
	RETVAL = sizeof(GtkHPanedClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::HRuler		PREFIX = gtk_hruler_

#ifdef GTK_HRULER

int
gtk_hruler_get_type(self)
	Gtk::HRuler	self
	CODE:
	RETVAL = gtk_hruler_get_type();
	OUTPUT:
	RETVAL

int
gtk_hruler_get_size(self)
	Gtk::HRuler	self
	CODE:
	RETVAL = sizeof(GtkHRuler);
	OUTPUT:
	RETVAL


int
gtk_hruler_get_class_size(self)
	Gtk::HRuler	self
	CODE:
	RETVAL = sizeof(GtkHRulerClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::HScale		PREFIX = gtk_hscale_

#ifdef GTK_HSCALE

int
gtk_hscale_get_type(self)
	Gtk::HScale	self
	CODE:
	RETVAL = gtk_hscale_get_type();
	OUTPUT:
	RETVAL

int
gtk_hscale_get_size(self)
	Gtk::HScale	self
	CODE:
	RETVAL = sizeof(GtkHScale);
	OUTPUT:
	RETVAL


int
gtk_hscale_get_class_size(self)
	Gtk::HScale	self
	CODE:
	RETVAL = sizeof(GtkHScaleClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::HScrollbar		PREFIX = gtk_hscrollbar_

#ifdef GTK_HSCROLLBAR

int
gtk_hscrollbar_get_type(self)
	Gtk::HScrollbar	self
	CODE:
	RETVAL = gtk_hscrollbar_get_type();
	OUTPUT:
	RETVAL

int
gtk_hscrollbar_get_size(self)
	Gtk::HScrollbar	self
	CODE:
	RETVAL = sizeof(GtkHScrollbar);
	OUTPUT:
	RETVAL


int
gtk_hscrollbar_get_class_size(self)
	Gtk::HScrollbar	self
	CODE:
	RETVAL = sizeof(GtkHScrollbarClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::HSeparator		PREFIX = gtk_hseparator_

#ifdef GTK_HSEPARATOR

int
gtk_hseparator_get_type(self)
	Gtk::HSeparator	self
	CODE:
	RETVAL = gtk_hseparator_get_type();
	OUTPUT:
	RETVAL

int
gtk_hseparator_get_size(self)
	Gtk::HSeparator	self
	CODE:
	RETVAL = sizeof(GtkHSeparator);
	OUTPUT:
	RETVAL


int
gtk_hseparator_get_class_size(self)
	Gtk::HSeparator	self
	CODE:
	RETVAL = sizeof(GtkHSeparatorClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::HandleBox		PREFIX = gtk_handle_box_

#ifdef GTK_HANDLE_BOX

int
gtk_handle_box_get_type(self)
	Gtk::HandleBox	self
	CODE:
	RETVAL = gtk_handle_box_get_type();
	OUTPUT:
	RETVAL

int
gtk_handle_box_get_size(self)
	Gtk::HandleBox	self
	CODE:
	RETVAL = sizeof(GtkHandleBox);
	OUTPUT:
	RETVAL


int
gtk_handle_box_get_class_size(self)
	Gtk::HandleBox	self
	CODE:
	RETVAL = sizeof(GtkHandleBoxClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Image		PREFIX = gtk_image_

#ifdef GTK_IMAGE

int
gtk_image_get_type(self)
	Gtk::Image	self
	CODE:
	RETVAL = gtk_image_get_type();
	OUTPUT:
	RETVAL

int
gtk_image_get_size(self)
	Gtk::Image	self
	CODE:
	RETVAL = sizeof(GtkImage);
	OUTPUT:
	RETVAL


int
gtk_image_get_class_size(self)
	Gtk::Image	self
	CODE:
	RETVAL = sizeof(GtkImageClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::InputDialog		PREFIX = gtk_input_dialog_

#ifdef GTK_INPUT_DIALOG

int
gtk_input_dialog_get_type(self)
	Gtk::InputDialog	self
	CODE:
	RETVAL = gtk_input_dialog_get_type();
	OUTPUT:
	RETVAL

int
gtk_input_dialog_get_size(self)
	Gtk::InputDialog	self
	CODE:
	RETVAL = sizeof(GtkInputDialog);
	OUTPUT:
	RETVAL


int
gtk_input_dialog_get_class_size(self)
	Gtk::InputDialog	self
	CODE:
	RETVAL = sizeof(GtkInputDialogClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Item		PREFIX = gtk_item_

#ifdef GTK_ITEM

int
gtk_item_get_type(self)
	Gtk::Item	self
	CODE:
	RETVAL = gtk_item_get_type();
	OUTPUT:
	RETVAL

int
gtk_item_get_size(self)
	Gtk::Item	self
	CODE:
	RETVAL = sizeof(GtkItem);
	OUTPUT:
	RETVAL


int
gtk_item_get_class_size(self)
	Gtk::Item	self
	CODE:
	RETVAL = sizeof(GtkItemClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Label		PREFIX = gtk_label_

#ifdef GTK_LABEL

int
gtk_label_get_type(self)
	Gtk::Label	self
	CODE:
	RETVAL = gtk_label_get_type();
	OUTPUT:
	RETVAL

int
gtk_label_get_size(self)
	Gtk::Label	self
	CODE:
	RETVAL = sizeof(GtkLabel);
	OUTPUT:
	RETVAL


int
gtk_label_get_class_size(self)
	Gtk::Label	self
	CODE:
	RETVAL = sizeof(GtkLabelClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::List		PREFIX = gtk_list_

#ifdef GTK_LIST

int
gtk_list_get_type(self)
	Gtk::List	self
	CODE:
	RETVAL = gtk_list_get_type();
	OUTPUT:
	RETVAL

int
gtk_list_get_size(self)
	Gtk::List	self
	CODE:
	RETVAL = sizeof(GtkList);
	OUTPUT:
	RETVAL


int
gtk_list_get_class_size(self)
	Gtk::List	self
	CODE:
	RETVAL = sizeof(GtkListClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::ListItem		PREFIX = gtk_list_item_

#ifdef GTK_LIST_ITEM

int
gtk_list_item_get_type(self)
	Gtk::ListItem	self
	CODE:
	RETVAL = gtk_list_item_get_type();
	OUTPUT:
	RETVAL

int
gtk_list_item_get_size(self)
	Gtk::ListItem	self
	CODE:
	RETVAL = sizeof(GtkListItem);
	OUTPUT:
	RETVAL


int
gtk_list_item_get_class_size(self)
	Gtk::ListItem	self
	CODE:
	RETVAL = sizeof(GtkListItemClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Menu		PREFIX = gtk_menu_

#ifdef GTK_MENU

int
gtk_menu_get_type(self)
	Gtk::Menu	self
	CODE:
	RETVAL = gtk_menu_get_type();
	OUTPUT:
	RETVAL

int
gtk_menu_get_size(self)
	Gtk::Menu	self
	CODE:
	RETVAL = sizeof(GtkMenu);
	OUTPUT:
	RETVAL


int
gtk_menu_get_class_size(self)
	Gtk::Menu	self
	CODE:
	RETVAL = sizeof(GtkMenuClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::MenuBar		PREFIX = gtk_menu_bar_

#ifdef GTK_MENU_BAR

int
gtk_menu_bar_get_type(self)
	Gtk::MenuBar	self
	CODE:
	RETVAL = gtk_menu_bar_get_type();
	OUTPUT:
	RETVAL

int
gtk_menu_bar_get_size(self)
	Gtk::MenuBar	self
	CODE:
	RETVAL = sizeof(GtkMenuBar);
	OUTPUT:
	RETVAL


int
gtk_menu_bar_get_class_size(self)
	Gtk::MenuBar	self
	CODE:
	RETVAL = sizeof(GtkMenuBarClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::MenuItem		PREFIX = gtk_menu_item_

#ifdef GTK_MENU_ITEM

int
gtk_menu_item_get_type(self)
	Gtk::MenuItem	self
	CODE:
	RETVAL = gtk_menu_item_get_type();
	OUTPUT:
	RETVAL

int
gtk_menu_item_get_size(self)
	Gtk::MenuItem	self
	CODE:
	RETVAL = sizeof(GtkMenuItem);
	OUTPUT:
	RETVAL


int
gtk_menu_item_get_class_size(self)
	Gtk::MenuItem	self
	CODE:
	RETVAL = sizeof(GtkMenuItemClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::MenuShell		PREFIX = gtk_menu_shell_

#ifdef GTK_MENU_SHELL

int
gtk_menu_shell_get_type(self)
	Gtk::MenuShell	self
	CODE:
	RETVAL = gtk_menu_shell_get_type();
	OUTPUT:
	RETVAL

int
gtk_menu_shell_get_size(self)
	Gtk::MenuShell	self
	CODE:
	RETVAL = sizeof(GtkMenuShell);
	OUTPUT:
	RETVAL


int
gtk_menu_shell_get_class_size(self)
	Gtk::MenuShell	self
	CODE:
	RETVAL = sizeof(GtkMenuShellClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Misc		PREFIX = gtk_misc_

#ifdef GTK_MISC

int
gtk_misc_get_type(self)
	Gtk::Misc	self
	CODE:
	RETVAL = gtk_misc_get_type();
	OUTPUT:
	RETVAL

int
gtk_misc_get_size(self)
	Gtk::Misc	self
	CODE:
	RETVAL = sizeof(GtkMisc);
	OUTPUT:
	RETVAL


int
gtk_misc_get_class_size(self)
	Gtk::Misc	self
	CODE:
	RETVAL = sizeof(GtkMiscClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Notebook		PREFIX = gtk_notebook_

#ifdef GTK_NOTEBOOK

int
gtk_notebook_get_type(self)
	Gtk::Notebook	self
	CODE:
	RETVAL = gtk_notebook_get_type();
	OUTPUT:
	RETVAL

int
gtk_notebook_get_size(self)
	Gtk::Notebook	self
	CODE:
	RETVAL = sizeof(GtkNotebook);
	OUTPUT:
	RETVAL


int
gtk_notebook_get_class_size(self)
	Gtk::Notebook	self
	CODE:
	RETVAL = sizeof(GtkNotebookClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Object		PREFIX = gtk_object_

#ifdef GTK_OBJECT

int
gtk_object_get_type(self)
	Gtk::Object	self
	CODE:
	RETVAL = gtk_object_get_type();
	OUTPUT:
	RETVAL

int
gtk_object_get_size(self)
	Gtk::Object	self
	CODE:
	RETVAL = sizeof(GtkObject);
	OUTPUT:
	RETVAL


int
gtk_object_get_class_size(self)
	Gtk::Object	self
	CODE:
	RETVAL = sizeof(GtkObjectClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::OptionMenu		PREFIX = gtk_option_menu_

#ifdef GTK_OPTION_MENU

int
gtk_option_menu_get_type(self)
	Gtk::OptionMenu	self
	CODE:
	RETVAL = gtk_option_menu_get_type();
	OUTPUT:
	RETVAL

int
gtk_option_menu_get_size(self)
	Gtk::OptionMenu	self
	CODE:
	RETVAL = sizeof(GtkOptionMenu);
	OUTPUT:
	RETVAL


int
gtk_option_menu_get_class_size(self)
	Gtk::OptionMenu	self
	CODE:
	RETVAL = sizeof(GtkOptionMenuClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Paned		PREFIX = gtk_paned_

#ifdef GTK_PANED

int
gtk_paned_get_type(self)
	Gtk::Paned	self
	CODE:
	RETVAL = gtk_paned_get_type();
	OUTPUT:
	RETVAL

int
gtk_paned_get_size(self)
	Gtk::Paned	self
	CODE:
	RETVAL = sizeof(GtkPaned);
	OUTPUT:
	RETVAL


int
gtk_paned_get_class_size(self)
	Gtk::Paned	self
	CODE:
	RETVAL = sizeof(GtkPanedClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Pixmap		PREFIX = gtk_pixmap_

#ifdef GTK_PIXMAP

int
gtk_pixmap_get_type(self)
	Gtk::Pixmap	self
	CODE:
	RETVAL = gtk_pixmap_get_type();
	OUTPUT:
	RETVAL

int
gtk_pixmap_get_size(self)
	Gtk::Pixmap	self
	CODE:
	RETVAL = sizeof(GtkPixmap);
	OUTPUT:
	RETVAL


int
gtk_pixmap_get_class_size(self)
	Gtk::Pixmap	self
	CODE:
	RETVAL = sizeof(GtkPixmapClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Preview		PREFIX = gtk_preview_

#ifdef GTK_PREVIEW

int
gtk_preview_get_type(self)
	Gtk::Preview	self
	CODE:
	RETVAL = gtk_preview_get_type();
	OUTPUT:
	RETVAL

int
gtk_preview_get_size(self)
	Gtk::Preview	self
	CODE:
	RETVAL = sizeof(GtkPreview);
	OUTPUT:
	RETVAL


int
gtk_preview_get_class_size(self)
	Gtk::Preview	self
	CODE:
	RETVAL = sizeof(GtkPreviewClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::ProgressBar		PREFIX = gtk_progress_bar_

#ifdef GTK_PROGRESS_BAR

int
gtk_progress_bar_get_type(self)
	Gtk::ProgressBar	self
	CODE:
	RETVAL = gtk_progress_bar_get_type();
	OUTPUT:
	RETVAL

int
gtk_progress_bar_get_size(self)
	Gtk::ProgressBar	self
	CODE:
	RETVAL = sizeof(GtkProgressBar);
	OUTPUT:
	RETVAL


int
gtk_progress_bar_get_class_size(self)
	Gtk::ProgressBar	self
	CODE:
	RETVAL = sizeof(GtkProgressBarClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::RadioButton		PREFIX = gtk_radio_button_

#ifdef GTK_RADIO_BUTTON

int
gtk_radio_button_get_type(self)
	Gtk::RadioButton	self
	CODE:
	RETVAL = gtk_radio_button_get_type();
	OUTPUT:
	RETVAL

int
gtk_radio_button_get_size(self)
	Gtk::RadioButton	self
	CODE:
	RETVAL = sizeof(GtkRadioButton);
	OUTPUT:
	RETVAL


int
gtk_radio_button_get_class_size(self)
	Gtk::RadioButton	self
	CODE:
	RETVAL = sizeof(GtkRadioButtonClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::RadioMenuItem		PREFIX = gtk_radio_menu_item_

#ifdef GTK_RADIO_MENU_ITEM

int
gtk_radio_menu_item_get_type(self)
	Gtk::RadioMenuItem	self
	CODE:
	RETVAL = gtk_radio_menu_item_get_type();
	OUTPUT:
	RETVAL

int
gtk_radio_menu_item_get_size(self)
	Gtk::RadioMenuItem	self
	CODE:
	RETVAL = sizeof(GtkRadioMenuItem);
	OUTPUT:
	RETVAL


int
gtk_radio_menu_item_get_class_size(self)
	Gtk::RadioMenuItem	self
	CODE:
	RETVAL = sizeof(GtkRadioMenuItemClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Range		PREFIX = gtk_range_

#ifdef GTK_RANGE

int
gtk_range_get_type(self)
	Gtk::Range	self
	CODE:
	RETVAL = gtk_range_get_type();
	OUTPUT:
	RETVAL

int
gtk_range_get_size(self)
	Gtk::Range	self
	CODE:
	RETVAL = sizeof(GtkRange);
	OUTPUT:
	RETVAL


int
gtk_range_get_class_size(self)
	Gtk::Range	self
	CODE:
	RETVAL = sizeof(GtkRangeClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Ruler		PREFIX = gtk_ruler_

#ifdef GTK_RULER

int
gtk_ruler_get_type(self)
	Gtk::Ruler	self
	CODE:
	RETVAL = gtk_ruler_get_type();
	OUTPUT:
	RETVAL

int
gtk_ruler_get_size(self)
	Gtk::Ruler	self
	CODE:
	RETVAL = sizeof(GtkRuler);
	OUTPUT:
	RETVAL


int
gtk_ruler_get_class_size(self)
	Gtk::Ruler	self
	CODE:
	RETVAL = sizeof(GtkRulerClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Scale		PREFIX = gtk_scale_

#ifdef GTK_SCALE

int
gtk_scale_get_type(self)
	Gtk::Scale	self
	CODE:
	RETVAL = gtk_scale_get_type();
	OUTPUT:
	RETVAL

int
gtk_scale_get_size(self)
	Gtk::Scale	self
	CODE:
	RETVAL = sizeof(GtkScale);
	OUTPUT:
	RETVAL


int
gtk_scale_get_class_size(self)
	Gtk::Scale	self
	CODE:
	RETVAL = sizeof(GtkScaleClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Scrollbar		PREFIX = gtk_scrollbar_

#ifdef GTK_SCROLLBAR

int
gtk_scrollbar_get_type(self)
	Gtk::Scrollbar	self
	CODE:
	RETVAL = gtk_scrollbar_get_type();
	OUTPUT:
	RETVAL

int
gtk_scrollbar_get_size(self)
	Gtk::Scrollbar	self
	CODE:
	RETVAL = sizeof(GtkScrollbar);
	OUTPUT:
	RETVAL


int
gtk_scrollbar_get_class_size(self)
	Gtk::Scrollbar	self
	CODE:
	RETVAL = sizeof(GtkScrollbarClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::ScrolledWindow		PREFIX = gtk_scrolled_window_

#ifdef GTK_SCROLLED_WINDOW

int
gtk_scrolled_window_get_type(self)
	Gtk::ScrolledWindow	self
	CODE:
	RETVAL = gtk_scrolled_window_get_type();
	OUTPUT:
	RETVAL

int
gtk_scrolled_window_get_size(self)
	Gtk::ScrolledWindow	self
	CODE:
	RETVAL = sizeof(GtkScrolledWindow);
	OUTPUT:
	RETVAL


int
gtk_scrolled_window_get_class_size(self)
	Gtk::ScrolledWindow	self
	CODE:
	RETVAL = sizeof(GtkScrolledWindowClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Separator		PREFIX = gtk_separator_

#ifdef GTK_SEPARATOR

int
gtk_separator_get_type(self)
	Gtk::Separator	self
	CODE:
	RETVAL = gtk_separator_get_type();
	OUTPUT:
	RETVAL

int
gtk_separator_get_size(self)
	Gtk::Separator	self
	CODE:
	RETVAL = sizeof(GtkSeparator);
	OUTPUT:
	RETVAL


int
gtk_separator_get_class_size(self)
	Gtk::Separator	self
	CODE:
	RETVAL = sizeof(GtkSeparatorClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::SpinButton		PREFIX = gtk_spin_button_

#ifdef GTK_SPIN_BUTTON

int
gtk_spin_button_get_type(self)
	Gtk::SpinButton	self
	CODE:
	RETVAL = gtk_spin_button_get_type();
	OUTPUT:
	RETVAL

int
gtk_spin_button_get_size(self)
	Gtk::SpinButton	self
	CODE:
	RETVAL = sizeof(GtkSpinButton);
	OUTPUT:
	RETVAL


int
gtk_spin_button_get_class_size(self)
	Gtk::SpinButton	self
	CODE:
	RETVAL = sizeof(GtkSpinButtonClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Statusbar		PREFIX = gtk_statusbar_

#ifdef GTK_STATUSBAR

int
gtk_statusbar_get_type(self)
	Gtk::Statusbar	self
	CODE:
	RETVAL = gtk_statusbar_get_type();
	OUTPUT:
	RETVAL

int
gtk_statusbar_get_size(self)
	Gtk::Statusbar	self
	CODE:
	RETVAL = sizeof(GtkStatusbar);
	OUTPUT:
	RETVAL


int
gtk_statusbar_get_class_size(self)
	Gtk::Statusbar	self
	CODE:
	RETVAL = sizeof(GtkStatusbarClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Table		PREFIX = gtk_table_

#ifdef GTK_TABLE

int
gtk_table_get_type(self)
	Gtk::Table	self
	CODE:
	RETVAL = gtk_table_get_type();
	OUTPUT:
	RETVAL

int
gtk_table_get_size(self)
	Gtk::Table	self
	CODE:
	RETVAL = sizeof(GtkTable);
	OUTPUT:
	RETVAL


int
gtk_table_get_class_size(self)
	Gtk::Table	self
	CODE:
	RETVAL = sizeof(GtkTableClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Text		PREFIX = gtk_text_

#ifdef GTK_TEXT

int
gtk_text_get_type(self)
	Gtk::Text	self
	CODE:
	RETVAL = gtk_text_get_type();
	OUTPUT:
	RETVAL

int
gtk_text_get_size(self)
	Gtk::Text	self
	CODE:
	RETVAL = sizeof(GtkText);
	OUTPUT:
	RETVAL


int
gtk_text_get_class_size(self)
	Gtk::Text	self
	CODE:
	RETVAL = sizeof(GtkTextClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::TipsQuery		PREFIX = gtk_tips_query_

#ifdef GTK_TIPS_QUERY

int
gtk_tips_query_get_type(self)
	Gtk::TipsQuery	self
	CODE:
	RETVAL = gtk_tips_query_get_type();
	OUTPUT:
	RETVAL

int
gtk_tips_query_get_size(self)
	Gtk::TipsQuery	self
	CODE:
	RETVAL = sizeof(GtkTipsQuery);
	OUTPUT:
	RETVAL


int
gtk_tips_query_get_class_size(self)
	Gtk::TipsQuery	self
	CODE:
	RETVAL = sizeof(GtkTipsQueryClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::ToggleButton		PREFIX = gtk_toggle_button_

#ifdef GTK_TOGGLE_BUTTON

int
gtk_toggle_button_get_type(self)
	Gtk::ToggleButton	self
	CODE:
	RETVAL = gtk_toggle_button_get_type();
	OUTPUT:
	RETVAL

int
gtk_toggle_button_get_size(self)
	Gtk::ToggleButton	self
	CODE:
	RETVAL = sizeof(GtkToggleButton);
	OUTPUT:
	RETVAL


int
gtk_toggle_button_get_class_size(self)
	Gtk::ToggleButton	self
	CODE:
	RETVAL = sizeof(GtkToggleButtonClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Toolbar		PREFIX = gtk_toolbar_

#ifdef GTK_TOOLBAR

int
gtk_toolbar_get_type(self)
	Gtk::Toolbar	self
	CODE:
	RETVAL = gtk_toolbar_get_type();
	OUTPUT:
	RETVAL

int
gtk_toolbar_get_size(self)
	Gtk::Toolbar	self
	CODE:
	RETVAL = sizeof(GtkToolbar);
	OUTPUT:
	RETVAL


int
gtk_toolbar_get_class_size(self)
	Gtk::Toolbar	self
	CODE:
	RETVAL = sizeof(GtkToolbarClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Tooltips		PREFIX = gtk_tooltips_

#ifdef GTK_TOOLTIPS

int
gtk_tooltips_get_type(self)
	Gtk::Tooltips	self
	CODE:
	RETVAL = gtk_tooltips_get_type();
	OUTPUT:
	RETVAL

int
gtk_tooltips_get_size(self)
	Gtk::Tooltips	self
	CODE:
	RETVAL = sizeof(GtkTooltips);
	OUTPUT:
	RETVAL


int
gtk_tooltips_get_class_size(self)
	Gtk::Tooltips	self
	CODE:
	RETVAL = sizeof(GtkTooltipsClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Tree		PREFIX = gtk_tree_

#ifdef GTK_TREE

int
gtk_tree_get_type(self)
	Gtk::Tree	self
	CODE:
	RETVAL = gtk_tree_get_type();
	OUTPUT:
	RETVAL

int
gtk_tree_get_size(self)
	Gtk::Tree	self
	CODE:
	RETVAL = sizeof(GtkTree);
	OUTPUT:
	RETVAL


int
gtk_tree_get_class_size(self)
	Gtk::Tree	self
	CODE:
	RETVAL = sizeof(GtkTreeClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::TreeItem		PREFIX = gtk_tree_item_

#ifdef GTK_TREE_ITEM

int
gtk_tree_item_get_type(self)
	Gtk::TreeItem	self
	CODE:
	RETVAL = gtk_tree_item_get_type();
	OUTPUT:
	RETVAL

int
gtk_tree_item_get_size(self)
	Gtk::TreeItem	self
	CODE:
	RETVAL = sizeof(GtkTreeItem);
	OUTPUT:
	RETVAL


int
gtk_tree_item_get_class_size(self)
	Gtk::TreeItem	self
	CODE:
	RETVAL = sizeof(GtkTreeItemClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::VBox		PREFIX = gtk_vbox_

#ifdef GTK_VBOX

int
gtk_vbox_get_type(self)
	Gtk::VBox	self
	CODE:
	RETVAL = gtk_vbox_get_type();
	OUTPUT:
	RETVAL

int
gtk_vbox_get_size(self)
	Gtk::VBox	self
	CODE:
	RETVAL = sizeof(GtkVBox);
	OUTPUT:
	RETVAL


int
gtk_vbox_get_class_size(self)
	Gtk::VBox	self
	CODE:
	RETVAL = sizeof(GtkVBoxClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::VButtonBox		PREFIX = gtk_vbutton_box_

#ifdef GTK_VBUTTON_BOX

int
gtk_vbutton_box_get_type(self)
	Gtk::VButtonBox	self
	CODE:
	RETVAL = gtk_vbutton_box_get_type();
	OUTPUT:
	RETVAL

int
gtk_vbutton_box_get_size(self)
	Gtk::VButtonBox	self
	CODE:
	RETVAL = sizeof(GtkVButtonBox);
	OUTPUT:
	RETVAL


int
gtk_vbutton_box_get_class_size(self)
	Gtk::VButtonBox	self
	CODE:
	RETVAL = sizeof(GtkVButtonBoxClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::VPaned		PREFIX = gtk_vpaned_

#ifdef GTK_VPANED

int
gtk_vpaned_get_type(self)
	Gtk::VPaned	self
	CODE:
	RETVAL = gtk_vpaned_get_type();
	OUTPUT:
	RETVAL

int
gtk_vpaned_get_size(self)
	Gtk::VPaned	self
	CODE:
	RETVAL = sizeof(GtkVPaned);
	OUTPUT:
	RETVAL


int
gtk_vpaned_get_class_size(self)
	Gtk::VPaned	self
	CODE:
	RETVAL = sizeof(GtkVPanedClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::VRuler		PREFIX = gtk_vruler_

#ifdef GTK_VRULER

int
gtk_vruler_get_type(self)
	Gtk::VRuler	self
	CODE:
	RETVAL = gtk_vruler_get_type();
	OUTPUT:
	RETVAL

int
gtk_vruler_get_size(self)
	Gtk::VRuler	self
	CODE:
	RETVAL = sizeof(GtkVRuler);
	OUTPUT:
	RETVAL


int
gtk_vruler_get_class_size(self)
	Gtk::VRuler	self
	CODE:
	RETVAL = sizeof(GtkVRulerClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::VScale		PREFIX = gtk_vscale_

#ifdef GTK_VSCALE

int
gtk_vscale_get_type(self)
	Gtk::VScale	self
	CODE:
	RETVAL = gtk_vscale_get_type();
	OUTPUT:
	RETVAL

int
gtk_vscale_get_size(self)
	Gtk::VScale	self
	CODE:
	RETVAL = sizeof(GtkVScale);
	OUTPUT:
	RETVAL


int
gtk_vscale_get_class_size(self)
	Gtk::VScale	self
	CODE:
	RETVAL = sizeof(GtkVScaleClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::VScrollbar		PREFIX = gtk_vscrollbar_

#ifdef GTK_VSCROLLBAR

int
gtk_vscrollbar_get_type(self)
	Gtk::VScrollbar	self
	CODE:
	RETVAL = gtk_vscrollbar_get_type();
	OUTPUT:
	RETVAL

int
gtk_vscrollbar_get_size(self)
	Gtk::VScrollbar	self
	CODE:
	RETVAL = sizeof(GtkVScrollbar);
	OUTPUT:
	RETVAL


int
gtk_vscrollbar_get_class_size(self)
	Gtk::VScrollbar	self
	CODE:
	RETVAL = sizeof(GtkVScrollbarClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::VSeparator		PREFIX = gtk_vseparator_

#ifdef GTK_VSEPARATOR

int
gtk_vseparator_get_type(self)
	Gtk::VSeparator	self
	CODE:
	RETVAL = gtk_vseparator_get_type();
	OUTPUT:
	RETVAL

int
gtk_vseparator_get_size(self)
	Gtk::VSeparator	self
	CODE:
	RETVAL = sizeof(GtkVSeparator);
	OUTPUT:
	RETVAL


int
gtk_vseparator_get_class_size(self)
	Gtk::VSeparator	self
	CODE:
	RETVAL = sizeof(GtkVSeparatorClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Viewport		PREFIX = gtk_viewport_

#ifdef GTK_VIEWPORT

int
gtk_viewport_get_type(self)
	Gtk::Viewport	self
	CODE:
	RETVAL = gtk_viewport_get_type();
	OUTPUT:
	RETVAL

int
gtk_viewport_get_size(self)
	Gtk::Viewport	self
	CODE:
	RETVAL = sizeof(GtkViewport);
	OUTPUT:
	RETVAL


int
gtk_viewport_get_class_size(self)
	Gtk::Viewport	self
	CODE:
	RETVAL = sizeof(GtkViewportClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Widget		PREFIX = gtk_widget_

#ifdef GTK_WIDGET

int
gtk_widget_get_type(self)
	Gtk::Widget	self
	CODE:
	RETVAL = gtk_widget_get_type();
	OUTPUT:
	RETVAL

int
gtk_widget_get_size(self)
	Gtk::Widget	self
	CODE:
	RETVAL = sizeof(GtkWidget);
	OUTPUT:
	RETVAL


int
gtk_widget_get_class_size(self)
	Gtk::Widget	self
	CODE:
	RETVAL = sizeof(GtkWidgetClass);
	OUTPUT:
	RETVAL

#endif

	
MODULE = Gtk	PACKAGE = Gtk::Window		PREFIX = gtk_window_

#ifdef GTK_WINDOW

int
gtk_window_get_type(self)
	Gtk::Window	self
	CODE:
	RETVAL = gtk_window_get_type();
	OUTPUT:
	RETVAL

int
gtk_window_get_size(self)
	Gtk::Window	self
	CODE:
	RETVAL = sizeof(GtkWindow);
	OUTPUT:
	RETVAL


int
gtk_window_get_class_size(self)
	Gtk::Window	self
	CODE:
	RETVAL = sizeof(GtkWindowClass);
	OUTPUT:
	RETVAL

#endif

BOOT:
{
	#ifdef GTK_ADJUSTMENT
                extern void boot_Gtk__Adjustment(CV *cv);
		callXS (boot_Gtk__Adjustment, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_ALIGNMENT
                extern void boot_Gtk__Alignment(CV *cv);
		callXS (boot_Gtk__Alignment, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_ARROW
                extern void boot_Gtk__Arrow(CV *cv);
		callXS (boot_Gtk__Arrow, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_ASPECT_FRAME
                extern void boot_Gtk__AspectFrame(CV *cv);
		callXS (boot_Gtk__AspectFrame, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_BIN
                extern void boot_Gtk__Bin(CV *cv);
		callXS (boot_Gtk__Bin, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_BOX
                extern void boot_Gtk__Box(CV *cv);
		callXS (boot_Gtk__Box, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_BUTTON
                extern void boot_Gtk__Button(CV *cv);
		callXS (boot_Gtk__Button, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_BUTTON_BOX
                extern void boot_Gtk__ButtonBox(CV *cv);
		callXS (boot_Gtk__ButtonBox, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_CLIST
                extern void boot_Gtk__CList(CV *cv);
		callXS (boot_Gtk__CList, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_CHECK_BUTTON
                extern void boot_Gtk__CheckButton(CV *cv);
		callXS (boot_Gtk__CheckButton, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_CHECK_MENU_ITEM
                extern void boot_Gtk__CheckMenuItem(CV *cv);
		callXS (boot_Gtk__CheckMenuItem, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_COLOR_SELECTION
                extern void boot_Gtk__ColorSelection(CV *cv);
		callXS (boot_Gtk__ColorSelection, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_COLOR_SELECTION_DIALOG
                extern void boot_Gtk__ColorSelectionDialog(CV *cv);
		callXS (boot_Gtk__ColorSelectionDialog, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_COMBO
                extern void boot_Gtk__Combo(CV *cv);
		callXS (boot_Gtk__Combo, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_CONTAINER
                extern void boot_Gtk__Container(CV *cv);
		callXS (boot_Gtk__Container, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_CURVE
                extern void boot_Gtk__Curve(CV *cv);
		callXS (boot_Gtk__Curve, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_DATA
                extern void boot_Gtk__Data(CV *cv);
		callXS (boot_Gtk__Data, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_DIALOG
                extern void boot_Gtk__Dialog(CV *cv);
		callXS (boot_Gtk__Dialog, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_DRAWING_AREA
                extern void boot_Gtk__DrawingArea(CV *cv);
		callXS (boot_Gtk__DrawingArea, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_EDITABLE
                extern void boot_Gtk__Editable(CV *cv);
		callXS (boot_Gtk__Editable, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_ENTRY
                extern void boot_Gtk__Entry(CV *cv);
		callXS (boot_Gtk__Entry, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_EVENT_BOX
                extern void boot_Gtk__EventBox(CV *cv);
		callXS (boot_Gtk__EventBox, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_FILE_SELECTION
                extern void boot_Gtk__FileSelection(CV *cv);
		callXS (boot_Gtk__FileSelection, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_FIXED
                extern void boot_Gtk__Fixed(CV *cv);
		callXS (boot_Gtk__Fixed, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_FRAME
                extern void boot_Gtk__Frame(CV *cv);
		callXS (boot_Gtk__Frame, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_GAMMA_CURVE
                extern void boot_Gtk__GammaCurve(CV *cv);
		callXS (boot_Gtk__GammaCurve, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_HBOX
                extern void boot_Gtk__HBox(CV *cv);
		callXS (boot_Gtk__HBox, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_HBUTTON_BOX
                extern void boot_Gtk__HButtonBox(CV *cv);
		callXS (boot_Gtk__HButtonBox, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_HPANED
                extern void boot_Gtk__HPaned(CV *cv);
		callXS (boot_Gtk__HPaned, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_HRULER
                extern void boot_Gtk__HRuler(CV *cv);
		callXS (boot_Gtk__HRuler, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_HSCALE
                extern void boot_Gtk__HScale(CV *cv);
		callXS (boot_Gtk__HScale, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_HSCROLLBAR
                extern void boot_Gtk__HScrollbar(CV *cv);
		callXS (boot_Gtk__HScrollbar, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_HSEPARATOR
                extern void boot_Gtk__HSeparator(CV *cv);
		callXS (boot_Gtk__HSeparator, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_HANDLE_BOX
                extern void boot_Gtk__HandleBox(CV *cv);
		callXS (boot_Gtk__HandleBox, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_IMAGE
                extern void boot_Gtk__Image(CV *cv);
		callXS (boot_Gtk__Image, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_INPUT_DIALOG
                extern void boot_Gtk__InputDialog(CV *cv);
		callXS (boot_Gtk__InputDialog, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_ITEM
                extern void boot_Gtk__Item(CV *cv);
		callXS (boot_Gtk__Item, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_LABEL
                extern void boot_Gtk__Label(CV *cv);
		callXS (boot_Gtk__Label, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_LIST
                extern void boot_Gtk__List(CV *cv);
		callXS (boot_Gtk__List, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_LIST_ITEM
                extern void boot_Gtk__ListItem(CV *cv);
		callXS (boot_Gtk__ListItem, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_MENU
                extern void boot_Gtk__Menu(CV *cv);
		callXS (boot_Gtk__Menu, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_MENU_BAR
                extern void boot_Gtk__MenuBar(CV *cv);
		callXS (boot_Gtk__MenuBar, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_MENU_ITEM
                extern void boot_Gtk__MenuItem(CV *cv);
		callXS (boot_Gtk__MenuItem, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_MENU_SHELL
                extern void boot_Gtk__MenuShell(CV *cv);
		callXS (boot_Gtk__MenuShell, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_MISC
                extern void boot_Gtk__Misc(CV *cv);
		callXS (boot_Gtk__Misc, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_NOTEBOOK
                extern void boot_Gtk__Notebook(CV *cv);
		callXS (boot_Gtk__Notebook, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_OBJECT
                extern void boot_Gtk__Object(CV *cv);
		callXS (boot_Gtk__Object, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_OPTION_MENU
                extern void boot_Gtk__OptionMenu(CV *cv);
		callXS (boot_Gtk__OptionMenu, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_PANED
                extern void boot_Gtk__Paned(CV *cv);
		callXS (boot_Gtk__Paned, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_PIXMAP
                extern void boot_Gtk__Pixmap(CV *cv);
		callXS (boot_Gtk__Pixmap, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_PREVIEW
                extern void boot_Gtk__Preview(CV *cv);
		callXS (boot_Gtk__Preview, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_PROGRESS_BAR
                extern void boot_Gtk__ProgressBar(CV *cv);
		callXS (boot_Gtk__ProgressBar, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_RADIO_BUTTON
                extern void boot_Gtk__RadioButton(CV *cv);
		callXS (boot_Gtk__RadioButton, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_RADIO_MENU_ITEM
                extern void boot_Gtk__RadioMenuItem(CV *cv);
		callXS (boot_Gtk__RadioMenuItem, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_RANGE
                extern void boot_Gtk__Range(CV *cv);
		callXS (boot_Gtk__Range, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_RULER
                extern void boot_Gtk__Ruler(CV *cv);
		callXS (boot_Gtk__Ruler, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_SCALE
                extern void boot_Gtk__Scale(CV *cv);
		callXS (boot_Gtk__Scale, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_SCROLLBAR
                extern void boot_Gtk__Scrollbar(CV *cv);
		callXS (boot_Gtk__Scrollbar, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_SCROLLED_WINDOW
                extern void boot_Gtk__ScrolledWindow(CV *cv);
		callXS (boot_Gtk__ScrolledWindow, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_SEPARATOR
                extern void boot_Gtk__Separator(CV *cv);
		callXS (boot_Gtk__Separator, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_SPIN_BUTTON
                extern void boot_Gtk__SpinButton(CV *cv);
		callXS (boot_Gtk__SpinButton, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_STATUSBAR
                extern void boot_Gtk__Statusbar(CV *cv);
		callXS (boot_Gtk__Statusbar, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_TABLE
                extern void boot_Gtk__Table(CV *cv);
		callXS (boot_Gtk__Table, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_TEXT
                extern void boot_Gtk__Text(CV *cv);
		callXS (boot_Gtk__Text, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_TIPS_QUERY
                extern void boot_Gtk__TipsQuery(CV *cv);
		callXS (boot_Gtk__TipsQuery, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_TOGGLE_BUTTON
                extern void boot_Gtk__ToggleButton(CV *cv);
		callXS (boot_Gtk__ToggleButton, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_TOOLBAR
                extern void boot_Gtk__Toolbar(CV *cv);
		callXS (boot_Gtk__Toolbar, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_TOOLTIPS
                extern void boot_Gtk__Tooltips(CV *cv);
		callXS (boot_Gtk__Tooltips, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_TREE
                extern void boot_Gtk__Tree(CV *cv);
		callXS (boot_Gtk__Tree, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_TREE_ITEM
                extern void boot_Gtk__TreeItem(CV *cv);
		callXS (boot_Gtk__TreeItem, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_VBOX
                extern void boot_Gtk__VBox(CV *cv);
		callXS (boot_Gtk__VBox, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_VBUTTON_BOX
                extern void boot_Gtk__VButtonBox(CV *cv);
		callXS (boot_Gtk__VButtonBox, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_VPANED
                extern void boot_Gtk__VPaned(CV *cv);
		callXS (boot_Gtk__VPaned, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_VRULER
                extern void boot_Gtk__VRuler(CV *cv);
		callXS (boot_Gtk__VRuler, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_VSCALE
                extern void boot_Gtk__VScale(CV *cv);
		callXS (boot_Gtk__VScale, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_VSCROLLBAR
                extern void boot_Gtk__VScrollbar(CV *cv);
		callXS (boot_Gtk__VScrollbar, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_VSEPARATOR
                extern void boot_Gtk__VSeparator(CV *cv);
		callXS (boot_Gtk__VSeparator, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_VIEWPORT
                extern void boot_Gtk__Viewport(CV *cv);
		callXS (boot_Gtk__Viewport, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_WIDGET
                extern void boot_Gtk__Widget(CV *cv);
		callXS (boot_Gtk__Widget, cv, mark);
	#endif
}

BOOT:
{
	#ifdef GTK_WINDOW
                extern void boot_Gtk__Window(CV *cv);
		callXS (boot_Gtk__Window, cv, mark);
	#endif
}

