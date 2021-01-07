#include "recentfiles-perl.h"

#ifdef EGG_TYPE_RECENT_MODEL_SORT
/* register this enum ourselves, since egg-recent doesn't do that for us. */
static const GEnumValue _egg_recent_perl_model_sort_values[] = {
	{ EGG_RECENT_MODEL_SORT_MRU, "EGG_RECENT_MODEL_SORT_MRU", "mru" },
	{ EGG_RECENT_MODEL_SORT_LRU, "EGG_RECENT_MODEL_SORT_LRU", "lru" },
	{ EGG_RECENT_MODEL_SORT_NONE, "EGG_RECENT_MODEL_SORT_NONE", "none" },
	{ 0, NULL, NULL}
};

GType
egg_recent_perl_model_sort_get_type (void)
{
	static GType t = 0;
	if (! t) {
		t = g_enum_register_static ("EggRecentModelSort",
				_egg_recent_perl_model_sort_values);
	}
	return t;
}
#endif
		

MODULE = Gtk2::Recent::Model	PACKAGE = Gtk2::Recent::Model	PREFIX = egg_recent_model_

#ifdef EGG_TYPE_RECENT_MODEL_SORT
=for enum EggRecentModelSort
=cut
#endif

=for apidoc
Creates a new model, linked to the recent files list. $sort states the
algorithm used to order the list: most recently used, least recently used or no
order.
=cut
EggRecentModel_noinc *
egg_recent_model_new (class, sort)
	EggRecentModelSort sort
    C_ARGS:
	sort

=for apidoc
=for signature $model->set_filter_mime_types ($mime_type)
=for arg ... (__hide__)
Filter the list using $mime_type. This will not affect the list of recently
used files, it will only alter the result of the get_list method.
=cut
void
egg_recent_model_set_filter_mime_types (model, ...)
	EggRecentModel * model
    PREINIT:
    	int i;
	GSList *mime_filter = NULL;
	GValue *value = NULL;
    CODE:
    	/* This is an ugly hack. Since there's only a variable argument
	 * function that sets filters, and it resets the filter list internally
	 * at each call, we need to create an array of strings and pass it
	 * directly to the corresponding property. I know: this is libegg.
	 */
    	for (i = 1; i < items; i++) {
		gchar *mime_type = SvGChar (ST (i));
		mime_filter = g_slist_prepend (mime_filter,
				g_pattern_spec_new (mime_type));
	}
	value = g_new0 (GValue, 1);
	value = g_value_init (value, G_TYPE_POINTER);
	g_value_set_pointer (value, (gpointer) mime_filter);
	g_object_set_property (G_OBJECT (model), "mime-filters", value);

=for apidoc
=for signature $model->set_filter_group ($group)
=for arg ... (__hide__)
Filter the list using $group. This will not affect the list of recently
used files, it will only alter the result of the get_list method.
=cut
void
egg_recent_model_set_filter_groups (model, ...)
	EggRecentModel * model
    PREINIT:
    	int i;
	GSList *group_filter = NULL;
	GValue *value = NULL;
    CODE:
    	for (i = 1; i < items; i++) {
		gchar *group = SvGChar (ST (i));
		group_filter = g_slist_prepend (group_filter, g_strdup (group));
	}
	value = g_new0 (GValue, 1);
	value = g_value_init (value, G_TYPE_POINTER);
	g_value_set_pointer (value, (gpointer) group_filter);
	g_object_set_property (G_OBJECT (model), "group-filters", value);

=for apidoc
=for signature $model->set_filter_uri_schemes ($uri_scheme)
=for arg ... (__hide__)
Filter the list using $uri_scheme. This will not affect the list of recently
used files, it will only alter the result of the get_list method.
=cut
void
egg_recent_model_set_filter_uri_schemes (model, ...)
	EggRecentModel * model
    PREINIT:
    	int i;
	GSList *scheme_filter = NULL;
	GValue *value = NULL;
    CODE:
    	for (i = 1; i < items; i++) {
		gchar *uri_scheme = SvGChar (ST (i));
		scheme_filter = g_slist_prepend (scheme_filter,
				g_pattern_spec_new (uri_scheme));
	}
	value = g_new0 (GValue, 1);
	value = g_value_init (value, G_TYPE_POINTER);
	g_value_set_pointer (value, (gpointer) scheme_filter);
	g_object_set_property (G_OBJECT (model), "scheme-filters", value);

=for apidoc
Set the sorting algorithm for the list order.
=cut
void
egg_recent_model_set_sort (model, sort)
	EggRecentModel * model
	EggRecentModelSort sort

=for apidoc
Add $item to the list of recently used files. Return TRUE on success.
=cut
gboolean
egg_recent_model_add_full (model, item)
	EggRecentModel * model
	EggRecentItem * item

=for apidoc
Add a $uri to the list of recently used files. Return TRUE on success.
=cut
gboolean
egg_recent_model_add (model, uri)
	EggRecentModel * model
	const gchar * uri

=for apidoc
Remove $uri from the list of recently used files. Return TRUE on success.
=cut
gboolean
egg_recent_model_delete (model, uri)
	EggRecentModel * model
	const gchar * uri

=for apidoc
Clear the list of recently used files.
=cut
void
egg_recent_model_clear (model)
	EggRecentModel * model

##GList * egg_recent_model_get_list  (EggRecentModel *model);
=for apidoc
=for signature list = $model->get_list
Return the list of recently used files, in form of Gtk2::Recent::Item objects.
=cut
void
egg_recent_model_get_list (model)
	EggRecentModel * model
    PREINIT:
    	GList *res = NULL, *iter;
    PPCODE:
    	res = egg_recent_model_get_list (model);
	for (iter = res; iter; iter = iter->next) {
		EggRecentItem *item = (EggRecentItem *) iter->data;
		XPUSHs (sv_2mortal (newSVEggRecentItem (item)));
	}

##void egg_recent_model_changed      (EggRecentModel *model);
=for apidoc
Emit the "changed" signal of the model.
=cut
void
egg_recent_model_changed (model)
	EggRecentModel * model

##void egg_recent_model_set_limit    (EggRecentModel *model, int limit);

=for apidoc
Set the limit to the size of the list. This will not affect the real list, only
the list returned by the get_list method.
=cut
void
egg_recent_model_set_limit (model, limit)
	EggRecentModel * model
	int limit

##int  egg_recent_model_get_limit    (EggRecentModel *model);
=for apidoc
Get the limit to the size of the list.
=cut
int
egg_recent_model_get_limit (model)
	EggRecentModel * model

##void egg_recent_model_remove_expired (EggRecentModel *model);
=for apidoc
Removes the expired items from the list.
=cut
void
egg_recent_model_remove_expired (model)
	EggRecentModel * model
