#include <gtk/gtk.h>
#include <libayatana-appindicator/app-indicator.h>
#include <pango/pangocairo.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

typedef struct DDItem DDItem;
struct DDItem {
    char *name_utf8;
    char *icon_utf8;
    int clickable;
    int click_stay;
    int removed;
    DDItem *parent;
    DDItem **children;
    size_t child_count;
    AppIndicator *indicator;
    char *icon_theme_dir;
    char **icon_files;
    time_t *icon_file_times;
    size_t icon_file_count;
    unsigned long icon_sequence;
    GtkWidget *menu;
    GtkWidget *menu_item;
};

static DDItem **g_roots = NULL;
static size_t g_root_count = 0;
static GIOChannel *g_stdin_channel = NULL;
static unsigned long g_icon_sequence = 0;

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
/* ---------------------------- small JSON parser ---------------------------- */

typedef struct {
    const char *p;
    const char *end;
    const char *error;
} JParser;

static void *xcalloc(size_t n, size_t s)
{
    void *p = calloc(n, s);
    if (!p) exit(111);
    return p;
}

static void *xrealloc(void *p, size_t n)
{
    void *q = realloc(p, n);
    if (!q) exit(111);
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

/* ----------------------------- output/events ------------------------------ */

static int write_all_fd(int fd, const char *buf, size_t len)
{
    while (len) {
        ssize_t n = write(fd, buf, len);
        if (n < 0) {
            if (errno == EINTR) continue;
            return 0;
        }
        if (n == 0) return 0;
        buf += n;
        len -= (size_t)n;
    }
    return 1;
}

static void emit_json_string(const char *s)
{
    const unsigned char *p = (const unsigned char *)s;
    write_all_fd(STDOUT_FILENO, "\"", 1);
    while (*p) {
        char esc[7];
        if (*p == '"') write_all_fd(STDOUT_FILENO, "\\\"", 2);
        else if (*p == '\\') write_all_fd(STDOUT_FILENO, "\\\\", 2);
        else if (*p == '\n') write_all_fd(STDOUT_FILENO, "\\n", 2);
        else if (*p == '\r') write_all_fd(STDOUT_FILENO, "\\r", 2);
        else if (*p == '\t') write_all_fd(STDOUT_FILENO, "\\t", 2);
        else if (*p < 0x20) {
            snprintf(esc, sizeof(esc), "\\u%04x", (unsigned)*p);
            write_all_fd(STDOUT_FILENO, esc, 6);
        }
        else write_all_fd(STDOUT_FILENO, (const char *)p, 1);
        p++;
    }
    write_all_fd(STDOUT_FILENO, "\"", 1);
}

static void emit_click(DDItem *item)
{
    if (!item || !item->name_utf8 || item->removed) return;
    write_all_fd(STDOUT_FILENO, "{\"event\":\"click\",\"name\":", 24);
    emit_json_string(item->name_utf8);
    write_all_fd(STDOUT_FILENO, "}\n", 2);
}

/* ---------------------------- item model --------------------------------- */

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
    item->icon_utf8 = xstrdup(icon);
    item->clickable = j_get(obj, "click") != NULL;
    item->click_stay = j_get_bool(obj, "click_stay", 0);
    item->parent = parent;

    children = j_get(obj, "menu");
    if (children && children->type == J_ARRAY) {
        item->children = (DDItem **)xcalloc(
            children->u.array.count ? children->u.array.count : 1,
            sizeof(DDItem *)
        );
        for (i = 0; i < children->u.array.count; i++) {
            DDItem *child = item_from_json(children->u.array.items[i], item);
            if (child) item->children[item->child_count++] = child;
        }
    }

    return item;
}

static void item_mark_removed(DDItem *item)
{
    size_t i;
    if (!item) return;
    item->removed = 1;
    for (i = 0; i < item->child_count; i++) item_mark_removed(item->children[i]);
}

/* Release an item subtree, its AppIndicator, and all temporary icon assets.
 * Input: owned menu item tree root.
 * Output: no value; releases native and heap resources, reporting filesystem failures.
 */
