#!perl -T
use strict;
use warnings FATAL => 'all';
use Data::Section -setup;
use Test::More;
use XML::LibXML;

our $lexemesXpath = XML::LibXML::XPathExpression->new('//*[@start]');

plan tests => 4 + scalar(__PACKAGE__->section_data_names);

use_ok('MarpaX::Languages::SQL2003::AST');

sub _diag {
  if ($ENV{TEST_DEBUG}) {
    diag(@_);
  }
}

my $obj = new_ok('MarpaX::Languages::SQL2003::AST');
my $tokenObj;
{
  no warnings;
  local $MarpaX::Languages::SQL2003::AST::start = ":start ::= <Tokens>\n<Tokens> ::= <Token>+\n";
  $tokenObj = new_ok('MarpaX::Languages::SQL2003::AST');
  _diag("Second grammar with <token>+ as value");
}
my $literalObj;
{
  no warnings;
  local $MarpaX::Languages::SQL2003::AST::start = ":start ::= <Literals>\n<Literals> ::= <Literal>+\n";
  $literalObj = new_ok('MarpaX::Languages::SQL2003::AST');
  _diag("Third grammar with <Literal>+ as value");
}
foreach (sort __PACKAGE__->section_data_names) {
  my $testName = $_;
  my $stringp = __PACKAGE__->section_data($testName);
  if ($testName =~ /\b(?:token|literal):/) {
    subtest $testName => sub {
      foreach (split(/\n/, ${$stringp})) {
	my $input = $_;
	$input =~ s/^\s*//;
	$input =~ s/\s*$//;
	if (length($input) > 0 && substr($input, 0, 2) ne '/*') {
	  my $obj = ($testName =~ /\btoken:/) ? $tokenObj : $literalObj;
	  my $xml = $obj->asXML($input
				# , trace_terminals => 1
			       );
	  my $length = length($input);
	  $length = 78 if ($length > 78);
	  _diag("\n" . ('=' x $length) . "\n$input\n" . ('=' x $length) . "\n" . $xml->toString(1));
	  my %wantedLexemes = ();
	  map {$wantedLexemes{$_} = 0} split(/,/, (split(/:/, $testName))[-1]);
	  my %unwantedLexemes = ();
	  foreach ($xml->findnodes($lexemesXpath)) {
	    my $localname = $_->localname();
	    if (exists($wantedLexemes{$localname})) {
	      $wantedLexemes{$localname}++;
	    } else {
	      $unwantedLexemes{$localname}++;
	    }
	  }
	  if (%unwantedLexemes) {
	    fail("$testName: $input");
	    diag("Some lexemes are not of type " . join(', or ', keys %wantedLexemes) . ": " . join(', ', keys %unwantedLexemes) . ". XML AST is:\n" . $xml->toString(1) . "\n");
	  } elsif (grep {$wantedLexemes{$_} <= 0} keys %wantedLexemes) {
	    fail("$testName: $input");
	    diag("Some lexemes are not found: " . join(', ', grep {$wantedLexemes{$_} <= 0} keys %wantedLexemes) . ". XML AST is:\n" . $xml->toString(1) . "\n");
	  } else {
	    pass("$testName: $input");
	  }
	}
      }
    }
  } else {
    subtest $testName => sub {
      foreach (split(/\n/, ${$stringp})) {
	my $input = $_;
	$input =~ s/^\s*//;
	$input =~ s/\s*$//;
	if (length($input) > 0 && substr($input, 0, 2) ne '/*') {
	  my $xml = $obj->asXML($input
				# , trace_terminals => 1
			       );
	  my $length = length($input);
	  $length = 78 if ($length > 78);
	  _diag("\n" . ('=' x $length) . "\n$input\n" . ('=' x $length) . "\n" . $xml->toString(1));
	  pass("$testName: $input");
	}
      }
    }
  }
}

__DATA__
__[ <001> token:Regular Identifier:Regular_Identifier ]__
/***************************************************************************/
A
A0
A_0
A_0_B

__[ <002> token:Key word:ADD ]__
/***************************************************************************/
ADD

__[ <003> token:Unsigned Numeric Literal:Unsigned_Numeric_Literal ]__
/***************************************************************************/
0
0.21
.22
1E+10
1E-20

__[ <005> token:National Character String Literal:National_Character_String_Literal ]__
/***************************************************************************/
N'some text'
n'some text'
N'some text'/*A comment */'Another text'
n'some text'/*A comment */'Another text'/* Another comment */

__[ <006> token:Large Object Length Token:Large_Object_Length_Token ]__
/***************************************************************************/
1G
10K
1000m

__[ <008> token:Unicode Delimited Identifier:Unicode_Delimited_Identifier ]__
/***************************************************************************/
U&"\0441\043F\0430\0441\0438\0431\043E" UESCAPE '#'
U&"\0441\043F\0430\0441\0438\0431\043E" UESCAPE '\'
U&"m\00fcde"
U&"m\00fcde""m\00fcde"
U&"m\00fcde"/* Comment */"m\00fcde"

