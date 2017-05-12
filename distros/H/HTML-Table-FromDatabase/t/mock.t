#!/usr/bin/perl

# $Id$
# Put HTML::Table::FromDatabase through its paces, using Test::MockObject
# to provide a fake statement handle which provides known data.

use strict;
use Test::More;
use HTML::Table::FromDatabase;

eval "use Test::MockObject";
plan skip_all => "Test::MockObject required for mock testing"
    if $@;

# OK, we've got Test::MockObject, so we can go ahead:
plan tests => 17;

# Easy test: get a mock statement handle, and check we can make a table:
my $table = HTML::Table::FromDatabase->new( -sth => mocked_sth() );
ok($table, 'Seemed to get a table back');
isa_ok($table, 'HTML::Table', 'We got something that ISA HTML::Table');
my $html = $table->getTable;
like($html, qr{<th>Col1</th>}, 'Table contains one of the known column names');
like($html, qr{<td>R1C1</td>}, 'Table contains a known field value');

# now, test transformations:
$table = HTML::Table::FromDatabase->new(
    -sth => mocked_sth(),
    -callbacks => [
        {
            column => qr/Col[12]/,
            transform => sub { "RE_T" },
        },
        {
            column => 'Col3',
            transform => sub { "Plain_T" },
        },
        {
            value => 'R2C4',
            transform => sub { $_ = shift; s/R\dC\d/value_T/; $_ },
        },
    ],
    -row_callbacks => [
        sub {
            my $row = shift;
            if ($row->{Col1} eq 'Hide') {
                $row = undef;
            }
        },
        sub {
            my $row = shift;
            if ($row->{Col4} eq 'Munge') {
                $row->{Col4} = 'Munged';
            }
        },
    ],
);
$html = $table->getTable;
like($html, qr{<td>RE_T</td><td>RE_T</td>},
    'Callback regexp-matching column transformed OK');
like($html, qr{<td>Plain_T</td>},
    'Callback plain-matching column transformed OK');
like($html, qr{<td>value_T</td>}, 'Callback matching cell value transform OK');

like(  $html, qr{<td>Munged</td>}, "row_callback munged row");
unlike($html, qr{<td>Hide</td>},   "row_callback hid row");

# We can only test HTML stripping if HTML::Strip is available.
SKIP: {
    eval { require "HTML::Strip"; };
    skip "HTML::Strip not installed", 2 if $@;
    
    # check that HTML is stripped/encoded properly
    $table = HTML::Table::FromDatabase->new(
        -sth  => mocked_sth(),
        -html => 'strip',
    );
    $html = $table->getTable;
    like(  $html, qr{<td>HTML</td>}, 'HTML stripped correctly');
    unlike($html, qr{evilscript},    'Scripts removed correctly');
}

# Check that HTML is encoded properly:
$table = HTML::Table::FromDatabase->new(
    -sth  => mocked_sth(),
    -html => 'escape',
);
$html = $table->getTable;
like($html, qr{<td>&lt;p&gt;HTML&lt;/p&gt;</td>}, 'HTML encoded correctly');


# Check that overriding column names works
# Regression test for bug #50164 reported b Ireneusz Pluta
$table = HTML::Table::FromDatabase->new(
    -sth => mocked_sth(),
    -override_headers => [ qw(One Two Three Four Foo) ],
);
$html = $table->getTable;
like($html, qr{<th>One</th>}, '-override_headers works');

# Check that renaming certain headers works
$table = HTML::Table::FromDatabase->new(
    -sth => mocked_sth(),
    -rename_headers => { Col2 => 'Two' },
);
$html = $table->getTable;
like($html, qr{<th>Two</th>}, 
    '-rename_headers option renames column headers');
like ($html, qr{<th>Col3</th>},
    "-rename_headers option doesn't rename headers it shouldn't");
like ($html, qr{<th>foo_bar</th>},
    "-auto_pretty_headers has no effect if not asked for");

$table = HTML::Table::FromDatabase->new(
    -sth => mocked_sth(),
    -auto_pretty_headers => 1,
);
$html = $table->getTable;

like($html, qr{<th>Foo Bar</th>},
    "-auto_pretty_headers works when requested");


# Returns a make-believe statement handle, which should behave just like
# a real one would, returning known data to test against.
sub mocked_sth {
    # Create a make-believe statement handle:
    my $mock = Test::MockObject->new();
    $mock->set_isa('DBI::st');

    # Make it behave as we'd expect:
    $mock->{NAME} = [ qw(Col1 Col2 Col3 Col4 foo_bar) ];
    
    $mock->set_series(
	'fetchrow_hashref',
	{
	    Col1    => 'R1C1',
	    Col2    => 'R1C2',
	    Col3    => 'R1C3',
	    Col4    => 'R1C4',
	    foo_bar => 1,
	},
	{
	    Col1    => 'R2C1',
	    Col2    => 'R2C2',
	    Col3    => 'R2C3',
	    Col4    => 'R2C4',
	    foo_bar => 1,
	},
	{
	    Col1    => 'R3C1',
	    Col2    => 'R3C2',
	    Col3    => 'R3C3',
	    Col4    => 'R3C4',
	    foo_bar => 1,
	},
	{
	    Col1    => '<p>HTML</p>',
	    Col2    => '<div align="center">R3C2</div>',
	    Col3    => '<script>evilscript</script>',
	    Col4    => 'R3C4',
	    foo_bar => 1,
	},

	# This row will be hidden to test row_callbacks callbacks setting the
	# row hashref to undef:
	{
	    Col1    => 'Hide',
	    Col2    => 'R5C2',
	    Col3    => 'R5C3',
	    Col4    => 'R5C4',
	    foo_bar => 1,
	},

	# And this row will be changed via a row_callback
	{
	    Col1    => 'R6C1',
	    Col2    => 'R6C2',
	    Col3    => 'R6C3',
	    Col4    => 'Munge',
	    foo_bar => 1,
	},
    );
}
