/*
 * Copyright (c) 2003 by Emmanuele Bassi (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 */

#include "gconfperl.h"

/*
 * GConfValue is a dynamic type container used by GConf, in many ways similar
 * to GValue.  It should be accessed only via methods, so GConf doesn't export
 * it as a registered type.  Hence, I decided to translate it into a Perl data
 * structure completely transparent to the programmer; GConfValues are used
 * only internally: what a programmer will always see or use will be an hashref
 * containing the "type" field, which is used to store the symbolic type of the
 * key which GConfValue is bound to, and the payload, that is the value bound
 * to the key.  Fundamental types will have the "value" field filled with the
 * corresponding perl scalar; lists of fundamental types will have the "value"
 * field filled with an arrayref of scalars; pairs of fundamental types will
 * have two fields, "car" (for the first value of the pair) and "cdr" (for the
 * second value of the pair), each one containing an hashref corresponding to a
 * GConfValue of their fundamental types. This may seems a little obfuscated,
 * but, since we're not providing any accessor methods to gather the data
 * inside GConfValue, I've decided to keep the semantics as much as similar to
 * the corresponding C one. (ebassi)
 * 
 */

/* gconfperl_sv_from_value returns the correct SV for the fundamental types
 * stored inside a GConfValue.  gconfperl_value_from_sv is used the other way
 * around, to fill an already initialized GConfValue from a SV.
 */
static SV *
gconfperl_sv_from_value (GConfValue * v)
{
	SV * sv;
	
	switch (v->type) {
		case GCONF_VALUE_BOOL:
			sv = newSViv (gconf_value_get_bool (v));
                        break;
		case GCONF_VALUE_FLOAT:
			sv = newSVnv (gconf_value_get_float (v));
                        break;
		case GCONF_VALUE_INT:
			sv = newSViv (gconf_value_get_int (v));
                        break;
		case GCONF_VALUE_STRING:
			sv = newSVGChar (gconf_value_get_string (v));
                        break;
		case GCONF_VALUE_SCHEMA:
                        sv = newSVGConfSchema (gconf_value_get_schema (v));
                        break;
		case GCONF_VALUE_INVALID:
		default:
			sv = NULL;
                        break;
	}
	
	return sv;
}

static void
gconfperl_value_from_sv (SV * sv, GConfValue * v)
{
	switch (v->type) {
		case GCONF_VALUE_BOOL:
			gconf_value_set_bool (v, SvIV (sv));
                        break;
		case GCONF_VALUE_FLOAT:
			gconf_value_set_float (v, SvNV (sv));
                        break;
		case GCONF_VALUE_INT:
			gconf_value_set_int (v, SvIV (sv));
                        break;
		case GCONF_VALUE_STRING:
			gconf_value_set_string (v, SvGChar (sv));
                        break;
                case GCONF_VALUE_SCHEMA:
                        gconf_value_set_schema (v, SvGConfSchema (sv));
                        break;
		case GCONF_VALUE_INVALID:
		default:
			break;
	}
}

/*
 * Create a SV from a GConfValue.
 * The hash has this form:
 * 
 * fundamentals = { 'int' | 'bool' | 'float' | 'string' | 'schema' }
 * 
 * iff <type> := <fundamentals>
 * 	{ type => <type>, value => { <scalar> | <arrayref> } }
 * 
 * iff <type> := 'pair'
 * 	{
 * 		type => 'pair',
 * 		car  => { type => <fundamentals>, value => <scalar> },
 * 		cdr  => { type => <fundamentals>, value => <scalar> }
 * 	}
 * 
 * a schema is a fundamental type because we have a type for it, like
 * we do have types for integer, boolean, floating and string values.
 */ 
