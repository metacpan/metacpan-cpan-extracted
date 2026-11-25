#define _CRT_SECURE_NO_WARNINGS
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <windowsx.h>
#include <shellapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#define WM_DD_TRAY    (WM_APP + 1)
#define WM_DD_COMMAND (WM_APP + 2)
#define DD_ROW_HEIGHT 28
#define DD_MAX_POPUPS 16

typedef enum {
    J_NULL,
    J_BOOL,
    J_STRING,
    J_ARRAY,
    J_OBJECT
} JType;

typedef struct JValue JValue;
typedef struct {
    char *key;
    JValue *value;
} JPair;

struct JValue {
    JType type;
    union {
        int boolean;
        char *string;
        struct { JValue **items; size_t count; } array;
        struct { JPair *pairs; size_t count; } object;
    } u;
};

typedef struct DDItem DDItem;
struct DDItem {
    char *name_utf8;
    wchar_t *name;
    wchar_t *icon;
    int clickable;
    int click_stay;
    int removed;
    DDItem *parent;
    DDItem **children;
    size_t child_count;
    UINT tray_id;
    HICON tray_icon;
};

typedef struct {
    HWND hwnd;
    DDItem *owner;
    DDItem **items;
    int count;
    int hover;
    int depth;
} DDPopup;

static HINSTANCE g_instance = NULL;
static HWND g_host = NULL;
static HANDLE g_stdout = NULL;
static DDItem **g_roots = NULL;
static size_t g_root_count = 0;
static UINT g_next_tray_id = 1;
static UINT g_taskbar_created = 0;
static DDPopup *g_popups[DD_MAX_POPUPS];
static int g_popup_count = 0;
static int g_closing_popups = 0;
static HFONT g_menu_font = NULL;

static const wchar_t *HOST_CLASS = L"DeveloperDashboardSystemMenuHost";
static const wchar_t *POPUP_CLASS = L"DeveloperDashboardSystemMenuPopup";

/* ---------------------------- small JSON parser ---------------------------- */

typedef struct {
    const char *p;
    const char *end;
    const char *error;
} JParser;

static void *xcalloc(size_t n, size_t s)
{
    void *p = calloc(n, s);
    if (!p) ExitProcess(111);
    return p;
}

static void *xrealloc(void *p, size_t n)
{
    void *q = realloc(p, n);
    if (!q) ExitProcess(111);
    return q;
}

static char *xstrdup(const char *s)
{
    size_t n = strlen(s) + 1;
    char *p = (char *)xcalloc(n, 1);
    memcpy(p, s, n);
    return p;
}

static void j_skip(JParser *ps)
{
    while (ps->p < ps->end && (*ps->p == ' ' || *ps->p == '\t' || *ps->p == '\r' || *ps->p == '\n')) ps->p++;
}

static int hexval(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return 10 + c - 'a';
    if (c >= 'A' && c <= 'F') return 10 + c - 'A';
    return -1;
}

static void append_utf8(char **buf, size_t *len, size_t *cap, unsigned cp)
{
    unsigned char out[4];
    size_t n = 0;
    if (cp <= 0x7F) { out[0] = (unsigned char)cp; n = 1; }
    else if (cp <= 0x7FF) {
        out[0] = 0xC0 | (cp >> 6);
        out[1] = 0x80 | (cp & 0x3F);
        n = 2;
    }
    else if (cp <= 0xFFFF) {
        out[0] = 0xE0 | (cp >> 12);
        out[1] = 0x80 | ((cp >> 6) & 0x3F);
        out[2] = 0x80 | (cp & 0x3F);
        n = 3;
    }
    else {
        out[0] = 0xF0 | (cp >> 18);
        out[1] = 0x80 | ((cp >> 12) & 0x3F);
        out[2] = 0x80 | ((cp >> 6) & 0x3F);
        out[3] = 0x80 | (cp & 0x3F);
        n = 4;
    }
    if (*len + n + 1 > *cap) {
        while (*len + n + 1 > *cap) *cap *= 2;
        *buf = (char *)xrealloc(*buf, *cap);
    }
    memcpy(*buf + *len, out, n);
    *len += n;
    (*buf)[*len] = 0;
}

