use Test::More tests => 2;

BEGIN { use_ok( 'HTML::TableParser' ); }

my $p = HTML::TableParser->new( [ { id => 'DEFAULT' } ] );
eval {
$p->parse_file( 'tdata/end_table.html' );
};
ok ( $@ && $@ =~ m{too many </table>}, 'extra </table> tags' );