static void item_free(DDItem *item)
{
    size_t i;
    if (!item) return;
    for (i = 0; i < item->child_count; i++) item_free(item->children[i]);
    if (item->indicator) {
        app_indicator_set_status(item->indicator, APP_INDICATOR_STATUS_PASSIVE);
        g_object_unref(item->indicator);
    }
    for (i = 0; i < item->icon_file_count; i++) {
        if (item->icon_files[i] && unlink(item->icon_files[i]) != 0 && errno != ENOENT)
            fprintf(stderr, "System::Menu: unable to remove indicator icon '%s': %s\n",
                    item->icon_files[i], strerror(errno));
        free(item->icon_files[i]);
    }
    free(item->icon_files);
    free(item->icon_file_times);
    if (item->icon_theme_dir) {
        if (rmdir(item->icon_theme_dir) != 0 && errno != ENOENT)
            fprintf(stderr, "System::Menu: unable to remove icon directory '%s': %s\n",
                    item->icon_theme_dir, strerror(errno));
        g_free(item->icon_theme_dir);
    }
    free(item->children);
    free(item->name_utf8);
    free(item->icon_utf8);
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

/* Remove every active top-level indicator and release its complete item tree.
 * Input: none; uses the process-global root array.
 * Output: no value; leaves the global root array empty.
 */
static void clear_roots(void)
{
    size_t i;
    for (i = 0; i < g_root_count; i++) {
        DDItem *root = g_roots[i];
        if (root->indicator)
            app_indicator_set_status(root->indicator, APP_INDICATOR_STATUS_PASSIVE);
        item_free(root);
    }
    free(g_roots);
    g_roots = NULL;
    g_root_count = 0;
}

/* ---------------------------- icon rendering ----------------------------- */

static GdkPixbuf *render_text_icon(const char *text)
{
    const int size = 24;
    cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, size, size);
    cairo_t *cr = cairo_create(surface);
    PangoLayout *layout = pango_cairo_create_layout(cr);
    PangoFontDescription *font = pango_font_description_from_string("Sans 13");
    PangoRectangle ink, logical;
    double scale = 1.0;
    double x, y;
    GdkPixbuf *pixbuf;

    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
    cairo_set_source_rgba(cr, 0, 0, 0, 0);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);

    pango_layout_set_font_description(layout, font);
    pango_layout_set_text(layout, text ? text : "", -1);
    pango_layout_get_pixel_extents(layout, &ink, &logical);

    if (logical.width > size - 2 && logical.width > 0)
        scale = (double)(size - 2) / (double)logical.width;
    if (logical.height * scale > size - 2 && logical.height > 0)
        scale = (double)(size - 2) / (double)logical.height;

    x = ((double)size - logical.width * scale) / 2.0 - logical.x * scale;
    y = ((double)size - logical.height * scale) / 2.0 - logical.y * scale;

    cairo_translate(cr, x, y);
    cairo_scale(cr, scale, scale);
    /* Ubuntu's top panel is normally dark. Color emoji keep their own glyph
     * colors; ordinary text such as "OK" uses white for readability. */
    cairo_set_source_rgba(cr, 1, 1, 1, 1);
    pango_cairo_show_layout(cr, layout);

    pixbuf = gdk_pixbuf_get_from_surface(surface, 0, 0, size, size);

    pango_font_description_free(font);
    g_object_unref(layout);
    cairo_destroy(cr);
    cairo_surface_destroy(surface);
    return pixbuf;
}

/* Render and publish one root's current text icon through Ayatana AppIndicator.
 * Input: root item with an active AppIndicator and UTF-8 icon text.
 * Output: no value; updates the desktop icon and retains recent icon assets.
 */
static void update_status_icon(DDItem *item)
{
    GdkPixbuf *pixbuf;
    GError *error = NULL;
    char *filename;
    char *icon_name;
    size_t i;
    time_t now = time(NULL);
    if (!item || !item->indicator) return;

    if (!item->icon_theme_dir) {
        item->icon_theme_dir = g_dir_make_tmp("developer-dashboard-menu-XXXXXX", &error);
        if (!item->icon_theme_dir) {
            fprintf(stderr, "System::Menu: unable to create indicator icon directory: %s\n",
                    error ? error->message : "unknown error");
            if (error) g_error_free(error);
            exit(2);
        }
        app_indicator_set_icon_theme_path(item->indicator, item->icon_theme_dir);
    }

    /* Remove icon assets only after a generous grace period: desktop shells
     * request theme-path images asynchronously after the D-Bus update. */
    for (i = 0; i < item->icon_file_count; ) {
        if (now - item->icon_file_times[i] > 60) {
            if (unlink(item->icon_files[i]) != 0 && errno != ENOENT)
                fprintf(stderr, "System::Menu: unable to remove stale indicator icon '%s': %s\n",
                        item->icon_files[i], strerror(errno));
            free(item->icon_files[i]);
            item->icon_file_count--;
            item->icon_files[i] = item->icon_files[item->icon_file_count];
            item->icon_file_times[i] = item->icon_file_times[item->icon_file_count];
        }
        else {
            i++;
        }
    }

    pixbuf = render_text_icon(item->icon_utf8);
    if (pixbuf) {
        item->icon_sequence++;
        g_icon_sequence++;
        icon_name = g_strdup_printf("dd-icon-%lu", g_icon_sequence);
        filename = g_strdup_printf("%s/%s.png", item->icon_theme_dir,
                                    icon_name);
        if (!gdk_pixbuf_save(pixbuf, filename, "png", &error, NULL)) {
            fprintf(stderr, "System::Menu: unable to save indicator icon: %s\n",
                    error ? error->message : "unknown error");
            if (error) g_error_free(error);
            g_free(filename);
            g_free(icon_name);
            g_object_unref(pixbuf);
            exit(2);
        }
        item->icon_files = (char **)xrealloc(item->icon_files,
            sizeof(char *) * (item->icon_file_count + 1));
        item->icon_file_times = (time_t *)xrealloc(item->icon_file_times,
            sizeof(time_t) * (item->icon_file_count + 1));
        item->icon_files[item->icon_file_count] = xstrdup(filename);
        item->icon_file_times[item->icon_file_count] = now;
        item->icon_file_count++;
        app_indicator_set_icon_full(item->indicator, icon_name, item->name_utf8);
        g_free(filename);
        g_free(icon_name);
        g_object_unref(pixbuf);
    }
}