static char *j_string(JParser *ps)
{
    size_t cap = 64, len = 0;
    char *buf;
    if (ps->p >= ps->end || *ps->p != '"') return NULL;
    ps->p++;
    buf = (char *)xcalloc(cap, 1);

    while (ps->p < ps->end) {
        unsigned char c = (unsigned char)*ps->p++;
        if (c == '"') return buf;
        if (c == '\\') {
            char e;
            if (ps->p >= ps->end) break;
            e = *ps->p++;
            if (e == '"' || e == '\\' || e == '/') c = (unsigned char)e;
            else if (e == 'b') c = '\b';
            else if (e == 'f') c = '\f';
            else if (e == 'n') c = '\n';
            else if (e == 'r') c = '\r';
            else if (e == 't') c = '\t';
            else if (e == 'u') {
                int h0, h1, h2, h3;
                unsigned cp;
                if (ps->end - ps->p < 4) break;
                h0 = hexval(ps->p[0]); h1 = hexval(ps->p[1]);
                h2 = hexval(ps->p[2]); h3 = hexval(ps->p[3]);
                if (h0 < 0 || h1 < 0 || h2 < 0 || h3 < 0) break;
                cp = (unsigned)((h0 << 12) | (h1 << 8) | (h2 << 4) | h3);
                ps->p += 4;
                if (cp >= 0xD800 && cp <= 0xDBFF && ps->end - ps->p >= 6 && ps->p[0] == '\\' && ps->p[1] == 'u') {
                    int l0 = hexval(ps->p[2]), l1 = hexval(ps->p[3]);
                    int l2 = hexval(ps->p[4]), l3 = hexval(ps->p[5]);
                    unsigned low;
                    if (l0 >= 0 && l1 >= 0 && l2 >= 0 && l3 >= 0) {
                        low = (unsigned)((l0 << 12) | (l1 << 8) | (l2 << 4) | l3);
                        if (low >= 0xDC00 && low <= 0xDFFF) {
                            cp = 0x10000 + ((cp - 0xD800) << 10) + (low - 0xDC00);
                            ps->p += 6;
                        }
                    }
                }
                append_utf8(&buf, &len, &cap, cp);
                continue;
            }
            else break;
        }
        if (len + 2 > cap) { cap *= 2; buf = (char *)xrealloc(buf, cap); }
        buf[len++] = (char)c;
        buf[len] = 0;
    }

    free(buf);
    ps->error = "invalid JSON string";
    return NULL;
}

static JValue *j_value(JParser *ps);

static JValue *j_array(JParser *ps)
{
    JValue *v = (JValue *)xcalloc(1, sizeof(*v));
    v->type = J_ARRAY;
    ps->p++;
    j_skip(ps);
    if (ps->p < ps->end && *ps->p == ']') { ps->p++; return v; }
    while (ps->p < ps->end) {
        JValue *item = j_value(ps);
        if (!item) break;
        v->u.array.items = (JValue **)xrealloc(v->u.array.items, sizeof(JValue *) * (v->u.array.count + 1));
        v->u.array.items[v->u.array.count++] = item;
        j_skip(ps);
        if (ps->p < ps->end && *ps->p == ',') { ps->p++; j_skip(ps); continue; }
        if (ps->p < ps->end && *ps->p == ']') { ps->p++; return v; }
        break;
    }
    ps->error = "invalid JSON array";
    return v;
}

static JValue *j_object(JParser *ps)
{
    JValue *v = (JValue *)xcalloc(1, sizeof(*v));
    v->type = J_OBJECT;
    ps->p++;
    j_skip(ps);
    if (ps->p < ps->end && *ps->p == '}') { ps->p++; return v; }
    while (ps->p < ps->end) {
        char *key;
        JValue *value;
        j_skip(ps);
        key = j_string(ps);
        if (!key) break;
        j_skip(ps);
        if (ps->p >= ps->end || *ps->p != ':') { free(key); break; }
        ps->p++;
        j_skip(ps);
        value = j_value(ps);
        if (!value) { free(key); break; }
        v->u.object.pairs = (JPair *)xrealloc(v->u.object.pairs, sizeof(JPair) * (v->u.object.count + 1));
        v->u.object.pairs[v->u.object.count].key = key;
        v->u.object.pairs[v->u.object.count].value = value;
        v->u.object.count++;
        j_skip(ps);
        if (ps->p < ps->end && *ps->p == ',') { ps->p++; continue; }
        if (ps->p < ps->end && *ps->p == '}') { ps->p++; return v; }
        break;
    }
    ps->error = "invalid JSON object";
    return v;
}

