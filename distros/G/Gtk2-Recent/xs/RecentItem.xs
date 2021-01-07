#include "recentfiles-perl.h"

MODULE = Gtk2::Recent::Item	PACKAGE = Gtk2::Recent::Item	PREFIX = egg_recent_item_

EggRecentItem *
egg_recent_item_new (class)
    C_ARGS:
    	/* void */

EggRecentItem *
egg_recent_item_new_from_uri (class, uri)
	const gchar *uri
    C_ARGS:
    	uri

gboolean
egg_recent_item_set_uri (item, uri)
	EggRecentItem * item
	const gchar * uri

gchar *
egg_recent_item_get_uri (item)
	const EggRecentItem * item

gchar *
egg_recent_item_get_uri_utf8 (item)
	const EggRecentItem * item

gchar *
egg_recent_item_get_uri_for_display (item)
	const EggRecentItem * item

gchar *
egg_recent_item_get_short_name (item)
	const EggRecentItem * item

void
egg_recent_item_set_mime_type (item, mime)
	EggRecentItem * item
	const gchar * mime

gchar *
egg_recent_item_get_mime_type (item)
	const EggRecentItem * item

void
egg_recent_item_set_timestamp (item, timestamp)
	EggRecentItem * item
	time_t timestamp

time_t
egg_recent_item_get_timestamp (item)
	const EggRecentItem *item

const gchar *
egg_recent_item_peek_uri (const EggRecentItem *item)

##G_CONST_RETURN GList *  egg_recent_item_get_groups (const EggRecentItem *item);
=for apidoc
=for signature list = $item->get_groups
=cut
void
egg_recent_item_get_groups (item)
	const EggRecentItem *item
    PREINIT:
    	GList *i, *groups;
    PPCODE:
    	groups = (GList *) egg_recent_item_get_groups (item);
	for (i = groups; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGChar (i->data)));

gboolean
egg_recent_item_in_group (item, group)
	const EggRecentItem * item
	const gchar * group

void
egg_recent_item_add_group (item, group)
	EggRecentItem * item
	const gchar * group

void
egg_recent_item_remove_group (item, group)
	EggRecentItem * item
	const gchar * group

void
egg_recent_item_set_private (item, private)
	EggRecentItem * item
	gboolean private

gboolean
egg_recent_item_get_private (item)
	const EggRecentItem * item