__[ <009> token:Large object:Large_Object_Length_Token ]__
/***************************************************************************/
1M
100K
2G

__[ <010> token:Delimited Identifier:Delimited_Identifier ]__
/***************************************************************************/
"This"
"This \"quoted\""

__[ <011> literal:Character String Literal:Character_String_Literal ]__
/***************************************************************************/
'This' 'String'
_setName'This' 'String'
_anotherSetName'This' /* A Comment */ 'Other''String with a simple and an escaped quotes: \' inside'

__[ <100> SELECT ]__
/***************************************************************************/
/* Please note that SQL2003 *REQUIRES* a FROM */
SELECT _latin1'string' FROM dual;
SELECT _latin1'string' COLLATE latin1_danish_ci FROM dual;
SELECT N'some text' FROM dual;
SELECT n'some text' FROM dual;
SELECT _utf8'some text' FROM dual;
SELECT 'hello', '"hello"', '""hello""', 'hel''lo', '\'hello' FROM dual;
SELECT "hello", "'hello'", "''hello''", "hel""lo", "\"hello" FROM dual;
SELECT 'This\nIs\nFour\nLines' FROM dual;
SELECT 'disappearing\ backslash' FROM dual;

__[ <101> CREATE CHARACTER SET ]__
CREATE CHARACTER SET bob.charset_1 AS GET LATIN1;
CREATE CHARACTER SET bob.charset_1 GET LATIN1;
CREATE CHARACTER SET bob.charset_1 AS GET LATIN1 COLLATE bob.collation_1;

__[ <102> General statements ]__
/* Found at https://github.com/nilportugues/sql-query-builder */
/* Note that this page claims to provide SQL2003 compliant thingies. Not */
/* totally true: colum names are not enclosed in quotes. LIMIT is not part of */
/* SQL2003, a SELECT requires a FROM and so on. */
INSERT INTO user (user_id, name, contact) VALUES (:v1, :v2, :v3);
SELECT user.* FROM user;
SELECT user.user_id AS userId, user.name AS username, user.email AS email FROM user;
SELECT user.user_id AS userId, user.name AS username, user.email AS email FROM user WHERE (user.user_id < :v1) AND (user.username NOT LIKE :v2);
SELECT user.* FROM user WHERE (user.user_id = :v1) AND (user.user_id = :v2) AND ((user.user_id < :v3) OR (user.user_id > :v4));
SELECT user.user_id AS userId, user.name AS username, user.email AS email, user.created_at, news.title AS newsTitle, news.body, news.created_at, news.updated_at FROM user LEFT JOIN news ON (news.author_id = user.user_id) AND (news.author_id = :v1) WHERE (user.user_id < :v2) AND (user.username NOT LIKE :v3) ORDER BY user.user_id DESC, news.created_at DESC;
SELECT COUNT(*) FROM user;
SELECT COUNT(user.user_id) FROM user;
SELECT COUNT(user.user_id) AS total_users FROM user;
UPDATE user SET user.user_id = :v1, user.name = :v2, user.contact = :v3 WHERE (user.user_id = :v4);
UPDATE user SET user.name = :v1 WHERE (user.username LIKE :v2) AND (user.user_id BETWEEN :v3 AND :v4);
DELETE FROM user;
DELETE FROM user WHERE (user.user_id = :v1);
DELETE FROM user WHERE (user.username LIKE :v1) AND (user.user_id BETWEEN :v2 AND :v3);
SELECT user.* FROM user INTERSECT SELECT user_email.* FROM user_email;
SELECT user.* FROM user MINUS SELECT user_email.* FROM user_email;
SELECT user.* FROM user UNION SELECT user_email.* FROM user_email;
SELECT user.* FROM user UNION ALL SELECT user_email.* FROM user_email;
SELECT user.* FROM user WHERE (user.user_id = :v1) OR (user.name LIKE :v2);
SELECT user.user_id AS userId, user.name AS username, user.email AS email, user.created_at FROM user GROUP BY user.user_id, user.name HAVING (user.user_id = :v1) AND (user.user_id = :v2);
SELECT user.user_id AS userId, user.name AS username, user.email AS email, user.created_at FROM user GROUP BY user.user_id, user.name HAVING (user.user_id = :v1) OR (user.user_id = :v2);
SELECT user.user_id, user.username, ( SELECT role.role_name FROM role WHERE (role.role_id = :v1) ) AS user_role, ( SELECT role.role_name FROM role WHERE (role.role_id = :v4) ) AS role FROM user WHERE (user.user_id = :v7);
SELECT user.user_id, user.username, :v1 AS priority FROM user WHERE (user.user_id = :v2);
SELECT user.user_id, user.username, MAX(user_id) AS max_id FROM user WHERE (user.user_id = :v1);
SELECT user.user_id, user.username, CURRENT_TIMESTAMP AS server_time FROM user WHERE (user.user_id = :v1);
