#include <string.h>
#include <gtk/gtk.h>
#include <webkit2/webkit-web-extension.h>
#include "webextensionif.h"

WebKitDOMDocument *document;

static gboolean on_handle_get_title(
    WebExtensionIf *skeleton,
    GDBusMethodInvocation *invocation,
    guint seconds
) {
    web_extension_if_complete_get_title(
        skeleton,
        invocation,
        webkit_dom_document_get_title(document)
    );
}

static void on_name_acquired(
    GDBusConnection *connection,
    const gchar *name,
    gpointer user_data
) {
    WebExtensionIf *skeleton;

    skeleton = web_extension_if_skeleton_new();
    g_signal_connect(
        skeleton,
        "handle-get-title",
        G_CALLBACK (on_handle_get_title),
        NULL
    );

    g_dbus_interface_skeleton_export(
        G_DBUS_INTERFACE_SKELETON(skeleton),
        connection,
        "/at/atikon/WebExtensionIf",
        NULL
    );
}

static void on_document_loaded(WebKitWebPage *p) {
    document = webkit_web_page_get_dom_document(p);
}

static void on_page_created (
    WebKitWebExtension *ext,
    WebKitWebPage *p
) {
    g_signal_connect(p, "document-loaded", G_CALLBACK(on_document_loaded), NULL);
}

void webkit_web_extension_initialize (WebKitWebExtension *ext) {
    g_signal_connect(
        ext,
        "page-created",
        G_CALLBACK(on_page_created),
        NULL
    );

    g_bus_own_name(
        G_BUS_TYPE_SESSION,
        "at.atikon.WebExtensionIf",
        G_BUS_NAME_OWNER_FLAGS_NONE,
        NULL,
        on_name_acquired,
        NULL,
        NULL,
        NULL
    );
}
