<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:csl="urn:csl">
  <xsl:output method="xml" omit-xml-declaration="no" cdata-section-elements="size" />

  <!-- =================================================================== -->
  <!--                                  MAIN                               -->
  <!-- =================================================================== -->

  <xsl:template match="/">
    <csl>
      <xsl:call-template name="anyDeclarator" />
    </csl>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                              anyDeclarator                          -->
  <!-- =================================================================== -->
  <xsl:template name="anyDeclarator">
    <!--
        We search any declarator (abstract or not) from current node that is
        not a child of a scoped declaration nor array size definition, and
        that is at the end of an eventual () chain of the same declarator
        type.
        The absence of declarator is possible when we are called recursively
        for a parameterTypeList content. The signature is then well known:
        <parameterDeclaration>
          <declarationSpecifiers>
          ...
          </declarationSpecifiers>
        </parameterDeclaration>

        Note that old C-styleI identifierList will never match a declarator.
    -->
    <identifiers>
      <xsl:for-each select=".//*[
                            (
                             (
                              (local-name()='directDeclarator' and not(descendant::*[self::directDeclarator])) or
                              (local-name()='abstractDeclarator' and not(descendant::*[self::abstractDeclarator]))
                             )
                             and not
                              (ancestor::*
                               [
                               self::structDeclarationList or
                               self::parameterTypeList     or
                             
                               self::typeQualifierList     or
                               self::assignmentExpression
                               ]
                              )
                             )
                            ]
                            ">
        <xsl:if test="csl:fileOk(./@file) != 0" >
          <xsl:choose>
            <xsl:when test="local-name()='directDeclarator'">
              <xsl:text disable-output-escaping="yes">&lt;</xsl:text>identifier text="<xsl:value-of select="./@text" />"<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
              <xsl:call-template name="directDeclarator" />
              <xsl:text disable-output-escaping="yes">&lt;&#47;identifier&gt;</xsl:text>
            </xsl:when>
            <xsl:when test="local-name()='abstractDeclarator'">
              <xsl:text disable-output-escaping="yes">&lt;</xsl:text>identifier text="<xsl:value-of select="csl:getAnonIdentifier()" />"<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
              <xsl:call-template name="abstractDeclarator" />
              <xsl:text disable-output-escaping="yes">&lt;&#47;identifier&gt;</xsl:text>
            </xsl:when>
            <xsl:when test="local-name()='parameterDeclaration'">
              <xsl:text disable-output-escaping="yes">&lt;</xsl:text>identifier text="<xsl:value-of select="csl:getAnonIdentifier()" />"<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
              <xsl:call-template name="parameterDeclaration" />
              <xsl:text disable-output-escaping="yes">&lt;&#47;identifier&gt;</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:if>
      </xsl:for-each>
    </identifiers>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                             directDeclarator                        -->
  <!-- =================================================================== -->
  <xsl:template name="directDeclarator">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s in %s', local-name(), ./@text, ./@file)" />
    <xsl:call-template name="parent" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                            abstractDeclarator                       -->
  <!-- =================================================================== -->
  <xsl:template name="abstractDeclarator">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s in %s', local-name(), ./@text, ./@file)" />
    <!--
        Before moving upward, the abstractDeclarator has a special case:
        it can refer to a pointer.
        Please note that this template is called only when no more
        abstractDeclarator exist below, so there is no risk of recursion
    -->
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='pointer'" >
          <xsl:call-template name="pointer" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
    <xsl:call-template name="parent" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                           parameterDeclaration                      -->
  <!-- =================================================================== -->
  <xsl:template name="parameterDeclaration">
    <!--
        This template is called in the specific case of parameterTypeList
        without abstractDeclarator or directDeclarator.
        So the following test will match only declarationSpecifiers.
    -->
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s in %s', local-name(), ./@text, ./@file)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <!--
        <xsl:when test="local-name()='parameterDeclarationCheck'" >
          <xsl:call-template name="parameterDeclarationCheck" />
        </xsl:when>
        -->
        <xsl:when test="local-name()='declarationSpecifiers'" >
          <xsl:call-template name="declarationSpecifiers" />
        </xsl:when>
        <!--
        <xsl:when test="local-name()='abstractDeclarator'" >
          <xsl:call-template name="abstractDeclarator" />
        </xsl:when>
        -->
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                 parent                              -->
  <!-- =================================================================== -->
  <xsl:template name="parent">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <!--
        Look to the preceding siblings.
    -->
    <xsl:for-each select="./preceding-sibling::*" >
      <xsl:variable name="dummyTracef2" select="csl:tracef('&lt;. %s: %s', local-name(), ./@text)" />
      <xsl:choose>
        <xsl:when test="local-name()='pointer'">
          <xsl:call-template name="pointer" />
        </xsl:when>
        <xsl:when test="local-name()='declarationCheckdeclarationSpecifiers'">
          <xsl:call-template name="declarationCheckdeclarationSpecifiers" />
        </xsl:when>
        <xsl:when test="local-name()='parameterDeclarationdeclarationSpecifiers'">
          <xsl:call-template name="parameterDeclarationdeclarationSpecifiers" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers'">
          <xsl:call-template name="declarationSpecifiers" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList'">
          <xsl:call-template name="specifierQualifierList" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
    <!--
        Is it an array or a function.
    -->
    <xsl:for-each select="./following-sibling::*[1]">
      <xsl:variable name="dummyTracef2" select="csl:tracef('.> %s: %s', local-name(), ./@text)" />
      <xsl:choose>
        <xsl:when test="local-name() = 'LBRACKET'" >
          <array text="array">
            <size text="size">
              <xsl:for-each select="./following-sibling::*[1]">
                <xsl:choose>
                  <xsl:when test="local-name() != 'RBRACKET'" >
                    <xsl:value-of select="./@text" />
                  </xsl:when>
                </xsl:choose>
              </xsl:for-each>
            </size>
          </array>
        </xsl:when>
        <xsl:when test="local-name() = 'LPAREN_SCOPE'" >
          <!--
              This is a function.
              We recurse on the parameters.
          -->
          <function text="function">
            <xsl:for-each select="./following-sibling::*[1]">
              <xsl:choose>
                <xsl:when test="local-name() = 'parameterTypeList'" >
                  <xsl:variable name="dummyTracef3" select="csl:tracef('recurse %s: %s', local-name(), ./@text)" />
                  <parameters text="receiving parameters">
                    <xsl:for-each select="./*" >
                      <xsl:value-of select="csl:recurse(.)" disable-output-escaping="yes" />
                    </xsl:for-each>
                  </parameters>
                </xsl:when>
                <xsl:when test="local-name() = 'identifierList'" >
                  <!--
                      Issue a warning for old C-style declaration
                  -->
                  <xsl:variable name="dummyWarnf" select="csl:warnf('Old c-style not supported: %s', ../@text)" />
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </function>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
    <!--
        and recurse to the parent. In case of a function, the returning functionnality
        is enclosed in a dedicated block.
    -->
    <xsl:if test="./following-sibling::*[self::LPAREN_SCOPE]">
      <xsl:text disable-output-escaping="yes">&lt;</xsl:text>return text="returning"<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
    </xsl:if>
    <xsl:for-each select=".." >
      <xsl:if test="(local-name()!='structDeclarationList') and
                    (local-name()!='parameterTypeList')">
        <!-- not necessary but let's skip explicitely the root element -->
        <xsl:if test="generate-id(.) != generate-id(/)">
          <xsl:call-template name="parent" />
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="./following-sibling::*[self::LPAREN_SCOPE]">
      <xsl:text disable-output-escaping="yes">&lt;&#47;return&gt;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                  pointer                            -->
  <!-- =================================================================== -->
  <xsl:template name="pointer">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='STAR'" >
          <xsl:call-template name="STAR" />
        </xsl:when>
        <xsl:when test="local-name()='pointerQualifierList'" >
          <xsl:call-template name="pointerQualifierList" />
        </xsl:when>
        <xsl:when test="local-name()='pointer'" >
          <xsl:call-template name="pointer" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                     STAR                            -->
  <!-- =================================================================== -->
  <xsl:template name="STAR">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <pointer text="pointer to" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                         pointerQualifierList                        -->
  <!-- =================================================================== -->
  <xsl:template name="pointerQualifierList">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='pointerQualifier'" >
          <xsl:call-template name="pointerQualifier" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                           pointerQualifier                          -->
  <!-- =================================================================== -->
  <xsl:template name="pointerQualifier">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='typeQualifier'" >
          <xsl:call-template name="typeQualifier" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                typeQualifier                        -->
  <!-- =================================================================== -->
  <xsl:template name="typeQualifier">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='CONST'" >
          <xsl:call-template name="CONST" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                    CONST                            -->
  <!-- =================================================================== -->
  <xsl:template name="CONST">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <const text="read-only" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                      declarationCheckdeclarationSpecifiers          -->
  <!-- =================================================================== -->
  <xsl:template name="declarationCheckdeclarationSpecifiers">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='declarationSpecifiers'" >
          <xsl:call-template name="declarationSpecifiers" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                          declarationSpecifiers                      -->
  <!-- =================================================================== -->
  <xsl:template name="declarationSpecifiers">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='declarationSpecifiers0'" >
          <xsl:call-template name="declarationSpecifiers0" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers1'" >
          <xsl:call-template name="declarationSpecifiers1" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers2'" >
          <xsl:call-template name="declarationSpecifiers2" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                           declarationSpecifiers0                    -->
  <!-- =================================================================== -->
  <xsl:template name="declarationSpecifiers0">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='storageClassSpecifier'" >
          <xsl:call-template name="storageClassSpecifier" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers0'" >
          <xsl:call-template name="declarationSpecifiers0" />
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'" >
          <xsl:call-template name="typeQualifier" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                            storageClassSpecifier                    -->
  <!-- =================================================================== -->
  <xsl:template name="storageClassSpecifier">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='storageClassSpecifierTypedef'" >
          <xsl:call-template name="storageClassSpecifierTypedef" />
        </xsl:when>
        <xsl:when test="local-name()='EXTERN'" >
          <xsl:call-template name="EXTERN" />
        </xsl:when>
        <xsl:when test="local-name()='STATIC'" >
          <xsl:call-template name="STATIC" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                        storageClassSpecifierTypedef                 -->
  <!-- =================================================================== -->
  <xsl:template name="storageClassSpecifierTypedef">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='TYPEDEF'" >
          <xsl:call-template name="TYPEDEF" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                TYPEDEF                              -->
  <!-- =================================================================== -->
  <xsl:template name="TYPEDEF">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <typedef text="typedef" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                 EXTERN                              -->
  <!-- =================================================================== -->
  <xsl:template name="EXTERN">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <extern text="extern" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                 STATIC                              -->
  <!-- =================================================================== -->
  <xsl:template name="STATIC">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <static text="static" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                           declarationSpecifiers1                    -->
  <!-- =================================================================== -->
  <xsl:template name="declarationSpecifiers1">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='typeSpecifier1'" >
          <xsl:call-template name="typeSpecifier1" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers0'" >
          <xsl:call-template name="declarationSpecifiers0" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers1'" >
          <xsl:call-template name="declarationSpecifiers1" />
        </xsl:when>
        <xsl:when test="local-name()='storageClassSpecifier'" >
          <xsl:call-template name="storageClassSpecifier" />
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'" >
          <xsl:call-template name="typeQualifier" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                           declarationSpecifiers2                    -->
  <!-- =================================================================== -->
  <xsl:template name="declarationSpecifiers2">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='typeSpecifier2'" >
          <xsl:call-template name="typeSpecifier2" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers0'" >
          <xsl:call-template name="declarationSpecifiers0" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers2'" >
          <xsl:call-template name="declarationSpecifiers2" />
        </xsl:when>
        <xsl:when test="local-name()='storageClassSpecifier'" >
          <xsl:call-template name="storageClassSpecifier" />
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'" >
          <xsl:call-template name="typeQualifier" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                               typeSpecifier1                        -->
  <!-- =================================================================== -->
  <xsl:template name="typeSpecifier1">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='VOID'" >
          <xsl:call-template name="VOID" />
        </xsl:when>
        <xsl:when test="local-name()='FLOAT'" >
          <xsl:call-template name="FLOAT" />
        </xsl:when>
        <xsl:when test="local-name()='structOrUnionSpecifier'" >
          <xsl:call-template name="structOrUnionSpecifier" />
        </xsl:when>
        <xsl:when test="local-name()='enumSpecifier'" >
          <xsl:call-template name="enumSpecifier" />
        </xsl:when>
        <xsl:when test="local-name()='TYPEDEF_NAME'" >
          <xsl:call-template name="TYPEDEF_NAME" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                   VOID                              -->
  <!-- =================================================================== -->
  <xsl:template name="VOID">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <void text="void" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                  FLOAT                              -->
  <!-- =================================================================== -->
  <xsl:template name="FLOAT">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <float text="float" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                 TYPEDEF_NAME                        -->
  <!-- =================================================================== -->
  <xsl:template name="TYPEDEF_NAME">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:text disable-output-escaping="yes">&lt;</xsl:text>type name="<xsl:value-of select="./@text" />"<xsl:text disable-output-escaping="yes">&#47;&gt;</xsl:text>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                             structOrUnionSpecifier                  -->
  <!-- =================================================================== -->
  <xsl:template name="structOrUnionSpecifier">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='structOrUnion'" >
          <xsl:call-template name="structOrUnion" />
        </xsl:when>
        <xsl:when test="local-name()='structDeclarationList'" >
          <xsl:variable name="dummyTracef3" select="csl:tracef('recurse %s: %s', local-name(), ./@text)" />
          <members text="declared as:">
            <xsl:for-each select="./*" >
              <member>
                <xsl:value-of select="csl:recurse(.)" disable-output-escaping="yes" />
              </member>
            </xsl:for-each>
          </members>
        </xsl:when>
        <xsl:when test="local-name()='IDENTIFIER_UNAMBIGUOUS'" >
          <xsl:call-template name="IDENTIFIER_UNAMBIGUOUS" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                              structOrUnion                          -->
  <!-- =================================================================== -->
  <xsl:template name="structOrUnion">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='STRUCT'" >
          <xsl:call-template name="STRUCT" />
        </xsl:when>
        <xsl:when test="local-name()='UNION'" >
          <xsl:call-template name="UNION" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                    STRUCT                           -->
  <!-- =================================================================== -->
  <xsl:template name="STRUCT">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <struct text="struct" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                    UNION                            -->
  <!-- =================================================================== -->
  <xsl:template name="UNION">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <union text="union" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                             IDENTIFIER_UNAMBIGUOUS                  -->
  <!-- =================================================================== -->
  <xsl:template name="IDENTIFIER_UNAMBIGUOUS">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:text disable-output-escaping="yes">&lt;</xsl:text>identifier text="<xsl:value-of select="./@text" />"<xsl:text disable-output-escaping="yes">&#47;&gt;</xsl:text>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                               typeSpecifier2                        -->
  <!-- =================================================================== -->
  <xsl:template name="typeSpecifier2">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='CHAR'" >
          <xsl:call-template name="CHAR" />
        </xsl:when>
        <xsl:when test="local-name()='SHORT'" >
          <xsl:call-template name="SHORT" />
        </xsl:when>
        <xsl:when test="local-name()='INT'" >
          <xsl:call-template name="INT" />
        </xsl:when>
        <xsl:when test="local-name()='LONG'" >
          <xsl:call-template name="LONG" />
        </xsl:when>
        <xsl:when test="local-name()='DOUBLE'" >
          <xsl:call-template name="DOUBLE" />
        </xsl:when>
        <xsl:when test="local-name()='SIGNED'" >
          <xsl:call-template name="SIGNED" />
        </xsl:when>
        <xsl:when test="local-name()='UNSIGNED'" >
          <xsl:call-template name="UNSIGNED" />
        </xsl:when>
        <xsl:when test="local-name()='BOOL'" >
          <xsl:call-template name="BOOL" />
        </xsl:when>
        <xsl:when test="local-name()='COMPLEX'" >
          <xsl:call-template name="COMPLEX" />
        </xsl:when>
        <xsl:when test="local-name()='IMAGINARY'" >
          <xsl:call-template name="IMAGINARY" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                   CHAR                              -->
  <!-- =================================================================== -->
  <xsl:template name="CHAR">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <char text="char" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                  SHORT                              -->
  <!-- =================================================================== -->
  <xsl:template name="SHORT">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <short text="short" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                   INT                               -->
  <!-- =================================================================== -->
  <xsl:template name="INT">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <int text="int" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                  LONG                               -->
  <!-- =================================================================== -->
  <xsl:template name="LONG">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <long text="long" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                 DOUBLE                              -->
  <!-- =================================================================== -->
  <xsl:template name="DOUBLE">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <double text="double" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                 SIGNED                              -->
  <!-- =================================================================== -->
  <xsl:template name="SIGNED">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <signed text="signed" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                UNSIGNED                             -->
  <!-- =================================================================== -->
  <xsl:template name="UNSIGNED">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <unsigned text="unsigned" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                  BOOL                               -->
  <!-- =================================================================== -->
  <xsl:template name="BOOL">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <bool text="bool" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                 LABEL                               -->
  <!-- =================================================================== -->
  <xsl:template name="LABEL">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <label text="label" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                                COMPLEX                              -->
  <!-- =================================================================== -->
  <xsl:template name="COMPLEX">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <complex text="complex" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--                               IMAGINARY                             -->
  <!-- =================================================================== -->
  <xsl:template name="IMAGINARY">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <imaginary text="imaginary" />
  </xsl:template>

  <!-- =================================================================== -->
  <!--            parameterDeclarationdeclarationSpecifiers                -->
  <!-- =================================================================== -->
  <xsl:template name="parameterDeclarationdeclarationSpecifiers">
    <xsl:variable name="dummyTracef" select="csl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='declarationSpecifiers'" >
          <xsl:call-template name="declarationSpecifiers" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                          specifierQualifierList                     -->
  <!-- =================================================================== -->
  <xsl:template name="specifierQualifierList">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='specifierQualifierList0'" >
          <xsl:call-template name="specifierQualifierList0" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList1'" >
          <xsl:call-template name="specifierQualifierList1" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList2'" >
          <xsl:call-template name="specifierQualifierList2" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                           specifierQualifierList0                   -->
  <!-- =================================================================== -->
  <xsl:template name="specifierQualifierList0">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='typeQualifier'" >
          <xsl:call-template name="typeQualifier" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList0'" >
          <xsl:call-template name="specifierQualifierList0" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                           specifierQualifierList1                   -->
  <!-- =================================================================== -->
  <xsl:template name="specifierQualifierList1">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='typeSpecifier1'" >
          <xsl:call-template name="typeSpecifier1" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList0'" >
          <xsl:call-template name="specifierQualifierList0" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList1'" >
          <xsl:call-template name="specifierQualifierList1" />
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'" >
          <xsl:call-template name="typeQualifier" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                           specifierQualifierList2                   -->
  <!-- =================================================================== -->
  <xsl:template name="specifierQualifierList2">
    <xsl:variable name="dummyTracef" select="csl:tracef('.. %s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*" >
      <xsl:choose>
        <xsl:when test="local-name()='typeSpecifier2'" >
          <xsl:call-template name="typeSpecifier2" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList0'" >
          <xsl:call-template name="specifierQualifierList0" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList2'" >
          <xsl:call-template name="specifierQualifierList2" />
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'" >
          <xsl:call-template name="typeQualifier" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
