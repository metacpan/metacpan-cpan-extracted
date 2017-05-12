
MODULE = MIME::Fast		PACKAGE = MIME::Fast::MessagePartial	PREFIX=g_mime_message_partial_

 # new(id, number, total)
MIME::Fast::MessagePartial
g_mime_message_part_new(Class, id, number, total)
        char *			Class
        char *			id
	int			number
	int			total
    CODE:
    	RETVAL = g_mime_message_partial_new(id, number, total);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

# destroy(partial)
void
DESTROY(partial)
        MIME::Fast::MessagePartial	partial
    CODE:
        if (gmime_debug)
          warn("g_mime_message_partial_DESTROY: 0x%x %s", partial,
          g_list_find(plist,partial) ? "(true destroy)" : "(only attempt)");
        if (g_list_find(plist,partial)) {
          g_mime_object_unref (GMIME_OBJECT (partial));
          plist = g_list_remove(plist, partial);
	}

const char *
g_mime_message_partial_get_id(partial)
	MIME::Fast::MessagePartial	partial

int
g_mime_message_partial_get_number(partial)
	MIME::Fast::MessagePartial	partial

int
g_mime_message_partial_get_total(partial)
	MIME::Fast::MessagePartial	partial

MIME::Fast::Message
g_mime_message_partial_reconstruct_message(svmixed)
	SV *			svmixed
    PREINIT:
	SV *			svvalue;
	svtype			svvaltype;
	GMimeMessagePartial	**msg_list, *partial;
	GMimeMessage		*message;
	GPtrArray		*parts;
    CODE:
	svvalue = svmixed;
	if (SvROK(svmixed)) {
	  svvalue = SvRV(svmixed);
	}
	svvaltype = SvTYPE(svvalue);
	
	parts = g_ptr_array_new ();
	if (svvaltype == SVt_PVAV) {
	  AV *		avvalue;
	  I32		i, avlen;
	  SV *		svtmp;
	  IV 		tmp;

	  /* set header */
	  avvalue = (AV *)svvalue;
	  avlen = av_len(avvalue); // highest index in the array
          if (avlen == -1) {
        	croak("Usage: MIME::Fast::MessagePartial::reconstruct_message([partial,[partial]+])");
		XSRETURN_UNDEF;
	  }
	  for (i=0; i<=avlen; ++i) {
	    svtmp = (SV *)(*(av_fetch(avvalue, i, 0)));
	    tmp = SvIV((SV*)SvRV(svtmp));
	    if (tmp) {
	      if (GMIME_IS_MESSAGE (tmp) && GMIME_IS_MESSAGE_PARTIAL (GMIME_MESSAGE(tmp)->mime_part)) {
	        partial = INT2PTR(MIME__Fast__MessagePartial, GMIME_MESSAGE(tmp)->mime_part);
	      } else if (GMIME_IS_MESSAGE_PARTIAL(tmp)) {
	        partial = INT2PTR(MIME__Fast__MessagePartial, tmp);
	      } else {
		warn("MIME::Fast::Message::reconstruct_message: Unknown type of object 0x%x", tmp);
		continue;
	      }
	      g_ptr_array_add (parts, partial);
	    }
	  }
	}

	msg_list = (GMimeMessagePartial **) parts->pdata;
	message = g_mime_message_partial_reconstruct_message(msg_list, parts->len);
	RETVAL = message;
	if (gmime_debug)
          warn("MIME::Fast::Message::reconstruct_message: 0x%x\n", RETVAL);
	plist = g_list_prepend(plist, message);
	g_ptr_array_free (parts, FALSE);
    OUTPUT:
	RETVAL

AV *
g_mime_message_partial_split_message(message, max_size)
	MIME::Fast::Message	message
	size_t			max_size
    PREINIT:
	size_t			nparts = 0;
	int			i = 0;
        AV * 			retav;
	GMimeMessage		**msg_list = NULL;
	SV *			svmsg;
    CODE:
	retav = newAV();
	msg_list = g_mime_message_partial_split_message(message, max_size, &nparts);
	if (nparts < 1)
	  XSRETURN_UNDEF;
	// for nparts == 1 msg_list[0] is equal to message, then double destruction is necessary
	for (i = 0; i < nparts; ++i) {
		svmsg = newSViv(0);
		sv_setref_pv(svmsg, "MIME::Fast::Message", (void *)msg_list[i]);
		av_push(retav, svmsg);
        	plist = g_list_prepend(plist, msg_list[i]);
	}
	g_free(msg_list);
	RETVAL = retav;
    OUTPUT:
	RETVAL


