#
#   This file is part of the Kools::Okapi package
#   a Perl C wrapper for the Thomson Reuters Kondor+ OKAPI api.
#
#   Copyright (C) 2009 Gabriel Galibourg
#
#   The Kools::Okapi package is free software; you can redistribute it and/or
#   modify it under the terms of the Artistic License 2.0 as published by
#   The Perl Foundation; either version 2.0 of the License, or
#   (at your option) any later version.
#
#   The Kools::Okapi package is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   Perl Artistic License for more details.
#
#   You should have received a copy of the Artistic License along with
#   this package.  If not, see <http://www.perlfoundation.org/legal/>.
# 
#


package Kools::Okapi;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

# ICC_status_t
use constant ICC_ERROR                                    => ($! = -1);
use constant ICC_OK                                       => ($! = 0);

# ICC_option_t
use constant ICC_TIMEOUT                                  => ($! = 1);
use constant ICC_RECONNECT                                => ($! = 2);
use constant ICC_PING_INTERVAL                            => ($! = 3);
use constant ICC_PORT_NAME                                => ($! = 4);
use constant ICC_KIS_HOST_NAMES                           => ($! = 5);
use constant ICC_CLIENT_NAME                              => ($! = 6);
use constant ICC_CLIENT_RECEIVE                           => ($! = 7);

use constant ICC_CLIENT_DATA                              => ($! = 8);
use constant ICC_CLIENT_READY                             => ($! = 9);

use constant ICC_SET_FDS_CALLBACK                         => ($! = 10);
use constant ICC_SELECT_TIMEOUT                           => ($! = 11);
use constant ICC_SELECT_TIMEOUT_CALLBACK                  => ($! = 12);
use constant ICC_SELECT_SIGNAL_CALLBACK                   => ($! = 13);
use constant ICC_SELECT_MSG_CALLBACK                      => ($! = 14);
use constant ICC_IDENT_MSG_CALLBACK                       => ($! = 15);
use constant ICC_DATA_MSG_CALLBACK                        => ($! = 16);
use constant ICC_PING_MSG_CALLBACK                        => ($! = 17);
use constant ICC_CLOSE_FD_MSG_CALLBACK                    => ($! = 18);
use constant ICC_CLOSE_MSG_CALLBACK                       => ($! = 19); #/* Rendez Vous */
use constant ICC_DISCONNECT_CALLBACK                      => ($! = 20); #/* Client Only */
use constant ICC_RECONNECT_CALLBACK                       => ($! = 21); #/* Client Only */

use constant ICC_SEND_DATA                                => ($! = 22);
use constant ICC_GET_DATA_MSG                             => ($! = 23);
use constant ICC_GET_SENT_DATA_MSG_FOR_DISPLAY            => ($! = 24);
use constant ICC_GET_RECEIVED_DATA_MSG_FOR_DISPLAY        => ($! = 25);

use constant ICC_CRYPT_PASSWORD                           => ($! = 26); #/* Password if we want an encrypted link */
use constant ICC_DISCONNECT                               => ($! = 27); #/* If Client wants to cut off the link */
use constant ICC_IDENTIFICATION                           => ($! = 28); #/* Client Identity */
use constant ICC_CLIENT_RECEIVE_ARRAY                     => ($! = 29); #/* If you want to send an array of attributes to the server */
use constant ICC_OKAPI_VERSION                            => ($! = 30); #/* To retrieve the current libOKAPI version */
use constant ICC_KONDOR_PLUS_VERSION                      => ($! = 31); #/* To retrieve the current K+ version */
use constant ICC_KRYPTON_VERSION                          => ($! = 32);
use constant ICC_IDENTIFICATION_TYPE                      => ($! = 33); #/*  UNKNOWN, LOCAL ou GLOBAL */
use constant ICC_GET_FD                                   => ($! = 34);        #/* File descriptor used with the connection of the server */
        #/* RendezVous */
use constant ICC_KPLUSFEED_MODE                           => ($! = 35); #/* Kplusfeed or Rendezvous or XML */
use constant ICC_RENDEZVOUS_MODE                          => ($! = 36);
use constant ICC_RENDEZVOUS_STRING_MODE                   => ($! = 37);
use constant ICC_XML_MODE                                 => ($! = 38);
        #/* New TK reqs 2.5 */
use constant ICC_TRANSPORT_PREFIX                         => ($! = 39); #/* Rendezvous */
        #/* New TK reqs 2.6 */
use constant ICC_ADMIN_MSG_CALLBACK                       => ($! = 100);
use constant ICC_CBERROR_CALLBACK                         => ($! = 101);
use constant ICC_DOUBLECONN_CALLBACK                      => ($! = 102); #/* Client Only */
use constant ICC_INITIALISATION_CALLBACK                  => ($! = 103); #/* Server Only */

