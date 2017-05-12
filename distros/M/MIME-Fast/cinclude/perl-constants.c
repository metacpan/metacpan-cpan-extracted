
static int
constant(char *name, int len, int arg)
{
    errno = 0;
    switch (*name) {
    case 'G':
      if (strnEQ(name, "GMIME_", 6)) {
        switch (*(name+6)) {
        case 'B':
	  /* gmime-filter-best.h */
          if (strEQ(name, "GMIME_BEST_ENCODING_7BIT"))
            return GMIME_BEST_ENCODING_7BIT;
          else if (strEQ(name, "GMIME_BEST_ENCODING_8BIT"))
            return GMIME_BEST_ENCODING_8BIT;
          else if (strEQ(name, "GMIME_BEST_ENCODING_BINARY"))
            return GMIME_BEST_ENCODING_BINARY;
	  break;
        case 'C':
	  /* gmime-cipher-context.h */
          if (strEQ(name, "GMIME_CIPHER_HASH_DEFAULT"))
            return GMIME_CIPHER_HASH_DEFAULT;
          else if (strEQ(name, "GMIME_CIPHER_HASH_MD2"))
            return GMIME_CIPHER_HASH_MD2;
          else if (strEQ(name, "GMIME_CIPHER_HASH_MD5"))
            return GMIME_CIPHER_HASH_MD5;
          else if (strEQ(name, "GMIME_CIPHER_HASH_SHA1"))
            return GMIME_CIPHER_HASH_SHA1;
          else if (strEQ(name, "GMIME_CIPHER_HASH_RIPEMD160"))
            return GMIME_CIPHER_HASH_RIPEMD160;
          else if (strEQ(name, "GMIME_CIPHER_HASH_TIGER192"))
            return GMIME_CIPHER_HASH_TIGER192;
          else if (strEQ(name, "GMIME_CIPHER_HASH_HAVAL5160"))
            return GMIME_CIPHER_HASH_HAVAL5160;
	  break;
        case 'E':
	  /* gmime-error.h */
          if (strEQ(name, "GMIME_ERROR_GENERAL"))
            return GMIME_ERROR_GENERAL;
          else if (strEQ(name, "GMIME_ERROR_NOT_SUPPORTED"))
            return GMIME_ERROR_NOT_SUPPORTED;
          else if (strEQ(name, "GMIME_ERROR_PARSE_ERROR"))
            return GMIME_ERROR_PARSE_ERROR;
          else if (strEQ(name, "GMIME_ERROR_PROTOCOL_ERROR"))
            return GMIME_ERROR_PROTOCOL_ERROR;
          else if (strEQ(name, "GMIME_ERROR_BAD_PASSWORD"))
            return GMIME_ERROR_BAD_PASSWORD;
          else if (strEQ(name, "GMIME_ERROR_NO_VALID_RECIPIENTS"))
            return GMIME_ERROR_NO_VALID_RECIPIENTS;
	  break;
        case 'F':
	  /* gmime-filter-basic.h */
          if (strEQ(name, "GMIME_FILTER_BASIC_BASE64_ENC"))
            return GMIME_FILTER_BASIC_BASE64_ENC;
          else if (strEQ(name, "GMIME_FILTER_BASIC_BASE64_DEC"))
            return GMIME_FILTER_BASIC_BASE64_DEC;
          else if (strEQ(name, "GMIME_FILTER_BASIC_QP_ENC"))
            return GMIME_FILTER_BASIC_QP_ENC;
          else if (strEQ(name, "GMIME_FILTER_BASIC_QP_DEC"))
            return GMIME_FILTER_BASIC_QP_DEC;
          else if (strEQ(name, "GMIME_FILTER_BASIC_UU_ENC"))
            return GMIME_FILTER_BASIC_UU_ENC;
          else if (strEQ(name, "GMIME_FILTER_BASIC_UU_DEC"))
            return GMIME_FILTER_BASIC_UU_DEC;
	  /* gmime-filter-best.h */
          else if (strEQ(name, "GMIME_FILTER_BEST_CHARSET"))
            return GMIME_FILTER_BEST_CHARSET;
          else if (strEQ(name, "GMIME_FILTER_BEST_ENCODING"))
            return GMIME_FILTER_BEST_ENCODING;
	  /* gmime-filter-crlf.h */
          else if (strEQ(name, "GMIME_FILTER_CRLF_ENCODE"))
            return GMIME_FILTER_CRLF_ENCODE;
          else if (strEQ(name, "GMIME_FILTER_CRLF_DECODE"))
            return GMIME_FILTER_CRLF_DECODE;
          else if (strEQ(name, "GMIME_FILTER_CRLF_MODE_CRLF_DOTS"))
            return GMIME_FILTER_CRLF_MODE_CRLF_DOTS;
          else if (strEQ(name, "GMIME_FILTER_CRLF_MODE_CRLF_ONLY"))
            return GMIME_FILTER_CRLF_MODE_CRLF_ONLY;
	  /* gmime-filter-enriched.h */
          else if (strEQ(name, "GMIME_FILTER_ENRICHED_IS_RICHTEXT"))
            return GMIME_FILTER_ENRICHED_IS_RICHTEXT;
	  /* gmime-filter-from.h */
          else if (strEQ(name, "GMIME_FILTER_FROM_MODE_DEFAULT"))
            return GMIME_FILTER_FROM_MODE_DEFAULT;
          else if (strEQ(name, "GMIME_FILTER_FROM_MODE_ESCAPE"))
            return GMIME_FILTER_FROM_MODE_ESCAPE;
          else if (strEQ(name, "GMIME_FILTER_FROM_MODE_ARMOR"))
            return GMIME_FILTER_FROM_MODE_ARMOR;
	  /* gmime-filter-yenc.h */
          else if (strEQ(name, "GMIME_FILTER_YENC_DIRECTION_ENCODE"))
            return GMIME_FILTER_YENC_DIRECTION_ENCODE;
          else if (strEQ(name, "GMIME_FILTER_YENC_DIRECTION_DECODE"))
            return GMIME_FILTER_YENC_DIRECTION_DECODE;
	  break;
        case 'L':
	  /* local constants */
          if (strEQ(name, "GMIME_LENGTH_ENCODED"))
            return GMIME_LENGTH_ENCODED;
          else if (strEQ(name, "GMIME_LENGTH_CUMULATIVE"))
            return GMIME_LENGTH_CUMULATIVE;
          break;
        case 'M':
	  /* gmime-multipart-signed.h */
          if (strEQ(name, "GMIME_MULTIPART_SIGNED_CONTENT"))
            return GMIME_MULTIPART_SIGNED_CONTENT;
          else if (strEQ(name, "GMIME_MULTIPART_SIGNED_SIGNATURE"))
            return GMIME_MULTIPART_SIGNED_SIGNATURE;
	  /* gmime-multipart-encrypted.h */
          else if (strEQ(name, "GMIME_MULTIPART_ENCRYPTED_VERSION"))
            return GMIME_MULTIPART_ENCRYPTED_VERSION;
          else if (strEQ(name, "GMIME_MULTIPART_ENCRYPTED_CONTENT"))
            return GMIME_MULTIPART_ENCRYPTED_CONTENT;
	  break;
        case 'P':
	  /* gmime-utils.h */
          if (strEQ(name, "GMIME_PART_ENCODING_DEFAULT"))
            return GMIME_PART_ENCODING_DEFAULT;
          else if (strEQ(name, "GMIME_PART_ENCODING_7BIT"))
            return GMIME_PART_ENCODING_7BIT;
          else if (strEQ(name, "GMIME_PART_ENCODING_8BIT"))
            return GMIME_PART_ENCODING_8BIT;
          else if (strEQ(name, "GMIME_PART_ENCODING_BASE64"))
            return GMIME_PART_ENCODING_BASE64;
          else if (strEQ(name, "GMIME_PART_ENCODING_QUOTEDPRINTABLE"))
            return GMIME_PART_ENCODING_QUOTEDPRINTABLE;
          else if (strEQ(name, "GMIME_PART_ENCODING_UUENCODE"))
            return GMIME_PART_ENCODING_UUENCODE;
          else if (strEQ(name, "GMIME_PART_NUM_ENCODINGS"))
            return GMIME_PART_NUM_ENCODINGS;
          break;
        case 'S':
	  /* gmime-stream*.h */
          if (strEQ(name, "GMIME_STREAM_SEEK_SET"))
            return GMIME_STREAM_SEEK_SET;
          else if (strEQ(name, "GMIME_STREAM_SEEK_CUR"))
	    return GMIME_STREAM_SEEK_CUR;
          else if (strEQ(name, "GMIME_STREAM_SEEK_END"))
	    return GMIME_STREAM_SEEK_END;
          else if (strEQ(name, "GMIME_STREAM_BUFFER_CACHE_READ"))
	    return GMIME_STREAM_BUFFER_CACHE_READ;
          else if (strEQ(name, "GMIME_STREAM_BUFFER_BLOCK_READ"))
	    return GMIME_STREAM_BUFFER_BLOCK_READ;
          else if (strEQ(name, "GMIME_STREAM_BUFFER_BLOCK_WRITE"))
	    return GMIME_STREAM_BUFFER_BLOCK_WRITE;
          break;
        }
      }
      break;
    case 'I':
      /* internet-address.h */
      if (strEQ(name, "INTERNET_ADDRESS_NONE"))
        return INTERNET_ADDRESS_NONE;
      else if (strEQ(name, "INTERNET_ADDRESS_NAME"))
        return INTERNET_ADDRESS_NAME;
      else if (strEQ(name, "INTERNET_ADDRESS_GROUP"))
        return INTERNET_ADDRESS_GROUP;
    }
    errno = EINVAL;
    return 0;
not_there:
    errno = ENOENT;
    return 0;
}