static JValue *j_value(JParser *ps)
{
    JValue *v;
    j_skip(ps);
    if (ps->p >= ps->end) return NULL;
    if (*ps->p == '{') return j_object(ps);
    if (*ps->p == '[') return j_array(ps);
    if (*ps->p == '"') {
        char *s = j_string(ps);
        if (!s) return NULL;
        v = (JValue *)xcalloc(1, sizeof(*v));
        v->type = J_STRING;
        v->u.string = s;
        return v;
    }
    if (ps->end - ps->p >= 4 && memcmp(ps->p, "true", 4) == 0) {
        ps->p += 4; v = (JValue *)xcalloc(1, sizeof(*v)); v->type = J_BOOL; v->u.boolean = 1; return v;
    }
    if (ps->end - ps->p >= 5 && memcmp(ps->p, "false", 5) == 0) {
        ps->p += 5; v = (JValue *)xcalloc(1, sizeof(*v)); v->type = J_BOOL; v->u.boolean = 0; return v;
    }
    if (ps->end - ps->p >= 4 && memcmp(ps->p, "null", 4) == 0) {
        ps->p += 4; v = (JValue *)xcalloc(1, sizeof(*v)); v->type = J_NULL; return v;
    }
    ps->error = "unsupported JSON value";
    return NULL;
}

static void j_free(JValue *v)
{
    size_t i;
    if (!v) return;
    if (v->type == J_STRING) free(v->u.string);
    else if (v->type == J_ARRAY) {
        for (i = 0; i < v->u.array.count; i++) j_free(v->u.array.items[i]);
        free(v->u.array.items);
    }
    else if (v->type == J_OBJECT) {
        for (i = 0; i < v->u.object.count; i++) {
            free(v->u.object.pairs[i].key);
            j_free(v->u.object.pairs[i].value);
        }
        free(v->u.object.pairs);
    }
    free(v);
}

static JValue *j_parse(const char *s)
{
    JParser ps;
    JValue *v;
    ps.p = s; ps.end = s + strlen(s); ps.error = NULL;
    v = j_value(&ps);
    j_skip(&ps);
    if (!v || ps.p != ps.end || ps.error) {
        j_free(v);
        return NULL;
    }
    return v;
}

static JValue *j_get(JValue *obj, const char *key)
{
    size_t i;
    if (!obj || obj->type != J_OBJECT) return NULL;
    for (i = 0; i < obj->u.object.count; i++) {
        if (strcmp(obj->u.object.pairs[i].key, key) == 0) return obj->u.object.pairs[i].value;
    }
    return NULL;
}

static const char *j_get_string(JValue *obj, const char *key)
{
    JValue *v = j_get(obj, key);
    return v && v->type == J_STRING ? v->u.string : NULL;
}

static int j_get_bool(JValue *obj, const char *key, int def)
{
    JValue *v = j_get(obj, key);
    return v && v->type == J_BOOL ? v->u.boolean : def;
}

/* ---------------------------- Unicode / output ----------------------------- */

static wchar_t *utf8_to_wide(const char *s)
{
    int n;
    wchar_t *w;
    if (!s) return NULL;
    n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, s, -1, NULL, 0);
    if (!n) n = MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0);
    if (!n) return NULL;
    w = (wchar_t *)xcalloc((size_t)n, sizeof(wchar_t));
    MultiByteToWideChar(CP_UTF8, 0, s, -1, w, n);
    return w;
}

static int write_all(HANDLE h, const char *buf, size_t len)
{
    while (len) {
        DWORD n = 0;
        DWORD want = len > 0x7fffffffU ? 0x7fffffffU : (DWORD)len;
        if (!WriteFile(h, buf, want, &n, NULL) || n == 0) return 0;
        buf += n;
        len -= n;
    }
    return 1;
}

static void emit_json_string(const char *s)
{
    const unsigned char *p = (const unsigned char *)s;
    write_all(g_stdout, "\"", 1);
    while (*p) {
        char esc[7];
        if (*p == '"') write_all(g_stdout, "\\\"", 2);
        else if (*p == '\\') write_all(g_stdout, "\\\\", 2);
        else if (*p == '\n') write_all(g_stdout, "\\n", 2);
        else if (*p == '\r') write_all(g_stdout, "\\r", 2);
        else if (*p == '\t') write_all(g_stdout, "\\t", 2);
        else if (*p < 0x20) {
            _snprintf(esc, sizeof(esc), "\\u%04x", (unsigned)*p);
            write_all(g_stdout, esc, 6);
        }
        else write_all(g_stdout, (const char *)p, 1);
        p++;
    }
    write_all(g_stdout, "\"", 1);
}

static void emit_click(DDItem *item)
{
    if (!item || !item->name_utf8) return;
    write_all(g_stdout, "{\"event\":\"click\",\"name\":", 24);
    emit_json_string(item->name_utf8);
    write_all(g_stdout, "}\n", 2);
}

/* ------------------------------ item model -------------------------------- */

