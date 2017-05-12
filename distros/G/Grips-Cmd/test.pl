# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => $ENV{GRIPS_CMD_TESTS} ? 80 : 1 };
use strict;
use Data::Dumper;
use Grips::Cmd;
use Carp;
use Term::ReadKey;

my $uc     = '';
my $pwd    = '';
my $host   = 'app01testgrips.dimdi.de';
my $port   = 5101;
my $debug  = 0;
my $tmp;
my $grips;

my %testResponses = ();
my @tests;
my $grips;
my @names;
my $longest;

if ($ENV{GRIPS_CMD_TESTS}) {
	fillTestResponses(\%testResponses);
	
	print "\nPlease enter hostname (type enter to use $host):";
	$tmp = <STDIN>;
	chomp $tmp;
	$host = $tmp if ($tmp);
	
	print "Please enter port (type enter to use $port):";
	$tmp = <STDIN>;
	chomp $tmp;
	$port = $tmp if ($tmp);
	
	ReadMode('noecho');
	print "Please enter user code:";
	$uc = ReadLine(0);
	chomp $uc;
	print "\n";
	ReadMode(0);
	
	ReadMode('noecho');
	print "Please enter password (type enter if you have no password):";
	$pwd = ReadLine(0);
	chomp $pwd;
	print "\n";
	ReadMode(0);

	$grips = new Grips::Cmd(host => $host, port => $port);
	
	push @tests, {name => "login",                          meth => sub {return $grips->login(user => $uc, pwd => $pwd, debug => $debug)}};
	push @tests, {name => "enterApplication",               meth => sub {return $grips->enterApplication(_ => $grips->getSessionID(), app_name => 'index', mode => 'CBI_REPLACE', debug => $debug)}};
	push @tests, {name => "getIndexedBaseList",             meth => sub {return $grips->getIndexedBaseList(_ => $grips->getSessionID(), subject => [1234], subject_num => 1, query => {string => "nix", lang => 'CBI_NATIVE'}, titles_num_required => 3, debug => $debug)}};
	push @tests, {name => "leaveApplication",               meth => sub {return $grips->leaveApplication(_ => $grips->getSessionID(), debug => $debug)}};
	push @tests, {name => "getApplicationList",             meth => sub {return $grips->getApplicationList(_ => $grips->getSessionID(), debug => $debug)}};
	push @tests, {name => "getSubjectList",                 meth => sub {return $grips->getSubjectList(_ => $grips->getSessionID(), debug => $debug)}};
	push @tests, {name => "getBaseList",                    meth => sub {return $grips->getBaseList(_ => $grips->getSessionID(), debug => $debug)}};
	push @tests, {name => "getApplicationInfo",             meth => sub {return $grips->getApplicationInfo(_ => $grips->getSessionID(), application => "meddirect", debug => $debug)}};
	push @tests, {name => "SESSION.setAttributePermanent",  meth => sub {return $grips->setAttributePermanent(_ => $grips->getSessionID(), highlight => 'CBI_YES', debug => $debug)}};
	push @tests, {name => "SESSION.setAttribute",           meth => sub {return $grips->setAttribute(_ => $grips->getSessionID(), language => 'germ', timeout => 60, debug => $debug)}};
	push @tests, {name => "SESSION.getAttributes",          meth => sub {return $grips->getAttributes(_ => $grips->getSessionID(), debug => $debug)}};
	push @tests, {name => "SESSION.getAttributes2",         meth => sub {return $grips->getAttributes(_ => $grips->getSessionID(), attributes => ["timeout", "title_length", "language", "highlight"], debug => $debug)}};
	push @tests, {name => "defineBase",                     meth => sub {return $grips->defineBase(_ => $grips->getSessionID(), id => "bas1", dbs => ["me66"], debug => $debug)}};
	push @tests, {name => "open",                           meth => sub {return $grips->open(_ => "bas1", debug => $debug)}};
	push @tests, {name => "setLimit",                       meth => sub {return $grips->setLimit(_ => "bas1", cond => {lang => 'CBI_NATIVE', string => 'PY>=1990'}, debug => $debug)}};
	push @tests, {name => "BASE.setAttribute",              meth => sub {return $grips->setAttribute(_ => "bas1", name => 'blubber', debug => $debug)}};
	push @tests, {name => "BASE.getAttributes",             meth => sub {return $grips->getAttributes(_ => "bas1", debug => $debug)}};
	push @tests, {name => "getFieldsInfo",                  meth => sub {return $grips->getFieldsInfo(_ => "bas1", fields_num => 2, field => ["AU", "TI"], debug => $debug)}};
	push @tests, {name => "browseIndex",                    meth => sub {return $grips->browseIndex(	_ => "bas1",
																							term => 'heart',
																							field => 'ct',
																							relation => 'CBI_NARROW',
																							terms_num_requested => 10,
																							debug => $debug,
																							_ => "bas1",
																							req_modifier => 'CBI_NEW',
																							"check_result.id" => 2)}};
	push @tests, {name => "search1",                        meth => sub {return $grips->search(_ => "bas1", query => {string => "nix", lang => 'CBI_NATIVE'}, debug => $debug)}};
	push @tests, {name => "search2",                        meth => sub {return $grips->search(_ => "bas1", query => {string => "nix", lang => 'CBI_NATIVE', mode => 'CBI_NOFIND'}, debug => $debug)}};
	push @tests, {name => "search3",                        meth => sub {return $grips->search(_ => "bas1", query => "nix", 'query.mode' => 'CBI_NOFIND', debug => $debug)}};
	push @tests, {name => "search4",                        meth => sub {return $grips->search(_ => "bas1", 'query.string' => "nix", debug => $debug)}};
	push @tests, {name => "getResults",                     meth => sub {return $grips->getResults(_ =>  "bas1", debug => $debug)}};
	push @tests, {name => "removeDuplicates",               meth => sub {return $grips->removeDuplicates(debug => $debug, _ => "bas1", "check_result.id" => 2)}};
	push @tests, {name => "sort",                           meth => sub {return $grips->sort(debug => $debug,
												_ => 2,
												sort_args_num => 2,
												sort_arg => [{field => 'AU', seq => 'CBI_ASCENDING'}, {field => 'PY', seq => 'CBI_DESCENDING'}])}};
	push @tests, {name => "getDocs",                        meth => sub {return $grips->getDocs(_ => 2, req_modifier => 'CBI_TITLES', subset => "1-2", debug => $debug)}};
	push @tests, {name => "getDocBody",                     meth => sub {return $grips->getDocBody(_ => 2, subset => "1-2", layout => "CBI_HTML", req_modifier => "CBI_FULL", debug => $debug)}};
	push @tests, {name => "getField",                       meth => sub {return $grips->getField(_ => 2, 'doc.id' => "1", path => "STD", debug => $debug)}};
	push @tests, {name => "analyseTerms",                   meth => sub {return $grips->AnalyseTerms(_ => 2, 
	                                                                                        req_modifier => "CBI_NEW",
																							field => "AU",
																							sample_size => 4,
	                                                                                        debug => $debug)}};
	push @tests, {name => "analyseTermsStatistic",          meth => sub {return $grips->AnalyseTermsStatistic(   _ => 2, 
	                                                                                                    req_modifier => "CBI_NEW",
	                                                                                                    field => "AU",
																										required_subset => "1-3",
																										terms_num_requested => 3,
																										sample_size => 3,
	                                                                                                    debug => $debug)}};
	push @tests, {name => "getSupplList",                   meth => sub {return $grips->getSupplList(_ => "service", debug => $debug)}};
	push @tests, {name => "getSupplInfo",                   meth => sub {return $grips->getSupplInfo(_ => "service", supplier => {name => 'TRAIN'}, debug => $debug)}};
	push @tests, {name => "deleteResult",                   meth => sub {return $grips->deleteResult(_ => "bas1", result => {id => 2}, debug => $debug)}};
	push @tests, {name => "close",                          meth => sub {return $grips->close(_ => "bas1", debug => $debug)}};
	push @tests, {name => "getCost",                        meth => sub {return $grips->getCost(_ => $grips->getSessionID(), debug => $debug)}};
	push @tests, {name => "logout",                         meth => sub {return $grips->logout(_ => $grips->getSessionID(), debug => $debug)}};
	
	@names;
	
	push @names, $_->{name} for @tests; 
	
	$longest = getLongestName();
	
	print "\n";
	
	
	testMe($_, $longest) foreach (@tests);
	
	print "\nnow testing again but with new response syntax ('dot syntax') ...\n\n";
	
	$grips = new Grips::Cmd(host => $host, port => $port, newResponseSyntax => 1);
	testMe($_, $longest) foreach (@tests);
} else {
	ok(1);
}

