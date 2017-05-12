/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"
#include "gtk2perl-private.h" /* For the translate callback. */

/*
struct GtkStockItem {

  gchar *stock_id;
  gchar *label;
  GdkModifierType modifier;
  guint keyval;
  gchar *translation_domain;
};
*/

static SV *
newSVGtkStockItem (GtkStockItem * item)
{
	HV * hv = newHV();
	gperl_hv_take_sv_s (hv, "stock_id", newSVGChar (item->stock_id));
	gperl_hv_take_sv_s (hv, "label", newSVGChar (item->label));
	gperl_hv_take_sv_s (hv, "modifier", newSVGdkModifierType (item->modifier));
	gperl_hv_take_sv_s (hv, "keyval", newSVuv (item->keyval));
	if (item->translation_domain)
		gperl_hv_take_sv_s (hv, "translation_domain", newSVGChar (item->translation_domain));
	return newRV_noinc ((SV *) hv);
}

/*
 * returns a pointer to a temp stock item you can use until control returns
 * to perl.
 */
static GtkStockItem *
SvGtkStockItem (SV * sv)
{
	HV * hv;
	SV ** svp;
	GtkStockItem * item;

	if (!gperl_sv_is_hash_ref (sv))
		croak ("malformed stock item; use a reference to a hash as a stock item");

	hv = (HV*) SvRV (sv);

	item = gperl_alloc_temp (sizeof (GtkStockItem));

	svp = hv_fetch (hv, "stock_id", 8, FALSE);
	if (svp) item->stock_id = SvGChar (*svp);

	svp = hv_fetch (hv, "label", 5, FALSE);
	if (svp) item->label = SvGChar (*svp);

	svp = hv_fetch (hv, "modifier", 8, FALSE);
	if (svp) item->modifier = SvGdkModifierType (*svp);

	svp = hv_fetch (hv, "keyval", 6, FALSE);
	if (svp) item->keyval = SvUV (*svp);

	svp = hv_fetch (hv, "translation_domain", 18, FALSE);
	if (svp) item->translation_domain = SvGChar (*svp);

	return item;
}

MODULE = Gtk2::Stock	PACKAGE = Gtk2::Stock	PREFIX = gtk_stock_

=head1 Gtk2::StockItem

When a Gtk2::StockItem is returned from a function or required as a parameter a
hash reference with the following key/value pairs will be required/returned.

  {
      stock_id => (string),
      label => (string),
      modifier => (Gtk2::Gdk::ModifierType),
      keyval => (integer),
      translation_domain => (string),
  }

=cut

=for include build/stock_items.podi
=cut

###  void gtk_stock_add (const GtkStockItem *items, guint n_items)
=for apidoc
=for arg ... of Gtk2::StockItem's to be added
=cut
void
gtk_stock_add (class, ...)
    PREINIT:
	int i;
    CODE:
	for (i = 1 ; i < items ; i++)
		gtk_stock_add (SvGtkStockItem (ST (i)), 1);

## you don't really ever get static memory from perl, so this is irrelevant.
###  void gtk_stock_add_static (const GtkStockItem *items, guint n_items)

##  gboolean gtk_stock_lookup (const gchar *stock_id, GtkStockItem *item)
=for apidoc
Returns a hash reference, a L<Gtk2::StockItem>.
=cut
SV *
gtk_stock_lookup (class, stock_id)
	const gchar *stock_id
    PREINIT:
	GtkStockItem item;
    CODE:
	if (! gtk_stock_lookup (stock_id, &item))
		XSRETURN_UNDEF;
	RETVAL = newSVGtkStockItem (&item);
    OUTPUT:
	RETVAL

##  GSList* gtk_stock_list_ids (void)
=for apidoc
Returns a list of strings, the stock-ids.
=cut
void
gtk_stock_list_ids (class)
    PREINIT:
	GSList * ids, * i;
    PPCODE:
	ids = gtk_stock_list_ids ();
	for (i = ids ; i != NULL ; i = i->next) {
		XPUSHs (sv_2mortal (newSVpv ((char*)(i->data), 0)));
		g_free (i->data);
	}
	g_slist_free (ids);
	PERL_UNUSED_VAR (ax);

#if GTK_CHECK_VERSION (2, 8, 0)

void
gtk_stock_set_translate_func (class, domain, func, data=NULL)
	const gchar *domain
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_translate_func_create (func, data);
	gtk_stock_set_translate_func (domain,
	                              gtk2perl_translate_func,
	                              callback,
	                              (GtkDestroyNotify)
	                                gperl_callback_destroy);

#endif

## Boxed type support
###  GtkStockItem *gtk_stock_item_copy (const GtkStockItem *item)
###  void gtk_stock_item_free (GtkStockItem *item)

