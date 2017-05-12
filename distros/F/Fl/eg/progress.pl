use strict;
use warnings;
use Fl;

void buttcb(Fl_Widget*,void*data) {
    Fl_Input_Choice *in=(Fl_Input_Choice *)data;
    static int flag = 1;
    flag ^= 1;
    if ( flag ) in->activate();
    else        in->deactivate();
}

int main(int argc, char **argv) {
    Fl::scheme("plastic");		// optional
    Fl_Window win(300, 200);
    Fl_Input_Choice in(40,40,100,28,"Test");
    in.menubutton().add("one");
    in.menubutton().add("two");
    in.menubutton().add("three");
    in.menuvalue(0);
    Fl_Button onoff(40,150,200,28,"Activate/Deactivate");
    onoff.callback(buttcb, (void*)&in);
    win.end();
    win.resizable(win);
    win.show(argc, argv);
    return Fl::run();
}
