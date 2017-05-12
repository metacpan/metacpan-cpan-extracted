typedef struct {
   GLenum mode;
   GLenum format; // 0, GL_T2F_V3F, GL_V2F
   GLuint texname;
   unsigned char r, g, b, a;
} rc_key_t;

typedef struct {
   HV *hv;
} rc_t;

typedef SV rc_array_t;

static rc_t *
rc_alloc (void)
{
  rc_t *rc = g_slice_new0 (rc_t);
  rc->hv = newHV ();

  return rc;
}

static void
rc_free (rc_t *rc)
{
  SvREFCNT_dec (rc->hv);
  g_slice_free (rc_t, rc);
}

static void
rc_clear (rc_t *rc)
{
  hv_clear (rc->hv);
}

static rc_array_t *
rc_array (rc_t *rc, rc_key_t *k)
{
  SV *sv = *hv_fetch (rc->hv, (char *)k, sizeof (*k), 1);

  if (SvTYPE (sv) != SVt_PV)
    {
      sv_upgrade (sv, SVt_PV);
      SvPOK_only (sv);
    }

  return sv;
}

static void
rc_v2f (rc_array_t *arr, float x, float y)
{
  STRLEN len = SvCUR (arr) + sizeof (float) * 2;
  SvGROW (arr, len);

  ((float *)SvEND (arr))[0] = x;
  ((float *)SvEND (arr))[1] = y;

  SvCUR_set (arr, len);
}

static void
rc_t2f_v3f (rc_array_t *arr, float u, float v, float x, float y, float z)
{
  STRLEN len = SvCUR (arr) + sizeof (float) * 5;
  SvGROW (arr, len);

  ((float *)SvEND (arr))[0] = u;
  ((float *)SvEND (arr))[1] = v;

  ((float *)SvEND (arr))[2] = x;
  ((float *)SvEND (arr))[3] = y;
  ((float *)SvEND (arr))[4] = z;

  SvCUR_set (arr, len);
}

static void
rc_glyph (rc_array_t *arr, int u, int v, int w, int h, int x, int y)
{
  if (w && h)
    {
      U8 *c;
      STRLEN len = SvCUR (arr);
      SvGROW (arr, len + 2 * 2 + 1 * 4);
      c = (U8 *)SvEND (arr);

      x += w;
      y += h;

      *c++ = u;
      *c++ = v;
      *c++ = w;
      *c++ = h;

      // use ber-encoding for up to 14 bits (16k)
      *c = 0x80 | (x >> 7); c += (x >> 7) ? 1 : 0; *c++ = x & 0x7f;
      *c = 0x80 | (y >> 7); c += (y >> 7) ? 1 : 0; *c++ = y & 0x7f;

      SvCUR_set (arr, c - (U8 *)SvPVX (arr));
    }
}

static void
rc_draw (rc_t *rc)
{
  HE *he;

  hv_iterinit (rc->hv);
  while ((he = hv_iternext (rc->hv)))
    {
      rc_key_t *key = (rc_key_t *)HeKEY (he);
      rc_array_t *arr = HeVAL (he);
      STRLEN len;
      char *arr_pv = SvPV (arr, len);
      GLsizei stride;

      if (key->texname)
        {
          glBindTexture (GL_TEXTURE_2D, key->texname);
          glEnable (GL_TEXTURE_2D);
        }
      else
        glDisable (GL_TEXTURE_2D);

      glColor4ub (key->r, key->g, key->b, key->a);

      if (key->format)
        {
          stride = key->format == GL_T2F_V3F ? sizeof (float) * 5
                 : key->format == GL_V2F     ? sizeof (float) * 2
                 : 65536;

          glInterleavedArrays (key->format, 0, (void *)arr_pv);
          //glLockArraysEXT (0, len / stride);
          glDrawArrays (key->mode, 0, len / stride);
          //glUnlockArraysEXT ();
        }
      else
        {
          // optimised character quad storage. slower but nice on memory.
          // reduces storage requirements from 80 bytes/char to 6-8
          U8 *c = (U8 *)arr_pv;
          U8 *e = c + len;

          glBegin (key->mode); // practically must be quads

          while (c < e)
            {
              int u, v, x, y, w, h;

              u = *c++;
              v = *c++;
              w = *c++;
              h = *c++;

              x = *c++; if (x > 0x7f) x = ((x & 0x7f) << 7) | *c++;
              y = *c++; if (y > 0x7f) y = ((y & 0x7f) << 7) | *c++;

              x -= w;
              y -= h;

              glTexCoord2f ( u      * (1.f / TC_WIDTH),  v      * (1.f / TC_HEIGHT)); glVertex2i (x    , y    );
              glTexCoord2f ((u + w) * (1.f / TC_WIDTH),  v      * (1.f / TC_HEIGHT)); glVertex2i (x + w, y    );
              glTexCoord2f ((u + w) * (1.f / TC_WIDTH), (v + h) * (1.f / TC_HEIGHT)); glVertex2i (x + w, y + h);
              glTexCoord2f ( u      * (1.f / TC_WIDTH), (v + h) * (1.f / TC_HEIGHT)); glVertex2i (x    , y + h);
            }

          glEnd ();
        }
    }

  glDisable (GL_TEXTURE_2D);
}




