<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:hsl="urn:hsl">
  <xsl:output method="text" omit-xml-declaration="yes" />

  <!-- =================================================================== -->
  <!--                            MAIN                                     -->
  <!-- =================================================================== -->

  <xsl:template match="/">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select=".//structOrUnionSpecifier[not (ancestor::*[self::structDeclarationList])]">
      <xsl:call-template name="topStructOrUnionSpecifier" />
    </xsl:for-each>
    <!-- In theory this is not possible to have a typedef ancestor of typedef -; -->
    <xsl:for-each select=".//TYPEDEF">
      <xsl:call-template name="typedef" />
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                 Top Level Structure Or Union                        -->
  <!-- =================================================================== -->

  <xsl:template name="topStructOrUnionSpecifier">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <!-- Decypher the structures or unions -->
    <xsl:call-template name="structOrUnionSpecifier">
      <xsl:with-param name="top" select="1"/>
    </xsl:call-template>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                   structOrUnionSpecifier                            -->
  <!-- =================================================================== -->

  <xsl:template name="structOrUnionSpecifier">
    <xsl:param name="top" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <!--
          We are not interested in the eventual structOrUnion unambiguous
          identifier, we aways retypedef everything under a name that we
          control. Ok, If there is such identifier, we use it in the typedef.
          Otherwise the full structure content is repeated.
    -->
    <xsl:variable name="content" select="./structDeclarationList/@text" />
    <xsl:if test="$content">
      <xsl:variable name="identifierUnambiguous" select="./IDENTIFIER_UNAMBIGUOUS" />
      <xsl:variable name="cachedIdentifier" select="hsl:getContentToIdentifier($content)" />
      <xsl:variable name="identifier">
        <xsl:choose>
          <xsl:when test="$cachedIdentifier!=''">
            <xsl:value-of select="$cachedIdentifier" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat(hsl:prefix(), hsl:anon(), hsl:nextAnonCounter())"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!-- If first time for this text, do a declaration -->
      <xsl:if test="$cachedIdentifier=''">
        <xsl:choose>
          <!-- Take care: a eventual existing unambiguous identifier can be taken only if at the top -->
          <xsl:when test="($top='1') and ($identifierUnambiguous)" >
            <xsl:variable name="dummyAddStruct" select="hsl:addTypedef(./structOrUnion/@text, $identifier, $identifierUnambiguous/@text)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="dummyAddStruct" select="hsl:addTypedef(./structOrUnion/@text, $identifier, concat('{', $content, '}'))" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:variable name="dummySetContentToIdentifier" select="hsl:setContentToIdentifier($content, $identifier)"/>
      </xsl:if>
      <xsl:if test="hsl:getDoneIdentifier($identifier)=''">
        <xsl:variable name="dummyCdeclPush" select="hsl:cdeclPush($identifier, ./structOrUnion/@text)" />
        <xsl:for-each select="./structDeclarationList/*/structDeclaratorList/*/declarator">
          <xsl:call-template name="declarator" />
        </xsl:for-each>
        <xsl:variable name="dummySetDoneIdentifier" select="hsl:setDoneIdentifier($identifier)" />
        <xsl:variable name="dummyCdeclPop" select="hsl:cdeclPop()" />
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                            typedef                                  -->
  <!-- =================================================================== -->
  <xsl:template name="typedef">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <!-- Move to the nearest initDeclaratorList -->
    <xsl:for-each select="./following::*[self::initDeclaratorList][1]" >
      <xsl:for-each select="./initDeclarator/declarator" >
        <xsl:call-template name="declarator">
          <xsl:with-param name="typedefMode" select="1" />
          <xsl:with-param name="withTypedef" select="0" />
        </xsl:call-template>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                       Decypher declarators                          -->
  <!-- =================================================================== -->

  <xsl:template name="declarator">
    <xsl:param name="typedefMode" />
    <xsl:param name="withTypedef" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />

    <!-- by definition the first found identifier is the one we are looking for -->
    <xsl:variable name="IDENTIFIER" select="./descendant::IDENTIFIER[1]" />
    <xsl:variable name="member" select="$IDENTIFIER/@text"/>
    <xsl:choose>
      <xsl:when test="$typedefMode">
        <xsl:variable name="dummyTypedefPush" select="hsl:typedefPush($member)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="dummyCdecl" select="hsl:cdecl($member)" />
      </xsl:otherwise>
    </xsl:choose>
    <!-- Decypher the declarator -->
    <xsl:for-each select="$IDENTIFIER/../..">
      <xsl:call-template name="decypherDirectDeclarator" />
    </xsl:for-each>
    <xsl:choose>
      <xsl:when test="$typedefMode">
        <!--
            Decypher the declaration specifiers. Tree is:
            declarationCheck/declarationCheckinitDeclaratorList/initDeclaratorList/initDeclarator/declarator
            declarationCheck/declarationCheckdeclarationSpecifiers/declarationSpecifiers
        -->
        <xsl:for-each select="../../../../declarationCheckdeclarationSpecifiers/declarationSpecifiers">
          <xsl:call-template name="decypherDeclarationSpecifiers">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:for-each>
        <xsl:variable name="dummyTypedefPop" select="hsl:typedefPop()" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="decypherDeclarationSpecifiers">
    <xsl:param name="withTypedef" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='declarationSpecifiers0'">
          <xsl:call-template name="decypherDeclarationSpecifiers0">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers1'">
          <xsl:call-template name="decypherDeclarationSpecifiers1">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers2'">
          <xsl:call-template name="decypherDeclarationSpecifiers2">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherDirectDeclarator">
    <!-- Look for the next lexeme on the right -->
    <xsl:variable name="nextLexeme" select="./following-sibling::*[1]" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:choose>
      <xsl:when test="$nextLexeme[local-name()='LBRACKET']">
        <!-- We take all the text as-is up to the RBRACKET -->
        <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'array')" />
        <!-- If you want the size, you could do: <xsl:for-each select="$nextLexeme/following-sibling::*[local-name()!='RBRACKET']"><xsl:value-of select="concat(' ', ./@text)" /></xsl:for-each> -->
      </xsl:when>
      <xsl:when test="$nextLexeme[local-name()='LPAREN_SCOPE']">
        <xsl:variable name="nextLexeme2" select="$nextLexeme/following-sibling::*[1]" />
        <xsl:choose>
          <xsl:when test="$nextLexeme2[local-name()='parameterTypeList']">
            <xsl:for-each select="$nextLexeme2">
              <xsl:call-template name="decypherParameterTypeList" />
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="$nextLexeme2[local-name()='RPAREN_SCOPE']">
            <xsl:variable name="dummyWarnf" select="hsl:warnf('%s: unparameterized function', ../@text)" />
          </xsl:when>
          <xsl:when test="$nextLexeme2[local-name()='identifierList']">
            <xsl:variable name="dummyWarnf" select="hsl:warnf('%s: old style declaration', ../@text)" />
          </xsl:when>
        </xsl:choose>
        <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'function')" />
      </xsl:when>
    </xsl:choose>
    <!--
        Look to parent of directDeclarator. This can only be:
        * declarator
        * directDeclarator
    -->
    <xsl:for-each select="..">
      <xsl:choose>
        <xsl:when test="local-name()='declarator'">
          <xsl:call-template name="decypherDeclarator" />
        </xsl:when>
        <xsl:when test="local-name()='directDeclarator'">
          <xsl:call-template name="decypherDirectDeclarator" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherPointer">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <!--
        A pointer may have a pointerQualifierList that is nothing else but
        a typeQualifier, or again a pointer. Nevertheless there is the
        subtility of CONST lexeme. CONST belong only in typeQualifier, and the
        the rule is: if there is CONST in pointerQualifier, it means the pointer
        is read-only.
    -->
    <xsl:if test="./pointerQualifierList/pointerQualifier/typeQualifier/CONST">
      <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'readonly')" />
    </xsl:if>
    <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'pointer')" />
    <!-- Then take all typeQualifiers except CONST -->
    <xsl:for-each select="./pointerQualifierList/pointerQualifier/typeQualifier">
      <xsl:call-template name="decypherTypeQualifier">
        <xsl:with-param name="withConst" select="0" />
      </xsl:call-template>
    </xsl:for-each>
    <xsl:for-each select="./pointer">
      <xsl:call-template name="decypherPointer" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherDeclarator">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <!--
        The only important thing is to know if there is a pointer, which can
        only be the very first child of declarator
    -->
    <xsl:for-each select="./child::*[1][local-name()='pointer']">
      <xsl:call-template name="decypherPointer" />
    </xsl:for-each>
    <!--
        Look to parent of declarator. This can only be:
        * initDeclarator                       : cannot happen in a context of a structure declaration
        * structDeclarator                     : we are interested in specifierQualifierList
        * directDeclarator
        * parameterDeclarationCheckDeclarator  : we are not in the context of a parameter declaration
        * fileScopeDeclarator                  : end of the story
    -->
    <xsl:for-each select="..">
      <xsl:choose>
        <xsl:when test="local-name()='structDeclarator'">
          <!-- structDeclaratorList/structDeclarator -->
          <xsl:for-each select="../preceding-sibling::*[1]">
            <xsl:call-template name="decypherSpecifierQualifierList" />
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="local-name()='directDeclarator'">
          <xsl:call-template name="decypherDirectDeclarator" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherAbstractDeclarator">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <!--
        The only important thing is to know if there is a pointer, which can
        only be the very first child of an abstractDeclarator
    -->
    <xsl:for-each select="./child::*[1][local-name()='pointer']">
      <xsl:call-template name="decypherPointer" />
    </xsl:for-each>
    <!--
        Look to parent of abstractDeclarator. This can only be:
        * parameterDeclaration
        * typeName
        * directAbstractDeclarator
    -->
    <xsl:for-each select="..">
      <xsl:choose>
        <xsl:when test="local-name()='parameterDeclaration'">
          <!-- structDeclaratorList/structDeclarator -->
          <xsl:for-each select="../preceding-sibling::*[1]">
            <xsl:call-template name="decypherSpecifierQualifierList" />
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="local-name()='directDeclarator'">
          <xsl:call-template name="decypherDirectDeclarator" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherSpecifierQualifierList">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='specifierQualifierList0'">
          <xsl:call-template name="decypherSpecifierQualifierList0" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList1'">
          <xsl:call-template name="decypherSpecifierQualifierList1" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList2'">
          <xsl:call-template name="decypherSpecifierQualifierList2" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherParameterDeclaration">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:variable name="parameterDeclarationCheck" select="./*[local-name()='parameterDeclarationCheck']" />
    <xsl:variable name="abstractDeclarator" select="./*[local-name()='abstractDeclarator']" />
    <xsl:choose>
      <xsl:when test="$abstractDeclarator">
        <!-- If there is an abstractDeclarator, we start from there -->
        <xsl:for-each select="$abstractDeclarator">
          <xsl:call-template name="decypherAbstractDeclarator" />
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$abstractDeclarator">
        <!-- If there is an parameterDeclarationCheck, then there is a declarator -->
        <xsl:for-each select="$parameterDeclarationCheck/parameterDeclarationCheckDeclarator/declarator">
          <xsl:call-template name="decypherDeclarator" />
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <!-- else this is only declarationSpecifiers -->
        <xsl:for-each select="./declarationSpecifiers">
          <xsl:call-template name="decypherDeclarationSpecifiers" />
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="decypherParameterDeclarationdeclarationSpecifiers">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='declarationSpecifiers'">
          <xsl:call-template name="decypherDeclarationSpecifiers" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherParameterTypeList">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:variable name="parameterList" select="./parameterList" />
    <xsl:if test="./ELLIPSIS">
      <xsl:variable name="dummyWarnf" select="hsl:warnf('%s: ellipsis parameter', ../@text)" />
    </xsl:if>
    <xsl:for-each select="$parameterList" >
      <xsl:call-template name="decypherParameterList" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherParameterList">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:call-template name="decypherParameterDeclaration" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherSpecifierQualifierList1">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='typeSpecifier1'">
          <xsl:call-template name="decypherTypeSpecifier1" />
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'">
          <xsl:call-template name="decypherTypeQualifier">
            <xsl:with-param name="withConst" select="1" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList0'">
          <xsl:call-template name="decypherSpecifierQualifierList0" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList1'">
          <xsl:call-template name="decypherSpecifierQualifierList1" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherSpecifierQualifierList2">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='typeSpecifier2'">
          <xsl:call-template name="decypherTypeSpecifier2" />
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'">
          <xsl:call-template name="decypherTypeQualifier">
            <xsl:with-param name="withConst" select="1" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList0'">
          <xsl:call-template name="decypherSpecifierQualifierList0" />
        </xsl:when>
        <xsl:when test="local-name()='specifierQualifierList2'">
          <xsl:call-template name="decypherSpecifierQualifierList2" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherTypeSpecifier1">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='VOID'">
          <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'void')" />
        </xsl:when>
        <xsl:when test="local-name()='FLOAT'">
          <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'float')" />
        </xsl:when>
        <xsl:when test="local-name()='structOrUnionSpecifier'">
          <!-- Decypher the structure or union -->
          <xsl:call-template name="structOrUnionSpecifier">
            <xsl:with-param name="top" select="0"/>
          </xsl:call-template>
          <xsl:variable name="content" select="./structDeclarationList/@text" />
          <xsl:variable name="type">
            <xsl:choose>
              <xsl:when test="$content">
                <xsl:value-of select="hsl:cdecl('', 'type', ./structOrUnion/@text, 'name', hsl:getContentToIdentifier(./structDeclarationList/@text))" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="hsl:cdecl('', 'type', ./structOrUnion/@text, 'name', ./IDENTIFIER_UNAMBIGUOUS/@text)" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
        </xsl:when>
        <xsl:when test="local-name()='TYPEDEF_NAME'">
          <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'typedef_name', 'name', ./@text)" />
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherTypeQualifier">
    <xsl:param name="withConst" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:if test="($withConst='1' and local-name()='CONST') or ($withConst='0' and local-name()!='CONST')" >
        <xsl:if test="local-name()='CONST'">
          <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'read-only')" />
        </xsl:if>
        <xsl:if test="local-name()!='CONST'">
          <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', ./@text)" />
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherTypeSpecifier2">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', ./@text)" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherDeclarationSpecifiers0">
    <xsl:param name="withTypedef" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='storageClassSpecifier'">
          <xsl:call-template name="decypherStorageClassSpecifier">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers0'">
          <xsl:call-template name="decypherDeclarationSpecifiers0">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'">
          <xsl:call-template name="decypherTypeQualifier">
            <xsl:with-param name="withConst" select="1" />
            <!-- typedef is not in typeQualifier -->
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='functionSpecifier'">
          <xsl:call-template name="decypherFunctionSpecifier">
            <!-- typedef is not in functionSpecifier -->
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='alignmentSpecifier'">
          <!-- alignmentSpecifier is explicitely ignored -->
        </xsl:when>
        <xsl:when test="local-name()='gccExtension'">
          <!-- gccExtension is explicitely ignored -->
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherDeclarationSpecifiers1">
    <xsl:param name="withTypedef" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='typeSpecifier1'">
          <xsl:call-template name="decypherTypeSpecifier1" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers0'">
          <xsl:call-template name="decypherDeclarationSpecifiers0">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers1'">
          <xsl:call-template name="decypherDeclarationSpecifiers1">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='storageClassSpecifier'">
          <xsl:call-template name="decypherStorageClassSpecifier">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'">
          <xsl:call-template name="decypherTypeQualifier">
            <xsl:with-param name="withConst" select="1" />
            <!-- typedef is not in typeQualifier -->
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='functionSpecifier'">
          <xsl:call-template name="decypherFunctionSpecifier">
            <!-- typedef is not in functionSpecifier -->
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='alignmentSpecifier'">
          <!-- alignmentSpecifier is explicitely ignored -->
        </xsl:when>
        <xsl:when test="local-name()='gccExtension'">
          <!-- gccExtension is explicitely ignored -->
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherDeclarationSpecifiers2">
    <xsl:param name="withTypedef" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:choose>
        <xsl:when test="local-name()='typeSpecifier2'">
          <xsl:call-template name="decypherTypeSpecifier2" />
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers0'">
          <xsl:call-template name="decypherDeclarationSpecifiers0">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='declarationSpecifiers2'">
          <xsl:call-template name="decypherDeclarationSpecifiers2">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='storageClassSpecifier'">
          <xsl:call-template name="decypherStorageClassSpecifier">
            <xsl:with-param name="withTypedef" select="$withTypedef" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='typeQualifier'">
          <xsl:call-template name="decypherTypeQualifier">
            <xsl:with-param name="withConst" select="1" />
            <!-- typedef is not in typeQualifier -->
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='functionSpecifier'">
          <xsl:call-template name="decypherFunctionSpecifier">
            <!-- typedef is not in functionSpecifier -->
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="local-name()='alignmentSpecifier'">
          <!-- alignmentSpecifier is explicitely ignored -->
        </xsl:when>
        <xsl:when test="local-name()='gccExtension'">
          <!-- gccExtension is explicitely ignored -->
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherFunctionSpecifier">
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', ./@text)" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="decypherStorageClassSpecifier">
    <xsl:param name="withTypedef" />
    <xsl:variable name="dummyTracef" select="hsl:tracef('%s: %s', local-name(), ./@text)" />
    <xsl:for-each select="./*">
      <xsl:if test="($withTypedef='1' and local-name()='storageClassSpecifierTypedef') or ($withTypedef='0' and local-name()!='storageClassSpecifierTypedef')" >
        <xsl:if test="local-name()='storageClassSpecifierTypedef'">
          <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', 'typedef')" />
        </xsl:if>
        <xsl:if test="local-name()!='storageClassSpecifierTypedef'">
          <xsl:variable name="dummyCdecl" select="hsl:cdecl('', 'type', ./@text)" />
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
