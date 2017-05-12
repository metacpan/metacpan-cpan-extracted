#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "wiiuse.h"

MODULE = Linux::Input::Wiiuse		PACKAGE = Linux::Input::Wiiuse

const char *
wiiuse_version()

struct wiimote_t **
wiiuse_init(int wiimotes)

void
wiiuse_disconnected(struct wiimote_t* wm)

void
wiiuse_cleanup(struct wiimote_t** wm, int wiimotes)

void
wiiuse_rumble(struct wiimote_t* wm, int status)

void
wiiuse_toggle_rumble(struct wiimote_t* wm)

void
wiiuse_set_leds(struct wiimote_t* wm, int leds)

void
wiiuse_motion_sensing(struct wiimote_t* wm, int status)

int
wiiuse_read_data(struct wiimote_t* wm, byte* buffer, unsigned int offset, unsigned short len)

int
wiiuse_write_data(struct wiimote_t* wm, unsigned int addr, byte* data, byte len)

void
wiiuse_status(struct wiimote_t* wm)

struct wiimote_t *
wiiuse_get_by_id(struct wiimote_t** wm, int wiimotes, int unid)

int
wiiuse_set_flags(struct wiimote_t* wm, int enable, int disable)

float
wiiuse_set_smooth_alpha(struct wiimote_t* wm, float alpha)

void
wiiuse_set_bluetooth_stack(struct wiimote_t** wm, int wiimotes, int type_int)
    CODE:
        win_bt_stack_t type = type_int;
        wiiuse_set_bluetooth_stack(wm, wiimotes, type);

void
wiiuse_set_orient_threshold(struct wiimote_t* wm, float threshold)

void
wiiuse_resync(struct wiimote_t* wm)

void
wiiuse_set_timeout(struct wiimote_t** wm, int wiimotes, byte normal_timeout, byte exp_timeout)

void
wiiuse_set_accel_threshold(struct wiimote_t* wm, int threshold)

int
wiiuse_find(struct wiimote_t** wm, int max_wiimotes, int timeout)

int
wiiuse_connect(struct wiimote_t** wm, int wiimotes)

void
wiiuse_disconnect(struct wiimote_t* wm)

int
wiiuse_poll(struct wiimote_t** wm, int wiimotes)

void
wiiuse_set_ir(struct wiimote_t* wm, int status)

void
wiiuse_set_ir_vres(struct wiimote_t* wm, unsigned int x, unsigned int y)

void
wiiuse_set_ir_position(struct wiimote_t* wm, int pos_int)
    CODE:
        ir_position_t pos = pos_int;
        wiiuse_set_ir_position(wm, pos);

void
wiiuse_set_aspect_ratio(struct wiimote_t* wm, int aspect_int)
    CODE:
        aspect_t aspect = aspect_int;
        wiiuse_set_aspect_ratio(wm, aspect);

void
wiiuse_set_ir_sensitivity(struct wiimote_t* wm, int level)

void
wiiuse_set_nunchuk_orient_threshold(struct wiimote_t* wm, float threshold)

void
wiiuse_set_nunchuk_accel_threshold(struct wiimote_t* wm, int threshold)

