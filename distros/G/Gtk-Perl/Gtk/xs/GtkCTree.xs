
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

/* This CTree implementation is only suitable for Gtk+ 1.1.1 and later. */

static void ctree_func_handler (GtkCTree *ctree, GtkCTreeNode *node, gpointer data)
{
	AV * perlargs = (AV*)data;
	SV * perlhandler = *av_fetch(perlargs, 1, 0);
	SV * sv_ctree = newSVGtkCTree(ctree);
	SV * sv_node = newSVGtkCTreeNode(node);
	int i;
	dSP;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(sv_ctree));
	XPUSHs(sv_2mortal(sv_node));
	for(i=2;i<av_len(perlargs);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(perlargs,i,0))));
	XPUSHs(sv_2mortal(newSVsv(*av_fetch(perlargs,0,0))));
	PUTBACK;

	perl_call_sv(perlhandler, G_DISCARD);
}

static void
svrefcnt_dec(gpointer data) {
	SvREFCNT_dec((SV*)data);
}

MODULE = Gtk::CTree		PACKAGE = Gtk::CTree		PREFIX = gtk_ctree_

#ifdef GTK_CTREE

Gtk::CTree_Sink
gtk_ctree_new(Class, columns, tree_column=0)
	SV *	Class
	int	columns
	int	tree_column
	CODE:
	RETVAL = (GtkCTree*)(gtk_ctree_new(columns, tree_column));
	OUTPUT:
	RETVAL

 #ARG: $title string (first column title)
 #ARG: ... list (additional column titles)
Gtk::CTree_Sink
gtk_ctree_new_with_titles(Class, tree_column, title, ...)
	SV *	Class
	int	tree_column
	SV *	title
	CODE:
	{
		int columns = items - 2;
		int i;
		char** titles = malloc(columns * sizeof(gchar*));
		for (i=2; i < items; ++i)
			titles[i-2] = SvPV(ST(i),PL_na);
		RETVAL = (GtkCTree*)(gtk_ctree_new_with_titles(columns, tree_column, titles));
		free(titles);
	}
	OUTPUT:
	RETVAL


 #ARG: $title string (first column title)
 #ARG: ... list (additional column titles)
void
gtk_ctree_construct(ctree, tree_column, title, ...)
	Gtk::CTree	ctree
	int		tree_column
	SV *		title
	CODE:
	{
		int columns = items - 2;
		int i;
		char** titles = malloc(columns * sizeof(gchar*));
		for (i=2; i < items; ++i)
			titles[i-2] = SvPV(ST(i),PL_na);
		gtk_ctree_construct(ctree, columns, tree_column, titles);
		free(titles);
	}

void
gtk_ctree_set_indent(ctree, indent)
	Gtk::CTree	ctree
	int		indent

void
gtk_ctree_set_reorderable(ctree, reorderable)
	Gtk::CTree	ctree
	bool		reorderable
	CODE:
#if GTK_HVER < 0x010108
	/* DEPRECATED */
	gtk_ctree_set_reorderable(ctree, reorderable);
#else
	gtk_clist_set_reorderable(GTK_CLIST(ctree), reorderable);
#endif

void
gtk_ctree_set_line_style(ctree, line_style)
	Gtk::CTree		ctree
	Gtk::CTreeLineStyle	line_style

int
tree_indent(ctree)
	Gtk::CTree	ctree
	CODE:
	RETVAL=ctree->tree_indent;
	OUTPUT:
	RETVAL

int
tree_column(ctree)
	Gtk::CTree	ctree
	CODE:
	RETVAL=ctree->tree_column;
	OUTPUT:
	RETVAL

Gtk::CTreeLineStyle
line_style(ctree)
	Gtk::CTree	ctree
	CODE:
	RETVAL=ctree->line_style;
	OUTPUT:
	RETVAL

Gtk::CellType
gtk_ctree_node_get_cell_type (ctree, node, column)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int column