sub testMe
{
  my $test = shift;
  my $lon  = shift;
  my $resp;
  my $respStructTxt = "reponse structure";

  print "testing $test->{name} ", '.' x ($lon + 3 - length ($test->{name})), ' ';
  
  
  $resp = &{$test->{meth}};

  ok($resp->{status} eq 'CBI_OK' or $resp->{status} eq 'CBI_NO_MORE');

  #print Dumper $resp;

  if (exists $testResponses{$test->{name}}) {
      print "        $respStructTxt ", '.' x ($lon + 3 - length ($respStructTxt)), ' ';
      ok(checkResponse($testResponses{$test->{name}}, $resp));
  }
}

sub getLongestName
{
  my $len = 0;

  foreach (@names)
  {
    $len = length if (length > $len);
  }

  return $len;
}

sub checkResponse {
    my $orig  = shift;
    my $check = shift;
    
    my $VAR1;
    
    eval $orig;
    
    my $str1 = resp2Str($VAR1, "");
    my $str2 = resp2Str($check, "");
    
    if ($str1 eq $str2) {
        return 1;
    } else {

	print STDERR "IS:\n$str2\n\n";
	print STDERR "SHOULD BE:\n$str1\n\n";

        return 0;
    }
}


sub resp2Str {
	my $data   = shift;
	my $prefix = shift;
	my $tmp;
        my $out;
        my $dot;
        
        $prefix ||= "";

        unless (defined $data) {
            $data = "";
            carp "Value of $prefix is undefined, I convert it to '' (empty string). Warning issued";
	}
	
	if (!defined ref($data) or ref($data) eq "") {
            $out .= $prefix . "=\n";
            
	} elsif (ref($data) eq "SCALAR") {
            $out .= $prefix . "=\n";

	}  elsif (ref($data) eq "ARRAY") {
	    for (1.. sort @$data) {
	        $dot = "";
	        $out .= resp2Str($data->[$_ - 1], $prefix . "(" . $_ . ")" . $dot);
	    }
	    
	} elsif (ref($data) eq "HASH") {
	    for (sort keys %$data) {
	        $out .= resp2Str($data->{$_}, $prefix . "." . $_);
	    }
	    
	} else {
		croak "Unsupported data structure " . ref $data . "!";
	}
	
	return $out;
}

