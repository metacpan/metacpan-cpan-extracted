package syntaxhighlighter::idl;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_CPP wxSTC_H_TAG);
    my $idl_keywords = 'aggregatable allocate appobject arrays async async_uuid \
auto_handle bindable boolean broadcast byte byte_count \
call_as callback char coclass code comm_status \
const context_handle context_handle_noserialize \
context_handle_serialize control cpp_quote custom \
decode default defaultbind defaultcollelem \
defaultvalue defaultvtable dispinterface displaybind dllname \
double dual enable_allocate encode endpoint entry enum error_status_t \
explicit_handle fault_status first_is float \
handle_t heap helpcontext helpfile helpstring \
helpstringcontext helpstringdll hidden hyper \
id idempotent ignore iid_as iid_is immediatebind implicit_handle \
import importlib in include in_line int __int64 __int3264 interface \
last_is lcid length_is library licensed local long \
max_is maybe message methods midl_pragma \
midl_user_allocate midl_user_free min_is module ms_union \
ncacn_at_dsp ncacn_dnet_nsp ncacn_http ncacn_ip_tcp \
ncacn_nb_ipx ncacn_nb_nb ncacn_nb_tcp ncacn_np \
ncacn_spx ncacn_vns_spp ncadg_ip_udp ncadg_ipx ncadg_mq \
ncalrpc nocode nonbrowsable noncreatable nonextensible notify \
object odl oleautomation optimize optional out out_of_line \
pipe pointer_default pragma properties propget propput propputref \
ptr public range readonly ref represent_as requestedit restricted retval \
shape short signed size_is small source strict_context_handle \
string struct switch switch_is switch_type \
transmit_as typedef uidefault union unique unsigned user_marshal usesgetlasterror uuid \
v1_enum vararg version void wchar_t wire_marshal';

    $_[0]->SetLexer(wxSTC_LEX_CPP);            # Set Lexers to use
    $_[0]->SetKeyWords(0,$idl_keywords);
#    $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );

    $_[0]->StyleSetSpec(0,"fore:#202020");					# White space
    $_[0]->StyleSetSpec(1,"fore:#bbbbbb");					# Comment
    $_[0]->StyleSetSpec(2,"fore:#cccccc)");					# Line Comment
    $_[0]->StyleSetSpec(3,"fore:#004000");					# Doc comment
    $_[0]->StyleSetSpec(4,"fore:#007f7f");					# Number
    $_[0]->StyleSetSpec(5,"fore:#7788bb,bold");					# Keywords
    $_[0]->StyleSetSpec(6,"fore:#555555,back:#ddeecc");			#  Doublequoted string
    $_[0]->StyleSetSpec(7,"fore:#555555,back:#eeeebb");			#  Single quoted string
    $_[0]->StyleSetSpec(8,"fore:#55ffff");					# UUIDs (only in IDL)
    $_[0]->StyleSetSpec(9,"fore:#228833");					# Preprocessor
    $_[0]->StyleSetSpec(10,"fore:#bb7799,bold");				# Operators
    $_[0]->StyleSetSpec(11,"fore:#778899");					# Identifiers (functions, etc.)
    $_[0]->StyleSetSpec(12,"fore:#228822");					# End of line where string is not closed
    $_[0]->StyleSetSpec(13,"fore:#339933");					# Verbatim strings for C#
    $_[0]->StyleSetSpec(14,"fore:#44aa44");					# Regular expressions for JavaScript
    $_[0]->StyleSetSpec(15,"fore:#55bb55");					# Doc Comment Line
    $_[0]->StyleSetSpec(17,"fore:#000000,back:#A0FFA0");			# Comment keyword
    $_[0]->StyleSetSpec(18,"fore:#000000,back:#F0E080");			# Comment keyword error
    # Braces are only matched in operator style     braces.cpp.style=10
    $_[0]->StyleSetSpec(32,"fore:#000000");					# Default
}

1;
