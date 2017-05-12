#include "include/Fl_pm.h"

#include <FL/Fl_Box.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Chart.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Light_Button.H>
#include <FL/Fl_Radio_Button.H>
#include <FL/Fl_Radio_Light_Button.H>
#include <FL/Fl_Radio_Round_Button.H>
#include <FL/Fl_Repeat_Button.H>
#include <FL/Fl_Return_Button.H>
#include <FL/Fl_Round_Button.H>
#include <FL/Fl_Toggle_Button.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Secret_Input.H>
#include <FL/Fl_Float_Input.H>
#include <FL/Fl_Int_Input.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_Menu_Item.H>
#include <FL/Fl_Input_Choice.H>
#include <FL/Fl_Menu_Button.H>
#include <FL/Fl_Scrollbar.H>

void         _cache( const char * ptr, const char * cls );
void         _cache( void       * ptr, const char * cls );
const char * _cache( const char * ptr );
const char * _cache( void       * ptr );
void  _delete_cache( void       * ptr );
void  _delete_cache( const char * ptr );

const char * object2package (CTX * w) {
     return object2package(w->cp_ctx);
}

const char * object2package (WidgetSubclass<Fl_Widget> * w) {
     return object2package(w);
}

const char * object2package (Fl_Widget * w) {
     const char * package;
     package = _cache((void *) w);
     if (package != NULL && package[0] != '\0')
          return package;

     /*Remember to add _most_ specific classes first*/
     package = "Fl::Widget";
/*
     const char * user_data = (const char *) w->user_data();

if (user_data != NULL && user_data[0] != '\0') {
     return user_data;
}

     if (dynamic_cast<WidgetSubclass<Fl_Box> *>(w)) {
          return w->user_data(); // See cheat in Fl_pm.h
     }
*/
          if ( dynamic_cast<Fl_Box                  *>(w) ) { package = "Fl::Box";    }
     else if ( dynamic_cast<Fl_Check_Button         *>(w) ) { package = "Fl::CheckButton"; }
     else if ( dynamic_cast<Fl_Radio_Round_Button   *>(w) ) { package = "Fl::RadioRoundButton"; }
     else if ( dynamic_cast<Fl_Round_Button         *>(w) ) { package = "Fl::RoundButton"; }
     else if ( dynamic_cast<Fl_Radio_Light_Button   *>(w) ) { package = "Fl::RadioLightButton"; }
     else if ( dynamic_cast<Fl_Light_Button         *>(w) ) { package = "Fl::LightButton"; }
     else if ( dynamic_cast<Fl_Return_Button        *>(w) ) { package = "Fl::ReturnButton"; }
     else if ( dynamic_cast<Fl_Repeat_Button        *>(w) ) { package = "Fl::RepeatButton"; }
     else if ( dynamic_cast<Fl_Radio_Button         *>(w) ) { package = "Fl::RadioButton"; }
     else if ( dynamic_cast<Fl_Toggle_Button        *>(w) ) { package = "Fl::ToggleButton"; }
     else if ( dynamic_cast<Fl_Button               *>(w) ) { package = "Fl::Button"; }
     else if ( dynamic_cast<Fl_Window               *>(w) ) { package = "Fl::Window"; }
     else if ( dynamic_cast<Fl_Group                *>(w) ) { package = "Fl::Group";  }
     else if ( dynamic_cast<Fl_Chart                *>(w) ) { package = "Fl::Chart";  }

     else if ( dynamic_cast<Fl_Multiline_Input      *>(w) ) { package = "Fl::MultilineInput";  }
     else if ( dynamic_cast<Fl_Int_Input            *>(w) ) { package = "Fl::IntInput";  }
     else if ( dynamic_cast<Fl_Float_Input          *>(w) ) { package = "Fl::FloatInput";  }
     else if ( dynamic_cast<Fl_Secret_Input         *>(w) ) { package = "Fl::SecretInput";  }
     else if ( dynamic_cast<Fl_Input                *>(w) ) { package = "Fl::Input";  }
     else if ( dynamic_cast<      Fl_Menu_Item      *>(w) ||
               dynamic_cast<const Fl_Menu_Item      *>(w) ) { package = "Fl::MenuItem";  }
     else if ( dynamic_cast<Fl_Input_Choice         *>(w) ) { package = "Fl::InputChoice";  }
     else if ( dynamic_cast<Fl_Menu_Button          *>(w) ) { package = "Fl::MenuButton";  }
     else if ( dynamic_cast<Fl_Scrollbar            *>(w) ) { package = "Fl::Scrollbar";  }

     return package;
}