char*
gtk_ctree_node_get_text(ctree, node, column)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int column
	ALIAS:
		Gtk::CTree::node_get_text = 0
		Gtk::CTree::get_text = 1
	CODE:
	{
		gchar* text=NULL;
#if GTK_HVER <= 0x010101
		/* FIXME: DEPRECATED? */
		gtk_ctree_get_text(ctree, node, column, &text);
#else
		gtk_ctree_node_get_text(ctree, node, column, &text);
#endif
		RETVAL = text;
	}
	OUTPUT:
	RETVAL

 #OUTPUT: list
 #RETURNS: the pixmap and the bitmap at the specified column
void
gtk_ctree_node_get_pixmap (ctree, node, column)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int column
	ALIAS:
		Gtk::CTree::node_get_pixmap = 0
		Gtk::CTree::get_pixmap = 1
	PPCODE:
	{
		GdkPixmap * pixmap = NULL;
		GdkBitmap * bitmap = NULL;
		int result;
		result = gtk_ctree_node_get_pixmap(ctree, node, column, &pixmap, (GIMME == G_ARRAY) ?&bitmap: NULL);
		if ( result ) {
			if ( pixmap ) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVGdkPixmap(pixmap)));
			}
			if (bitmap ) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVGdkBitmap(bitmap)));
			}
		}
	}

 #OUTPUT: list
 #RETURNS: ($text, $spacing, $pixmap, $bitmap)
void
gtk_ctree_node_get_pixtext (ctree, node, column)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int column
	ALIAS:
		Gtk::CTree::node_get_pixtext = 0
		Gtk::CTree::get_pixtext = 1
	PPCODE:
	{
		gchar* text = NULL;
		guint8 spacing;
		GdkPixmap * pixmap = NULL;
		GdkBitmap * bitmap = NULL;
		int result;
		/* FIXME: require GIMME == G_ARRAY? */
		result = gtk_ctree_node_get_pixtext(ctree, node, column, &text, &spacing, &pixmap, &bitmap);
		if ( result ) {
			EXTEND(sp, 4);
			if ( text )
				PUSHs(sv_2mortal(newSVpv(text, 0)));
			else
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
			PUSHs(sv_2mortal(newSViv(spacing)));
			if ( pixmap )
				PUSHs(sv_2mortal(newSVGdkPixmap(pixmap)));
			else
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
			if (bitmap )
				PUSHs(sv_2mortal(newSVGdkBitmap(bitmap)));
			else
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
		}
	}


#if GTK_HVER >= 0x010200

Gtk::Style
gtk_ctree_node_get_cell_style (ctree, node, column)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int	column

