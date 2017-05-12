
MODULE = MIME::Fast		PACKAGE = MIME::Fast::MultiPart		PREFIX=g_mime_multipart_

 #
 ## CONSTRUCTION/DESCTRUCTION
 #

MIME::Fast::MultiPart
g_mime_multipart_new(Class = "MIME::Fast::MultiPart", subtype = "mixed")
        char *		Class;
        const char *		subtype;
    PROTOTYPE: $;$$
    CODE:
        RETVAL = g_mime_multipart_new_with_subtype(subtype);
        plist = g_list_prepend(plist, RETVAL);
        if (gmime_debug)
          warn("function g_mime_multipart_new (also in plist): 0x%x", RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(mime_multipart)
        MIME::Fast::MultiPart	mime_multipart
    CODE:
        if (gmime_debug)
          warn("g_mime_multipart_DESTROY: 0x%x %s", mime_multipart,
          g_list_find(plist,mime_multipart) ? "(true destroy)" : "(only attempt)");
        if (g_list_find(plist,mime_multipart)) {
          g_mime_object_unref(GMIME_OBJECT (mime_multipart));
          // g_mime_part_destroy(mime_multipart);
          plist = g_list_remove(plist, mime_multipart);
        }

void
interface_p_set(mime_multipart, value)
	MIME::Fast::MultiPart	mime_multipart
	const char *	        value
    INTERFACE_MACRO:
	XSINTERFACE_FUNC
	XSINTERFACE_FUNC_MIMEFAST_MULTIPART_SET
    INTERFACE:
	set_boundary
	set_preface
	set_postface

const char *
interface_p_get(mime_multipart)
	MIME::Fast::MultiPart	mime_multipart
    INTERFACE_MACRO:
	XSINTERFACE_FUNC
	XSINTERFACE_FUNC_MIMEFAST_MULTIPART_SET
    INTERFACE:
	get_boundary
	get_preface
	get_postface

 #
 # remove_part
 # remove_part_at
 #
void
g_mime_multipart_remove_part(mime_multipart, subpart = 0)
        MIME::Fast::MultiPart	mime_multipart
        SV *			subpart
    PREINIT:
        GMimeObject		*mime_object = NULL;
	int			index;
    CODE:
	if (sv_isobject(subpart) && SvROK(subpart)) {
	  IV tmp = SvIV((SV*)SvRV(subpart));
	  mime_object = INT2PTR(MIME__Fast__Object, tmp);
          if (gmime_debug)
            warn("g_mime_part_remove_subpart: 0x%x, child=0x%x (not add to plist)", mime_multipart, mime_object);
          g_mime_multipart_remove_part(mime_multipart, mime_object);
	} else if (SvIOK(subpart)) {
	  index = SvIV(subpart);
          if (gmime_debug)
            warn("g_mime_part_remove_subpart_at: 0x%x, index=%d", mime_multipart, index);
	  g_mime_multipart_remove_part_at(mime_multipart, index);
	}
        
  # return mime part for the given numer(s)
SV *
g_mime_multipart_get_part(mime_multipart, ...)
        MIME::Fast::MultiPart	mime_multipart
    PREINIT:
        int		i;
        IV		partnum = -1;
	GMimeMultipart  *part;
	GMimeObject     *mime_object;
        GMimeMessage	*message;
    CODE:
	if (!GMIME_IS_MULTIPART(mime_multipart))
	{
          warn("Submitted argument is not of type MIME::Fast::MultiPart");
	  XSRETURN_UNDEF;
	}

	RETVAL = &PL_sv_undef;
	part = mime_multipart;

	for (i=items - 1; part && i>0; --i) {
          
	  partnum = SvIV(ST(items - i));
	  if (partnum >= g_mime_multipart_get_number(part)) {
	    warn("MIME::Fast::MultiPart::get_part: part no. %d (index %d) is greater than no. of subparts (%d)",
			    partnum, items - i, g_mime_multipart_get_number(part));
	    if (part != mime_multipart)
	      g_mime_object_unref(GMIME_OBJECT(part));
	    XSRETURN_UNDEF;
	  }
	  mime_object = g_mime_multipart_get_part(part, partnum);

	  if (part != mime_multipart)
	    g_mime_object_unref(GMIME_OBJECT(part));

	  if (i != 1) { // more parts necessary 
	    
	    if (GMIME_IS_MESSAGE_PART(mime_object))	// message/rfc822 - returns message
	    {
	      message = g_mime_message_part_get_message ((MIME__Fast__MessagePart)mime_object);
	      g_mime_object_unref(GMIME_OBJECT(mime_object));
   
	      mime_object = GMIME_OBJECT(message->mime_part);
	      g_mime_object_ref(mime_object);
	      g_mime_object_unref(GMIME_OBJECT(message));
	    }
 
	    if (GMIME_IS_MULTIPART(mime_object))
	    {
	      part = GMIME_MULTIPART(mime_object);
	    }
	    else
	    {
	      warn("MIME::Fast::MultiPart::get_part: found part no. %d (index %d) that is not a Multipart MIME object", partnum, items - i);
	      g_mime_object_unref(mime_object);
	      XSRETURN_UNDEF;
	    }

	  }
	  else		// the last part we are looking for
	  {
	    if (GMIME_IS_OBJECT(mime_object)) {
	      RETVAL = newSViv(0);
	      if (GMIME_IS_MESSAGE_PARTIAL(mime_object))
	        sv_setref_pv(RETVAL, "MIME::Fast::MessagePartial", (MIME__Fast__MessagePartial)mime_object);
#if GMIME_CHECK_VERSION_UNSUPPORTED
	      else if (GMIME_IS_MESSAGE_MDN(mime_object))
	        sv_setref_pv(RETVAL, "MIME::Fast::MessageMDN", (MIME__Fast__MessageMDN)mime_object);
	      else if (GMIME_IS_MESSAGE_DELIVERY(mime_object))
	        sv_setref_pv(RETVAL, "MIME::Fast::MessageDelivery", (MIME__Fast__MessageDelivery)mime_object);
#endif
	      else if (GMIME_IS_MESSAGE_PART(mime_object))
	        sv_setref_pv(RETVAL, "MIME::Fast::MessagePart", (MIME__Fast__MessagePart)mime_object);
	      else if (GMIME_IS_MULTIPART(mime_object))
	        sv_setref_pv(RETVAL, "MIME::Fast::MultiPart", (MIME__Fast__MultiPart)mime_object);
	      else if (GMIME_IS_PART(mime_object))
	        sv_setref_pv(RETVAL, "MIME::Fast::Part", (MIME__Fast__Part)mime_object);
	      else
	        sv_setref_pv(RETVAL, "MIME::Fast::Object", mime_object);
              plist = g_list_prepend(plist, mime_object);
	    }
	    else
	    {
	      die("MIME::Fast::MultiPart::get_part: found unknown type of part no. %d (index %d)", partnum, items - i);
	    }
	    break;
	  }
 
	} // end of for

    OUTPUT:
        RETVAL

 #
 # subpart
 #
SV *
g_mime_multipart_get_subpart_from_content_id(mime_multipart, content_id)
        MIME::Fast::MultiPart	mime_multipart
        const char *	content_id
    PREINIT:
        GMimeObject     *mime_object = NULL;
    CODE:
        mime_object = g_mime_multipart_get_subpart_from_content_id(mime_multipart, content_id);
	RETVAL = newSViv(0);
	if (mime_object == NULL)
	  XSRETURN_UNDEF;
	else if (GMIME_IS_MULTIPART(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::MultiPart", (GMimeMultipart *)mime_object);
	else if (GMIME_IS_MESSAGE(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::Message", (GMimeMessage *)mime_object);
	else if (GMIME_IS_MESSAGE_PARTIAL(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::MessagePartial", (GMimeMessagePartial *)mime_object);
#if GMIME_CHECK_VERSION_UNSUPPORTED
	else if (GMIME_IS_MESSAGE_MDN(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::MessageMDN", (GMimeMessageMDN *)mime_object);
	else if (GMIME_IS_MESSAGE_DELIVERY(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::MessageDelivery", (GMimeMessageDelivery *)mime_object);
#endif
	else if (GMIME_IS_MESSAGE_PART(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::MessagePart", (GMimeMessagePart *)mime_object);
	else if (GMIME_IS_PART(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::Part", (void*)mime_object);
	else
	  die("g_mime_multipart_get_subpart_from_content_id: unknown type of object: 0x%x", mime_object);
	g_mime_object_ref( mime_object );
        plist = g_list_prepend(plist, RETVAL);
        if (gmime_debug)
          warn("function g_mime_multipart_get_subpart_from_content_id (also in plist): 0x%x", RETVAL);
    OUTPUT:
        RETVAL

 #
 # add_part
 # add_part_at
 #
void
g_mime_multipart_add_part(mime_multipart, subpart, index = 0)
    CASE: items == 2
        MIME::Fast::MultiPart	mime_multipart
        SV *			subpart
    PREINIT:
	GMimeObject		*mime_object;
    CODE:
	if (sv_isobject(subpart) && SvROK(subpart)) {
	  IV tmp = SvIV((SV*)SvRV(subpart));
	  mime_object = INT2PTR(MIME__Fast__Object, tmp);
          g_mime_multipart_add_part(mime_multipart, mime_object);
          plist = g_list_remove(plist, subpart);
	}
    CASE: items == 3
        MIME::Fast::MultiPart	mime_multipart
        SV *			subpart
	int			index
    PREINIT:
	GMimeObject		*mime_object;
    CODE:
	if (sv_isobject(subpart) && SvROK(subpart)) {
	  IV tmp = SvIV((SV*)SvRV(subpart));
	  mime_object = INT2PTR(MIME__Fast__Object, tmp);
          g_mime_multipart_add_part_at(mime_multipart, mime_object, index);
          plist = g_list_remove(plist, subpart);
	}

 #
 # get_number (number of parts)
 #
int
g_mime_multipart_get_number(mime_multipart)
        MIME::Fast::MultiPart		mime_multipart

 #
 # callback function
 #
void
g_mime_multipart_foreach(mime_multipart, callback, svdata)
        MIME::Fast::MultiPart		mime_multipart
        SV *			callback
        SV *			svdata
    PREINIT:
	struct _user_data_sv    *data;
    CODE:
	data = g_new0 (struct _user_data_sv, 1);
	data->svuser_data = newSVsv(svdata);
	data->svfunc = newSVsv(callback);
        g_mime_multipart_foreach(mime_multipart, call_sub_foreach, data);
	g_free (data);

 #
 # children
 # ALIAS: parts
 #
void
children(mime_multipart, ...)
        MIME::Fast::MultiPart	mime_multipart
    ALIAS:
        MIME::Fast::MultiPart::parts = 1
    PREINIT:
        GList *		child;
        IV		partnum = -1;
        I32		gimme = GIMME_V;
        gint		count = 0;
    PPCODE:
        if (items == 2) {
          partnum = SvIV(ST(1));
        }
        if (GMIME_IS_MULTIPART (mime_multipart)) {
          for (child = GMIME_MULTIPART (mime_multipart)->subparts; child && child->data; child = child->next, ++count) {
            SV * part;
	    if (gmime_debug)
	    warn(" ** children 0x%x\n", child->data);
            if (items == 1 && gimme == G_SCALAR)
              continue;

            # avoid unnecessary SV creation
            if (items == 2 && partnum != count)
              continue;

            # push part
            part = sv_newmortal();
            if (GMIME_IS_MULTIPART(child->data))
	    {
	      if (gmime_debug)
	      warn(" ** children add: %s 0x%x\n", "MIME::Fast::MultiPart", child->data);
	      sv_setref_pv(part, "MIME::Fast::MultiPart", (MIME__Fast__MultiPart)(child->data));
	    } else if (GMIME_IS_MESSAGE_PARTIAL(child->data))
	    {
	      if (gmime_debug)
	      warn(" ** children add: %s 0x%x\n", "MIME::Fast::MessagePartial", child->data);
              sv_setref_pv(part, "MIME::Fast::MessagePartial", (MIME__Fast__MessagePartial)(child->data));
#if GMIME_CHECK_VERSION_UNSUPPORTED
	    } else if (GMIME_IS_MESSAGE_MDN(child->data))
	    {
	      if (gmime_debug)
	      warn(" ** children add: %s 0x%x\n", "MIME::Fast::MessageMDN", child->data);
              sv_setref_pv(part, "MIME::Fast::MessageMDN", (MIME__Fast__MessageMDN)(child->data));
	    } else if (GMIME_IS_MESSAGE_DELIVERY(child->data))
	    {
	      if (gmime_debug)
	      warn(" ** children add: %s 0x%x\n", "MIME::Fast::MessageDelivery", child->data);
              sv_setref_pv(part, "MIME::Fast::MessageDelivery", (MIME__Fast__MessageDelivery)(child->data));
#endif
	    } else if (GMIME_IS_PART(child->data))
	    {
	      if (gmime_debug)
	      warn(" ** children add: %s 0x%x\n", "MIME::Fast::Part", child->data);
              sv_setref_pv(part, "MIME::Fast::Part", (MIME__Fast__Part)(child->data));
	    } else if (GMIME_IS_MESSAGE_PART(child->data))
	    {
	      if (gmime_debug)
	      warn(" ** children add: %s 0x%x\n", "MIME::Fast::MessagePart", child->data);
              sv_setref_pv(part, "MIME::Fast::MessagePart", (MIME__Fast__MessagePart)(child->data));
	    } else if (GMIME_IS_OBJECT(child->data))
	      die("g_mime_multipart children: unknown type of object: 0x%x '%s'",
	        child->data, g_mime_content_type_to_string(g_mime_object_get_content_type(child->data)));
	    else
	      die("g_mime_multipart children: unknown reference (not GMIME object): 0x%x '%5s'",
			       child->data, child->data);

            if (gmime_debug)
              warn("function g_mime_part subparts setref (not in plist): 0x%x", child->data);

            if (items == 1) {
              XPUSHs(part);
            } else if (partnum == count) {
              XPUSHs(part);
              break;
            }
          }
          if (gimme == G_SCALAR && partnum == -1)
            XPUSHs(sv_2mortal(newSViv(count)));
        }