static const char *
constant_string(char *name, int len, int arg)
{
    errno = 0;
    switch (*name) {
    case 'G':
      if (strnEQ(name, "GMIME_", 6)) {
        switch (*(name+6)) {
        case 'D':
	  /* gmime-disposition.h */
          if (strEQ(name, "GMIME_DISPOSITION_ATTACHMENT"))
            return GMIME_DISPOSITION_ATTACHMENT;
	  else if (strEQ(name, "GMIME_DISPOSITION_INLINE"))
	    return GMIME_DISPOSITION_INLINE;
#if GMIME_CHECK_VERSION_UNSUPPORTED
	  /* gmime-message-delivery.h */
          if (strEQ(name, "GMIME_DSN_ACTION_FAILED"))
            return GMIME_DSN_ACTION_FAILED;
          else if (strEQ(name, "GMIME_DSN_ACTION_DELAYED"))
            return GMIME_DSN_ACTION_DELAYED;
          else if (strEQ(name, "GMIME_DSN_ACTION_DELIVERED"))
            return GMIME_DSN_ACTION_DELIVERED;
          else if (strEQ(name, "GMIME_DSN_ACTION_RELAYED"))
            return GMIME_DSN_ACTION_RELAYED;
          else if (strEQ(name, "GMIME_DSN_ACTION_EXPANDED"))
            return GMIME_DSN_ACTION_EXPANDED;
#endif
	  break;
        case 'M':
#if GMIME_CHECK_VERSION_UNSUPPORTED
	  /* gmime-message-mdn-disposition.h */
          if (strEQ(name, "GMIME_MDN_DISPOSITION_DISPLAYED"))
            return GMIME_MDN_DISPOSITION_DISPLAYED;
          else
          if (strEQ(name, "GMIME_MDN_DISPOSITION_DISPATCHED"))
            return GMIME_MDN_DISPOSITION_DISPATCHED;
          else
          if (strEQ(name, "GMIME_MDN_DISPOSITION_PROCESSED"))
            return GMIME_MDN_DISPOSITION_PROCESSED;
          else
          if (strEQ(name, "GMIME_MDN_DISPOSITION_DELETED"))
            return GMIME_MDN_DISPOSITION_DELETED;
          else
          if (strEQ(name, "GMIME_MDN_DISPOSITION_DENIED"))
            return GMIME_MDN_DISPOSITION_DENIED;
          else
          if (strEQ(name, "GMIME_MDN_DISPOSITION_FAILED"))
            return GMIME_MDN_DISPOSITION_FAILED;
          else
          if (strEQ(name, "GMIME_MDN_ACTION_MANUAL"))
            return GMIME_MDN_ACTION_MANUAL;
          else
          if (strEQ(name, "GMIME_MDN_ACTION_AUTOMATIC"))
            return GMIME_MDN_ACTION_AUTOMATIC;
          else
          if (strEQ(name, "GMIME_MDN_SENT_MANUALLY"))
            return GMIME_MDN_SENT_MANUALLY;
          else
          if (strEQ(name, "GMIME_MDN_SENT_AUTOMATICALLY"))
            return GMIME_MDN_SENT_AUTOMATICALLY;
          else
          if (strEQ(name, "GMIME_MDN_MODIFIER_ERROR"))
            return GMIME_MDN_MODIFIER_ERROR;
          else
          if (strEQ(name, "GMIME_MDN_MODIFIER_WARNING"))
            return GMIME_MDN_MODIFIER_WARNING;
          else
          if (strEQ(name, "GMIME_MDN_MODIFIER_SUPERSEDED"))
            return GMIME_MDN_MODIFIER_SUPERSEDED;
          else
          if (strEQ(name, "GMIME_MDN_MODIFIER_EXPIRED"))
            return GMIME_MDN_MODIFIER_EXPIRED;
          else
          if (strEQ(name, "GMIME_MDN_MODIFIER_MAILBOX_TERMINATED"))
            return GMIME_MDN_MODIFIER_MAILBOX_TERMINATED;
#endif
          break;
        case 'R':
         /* gmime-message.h */
          if (strEQ(name, "GMIME_RECIPIENT_TYPE_TO"))
            return GMIME_RECIPIENT_TYPE_TO;
          else if (strEQ(name, "GMIME_RECIPIENT_TYPE_CC"))
            return GMIME_RECIPIENT_TYPE_CC;
          else if (strEQ(name, "GMIME_RECIPIENT_TYPE_BCC"))
            return GMIME_RECIPIENT_TYPE_BCC;
          break;
        }
      }
      break;
    }
    errno = EINVAL;
    return 0;
not_there:
    errno = ENOENT;
    return 0;
}


