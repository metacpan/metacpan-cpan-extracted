#!perl -T

use lib qw( lib );
use Test::More tests => 71;

BEGIN {
	use_ok( 'LedgerSMB::API' );
}

my ($myconfig,$lsmb) = LedgerSMB::API->new_lsmb('LSMB_USER');

isa_ok($lsmb,'Form');
isa_ok($lsmb->{'dbh'},'DBI::db');

my @form_methods = qw{ new debug encode_all decode_all escape unescape quote unquote hide_form error info numtextrows dberror isblank header redirect sort_columns sort_order format_amount parse_amount round_amount db_parse_numeric callproc get_my_emp_num parse_template format_line cleanup rerun_latex format_string datetonum add_date print_button db_init run_custom_queries dbconnect dbconnect_noauto dbquote update_balance update_exchangerate save_exchangerate get_exchangerate check_exchangerate add_shipto get_employee get_name all_vc all_taxaccounts all_employees all_projects all_departments all_years create_links lastname_used current_date like redo_rows get_partsgroup update_status save_status get_recurring save_recurring save_intnotes update_defaults db_prepare_vars split_date format_date from_to audittrail };

foreach my $method (@form_methods){
  can_ok($lsmb,$method);
}

# diag( "Testing LedgerSMB::API $LedgerSMB::API::VERSION, Perl $], $^X" );