sub fillTestResponses {
    my $t = shift;
    
    $t->{search} = q($VAR1 = {
              'request' => 'bas1.Search',
              'status' => 'CBI_OK',
              'CBI_RESPONSE' => '10409239699228.0000018',
              'result' => {
                            'hits' => '44',
                            'query' => 'nix',
                            'id' => '2'
                          },
              'message' => 'Base.Search: Search was o.K.'
            };
    );
    
    $t->{browseIndex} = q($VAR1 = {
              'request' => 'bas1.BrowseIndex',
              'remaining_terms' => '',
              'status' => 'CBI_OK',
              'CBI_RESPONSE' => '10409252419673.0000017',
              'terms_num' => '10',
              'term_num' => '10',
              'term' => [
                          {
                            'in_docs' => '82991',
                            'string' => 'A07.541 ... HEART'
                          },
                          {
                            'in_docs' => '3568',
                            'string' => 'A07.541.207 ... ENDOCARDIUM'
                          },
                          {
                            'in_docs' => '6225',
                            'string' => 'A07.541.278 ... FETAL HEART'
                          },
                          {
                            'in_docs' => '1031',
                            'string' => 'A07.541.278.395 ... DUCTUS ARTERIOSUS'
                          },
                          {
                            'in_docs' => '91',
                            'string' => 'A07.541.278.930 ... TRUNCUS ARTERIOSUS'
                          },
                          {
                            'in_docs' => '21635',
                            'string' => 'A07.541.358 ... HEART ATRIUM'
                          },
                          {
                            'in_docs' => '139',
                            'string' => 'A07.541.358.100 ... ATRIAL APPENDAGE'
                          },
                          {
                            'in_docs' => '19417',
                            'string' => 'A07.541.409 ... HEART CONDUCTION SYSTEM'
                          },
                          {
                            'in_docs' => '4825',
                            'string' => 'A07.541.409.147 ... ATRIOVENTRICULAR NODE'
                          },
                          {
                            'in_docs' => '2809',
                            'string' => 'A07.541.409.273 ... BUNDLE OF HIS'
                          }
                        ],
              'message' => 'Base.BrowseIndex: 10 terms returned'
            };
    );
    
    $t->{getFieldsInfo} = q($VAR1 = {
              'fields_num' => '2',
              'request' => 'bas1.GetFieldsInfo',
              'status' => 'CBI_OK',
              'CBI_RESPONSE' => '10409252419673.0000016',
              'field' => [
                           {
                             'index' => [
                                          {
                                            'addinfo_fields_num' => '0',
                                            'qualification_num' => '0',
                                            'type' => 'DIRECT',
                                            'id' => 'AU',
                                            'thesaurus_relations' => 'NO'
                                          }
                                        ],
                             'type' => 'STRING',
                             'id' => 'AU',
                             'index_num' => '1'
                           },
                           {
                             'index' => [
                                          {
                                            'addinfo_fields_num' => '0',
                                            'qualification_num' => '0',
                                            'type' => 'ADJACENT',
                                            'id' => 'FT',
                                            'thesaurus_relations' => 'NO'
                                          }
                                        ],
                             'type' => 'STRING',
                             'id' => 'TI',
                             'index_num' => '1'
                           }
                         ],
              'message' => 'Base.GetFieldsInfo: ok'
            };
    );
    
    $t->{getCost} = q($VAR1 = {
              'request' => '10409255749800.GetCost',
              'status' => 'CBI_OK',
              'reason' => [
                            'Licence Fees',
                            'Host Charges',
                            'Total Net'
                          ],
              'message' => 'Session.GetCost(): Cost Information returned',
              'sub_cost' => [
                              '      0.00 EUR',
                              '      1.50 EUR',
                              '      1.50 EUR'
                            ],
              'tot_cost' => '      1.74 EUR',
              'CBI_RESPONSE' => '10409255749800.0000031',
              'costs_num' => '3',
              'sub_cost_num' => '3',
              'reason_num' => '3'
            };
    );
    
    $t->{getSupplInfo} = q($VAR1 = {
              'request' => 'service.GetSupplInfo',
              'it' => [
                        'CBI_COLLECTIVE',
                        'CBI_SINGLE'
                      ],
              'status' => 'CBI_OK',
              'name' => 'TRAIN',
              'message' => 'Service.GetSupplInfo: Supplier information returned',
              'group' => 'CBI_SUPPL_SUBITO',
              'format_num' => '9',
              'it_num' => '2',
              'format' => [
                            'CBI_PDF',
                            'CBI_GIF',
                            'CBI_TIFF',
                            'CBI_POSTSCRIPT',
                            'CBI_MICROFILM',
                            'CBI_MICROFICHE',
                            'CBI_COPY',
                            'CBI_LOAN',
                            'CBI_MTIFF'
                          ],
              'bi_num' => '1',
              'medium' => [
                            'CBI_EMAIL',
                            'CBI_MAIL',
                            'CBI_FAX',
                            'CBI_FTP',
                            'CBI_FTP-P'
                          ],
              'CBI_RESPONSE' => '10409255749800.0000028',
              'bi' => [
                        'CBI_NONE'
                      ],
              'medium_num' => '5'
            };
    );
    
    $t->{getField} = q($VAR1 = {
	  'status' => 'CBI_OK',
          'message' => 'SearchResult.GetField: end of field(s)',
          'CBI_RESPONSE' => '109784566916835.0000027',
          'doc' => {
                     'DT' => 'News',
                     'SU' => 'IM',
                     'SOPAGE' => '266',
                     'CY' => 'United States',
                     'ND' => 'ME11138860',
                     '$COPYR' => 'NLM 2002',
                     '$DBKEY' => 'ME66',
                     'PMID' => '11138860',
                     'SOI' => 'SOURCE AVAILABLE',
                     'PD' => '2000 Nov-Dec',
                     'TE' => 'Spermatocidal Agents; Nonoxynol/26027-38-3',
                     'SOVOL' => '32',
                     'TI' => 'Nix to nonoxynol-9 to prevent HIV.',
                     'CO' => 'FPGPA',
                     'SOJTL' => 'Family planning perspectives',
                     'ISSN' => '0014-7354',
                     'STA' => '',
                     'JID' => '0241370',
                     'fulltext_link' => 'CBI_YES',
                     'SOISS' => '6',
                     'CR' => '26027-38-3',
                     'LA' => 'English',
                     'CTG' => 'HIV-INFEKTIONEN/*Verh%/1��iso8859-15��tung & Bek%/1��iso8859-15��mpfung; MENSCH; NONOXYNOL/*therapeutische Anwendung; SPERMIZIDE MITTEL/*therapeutische Anwendung',
                     'CT' => 'HIV INFECTIONS/*prevention & control; HUMAN; NONOXYNOL/*therapeutic use; SPERMATOCIDAL AGENTS/*therapeutic use'
                   },
          'request' => '2.GetField'
	  };
		       );

}

#########################