SV *
newSVGConfValue (GConfValue * v)
{
	HV * h;
	SV * sv;
	HV * stash;
	
	if (! v)
		return newSVsv(&PL_sv_undef);

	h = newHV ();
	sv = newRV_noinc ((SV *) h);	/* safe */
	
	switch (v->type) {
		case GCONF_VALUE_STRING:
		case GCONF_VALUE_INT:
		case GCONF_VALUE_FLOAT:
		case GCONF_VALUE_BOOL:
                case GCONF_VALUE_SCHEMA:
			/* these are fundamental types, so store type and value
			 * directly inside the hashref; for the type, use the
			 * 'stringyfied' version.
			 */
			hv_store (h, "type", 4, gperl_convert_back_enum (GCONF_TYPE_VALUE_TYPE, v->type), 0);
			hv_store (h, "value", 5, gconfperl_sv_from_value (v), 0);
			break;
		case GCONF_VALUE_PAIR:
			/* a pair consists of two fundamental types, stored as
			 * car and cdr (damned LISP lovers).  We do not supply
			 * accessor methods for GConfValue, so we try to
			 * reflect the storage as much as we can; thus, we
			 * create two keys, 'car' and 'cdr', instead of the
			 * usual 'value' one.  The programmer must be warned,
			 * so we leave type as 'pair' (also because car and cdr
			 * may be of two different types, so we need a marker
			 * for this situation).
			 */
			{
			SV * car, * cdr;
			hv_store (h, "type", 4,
				gperl_convert_back_enum (GCONF_TYPE_VALUE_TYPE, v->type), 0);
			
			car = newSVGConfValue (gconf_value_get_car (v));
			cdr = newSVGConfValue (gconf_value_get_cdr (v));
			hv_store (h, "car", 3, newSVsv (car), 0);
			hv_store (h, "cdr", 3, newSVsv (cdr), 0);
			}
			break;
		case GCONF_VALUE_LIST:
			/* lists are handled like arrayrefs; the type is the
			 * list type, in order to mask the special 'list' type
			 * from the programmer.
			 */
			{
			AV * a;
			SV * r;
			GSList * l, * tmp;
			GConfValueType t = gconf_value_get_list_type (v);
			
			a = newAV ();
			r = newRV_noinc ((SV *) a);	/* safe */
			l = gconf_value_get_list (v);
			for (tmp = l; tmp != NULL; tmp = tmp->next)
				av_push (a, gconfperl_sv_from_value ((GConfValue *) tmp->data));
			
			hv_store (h, "type", 4, gperl_convert_back_enum (GCONF_TYPE_VALUE_TYPE, t), 0);
			hv_store (h, "value", 5, newSVsv (r), 0);
			}
			break;
		case GCONF_VALUE_INVALID:
			/* this is used only for error handling */
		default:
			croak ("newSVGConfValue: invalid type found");
                        break;
	}

	stash = gv_stashpv ("Gnome2::GConf::Value", TRUE);
	sv_bless (sv, stash);
	
	return sv;
}

/* Create a GConfValue from a SV. */
GConfValue *
SvGConfValue (SV * data)
{
	HV * h;
	SV ** s;
	GConfValue * v;
	GConfValueType t;
	int n;
		
	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		croak ("SvGConfValue: value must be an hashref");

	h = (HV *) SvRV (data);
	
	/* retrieve the type */
	if (! ((s = hv_fetch (h, "type", 4, 0)) && SvOK (*s)))
		croak ("SvGConfValue: 'type' key is needed");
	
	/* if it is an integer, just assign it... */
	if (looks_like_number (*s))
		t = SvIV (*s);
	
	/* otherwise, try to convert it from the enum */
	if (!gperl_try_convert_enum (GCONF_TYPE_VALUE_TYPE, *s, &n))
		croak ("SvGConfValue: 'type' should be either a GConfValueType or an integer");
	t = (GConfValueType) n;
	
	/* set GConfValue using the right setter method */
	switch (t) {
		case GCONF_VALUE_STRING:
		case GCONF_VALUE_INT:
		case GCONF_VALUE_FLOAT:
		case GCONF_VALUE_BOOL:
                case GCONF_VALUE_SCHEMA:
			if (! ((s = hv_fetch (h, "value", 5, 0)) && SvOK (*s)))
				croak ("SvGConfValue: fundamental types require a value key");
			
			/* the argument is not a reference, so convert it */
			if (!SvROK (*s)) {
				v = gconf_value_new (t);
				gconfperl_value_from_sv (*s, v);
			}
			else if (SvROK (*s) || SvTYPE (SvRV (*s)) == SVt_PVAV) {
				/* the argument is an array, so fill the list */
				AV * av = (AV*) SvRV (*s);
				GSList * list = NULL;
				int i;
				
				v = gconf_value_new (GCONF_VALUE_LIST);
				gconf_value_set_list_type (v, t);
				
				for (i = av_len (av) ; i >= 0 ; i--) {
					GConfValue * v = gconf_value_new (t);
					gconfperl_value_from_sv (*av_fetch (av, i, FALSE), v);
					list = g_slist_prepend (list, v);
				}
				gconf_value_set_list_nocopy (v, list);
			}
			else
				croak ("SvGConfValue: value must be either a "
				       "scalar or an array reference");
			break;
		case GCONF_VALUE_PAIR:
			{
			GConfValue * car, * cdr;
			
			v = gconf_value_new (GCONF_VALUE_PAIR);
			
			/* build up the first value of the pair */	
			if (! ((s = hv_fetch (h, "car", 3, 0)) && SvOK (*s)))
				croak ("SvGConfValue: 'pair' type requires a 'car' key");
			
			car = SvGConfValue (*s);
			gconf_value_set_car_nocopy (v, car);
			
			/* and then the second value */
			if (! ((s = hv_fetch (h, "cdr", 3, 0)) && SvOK (*s)))
				croak ("SvGConfValue: 'pair' type requires a 'cdr' key");
			
			cdr = SvGConfValue (*s);
			gconf_value_set_cdr_nocopy (v, cdr);
			}
			break;	
		case GCONF_VALUE_LIST:
			/* handled above, this should never be passed */
		case GCONF_VALUE_INVALID:
			/* used for error situations */
		default:
			croak ("SvGConfValue: invalid type found.");
	}
	
	return v;
}