use constant ICC_READY_FOR_SENDING                        => ($! = 104);
use constant ICC_SYNCHRONOUS_MODE                         => ($! = 105);
use constant ICC_GET_SYNCHRONOUS_MODE                     => ($! = 106);
use constant ICC_ACK_ALLOWANCE                            => ($! = 107); #/* Nb of acks with T_Id > N TK accepts to receive before ack N */
use constant ICC_GET_ACK_ALLOWANCE                        => ($! = 108);
        #/* New TK reqs 2.6.3.L3 */
use constant ICC_PORT_TIMEOUT                             => ($! = 109);
use constant ICC_XML_WRAP                                 => ($! = 110);
use constant ICC_XML_PARSE                                => ($! = 111);
use constant ICC_GET_XML_PARSE                            => ($! = 112);


use constant DATA_KEY_TABLE                               => "Table";
use constant DATA_KEY_NUMBER                              => "Number";
use constant DATA_KEY_TRANSID                             => "TransactionId";
use constant DATA_KEY_DEALID                              => "DealId";
use constant DATA_KEY_ACTION                              => "Action";
use constant DATA_KEY_DOWNLOADKEY                         => "DownloadKey";
use constant DATA_KEY_UPD_COMMENT                         => "UpdComment";
use constant DATA_KEY_UPD_STATUS                          => "UpdStatus";
use constant DATA_KEY_UPD_MVTS                            => "UpdMvts";
use constant DATA_KEY_DATEFMT                             => "DateFormat";
use constant DATA_KEY_MVT_DATE                            => "MvtDate";
use constant DATA_KEY_LAST_MODIF_DATE                     => "LastModifDate";
use constant DATA_KEY_VALID_STATUS                        => "ValidStatus";
use constant DATA_KEY_TABLE_NAME                          => "TableName";
use constant DATA_KEY_CLIENT_DEAL_ID                      => "ClientDealId";
use constant DATA_KEY_ORIGIN_MESSAGE                      => "OriginMessage";
use constant DATA_KEY_DEFAULT_FOLDERS_METHOD              => "DefaultFoldersMethod";
use constant DATA_KEY_DEFAULT_CODIFIERS_METHOD            => "DefaultCodifiersMethod";
use constant DATA_KEY_CODIFIER                            => "Codifier";
use constant DATA_KEY_SET_DEFAULT_VALUES                  => "SetDefaultValues";
use constant DATA_KEY_USE_DEFAULT_CORRESP                 => "UseDefaultCorresp";
use constant DATA_KEY_DEFAULT_CORRESP                     => "Corresp_Default";
use constant DATA_KEY_EXECUTE_SQL_PROCEDURE               => "ExecuteSqlProcedure";
use constant DATA_KEY_BASE_NAME                           => "BaseName";
use constant DATA_KEY_SQL_PROCEDURE                       => "SqlProcedure";
use constant DATA_KEY_CHARACTER_CHECK                     => "CharacterCheck";
use constant DATA_KEY_DELETE_BLANK_CHAR                   => "DeleteBlankCharacter";
use constant DATA_KEY_CONNECTION                          => "Connection_Acknowledgement";
use constant DATA_KEY_IMPORTED_BY_KONNECT                 => "ImportedByKonnect";
use constant DATA_KEY_CHECK_DOWNLOADKEY_IN_ARCHIVE        => "CheckDownloadKeyInArchive";

use constant DATA_KEY_USER_ID                             => "UsersId";
use constant DATA_KEY_PID                                 => "Pid";
use constant DATA_KEY_REQUEST_ID                          => "RequestId";
use constant DATA_KEY_REQUEST_TYPE                        => "RequestType";
use constant DATA_KEY_ANSWER                              => "Answer";
use constant DATA_KEY_ANSWER_TYPE                         => "AnswerType";
use constant DATA_KEY_ANSWER_MAIL                         => "AnswerMailTo";
use constant DATA_KEY_ANSWER_MATRIX                       => "AnswerMatrix";
use constant DATA_KEY_REQ_ROWID                           => "ReqRowId";
use constant DATA_KEY_REQ_SELECT_ID                       => "ReqSelectId";
use constant DATA_KEY_REQ_MULTIPLE                        => "ReqMultiple";
use constant DATA_KEY_REQUESTED_ID                        => "RequestedId";

use constant DATA_KEY_ERROR_CLASS                         => "ErrorClass";
use constant DATA_KEY_ERROR_TYPE                          => "ErrorType";
use constant DATA_KEY_ERROR_MESSAGE                       => "ErrorMessage";
use constant DATA_KEY_WARNING_MESSAGE                     => "WarningMessage";
use constant DATA_KEY_KPLUS_TABLE_ID                      => "Kondor+TableId";

use constant DATA_KEY_LIST                                => "_LIST_";