/* ------------------------------ menus ------------------------------------ */

static void on_menu_activate(GtkMenuItem *menu_item, gpointer data)
{
    (void)menu_item;
    emit_click((DDItem *)data);
}

static gboolean on_stay_button_press(GtkWidget *widget, GdkEventButton *event, gpointer data)
{
    DDItem *item = (DDItem *)data;
    (void)widget;
    if (event && event->button == 1) {
        emit_click(item);
        /* Stop GtkMenuShell from turning this into normal menu-item activation.
         * That keeps the current menu/submenu tracking session visible. */
        return TRUE;
    }
    return FALSE;
}

static GtkWidget *build_menu(DDItem *owner)
{
    GtkWidget *menu = gtk_menu_new();
    size_t i;

    for (i = 0; i < owner->child_count; i++) {
        DDItem *item = owner->children[i];
        GtkWidget *mi = gtk_menu_item_new_with_label(item->icon_utf8);
        item->menu_item = mi;

        if (item->child_count > 0) {
            item->menu = build_menu(item);
            gtk_menu_item_set_submenu(GTK_MENU_ITEM(mi), item->menu);
        }
        else if (item->clickable) {
            if (item->click_stay) {
                gtk_widget_add_events(mi, GDK_BUTTON_PRESS_MASK);
                g_signal_connect(mi, "button-press-event",
                    G_CALLBACK(on_stay_button_press), item);
            }
            else {
                g_signal_connect(mi, "activate", G_CALLBACK(on_menu_activate), item);
            }
        }
        else {
            gtk_widget_set_sensitive(mi, FALSE);
        }

        gtk_menu_shell_append(GTK_MENU_SHELL(menu), mi);
        gtk_widget_show(mi);
    }

    return menu;
}

/* Build the root menu; an item without children remains clickable via its menu.
 * Input: root item with its configuration children.
 * Output: GTK menu attached to the root AppIndicator.
 */
static GtkWidget *build_root_menu(DDItem *root)
{
    GtkWidget *menu;
    GtkWidget *menu_item;
    if (root->child_count > 0) return build_menu(root);
    menu = gtk_menu_new();
    menu_item = gtk_menu_item_new_with_label(root->icon_utf8);
    root->menu_item = menu_item;
    if (root->clickable)
        g_signal_connect(menu_item, "activate", G_CALLBACK(on_menu_activate), root);
    else
        gtk_widget_set_sensitive(menu_item, FALSE);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
    gtk_widget_show(menu_item);
    return menu;
}

static void install_roots(JValue *items)
{
    size_t i;
    clear_roots();
    if (!items || items->type != J_ARRAY) return;

    g_roots = (DDItem **)xcalloc(items->u.array.count ? items->u.array.count : 1,
                                 sizeof(DDItem *));

    for (i = 0; i < items->u.array.count; i++) {
        DDItem *root = item_from_json(items->u.array.items[i], NULL);
        char *indicator_id;
        if (!root) continue;

        root->menu = build_root_menu(root);
        indicator_id = g_strdup_printf("developer-dashboard-%lu", ++g_icon_sequence);
        /* The package's public convenience constructors are deprecated;
         * initialize the same documented GObject properties directly. */
        root->indicator = APP_INDICATOR(g_object_new(
            APP_INDICATOR_TYPE,
            "id", indicator_id,
            "icon-name", "applications-system",
            "category", APP_INDICATOR_CATEGORY_APPLICATION_STATUS,
            NULL));
        g_free(indicator_id);
        if (!root->indicator) {
            fprintf(stderr, "System::Menu: unable to create Ubuntu AppIndicator\n");
            item_free(root);
            continue;
        }
        app_indicator_set_menu(root->indicator, GTK_MENU(root->menu));
        update_status_icon(root);
        app_indicator_set_status(root->indicator, APP_INDICATOR_STATUS_ACTIVE);

        g_roots[g_root_count++] = root;
    }
}