static DDItem *item_from_json(JValue *obj, DDItem *parent)
{
    const char *name;
    const char *icon;
    JValue *children;
    DDItem *item;
    size_t i;

    if (!obj || obj->type != J_OBJECT) return NULL;
    name = j_get_string(obj, "name");
    icon = j_get_string(obj, "icon");
    if (!name || !icon) return NULL;

    item = (DDItem *)xcalloc(1, sizeof(*item));
    item->name_utf8 = xstrdup(name);
    item->name = utf8_to_wide(name);
    item->icon = utf8_to_wide(icon);
    item->clickable = j_get(obj, "click") != NULL;
    item->click_stay = j_get_bool(obj, "click_stay", 0);
    item->parent = parent;

    children = j_get(obj, "menu");
    if (children && children->type == J_ARRAY) {
        item->children = (DDItem **)xcalloc(children->u.array.count ? children->u.array.count : 1, sizeof(DDItem *));
        for (i = 0; i < children->u.array.count; i++) {
            DDItem *child = item_from_json(children->u.array.items[i], item);
            if (child) item->children[item->child_count++] = child;
        }
    }
    return item;
}

static void item_free(DDItem *item)
{
    size_t i;
    if (!item) return;
    for (i = 0; i < item->child_count; i++) item_free(item->children[i]);
    if (item->tray_icon) DestroyIcon(item->tray_icon);
    free(item->children);
    free(item->name_utf8);
    free(item->name);
    free(item->icon);
    free(item);
}

static DDItem *find_item_rec(DDItem *item, const char *name)
{
    size_t i;
    DDItem *found;
    if (!item) return NULL;
    if (item->name_utf8 && strcmp(item->name_utf8, name) == 0) return item;
    for (i = 0; i < item->child_count; i++) {
        found = find_item_rec(item->children[i], name);
        if (found) return found;
    }
    return NULL;
}

static DDItem *find_item(const char *name)
{
    size_t i;
    DDItem *found;
    for (i = 0; i < g_root_count; i++) {
        found = find_item_rec(g_roots[i], name);
        if (found) return found;
    }
    return NULL;
}

static DDItem *find_root_by_tray_id(UINT id)
{
    size_t i;
    for (i = 0; i < g_root_count; i++) {
        if (!g_roots[i]->removed && g_roots[i]->tray_id == id) return g_roots[i];
    }
    return NULL;
}

/* ----------------------------- tray rendering ------------------------------ */

static int contains_non_ascii(const wchar_t *s)
{
    while (s && *s) { if (*s > 127) return 1; s++; }
    return 0;
}

static HICON create_text_icon(const wchar_t *text)
{
    int w = GetSystemMetrics(SM_CXSMICON);
    int h = GetSystemMetrics(SM_CYSMICON);
    BITMAPINFO bi;
    void *bits = NULL;
    HDC screen = GetDC(NULL);
    HDC dc = CreateCompatibleDC(screen);
    HBITMAP color;
    HBITMAP oldbmp;
    HFONT font, oldfont;
    LOGFONTW lf;
    RECT rc;
    DWORD *px;
    int i, count;
    BYTE *maskbits;
    HBITMAP mask;
    ICONINFO ii;
    HICON icon;

    if (w < 16) w = 16;
    if (h < 16) h = 16;

    ZeroMemory(&bi, sizeof(bi));
    bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bi.bmiHeader.biWidth = w;
    bi.bmiHeader.biHeight = -h;
    bi.bmiHeader.biPlanes = 1;
    bi.bmiHeader.biBitCount = 32;
    bi.bmiHeader.biCompression = BI_RGB;

    color = CreateDIBSection(screen, &bi, DIB_RGB_COLORS, &bits, NULL, 0);
    ReleaseDC(NULL, screen);
    if (!color || !bits || !dc) return LoadIcon(NULL, IDI_APPLICATION);

    px = (DWORD *)bits;
    count = w * h;
    for (i = 0; i < count; i++) px[i] = RGB(1, 2, 3);

    oldbmp = (HBITMAP)SelectObject(dc, color);
    ZeroMemory(&lf, sizeof(lf));
    lf.lfHeight = -(h - 2);
    lf.lfWeight = FW_NORMAL;
    lf.lfQuality = CLEARTYPE_QUALITY;
    wcsncpy(lf.lfFaceName, contains_non_ascii(text) ? L"Segoe UI Emoji" : L"Segoe UI", LF_FACESIZE - 1);
    font = CreateFontIndirectW(&lf);
    oldfont = (HFONT)SelectObject(dc, font);
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, RGB(255,255,255));
    rc.left = 0; rc.top = -1; rc.right = w; rc.bottom = h;
    DrawTextW(dc, text ? text : L"", -1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);

    SelectObject(dc, oldfont);
    SelectObject(dc, oldbmp);
    DeleteObject(font);
    DeleteDC(dc);

    for (i = 0; i < count; i++) {
        DWORD rgb = px[i] & 0x00FFFFFF;
        if (rgb == (RGB(1,2,3) & 0x00FFFFFF)) px[i] = 0;
        else px[i] = rgb | 0xFF000000;
    }

    maskbits = (BYTE *)xcalloc((size_t)((w + 15) / 16 * 2 * h), 1);
    mask = CreateBitmap(w, h, 1, 1, maskbits);
    free(maskbits);

    ZeroMemory(&ii, sizeof(ii));
    ii.fIcon = TRUE;
    ii.hbmColor = color;
    ii.hbmMask = mask;
    icon = CreateIconIndirect(&ii);
    DeleteObject(mask);
    DeleteObject(color);
    return icon ? icon : CopyIcon(LoadIcon(NULL, IDI_APPLICATION));
}