MODULE = Gnome2::GConf::Value	PACKAGE = Gnome2::GConf::Value


=for object Gnome2::GConf::Value Opaque datatype for generic values
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  $client = Gnome2::GConf::Client->get_default;
  $client->set($config_key,
      {
        type  => 'string',
	value => 'Hello, World',
      });
  print "The Meaning of Life." if ($client->get($another_key)->{value} == 42);

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

C<GConfValue> is a dynamic type similar to C<GValue>,  and represents a value
that can be obtained from or stored in the configuration database; it contains
the value bound to a key, and its type.

In perl, it's an hashref containing these keys:

=over

=item B<type>

The type of the data.  Fundamental types are 'string', 'int', 'float' and
'bool'.  Lists are handled by passing an arrayref as the payload of the C<value>
key:
	
	$client->set($key, { type => 'string', value => 'some string' });
	$client->set($key, { type => 'float',  value => 0.5           });
	$client->set($key, { type => 'bool',   value => FALSE         });
	$client->set($key, { type => 'int',    value => [0..15]       });
	
Pairs are handled by using the special type 'pair', and passing, in place
of the C<value> key, the C<car> and the C<cdr> keys, each containing an hashref
representing a GConfValue:

	$client->set($key, {
			type => 'pair',
			car  => { type => 'string', value => 'some string' },
			cdr  => { type => 'int',    value => 42            },
		});

This is needed since pairs might have different types; lists, instead, are of
the same type.

=item B<value>

The payload, containing the value of type C<type>.  It is used only for
fundamental types (scalars or lists).

=item B<car>, B<cdr>

Special keys, that must be used only when working with the 'pair' type.

=back

=cut

=for see_also

=head1 SEE ALSO

L<Gnome2::GConf>(3pm), L<Gnome2::GConf::Entry>(3pm), L<Gnome2::GConf::Schema>(3pm),
L<Gnome2::GConf::ChangeSet>(3pm).

=cut

##/* we need to provide a real DESTROY function because GConfValue
## * objects are dynamically allocated
## */

void
DESTROY (value)
        SV * value
    CODE:
        gconf_value_free (SvGConfValue (value));        

#if GCONF_CHECK_VERSION (2, 13, 1)

gint
compare (value_a, value_b)
	GConfValue * value_a
	GConfValue * value_b
    CODE:
    	RETVAL = gconf_value_compare (value_a, value_b);
    OUTPUT:
    	RETVAL

#endif /* GCONF_CHECK_VERSION (2, 13, 1) */
	
gchar_own *
to_string (value)
	GConfValue * value
    CODE:
    	RETVAL = gconf_value_to_string (value);
    OUTPUT:
    	RETVAL