int
wiiuse_event(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->event;
    OUTPUT:
        RETVAL

int
wiiuse_state_using_accel(struct wiimote_t* wm)
    CODE:
        RETVAL = WIIUSE_USING_ACC(wm);
    OUTPUT:
        RETVAL

int
wiiuse_state_using_expansion(struct wiimote_t* wm)
    CODE:
        RETVAL = WIIUSE_USING_EXP(wm);
    OUTPUT:
        RETVAL

int
wiiuse_state_using_ir(struct wiimote_t* wm)
    CODE:
        RETVAL = WIIUSE_USING_IR(wm);
    OUTPUT:
        RETVAL

int
wiiuse_state_using_speaker(struct wiimote_t* wm)
    CODE:
        RETVAL = WIIUSE_USING_SPEAKER(wm);
    OUTPUT:
        RETVAL

int
wiiuse_get_leds(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->leds;
    OUTPUT:
        RETVAL

float
wiiuse_battery(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->battery_level;
    OUTPUT:
        RETVAL

int
wiiuse_attachment(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->exp.type;
    OUTPUT:
        RETVAL

float
wiiuse_ir_distance(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->ir.z;
    OUTPUT:
        RETVAL

float
wiiuse_ir_cursor_x(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->ir.x;
    OUTPUT:
        RETVAL

float
wiiuse_ir_cursor_y(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->ir.y;
    OUTPUT:
        RETVAL

int
wiiuse_ir_dot_visible(struct wiimote_t* wm, int dot)
    CODE:
        RETVAL = wm->ir.dot[dot].visible;
    OUTPUT:
        RETVAL

float
wiiuse_ir_dot_x(struct wiimote_t* wm, int dot)
    CODE:
        RETVAL = wm->ir.dot[dot].x;
    OUTPUT:
        RETVAL

float
wiiuse_ir_dot_y(struct wiimote_t* wm, int dot)
    CODE:
        RETVAL = wm->ir.dot[dot].y;
    OUTPUT:
        RETVAL

float
wiiuse_roll(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->orient.roll;
    OUTPUT:
        RETVAL

float
wiiuse_aroll(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->orient.a_roll;
    OUTPUT:
        RETVAL

float
wiiuse_pitch(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->orient.pitch;
    OUTPUT:
        RETVAL

float
wiiuse_apitch(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->orient.a_pitch;
    OUTPUT:
        RETVAL

float
wiiuse_yaw(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->orient.yaw;
    OUTPUT:
        RETVAL

int
wiiuse_buttons_pressed(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->btns;
    OUTPUT:
        RETVAL

int
wiiuse_nunchuk_buttons_pressed(struct wiimote_t* wm)
    CODE:
        struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;
        RETVAL = nc->btns;
    OUTPUT:
        RETVAL

int
wiiuse_classic_buttons_pressed(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->btns;
    OUTPUT:
        RETVAL

int
wiiuse_gh3_buttons_pressed(struct wiimote_t* wm)
    CODE:
        struct guitar_hero_3_t* gh3 = (guitar_hero_3_t*)&wm->exp.gh3;
        RETVAL = gh3->btns;
    OUTPUT:
        RETVAL

int
wiiuse_buttons_held(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->btns_held;
    OUTPUT:
        RETVAL

int
wiiuse_nunchuk_buttons_held(struct wiimote_t* wm)
    CODE:
        struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;
        RETVAL = nc->btns_held;
    OUTPUT:
        RETVAL

int
wiiuse_classic_buttons_held(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->btns_held;
    OUTPUT:
        RETVAL

int
wiiuse_gh3_buttons_held(struct wiimote_t* wm)
    CODE:
        struct guitar_hero_3_t* gh3 = (guitar_hero_3_t*)&wm->exp.gh3;
        RETVAL = gh3->btns_held;
    OUTPUT:
        RETVAL

int
wiiuse_buttons_released(struct wiimote_t* wm)
    CODE:
        RETVAL = wm->btns_released;
    OUTPUT:
        RETVAL

int
wiiuse_nunchuk_buttons_released(struct wiimote_t* wm)
    CODE:
        struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;
        RETVAL = nc->btns_released;
    OUTPUT:
        RETVAL

int
wiiuse_classic_buttons_released(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->btns_released;
    OUTPUT:
        RETVAL

int
wiiuse_gh3_buttons_released(struct wiimote_t* wm)
    CODE:
        struct guitar_hero_3_t* gh3 = (guitar_hero_3_t*)&wm->exp.gh3;
        RETVAL = gh3->btns_released;
    OUTPUT:
        RETVAL

float
wiiuse_nunchuk_roll(struct wiimote_t* wm)
    CODE:
        struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;
        RETVAL = nc->orient.roll;
    OUTPUT:
        RETVAL

float
wiiuse_nunchuk_pitch(struct wiimote_t* wm)
    CODE:
        struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;
        RETVAL = nc->orient.pitch;
    OUTPUT:
        RETVAL

float
wiiuse_nunchuk_yaw(struct wiimote_t* wm)
    CODE:
        struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;
        RETVAL = nc->orient.yaw;
    OUTPUT:
        RETVAL

float
wiiuse_nunchuk_joystick_angle(struct wiimote_t* wm)
    CODE:
        struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;
        RETVAL = nc->js.ang;
    OUTPUT:
        RETVAL

float
wiiuse_nunchuk_joystick_magnitude(struct wiimote_t* wm)
    CODE:
        struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;
        RETVAL = nc->js.mag;
    OUTPUT:
        RETVAL

float
wiiuse_classic_shoulder_left(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->l_shoulder;
    OUTPUT:
        RETVAL

float
wiiuse_classic_shoulder_right(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->r_shoulder;
    OUTPUT:
        RETVAL

float
wiiuse_classic_joystick_left_angle(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->ljs.ang;
    OUTPUT:
        RETVAL

float
wiiuse_classic_joystick_left_magnitude(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->ljs.mag;
    OUTPUT:
        RETVAL

float
wiiuse_classic_joystick_right_angle(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->rjs.ang;
    OUTPUT:
        RETVAL

float
wiiuse_classic_joystick_right_magnitude(struct wiimote_t* wm)
    CODE:
        struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
        RETVAL = cc->rjs.mag;
    OUTPUT:
        RETVAL

float
wiiuse_gh3_whammy(struct wiimote_t* wm)
    CODE:
        struct guitar_hero_3_t* gh3 = (guitar_hero_3_t*)&wm->exp.gh3;
        RETVAL = gh3->whammy_bar;
    OUTPUT:
        RETVAL

float
wiiuse_gh3_joystick_angle(struct wiimote_t* wm)
    CODE:
        struct guitar_hero_3_t* gh3 = (guitar_hero_3_t*)&wm->exp.gh3;
        RETVAL = gh3->js.ang;
    OUTPUT:
        RETVAL

float
wiiuse_gh3_joystick_magnitude(struct wiimote_t* wm)
    CODE:
        struct guitar_hero_3_t* gh3 = (guitar_hero_3_t*)&wm->exp.gh3;
        RETVAL = gh3->js.mag;
    OUTPUT:
        RETVAL