static void add_or_modify_tray(DDItem *item, int add)
{
    NOTIFYICONDATAW nid;
    if (!item || item->removed) return;

    if (item->tray_icon) { DestroyIcon(item->tray_icon); item->tray_icon = NULL; }
    item->tray_icon = create_text_icon(item->icon);

    ZeroMemory(&nid, sizeof(nid));
    nid.cbSize = sizeof(nid);
    nid.hWnd = g_host;
    nid.uID = item->tray_id;
    nid.uFlags = NIF_MESSAGE | NIF_ICON;
    nid.uCallbackMessage = WM_DD_TRAY;
    nid.hIcon = item->tray_icon;
    Shell_NotifyIconW(add ? NIM_ADD : NIM_MODIFY, &nid);
}

static void delete_tray(DDItem *item)
{
    NOTIFYICONDATAW nid;
    if (!item || !item->tray_id) return;
    ZeroMemory(&nid, sizeof(nid));
    nid.cbSize = sizeof(nid);
    nid.hWnd = g_host;
    nid.uID = item->tray_id;
    Shell_NotifyIconW(NIM_DELETE, &nid);
}

/* -------------------------- custom popup menus ----------------------------- */

static int item_visible_child_count(DDItem *owner)
{
    size_t i;
    int n = 0;
    for (i = 0; owner && i < owner->child_count; i++) if (!owner->children[i]->removed) n++;
    return n;
}

static void popup_close_from(int depth);

static void popup_free(DDPopup *p)
{
    if (!p) return;
    free(p->items);
    free(p);
}

static DDPopup *popup_at_point(POINT pt, int *row_out)
{
    int d;
    for (d = g_popup_count - 1; d >= 0; d--) {
        RECT r;
        DDPopup *p = g_popups[d];
        if (!p || !IsWindow(p->hwnd)) continue;
        GetWindowRect(p->hwnd, &r);
        if (PtInRect(&r, pt)) {
            int row = (pt.y - r.top) / DD_ROW_HEIGHT;
            if (row >= 0 && row < p->count) {
                if (row_out) *row_out = row;
                return p;
            }
        }
    }
    return NULL;
}

static void popup_set_hover(DDPopup *p, int row)
{
    if (!p || p->hover == row) return;
    p->hover = row;
    InvalidateRect(p->hwnd, NULL, FALSE);
}

static void popup_close_all(void)
{
    if (g_closing_popups) return;
    g_closing_popups = 1;
    if (GetCapture()) ReleaseCapture();
    popup_close_from(0);
    g_closing_popups = 0;
}

static void popup_close_from(int depth)
{
    int i;
    for (i = g_popup_count - 1; i >= depth; i--) {
        DDPopup *p = g_popups[i];
        g_popups[i] = NULL;
        if (p && IsWindow(p->hwnd)) DestroyWindow(p->hwnd);
        popup_free(p);
    }
    if (g_popup_count > depth) g_popup_count = depth;
}

static void popup_measure(DDItem *owner, int *width, int *height)
{
    HDC dc = GetDC(NULL);
    HFONT old = (HFONT)SelectObject(dc, g_menu_font);
    SIZE sz;
    size_t i;
    int w = 140;
    int n = 0;

    for (i = 0; owner && i < owner->child_count; i++) {
        DDItem *item = owner->children[i];
        if (item->removed) continue;
        if (GetTextExtentPoint32W(dc, item->icon ? item->icon : L"", (int)wcslen(item->icon ? item->icon : L""), &sz)) {
            int need = sz.cx + (item->child_count ? 52 : 38);
            if (need > w) w = need;
        }
        n++;
    }

    SelectObject(dc, old);
    ReleaseDC(NULL, dc);
    *width = w;
    *height = n * DD_ROW_HEIGHT;
}