use constant DATA_TABLE_IMPORT                            => "ImportTable";
use constant DATA_TABLE_EXPORT                            => "ExportTable";
use constant DATA_TABLE_FOLDER_DEFAULT_METHOD             => "Folders_Default_Method";
use constant DATA_TABLE_CODIFIER_DEFAULT_METHOD           => "Codifiers_Default_Method";


# ICC_Data_Msg_Type_t
use constant ICC_DATA_MSG_SIGNON                          => ($! = 1);
use constant ICC_DATA_MSG_SIGNOFF                         => ($! = 2);
use constant ICC_DATA_MSG_REQUEST                         => ($! = 3);
use constant ICC_DATA_MSG_REQUEST_ANSWER                  => ($! = 4);
use constant ICC_DATA_MSG_TABLE                           => ($! = 5);
use constant ICC_DATA_MSG_TABLE_ACK                       => ($! = 6);
use constant ICC_DATA_MSG_READY_ON                        => ($! = 7);
use constant ICC_DATA_MSG_READY_OFF                       => ($! = 8);
use constant ICC_DATA_MSG_RELOAD_END                      => ($! = 9);
use constant ICC_DATA_MSG_ERROR                           => ($! = 10);
use constant ICC_DATA_MSG_INFO                            => ($! = 11);
use constant ICC_DATA_MSG_TABLE_SEND                      => ($! = 12);
use constant ICC_DATA_MSG_TABLE_REQ                       => ($! = 13);
use constant ICC_DATA_MSG_EVENT                           => ($! = 14);
use constant ICC_DATA_MSG_TRANS_ID                        => ($! = 15);


# ICC_Error_Type_t
use constant ICC_ERR_SUCCESSFUL                           => ($! = 0); # Not an error
use constant ICC_ERR_OTHER_TYPE                           => ($! = 1);
use constant ICC_ERR_SYBASE                               => ($! = 2);

use constant ICC_ERR_INSTRUMENT_NOT_RECOGNIZED            => ($! = 3);
use constant ICC_ERR_ACTION_NOT_FOUND                     => ($! = 4);
use constant ICC_ERR_ACTION_UNKNOWN                       => ($! = 5);
use constant ICC_ERR_ACTION_NOT_SUPPORTED                 => ($! = 6);

use constant ICC_ERR_STRING_TOO_LONG                      => ($! = 7);
use constant ICC_ERR_DATA_INVALID                         => ($! = 8);
use constant ICC_ERR_DATA_NOT_FOUND                       => ($! = 9);
use constant ICC_ERR_DATA_MUST_NOT_BE_NULL                => ($! = 10);
use constant ICC_ERR_DATA_MUST_BE_NULL                    => ($! = 11);
use constant ICC_ERR_DATA_IS_MANDATORY                    => ($! = 12);
use constant ICC_ERR_DATA_NOT_ALLOWED                     => ($! = 13);

use constant ICC_ERR_DATE_ERROR                           => ($! = 14);

use constant ICC_ERR_DOWNLOADKEY_NOT_FOUND                => ($! = 15);

use constant ICC_ERR_OLD_INSTRUMENT_NOT_FOUND             => ($! = 16);

use constant ICC_ERR_INSTRUMENT_ALREADY_EXISTS            => ($! = 17);

use constant ICC_ERR_FOLDER_EQUAL_CPTY                    => ($! = 18);

use constant ICC_ERR_DATABASE_INSERT                      => ($! = 19);
use constant ICC_ERR_DATABASE_UPDATE                      => ($! = 20);
use constant ICC_ERR_DATABASE_DELETE                      => ($! = 21);
use constant ICC_ERR_THE_ID_IS_NULL                       => ($! = 22);
use constant ICC_ERR_IMPORT_INSERT_FAILED                 => ($! = 23);

use constant ICC_ERR_ALREADY_CONNECTED                    => ($! = 1000);  # = 1000
use constant ICC_ERR_UNKNOWN_IN_THE_DATABASE              => ($! = 1001);
use constant ICC_ERR_CLIENT_DISCONNECTION                 => ($! = 1002);

use constant ICC_ERR_INVALID_ARG                          => ($! = 1003);
use constant ICC_ERR_UNKNOWN_ATTR                         => ($! = 1004);
use constant ICC_ERR_MEMORY                               => ($! = 1005);
use constant ICC_ERR_TCP                                  => ($! = 1006);
use constant ICC_ERR_KIS                                  => ($! = 1007);
use constant ICC_ERR_CLIENT_NAME                          => ($! = 1008);
use constant ICC_ERR_KIS_DISCONNECTION                    => ($! = 1009);
use constant ICC_ERR_KIS_CONNECTION                       => ($! = 1010);
use constant ICC_ERR_KIS_ACK_MESSAGE_ERROR                => ($! = 1011);
use constant ICC_ERR_KIS_ERROR_MESSAGE_ERROR              => ($! = 1012);
use constant ICC_ERR_KIS_SELECT_MSG_ERROR                 => ($! = 1013);
use constant ICC_ERR_KIS_SELECT_TIMEOUT_ERROR             => ($! = 1014);
use constant ICC_ERR_KIS_SELECT_SIGNAL_ERROR              => ($! = 1015);
use constant ICC_ERR_KIS_DATA_MESSAGE_ERROR               => ($! = 1016);

