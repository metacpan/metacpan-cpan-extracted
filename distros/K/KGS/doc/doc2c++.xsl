<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text" media-type="text/plain" encoding="utf-8"/>

<xsl:template match="/"><![CDATA[
// This is an automatically generated file. 
// This is an automatically generated file. 
// This is an automatically generated file. 
// This is an automatically generated file. 
// This is an automatically generated file. 

// See doc/protocol.xml and doc/doc2C.xsl

// this is NOT really c++, but it should compile as such

// this code is untested and just exists for demo purposes.
// please test and improve :)

#include <assert.h>

#include <...> should provide
typedef unsigned char U16;
typedef unsigned short U16;
typedef unsigned int U32;
typedef unsigned long long U64;
typedef signed char I8;
typedef signed short I16;
typedef signed int I32;
typedef signed long long I64;

// yeah, not very elegant
static U8 *data;
static U16 dlen;

static U8
dec_U8 (void)
{
  assert (dlen > 0);
  dlen--;
  return *data++;
}

static U16
dec_U16 (void)
{
  U16 l = dec_U8 ();
  U16 h = dec_U8 ();

  return l | (h << 8);
}

static U32
dec_U32 (void)
{
  U32 l = dec_U16 ();
  U32 h = dec_U16 ();

  return l | (h << 16);
}

static U64
dec_U64 (void)
{
  U64 l = dec_U32 ();
  U64 h = dec_U32 ();

  return l | (h << 32);
}

#define dec_I8()  ((I8)dec_U8 ())
#define dec_I16() ((I16)dec_U16 ())
#define dec_I32() ((I32)dec_U32 ())
#define dec_I64() ((I64)dec_U64 ())

// dec_DATA
// dec_STRING n
// dec_CONSTANT

#define dec_password() dec_U64()

static void
enc_U8 (U8 d)
{
  assert (dlen > 0);
  dlen--;
  *data++ = d;
}

#define enc_U16(d) enc_U8  (d); enc_U16 ((d) >>  8)
#define enc_U32(d) enc_U16 (d); enc_U16 ((d) >> 16)
#define enc_U64(d) enc_U32 (d); enc_U32 ((d) >> 32)
#define enc_I8(d)  enc_U8  ((U8 )d)
#define enc_I16(d) enc_U16 ((U16)d)
#define enc_I32(d) enc_U32 ((U32)d)
#define enc_I64(d) enc_U64 ((U64)d)

// enc_DATA
// enc_STRING ,n
// enc_CONSTANT

// enc_password
//   # $hash must be 64 bit
//   my $hash = new Math::BigInt;
//   $hash = $hash * 1055 + ord for split //, $_[0];
//   enc_U64 $hash;

]]>

#############################################################################
# types
<xsl:apply-templates select="descendant::type"/>

#############################################################################
# structures
<xsl:apply-templates select="descendant::struct"/>

#############################################################################
# "less" primitive types<![CDATA[

// dec_TREE
// enc_TREE
}
]]>

#############################################################################
# messages
<xsl:apply-templates select="descendant::message"/>
}

1;
</xsl:template>

<xsl:template match="type[@type = 'S']">

static U16 *
dec_<xsl:value-of select="@name"/> ()
{
   return dec_STRING (<xsl:value-of select="@length"/>);
}

static void
enc_<xsl:value-of select="@name"/> (const U16 *s)
{
   enc_STRING (s, <xsl:value-of select="@length"/>);
}
</xsl:template>

<xsl:template match="type[@type = 'A']">

static char *
dec_<xsl:value-of select="@name"/> ()
{
   return dec_ASCIZ (<xsl:value-of select="@length"/>);
}

static void
enc_<xsl:value-of select="@name"/> (const char *s)
{
   enc_ASCIZ (s, <xsl:value-of select="@length"/>);
}
</xsl:template>

<xsl:template match="type[@multiplier]">
static float
dec_<xsl:value-of select="@name"/> ()
{
   (1. / <xsl:value-of select="@multiplier"/>) * dec_<xsl:value-of select="@type"/> ();
}

static void
enc_<xsl:value-of select="@name"/> (float f)
{
   enc_<xsl:value-of select="@type"/> (f * <xsl:value-of select="@multiplier"/>);
}
</xsl:template>

<xsl:template match="member" mode="decl">
   <xsl:text>   </xsl:text><xsl:value-of select="@type"/><xsl:text> </xsl:text><xsl:value-of select="@name"/>;
</xsl:template>

<xsl:template match="member[@array = 'yes']" mode="dec">
   while (dlen)
      r.<xsl:value-of select="@name"/>->append (dec_<xsl:value-of select="@type"/> ());
</xsl:template>

<xsl:template match="member" mode="dec">
   <xsl:if test="@guard-cond">
 if (r.<xsl:value-of select="@guard-member"/> <xsl:value-of select="@guard-cond"/>)</xsl:if>
   r.<xsl:value-of select="@name"/> = dec_<xsl:value-of select="@type"/> ();
</xsl:template>

<xsl:template match="member" mode="enc">
   enc_<xsl:value-of select="@type"/> (r.<xsl:value-of select="@name"/>);
</xsl:template>

<xsl:template match="struct">
struct KGS_<xsl:value-of select="@name"/> {
<xsl:apply-templates select="member" mode="decl"/>};

static const struct KGS_<xsl:value-of select="@name"/> &amp;
dec_<xsl:value-of select="@name"/> ()
{
   struct KGS_<xsl:value-of select="@name"/> r;

   <xsl:apply-templates select="member" mode="dec"/>

   return r;
}

static void
enc_<xsl:value-of select="@name"/> (const struct KGS_<xsl:value-of select="@name"/> &amp;r)
{
   <xsl:apply-templates select="member" mode="enc"/>
}
</xsl:template>

<xsl:template match="message">
struct KGS_<xsl:value-of select="@src"/>_<xsl:value-of select="@name"/> {
<xsl:apply-templates select="member" mode="decl"/>};

static struct KGS_<xsl:value-of select="@src"/>_<xsl:value-of select="@name"/> &amp;
dec_<xsl:value-of select="@src"/>_<xsl:value-of select="@name"/> ()
{
   struct KGS_<xsl:value-of select="@src"/>_<xsl:value-of select="@name"/> r;
   
   r.type = MSG_<xsl:value-of select="@name"/>;
   <xsl:apply-templates select="member" mode="dec"/>
}

static void
enc_<xsl:value-of select="@src"/>_<xsl:value-of select="@name"/> (const struct KGS_<xsl:value-of select="@src"/>_<xsl:value-of select="@name"/> &amp;r)
{
   enc_U16 (0x<xsl:value-of select="@type"/>);
   <xsl:apply-templates select="member" mode="enc"/>
}

</xsl:template>

<xsl:template match="text()">
</xsl:template>

</xsl:stylesheet>