static void popup_adjust_position(int *x, int *y, int w, int h, int child, RECT *parent_rect)
{
    POINT pt;
    HMONITOR mon;
    MONITORINFO mi;
    pt.x = *x; pt.y = *y;
    mon = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
    ZeroMemory(&mi, sizeof(mi)); mi.cbSize = sizeof(mi);
    GetMonitorInfoW(mon, &mi);

    if (child && parent_rect && *x + w > mi.rcWork.right) *x = parent_rect->left - w + 1;
    else if (*x + w > mi.rcWork.right) *x = mi.rcWork.right - w;
    if (*x < mi.rcWork.left) *x = mi.rcWork.left;

    if (*y + h > mi.rcWork.bottom) *y = mi.rcWork.bottom - h;
    if (*y < mi.rcWork.top) *y = mi.rcWork.top;
}

static DDPopup *popup_open(DDItem *owner, int x, int y, int depth, RECT *parent_rect)
{
    DDPopup *p;
    size_t i;
    int width, height, n = 0;

    if (!owner || depth >= DD_MAX_POPUPS || item_visible_child_count(owner) == 0) return NULL;
    popup_close_from(depth);

    p = (DDPopup *)xcalloc(1, sizeof(*p));
    p->owner = owner;
    p->hover = -1;
    p->depth = depth;
    p->count = item_visible_child_count(owner);
    p->items = (DDItem **)xcalloc((size_t)p->count, sizeof(DDItem *));
    for (i = 0; i < owner->child_count; i++) if (!owner->children[i]->removed) p->items[n++] = owner->children[i];

    popup_measure(owner, &width, &height);
    popup_adjust_position(&x, &y, width, height, depth > 0, parent_rect);

    p->hwnd = CreateWindowExW(
        WS_EX_TOOLWINDOW | WS_EX_TOPMOST,
        POPUP_CLASS,
        L"",
        WS_POPUP | WS_BORDER,
        x, y, width, height,
        NULL, NULL, g_instance, p);
    if (!p->hwnd) { popup_free(p); return NULL; }

    g_popups[depth] = p;
    if (g_popup_count < depth + 1) g_popup_count = depth + 1;
    ShowWindow(p->hwnd, SW_SHOWNOACTIVATE);
    UpdateWindow(p->hwnd);
    return p;
}

static void popup_open_child(DDPopup *p, int row)
{
    DDItem *item;
    RECT r;
    int x, y;
    if (!p || row < 0 || row >= p->count) return;
    item = p->items[row];
    if (!item || item_visible_child_count(item) == 0) {
        popup_close_from(p->depth + 1);
        return;
    }

    if (p->depth + 1 < g_popup_count && g_popups[p->depth + 1] && g_popups[p->depth + 1]->owner == item)
        return;

    GetWindowRect(p->hwnd, &r);
    x = r.right - 1;
    y = r.top + row * DD_ROW_HEIGHT;
    popup_open(item, x, y, p->depth + 1, &r);
}

static void handle_popup_mouse(HWND capture_hwnd, LPARAM lParam, int click)
{
    POINT pt;
    DDPopup *p;
    int row = -1;
    DDItem *item;

    pt.x = GET_X_LPARAM(lParam);
    pt.y = GET_Y_LPARAM(lParam);
    ClientToScreen(capture_hwnd, &pt);
    p = popup_at_point(pt, &row);

    if (!p) {
        int i;
        for (i = 0; i < g_popup_count; i++) popup_set_hover(g_popups[i], -1);
        if (click) popup_close_all();
        return;
    }

    popup_set_hover(p, row);
    item = p->items[row];
    if (item && item_visible_child_count(item) > 0) popup_open_child(p, row);
    else popup_close_from(p->depth + 1);

    if (!click || !item || item->removed) return;
    if (item_visible_child_count(item) > 0) return;
    if (!item->clickable) return;

    if (!item->click_stay) popup_close_all();
    emit_click(item);
}

static void popup_show_root(DDItem *root)
{
    POINT pt;
    DDPopup *p;
    if (!root || item_visible_child_count(root) == 0) return;
    popup_close_all();
    GetCursorPos(&pt);
    p = popup_open(root, pt.x, pt.y, 0, NULL);
    if (!p) return;
    SetForegroundWindow(p->hwnd);
    SetFocus(p->hwnd);
    SetCapture(p->hwnd);
}