use constant ICC_ERR_REFERENCE_NOT_FOUND                  => ($! = 1017);

use constant ICC_ERR_BAD_IDENTITY                         => ($! = 1018);
use constant ICC_ERR_CRYPT                                => ($! = 1019);

use constant ICC_ERR_IMPORT_DEALS_FAILED                  => ($! = 1020);

        #/* RendezVous */
use constant ICC_ERR_SERVER                               => ($! = 1021);
use constant ICC_ERR_SERVER_NAME                          => ($! = 1022);
use constant ICC_ERR_SERVER_HOSTNAME                      => ($! = 1023);
use constant ICC_ERR_SERVER_DISCONNECTION                 => ($! = 1024);
use constant ICC_ERR_SERVER_CONNECTION                    => ($! = 1025);
use constant ICC_ERR_SERVER_ACK_MESSAGE_ERROR             => ($! = 1026);
use constant ICC_ERR_SERVER_ERROR_MESSAGE_ERROR           => ($! = 1027);
use constant ICC_ERR_SERVER_SELECT_MSG_ERROR              => ($! = 1028);
use constant ICC_ERR_SERVER_SELECT_TIMEOUT_ERROR          => ($! = 1029);
use constant ICC_ERR_SERVER_SELECT_SIGNAL_ERROR           => ($! = 1030);
use constant ICC_ERR_SERVER_DATA_MESSAGE_ERROR            => ($! = 1031);
use constant ICC_ERR_KNEL_CONFIG_FILE_LOAD_FAILED         => ($! = 1032);
use constant ICC_ERR_KNEL_OPEN_FAILED                     => ($! = 1033);
use constant ICC_ERR_KNEL_INIT_FAILED                     => ($! = 1034);
use constant ICC_ERR_KNEL_CLOSE_FAILED                    => ($! = 1035);
use constant ICC_ERR_KNEL_FIELD_ADD_FAILED                => ($! = 1036);
use constant ICC_ERR_KNEL_FIELD_GET_FAILED                => ($! = 1037);

use constant ICC_ERR_RDV                                  => ($! = 1038);
use constant ICC_ERR_UNDEFINED                            => ($! = 1039);

use constant ICC_ERR_FIELD_ADD_FAILED                     => ($! = 1040);
use constant ICC_ERR_FIELD_GET_FAILED                     => ($! = 1041);
use constant ICC_ERR_CONFIG_FILE_LOAD_FAILED              => ($! = 1042);
use constant ICC_ERR_OPEN_FAILED                          => ($! = 1043);
use constant ICC_ERR_INIT_FAILED                          => ($! = 1044);
use constant ICC_ERR_CLOSE_FAILED                         => ($! = 1045);
use constant ICC_ERR_CLIENT_REJECTED                      => ($! = 1046);
use constant ICC_ERR_SEND_SOCKET_FULL                     => ($! = 1047);




require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(

	
);
@EXPORT = qw(
      ICC_create
      ICC_set
      ICC_get
      ICC_main_loop
      ICC_main_init
      ICC_main_start
      ICC_main_select
      ICC_main_timeout
      ICC_main_signal
      ICC_main_message
      ICC_main_disconnect
      ICC_main_loop
      ICC_multiple_main_start
      ICC_multiple_main_message
      ICC_multi_main_loop 

      ICC_DataMsg_init
      ICC_DataMsg_set
      ICC_DataMsg_String_set
      ICC_DataMsg_Integer_set
      ICC_DataMsg_Float_set
      ICC_DataMsg_Date_set
      ICC_DataMsg_Choice_set
      ICC_DataMsg_get

      ICC_DataMsg_Buffer_set
      ICC_DataMsg_Buffer_get
      
      ICC_DataMsg_send_to_server
);

$VERSION = '263.005';

bootstrap Kools::Okapi $VERSION;


1;
__END__


=head1 NAME

Kools::Okapi - Perl extension for the OKAPI api of Kondor+ 2.6

=head1 SYNOPSIS

use Kools::Okapi;

$icc = ICC_create(ICC_HOST_NAME,"localhost");

=head1 DESCRIPTION

Provides a base OKAPI wrapper functions. See the OKAPI programmers guide for more usage information.

=head1 AUTHOR

Gabriel Galibourg.

=head1 SEE ALSO

perl(1).
http://kools.sourceforge.net

=cut

