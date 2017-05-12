<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text" media-type="text/plain" encoding="utf-8"/>

<xsl:template match="/"><![CDATA[
# This is an automatically generated file. 
# This is an automatically generated file. 
# This is an automatically generated file. 
# This is an automatically generated file. 
# This is an automatically generated file. 

# See doc/protocol.xml and doc/doc2constants_pm.xsl (and doc/Makefile)

package KGS::Constants;

use base Exporter;

BEGIN {
   @EXPORT = qw(
]]>
      <xsl:for-each select="descendant::enum | descendant::set">
         <xsl:variable name="prefix" select="@name"/>
         <xsl:text>&#10;      </xsl:text>
         <xsl:for-each select="descendant::member">
            <xsl:value-of select="concat($prefix, '_', @name)"/>
            <xsl:text> </xsl:text>
         </xsl:for-each>
      </xsl:for-each>
      <![CDATA[

      %ruleset %timesys %gametype %special_score %room_group
      
      INTERVAL_GAMEUPDATES
   );
}

]]>

<xsl:for-each select="descendant::enum | descendant::set">
   <xsl:variable name="prefix" select="@name"/>
   <xsl:for-each select="descendant::member">
      <xsl:value-of select="concat('sub ', $prefix, '_', @name, ' () { ', @value, ' }')"/>
      <xsl:text>&#10;</xsl:text>
   </xsl:for-each>
</xsl:for-each>

<![CDATA[

sub INTERVAL_GAMEUPDATES   () { 60 } # request game list updates this often (seconds).

# gametype (% 5)

%gametype = (
    &GAMETYPE_DEMONSTRATION => "demonstration",
    &GAMETYPE_EDITING       => "editing",
    &GAMETYPE_TEACHING      => "teaching",
    &GAMETYPE_SIMUL         => "simul",
    &GAMETYPE_FREE          => "free",
    &GAMETYPE_RATED         => "rated",
);

# special score values.
# positive == black won, negative == white one

# use the abs value
%special_score = (
   &SCORE_TIMEOUT   => "time",
   &SCORE_RESIGN    => "resign",
   &SCORE_FORFEIT   => "forfeit",

   &SCORE_JIGO      => "jigo",

   &SCORE_NO_RESULT => "NR",
   &SCORE_ADJOURNED => "(adj)",
   &SCORE_UNKNOWN   => "(unknown)",
);

# rule set

%ruleset = (
   &RULESET_JAPANESE    => "japanese",
   &RULESET_CHINESE     => "chinese",
   &RULESET_AGA         => "AGA",
   &RULESET_NEW_ZEALAND => "new zealand",
);

# time system

%timesys = (
   &TIMESYS_NONE     => "none",
   &TIMESYS_ABSOLUTE => "absolute",
   &TIMESYS_BYO_YOMI => "byo-yomi",
   &TIMESYS_CANADIAN => "canadian",
);

# stone/player etc. colours

%room_group = (
   0 => "Main",
   1 => "New Rooms",
   2 => "Clubs",
   3 => "Lessons",
   4 => "Tournaments",
   5 => "Social",
   6 => "National",
);

# misplaced here...
sub findfile {
   my @files = @_;
   file:
   for (@files) {
      for my $prefix (@INC) {
         if (-f "$prefix/$_") {
            $_ = "$prefix/$_";
            next file;
         }
      }
      die "$_: file not found in \@INC\n";
   }
   wantarray ? @files : $files[0];
}

1;
]]>
</xsl:template>

</xsl:stylesheet>