static LRESULT CALLBACK PopupProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    DDPopup *p = (DDPopup *)GetWindowLongPtrW(hwnd, GWLP_USERDATA);
    switch (msg) {
    case WM_NCCREATE: {
        CREATESTRUCTW *cs = (CREATESTRUCTW *)lParam;
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)cs->lpCreateParams);
        return TRUE;
    }
    case WM_MOUSEMOVE:
        if (g_popup_count && GetCapture() == g_popups[0]->hwnd) handle_popup_mouse(g_popups[0]->hwnd, lParam, 0);
        return 0;
    case WM_LBUTTONUP:
    case WM_RBUTTONUP:
        if (g_popup_count && GetCapture() == g_popups[0]->hwnd) handle_popup_mouse(g_popups[0]->hwnd, lParam, 1);
        return 0;
    case WM_KEYDOWN:
        if (wParam == VK_ESCAPE) { popup_close_all(); return 0; }
        break;
    case WM_CAPTURECHANGED:
        if (!g_closing_popups && g_popup_count) popup_close_all();
        return 0;
    case WM_PAINT:
        if (p) {
            PAINTSTRUCT ps;
            HDC dc = BeginPaint(hwnd, &ps);
            RECT client;
            int i;
            GetClientRect(hwnd, &client);
            FillRect(dc, &client, GetSysColorBrush(COLOR_MENU));
            SelectObject(dc, g_menu_font);
            SetBkMode(dc, TRANSPARENT);

            for (i = 0; i < p->count; i++) {
                DDItem *item = p->items[i];
                RECT row;
                RECT text;
                row.left = 0; row.right = client.right;
                row.top = i * DD_ROW_HEIGHT; row.bottom = row.top + DD_ROW_HEIGHT;
                if (i == p->hover) {
                    FillRect(dc, &row, GetSysColorBrush(COLOR_HIGHLIGHT));
                    SetTextColor(dc, GetSysColor(COLOR_HIGHLIGHTTEXT));
                }
                else SetTextColor(dc, item->clickable || item->child_count ? GetSysColor(COLOR_MENUTEXT) : GetSysColor(COLOR_GRAYTEXT));

                text = row;
                text.left += 20;
                text.right -= item_visible_child_count(item) ? 24 : 8;
                DrawTextW(dc, item->icon ? item->icon : L"", -1, &text, DT_SINGLELINE | DT_VCENTER | DT_LEFT | DT_NOPREFIX);

                if (item_visible_child_count(item)) {
                    RECT arrow = row;
                    arrow.left = arrow.right - 20;
                    DrawTextW(dc, L">", -1, &arrow, DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX);
                }
            }
            EndPaint(hwnd, &ps);
            return 0;
        }
        break;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

static void invalidate_popups(void)
{
    int i;
    for (i = 0; i < g_popup_count; i++) if (g_popups[i] && IsWindow(g_popups[i]->hwnd)) InvalidateRect(g_popups[i]->hwnd, NULL, TRUE);
}

/* ------------------------------- commands --------------------------------- */

static void clear_all(void)
{
    size_t i;
    popup_close_all();
    for (i = 0; i < g_root_count; i++) {
        delete_tray(g_roots[i]);
        item_free(g_roots[i]);
    }
    free(g_roots);
    g_roots = NULL;
    g_root_count = 0;
    g_next_tray_id = 1;
}

static void install_run(JValue *cmd)
{
    JValue *items = j_get(cmd, "items");
    size_t i;
    clear_all();
    if (!items || items->type != J_ARRAY) return;

    g_roots = (DDItem **)xcalloc(items->u.array.count ? items->u.array.count : 1, sizeof(DDItem *));
    for (i = 0; i < items->u.array.count; i++) {
        DDItem *root = item_from_json(items->u.array.items[i], NULL);
        if (!root) continue;
        root->tray_id = g_next_tray_id++;
        g_roots[g_root_count++] = root;
        add_or_modify_tray(root, 1);
    }
}

static void command_icon(JValue *cmd)
{
    const char *name = j_get_string(cmd, "name");
    const char *icon = j_get_string(cmd, "icon");
    DDItem *item;
    wchar_t *w;
    if (!name || !icon) return;
    item = find_item(name);
    if (!item || item->removed) return;
    w = utf8_to_wide(icon);
    if (!w) return;
    free(item->icon);
    item->icon = w;
    if (!item->parent) add_or_modify_tray(item, 0);
    invalidate_popups();
}

static void command_remove(JValue *cmd)
{
    const char *name = j_get_string(cmd, "name");
    DDItem *item;
    if (!name) return;
    item = find_item(name);
    if (!item || item->removed) return;
    item->removed = 1;
    if (!item->parent) delete_tray(item);
    popup_close_all();
}

static void handle_command_line(char *line)
{
    JValue *cmd = j_parse(line);
    const char *op;
    if (!cmd || cmd->type != J_OBJECT) { j_free(cmd); return; }
    op = j_get_string(cmd, "op");
    if (!op) { j_free(cmd); return; }

    if (strcmp(op, "run") == 0) install_run(cmd);
    else if (strcmp(op, "icon") == 0) command_icon(cmd);
    else if (strcmp(op, "remove") == 0) command_remove(cmd);
    else if (strcmp(op, "stop") == 0) {
        clear_all();
        DestroyWindow(g_host);
    }
    j_free(cmd);
}