Gtk::Style
gtk_ctree_node_get_row_style (ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

void
gtk_ctree_node_set_row_style (ctree, node, style)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	Gtk::Style	style

void
gtk_ctree_node_set_cell_style (ctree, node, column, style)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	gint	column
	Gtk::Style	style

gboolean
gtk_ctree_node_get_selectable (ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

void
gtk_ctree_node_set_selectable (ctree, node, selectable)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	gboolean	selectable

void
gtk_ctree_node_set_shift (ctree, node, column, vertical, horizontal)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int	column
	int	vertical
	int	horizontal

Gtk::Visibility
gtk_ctree_node_is_visible (ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

void
gtk_ctree_node_moveto (ctree, node, column, row_align, col_align)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int	column
	double	row_align
	double	col_align

Gtk::CTreeNode
gtk_ctree_node_nth (ctree, row)
	Gtk::CTree	ctree
	int	row

void
gtk_ctree_node_set_foreground (ctree, node, color)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	Gtk::Gdk::Color	color

void
gtk_ctree_node_set_background (ctree, node, color)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	Gtk::Gdk::Color	color

void
gtk_ctree_node_set_pixmap (ctree, node, column, pixmap, mask)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int	column
	Gtk::Gdk::Pixmap_OrNULL	pixmap
	Gtk::Gdk::Bitmap_OrNULL	mask

void
gtk_ctree_node_set_pixtext (ctree, node, column, text, spacing, pixmap, mask)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int	column
	char *	text
	gint	spacing
	Gtk::Gdk::Pixmap_OrNULL	pixmap
	Gtk::Gdk::Bitmap_OrNULL	mask

void
gtk_ctree_set_node_info (ctree, node, text, spacing=5, pixmap_closed=NULL, mask_closed=NULL, pixmap_opened=NULL, mask_opened=NULL, is_leaf=TRUE, expanded=FALSE)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	char *	text
	gint	spacing
	Gtk::Gdk::Pixmap_OrNULL	pixmap_closed
	Gtk::Gdk::Bitmap_OrNULL	mask_closed
	Gtk::Gdk::Pixmap_OrNULL	pixmap_opened
	Gtk::Gdk::Bitmap_OrNULL	mask_opened
	gboolean	is_leaf
	gboolean	expanded

 #OUTPUT: list
 #RETURNS: ($text, $spacing, $openpix, $openbitmap, $closedpix, $closedbitmap, $isleaf, $expanded)
void
gtk_ctree_get_node_info (ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	PPCODE:
	{
		char * text;
		guint8 spacing;
		GdkPixmap *pc = NULL, * po=NULL;
		GdkBitmap *bc=NULL, *bo=NULL;
		gboolean is_leaf, expanded;

		if (gtk_ctree_get_node_info(ctree, node, &text, &spacing, &pc, &bc, &po, &bo, &is_leaf, &expanded)) {
			EXTEND(sp, 8);
			PUSHs(sv_2mortal(newSVpv(text, 0)));
			PUSHs(sv_2mortal(newSViv(spacing)));
			PUSHs(sv_2mortal(newSVGdkPixmap(pc)));
			PUSHs(sv_2mortal(newSVGdkBitmap(bc)));
			PUSHs(sv_2mortal(newSVGdkPixmap(po)));
			PUSHs(sv_2mortal(newSVGdkBitmap(bo)));
			PUSHs(sv_2mortal(newSViv(is_leaf)));
			PUSHs(sv_2mortal(newSViv(expanded)));
		}
	}

void
gtk_ctree_set_expander_style (ctree, expander_style)
	Gtk::CTree	ctree
	Gtk::CTreeExpanderStyle	expander_style

void
gtk_ctree_set_show_stub (ctree, show_stub)
	Gtk::CTree	ctree
	gboolean	show_stub

void
gtk_ctree_set_spacing (ctree, spacing)
	Gtk::CTree	ctree
	gint	spacing

 #ARG: $data reference (a reference to some data)
void
gtk_ctree_node_set_row_data(ctree, node, data)
	Gtk::CTree  ctree
	Gtk::CTreeNode node
	SV *	data
	CODE:
	{
		SV * sv = (SV*)SvRV(data);
		
		/*\ Hearken: we are given a reference, called 'data', which refers to
		 *          some SV, called 'sv'. The RV is ephemeral, and we must
		 *          not form a permanent reference to it. Instead, we
		 *          increment the refcount of the target sv, and store that
		 *          sv's pointer as the row data. When the row data is
		 *          deallocated, the sv's refcount will be decremented.
		\*/

		if (!sv)
			croak("Data must be a reference");
			
		SvREFCNT_inc(sv);
		
		gtk_ctree_node_set_row_data_full(ctree, node, sv, svrefcnt_dec);
	}

 #RETURNS: the reference set with Gtk::CTree:set_row_data
SV*
gtk_ctree_node_get_row_data(ctree, node)
	Gtk::CTree  ctree
	Gtk::CTreeNode node;
	CODE:
	{
		SV * sv = (SV*)gtk_ctree_node_get_row_data(ctree, node);
		RETVAL = sv ? newRV_inc(sv) : newSVsv(&PL_sv_undef);
	}
	OUTPUT:
	RETVAL

#endif

#endif


MODULE = Gtk::CTree		PACKAGE = Gtk::CTreeRow		PREFIX = gtk_ctree_row_

#ifdef GTK_CTREE

int
is_leaf(ctree_row)
	Gtk::CTreeRow	ctree_row
	CODE:
	RETVAL=ctree_row->is_leaf;
	OUTPUT:
	RETVAL

int
expanded(ctree_row)
	Gtk::CTreeRow	ctree_row
	CODE:
	RETVAL=ctree_row->expanded;
	OUTPUT:
	RETVAL

Gtk::CTreeNode
children (ctree_row)
	Gtk::CTreeRow	ctree_row
	CODE:
	RETVAL = ctree_row->children;
	OUTPUT:
	RETVAL

Gtk::CTreeNode
sibling (ctree_row)
	Gtk::CTreeRow	ctree_row
	CODE:
	RETVAL = ctree_row->sibling;
	OUTPUT:
	RETVAL

Gtk::CTreeNode
parent (ctree_row)
	Gtk::CTreeRow	ctree_row
	CODE:
	RETVAL = ctree_row->parent;
	OUTPUT:
	RETVAL

#endif


MODULE = Gtk::CTree		PACKAGE = Gtk::CTree		PREFIX = gtk_ctree_

#ifdef GTK_CTREE

 #ARG: $titles reference (refrence to an array of strings)
Gtk::CTreeNode
gtk_ctree_insert_node(ctree, parent, sibling, titles, spacing=5, pixmap_closed=NULL, mask_closed=NULL, pixmap_opened=NULL, mask_opened=NULL, is_leaf=TRUE, expanded=FALSE)
	Gtk::CTree		ctree
	Gtk::CTreeNode_OrNULL		parent
	Gtk::CTreeNode_OrNULL		sibling
	SV*			titles
	int			spacing
	Gtk::Gdk::Pixmap_OrNULL	pixmap_closed
	Gtk::Gdk::Bitmap_OrNULL	mask_closed
	Gtk::Gdk::Pixmap_OrNULL	pixmap_opened
	Gtk::Gdk::Bitmap_OrNULL	mask_opened
	bool			is_leaf
	bool			expanded
	ALIAS:
		Gtk::CTree::insert_node = 0
		Gtk::CTree::insert = 1
	CODE:
	{
		char** titlesa;
		AV* av;
		SV** temp;
		int i;
		if (!SvROK(titles) || (SvTYPE(SvRV(titles)) != SVt_PVAV))
			croak("titles must be a reference to an array");
		av = (AV*)SvRV(titles);
		titlesa = (char**)malloc(sizeof(char*) * (av_len(av)+2));
		for(i = 0; i <= av_len(av); ++i) {
			temp = av_fetch(av,i,0);
			titlesa[i] = temp?SvPV(*temp,PL_na):"";
		}
		titlesa[i]=0;
#if GTK_HVER <= 0x010101
		/* FIXME: DEPRECATED? */
		RETVAL = gtk_ctree_insert(ctree, parent, sibling, titlesa, spacing, pixmap_closed, mask_closed, pixmap_opened, mask_opened, is_leaf, expanded);
#else
		RETVAL = gtk_ctree_insert_node(ctree, parent, sibling, titlesa, spacing, pixmap_closed, mask_closed, pixmap_opened, mask_opened, is_leaf, expanded);
#endif
		free(titlesa);
	}
	OUTPUT:
	RETVAL


void
gtk_ctree_remove_node(ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	ALIAS:
		Gtk::CTree::remove_node = 0
		Gtk::CTree::remove = 1
	CODE:
#if GTK_HVER <= 0x010101
	/* FIXME: DEPRECATED? */
	gtk_ctree_remove(ctree, node);
#else
	gtk_ctree_remove_node(ctree, node);
#endif
	

void
gtk_ctree_post_recursive(ctree, node, func, ...)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL node
	SV *		func
	CODE:
	{
		AV * args;
		SV * arg;

		args = newAV();
		av_push(args, newRV_inc(SvRV(ST(0))));
		PackCallbackST(args, 2);

		gtk_ctree_post_recursive(ctree, node, ctree_func_handler, args);

		SvREFCNT_dec(args);
	}

void
gtk_ctree_pre_recursive(ctree, node, func, ...)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL node
	SV *		func
	CODE:
	{
		AV * args;
		SV * arg;

		args = newAV();
		av_push(args, newRV_inc(SvRV(ST(0))));
		PackCallbackST(args, 2);

		gtk_ctree_pre_recursive(ctree, node, ctree_func_handler, args);

		SvREFCNT_dec(args);
	}

#if GTK_HVER > 0x010101

# FIXME, or something

bool
gtk_ctree_is_viewable(ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

#endif

Gtk::CTreeNode
gtk_ctree_last(ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

bool
gtk_ctree_find(ctree, node, child)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	Gtk::CTreeNode	child

bool
gtk_ctree_is_ancestor(ctree, node, child)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	Gtk::CTreeNode	child


void
gtk_ctree_move(ctree, node, new_parent, new_sibling)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	Gtk::CTreeNode_OrNULL	new_parent
	Gtk::CTreeNode_OrNULL	new_sibling

void
gtk_ctree_expand(ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

void
gtk_ctree_expand_recursive(ctree, node=NULL)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL	node

void
gtk_ctree_expand_to_depth(ctree, node, depth)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int		depth

void
gtk_ctree_collapse(ctree, node=NULL)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL	node

void
gtk_ctree_collapse_recursive(ctree, node=NULL)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL	node

void
gtk_ctree_collapse_to_depth(ctree, node, depth)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int		depth

void
gtk_ctree_toggle_expansion(ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

void
gtk_ctree_toggle_expansion_recursive(ctree, node=NULL)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL	node

void
gtk_ctree_select(ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

void
gtk_ctree_select_recursive(ctree, node=NULL)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL	node

void
gtk_ctree_unselect(ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node

void
gtk_ctree_unselect_recursive(ctree, node=NULL)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL	node


void
gtk_ctree_node_set_text(ctree, node, column, text)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	int column
	char *text
	ALIAS:
		Gtk::CTree::node_set_text = 0
		Gtk::CTree::set_text = 1
	CODE:
#if GTK_HVER <= 0x010101
	/* FIXME: DEPRECATED? */
	gtk_ctree_set_text(ctree, node, column, text);
#else
	gtk_ctree_node_set_text(ctree, node, column, text);
#endif


void
gtk_ctree_sort_node(ctree, node=0)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL	node
	ALIAS:
		Gtk::CTree::sort_node = 0
		Gtk::CTree::sort = 1
	CODE:
#if GTK_HVER <= 0x010101
	/* FIXME: DEPRECATED? */
	gtk_ctree_sort(ctree, node);
#else
	gtk_ctree_sort_node(ctree, node);
#endif

void
gtk_ctree_sort_recursive(ctree, node=0)
	Gtk::CTree	ctree
	Gtk::CTreeNode_OrNULL	node

gboolean
gtk_ctree_is_hot_spot (ctree, x, y)
	Gtk::CTree	ctree
	int	x
	int	y

 #OUTPUT: list
 #RETURNS: list of Gtk::CTreeNode
void
selection (ctree)
	Gtk::CTree	ctree
	PPCODE:
	{
		GList * selection = GTK_CLIST(ctree)->selection;
		while(selection) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkCTreeNode(GTK_CTREE_NODE(selection->data))));
			selection=selection->next;
		}
	}

int
get_node_position (ctree, node)
	Gtk::CTree	ctree
	Gtk::CTreeNode	node
	CODE:
	RETVAL = g_list_position(GTK_CLIST(ctree)->row_list, (GList*)node);
	OUTPUT:
	RETVAL

 #OUTPUT: list
 #RETURNS: list of Gtk::CTreeRow
void
row_list (ctree)
	Gtk::CTree	ctree
	PPCODE:
	{
		GList * row_list = GTK_CLIST(ctree)->row_list;
		while(row_list) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkCTreeRow(row_list->data)));
			row_list=row_list->next;
		}

	}

#endif

MODULE = Gtk::CTree		PACKAGE = Gtk::CTreeNode		PREFIX = gtk_ctree_node_

#ifdef GTK_CTREE

 #OUTPUT: Gtk::CTreeRow
void
row(ctree_node)
	Gtk::CTreeNode	ctree_node
	PPCODE:
	{
		if (ctree_node) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkCTreeRow(GTK_CTREE_ROW(ctree_node))));
		}
	}

 #OUTPUT: Gtk::CTreeNode
void
next(ctree_node)
	Gtk::CTreeNode	ctree_node
	PPCODE:
	{
		if (ctree_node) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkCTreeNode(GTK_CTREE_NODE_NEXT(ctree_node))));
		}
	}

 #OUTPUT: Gtk::CTreeNode
void
prev(ctree_node)
	Gtk::CTreeNode	ctree_node
	PPCODE:
	{
		if (ctree_node) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkCTreeNode(GTK_CTREE_NODE_PREV(ctree_node))));
		}
	}

#endif