static void set_item_icon(DDItem *item, const char *icon)
{
    if (!item || item->removed || !icon) return;
    free(item->icon_utf8);
    item->icon_utf8 = xstrdup(icon);

    if (item->indicator) {
        update_status_icon(item);
    }
    else if (item->menu_item) {
        gtk_menu_item_set_label(GTK_MENU_ITEM(item->menu_item), item->icon_utf8);
    }
}

static void remove_item(DDItem *item)
{
    if (!item || item->removed) return;
    item_mark_removed(item);

    if (item->indicator) {
        app_indicator_set_status(item->indicator, APP_INDICATOR_STATUS_PASSIVE);
    }
    else if (item->menu_item) {
        gtk_widget_destroy(item->menu_item);
        item->menu_item = NULL;
    }
}

/* --------------------------- command processing -------------------------- */

static void handle_command(const char *line)
{
    JValue *cmd = j_parse(line);
    const char *op;

    if (!cmd || cmd->type != J_OBJECT) {
        j_free(cmd);
        return;
    }

    op = j_get_string(cmd, "op");
    if (!op) {
        j_free(cmd);
        return;
    }

    if (strcmp(op, "run") == 0) {
        install_roots(j_get(cmd, "items"));
    }
    else if (strcmp(op, "icon") == 0) {
        const char *name = j_get_string(cmd, "name");
        const char *icon = j_get_string(cmd, "icon");
        if (name && icon) set_item_icon(find_item(name), icon);
    }
    else if (strcmp(op, "remove") == 0) {
        const char *name = j_get_string(cmd, "name");
        if (name) remove_item(find_item(name));
    }
    else if (strcmp(op, "stop") == 0) {
        j_free(cmd);
        clear_roots();
        gtk_main_quit();
        return;
    }

    j_free(cmd);
}

static gboolean on_stdin_ready(GIOChannel *source, GIOCondition condition, gpointer data)
{
    (void)data;
    if (condition & (G_IO_HUP | G_IO_ERR | G_IO_NVAL)) {
        clear_roots();
        gtk_main_quit();
        return FALSE;
    }

    while (condition & G_IO_IN) {
        gchar *line = NULL;
        gsize length = 0;
        GError *error = NULL;
        GIOStatus status = g_io_channel_read_line(source, &line, &length, NULL, &error);

        if (status == G_IO_STATUS_NORMAL && line) {
            while (length > 0 && (line[length - 1] == '\n' || line[length - 1] == '\r'))
                line[--length] = '\0';
            if (length > 0) handle_command(line);
            g_free(line);
            continue;
        }

        if (line) g_free(line);
        if (error) g_error_free(error);
        if (status == G_IO_STATUS_AGAIN) break;
        if (status == G_IO_STATUS_EOF) {
            clear_roots();
            gtk_main_quit();
            return FALSE;
        }
        break;
    }

    return TRUE;
}

int main(int argc, char **argv)
{
    GError *error = NULL;
    GIOFlags flags;

    if (!gtk_init_check(&argc, &argv)) {
        fprintf(stderr,
            "Developer::Dashboard::System::Menu: GTK could not connect to the Ubuntu desktop session. "
            "A graphical session with AppIndicator support is required.\n");
        return 2;
    }

    g_stdin_channel = g_io_channel_unix_new(STDIN_FILENO);
    g_io_channel_set_encoding(g_stdin_channel, NULL, &error);
    if (error) {
        fprintf(stderr, "System::Menu: stdin encoding setup failed: %s\n", error->message);
        g_error_free(error);
        return 2;
    }
    flags = g_io_channel_get_flags(g_stdin_channel);
    g_io_channel_set_flags(g_stdin_channel, flags | G_IO_FLAG_NONBLOCK, NULL);
    g_io_add_watch(g_stdin_channel, G_IO_IN | G_IO_HUP | G_IO_ERR | G_IO_NVAL,
                   on_stdin_ready, NULL);

    gtk_main();

    clear_roots();
    if (g_stdin_channel) g_io_channel_unref(g_stdin_channel);
    return 0;
}