static DWORD WINAPI stdin_reader(LPVOID unused)
{
    HANDLE in = GetStdHandle(STD_INPUT_HANDLE);
    char tmp[4096];
    char *buf = NULL;
    size_t len = 0, cap = 0;
    (void)unused;

    for (;;) {
        DWORD n = 0;
        size_t start = 0, i;
        if (!ReadFile(in, tmp, sizeof(tmp), &n, NULL) || n == 0) break;
        if (len + n + 1 > cap) {
            cap = cap ? cap : 8192;
            while (len + n + 1 > cap) cap *= 2;
            buf = (char *)xrealloc(buf, cap);
        }
        memcpy(buf + len, tmp, n);
        len += n;
        buf[len] = 0;

        for (i = 0; i < len; i++) {
            if (buf[i] == '\n') {
                size_t line_len = i - start;
                char *line;
                while (line_len && buf[start + line_len - 1] == '\r') line_len--;
                line = (char *)xcalloc(line_len + 1, 1);
                memcpy(line, buf + start, line_len);
                PostMessageW(g_host, WM_DD_COMMAND, 0, (LPARAM)line);
                start = i + 1;
            }
        }
        if (start) {
            memmove(buf, buf + start, len - start);
            len -= start;
            if (buf) buf[len] = 0;
        }
    }

    free(buf);
    PostMessageW(g_host, WM_CLOSE, 0, 0);
    return 0;
}

static LRESULT CALLBACK HostProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (msg == g_taskbar_created && g_taskbar_created != 0) {
        size_t i;
        for (i = 0; i < g_root_count; i++) if (!g_roots[i]->removed) add_or_modify_tray(g_roots[i], 1);
        return 0;
    }

    switch (msg) {
    case WM_DD_COMMAND: {
        char *line = (char *)lParam;
        handle_command_line(line);
        free(line);
        return 0;
    }
    case WM_DD_TRAY: {
        UINT id = (UINT)wParam;
        UINT ev = (UINT)lParam;
        DDItem *root = find_root_by_tray_id(id);
        if (!root) return 0;
        if (ev == WM_LBUTTONUP || ev == WM_RBUTTONUP || ev == WM_CONTEXTMENU) {
            if (item_visible_child_count(root)) popup_show_root(root);
            else if (root->clickable) emit_click(root);
        }
        return 0;
    }
    case WM_CLOSE:
        clear_all();
        DestroyWindow(hwnd);
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

static int register_classes(void)
{
    WNDCLASSEXW wc;
    ZeroMemory(&wc, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.hInstance = g_instance;
    wc.lpfnWndProc = HostProc;
    wc.lpszClassName = HOST_CLASS;
    if (!RegisterClassExW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) return 0;

    ZeroMemory(&wc, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.hInstance = g_instance;
    wc.lpfnWndProc = PopupProc;
    wc.lpszClassName = POPUP_CLASS;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = GetSysColorBrush(COLOR_MENU);
    wc.style = CS_DROPSHADOW;
    if (!RegisterClassExW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) return 0;
    return 1;
}

int main(void)
{
    MSG msg;
    HANDLE thread;
    NONCLIENTMETRICSW ncm;

    g_instance = GetModuleHandleW(NULL);
    g_stdout = GetStdHandle(STD_OUTPUT_HANDLE);
    if (!register_classes()) return 2;

    ZeroMemory(&ncm, sizeof(ncm));
    ncm.cbSize = sizeof(ncm);
    if (SystemParametersInfoW(SPI_GETNONCLIENTMETRICS, sizeof(ncm), &ncm, 0))
        g_menu_font = CreateFontIndirectW(&ncm.lfMenuFont);
    if (!g_menu_font) g_menu_font = (HFONT)GetStockObject(DEFAULT_GUI_FONT);

    g_host = CreateWindowExW(0, HOST_CLASS, L"", 0, 0, 0, 0, 0, HWND_MESSAGE, NULL, g_instance, NULL);
    if (!g_host) return 3;

    g_taskbar_created = RegisterWindowMessageW(L"TaskbarCreated");
    thread = CreateThread(NULL, 0, stdin_reader, NULL, 0, NULL);
    if (thread) CloseHandle(thread);

    while (GetMessageW(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    clear_all();
    if (g_menu_font && g_menu_font != GetStockObject(DEFAULT_GUI_FONT)) DeleteObject(g_menu_font);
    return 0;
}
