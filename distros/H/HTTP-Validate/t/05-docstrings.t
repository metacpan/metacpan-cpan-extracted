#!perl 
# 
# This file tests for proper handling of 'allow' and 'require' rules.

use lib 'lib';

use strict;
use Test::More tests => 6;

use HTTP::Validate qw(:keywords :validators);

# Define some rulesets that include documentation strings.

eval {
    define_ruleset('A' =>
     { param => 'foo' },
        "Documentation for parameter C<foo>",
     { param => 'foe' },
	"! This parameter is not documented", 
     { param => 'bar' },
        "Documentation for parameter C<bar>",
     ">>A conclusion terminates this documentation.");
    
    define_ruleset('B' =>
     "An initial comment",
     { param => 'biff' },
        "Parameter C<biff> stuff,",
	"?!with multiple lines.",
	">Also, a new paragraph.",
     { param => 'baff' },
     { param => 'blort' },
        "No doc for C<baff>");
    
    define_ruleset('C' =>
     "A remark about A.",
     { require => 'A' },
     { allow => 'B' },
     "^An explanatory note about B.",
     { param => 'experimental', undocumented => 1 },
	"This parameter should not be shown in the documentation.");
    
    define_ruleset('D' =>
     "A header comment.",
     { allow => 'A' },
     "A comment to follow the inclusion.",
     "Plus another sentence.",
     { optional => 'foo' },
        "Single parameter comment.");
};

ok( !$@, 'rulesets with documentation' ) or diag( "    message was: $@");

my ($a_doc, $b_doc, $c_doc, $d_doc);

eval {
     $a_doc = document_params('A');
     $b_doc = document_params('B');
     $c_doc = document_params('C');
     $d_doc = document_params('D');
};

ok( !$@, 'get docstrings' ) or diag( "    message was: $@");

my $a_reference = <<A_DOC;
=over

=item foo

Documentation for parameter C<foo>

=item bar

Documentation for parameter C<bar>

=back

A conclusion terminates this documentation.
A_DOC

cmp_ok($a_doc, 'eq', $a_reference, 'docstring A');

my $b_reference = <<B_DOC;
An initial comment

=over

=item biff

Parameter C<biff> stuff,
!with multiple lines.

Also, a new paragraph.

=item baff

=item blort

No doc for C<baff>

=back
B_DOC

cmp_ok($b_doc, 'eq', $b_reference, 'docstring B');

my $c_reference = <<C_DOC;
A remark about A.

=over

=item foo

Documentation for parameter C<foo>

=item bar

Documentation for parameter C<bar>

=back

A conclusion terminates this documentation.

An explanatory note about B.
C_DOC

cmp_ok($c_doc, 'eq', $c_reference, 'docstring C');

my $d_reference = <<D_DOC;
A header comment.

=over

=item foo

Documentation for parameter C<foo>

=item bar

Documentation for parameter C<bar>

=back

A conclusion terminates this documentation.

A comment to follow the inclusion.
Plus another sentence.

=over

=item foo

Single parameter comment.

=back
D_DOC

cmp_ok($d_doc, 'eq', $d_reference, 'docstring D');
